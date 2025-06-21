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

# Parametri per la ricerca degli scioperi (anno corrente)
YEAR=2025
START="01/01/$YEAR"  # Data di inizio ricerca in formato DD/MM/YYYY
END="31/12/$YEAR"    # Data di fine ricerca in formato DD/MM/YYYY

# Funzione per eseguire curl con retry in caso di fallimento
curl_mit_with_retry() {
  local max_attempts=3
  local attempt=1

  while [ $attempt -le $max_attempts ]; do
    echo "Tentativo $attempt di download dal sito MIT..."

    if curl -s --max-time 30 --connect-timeout 10 --fail 'https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' \
      -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
      -H 'Content-Type: application/x-www-form-urlencoded' \
      -H 'Origin: https://scioperi.mit.gov.it' \
      -H 'Referer: https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' \
      --data-raw "dataInizio=${START}&dataFine=${END}&categoria=&sindacato=&settore=0&rilevanza=0&stato=0&submit=Ricerca" | \
      # Estrai la tabella dei risultati usando XPath
      scrape -be '//table[@id="ricercaScioperi"]' | \
      # Converti la tabella HTML in JSON strutturato mappando ogni colonna con controllo dei null
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
    }' > "$folder"/tmp/mit/mit.jsonl; then
      echo "Download completato con successo al tentativo $attempt"
      return 0
    else
      echo "Tentativo $attempt fallito"
      if [ $attempt -eq $max_attempts ]; then
        echo "ERRORE: Impossibile raggiungere il sito MIT dopo $max_attempts tentativi"
        exit 1
      fi
      sleep $((attempt * 2))  # Pausa progressiva tra i tentativi
      attempt=$((attempt + 1))
    fi
  done
}

# Esegui il download dei dati MIT con retry
curl_mit_with_retry

# Elaborazione dei dati con Miller (mlr)
# Converte le date dal formato DD/MM/YYYY al formato ISO YYYY-MM-DD e ordina per data
mlr -I --jsonl --from "$folder"/tmp/mit/mit.jsonl put 'if (!is_null($inizio)) {$inizio_iso = strftime(strptime($inizio, "%d/%m/%Y"), "%Y-%m-%d")}' then put 'if (!is_null($fine)) {$fine_iso = strftime(strptime($fine, "%d/%m/%Y"), "%Y-%m-%d")}' then sort -tr 'inizio_iso' -t sindacati

# Copia il file elaborato nella cartella dati finale
cp "$folder"/tmp/mit/mit.jsonl "$folder"/../data/mit/mit.jsonl

# Converte il file JSONL in formato CSV per compatibilità
mlr --ijsonl --ocsv unsparsify "$folder"/../data/mit/mit.jsonl > "$folder"/../data/mit/mit.csv
