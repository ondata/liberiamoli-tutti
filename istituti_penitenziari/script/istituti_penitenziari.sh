#!/bin/bash

#set -x
set -e
set -u
#set -o pipefail

### Requirements ###
# mlr - https://miller.readthedocs.io
# scrape-cli - https://pypi.org/project/scrape-cli/
# tidy - https://www.html-tidy.org/
# vd - https://www.visidata.org/
# jq - https://stedolan.github.io/jq/
# curl - https://curl.se/
# duckdb - https://duckdb.org/
# duckdb spatial - https://github.com/duckdb/duckdb-spatial
### Requirements ###

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/../data/raw

mkdir -p "${folder}"/tmp

# chiedi se si vuole cancellare la cartella tmp
read -p "Vuoi cancellare il contenuto della cartella tmp? (y/n): " answer
if [ "$answer" = "y" ]; then
  # svuota la cartella tmp
  rm -rf "${folder}"/tmp/*
fi

# URL base
URL="https://www.giustizia.it/giustizia/page/it/istituti_penitenziari"

# lista
curl -kL "${URL}" | grep -Pi '^marker\.' | grep -vP '.+\{.+' | sed -r 's/(marker.mii.+)/\n\1/' | sed -r "s/ *$//g" | sed -r "s/'([A-Za-z0-9_]+)'/\"\1\"/g" | sed -r 's/"//g;s/; *//g;s/marker.codice/\nmarker.codice/' | mlr --x2c --ips "=" unsparsify then clean-whitespace >"${folder}"/tmp/lista_details.csv

# lista ID carceri
curl -skL "https://www.giustizia.it/giustizia/page/it/istituti_penitenziari" | grep -Pi '^marker\.' | sed -r 's/(marker.mii.+)/\n\1/' | grep -oP 'MII\d+' | sort -u >"${folder}"/tmp/lista.txt

# per ogni ID scarica la pagina
while read -r line; do
  # scarica soltanto se non è stato già scaricato
  if [ ! -f "${folder}"/../data/raw/"${line}".html ]; then
    echo "File not found!"
    curl -kL "https://www.giustizia.it/giustizia/it/dettaglio_scheda.page?s=${line}" >"${folder}"/../data/raw/"${line}".html
  fi
done <"${folder}"/tmp/lista.txt

# Stanze di detenzione
for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  if grep -q "Stanze di detenzione" "${file}"; then
    echo "Stanze di detenzione found"
    #cat "${file}"
    cat "${file}" | scrape -be '//h2[text()="Stanze di detenzione"]/following-sibling::table[1]' | tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 | vd -f html +:table_0:: -b --save-filetype json -o - | jq -c --arg name "$name" '.[] | .name = $name' >"${folder}"/tmp/stanze_"${name}".jsonl
  else
    echo "Stanze di detenzione not found"
  fi

done

mlr --ijsonl --ocsv unsparsify then reorder -f name then rename name,id_pagina then remove-empty-columns then clean-whitespace "${folder}"/tmp/stanze_*.jsonl >"${folder}"/../data/stanze.csv

# Personale
for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  if grep -q " Personale" "${file}"; then
    echo " Personale  found"
    #cat "${file}"
    cat "${file}" | scrape -be '//h2[text()="Personale"]/following-sibling::table[1]' | tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 | vd -f html +:table_0:: -b --save-filetype json -o - | jq -c --arg name "$name" '.[] | .name = $name' >"${folder}"/tmp/personale_"${name}".jsonl
  else
    echo " Personale  not found"
  fi

done

mlr --ijsonl --ocsv unsparsify then reorder -f name then rename name,id_pagina then remove-empty-columns then clean-whitespace "${folder}"/tmp/personale_*.jsonl >"${folder}"/../data/personale.csv

# Spazi incontro
for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  if grep -q "incontro con i visitatori" "${file}"; then
    echo "incontro con i visitatori found"
    #cat "${file}"
    cat "${file}" | scrape -be '//h2[contains(text(), "incontro con i visitatori")]/following-sibling::table[1]' | tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 | vd -f html +:table_0:: -b --save-filetype json -o - | jq -c --arg name "$name" '.[] | .name = $name' >"${folder}"/tmp/spazi_incontro_"${name}".jsonl
  else
    echo "incontro con i visitatori not found"
  fi

done

mlr --ijsonl --ocsv unsparsify then reorder -f name then rename name,id_pagina then remove-empty-columns then clean-whitespace "${folder}"/tmp/spazi_incontro_*.jsonl >"${folder}"/../data/spazi_incontro.csv

# Spazi comuni

