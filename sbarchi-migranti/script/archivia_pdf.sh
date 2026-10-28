#!/bin/bash

# Archivia i PDF del Cruscotto statistico giornaliero del Ministero dell'Interno.
# Idempotente: per gli URL già visti fa una GET condizionale (If-None-Match) e
# scrive un file solo se il suo sha256 non è già in archivio.
# Nomi: YYYY-MM-DD_cruscotto_statistico_giornaliero[_vN].pdf
# Tiene traccia di ogni URL e file in rawdata/pdf/manifest.csv

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

URL="https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero"
archivio="$folder/../rawdata/pdf"
manifest="$archivio/manifest.csv"
oggi="$(date +%F)"

lavoro="$(mktemp -d)"
trap 'rm -rf "$lavoro"' EXIT

# data YYYY-MM-DD dal nome del file (dd-mm-yyyy, dd_mm_yyyy, dd.mm.yyyy, dd mese yyyy)
data_da_testo() {
  perl -CS -Mutf8 -ne '
    BEGIN{%m=(gennaio=>1,febbraio=>2,marzo=>3,aprile=>4,maggio=>5,giugno=>6,luglio=>7,agosto=>8,settembre=>9,ottobre=>10,novembre=>11,dicembre=>12)}
    s/%20/ /g;
    if(/(\d{2})[-_. ](\d{2})[-_. ](\d{4})/){print "$3-$2-$1"; exit}
    if(/(\d{1,2})°?[ _](gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre)[ _](\d{4})/i){printf("%s-%02d-%02d",$3,$m{lc $2},$1); exit}'
}

# lista dei PDF sulla pagina; se la pagina non risponde o non ha PDF, errore
curl -fsSL --retry 3 "$URL" -o "$lavoro/pagina.html"
grep -oE 'href="[^"]+\.pdf"' "$lavoro/pagina.html" | sed -E 's/^href="//;s/"$//' | sort -u >"$lavoro/url.txt"
n_url="$(wc -l <"$lavoro/url.txt")"
if [ "$n_url" -eq 0 ]; then
  echo "Nessun PDF trovato in $URL: la pagina è cambiata?" >&2
  exit 1
fi

# indice sha256 -> nome dei PDF già in archivio
declare -A nome_da_sha=()
while read -r sha percorso; do
  nome_da_sha[$sha]="$(basename "$percorso")"
done < <(sha256sum "$archivio"/*.pdf)

# manifest precedente, indicizzato per URL
declare -A m_etag=() m_lm=() m_len=() m_sha=() m_prima=()
if [ -f "$manifest" ]; then
  # separatore "|" e non tab: read fonde le tab consecutive e i campi vuoti si perderebbero
  while IFS='|' read -r data nome sha url sul_sito etag lm len prima; do
    [ -z "$url" ] && continue
    m_etag[$url]="$etag"
    m_lm[$url]="$lm"
    m_len[$url]="$len"
    m_sha[$url]="$sha"
    m_prima[$url]="$prima"
  done < <(mlr --icsv --ocsv --ofs '|' --headerless-csv-output cut -o -f data_report,nome_file,sha256,url,sul_sito,etag,last_modified,content_length,prima_vista "$manifest")
fi

righe="$lavoro/righe.tsv"
: >"$righe"
declare -A url_visti=() sha_visti=()

while read -r url; do
  url_visti[$url]=1
  etag="${m_etag[$url]:-}"
  condizione=()
  [ -n "$etag" ] && condizione=(-H "If-None-Match: \"$etag\"")

  stato="$(curl -sS --retry 3 -D "$lavoro/header.txt" -o "$lavoro/file.pdf" -w '%{http_code}' "${condizione[@]}" "$url")"

  if [ "$stato" = "304" ]; then
    sha="${m_sha[$url]}"
    lm="${m_lm[$url]}"
    len="${m_len[$url]}"
  elif [ "$stato" = "200" ]; then
    if [ "$(head -c 4 "$lavoro/file.pdf")" != "%PDF" ]; then
      echo "Non è un PDF: $url" >&2
      exit 1
    fi
    etag="$(grep -i '^etag:' "$lavoro/header.txt" | sed -E 's/^[^:]+: *//;s/"//g' | tr -d '\r')"
    lm="$(grep -i '^last-modified:' "$lavoro/header.txt" | sed -E 's/^[^:]+: *//' | tr -d '\r')"
    [ -n "$lm" ] && lm="$(date -u -d "$lm" +%FT%TZ)"
    len="$(stat -c %s "$lavoro/file.pdf")"
    sha="$(sha256sum "$lavoro/file.pdf" | cut -d' ' -f1)"

    if [ -z "${nome_da_sha[$sha]:-}" ]; then
      data="$(basename "$url" | data_da_testo)"
      [ -z "$data" ] && data="$(pdftotext -l 1 "$lavoro/file.pdf" - | data_da_testo)"
      if [ -z "$data" ]; then
        echo "Data non ricavabile né dal nome né dal testo: $url" >&2
        exit 1
      fi
      nome="${data}_cruscotto_statistico_giornaliero.pdf"
      v=2
      while [ -e "$archivio/$nome" ]; do
        nome="${data}_cruscotto_statistico_giornaliero_v${v}.pdf"
        v=$((v + 1))
      done
      mv "$lavoro/file.pdf" "$archivio/$nome"
      nome_da_sha[$sha]="$nome"
    fi
  else
    echo "HTTP $stato per $url" >&2
    exit 1
  fi

  nome="${nome_da_sha[$sha]}"
  sha_visti[$sha]=1
  printf '%s\t%s\t%s\t%s\tsi\t%s\t%s\t%s\t%s\n' \
    "${nome:0:10}" "$nome" "$sha" "$url" "$etag" "$lm" "$len" "${m_prima[$url]:-$oggi}" >>"$righe"
done <"$lavoro/url.txt"

# URL del manifest precedente non più sul sito
for url in "${!m_sha[@]}"; do
  [ -n "${url_visti[$url]:-}" ] && continue
  sha="${m_sha[$url]}"
  sha_visti[$sha]=1
  nome="${nome_da_sha[$sha]:-}"
  printf '%s\t%s\t%s\t%s\tno\t%s\t%s\t%s\t%s\n' \
    "${nome:0:10}" "$nome" "$sha" "$url" "${m_etag[$url]}" "${m_lm[$url]}" "${m_len[$url]}" "${m_prima[$url]}" >>"$righe"
done

# PDF in archivio che nessun URL attuale o passato restituisce
for sha in "${!nome_da_sha[@]}"; do
  [ -n "${sha_visti[$sha]:-}" ] && continue
  nome="${nome_da_sha[$sha]}"
  printf '%s\t%s\t%s\t\tno\t\t\t\t\n' "${nome:0:10}" "$nome" "$sha" >>"$righe"
done

{
  printf 'data_report\tnome_file\tsha256\turl\tsul_sito\tetag\tlast_modified\tcontent_length\tprima_vista\n'
  cat "$righe"
} | mlr --itsv --ocsv sort -f data_report,nome_file,url >"$lavoro/manifest.csv"

mv "$lavoro/manifest.csv" "$manifest"
