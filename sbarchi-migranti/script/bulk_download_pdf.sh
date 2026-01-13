#!/bin/bash

set -x
set -e
set -u
set -o pipefail

progetto="sbarchi-migranti"

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/check
mkdir -p "$folder"/data

URL="https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero"
BASE_URL="https://libertaciviliimmigrazione.dlci.interno.gov.it"

# se URL non risponde esci
curl -kL -s -f -o /dev/null "$URL" || exit 0

# estrai la lista dei file pdf presenti nella pagina
curl -kL "$URL" | scrape -be "//div[contains(@class, 'file--application-pdf')]//a[contains(@href, '.pdf')]" | xq -c '.html.body.a[]' | tail -n +2 >"$folder"/data/cruscotto-statistico-giornaliero_lista_raw.jsonl

# aggiungi la data di pubblicazione del report, in formato YYYY-MM-DD. Se non è presente, usa la data di default 30-08-2000
# rimuovi file pdf del giorno, mantieni soltanto i quindicinali

mlr -I -S --jsonl sub -f "@title" "([0-9]{2})\.([0-9]{2})\.([0-9]{4})" "\1-\2-\3" "$folder"/data/cruscotto-statistico-giornaliero_lista_raw.jsonl

mlr --jsonl put '$data=strftime(strptime(regextract_or_else(${@title},"[0-9]{2}-[0-9]{2}-[0-9]{4}","30-08-2000"),"%d-%m-%Y"),"%Y-%m-%d")' "$folder"/data/cruscotto-statistico-giornaliero_lista_raw.jsonl >"$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl

# estrai la lista dei file pdf, in cui è presente il dato dei sbarchi giornalieri. Ci sono dal report del 15/10/2019
# rimuovi il report del 15/07/2021, perché il PDF è danneggiato
# rimuovi la prima riga perché è quella del giorno. Teniamo soltanto i dati quindicinali
mlr --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -0 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

# scarica i file pdf, se non sono già presenti
while read -r line; do
  url_file=$(echo "$line" | jq -r '."@href"')
  # se url_file inizia con /, aggiungi BASE_URL
  if [[ "$url_file" =~ ^/ ]]; then
    url_file="$BASE_URL$url_file"
  fi
  wget -nc -P "$folder"/../../"$progetto"/rawdata/pdf/ "$url_file"
done <"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

# crea anagrafica dei report
mlr --ijsonl --ocsv cut -f "@href","data" then label URL,Data_Report then reorder -f Data_Report,URL then sort -f Data_Report "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl >"$folder"/../dati/anagrafica-report.csv
