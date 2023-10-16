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

# estrai la lista dei file pdf presenti nella pagina
curl -kL "$URL" | scrape -be "//div[contains(@class, 'field-item')]//a[contains(@href, '.pdf')]" | tail -n +2 | xq -c '.html.body.a[]' >"$folder"/data/cruscotto-statistico-giornaliero_lista_raw.jsonl

# aggiungi la data di pubblicazione del report, in formato YYYY-MM-DD. Se non è presente, usa la data di default 30-08-2000
mlrgo --jsonl put '$data=strftime(strptime(regextract_or_else(${@title},"[0-9]{2}-[0-9]{2}-[0-9]{4}","30-08-2000"),"%d-%m-%Y"),"%Y-%m-%d")' "$folder"/data/cruscotto-statistico-giornaliero_lista_raw.jsonl >"$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl

# estrai la lista dei file pdf, in cui è presente il dato dei sbarchi giornalieri. Ci sono dal report del 15/10/2019
# rimuovo il report del 15/07/2021, perché il PDF è danneggiato
mlrgo --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -1 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

# scarica i file pdf, se non sono già presenti
while read -r line; do
  url_file=$(echo "$line" | jq -r '."@href"')
  wget -nc -P "$folder"/../../"$progetto"/rawdata/pdf/ "$url_file"
done < "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

<"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl head -n 5 >"$folder"/data/tmp.jsonl

find "$folder"/tmp/check/ -type f -name '*.html' -exec rm {} \;
find "$folder"/tmp/check/ -type f -name '*.txt' -exec rm {} \;
find "$folder"/data -type f -name '*.csv' -exec rm {} \;

# estrai i dati dai file pdf
while read -r line; do
  file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
  data=$(echo "$line" | jq -r '.data')
  anno=$(echo "$data" | awk -F- '{print $1}')
  mese=$(echo "$data" | awk -F- '{print $2}')
  pagina=$(pdfgrep -n "per giorno" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq)
  pdftohtml -xml -c  -f "$pagina" -l "$pagina" "$folder"/../../"$progetto"/rawdata/pdf/"$file" "$folder"/tmp.xml
  <"$folder"/tmp.xml grep -P '<b>[0-9].*</b>' | sed -r 's/^(.+)<b>([0-9].+?)<\/b>(.+)/\2/g' | tr ' ' '\n' | sed '/^$/d'  >"$folder"/tmp_raw.txt
  cp "$folder"/tmp_raw.txt "$folder"/tmp/check/tmp_raw-"$data".txt
  sed -i -n '1N;$!N;/1\n2\n3/q;P;D' "$folder"/tmp_raw.txt
  # correggi i vari errori dovuti alle stranezze nei PDF, vedi "sbarchi-migranti/note"
  if [ "$data" = "2020-07-15" ]; then
    echo "0" >> "$folder"/tmp_raw.txt
  elif [ "$data" = "2021-07-31" ]; then
    echo "68" >> "$folder"/tmp_raw.txt
  elif [ "$data" = "2021-08-15" ]; then
    echo "0" >> "$folder"/tmp_raw.txt
  elif [ "$data" = "2022-03-15" ]; then
    for i in {1..16}; do
      echo "0" >> "$folder"/tmp_raw.txt
    done
  elif [ "$data" = "2023-07-15" ]; then
    # aggiungi riga vuota alla penultima riga
    sed -i '$i\ ' "$folder"/tmp_raw.txt
    # aggiungi riga vuota alla fine
    echo "" >> "$folder"/tmp_raw.txt
  elif [ "$data" = "2023-08-15" ]; then
    # rimuovi ultime due righe e poi aggiungi riga vuota e due zeri
    head -n -2 "$folder"/tmp_raw.txt > "$folder"/tmp_raw2.txt
    mv "$folder"/tmp_raw2.txt "$folder"/tmp_raw.txt
    echo -e "" >> "$folder"/tmp_raw.txt
    echo -e "0" >> "$folder"/tmp_raw.txt
    echo -e "0" >> "$folder"/tmp_raw.txt
  elif [ "$data" = "2023-06-30" ]; then
    # aggiungi riga vuota alla penultima riga
    sed -i '$i\ ' "$folder"/tmp_raw.txt
  fi
  mlrgo --csv --implicit-csv-header cat -n then label Data,Valore then clean-whitespace then \
  put '$Valore=gsub(string($Valore),"\.","")' then \
  put '$Data=fmtnum($Data,"%02d")' then \
  put '$Data="'"$anno"'"."-"."'"$mese"'"."-".string($Data)' then \
  put '$Note="*I dati si riferiscono agli eventi di sbarco rilevati entro le ore 8:00 del giorno di riferimento"' then \
  put '$Fonte="Fonte: Dipartimento della Pubblica sicurezza. I dati sono suscettibili di successivo consolidamento."' then \
  put '$Data_Report="'"$data"'"' "$folder"/tmp_raw.txt >"$folder"/data/"$data"_migranti_sbarcati_per_giorno.csv
  if [ "$data" = "2022-12-31" ]; then
    mlrgo -I --csv put '$Note="*I dati si riferiscono agli eventi di sbarco rilevati entro le ore 24:00 del giorno di riferimento"' "$folder"/data/"$data"_migranti_sbarcati_per_giorno.csv
  elif [ "$data" = "2023-06-30" ]; then
    mlrgo -I --csv put 'if($Data=="2023-06-29"){$Valore=2307}else{$Valore=$Valore}' "$folder"/data/"$data"_migranti_sbarcati_per_giorno.csv
  fi
  # check
  # daff --output "$folder"/tmp/check/"$data".html ../rawdata/csv/"$data"_migranti_sbarcati_per_giorno.csv "$folder"/data/"$data"_migranti_sbarcati_per_giorno.csv
done < "$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

find "$folder" -type f -name 'tmp*.png' -exec rm {} \;

## errori da correggere, per stranezze dei PDF, con giorni in più rispetto al mese
mlr -I --csv head -n 29 "$folder"/data/2020-02-15_migranti_sbarcati_per_giorno.csv
mlr -I --csv head -n 30 "$folder"/data/2020-09-15_migranti_sbarcati_per_giorno.csv
mlr -I --csv head -n 30 "$folder"/data/2023-04-15_migranti_sbarcati_per_giorno.csv

# check giorni mese
mlr --csv put '$mese=strftime(strptime($Data,"%Y-%m-%d"),"%m");$anno=strftime(strptime($Data,"%Y-%m-%d"),"%Y")' then cut -f Data_Report,mese,anno then count-similar -g Data_Report,mese then uniq -a then sort -f Data_Report "$folder"/data/*_migranti_sbarcati_per_giorno.csv >"$folder"/tmp/tmp_all.csv

mlr --csv join --ul --np -j anno,mese,count -f "$folder"/tmp/tmp_all.csv then unsparsify "$folder"/risorse/anagrafica_anni_mesi.csv > "$folder"/tmp/errori_giorni_mese.csv
