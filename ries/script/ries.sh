#!/bin/bash

### requisiti ###
# duckdb https://duckdb.org/
# Miller versione 6, che nello script è rinominato mlrgo https://github.com/johnkerl/miller
# qsv https://github.com/jqnatividad/qsv
# csvmatch 1.24 https://github.com/maxharlow/csvmatch
### requisiti ###

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../data
mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/province

# province

start="https://www.adm.gov.it/portale/monopoli/giochi/apparecchi_intr/elenco_soggetti_ries?p_p_id=it_sogei_wda_web_portlet_WebDisplayAamsPortlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_el=2"


# scarica elenco province se non esiste
if [ ! -f "$folder"/tmp/province.jsonl ]; then
  curl -kL "$start" | scrape -be '//select[@name="prov"]' | xq -c '.html.body.select.option[]' >"$folder"/tmp/province.jsonl
fi

# rimuovi provincia = 0
if [ -f "$folder"/tmp/province.jsonl ]; then
  mlrgo -I --jsonl filter -x '${@value}=="0"' "$folder"/tmp/province.jsonl
fi

<"$folder"/tmp/province.jsonl head -n 1 >"$folder"/tmp/province_test.jsonl

# find delete tutti i file jsonl contenuti in tmp/province
find "$folder"/tmp/province -type f -name "*.jsonl" -delete
#find "$folder"/tmp/ -type f -name "*.html" -delete

estrai_dati="no"

if [ "$estrai_dati" == "si" ]; then
  while IFS= read -r province; do
    echo "$province"
    provincia="$(echo "$province" | jq -r '."@value"')"
    mkdir -p "$folder"/tmp/province/"$provincia"
    # scarica pagina 1
    curl -kL "https://www.adm.gov.it/portale/monopoli/giochi/apparecchi_intr/elenco_soggetti_ries?p_p_id=it_sogei_wda_web_portlet_WebDisplayAamsPortlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_pagina=1&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_comune=0&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_el=2&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_id_pagina=2&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_form_elenco_soggetti_esercizi=1&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_prov=$provincia" >"$folder"/tmp/province/"$provincia"/"$provincia".html
    # estrai numero pagine
    #numero_pagine=$(<"$folder"/tmp/province/"$provincia"/"$provincia".html grep -m 1 -P 'Per una migliore visualizzazione' | grep -oP '[0-9]+')
    numero_pagine=$(grep -m 1 -P 'Per una migliore visualizzazione' "$folder"/tmp/province/"$provincia"/"$provincia".html | grep -oP '[0-9]+' || true)


    if [ -z "$numero_pagine" ] || [ "$numero_pagine" -eq 0 ]; then
      echo "numero_pagine vuoto"
    else
      for ((i=1; i<=numero_pagine; i++));do
        echo "$i"
        id_pagina=$((i + 1))
        if [ ! -f "$folder"/tmp/province/"$provincia"/"$provincia"_"$i".html ]; then
          curl -kL "https://www.adm.gov.it/portale/monopoli/giochi/apparecchi_intr/elenco_soggetti_ries?p_p_id=it_sogei_wda_web_portlet_WebDisplayAamsPortlet&p_p_lifecycle=2&p_p_state=normal&p_p_mode=view&p_p_cacheability=cacheLevelPage&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_pagina=$i&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_comune=0&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_el=2&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_id_pagina=${id_pagina}&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_form_elenco_soggetti_esercizi=1&_it_sogei_wda_web_portlet_WebDisplayAamsPortlet_prov=$provincia" >"$folder"/tmp/province/"$provincia"/"$provincia"_"$i".html
        fi
        vd -b "$folder"/tmp/province/"$provincia"/"$provincia"_"$i".html +:table_0:: --save-filetype jsonl -o - >>"$folder"/tmp/province/"$provincia".jsonl
      done
    fi
  done <"$folder"/tmp/province.jsonl
fi

# fai il merge dei jsonlines in un CSV
mlrgo -S --ijsonl --ocsv unsparsify then clean-whitespace "$folder"/tmp/province/*.jsonl >"$folder"/../data/ries.csv

# rendi più leggibili i nomi colonne
qsv safenames "$folder"/../data/ries.csv >"$folder"/tmp.csv
mv "$folder"/tmp.csv "$folder"/../data/ries.csv

# cambia separatore in tipologia apparecchio e estrai nomi Comune e Provincia
mlrgo -S -I --csv cut -x -r -f ".*link.*" then \
sub -f tipologia_apparecchio "/" ";" then \
put '$provincia=gsub(regextract($comune_e_provincia,"\(([^)]+)\)"),"[\(|\)]","")' then \
put '$comune=sub($comune_e_provincia," *\(.+","")' "$folder"/../data/ries.csv

# fai il join con i nomi comuni e province corretti e correggi i nomi comuni e province
# imposta anagrafica_modificata a 1 se ci sono modifiche in comune e/o provincia
# imposta il separatore decimale a punto
mlrgo -S --csv join --ul -j provincia,comune -f "$folder"/../data/ries.csv then \
unsparsify then \
put '$anagrafica_modificata=0;if(is_null($nome_comune_corretto)) {$comune=$comune} else {$comune=$nome_comune_corretto;$anagrafica_modificata=1};if(is_null($provincia_corretta)) {$provincia=$provincia} else {$provincia=$provincia_corretta;$anagrafica_modificata=1}' then \
sort -f provincia,comune then cut -x -f provincia_corretta,nome_comune_corretto then \
sub -f superficie_del_locale_in_mq "," "." "$folder"/../risorse/comuni_correggere.csv >"$folder"/tmp/ries_comuni_corretti.csv

mv "$folder"/tmp/ries_comuni_corretti.csv "$folder"/../data/ries.csv

# associa codici istat

# crea copia info Comuni da dati Istat al 1 gennaio 2024
duckdb --csv -c "SELECT * from read_csv('$folder/../risorse/comuni.csv',normalize_names=true,all_varchar=true,delim=';')" >"$folder"/tmp/comuni.csv

# estrai da copia dati Istat, le colonne utili
mlrgo -S -I --csv cut -f codice_comune_alfanumerico,comune_dizione_italiana,sigla_automobilistica then label codice_comune_alfanumerico,comune,provincia then put '$comune=sub($comune,"/.*","")' "$folder"/tmp/comuni.csv

# estrai valori univoci di coppie comune-provincia da dati Ries
mlrgo -S --csv cut -f provincia,comune then uniq -a then clean-whitespace "$folder"/../data/ries.csv >"$folder"/tmp/comuni_reis.csv

# Fai il join tra dati Ries e Istat, per associare
# codici Istat all'anagrafica dei Comuni Ries
csvmatch "$folder"/tmp/comuni_reis.csv "$folder"/tmp/comuni.csv --fields1 provincia comune --fields2 provincia comune  -i -a -n --join left-outer --output 1.provincia 1.comune 2.codice_comune_alfanumerico >"${folder}"/tmp/tmp_join.csv

# Associa i codici Istat ai dati Ries
mlrgo -S --csv join --ul -j provincia,comune -f "$folder"/../data/ries.csv then \
unsparsify "${folder}"/tmp/tmp_join.csv >"$folder"/tmp.csv

mv "$folder"/tmp.csv "$folder"/../data/ries.csv