for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  if grep -q "Spazi comuni e impianti" "${file}"; then
    echo "Spazi comuni e impianti found"
    #cat "${file}"
    cat "${file}" | scrape -be '//h2[contains(text(), "Spazi comuni e impianti")]/following-sibling::table[1]' | tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 | vd -f html +:table_0:: -b --save-filetype json -o - | jq -c --arg name "$name" '.[] | .name = $name' >"${folder}"/tmp/spazi_comuni_"${name}".jsonl
  else
    echo "Spazi comuni e impianti not found"
  fi

done

mlr --ijsonl --ocsv unsparsify then reorder -f name then rename name,id_pagina then remove-empty-columns then clean-whitespace "${folder}"/tmp/spazi_comuni_*.jsonl >"${folder}"/../data/spazi_comuni.csv

# Capienza e presenze

for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  if grep -q "Capienza e presenze" "${file}"; then
    echo "Capienza e presenze found"
    #cat "${file}"
    cat "${file}" | scrape -be '//h2[contains(text(), "Capienza e presenze")]/following-sibling::table[1]' | tidy -q --show-warnings no --drop-proprietary-attributes y --show-errors 0 | vd -f html +:table_0:: -b --save-filetype json -o - | jq -c --arg name "$name" '.[] | .name = $name' >"${folder}"/tmp/capienza_presenze_"${name}".jsonl
  else
    echo "Capienza e presenze not found"
  fi

done

mlr --ijsonl --ocsv unsparsify then reorder -f name then rename name,id_pagina then remove-empty-columns then clean-whitespace "${folder}"/tmp/capienza_presenze_*.jsonl >"${folder}"/../data/capienza_presenze.csv

# estrai data aggiornamento

# se "${folder}"/tmp/data_aggiornamento.jsonl esiste, cancellalo
if [ -f "${folder}"/tmp/data_aggiornamento.jsonl ]; then
  rm "${folder}"/tmp/data_aggiornamento.jsonl
fi

for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  data=$(<"${file}" scrape -e '//h2[contains(text(), "dati aggiornati al")]/following-sibling::span[1]/text()')
  # converti in formato ISO da dd/mm/yyyy
  data=$(date -d "${data}" +%Y-%m-%d)
  echo "{\"name\":\"${name}\",\"data\":\"${data}\"}" >>"${folder}"/tmp/data_aggiornamento.jsonl

done

mlr --ijsonl --ocsv unsparsify then label id_pagina,data_aggiornamento "${folder}"/tmp/data_aggiornamento.jsonl >"${folder}"/../data/data_aggiornamento.csv

# estrai località

for file in "${folder}"/../data/raw/*.html; do
  echo "Processing ${file}"
  name=$(basename "${file}" .html)

  scrape -e '//strong[@class="nomeSottocampo" and contains(text(), "località")]/following-sibling::span[1]/text()' ${file} | mlr --inidx --ojsonl --ifs ';' skip-trivial-records then clean-whitespace then label localita then put '$id_pagina="'${name}'"' >"${folder}"/tmp/localita_"${name}".jsonl

done

mlr --ijsonl --ocsv unsparsify then sub -f localita "\(.+" "" then clean-whitespace "${folder}"/tmp/localita_*.jsonl >"${folder}"/tmp/localita.csv

# Genera file anagrafico
mlr --csv --from "${folder}"/tmp/lista_details.csv remove-empty-columns then rename -r '"marker\."i,' then cut -x -f image then rename lat,latitude,lon,longitude,mii,id_pagina then put '$url="https://www.giustizia.it/giustizia/it/dettaglio_scheda.page?s=".$id_pagina' then sub -f tipo " +- *.*$" "" then clean-whitespace then rename title,titolo >"${folder}"/../data/anagrafica.csv

# aggiungi data aggiornamento
mlr --csv join --ul -j id_pagina -f "${folder}"/../data/anagrafica.csv then unsparsify "${folder}"/../data/data_aggiornamento.csv >"${folder}"/../data/anagrafica_tmp.csv

mv "${folder}"/../data/anagrafica_tmp.csv "${folder}"/../data/anagrafica.csv

# aggiungi codici ISTAT
duckdb --csv -c "select a.* exclude (geom), c.pro_com_t comune_istat,c.comune,c.cod_reg
from (
    select *, st_point(longitude, latitude) as geom
    from read_csv_auto('../data/anagrafica.csv')
) a
join (
    select *
    from st_read('../../risorse/ondata_confini_amministrativi_api_v2_it_20240101_comuni.geo.json')
) c
on st_within(a.geom, c.geom)" >"${folder}"/../data/tmp.csv

mv "${folder}"/../data/tmp.csv "${folder}"/../data/anagrafica.csv
