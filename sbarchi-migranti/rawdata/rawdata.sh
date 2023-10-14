#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mlr --csv sort -r Data_Report,Data "$folder"/csv/*.csv > "$folder"/../sbarchi-migranti.csv

mlr --c2m head -n 5 "$folder"/../sbarchi-migranti.csv > "$folder"/../tmp.md

