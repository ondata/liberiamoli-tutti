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
curl -s -o /dev/null -w "%{http_code}" https://firmereferendum.giustizia.it/referendum/api-portal/iniziativa/public | grep 200 || exit 1



# download the json file
curl -s https://firmereferendum.giustizia.it/referendum/api-portal/iniziativa/public >"${folder}"/../data/referendum_iniziative_popolare.json

<"${folder}"/../data/referendum_iniziative_popolare.json jq -c '.content[]' >"${folder}"/../data/referendum_iniziative_popolare.jsonl

mlrgo -I --jsonl --from "${folder}"/../data/referendum_iniziative_popolare.jsonl cut -f quorum,sito,sostenitori,supportata,titolo,titoloLeggeCostituzionale,estremi,id,dataApertura,dataFineRaccolta,dataFineValidita,dataGazzetta,dataInizioRaccolta,dataInizioValidita,dataIns,dataUltimoAgg,descrizione then put '$url="https://pnri.firmereferendum.giustizia.it/referendum/open/dettaglio-open/".$id'

# get the current datetime in the format YYYYMMDDHHMMSS ISO8601
datetime=$(date '+%Y-%m-%dT%H:%M:%S')

mlrgo --jsonl cut -f id,sostenitori then put '$datetime="'"$datetime"'"' then sort -f id,datetime "${folder}"/../data/referendum_iniziative_popolare.jsonl >>"${folder}"/../data/referendum_iniziative_popolare_log.jsonl

mlrgo -I --jsonl uniq -a then sort -n id -t datetime "${folder}"/../data/referendum_iniziative_popolare_log.jsonl

mlrgo --ijsonl --ocsv cat "${folder}"/../data/referendum_iniziative_popolare_log.jsonl >"${folder}"/../data/referendum_iniziative_popolare_log.csv

mlrgo --csv filter '$id==500020' "${folder}"/../data/referendum_iniziative_popolare_log.csv >"${folder}"/../data/referendum_iniziative_popolare_500020_log.csv

# allerta 500000
soglia=$(mlrgo --csv filter '$sostenitori>499999' "${folder}"/../data/referendum_iniziative_popolare_500020_log.csv | wc -l)

if [ "$soglia" -gt 0 ]; then
  echo "Allerta 500000"
  echo "stop" "${folder}"/../data/alert.txt
fi

exit 0

# extract historical data from git
datapath="${folder}/../data"
tmppath="${datapath}/tmp"
repopath="${folder}/../.."
filepath_from_repo_root="referendum_iniziative_popolare/data/referendum_iniziative_popolare.json"
filename="referendum_iniziative_popolare.json"

mkdir -p "${tmppath}"

# Use an array to keep track of processed dates
declare -A seen_dates

git -C "${repopath}" log --pretty=format:'%H %cI' -- "${filepath_from_repo_root}" | while read -r hash cdate; do
  day=$(echo "$cdate" | cut -d'T' -f1)

  if [[ -z "${seen_dates[${day}]-}" ]]; then
    outfile="${tmppath}/${day}_${filename}"
    git -C "${repopath}" show "${hash}:${filepath_from_repo_root}" > "${outfile}"
    seen_dates[${day}]=1
  fi
done
