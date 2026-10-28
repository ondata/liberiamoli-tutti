#!/bin/bash
set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$folder"

# palette: nome e opzioni di -classify; predefinita lajolla (scala di Crameri, si stacca dal grigio dei paesi senza dato)
nome="${1:-lajolla}"
palette="${2:-colors=lajolla stops=15,85 invert}"

# confini Natural Earth 1:50 milioni, scaricati una volta (non versionati)
mkdir -p ne
[ -f ne/ne_50m_admin_0_countries.geojson ] || curl -fsSL -o ne/ne_50m_admin_0_countries.geojson https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_50m_admin_0_countries.geojson

# popolazione 2025 dalla Banca Mondiale (WDI, SP_POP_TOTL) con la query salvata, poi il tasso
opensdmx run popolazione.yaml --out pop_opensdmx.csv
duckdb < tasso.sql

# Somaliland unito alla Somalia (il Ministero conta un solo paese); popolazione e sbarchi da tasso_2025.csv
# ritaglio largo in gradi, proiezione equivalente, poi ritaglio rettangolare in metri
mapshaper ne/ne_50m_admin_0_countries.geojson \
  -each 'if (ADM0_A3=="SOL") {ISO_A2_EH="SO"; ADMIN="Somalia"}' \
  -dissolve ISO_A2_EH copy-fields=ADMIN \
  -join tasso_2025.csv keys=ISO_A2_EH,iso string-fields=iso \
  -clip bbox=-40,-35,130,75 \
  -proj +proj=laea +lon_0=38 +lat_0=22 \
  -clip bbox=-5700000,-2900000,5500000,3250000 \
  -classify field=per_milione breaks=20,50,100,200 $palette null-value='#e6e5e1' \
  -style stroke='#fcfcfb' stroke-width=0.6 \
  -each 'if (ISO_A2_EH=="IT") {stroke="#0b0b0b"; fill="#c9c8c3"}' \
  -points inner + name=etichette \
  -filter 'per_milione != null || ISO_A2_EH=="IT"' target=etichette \
  -each 'testo = ISO_A2_EH=="IT" ? "Italia" : nazione; fill = "#0b0b0b"; stroke = "#fcfcfb"' target=etichette \
  -style label-text=testo font-size=12 font-family='DejaVu Sans' font-weight=bold text-anchor=middle r=0 target=etichette \
  -o mappa_base.svg 'target=*' width=1100 2>&1 | tee mapshaper.log

# colori effettivamente usati, per la legenda
grep -o 'Colors: .*' mapshaper.log | sed 's/Colors: //' > colori.txt

# titolo, legenda e note; PNG
python3 componi.py
mv sbarchi_per_milione_2025.svg "sbarchi_per_milione_2025_${nome}.svg"
rsvg-convert -w 1650 "sbarchi_per_milione_2025_${nome}.svg" -o "sbarchi_per_milione_2025_${nome}.png"
