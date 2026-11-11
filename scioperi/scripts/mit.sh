#!/bin/bash

# Configurazione rigorosa dello script
set -x  # Debug: mostra i comandi eseguiti
set -e  # Interrompe lo script se un comando fallisce
set -u  # Interrompe se viene usata una variabile non definita
set -o pipefail  # Considera fallita una pipeline se uno dei comandi fallisce

# Ottieni il percorso assoluto della cartella dello script
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crea le cartelle di lavoro necessarie
mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/mit
mkdir -p "$folder"/../data/mit

# Elimina tutti i file (non le directory) nella cartella tmp/mit e nelle sue sottocartelle
find "$folder"/tmp/mit -type f -delete

# Parametri per la ricerca degli scioperi: anno corrente e anno precedente
# (anche l'anno chiuso viene riscaricato, per catturare eventuali inserimenti tardivi)
YEAR="$(date +%Y)"
PREV_YEAR=$((YEAR - 1))

# Proxy Cloudflare (Worker con placement a Milano): i runner GitHub non
# raggiungono il sito MIT, mentre dal Worker la POST alla ricerca passa.
PROXY_URL="https://mit-post-proxy.andy-pr.workers.dev/ricerca"

# Scarica la ricerca per un anno dal sito MIT (diretto o via proxy) ed estrae la tabella in JSONL
scarica_mit() {
  local url="$1"
  local anno="$2"
  curl -s --max-time 30 --connect-timeout 10 --fail "$url" \
    -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Origin: https://scioperi.mit.gov.it' \
    -H 'Referer: https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' \
    --data-raw "dataInizio=01/01/${anno}&dataFine=31/12/${anno}&categoria=&sindacato=&settore=0&rilevanza=0&stato=&submit=Ricerca" | \
    scrape -be '//table[@id="ricercaScioperi"]' | \
    xq -c '.html.body.table.tbody.tr[] | {
      stato: (if .td[1] and (.td[1] | type) == "string" and .td[1] != "" then .td[1] else null end),
      inizio: (if .td[2] and (.td[2] | type) == "string" and .td[2] != "" then .td[2] else null end),
      fine: (if .td[3] and (.td[3] | type) == "string" and .td[3] != "" then .td[3] else null end),
      sindacati: (if .td[4] and (.td[4] | type) == "string" and .td[4] != "" then .td[4] else null end),
      settore: (if .td[5] and (.td[5] | type) == "string" and .td[5] != "" then .td[5] else null end),
      categoria: (if .td[6] and (.td[6] | type) == "string" and .td[6] != "" then .td[6] else null end),
      modalita: (if .td[7] and (.td[7] | type) == "string" and .td[7] != "" then .td[7] else null end),
      rilevanza: (if .td[8] and (.td[8] | type) == "string" and .td[8] != "" then .td[8] else null end),
      note: (if .td[9] and (.td[9] | type) == "string" and .td[9] != "" then .td[9] else null end),
      data_proclamazione: (if .td[10] and (.td[10] | type) == "string" and .td[10] != "" then .td[10] else null end),
      regione: (if .td[11] and (.td[11] | type) == "string" and .td[11] != "" then .td[11] else null end),
      provincia: (if .td[12] and (.td[12] | type) == "string" and .td[12] != "" then .td[12] else null end),
      data_ricezione: (if .td[13] and (.td[13] | type) == "string" and .td[13] != "" then .td[13] else null end)
    }' > "$folder"/tmp/mit/mit_data_${anno}.jsonl
}

# Funzione per eseguire il download con retry: prima diretto, poi via proxy
curl_mit_with_retry() {
  local anno="$1"
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "Tentativo $attempt di download dal sito MIT (anno $anno)..."

    if scarica_mit 'https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' "$anno"; then
      echo "Download diretto completato con successo al tentativo $attempt (anno $anno)"
      return 0
    fi

    echo "Tentativo $attempt: download diretto fallito (anno $anno), provo via proxy Cloudflare..."
    if scarica_mit "$PROXY_URL" "$anno"; then
      echo "Download via proxy Cloudflare completato al tentativo $attempt (anno $anno)"
      return 0
    fi

    echo "Tentativo $attempt fallito (diretto e via proxy, anno $anno)"
    if [ $attempt -eq $max_attempts ]; then
      echo "ERRORE: Impossibile raggiungere il sito MIT dopo $max_attempts tentativi (anno $anno)"
      exit 1
    fi
    sleep $((attempt * 2))  # Pausa progressiva tra i tentativi
    attempt=$((attempt + 1))
  done
}

# Per ciascun anno (precedente e corrente): scarico, elaborazione e file dedicato
for ANNO in "$PREV_YEAR" "$YEAR"; do
  curl_mit_with_retry "$ANNO"

  # Converte le date dal formato DD/MM/YYYY al formato ISO YYYY-MM-DD e ordina per data
  mlr -I --jsonl --from "$folder"/tmp/mit/mit_data_${ANNO}.jsonl put 'if (!is_null($inizio)) {$inizio_iso = strftime(strptime($inizio, "%d/%m/%Y"), "%Y-%m-%d")}' then put 'if (!is_null($fine)) {$fine_iso = strftime(strptime($fine, "%d/%m/%Y"), "%Y-%m-%d")}' then sort -tr 'inizio_iso' -t sindacati

  # Copia il file elaborato nella cartella dati finale, con nome per anno
  cp "$folder"/tmp/mit/mit_data_${ANNO}.jsonl "$folder"/../data/mit/mit_data_${ANNO}.jsonl

  # Converte il file JSONL in formato CSV per compatibilità
  mlr --ijsonl --ocsv unsparsify "$folder"/../data/mit/mit_data_${ANNO}.jsonl > "$folder"/../data/mit/mit_data_${ANNO}.csv
done

# File aggregato (anno precedente + anno corrente), ordinato per data di inizio
# (cat e sort in pipeline: in un'unica catena mlr interpretaba l'ultimo campo come nome file)
mlr --jsonl cat "$folder"/tmp/mit/mit_data_${PREV_YEAR}.jsonl "$folder"/tmp/mit/mit_data_${YEAR}.jsonl | \
  mlr --jsonl sort -tr inizio_iso -t sindacati > "$folder"/../data/mit/mit_data.jsonl
mlr --ijsonl --ocsv unsparsify "$folder"/../data/mit/mit_data.jsonl > "$folder"/../data/mit/mit_data.csv
