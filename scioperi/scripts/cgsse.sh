#!/bin/bash

# Configurazione rigorosa dello script
set -x  # Debug: mostra i comandi eseguiti
set -e  # Interrompe lo script se un comando fallisce
set -u  # Interrompe se viene usata una variabile non definita
set -o pipefail  # Considera fallita una pipeline se uno dei comandi fallisce

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

# Funzione per eseguire curl con retry in caso di fallimento tramite proxy
curl_with_retry() {
  local url="$1"
  local output_file="$2"
  local max_attempts=4
  local attempt=1

  # Codifica l'URL per il proxy
  local encoded_url
  encoded_url=$(echo "$url" | jq -Rr @uri)
  local proxy_url="https://proxy.andybandy.it/?url=${encoded_url}"

  while [ $attempt -le $max_attempts ]; do
    echo "Tentativo $attempt per: $url (tramite proxy)"

    if curl -ksL --max-time 30 --connect-timeout 10 --fail "$proxy_url" \
      -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
      -H 'accept-language: it,en-US;q=0.9,en;q=0.8' \
      -H 'cache-control: no-cache' \
      -H 'pragma: no-cache' \
      -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' \
      > "$output_file"; then
      echo "Download completato con successo al tentativo $attempt"
      return 0
    else
      echo "Tentativo $attempt fallito"
      if [ $attempt -eq $max_attempts ]; then
        echo "ERRORE: Impossibile scaricare $url dopo $max_attempts tentativi"
        exit 1
      fi
      sleep $((attempt * 2))  # Pausa progressiva tra i tentativi
      attempt=$((attempt + 1))
    fi
  done
}


# Scarica la prima pagina per determinare il numero totale di pagine usando la funzione retry
curl_with_retry "https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine=${oggi}&page=0" "$folder/tmp/cgsse/cgsse_page_000.html"

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
  curl_with_retry "https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine=${oggi}&page=$i" "$folder/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html"

  sleep 1  # Pausa di cortesia per evitare sovraccarico del server

  # Estrai i dati dalla pagina HTML usando scrape (XPath) e xq (trasformazione JSON)
  <"$folder"/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html scrape -be '//ul[@class="responsive-table"]/li[@class="table-row views-row"]' | xq -c '[
  .html.body.li[] | {
    data: .div.div[0]."#text",
    settore: .div.div[1]."#text",
    azienda: .div.div[2]."#text",
    sindacato: .div.div[3]."#text",
    ambito_geografico: (
      if .div.div[4]["#text"] then
        .div.div[4]["#text"]
      elif .div.div[4].img["@alt"] == "sciopero nazionale" then
        "NAZIONALE"
      else
        null
      end
    ),
    modalita: .div.div[5].p,
    dettagli_link: (
      .div.div[6].div
      | map(select(has("a")))
      | ("https://www.cgsse.it" + .[0].a["@href"]) // null
    ),
    revocato: (
      .div.div[6].div
      | map(
          if (.img | type) == "array" then
            any(.img[]?; .["@alt"] == "sciopero revocato")
          elif (.img | type) == "object" then
            .img["@alt"] == "sciopero revocato"
          else
            false
          end
        )
      | any
    )
  }
]|.[]' >> "$folder"/tmp/cgsse/cgsse_data.jsonl

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

cp "$folder"/tmp/cgsse/cgsse_data.jsonl "$folder"/../data/cgsse/cgsse_data.jsonl

mlr --ijsonl --ocsv unsparsify "$folder"/../data/cgsse/cgsse_data.jsonl > "$folder"/../data/cgsse/cgsse_data.csv
