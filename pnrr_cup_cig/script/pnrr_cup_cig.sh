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

# Crea le directory necessarie se non esistono
mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

# Log persistente delle cause di aggiornamento/fallimento
log_file="${folder}/../data/update_log.jsonl"
LAST_ERROR_LOGGED=false

json_escape() {
    local value="${1:-}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/}"
    printf '%s' "$value"
}

log_event() {
    local status="${1:-}"
    local stage="${2:-}"
    local source="${3:-}"
    local url="${4:-}"
    local http_code="${5:-}"
    local exit_code="${6:-}"
    local message="${7:-}"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    printf '{"timestamp":"%s","status":"%s","stage":"%s","source":"%s","url":"%s","http_code":"%s","exit_code":"%s","message":"%s","github_run_id":"%s","github_run_attempt":"%s","github_sha":"%s"}\n' \
        "$(json_escape "$timestamp")" \
        "$(json_escape "$status")" \
        "$(json_escape "$stage")" \
        "$(json_escape "$source")" \
        "$(json_escape "$url")" \
        "$(json_escape "$http_code")" \
        "$(json_escape "$exit_code")" \
        "$(json_escape "$message")" \
        "$(json_escape "${GITHUB_RUN_ID:-}")" \
        "$(json_escape "${GITHUB_RUN_ATTEMPT:-}")" \
        "$(json_escape "${GITHUB_SHA:-}")" >> "$log_file"
}

log_unhandled_error() {
    local exit_code="$1"
    local line="$2"
    if [ "$LAST_ERROR_LOGGED" != true ]; then
        log_event "error" "script" "pnrr_cup_cig" "" "" "$exit_code" "Script failed at line ${line}"
    fi
}

trap 'exit_code=$?; line=$LINENO; log_unhandled_error "$exit_code" "$line"' ERR

# URLs dei dataset
cup_cig_anac="https://dati.anticorruzione.it/opendata/download/dataset/cup/filesystem/cup_csv.zip"
progetti_pnrr="https://proxy.andybandy.it/?url=https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Progetti.csv"
gare_pnrr="https://proxy.andybandy.it/?url=https://www.italiadomani.gov.it/content/dam/sogei-ng/opendata/PNRR_Gare.csv"
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36"

# Funzione per verificare URL (usa GET leggera, non bloccante)
check_url() {
    local source="$1"
    local url="$2"
    local http_code
    local exit_code

    echo "Controllo URL: $url"
    set +e
    http_code="$(curl --retry 5 --retry-delay 3 --fail -s -L -o /dev/null -w "%{http_code}" "$url")"
    exit_code=$?
    set -e
    if [ "$exit_code" -ne 0 ]; then
        log_event "warning" "precheck" "$source" "$url" "$http_code" "$exit_code" "URL precheck failed"
    fi
}

download_with_curl() {
    local source="$1"
    local url="$2"
    local output="$3"
    local stderr_file="${folder}/tmp/${source}.curl.stderr.log"
    local http_code
    local exit_code
    local message

    set +e
    http_code="$(curl --retry 5 --retry-delay 3 --fail -sS -L -A "$user_agent" -o "$output" -w "%{http_code}" "$url" 2>"$stderr_file")"
    exit_code=$?
    set -e

    if [ "$exit_code" -ne 0 ]; then
        message="$(tail -n 20 "$stderr_file" | tr '\n' ' ')"
        log_event "error" "download" "$source" "$url" "$http_code" "$exit_code" "$message"
        LAST_ERROR_LOGGED=true
        return "$exit_code"
    fi

    if [ ! -s "$output" ]; then
        log_event "error" "download" "$source" "$url" "$http_code" "0" "Downloaded file is empty"
        LAST_ERROR_LOGGED=true
        return 1
    fi
}

download_with_wget() {
    local source="$1"
    local url="$2"
    local output="$3"
    local stderr_file="${folder}/tmp/${source}.wget.stderr.log"
    local http_code
    local exit_code
    local message

    set +e
    wget --no-check-certificate --server-response -O "$output" "$url" 2>"$stderr_file"
    exit_code=$?
    set -e

    http_code="$(awk '/^  HTTP\// {code=$2} END {print code}' "$stderr_file")"
    if [ "$exit_code" -ne 0 ]; then
        message="$(tail -n 20 "$stderr_file" | tr '\n' ' ')"
        log_event "error" "download" "$source" "$url" "$http_code" "$exit_code" "$message"
        LAST_ERROR_LOGGED=true
        return "$exit_code"
    fi

    if [ ! -s "$output" ]; then
        log_event "error" "download" "$source" "$url" "$http_code" "0" "Downloaded file is empty"
        LAST_ERROR_LOGGED=true
        return 1
    fi
}

# Verifica gli URL prima di procedere
check_url "italiadomani_progetti" "${progetti_pnrr}"
check_url "italiadomani_gare" "${gare_pnrr}"
check_url "anac_cup_zip" "${cup_cig_anac}"

# Svuota la cartella tmp se l'opzione -k non è stata specificata
if [ "$CLEAN_TMP" = true ]; then
  rm -f "${folder}"/tmp/*
fi

DOWNLOAD_FAILED=false

# Scarica i progetti PNRR solo se non esistono già
if [ -f "${folder}"/tmp/PNRR_Progetti.csv ]; then
  echo "File PNRR_Progetti.csv già esistente, salto il download."
else
  if ! download_with_curl "italiadomani_progetti" "${progetti_pnrr}" "${folder}"/tmp/PNRR_Progetti.csv; then
    DOWNLOAD_FAILED=true
  fi
fi

# Scarica le gare PNRR solo se non esistono già
if [ -f "${folder}"/tmp/PNRR_Gare.csv ]; then
  echo "File PNRR_Gare.csv già esistente, salto il download."
else
  if ! download_with_curl "italiadomani_gare" "${gare_pnrr}" "${folder}"/tmp/PNRR_Gare.csv; then
    DOWNLOAD_FAILED=true
  fi
fi

# Scarica e estrai i dati ANAC solo se non esistono già
if [ -f "${folder}"/tmp/cup_csv.zip ]; then
  echo "File cup_csv.zip già esistente, salto il download."
else
  if ! download_with_wget "anac_cup_zip" "${cup_cig_anac}" "${folder}"/tmp/cup_csv.zip; then
    DOWNLOAD_FAILED=true
  elif ! unzip -o "${folder}"/tmp/cup_csv.zip -d "${folder}"/tmp; then
    log_event "error" "extract" "anac_cup_zip" "${cup_cig_anac}" "" "1" "Unable to unzip cup_csv.zip"
    LAST_ERROR_LOGGED=true
    exit 1
  fi
fi

if [ "$DOWNLOAD_FAILED" = true ]; then
  exit 1
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

# Verifica dimensione file di output
check_file_size() {
    local file=$1
    local min_lines=2000
    local lines=$(wc -l < "$file")
    if [ "$lines" -lt "$min_lines" ]; then
        echo "ERRORE: Il file $file ha meno di $min_lines righe ($lines righe)"
        exit 1
    fi
}

# Dopo la creazione dei file CSV, verifica le loro dimensioni
check_file_size "${folder}"/../data/cup_cig_anac_pnrr.csv
check_file_size "${folder}"/../data/cup_cig_anac_pnrr_merge.csv

# Pulisci i file temporanei alla fine solo se CLEAN_TMP è true
if [ "$CLEAN_TMP" = true ]; then
  rm -f "${folder}"/tmp/*
fi

log_event "success" "script" "pnrr_cup_cig" "" "" "0" "Update completed"
