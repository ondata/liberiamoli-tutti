#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rawdata="${folder}/../rawdata/2026-02-02_riscontro_action_aid.xlsx"
vocabolario="${folder}/../risorse/vocabolario_comuni.csv"
tmp="${folder}/../../tmp"
data="${folder}/../data"

mkdir -p "${tmp}"

# --- FASE 1: Estrazione e normalizzazione dati sorgente ---

# Esporta il foglio con i dati di riscontro dall'XLSX in CSV grezzo
qsv excel --sheet 1 "${rawdata}" --output "${tmp}/riscontro_action_aid.csv"

# Normalizza gli header in snake_case e aggiunge url_cup per ogni CUP
csvnorm --force "${tmp}/riscontro_action_aid.csv" -o "${tmp}/riscontro_action_aid_norm.csv"
mlr --csv put '$url_cup = "https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/" . $cupxall' \
  "${tmp}/riscontro_action_aid_norm.csv" > "${tmp}/riscontro_action_aid_norm_url.csv" \
  && mv "${tmp}/riscontro_action_aid_norm_url.csv" "${tmp}/riscontro_action_aid_norm.csv"

# --- FASE 2: Scarica lista comuni ISTAT ---

# Usata come riferimento per il fuzzy match e l'assegnazione del codice ISTAT
comuni_json="${tmp}/comuni_istat.json"
comuni_csv="${tmp}/comuni_istat.csv"
pdata=$(date +"%d/%m/%Y")

if [[ ! -f "${comuni_json}" ]]; then
  curl -s "https://situas-servizi.istat.it/publish/reportspooljson?pfun=61&pdata=${pdata}" -o "${comuni_json}"
fi

if [[ ! -f "${comuni_csv}" ]]; then
  python3 -c "
import json, csv, sys
d = json.load(open('${comuni_json}'))
rows = d['resultset']
with open('${comuni_csv}', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)
"
fi

# --- FASE 3: Correzione errori noti nel sorgente ---

# Il vocabolario (risorse/vocabolario_comuni.csv) documenta errori di provincia
# e di nome comune presenti nel file sorgente ActionAid.
# Le correzioni vengono applicate prima del fuzzy match per massimizzare i match.
norm_fix="${tmp}/riscontro_action_aid_norm_fix.csv"
duckdb -c "
COPY (
  SELECT
    COALESCE(v.comune_fix, r.comune) AS comune,
    COALESCE(v.prov_fix, r.prov) AS prov,
    r.* EXCLUDE (comune, prov)
  FROM read_csv('${tmp}/riscontro_action_aid_norm.csv') r
  LEFT JOIN read_csv('${vocabolario}') v
    ON r.comune = v.comune_orig AND r.prov = v.prov_orig
) TO '${norm_fix}' (HEADER, DELIMITER ',')
"

# --- FASE 4: Fuzzy match comuni → codice ISTAT ---

# Match principale: usa sia nome comune sia provincia per maggiore precisione
comuni_match="${tmp}/riscontro_norm_comuni.csv"
tometo_tomato \
  "${norm_fix}" \
  "${comuni_csv}" \
  -j "comune,COMUNE" \
  -j "prov,SIGLA_AUTOMOBILISTICA" \
  -a "PRO_COM_T" \
  --latinize \
  --force \
  -o "${comuni_match}" \
  -u "${tmp}/riscontro_norm_comuni_ambigui.csv"

# Match di recupero: per i comuni con provincia NULL o #N/A nel sorgente,
# il match viene fatto solo sul nome comune (la provincia è inutilizzabile)
comuni_null_na="${tmp}/comuni_null_na.csv"
comuni_null_na_match="${tmp}/comuni_null_na_match.csv"

duckdb -c "
COPY (
  SELECT DISTINCT comune, prov
  FROM read_csv('${norm_fix}')
  WHERE prov IS NULL OR prov = '#N/A'
) TO '${comuni_null_na}' (HEADER, DELIMITER ',')
"

tometo_tomato \
  "${comuni_null_na}" \
  "${comuni_csv}" \
  -j "comune,COMUNE" \
  -a "PRO_COM_T" \
  --latinize \
  --force \
  -o "${comuni_null_na_match}"

# --- FASE 5: Produzione output riscontro_action_aid.csv ---

# Unisce i dati corretti con i codici ISTAT ottenuti dai due match.
# COALESCE: usa il match principale; se assente (prov NULL/#N/A), usa il match di recupero.
duckdb -c "
COPY (
  SELECT r.*, COALESCE(m.PRO_COM_T, m2.PRO_COM_T) AS cod_istat_comune
  FROM read_csv('${norm_fix}') r
  LEFT JOIN read_csv('${comuni_match}') m
    ON r.comune = m.comune AND r.prov = m.prov
  LEFT JOIN read_csv('${comuni_null_na_match}') m2
    ON r.comune = m2.comune AND (r.prov IS NULL OR r.prov = '#N/A')
  ORDER BY r.regione, r.comune
) TO '${data}/riscontro_action_aid.csv' (HEADER, DELIMITER ',')
"

# --- FASE 6: Join CUP-CIG con dataset ANAC ---

# Scarica il dataset CUP da ANAC (associa CUP a CIG)
cup_zip="${tmp}/cup_csv.zip"
cup_csv="${tmp}/cup.csv"
cup_url="https://dati.anticorruzione.it/opendata/download/dataset/cup/filesystem/cup_csv.zip"

if [[ ! -f "${cup_zip}" ]]; then
  curl -L "${cup_url}" -o "${cup_zip}"
fi

if [[ ! -f "${cup_csv}" ]]; then
  unzip -p "${cup_zip}" > "${cup_csv}"
fi

