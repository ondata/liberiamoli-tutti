#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${folder}"/../processing
mkdir -p "${folder}"/../output

# Verifica che sia stato passato l'argomento con la cartella di input
if [ $# -eq 0 ]; then
    echo "Errore: specificare la cartella di input come argomento" >&2
    exit 1
fi

cartella_input="$1"


# Estrai il nome base della cartella per usarlo nel nome del file di output
nome_output=$(basename "$cartella_input")

mlr -S --csv --implicit-csv-header cut -x -f 1 then clean-whitespace then skip-trivial-records then cat -n then put '$p=FILENAME;if(is_not_null($7)){$valore=sub(regextract_or_else($7,"[0-9]+,*[0-9]*","alert"),",",".")}else{$valore=""}' then remove-empty-columns then sort -t p then put '$p=sub($p,"^.+/","");$p=sub($p,"_tab.+","");$p=gsub($p,"^0+","")' then label n,data_erogazione,anno,data_trasmissione,soggetto_erogante,n_eroganti,importo,non_in_denaro,annotazioni,pagina "${cartella_input}"/*.csv >"${folder}"/../processing/tmp.csv

mlr --ijsonl --ocsv cat "${folder}"/../raw_data/output/"${nome_output}"_nomi_partiti.jsonl >"${folder}"/../processing/nomi_partiti.csv

mlr -S --csv join --ul -j pagina -f "${folder}"/../processing/tmp.csv then unsparsify then sort -t pagina,n then rename testo,partito "${folder}"/../processing/nomi_partiti.csv >"${folder}"/../output/"${nome_output}".csv

rm "${folder}"/../processing/tmp.csv
rm "${folder}"/../processing/nomi_partiti.csv
