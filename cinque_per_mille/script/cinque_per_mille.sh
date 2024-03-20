#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../dati
mkdir -p "$folder"/../dati/risorse
mkdir -p "$folder"/../tmp


home="https://www.agenziaentrate.gov.it/portale/elenco-complessivo-degli-enti-ammessi-in-una-o-piu-categorie-di-beneficiari"

# scarica lista se non esiste
if [ ! -f "$folder"/../dati/risorse/lista_pdf.jsonl ]; then
  curl -kL "$home" | scrape -be "//a[contains(@href, '.pdf')]" | xq -c '.html.body.a[]' | mlrgo --jsonl label href,title then sub -f href "\.pdf.+" ".pdf" then put '$href="https://www.agenziaentrate.gov.it".$href;$file=regextract($href,"P0[0-9]\.pdf")' >"$folder"/../dati/risorse/lista_pdf.jsonl
fi

# scarica PDF
while read -r line; do
  url=$(echo "$line" | jq -r '.href')
  file=$(echo "$line" | jq -r '.file')
  if [ ! -f "$folder"/../dati/risorse/"$file".pdf ]; then
    curl -kL "$url" >"$folder"/../dati/risorse/"$file".pdf
  fi
done < "$folder"/../dati/risorse/lista_pdf.jsonl
