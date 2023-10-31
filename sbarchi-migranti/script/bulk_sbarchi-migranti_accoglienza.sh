#!/bin/bash

set -x
#set -e
#set -u
#set -o pipefail

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
  echo "ok"
  # estrai i dati dai file pdf
  while read -r line; do
    file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
    nome=$(echo "$file" | basename -s .pdf)
    data=$(echo "$line" | jq -r '.data')
    anno=$(echo "$data" | awk -F- '{print $1}')
    mese=$(echo "$data" | awk -F- '{print $2}')
    pagina=$(pdfgrep -n "spot" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq)

    if [[ $pagina =~ ^[0-9]+$ ]]; then
      echo "$file is a number"
      python3 "$folder"/tabelle-accoglienza.py "$folder"/../../"$progetto"/rawdata/pdf/"$file" "$pagina"
    else
      echo "$file is not a number"
    fi
  #done < "$folder"/data/tmp.jsonl
  done < "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl
else
  echo "non estrarre"
fi

find "$folder"/nazionalita-accoglienza/process -name "*accoglienza.csv" -type f -delete

find "$folder"/nazionalita-accoglienza -name "*accoglienza.csv" -exec cp {} "$folder"/nazionalita-accoglienza/process \;

# for every file csv thats ends whit accoglienza.csv in "$folder"/nazionalita-accoglienza/process
for file in "$folder"/nazionalita-accoglienza/process/*-accoglienza.csv; do
  echo "$file"
  mlrgo -I -S --csv --implicit-csv-header --headerless-csv-output filter '$4=~"^[^U]"' then put '$f=FILENAME;for (k in $*) {$[k] = gsub($[k], "[*]", "")}' then clean-whitespace then remove-empty-columns then skip-trivial-records "$file"
  mlrgo -I -S --csv rename -r ".+crus.+","file" then put '$file=sub($file,".+/","")' "$file"
  # correggi errore tabula dei PDF del 31-12-2020 e del 28-02-2022
  if [[ "$file" =~ cruscotto_statistico_giornaliero_31-12-2020_1-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$file"
  fi
  if [[ "$file" =~ cruscotto_statistico_giornaliero_28-02-2022_0-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$file"
  fi
done

mlrgo -S --csv unsparsify then cut -x -r -f "percent" then \
put '$data=strftime(strptime(regextract_or_else($file,"([0-9]{2})-([0-9]{2})-([0-9]{4})","30-08-2000"),"%d-%m-%Y"),"%Y-%m-%d")' then \
reorder -e -f file then \
filter -x '$Regione=~"otale"' then \
put '$Regione=sub($Regione,"Trentino.+","Trentino-Alto Adige");$Regione=sub($Regione,"Valle.+","Valle d'\''Aosta");$Regione=gsub($Regione,"\*","")' then \
put 'for (k in $*) {$[k] = gsub($[k], "\.", "")}' then \
sort -f data,Regione then \
rename -r "^Tota.+",Totale then \
reorder -e -f Totale,file then \
reorder -f data then \
put '$file=sub($file,"-accoglienzacsv","")' "$folder"/nazionalita-accoglienza/process/*-accoglienza.csv >"$folder"/accoglienza.csv

exit 0


$data=strftime(strptime(regextract_or_else($file,"([0-9]{2})-([0-9]{2})-([0-9]{4})","30-08-2000"),"%d-%m-%Y"),"%Y-%m-%d")
put '$Regione=sub($Regione,"Trentino.+","Trentino-Alto Adige");$Regione=sub($Regione,"Valle.+","Valle d'Aosta")
put 'for (k in $*) {$[k] = gsub($[k], "\.0$", "")};for (k in $*) {$[k] = gsub($[k], "(\.[0-9]{2})$", "\10")};for (k in $*) {$[k] = gsub($[k], "\.", "")}'
