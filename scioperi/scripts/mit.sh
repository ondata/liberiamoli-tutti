#!/bin/bash

# Configurazione rigorosa dello script
set -x  # Debug: mostra i comandi eseguiti
set -e  # Interrompe lo script se un comando fallisce
set -u  # Interrompe se viene usata una variabile non definita
set -o pipefail  # Considera fallita una pipeline se uno dei comandi fallisce

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/mit
mkdir -p "$folder"/../data/mit
# Elimina tutti i file (non le directory) nella cartella tmp/mit e nelle sue sottocartelle
find "$folder"/tmp/mit -type f -delete

YEAR=2025
START="01/01/$YEAR"
END="31/12/$YEAR"

curl 'https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://scioperi.mit.gov.it' -H 'Referer: https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca' --data-raw "dataInizio=${START}&dataFine=${END}&categoria=&sindacato=&settore=0&rilevanza=0&stato=0&submit=Ricerca" | scrape -be '//table[@id="ricercaScioperi"]' | scrape -be "//table[@id='ricercaScioperi']" | xq -c '.html.body.table.tbody.tr[] | {
  stato: .td[1],
  inizio: .td[2],
  fine: .td[3],
  sindacati: .td[4],
  settore: .td[5],
  categoria: .td[6],
  modalita: .td[7],
  rilevanza: .td[8],
  note: .td[9],
  data_proclamazione: .td[10],
  regione: .td[11],
  provincia: .td[12],
  data_ricezione: .td[13]
}' > "$folder"/tmp/mit/mit.jsonl

mlr -I --jsonl --from "$folder"/tmp/mit/mit.jsonl put 'if (!is_null($inizio)) {$inizio_iso = strftime(strptime($inizio, "%d/%m/%Y"), "%Y-%m-%d")}' then put 'if (!is_null($fine)) {$fine_iso = strftime(strptime($fine, "%d/%m/%Y"), "%Y-%m-%d")}' then sort -tr 'inizio_iso' -t sindacati

cp "$folder"/tmp/mit/mit.jsonl "$folder"/../data/mit/mit.jsonl

mlr --ijsonl --ocsv unsparsify "$folder"/../data/mit/mit.jsonl > "$folder"/../data/mit/mit.csv
