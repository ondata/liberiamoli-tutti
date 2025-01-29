#!/bin/bash

# Script per scaricare e processare i dati COVID-19 dalle API di ArcGIS 
# e convertirli in formato CSV per regioni e province italiane
#
# Requisiti:
# - ogr2ogr (pacchetto gdal-bin)
# - duckdb

# Verifica presenza dei requisiti
command -v ogr2ogr >/dev/null 2>&1 || { echo "Richiesto ogr2ogr ma non è installato. Installare il pacchetto gdal-bin."; exit 1; }
command -v duckdb >/dev/null 2>&1 || { echo "Richiesto duckdb ma non è installato. Vedi https://duckdb.org/docs/installation/"; exit 1; }

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../data
mkdir -p "${folder}"/tmp

ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG "${folder}"/tmp/covid-19.gpkg "https://services-eu1.arcgis.com/EgmeDaRXVrgDRlIu/ArcGIS/rest/services/COVID19_Regioni/FeatureServer/0/query?where=1%3D1&outFields=*&f=json" ESRIJSON -oo FEATURE_SERVER_PAGING=YES -oo RESULTS_PER_PAGE=1000 --debug on -nln regioni -append

ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG "${folder}"/tmp/covid-19.gpkg "https://services-eu1.arcgis.com/EgmeDaRXVrgDRlIu/ArcGIS/rest/services/DPC_COVID19_Province/FeatureServer/0/query?where=1%3D1&outFields=*&f=json" ESRIJSON -oo FEATURE_SERVER_PAGING=YES -oo RESULTS_PER_PAGE=1000 --debug on -nln province -append

duckdb -c "copy(select * EXCLUDE(geom) from st_read('${folder}/tmp/covid-19.gpkg',layer=province) order by data desc,codice_regione ASC, codice_provincia ASC) to '${folder}/../data/province.csv'"

duckdb -c "copy(select * EXCLUDE(geom) from st_read('${folder}/tmp/covid-19.gpkg',layer=regioni) order by data desc,codice_regione ASC) to '${folder}/../data/regioni.csv'"
