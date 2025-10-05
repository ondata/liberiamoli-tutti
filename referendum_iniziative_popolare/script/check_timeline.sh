#!/bin/bash

# Script per verificare lo stato della timeline

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
datapath="${folder}/../data"

echo "=== Stato Timeline ==="
echo

if [[ -f "${datapath}/timeline.csv" ]]; then
  csv_lines=$(wc -l < "${datapath}/timeline.csv")
  csv_size=$(ls -lh "${datapath}/timeline.csv" | awk '{print $5}')
  csv_date=$(ls -l "${datapath}/timeline.csv" | awk '{print $6, $7, $8}')
  echo "Timeline CSV (deduplicata): ${csv_lines} righe, ${csv_size}"
  echo "Ultima modifica: ${csv_date}"
  echo
  
  # Mostra range date
  first_date=$(mlr --csv cut -f data_download "${datapath}/timeline.csv" | tail -n +2 | head -1)
  last_date=$(mlr --csv cut -f data_download "${datapath}/timeline.csv" | tail -1)
  echo "Prima data: ${first_date}"
  echo "Ultima data: ${last_date}"
else
  echo "File timeline.csv non trovato"
fi

echo
echo "=== Fine ==="