# Produce cup_cig.csv: per ogni CUP nel riscontro ActionAid,
# trova il CIG corrispondente nell'archivio ANAC e aggiunge url_cig
duckdb -c "
COPY (
  SELECT r.cupxall AS cup, c.CIG AS cig, 'https://dati.anticorruzione.it/superset/dashboard/dettaglio_cig/?cig=' || c.CIG AS url_cig
  FROM read_csv('${norm_fix}') r
  INNER JOIN read_csv('${cup_csv}') c ON r.cupxall = c.CUP
  WHERE r.cupxall IS NOT NULL
  ORDER BY r.cupxall
) TO '${data}/cup_cig.csv' (HEADER, DELIMITER ',')
"

# --- FASE 7: Estrazione ordinanze commissariali e ordinanze speciali ---

# Estrae una tabella Supsystic e salva solo le colonne utili:
# tipo_id, tipo_label, n, titolo, data_pubblicazione, download_titolo, download_url
extract_ordinanze_table() {
  local source_url="$1"
  local table_id="$2"
  local tmp_json="$3"
  local tipo_id="$4"
  local tipo_label="$5"
  local out_csv="$6"

  scrape "${source_url}" -b -e "//table[@id=\"${table_id}\"]/tbody/tr" \
    | xq . > "${tmp_json}"

  jq -r '
    def node($v):
      if $v == null then {}
      elif ($v|type) == "array" then ($v[0] // {})
      elif ($v|type) == "object" then $v
      else {} end;
    ["tipo_id","tipo_label","n","titolo","data_pubblicazione","download_titolo","download_url"],
    (.html.body.tr[]
      | objects
      | (node(.td[0])) as $c1
      | (node(.td[1])) as $c2
      | (node(.td[2])) as $c3
      | (node(.td[4])) as $c5
      | (node($c5.a)) as $a
      | ($c5["#text"] // "") as $cell_text
      | ($c5["@data-original-value"] // "") as $cell_original
      | ($c5["@data-formula"] // "") as $cell_formula
      | (
          if ($a["@href"] // "") != "" then $a["@href"]
          elif ($cell_text | test("^https?://")) then $cell_text
          elif ($cell_original | test("^https?://")) then $cell_original
          else ""
          end
        ) as $download_url
      | (
          if ($a["#text"] // "") != "" then $a["#text"]
          elif ($cell_formula | test("^HYPERLINK\\(")) then (try ($cell_formula | capture("^HYPERLINK\\(\"[^\"]+\";\\s*\"(?<label>[^\"]*)\"\\)") | .label) catch "")
          elif $download_url != "" then ($download_url | sub("^https?://"; "") | split("/") | .[-1])
          else ""
          end
        ) as $download_titolo
      | [
          $tipo_id,
          $tipo_label,
          ($c1["#text"] // ""),
          ($c2["#text"] // ""),
          ($c3["#text"] // ""),
          $download_titolo,
          $download_url
        ])
    | @csv
  ' --arg tipo_id "${tipo_id}" --arg tipo_label "${tipo_label}" "${tmp_json}" > "${out_csv}"
}

# Input 1: ordinanze commissariali (OC)
extract_ordinanze_table \
  "https://sisma2016.gov.it/ordinanze/" \
  "supsystic-table-34" \
  "${tmp}/ordinanze_commissariali.json" \
  "OC" \
  "ordinanze commissariali" \
  "${tmp}/ordinanze_commissariali.csv"

# Input 2: ordinanze speciali (OS)
extract_ordinanze_table \
  "https://sisma2016.gov.it/ordinanze-speciali/" \
  "supsystic-table-35" \
  "${tmp}/ordinanze_speciali.json" \
  "OS" \
  "ordinanze speciali" \
  "${tmp}/ordinanze_speciali.csv"

# Output unico: unione ordinanze commissariali + speciali
{
  head -n 1 "${tmp}/ordinanze_commissariali.csv"
  tail -n +2 "${tmp}/ordinanze_commissariali.csv"
  tail -n +2 "${tmp}/ordinanze_speciali.csv"
} > "${data}/ordinanze.csv"

# --- FASE 8: Arricchimento riscontro_action_aid con url_ordinanza ---

# Aggiunge url_ordinanza al main CSV in base a ordinanza_attuale.
# Supporta sia valori semplici (es. OC_129) sia valori multipli (es. OS_15 e OS_48).
duckdb -c "
COPY (
  WITH main_data AS (
    SELECT row_number() OVER () AS row_id, *
    FROM read_csv('${data}/riscontro_action_aid.csv')
  ),
  ord_map AS (
    SELECT tipo_id, CAST(n AS INTEGER) AS n, download_url
    FROM read_csv('${data}/ordinanze.csv')
  ),
  exploded AS (
    SELECT
      m.row_id,
      m.ordinanza_attuale,
      regexp_extract(m.ordinanza_attuale, '^(OC|OS)_', 1) AS tipo_id,
      CAST(unnest(regexp_extract_all(m.ordinanza_attuale, '(?:OC|OS)_([0-9]+)', 1)) AS INTEGER) AS n
    FROM main_data m
  ),
  joined AS (
    SELECT
      e.row_id,
      string_agg(DISTINCT o.download_url, ' | ' ORDER BY o.download_url) AS url_ordinanza
    FROM exploded e
    LEFT JOIN ord_map o
      ON e.tipo_id = o.tipo_id AND e.n = o.n
    GROUP BY e.row_id
  )
  SELECT m.* EXCLUDE (row_id), j.url_ordinanza
  FROM main_data m
  LEFT JOIN joined j
    ON m.row_id = j.row_id
) TO '${tmp}/riscontro_action_aid_con_ordinanza.csv' (HEADER, DELIMITER ',')
"

mv "${tmp}/riscontro_action_aid_con_ordinanza.csv" "${data}/riscontro_action_aid.csv"
