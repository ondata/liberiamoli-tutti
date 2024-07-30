#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

# check if I have code 200 from 'https://pnri.firmereferendum.giustizia.it/referendum/api-portal/iniziativa/public'
# if not, exit
curl -s -o /dev/null -w "%{http_code}" https://pnri.firmereferendum.giustizia.it/referendum/api-portal/iniziativa/public | grep 200 || exit 1

# download the json file
curl -s https://pnri.firmereferendum.giustizia.it/referendum/api-portal/iniziativa/public > "${folder}"/../data/referendum_iniziative_popolare.json

<"${folder}"/../data/referendum_iniziative_popolare.json  jq -c '.content[]' > "${folder}"/../data/referendum_iniziative_popolare.jsonl

mlrgo -I --jsonl --from "${folder}"/../data/referendum_iniziative_popolare.jsonl cut -f quorum,sito,sostenitori,supportata,titolo,titoloLeggeCostituzionale,estremi,id,dataApertura,dataFineRaccolta,dataFineValidita,dataGazzetta,dataInizioRaccolta,dataInizioValidita,dataIns,dataUltimoAgg,descrizione then put '$url="https://pnri.firmereferendum.giustizia.it/referendum/open/dettaglio-open/".$id'

# get the current datetime in the format YYYYMMDDHHMMSS ISO8601
datetime=$(date '+%Y-%m-%dT%H:%M:%S')

mlrgo --jsonl cut -f id,sostenitori then put '$datetime="'"$datetime"'"'  then sort -f id,datetime "${folder}"/../data/referendum_iniziative_popolare.jsonl>> "${folder}"/../data/referendum_iniziative_popolare_log.jsonl

mlrgo -I --jsonl uniq -a then sort -n id -t datetime  "${folder}"/../data/referendum_iniziative_popolare_log.jsonl

mlrgo --ijsonl --ocsv cat "${folder}"/../data/referendum_iniziative_popolare_log.jsonl >"${folder}"/../data/referendum_iniziative_popolare_log.csv

mlrgo --csv filter '$id==500020' "${folder}"/../data/referendum_iniziative_popolare_log.csv >"${folder}"/../data/referendum_iniziative_popolare_500020_log.csv
