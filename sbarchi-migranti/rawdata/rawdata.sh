#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mlr --csv sort -f Data_Report,Data "$folder"/csv/*.csv > "$folder"/../sbarchi-migranti-vit.csv

mlr --c2m head -n 5 "$folder"/../sbarchi-migranti-vit.csv > "$folder"/../tmp.md

mlr --csv sort -f Data_Report,Data "$folder"/../script/data/*.csv > "$folder"/../script/sbarchi-migranti-dbc.csv

daff --output "$folder"/../script/sbarchi-migranti.html "$folder"/../sbarchi-migranti-vit.csv "$folder"/../script/sbarchi-migranti-dbc.csv
