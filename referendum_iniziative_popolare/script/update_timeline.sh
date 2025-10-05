#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

git pull

# Clear files from tmp and its subdirectories
find "${folder}"/../data/tmp -type f -delete 2>/dev/null || true

# Check for mode - default to 30 days
MAX_DAYS=30
if [[ "$#" -gt 0 && "$1" == "--all" ]]; then
  MAX_DAYS=999999
fi

# extract historical data from git
datapath="${folder}/../data"
tmppath="${datapath}/tmp/timeline"
mkdir -p "${tmppath}"

repopath="${folder}/../.."
filepath_from_repo_root="referendum_iniziative_popolare/data/referendum_iniziative_popolare.json"
filename="referendum_iniziative_popolare.json"

# Use an array to keep track of processed dates
declare -A seen_dates
processed_days_count=0

# Extract JSON files from git
while IFS= read -r line; do
  hash=$(echo "$line" | awk '{print $1}')
  cdate=$(echo "$line" | awk '{print $2}')
  day=$(echo "$cdate" | cut -d'T' -f1)

  if [[ -z "${seen_dates[${day}]-}" ]]; then
    seen_dates[${day}]=1
    outfile="${tmppath}/${day}_${filename}"
    git -C "${repopath}" show "${hash}:${filepath_from_repo_root}" > "${outfile}"
    processed_days_count=$((processed_days_count + 1))

    echo "Estratto giorno: ${day} (${processed_days_count}/${MAX_DAYS})"

    if [[ $processed_days_count -ge $MAX_DAYS ]]; then
      echo "Raggiunto limite di ${MAX_DAYS} giorni"
      break
    fi
  fi
done < <(git -C "${repopath}" log --pretty=format:'%H %cI' -- "${filepath_from_repo_root}")

# Function to process a single JSON file
process_json() {
  local infile="$1"
  local day=$(basename "$infile" | grep -oP '\d{4}-\d{2}-\d{2}')
  local outfilejsonl="${infile%.json}.jsonl"

  jq -c '.content[]' "${infile}" | mlr --jsonl flatten -s "_" >"${outfilejsonl}"
  mlr -I --jsonl put '$data_download=FILENAME' then put '$data_download=regextract_or_else($data_download,"\d{4}-\d{2}-\d{2}","")' then reorder -e -f data_download "${outfilejsonl}"

  # Remove the original JSON file to save space
  rm -f "${infile}"
}

export -f process_json

# Parallel processing of JSON files with GNU parallel
echo "Processing parallelo di ${processed_days_count} file JSON..."
find "${tmppath}" -name "*.json" -type f | parallel -j+0 --bar process_json {}

# Genera timeline deduplicata con duckdb

echo "Generazione timeline deduplicata..."
duckdb --csv -c "
WITH all_data AS (
  SELECT
    COLUMNS(
      c ->  c NOT ILIKE '%Comitato%'
         AND c NOT ILIKE '%logo%'
         AND c NOT ILIKE '%descrizione%' AND c NOT ILIKE '%quesito%'
    )
  FROM read_json_auto(
         '${tmppath}/*.jsonl',
         union_by_name => true
       )
),
with_hash AS (
  SELECT
    *,
    MD5(CONCAT_WS('||',
      CAST(dataApertura AS VARCHAR), CAST(dataFineRaccolta AS VARCHAR), CAST(estremi AS VARCHAR),
      CAST(id AS VARCHAR), CAST(quorum AS VARCHAR), CAST(sostenitori AS VARCHAR),
      CAST(supportata AS VARCHAR), CAST(titolo AS VARCHAR), CAST(dataUltimoAgg AS VARCHAR),
      CAST(sito AS VARCHAR), CAST(dataInizioRaccolta AS VARCHAR), CAST(dataGazzetta AS VARCHAR)
    )) as row_hash,
    LAG(MD5(CONCAT_WS('||',
      CAST(dataApertura AS VARCHAR), CAST(dataFineRaccolta AS VARCHAR), CAST(estremi AS VARCHAR),
      CAST(id AS VARCHAR), CAST(quorum AS VARCHAR), CAST(sostenitori AS VARCHAR),
      CAST(supportata AS VARCHAR), CAST(titolo AS VARCHAR), CAST(dataUltimoAgg AS VARCHAR),
      CAST(sito AS VARCHAR), CAST(dataInizioRaccolta AS VARCHAR), CAST(dataGazzetta AS VARCHAR)
    ))) OVER (PARTITION BY id ORDER BY data_download) as prev_hash
  FROM all_data
)
SELECT * EXCLUDE (row_hash, prev_hash)
FROM with_hash
WHERE row_hash != prev_hash OR prev_hash IS NULL
ORDER BY data_download, id;
" >"${folder}"/../data/timeline.csv

echo "Timeline generata con successo: ${folder}/../data/timeline.csv"
echo "Giorni processati: ${processed_days_count}"

# Clean up temporary files
echo "Pulizia file temporanei..."
rm -rf "${tmppath}"
echo "File temporanei rimossi"
