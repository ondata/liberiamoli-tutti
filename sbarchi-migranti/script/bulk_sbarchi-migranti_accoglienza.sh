#!/bin/bash

set -x
#set -e
#set -u
#set -o pipefail

progetto="sbarchi-migranti"

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/accoglienza
mkdir -p "$folder"/tmp/check
mkdir -p "$folder"/data

# estrai la lista dei file pdf, in cui è presente il dato dei sbarchi giornalieri. Ci sono dal report del 15/10/2019
# rimuovi il report del 15/07/2021, perché il PDF è danneggiato
# rimuovi il dato giornaliero, tieni soltanto i quindicinali
mlrgo --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -0 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

estrai_dati="sì"

if [[ $estrai_dati == "sì" ]]; then
  echo "ok"
  # estrai i dati dai file pdf
  while read -r line; do
    file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
    nome=$(basename "$file" .pdf)
    data=$(echo "$line" | jq -r '.data')
    anno=$(echo "$data" | awk -F- '{print $1}')
    mese=$(echo "$data" | awk -F- '{print $2}')

    # estrai i dati, se non sono già stati estratti
    if [ ! -f "$folder"/../rawdata/csv/accoglienza/"$nome"-accoglienza.csv ]; then

      pagina=$(pdfgrep -n "spot" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq)

      if [[ $pagina =~ ^[0-9]+$ ]]; then
        echo "$file is a number"
        python3 "$folder"/tabelle-accoglienza.py "$folder"/../../"$progetto"/rawdata/pdf/"$file" "$pagina"
      else
        echo "$file is not a number"
      fi
    fi

  done <"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl
else
  echo "non estrarre"
fi

find "$folder"/../rawdata/pdf/ -name "*accoglienza.csv" -exec cp {} "$folder"/tmp/accoglienza \;
find "$folder"/../rawdata/pdf/ -name "*accoglienza.csv" -type f -delete

for file in "$folder"/tmp/accoglienza/*-accoglienza.csv; do

  nome=$(basename "$file" .csv)

  mlrgo -S --csv --implicit-csv-header --headerless-csv-output filter '$4=~"^[^U]"' then put '$f=FILENAME;for (k in $*) {$[k] = gsub($[k], "[*]", "")}' then clean-whitespace then remove-empty-columns then skip-trivial-records "$file" >"$folder"/../rawdata/csv/accoglienza/"$nome".csv
  mlrgo -I -S --csv rename -r ".+crus.+","file" then put '$file=sub($file,".+/","")' then rename -r "Immigrati","Migranti" "$folder"/../rawdata/csv/accoglienza/"$nome".csv
  # correggi errore tabula dei PDF del 31-12-2020 e del 28-02-2022
  if [[ "$file" =~ cruscotto_statistico_giornaliero_31-12-2020_1-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$folder"/../rawdata/csv/accoglienza/"$nome".csv
  fi
  if [[ "$file" =~ cruscotto_statistico_giornaliero_28-02-2022_0-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$folder"/../rawdata/csv/accoglienza/"$nome".csv
  fi
done

# aggiungi data report, rimuovi righe con totale, rimuovi separatore migliaia, rimuovi colonna totale
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
  rename data,Data_Report then \
  cut -x -f file then \
  cut -r -x -f "otale" "$folder"/../rawdata/csv/accoglienza/*-accoglienza.csv >"$folder"/../dati/accoglienza.csv

# estrai in nomi delle regioni presenti nei dati di accoglienza
mlrgo --csv cut -f Regione then uniq -a "$folder"/../dati/accoglienza.csv >"$folder"/tmp/accoglienza_regioni.csv

# associa al nome regione il nome regione ufficiale e il codice regione dell'ISTAT
duckdb -csv -c "SELECT *,LEVENSHTEIN(t1.Regione, t2.DenominazioneRegione) distanza
FROM read_csv_auto('"$folder"/tmp/accoglienza_regioni.csv',header=true) t1
JOIN read_csv_auto('"$folder"/../../risorse/Elenco-regioni.csv',header=true) t2
ON LEVENSHTEIN(t1.Regione, t2.DenominazioneRegione) < 40;" | mlr --csv top --min -a -f distanza -g DenominazioneRegione then cut -x -f distanza >"$folder"/tmp/accoglienza_regioni_stele.csv

# associa ai dati nome regione ufficiale e codice regione dell'ISTAT
mlrgo --csv join --ul -j Regione -f "$folder"/../dati/accoglienza.csv then unsparsify then sort -f Data_Report,Regione "$folder"/tmp/accoglienza_regioni_stele.csv >"$folder"/tmp/tmp-accoglienza.csv

mv "$folder"/tmp/tmp-accoglienza.csv "$folder"/../dati/accoglienza.csv
