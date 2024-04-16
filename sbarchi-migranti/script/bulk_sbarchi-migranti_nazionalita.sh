#!/bin/bash

set -x
set -e
set -u
set -o pipefail

progetto="sbarchi-migranti"

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/nazionalita
mkdir -p "$folder"/tmp/check
mkdir -p "$folder"/data


# estrai la lista dei file pdf, in cui è presente il dato dei sbarchi giornalieri. Ci sono dal report del 15/10/2019
# rimuovi il report del 15/07/2021, perché il PDF è danneggiato
# rimuovi la prima riga perché è il dato giornaliero, tieni soltanto i quindicinali
mlrgo --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -0 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl



estrai_dati="sì"

if [[ $estrai_dati == "sì" ]]; then
  # estrai i dati dai file pdf
  while read -r line; do
    file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
    nome=$(basename "$file" .pdf)
    data=$(echo "$line" | jq -r '.data')
    anno=$(echo "$data" | awk -F- '{print $1}')
    mese=$(echo "$data" | awk -F- '{print $2}')

    # estrai i dati, se non sono già stati estratti
    if [ ! -f "$folder"/../rawdata/csv/nazionalita/"$nome"-nazionalita.csv ]; then
      pagina=$(pdfgrep -n "azional" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq | head -n 1)

      # if $pagina is a number echo "is a number" else echo "is not a number"
      if [[ $pagina =~ ^[0-9]+$ ]]; then
        echo "$file is a number"
        python3 "$folder"/tabelle-nazionalita.py "$folder"/../../"$progetto"/rawdata/pdf/"$file" "$pagina"
      else
        echo "$file is not a number"
      fi
    fi

  done < "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl
fi


find "$folder"/../rawdata/pdf/ -name "*nazionalita.csv" -exec cp {} "$folder"/tmp/nazionalita \;

find "$folder"/../rawdata/pdf/ -name "*nazionalita.csv" -type f -delete



# for every file csv thats ends whit nazionalita.csv in "$folder"/nazionalita-accoglienza/process
for file in "$folder"/tmp/nazionalita/*-nazionalita.csv; do
  #echo "$file"
  nome=$(basename "$file")
  mlrgo -S --csv clean-whitespace then remove-empty-columns then skip-trivial-records "$file" >"$folder"/../rawdata/csv/nazionalita/"$nome"
  sed -i '1d' "$folder"/../rawdata/csv/nazionalita/"$nome"
  mlrgo -I -S -N --csv filter -x '$1=~"Tota.+"' then remove-empty-columns then put '$file=strftime(strptime(gsub(regextract(FILENAME,"[0-9]{2}.[0-9]{2}.[0-9]{4}"),"\.","-"),"%d-%m-%Y"),"%Y-%m-%d")' "$folder"/../rawdata/csv/nazionalita/"$nome"
done


mlrgo -S --csv --implicit-csv-header unsparsify then \
remove-empty-columns then \
put 'for (k in $*) {$[k] = gsub($[k], "\.", "")}' then \
label Nazione,Valore,Data_Report then \
reorder -f Data_Report then \
sort -f Data_Report,Nazione "$folder"/../rawdata/csv/nazionalita/*-nazionalita.csv >"$folder"/../dati/nazionalita.csv

# normalizza i nomi delle nazioni
mlrgo --csv join --ul -j Nazione -f "$folder"/../dati/nazionalita.csv then unsparsify then cut -x -f Nazione then reorder -f Data_Report,Nation,ISO_3166-1 then sort -f Data_Report,Nation "$folder"/risorse/nations.csv >"$folder"/../dati/tmp.csv

mv "$folder"/../dati/tmp.csv "$folder"/../dati/nazionalita.csv

mlrgo -I --csv rename Nation,Nazione "$folder"/../dati/nazionalita.csv
