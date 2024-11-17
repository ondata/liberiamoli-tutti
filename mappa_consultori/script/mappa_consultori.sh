#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

home="https://www.salute.gov.it/portale/donna/consultoriDonna.jsp?lingua=italiano&id=4524&area=Salute%20donna&menu=consultori"

if [ -f "${folder}"/tmp/consultori.jsonl ]; then
  rm "${folder}"/tmp/consultori.jsonl
fi

if [ -f "${folder}"/tmp/regioni.txt ]; then
  rm "${folder}"/tmp/regioni.txt
fi

curl -skL "$home" | scrape -be "area" | xq -r '.html.body.area[]."@href"| "https://www.salute.gov.it" + .' | while read -r regione; do
  echo "$regione"
  curl -skL "$regione" >"${folder}"/tmp/regione.html
  test=$(<"${folder}"/tmp/regione.html scrape -be '//table[1]' | grep -c 'td' || echo 0)
  test=$(echo "$test" | head -n 1 | grep -o '[0-9]\+')

  if [ "$test" -gt 1 ]; then
    <"${folder}"/tmp/regione.html scrape -be '//table' | xq -c '.html.body.table[].tbody.tr[].td' | jq -cr '.[0:5] + [(if (.[5] | type == "object") then .[5].a["@href"] else "-" end)]|@csv' | mlr --icsv --ojsonl --implicit-csv-header label comune,asl,denominazione,indirizzo,telefono,sito >>"${folder}"/tmp/consultori.jsonl

    mlr -I --jsonl put '$url="'"$regione"'"' "${folder}"/tmp/consultori.jsonl
  else
    echo "$regione" >>"${folder}"/tmp/regioni.txt
  fi
done

mlr --ijsonl --ocsv cat "${folder}"/tmp/consultori.jsonl >"${folder}"/../data/consultori.csv

cp "${folder}"/tmp/regioni.txt "${folder}"/../data/regioni_senza_dati.txt
