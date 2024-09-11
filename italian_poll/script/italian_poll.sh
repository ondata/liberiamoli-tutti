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
curl -ksL "https://raw.githubusercontent.com/ruggsea/llm_italian_poll_scraper/main/italian_polls.jsonl" > "$folder"/tmp/italian_polls.jsonl


campi=$(<"$folder"/tmp/italian_polls.jsonl head -n 1 | jq -r 'to_entries[] | .key' | mlrgo --csv -N put 'if(NR<9){$n="f_".$1}else{$n=$1}' then cut -f n | paste -sd ',' -)

# rinomina i campi che non sono nomi di partito
mlrgo --jsonl --from "$folder"/tmp/italian_polls.jsonl label "$campi" then cat -n then cut -x -f f_Row  "$folder"/tmp/italian_polls.jsonl >"$folder"/tmp/italian_polls_long.jsonl


# trasforma il file da wide a long
mlrgo -I --jsonl --from "$folder"/tmp/italian_polls_long.jsonl reshape -r "^[^f][^_]" -o partito,valore then filter -x '$valore=="null"'

# rimuovi eventuale "%" a fine cella e cambia separatore decimale da "," a "."
mlrgo -I --jsonl --from "$folder"/tmp/italian_polls_long.jsonl sub -f valore "%+$" "" then sub -f valore "^(\d+),(\d+)$" "\1.\2"

# salva il file
mv "$folder"/tmp/italian_polls_long.jsonl "$folder"/../data/italian_polls.jsonl

# salva elenco record con errori in valori numerici
mlrgo --jsonl filter -x '$valore=~"^-?\d+\.?\d*$"' then filter -x 'is_null($valore)' "$folder"/../data/italian_polls.jsonl >"$folder"/../data/italian_polls_errori.jsonl


# salva elenco record senza errori in valori numerici
mlrgo --jsonl filter '$valore=~"^-?\d+\.?\d*$"' then filter -x 'is_null($valore)' "$folder"/../data/italian_polls.jsonl >"$folder"/../data/italian_polls_clean.jsonl

# rimuovi prefisso "f_" dai nomi dei campi
mlrgo -I --jsonl rename -r "^f_",""  "$folder"/../data/italian_polls_clean.jsonl

# crea csv con nomi campo snake_case e formatta le date in ISO8601
mlrgo --ijsonl --ocsv cat "$folder"/../data/italian_polls_clean.jsonl | duckdb --csv -c "select * from read_csv_auto('/dev/stdin',normalize_names = TRUE,dateformat='%d/%m/%Y')" >"$folder"/../data/italian_polls_clean.csv

# crea jsonl a partire dal csv
mlrgo --icsv --ojsonl  count-similar -g n -o numero_partiti "$folder"/../data/italian_polls_clean.csv >"$folder"/../data/italian_polls_clean.jsonl

# crea jsonl con i metadati dei sondaggi
mlrgo --jsonl cut -f n,data_inserimento,realizzatore,committente,titolo,_text,domanda,national_poll,numero_partiti then uniq -a then sort -n n "$folder"/../data/italian_polls_clean.jsonl >"$folder"/../data/italian_polls_metadata.jsonl

# crea csv con i soli valori di voto, la data e l'id sondaggio
mlrgo --jsonl -I cut -x -f realizzatore,committente,titolo,_text,domanda,national_poll,numero_partiti "$folder"/../data/italian_polls_clean.jsonl

# crea csv dei valori di voto dei sondaggi
mlrgo --ijsonl --ocsv cat "$folder"/../data/italian_polls_clean.jsonl >"$folder"/../data/italian_polls_clean.csv

# crea csv dei metadati dei sondaggi
mlrgo --ijsonl --ocsv cat "$folder"/../data/italian_polls_metadata.jsonl >"$folder"/../data/italian_polls_metadata.csv
