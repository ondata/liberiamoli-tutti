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

URL="http://www.libertaciviliimmigrazione.dlci.interno.gov.it/it/documentazione/statistica/cruscotto-statistico-giornaliero"

# estrai la lista dei file pdf, in cui è presente il dato dei sbarchi giornalieri. Ci sono dal report del 15/10/2019
# rimuovo il report del 15/07/2021, perché il PDF è danneggiato
mlrgo --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -1 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl


<"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl head -n 5 >"$folder"/data/tmp.jsonl

estrai_dati="no"

if [[ $estrai_dati == "sì" ]]; then
  # estrai i dati dai file pdf
  while read -r line; do
    file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
    data=$(echo "$line" | jq -r '.data')
    anno=$(echo "$data" | awk -F- '{print $1}')
    mese=$(echo "$data" | awk -F- '{print $2}')
    pagina=$(pdfgrep -n "azional" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq | head -n 1)
    # if $pagina is a number echo "is a number" else echo "is not a number"
    if [[ $pagina =~ ^[0-9]+$ ]]; then
      echo "$file is a number"
      python3 "$folder"/tabelle-nazionalita.py "$folder"/../../"$progetto"/rawdata/pdf/"$file" "$pagina"
    else
      echo "$file is not a number"
    fi
  done < "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl
fi

find "$folder"/nazionalita-accoglienza/process -name "*nazionalita.csv" -type f -delete

find "$folder"/nazionalita-accoglienza -name "*nazionalita.csv" -exec cp {} "$folder"/nazionalita-accoglienza/process \;

# for every file csv thats ends whit nazionalita.csv in "$folder"/nazionalita-accoglienza/process
for file in "$folder"/nazionalita-accoglienza/process/*-nazionalita.csv; do
  echo "$file"
  mlrgo -I -S --csv clean-whitespace then remove-empty-columns then skip-trivial-records "$file"
  sed -i '1d' "$file"
  mlrgo -I -S -N --csv filter -x '$1=~"Tota.+"' then remove-empty-columns then put '$file=FILENAME' "$file"
done

mlrgo -S --csv --implicit-csv-header unsparsify then \
remove-empty-columns then \
put 'for (k in $*) {$[k] = gsub($[k], "\.", "")}' then \
label Nazione,Valore,file then \
put '$file=sub($file,".+/","");$file=sub($file,"-nazionalitacsv","")' then \
put '$data=strftime(strptime(regextract_or_else($file,"([0-9]{2})-([0-9]{2})-([0-9]{4})","30-08-2000"),"%d-%m-%Y"),"%Y-%m-%d")' then \
reorder -f data then \
sort -f data,Nazione "$folder"/nazionalita-accoglienza/process/*-nazionalita.csv >"$folder"/nazionalita.csv

exit 0

# normalizza i nomi delle nazioni
mlrgo --csv join --ul -j Nazione -f "$folder"/../dati/nazionalita.csv then unsparsify then cut -x -f Nazione then reorder -f data,Nation,ISO_3166-1 then sort -f data,Nation "$folder"/risorse/nations.csv >"$folder"/../dati/tmp.csv
mv "$folder"/../dati/tmp.csv "$folder"/../dati/nazionalita.csv
