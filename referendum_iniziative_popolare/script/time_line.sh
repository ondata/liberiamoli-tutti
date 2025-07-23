#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

# Clear files from tmp and its subdirectories
find "${folder}"/../data/tmp -type f -delete

# Check for debug mode
DEBUG=false
if [[ "$#" -gt 0 && "$1" == "--debug" ]]; then
  DEBUG=true
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

git -C "${repopath}" log --pretty=format:'%H %cI' -- "${filepath_from_repo_root}" | while read -r hash cdate; do
  day=$(echo "$cdate" | cut -d'T' -f1)

  if [[ -z "${seen_dates[${day}]-}" ]]; then
    outfile="${tmppath}/${day}_${filename}"
    outfilejsonl="${tmppath}/${day}_${filename%.json}.jsonl"
    git -C "${repopath}" show "${hash}:${filepath_from_repo_root}" > "${outfile}"
    jq -c '.content[]' "${outfile}" | mlr --jsonl flatten -s "_" >"${outfilejsonl}"
    mlr -I --jsonl put '$data_download=FILENAME' then put '$data_download=regextract_or_else($data_download,"\d{4}-\d{2}-\d{2}","")' then reorder -e -f data_download "${outfilejsonl}"
    seen_dates[${day}]=1
    processed_days_count=$((processed_days_count + 1))
    if $DEBUG && [[ $processed_days_count -ge 3 ]]; then
      break
    fi
  fi
done
