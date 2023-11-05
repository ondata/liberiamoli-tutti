#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

Elenco_comuni_italiani="https://www.istat.it/storage/codici-unita-amministrative/Elenco-comuni-italiani.csv"

curl -kL "$Elenco_comuni_italiani" | iconv -f Windows-1252 -t utf-8 | mlrgo --csv --ifs ";" clean-whitespace >"$folder"/../Elenco-comuni-italiani.csv

# regioni
mlrgo --csv -S cut -f "Codice Regione","Denominazione Regione" then uniq -a then rename -r "(.+) +(.+)","\1\2" "$folder"/../Elenco-comuni-italiani.csv >"$folder"/../Elenco-regioni.csv
