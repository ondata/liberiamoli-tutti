#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cup_cig_anac="https://dati.anticorruzione.it/opendata/download/dataset/cup/filesystem/cup_csv.zip"

progetti_pnrr="https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Progetti.csv"

gare_pnrr="https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Gare.csv"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

# svuota la cartella tmp
rm -f "${folder}"/tmp/*

# scarica i file in tmp
# se il file esiste già non lo scarica
if [ -f "${folder}"/tmp/cup_csv.zip ]; then
  echo "File cup_csv.zip already exists, skipping download."
else
  wget -O "${folder}"/tmp/cup_csv.zip "${cup_cig_anac}"
  unzip -o "${folder}"/tmp/cup_csv.zip -d "${folder}"/tmp
fi

# se il file esiste già non lo scarica
if [ -f "${folder}"/tmp/PNRR_Progetti.csv ]; then
  echo "File PNRR_Progetti.csv already exists, skipping download."
else
  wget -O "${folder}"/tmp/PNRR_Progetti.csv "${progetti_pnrr}"
fi

# se il file esiste già non lo scarica
if [ -f "${folder}"/tmp/PNRR_Gare.csv ]; then
  echo "File PNRR_Gare.csv already exists, skipping download."
else
  wget -O "${folder}"/tmp/PNRR_Gare.csv "${gare_pnrr}"
fi

# Estrai la colonna CUP di PNRR_Progetti.csv, e fai il join con la colonna CUP di cup_csv.csv, ed estrai soltanto CUP e CIG
duckdb --csv -c "SELECT DISTINCT pnrr.CUP, cup.CIG
FROM read_csv('${folder}/tmp/PNRR_Progetti.csv') AS pnrr
JOIN read_csv('${folder}/tmp/cup_csv.csv') AS cup
ON pnrr.CUP = cup.CUP
ORDER BY pnrr.CUP, cup.CIG" >"${folder}"/../data/cup_cig_anac_pnrr.csv

# crea anche versione parquet
duckdb -c "copy (select * from read_csv('${folder}/../data/cup_cig_anac_pnrr.csv',sample_size=-1)) TO '${folder}/../data/cup_cig_anac_pnrr.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', ROW_GROUP_SIZE 100_000)"

# estrai tutti i CUP present nel file PNRR_Gare.csv, non presenti in cup_csv.csv
duckdb --csv -c "SELECT DISTINCT pnrr.CUP,pnrr.CIG,pnrr.\"CIG Accordo Quadro\" CIG_Accordo_Quadro
FROM read_csv('${folder}/tmp/PNRR_Gare.csv') AS pnrr
LEFT JOIN read_csv('${folder}/tmp/cup_csv.csv') AS cup
ON pnrr.CUP = cup.CUP
WHERE cup.CUP IS NULL
ORDER BY pnrr.CUP" >"${folder}"/../data/cup_cig_pnrr_no-anac.csv.csv

mlr --csv put '$fonte="italiadomani"' "${folder}"/../data/cup_cig_pnrr_no-anac.csv.csv >"${folder}"/tmp/id.csv

mlr --csv put '$fonte="anac"' "${folder}"/../data/cup_cig_anac_pnrr.csv >"${folder}"/tmp/anac.csv

mlr --csv unsparsify then cut -f CUP,CIG,fonte then sort -f CUP,CIG then filter '$CIG=~".+"' then filter -x '$CUP=="N/A" || $CIG=="NULL"' "${folder}"/tmp/id.csv "${folder}"/tmp/anac.csv > "${folder}"/../data/cup_cig_anac_pnrr_merge.csv

rm -f "${folder}"/tmp/*
