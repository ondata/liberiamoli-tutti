#!/bin/bash

# Enable debug mode to print commands as they are executed
set -x
#set -e
#set -u
#set -o pipefail

# Set project name
progetto="sbarchi-migranti"

# Get the directory where the script is located
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create necessary directory structure
mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/accoglienza
mkdir -p "$folder"/tmp/check
mkdir -p "$folder"/data

# Filter the list of PDF files containing daily landing data since 15/10/2019
# Remove the report from 15/07/2021 (damaged PDF)
# Keep only bi-weekly reports
mlrgo --jsonl filter '$data>"2019-09-16"' then filter -x '$data=="2021-07-15"' then sort -f data "$folder"/data/cruscotto-statistico-giornaliero_lista.jsonl | head -n -0 >"$folder"/data/cruscotto-statistico-giornaliero_lista_dati_giornalieri.jsonl

# Flag to control data extraction
estrai_dati="sì"

if [[ $estrai_dati == "sì" ]]; then
  echo "ok"
  # Extract data from PDF files
  while read -r line; do
    # Extract file information and create date components
    file=$(echo "$line" | jq -r '."@href"' | sed -r 's|.+allegati/||')
    nome=$(basename "$file" .pdf)

    # Skip processing for the specific PDF file
    if [[ "$nome" == "cruscotto_statistico_giornaliero_28-02-2022_1" ]]; then
      echo "Skipping $nome.pdf as requested"
      continue
    fi

    data=$(echo "$line" | jq -r '.data')
    anno=$(echo "$data" | awk -F- '{print $1}')
    mese=$(echo "$data" | awk -F- '{print $2}')

    # Process PDF only if data hasn't been extracted yet
    if [ ! -f "$folder"/../rawdata/csv/accoglienza/"$nome"-accoglienza.csv ]; then
      # Find page containing "spot" keyword
      pagina=$(pdfgrep -n "spot" "$folder"/../../"$progetto"/rawdata/pdf/"$file" | awk -F: '{print $1}' | sort | uniq)

      # Process only if page number is valid
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

# Move and cleanup CSV files
find "$folder"/../rawdata/pdf/ -name "*accoglienza.csv" -exec cp {} "$folder"/tmp/accoglienza \;
find "$folder"/../rawdata/pdf/ -name "*accoglienza.csv" -type f -delete

# Process each CSV file
for file in "$folder"/tmp/accoglienza/*-accoglienza.csv; do
  nome=$(basename "$file" .csv)

  # Clean and format CSV data
  mlrgo -S --csv --implicit-csv-header --headerless-csv-output filter '$4=~"^[^U]"' then put '$f=FILENAME;for (k in $*) {$[k] = gsub($[k], "[*]", "")}' then clean-whitespace then remove-empty-columns then skip-trivial-records "$file" >"$folder"/../rawdata/csv/accoglienza/"$nome".csv
  mlrgo -I -S --csv rename -r ".+crus.+","file" then put '$file=sub($file,".+/","")' then rename -r "Immigrati","Migranti" then rename -r "immigrati","migranti" then rename -r "hotspot","hot spot" "$folder"/../rawdata/csv/accoglienza/"$nome".csv

  # Fix specific data issues for certain dates
  if [[ "$file" =~ cruscotto_statistico_giornaliero_31-12-2020_1-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$folder"/../rawdata/csv/accoglienza/"$nome".csv
  fi
  if [[ "$file" =~ cruscotto_statistico_giornaliero_28-02-2022_0-accoglienza.csv ]]; then
    sed -i -r 's/tirol,/tirol,,/;s/oste,/oste,,/;s/,,c/,c/' "$folder"/../rawdata/csv/accoglienza/"$nome".csv
  fi
done

# Consolidate and format final dataset
# - Remove percentage columns
# - Add report date
# - Remove total rows
# - Clean up region names
# - Remove thousand separators
# - Sort and reorganize columns
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

# Extract unique region names
mlrgo --csv cut -f Regione then uniq -a "$folder"/../dati/accoglienza.csv >"$folder"/tmp/accoglienza_regioni.csv

# Match region names with official ISTAT names using Levenshtein distance
duckdb -csv -c "SELECT *,LEVENSHTEIN(t1.Regione, t2.DenominazioneRegione) distanza
FROM read_csv_auto('"$folder"/tmp/accoglienza_regioni.csv',header=true) t1
JOIN read_csv_auto('"$folder"/../../risorse/Elenco-regioni.csv',header=true) t2
ON LEVENSHTEIN(t1.Regione, t2.DenominazioneRegione) < 40;" | mlr --csv top --min -a -f distanza -g DenominazioneRegione then cut -x -f distanza >"$folder"/tmp/accoglienza_regioni_stele.csv

# Join data with official region names and codes
mlrgo --csv join --ul -j Regione -f "$folder"/../dati/accoglienza.csv then unsparsify then sort -f Data_Report,Regione "$folder"/tmp/accoglienza_regioni_stele.csv >"$folder"/tmp/tmp-accoglienza.csv

# Move final result to destination
mv "$folder"/tmp/tmp-accoglienza.csv "$folder"/../dati/accoglienza.csv

mlrgo -I --csv --from "$folder"/../dati/accoglienza.csv filter -x '$Data_Report=="2000-08-30"'

mlr -I --csv uniq -a then sort -t Data_Report,Regione "$folder"/../dati/accoglienza.csv
