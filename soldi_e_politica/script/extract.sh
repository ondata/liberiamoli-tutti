#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Nomi partiti ###

# Definisce il file di output
output_jsonl="output.jsonl"
> "$output_jsonl"  # Inizializza il file JSON Lines

# Funzione per processare una singola pagina
process_page() {
    local page=$1
    local pdf_file=$2

    # Estrae il testo della pagina e rimuove le righe con solo "no"
    testo=$(pdf2txt -p "$page" "$pdf_file" 2>/dev/null | awk '/Annotazioni/{f=1; next} f && NF && !/^no$/{print; exit}')

    if [[ -n "$testo" ]]; then
        # Escaping delle virgolette nel testo
        escaped_testo=$(echo "$testo" | sed 's/"/\\"/g')

        # Crea la riga JSON
        echo "{\"pagina\": $page, \"testo\": \"$escaped_testo\"}"
    fi
}
export -f process_page  # Esporta la funzione per GNU Parallel

# Esegue il processamento in parallelo
# --keep-order mantiene l'ordine delle pagine
# --line-buffer fornisce output in tempo reale
# -j determina il numero di job paralleli (auto per rilevamento automatico)
seq 1 683 | \
    parallel --keep-order --line-buffer \
    "process_page {} ART_5_DL_149_2013_L_3_2019_dal_01012024.pdf" >> "$output_jsonl"

echo "Elaborazione completata. Output salvato in $output_jsonl"

mlr -S --csv --implicit-csv-header cut -x -f 1 then clean-whitespace then skip-trivial-records then cat -n then put '$p=FILENAME;if(is_not_null($7)){$valore=sub(regextract_or_else($7,"[0-9]+,*[0-9]*","alert"),",",".")}else{$valore=""}' then remove-empty-columns then sort -t p then put '$p=sub($p,"_tab.+","");$p=sub($p,".*o/","");$p=gsub($p,"^0+","")' then label n,data_erogazione,anno,data_trasmissione,soggetto_erogante,n_eroganti,importo,non_in_denaro,annotazioni,pagina ./o/*.csv >"$folder"/output/erogazioni_comunicate_dal_1_gennaio_2024.csv

cp "$output_jsonl" "$folder"/output/partiti.jsonl

mlr --ijsonl --ocsv label pagina,partito "$folder"/output/partiti.jsonl >"$folder"/output/partiti.csv

mlr --csv join --ul -j pagina -f "$folder"/output/erogazioni_comunicate_dal_1_gennaio_2024.csv then unsparsify then sort -t pagina,n then rename n,nn then cat -n -g pagina then cut -x -f nn then reorder -f pagina,n "$folder"/output/partiti.csv >"$folder"/output/tmp.csv

mv "$folder"/output/tmp.csv "$folder"/output/erogazioni_comunicate_dal_1_gennaio_2024.csv

exit 0

mlr -S --csv --implicit-csv-header cut -x -f 1 then clean-whitespace then skip-trivial-records then put '$p=FILENAME;if(is_not_null($7)){$valore=sub(regextract_or_else($7,"[0-9]+,*[0-9]*","alert"),",",".")}else{$valore=""}' then remove-empty-columns then sort -t p *.csv
