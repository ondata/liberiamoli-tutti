#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
progetto="punti_ivg_regionali"
mkdir -p "$folder"/tmp


URL="https://www.epicentro.iss.it/ivg/progetto-ccm-2022-mappa-punti-ivg"
URL_base="https://www.epicentro.iss.it/ivg/"

# se il file "$folder"/../data/punti_ivg_regionali.jsonl esiste, cancellalo
if [ -f "$folder"/../data/punti_ivg_regionali.jsonl ]; then
  rm "$folder"/../data/punti_ivg_regionali.jsonl
fi

# se URL non risponde esci
curl -skL "${URL}" | scrape -be ".w-100" | xq -c '.html.body.a[]' | while read -r line; do
  # estrai il link
  link=$(echo "$line" | jq -r '."@href"')
  regione=$(echo "$line" | jq -r '."#text"')

  # estrai il nome del file
  nome=$(basename "$link")
  curl -skL "${URL_base}${link}" | vd -f html +:table_0:: -b --save-filetype json -o - | mlr -S --ijson --ojsonl clean-whitespace then label struttura,n_totale_ivg,n_ivg_farmacologiche,perc_ivg_farmacologiche,perc_ivg_leq_8_sett,perc_ivg_9_10_sett,perc_ivg_11_12_sett,perc_certificazione_consultorio then put '$territorio="'"${regione}"'"' >> "$folder"/../data/punti_ivg_regionali.jsonl
done

# nei numeri rimuovi la "," e metti un . con sed

sed -i -r 's/([0-9]+),([0-9]+)/\1.\2/g' "$folder"/../data/punti_ivg_regionali.jsonl

mlr --ijsonl --ocsv  cat "$folder"/../data/punti_ivg_regionali.jsonl >"$folder"/../data/punti_ivg_regionali.csv
