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
      # Converti la tabella HTML in JSON strutturato mappando ogni colonna
      xq -c '.html.body.table.tbody.tr[] | {
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
