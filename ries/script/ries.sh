#!/bin/bash

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

