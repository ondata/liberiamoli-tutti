#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/tmp
mkdir -p "$folder"/../data

curl -ksL "https://raw.githubusercontent.com/ruggsea/llm_italian_poll_scraper/main/italian_polls.jsonl" > "$folder"/tmp/italian_polls.jsonl

partiti=$(<"$folder"/tmp/italian_polls.jsonl head -n 1 | jq -r 'to_entries[] | .key' | mlrgo --csv -N put 'if(NR<9){$n="f_".$1}else{$n=$1}' then cut -f n | paste -sd ',' -)

mlrgo --jsonl --from "$folder"/tmp/italian_polls.jsonl label "$partiti" then cat -n then cut -x -f f_Row  "$folder"/tmp/italian_polls.jsonl >"$folder"/tmp/italian_polls_long.jsonl

mlrgo -I --jsonl --from "$folder"/tmp/italian_polls_long.jsonl reshape -r "^[^f][^_]" -o partito,valore then clean-whitespace then filter -x '$valore=="null"'

mlrgo -I --jsonl --from "$folder"/tmp/italian_polls_long.jsonl sub -f valore "%+$" "" then sub -f valore "^(\d+),(\d+)$" "\1.\2"

mv "$folder"/tmp/italian_polls_long.jsonl "$folder"/../data/italian_polls.jsonl

mlrgo --jsonl filter -x '$valore=~"^-?\d+\.?\d*$"' then filter -x '$valore=="null"' "$folder"/../data/italian_polls.jsonl >"$folder"/../data/italian_polls_errori.jsonl

mlrgo --jsonl filter '$valore=~"^-?\d+\.?\d*$"' then filter -x '$valore=="null"' "$folder"/../data/italian_polls.jsonl >"$folder"/../data/italian_polls_clean.jsonl
