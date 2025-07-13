#!/bin/bash

# Configurazione rigorosa dello script
set -x          # Debug: mostra i comandi eseguiti
set -e          # Interrompe lo script se un comando fallisce
set -u          # Interrompe se viene usata una variabile non definita
set -o pipefail # Considera fallita una pipeline se uno dei comandi fallisce

# Controlla se è stata passata l'opzione --debug
DEBUG_MODE=false
if [[ "${1:-}" == "--debug" ]]; then
  DEBUG_MODE=true
  echo "MODALITÀ DEBUG ATTIVATA: scaricherò solo le prime 3 pagine (0-2)"
fi

# Ottieni il percorso assoluto della cartella dello script
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crea le cartelle di lavoro necessarie
mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/cgsse
mkdir -p "$folder"/../data/cgsse

# Elimina tutti i file (non le directory) nella cartella tmp/cgsse e nelle sue sottocartelle
find "$folder"/tmp/cgsse -type f -delete

# data di oggi in formato YYYY-MM-DD
oggi=$(date +%Y-%m-%d)

# aggiungi 30 giorni alla data di oggi
oggi=$(date -d "$oggi + 30 days" +%Y-%m-%d)

# Rileva se siamo in esecuzione su GitHub Actions
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  USE_TOR=true
  echo "Rilevato ambiente GitHub Actions: utilizzerò Tor per le chiamate"
else
  USE_TOR=false
  echo "Rilevato ambiente locale: utilizzerò chiamate dirette"
fi

# Funzione per eseguire curl con retry (con o senza Tor)
curl_with_retry() {
  local url="$1"
  local output_file="$2"
  local max_attempts=4
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    if [ "$USE_TOR" = true ]; then
      echo "Tentativo $attempt per: $url (tramite Tor)"

      # Usa Tor come proxy SOCKS5 sulla porta 9050
      if curl -ksL --socks5-hostname 127.0.0.1:9050 \
        --max-time 60 --connect-timeout 15 --fail "$url" \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'accept-language: it,en-US;q=0.9,en;q=0.8' \
        -H 'cache-control: no-cache' \
        -H 'pragma: no-cache' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' \
        >"$output_file"; then
        echo "Download completato con successo al tentativo $attempt"
        return 0
      fi
    else
      echo "Tentativo $attempt per: $url (chiamata diretta)"

      # Chiamata diretta senza Tor
      if curl -ksL \
        --max-time 30 --connect-timeout 10 --fail "$url" \
        -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
        -H 'accept-language: it,en-US;q=0.9,en;q=0.8' \
        -H 'cache-control: no-cache' \
        -H 'pragma: no-cache' \
        -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' \
        >"$output_file"; then
        echo "Download completato con successo al tentativo $attempt"
        return 0
      fi
    fi

    echo "Tentativo $attempt fallito"
    if [ $attempt -eq $max_attempts ]; then
      echo "ERRORE: Impossibile scaricare $url dopo $max_attempts tentativi"
      exit 1
    fi

    if [ "$USE_TOR" = true ]; then
      sleep $((attempt * 3)) # Pausa più lunga per Tor
    else
      sleep $((attempt * 2)) # Pausa più breve per chiamata diretta
    fi

    attempt=$((attempt + 1))
  done
}

data_inizio="2025-01-01"

# Scarica la prima pagina per determinare il numero totale di pagine usando la funzione retry
curl_with_retry "https://www.cgsse.it/calendario-scioperi?data_inizio=${data_inizio}&data_fine=${oggi}&page=0" "$folder/tmp/cgsse/cgsse_page_000.html"

# Estrai il numero dell'ultima pagina dall'attributo href usando XPath e regex
pagine=$(<"$folder"/tmp/cgsse/cgsse_page_000.html scrape -e '//a[contains(@title, "ultima pagina")]/@href' | grep -oP 'page=\K\d+')

echo "Numero di pagine: $pagine"

# Se è attiva la modalità debug, limita a solo 3 pagine (0-2)
if [ "$DEBUG_MODE" = true ]; then
  pagine=2
  echo "MODALITÀ DEBUG: numero di pagine limitato a $((pagine + 1)) (0-$pagine)"
fi

# Rimuovi il file di output precedente se esiste per evitare duplicati
if [ -f "$folder"/tmp/cgsse/cgsse_data.jsonl ]; then
  rm "$folder"/tmp/cgsse/cgsse_data.jsonl
fi

# Scarica tutte le pagine del calendario scioperi iterando da 0 al numero massimo
for ((i = 0; i <= pagine; i++)); do
  echo "Scaricando pagina $i"

  # Usa la funzione di retry per scaricare ogni pagina
  curl_with_retry "https://www.cgsse.it/calendario-scioperi?data_inizio=${data_inizio}&data_fine=${oggi}&page=$i" "$folder/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html"

  # Pausa tra le chiamate (più lunga per Tor, più breve per chiamate dirette)
  if [ "$USE_TOR" = true ]; then
    sleep 2
  else
    sleep 1
  fi

  # Estrai i dati dalla pagina HTML usando scrape (XPath) e xq (trasformazione JSON)
  <"$folder"/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html scrape -be '//ul[@class="responsive-table"]/li[@class="table-row views-row"]' | xq -c '
