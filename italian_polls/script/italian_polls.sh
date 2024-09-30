#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Aggiorna il repository
git pull origin main

mkdir -p "$folder"/tmp
mkdir -p "$folder"/../data

# scarica il file
curl -ksL "https://raw.githubusercontent.com/ruggsea/llm_italian_poll_scraper/main/italian_polls.jsonl" >"$folder"/tmp/risultati_raw.jsonl

# rimuovi eventuali righe duplicate
mlr -I --jsonl uniq -a "$folder"/tmp/risultati_raw.jsonl

mlr -I --jsonl tac "$folder"/tmp/risultati_raw.jsonl

campi=$(<"$folder"/tmp/risultati_raw.jsonl head -n 1 | jq -r 'to_entries[] | .key' | mlr --csv -N put 'if(NR<10){$n="f_".$1}else{$n=$1}' then cut -f n | paste -sd ',' -)

# rinomina i campi che non sono nomi di partito
mlr --jsonl --from "$folder"/tmp/risultati_raw.jsonl label "$campi" then cat -n then cut -x -f f_Row then sort -nr n >"$folder"/tmp/risultati_raw_long.jsonl

# trasforma il file da wide a long
mlr -I --jsonl --from "$folder"/tmp/risultati_raw_long.jsonl reshape -r "^[^f][^_]" -o partito,valore then filter -x '$valore=="null"'

# rimuovi eventuale "%" a fine cella e cambia separatore decimale da "," a "."
mlr -I --jsonl --from "$folder"/tmp/risultati_raw_long.jsonl sub -f valore "%+$" "" then sub -f valore "^(\d+),(\d+)$" "\1.\2"

# salva il file
mv "$folder"/tmp/risultati_raw_long.jsonl "$folder"/../data/risultati_raw.jsonl
mlr -I --jsonl uniq -a then sort -nr n "$folder"/../data/risultati_raw.jsonl

# salva elenco record con errori in valori numerici
mlr --jsonl filter -x '$valore=~"^-?\d+\.?\d*$"' then filter -x 'is_null($valore)' "$folder"/../data/risultati_raw.jsonl >"$folder"/../data/errori.jsonl

# salva elenco record senza errori in valori numerici
mlr --jsonl filter '$valore=~"^-?\d+\.?\d*$"' then filter -x 'is_null($valore)' "$folder"/../data/risultati_raw.jsonl >"$folder"/../data/risultati.jsonl

# rimuovi prefisso "f_" dai nomi dei campi
mlr -I --jsonl rename -r "^f_","" "$folder"/../data/risultati.jsonl

# crea csv con nomi campo snake_case e formatta le date in ISO8601
mlr --ijsonl --ocsv cat "$folder"/../data/risultati.jsonl | duckdb --csv -c "select * from read_csv_auto('/dev/stdin',normalize_names = TRUE,dateformat='%d/%m/%Y')" >"$folder"/../data/risultati.csv

# crea jsonl a partire dal csv
mlr --icsv --ojsonl count-similar -g n -o numero_partiti "$folder"/../data/risultati.csv >"$folder"/../data/risultati.jsonl

# crea jsonl con i metadati dei sondaggi
mlr --jsonl cut -f n,data_inserimento,realizzatore,committente,titolo,_text,domanda,national_poll_rationale,national_poll,numero_partiti then uniq -a then sort -n nr "$folder"/../data/risultati.jsonl >"$folder"/../data/anagrafica.jsonl

# normalizza i nomi dei realizzatori
python3 "$folder"/normalizza_realizzatore.py

# crea csv con i soli valori di voto, la data e l'id sondaggio
mlr --jsonl -I cut -x -f realizzatore,committente,titolo,_text,domanda,national_poll_rationale,national_poll,numero_partiti "$folder"/../data/risultati.jsonl

# crea csv dei valori di voto dei sondaggi
mlr --ijsonl --ocsv cat "$folder"/../data/risultati.jsonl >"$folder"/../data/risultati.csv

# crea csv dei metadati dei sondaggi
mlr --ijsonl --ocsv cat "$folder"/../data/anagrafica.jsonl >"$folder"/../data/anagrafica.csv

### almeno 5 partiti ###

# estrai i sondaggi con almeno 5 partiti
mlr --jsonl cut -f n,numero_partiti then filter '$numero_partiti>5' then cut -f n "$folder"/../data/anagrafica.jsonl >"$folder"/../data/tmp_risultati_raw_5.jsonl
# estrai i sondaggi che hanno valori negativi
mlr --jsonl filter '$valore<0' then cut -f n then uniq -a "$folder"/../data/risultati.jsonl >"$folder"/../data/tmp_risultati_raw_negativi.jsonl

# estrai soltanto i dati dei sondaggi con almeno 5 partiti
mlr --jsonl join -j n -f "$folder"/../data/tmp_risultati_raw_5.jsonl then unsparsify then sort -nr n "$folder"/../data/risultati.jsonl >"$folder"/../data/risultati_5_partiti.jsonl

# rimuovi i sondaggi in cui c'è almeno un partito con valori negativi
mlr --jsonl join --ul --np -j n -f "$folder"/../data/risultati_5_partiti.jsonl then unsparsify then sort -nr n "$folder"/../data/tmp_risultati_raw_negativi.jsonl >"$folder"/../data/tmp.jsonl

mv "$folder"/../data/tmp.jsonl "$folder"/../data/risultati_5_partiti.jsonl

mlr --ijsonl --ocsv cat "$folder"/../data/risultati_5_partiti.jsonl >"$folder"/../data/risultati_5_partiti.csv
