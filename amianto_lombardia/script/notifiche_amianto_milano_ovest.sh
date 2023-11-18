#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nome="notifiche_amianto_milano_ovest"

mkdir -p "$folder"/tmp

# rimuovi eventuali spazi bianchi e rinomina le colonne
mlrgo --csv clean-whitespace then rename -r '"Struttura *- *"i,' then rename -r '"à"i,a' "$folder"/../rawdata/NotificheAmianto_Milano_Ovest.csv >"$folder"/../dati/"$nome".csv

# estrai copia di Elenco-comuni-italiani.csv con solo i comuni della Lombardia
mlrgo --csv cut -f "Codice Comune formato alfanumerico","Denominazione in italiano","Denominazione Regione" then label comune_istat,comune,regione then filter '$regione=="Lombardia"' "$folder"/../../risorse/Elenco-comuni-italiani.csv >"$folder"/tmp/Elenco-comuni-italiani.csv

# aggiungi colonna con codice ISTAT del comune
duckdb -csv -c "SELECT t1.*,t2.comune_istat FROM read_csv_auto('"$folder"/../dati/"$nome".csv',header=true) t1
LEFT JOIN read_csv_auto('"$folder"/tmp/Elenco-comuni-italiani.csv',header=true) t2
ON LOWER(t1.Comune) = LOWER(t2.Comune);" >"$folder"/tmp/tmp.csv

# normalizza i nomi dei campi
qsv safenames "$folder"/tmp/tmp.csv >"$folder"/../dati/"$nome".csv

# Il comune di Vermezzo e quello di Zelo Surrigone ora sono unti. Inserito codice ISTAT attuale
mlrgo -I --csv put 'if (tolower($comune)=~"(vermezzo|zelo surrigone)"){$comune_istat="015251"}else{$comune_istat=$comune_istat}' "$folder"/../dati/"$nome".csv

# estrai record dati che contengono N/D e isolali in un file a parte
mlrgo --csv grep "N/D" "$folder"/../dati/"$nome".csv >"$folder"/../dati/"$nome"_ND.csv
mlrgo -I --csv grep -v "N/D" "$folder"/../dati/"$nome".csv

# cambia separatore decimale da virgola a punto
mlrgo -I --csv -S sub -f superfice_esposta,quantita_kg,quantita_m2,quantita_m3 , \. "$folder"/../dati/"$nome".csv