[
  # 1️⃣  Se "li" è già un array lo espando con .[],
  #     altrimenti lo metto fra [ ... ] e prendo l’unico elemento.
  (.html.body.li | if type=="array" then .[] else . end)

  # 2️⃣  Mi assicuro di lavorare solo sugli oggetti (scarto le stringhe).
  | select(type=="object")

  # 3️⃣  Estraggo i campi
  | {
      data:              .div.div[0]["#text"],
      settore:           .div.div[1]["#text"],
      azienda:           .div.div[2]["#text"],
      sindacato:         .div.div[3]["#text"],
      ambito_geografico: (
        if   .div.div[4]["#text"]?                               then .div.div[4]["#text"]
        elif .div.div[4].img["@alt"]? == "sciopero nazionale"    then "NAZIONALE"
        else null end
      ),
      modalita:          .div.div[5].p,
      dettagli_link: (
        .div.div[6].div
        | map(select(has("a")))
        | ("https://www.cgsse.it" + .[0].a["@href"])            // null
      ),
      revocato: (
        .div.div[6].div
        | map(
            if   (.img | type) == "array"  then any(.img[]?; .["@alt"] == "sciopero revocato")
            elif (.img | type) == "object" then      .img["@alt"] == "sciopero revocato"
            else false end
          )
        | any
      )
    }
] | .[]' >>"$folder"/tmp/cgsse/cgsse_data.jsonl

done

# Elaborazione finale dei dati estratti con Miller (mlr)
# Pulisce spazi bianchi, rimuove duplicati e converte le date in formato ISO
mlr -I --jsonl --from "$folder"/tmp/cgsse/cgsse_data.jsonl clean-whitespace then uniq -a then put 'if ($data =~ "^Dal (\d{2}-\d{2}-\d{4}) al (\d{2}-\d{2}-\d{4})$") {
    $data_dal_raw = "\1";  # Prima data in formato DD-MM-YYYY
    $data_al_raw = "\2";   # Seconda data in formato DD-MM-YYYY

    # Converti in formato YYYY-MM-DD per compatibilità ISO
    $data_dal_iso = strftime(strptime($data_dal_raw, "%d-%m-%Y"), "%Y-%m-%d");
    $data_al_iso = strftime(strptime($data_al_raw, "%d-%m-%Y"), "%Y-%m-%d");
}' then put 'if ($data =~ "^\d{2}-\d{2}-\d{4}$") {
    # Converti la data singola in formato YYYY-MM-DD per compatibilità ISO
    $data_iso = strftime(strptime($data, "%d-%m-%Y"), "%Y-%m-%d");

}' then cut -x -f data_dal_raw,data_al_raw then put 'if (!is_null($data_iso)) {$data_sort = $data_iso} else {$data_sort = $data_dal_iso}' then sort -tr dettagli_link

# aggiungi valori date dal, al, anche per gli scioperi di un giorno
mlr -I --jsonl --from "$folder"/tmp/cgsse/cgsse_data.jsonl put 'if (is_null($data_al_iso)){$data_al_iso = $data_iso;$data_dal_iso = $data_iso}else{$data_al_iso=$data_al_iso;$data_dal_iso=$data_dal_iso}' then uniq -a

# vai in append se i dati esistono già, altrimenti copia
if [ -f "$folder"/../data/cgsse/cgsse_data.jsonl ]; then
  cat "$folder"/tmp/cgsse/cgsse_data.jsonl >>"$folder"/../data/cgsse/cgsse_data.jsonl
else
  cp "$folder"/tmp/cgsse/cgsse_data.jsonl "$folder"/../data/cgsse/cgsse_data.jsonl
fi

mlr -I --jsonl uniq -a then sort -tr dettagli_link then put '$sindacato=sub($sindacato,"Aderente","\nAderente");$modalita=sub($modalita,"^null$","");$modalita=sub($modalita,", null","");$modalita=sub($modalita,"(\[|\])","")' then gsub -f modalita '"' '' "$folder"/../data/cgsse/cgsse_data.jsonl

mlr -I --jsonl put '$sindacato=sub($sindacato,"\n+","|")' then put '$sindacato=sub($sindacato,"[|]+","|")' then uniq -a then sort -tr dettagli_link "$folder"/../data/cgsse/cgsse_data.jsonl

mlr --ijsonl --ocsv unsparsify then uniq -a "$folder"/../data/cgsse/cgsse_data.jsonl >"$folder"/../data/cgsse/cgsse_data.csv
