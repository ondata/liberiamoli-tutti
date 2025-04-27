#!/bin/bash

# Imposta le opzioni di bash per una maggiore sicurezza e debugging
set -x # Stampa i comandi mentre vengono eseguiti
set -e # Esce se un comando fallisce
set -u # Esce se viene usata una variabile non definita
set -o pipefail # Esce se un comando in una pipeline fallisce

# Gestione dell'opzione per non svuotare la cartella tmp
CLEAN_TMP=true
while getopts ":k" opt; do
  case $opt in
    k) # -k mantiene i file temporanei
      CLEAN_TMP=false
      ;;
    \?)
      echo "Opzione non valida: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Ottiene il percorso assoluto della directory dello script
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# URLs dei dataset
cup_cig_anac="https://dati.anticorruzione.it/opendata/download/dataset/cup/filesystem/cup_csv.zip"
progetti_pnrr="https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Progetti.csv"
gare_pnrr="https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Gare.csv"

# Crea le directory necessarie se non esistono
mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

# Svuota la cartella tmp se l'opzione -k non è stata specificata
if [ "$CLEAN_TMP" = true ]; then
  rm -f "${folder}"/tmp/*
fi

# Scarica e estrai i dati ANAC solo se non esistono già
if [ -f "${folder}"/tmp/cup_csv.zip ]; then
  echo "File cup_csv.zip già esistente, salto il download."
else
  wget -O "${folder}"/tmp/cup_csv.zip "${cup_cig_anac}"
  unzip -o "${folder}"/tmp/cup_csv.zip -d "${folder}"/tmp
fi

# Scarica i progetti PNRR solo se non esistono già
if [ -f "${folder}"/tmp/PNRR_Progetti.csv ]; then
  echo "File PNRR_Progetti.csv già esistente, salto il download."
else
  curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" -L -o "${folder}"/tmp/PNRR_Progetti.csv "${progetti_pnrr}"
fi

# Scarica le gare PNRR solo se non esistono già
if [ -f "${folder}"/tmp/PNRR_Gare.csv ]; then
  echo "File PNRR_Gare.csv già esistente, salto il download."
else
  curl -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36" -L -o "${folder}"/tmp/PNRR_Gare.csv "${gare_pnrr}"
fi

# Estrai CUP e CIG dai progetti PNRR incrociati con i dati ANAC
duckdb --csv -c "SELECT DISTINCT pnrr.CUP, cup.CIG
FROM read_csv('${folder}/tmp/PNRR_Progetti.csv',header=true) AS pnrr
JOIN read_csv('${folder}/tmp/cup_csv.csv',header=true) AS cup
ON pnrr.CUP = cup.CUP
ORDER BY pnrr.CUP, cup.CIG" >"${folder}"/../data/cup_cig_anac_pnrr.csv

# Crea una versione parquet del file per una migliore efficienza
duckdb -c "copy (select * from read_csv('${folder}/../data/cup_cig_anac_pnrr.csv',sample_size=-1)) TO '${folder}/../data/cup_cig_anac_pnrr.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', ROW_GROUP_SIZE 100_000)"

# Estrai i CUP presenti nel file gare PNRR ma non presenti nei dati ANAC
duckdb --csv -c "SELECT DISTINCT pnrr.CUP,pnrr.CIG,pnrr.\"CIG Accordo Quadro\" CIG_Accordo_Quadro
FROM read_csv('${folder}/tmp/PNRR_Gare.csv') AS pnrr
LEFT JOIN read_csv('${folder}/tmp/cup_csv.csv') AS cup
ON pnrr.CUP = cup.CUP
WHERE cup.CUP IS NULL
ORDER BY pnrr.CUP" >"${folder}"/../data/cup_cig_pnrr_no-anac.csv.csv

# Aggiungi la fonte ai dati e unisci i dataset
mlr --csv put '$fonte="italiadomani"' "${folder}"/../data/cup_cig_pnrr_no-anac.csv.csv >"${folder}"/tmp/id.csv
mlr --csv put '$fonte="anac"' "${folder}"/../data/cup_cig_anac_pnrr.csv >"${folder}"/tmp/anac.csv

# Crea il dataset finale filtrato e ordinato
mlr --csv unsparsify then cut -f CUP,CIG,fonte then sort -f CUP,CIG then filter '$CIG=~".+"' then filter -x '$CUP=="N/A" || $CIG=="NULL"' "${folder}"/tmp/id.csv "${folder}"/tmp/anac.csv > "${folder}"/../data/cup_cig_anac_pnrr_merge.csv

# Pulisci i file temporanei alla fine solo se CLEAN_TMP è true
if [ "$CLEAN_TMP" = true ]; then
  rm -f "${folder}"/tmp/*
fi
