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
  curl -skL "${URL_base}${link}" | vd -f html +:table_0:: -b --save-filetype json -o - | mlr -S --ijson --ojsonl clean-whitespace then label struttura,url,n_totale_ivg,n_ivg_farmacologiche,perc_ivg_farmacologiche,perc_ivg_leq_8_sett,perc_ivg_9_10_sett,perc_ivg_11_12_sett,perc_certificazione_consultorio then put '$territorio="'"${regione}"'"' >> "$folder"/../data/punti_ivg_regionali.jsonl
done

# nei numeri rimuovi la "," e metti un . con sed

sed -i -r 's/([0-9]+),([0-9]+)/\1.\2/g;s/#ERR//' "$folder"/../data/punti_ivg_regionali.jsonl

mlr -I -S --jsonl cat -n "$folder"/../data/punti_ivg_regionali.jsonl

mlr --ijsonl --ocsv  cat "$folder"/../data/punti_ivg_regionali.jsonl >"$folder"/../data/punti_ivg_regionali.csv

# aggiungi dati Vittorio
mlr --csv -S join --ul -j n -f "$folder"/../data/punti_ivg_regionali.csv then unsparsify then reorder -f n,struttura,struttura_nome,indirizzo,cap,comune,provincia,regione_pa "$folder"/../risorse/vittorio_light.csv > "$folder"/tmp/punti_ivg_regionali.csv

mv "$folder"/tmp/punti_ivg_regionali.csv "$folder"/../data/punti_ivg_regionali.csv

# aggiungi codice istat comune
mlr --csv --from "$folder"/../data/punti_ivg_regionali.csv cut -f comune,provincia then uniq -a > "$folder"/tmp/comune_provincia.csv

csvmatch "$folder"/tmp/comune_provincia.csv "$folder"/../../risorse/Elenco-comuni-italiani.csv --fields1 comune provincia --fields2 "Denominazione in italiano" "Sigla automobilistica" --fuzzy levenshtein -r 0.9 -i -a -n --join left-outer --output 1.comune 1.provincia 2."Denominazione Regione" 2."Denominazione in italiano" 2."Codice Comune formato alfanumerico" >"$folder"/tmp/comune_provincia_istat.csv

mlr -S -I --csv cut -f comune,provincia,"Codice Comune formato alfanumerico" then label comune,provincia,comune_codice_istat "$folder"/tmp/comune_provincia_istat.csv

mlr -S --csv join --ul -j comune,provincia -f "$folder"/../data/punti_ivg_regionali.csv then unsparsify then sort -t n then reorder -f n,struttura,struttura_nome,indirizzo,cap,comune,provincia,regione_pa "$folder"/tmp/comune_provincia_istat.csv >"$folder"/tmp/punti_ivg_regionali.csv

mlr -I -S --csv sub -a "^-$" "" "$folder"/tmp/punti_ivg_regionali.csv

mv "$folder"/tmp/punti_ivg_regionali.csv "$folder"/../data/punti_ivg_regionali.csv
