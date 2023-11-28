#!/bin/bash

### requisiti ###
# duckdb https://duckdb.org/
# Miller versione 6, che nello script è rinominato mlrgo https://github.com/johnkerl/miller
# qsv https://github.com/jqnatividad/qsv
### requisiti ###

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

nome="notifiche_amianto_2012-2022"

mkdir -p "$folder"/tmp

# rimuovi eventuali spazi bianchi e rinomina le colonne
mlrgo --csv clean-whitespace "$folder"/tmp.csv >"$folder"/../dati/"$nome".csv

qsv safenames "$folder"/../dati/"$nome".csv >"$folder"/tmp/tmp.csv
mv "$folder"/tmp/tmp.csv "$folder"/../dati/"$nome".csv


sed -i -r 's/__*/_/g' "$folder"/../dati/"$nome".csv

# aggiungi i nomi comuni attuali, in modo da fare il join con Elenco-comuni-italiani.csv
mlrgo -I --csv put '$comune_nome_attuale=$localita_struttura_luogo' then \
put 'if (tolower($comune_nome_attuale)=~"(.*cavacurta.*)"){$comune_nome_attuale="CASTELGERUNDO"}else{$comune_nome_attuale=$comune_nome_attuale}' then \
put 'if (tolower($comune_nome_attuale)=~"(.*camairago \(.*)"){$comune_nome_attuale="CASTELGERUNDO"}else{$comune_nome_attuale=$comune_nome_attuale}'  then \
put 'if (tolower($comune_nome_attuale)=~"(.*vermezzo \(.*)"){$comune_nome_attuale="VERMEZZO CON ZELO"}else{$comune_nome_attuale=$comune_nome_attuale}'  then \
put 'if (tolower($comune_nome_attuale)=~"(.*zelo surrigone \(.*)"){$comune_nome_attuale="VERMEZZO CON ZELO"}else{$comune_nome_attuale=$comune_nome_attuale}' "$folder"/../dati/"$nome".csv

# estrai copia di Elenco-comuni-italiani.csv con solo i comuni della Lombardia
mlrgo --csv cut -f "Codice Comune formato alfanumerico","Denominazione in italiano","Denominazione Regione" then label comune_istat,comune,regione then filter '$regione=="Lombardia"' "$folder"/../../risorse/Elenco-comuni-italiani.csv >"$folder"/tmp/Elenco-comuni-italiani.csv


# aggiungi colonna con codice ISTAT del comune
duckdb -csv -c "SELECT t1.*,t2.comune_istat FROM read_csv_auto('"$folder"/../dati/"$nome".csv',header=true) t1
LEFT JOIN read_csv_auto('"$folder"/tmp/Elenco-comuni-italiani.csv',header=true) t2
ON LOWER(t1.comune_nome_attuale) = LOWER(t2.Comune);" >"$folder"/tmp/tmp.csv

mv "$folder"/tmp/tmp.csv "$folder"/../dati/"$nome".csv

# cambia separatore decimale da virgola a punto
mlrgo -I --csv -S sub -f superficie_esposta,quantita_kg,quantita_m2,quantita_m3 "([0-9]+),([0-9]+)" "\1.\2" "$folder"/../dati/"$nome".csv

# delete all empty files in amianto_lombardia/dati folder
find "$folder"/../dati -size 0 -delete
