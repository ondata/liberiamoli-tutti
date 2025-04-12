#!/bin/bash

# Abilita la modalità di debug per visualizzare i comandi durante l'esecuzione
set -x
# Termina lo script se un comando ha un errore
set -e
# Termina se viene usata una variabile non definita
set -u
# Termina se un comando in una pipeline fallisce
set -o pipefail

# Ottiene il percorso della directory dove si trova lo script
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Imposta il nome del progetto
progetto="punti_ivg_regionali"
# Crea la directory temporanea
mkdir -p "$folder"/tmp

# URL della pagina principale con i link regionali
URL="https://www.epicentro.iss.it/ivg/progetto-ccm-2022-mappa-punti-ivg"
# URL base per costruire i link completi
URL_base="https://www.epicentro.iss.it/ivg/"

# Rimuove il file JSONL se già esistente per ricrearlo da zero
if [ -f "$folder"/../data/punti_ivg_regionali.jsonl ]; then
  rm "$folder"/../data/punti_ivg_regionali.jsonl
fi

# Processa ogni link regionale
curl -skL "${URL}" | scrape -be ".w-100" | xq -c '.html.body.a[]' | while read -r line; do
  # Estrai il link relativo
  link=$(echo "$line" | jq -r '."@href"')
  # Estrai il nome della regione
  regione=$(echo "$line" | jq -r '."#text"')

  # Estrai il nome del file
  nome=$(basename "$link")
  # Scarica la pagina regionale, estrai la tabella e la formatta in JSONL
  curl -skL "${URL_base}${link}" | vd -f html +:table_0:: -b --save-filetype json -o - | mlr -S --ijson --ojsonl clean-whitespace then label struttura,url,n_totale_ivg,n_ivg_farmacologiche,perc_ivg_farmacologiche,perc_ivg_leq_8_sett,perc_ivg_9_10_sett,perc_ivg_11_12_sett,perc_certificazione_consultorio then put '$territorio="'"${regione}"'"' >>"$folder"/../data/punti_ivg_regionali.jsonl
done

# Normalizza i numeri decimali: sostituisce la virgola con il punto e rimuove errori
sed -i -r 's/([0-9]+),([0-9]+)/\1.\2/g;s/#ERR//' "$folder"/../data/punti_ivg_regionali.jsonl

# Aggiunge un numero progressivo a ogni record
mlr -I -S --jsonl cat -n "$folder"/../data/punti_ivg_regionali.jsonl

# Converte da JSONL a CSV
mlr --ijsonl --ocsv cat "$folder"/../data/punti_ivg_regionali.jsonl >"$folder"/../data/punti_ivg_regionali.csv

# Arricchisce il dataset con informazioni aggiuntive da vittorio_light.csv
mlr --csv -S join --ul -j n -f "$folder"/../data/punti_ivg_regionali.csv then unsparsify then reorder -f n,struttura,struttura_nome,indirizzo,cap,comune,provincia,regione_pa "$folder"/../risorse/vittorio_light.csv >"$folder"/tmp/punti_ivg_regionali.csv

# Sostituisce il file originale con quello arricchito
mv "$folder"/tmp/punti_ivg_regionali.csv "$folder"/../data/punti_ivg_regionali.csv

# Aggiungi codice istat comune
mlr --csv --from "$folder"/../data/punti_ivg_regionali.csv cut -f comune,provincia then uniq -a >"$folder"/tmp/comune_provincia.csv

# Confronta i comuni con l'elenco ufficiale e aggiungi il codice ISTAT
csvmatch "$folder"/tmp/comune_provincia.csv "$folder"/../../risorse/Elenco-comuni-italiani.csv --fields1 comune provincia --fields2 "Denominazione in italiano" "Sigla automobilistica" --fuzzy levenshtein -r 0.9 -i -a -n --join left-outer --output 1.comune 1.provincia 2."Denominazione Regione" 2."Denominazione in italiano" 2."Codice Comune formato alfanumerico" >"$folder"/tmp/comune_provincia_istat.csv

# Rinomina le colonne e salva il file
mlr -S -I --csv cut -f comune,provincia,"Codice Comune formato alfanumerico" then label comune,provincia,comune_codice_istat "$folder"/tmp/comune_provincia_istat.csv

# Unisci il codice ISTAT al dataset principale
mlr -S --csv join --ul -j comune,provincia -f "$folder"/../data/punti_ivg_regionali.csv then unsparsify then sort -t n then reorder -f n,struttura,struttura_nome,indirizzo,cap,comune,provincia,regione_pa "$folder"/tmp/comune_provincia_istat.csv >"$folder"/tmp/punti_ivg_regionali.csv

# Rimuovi valori non validi
mlr -I -S --csv sub -a "^-$" "" "$folder"/tmp/punti_ivg_regionali.csv
mlr -I -S --csv sub -a "^n\.d\.$" "" "$folder"/tmp/punti_ivg_regionali.csv

# Sostituisce il file originale con quello arricchito
mv "$folder"/tmp/punti_ivg_regionali.csv "$folder"/../data/punti_ivg_regionali.csv
