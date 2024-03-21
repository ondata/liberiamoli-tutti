#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$folder"/../dati
mkdir -p "$folder"/../dati/risorse
mkdir -p "$folder"/../tmp


home="https://www.agenziaentrate.gov.it/portale/elenco-complessivo-degli-enti-ammessi-in-una-o-piu-categorie-di-beneficiari"

# scarica lista se non esiste
if [ ! -f "$folder"/../dati/risorse/lista_pdf.jsonl ]; then
  curl -kL "$home" | scrape -be "//a[contains(@href, '.pdf')]" | xq -c '.html.body.a[]' | mlrgo --jsonl label href,title then sub -f href "\.pdf.+" ".pdf" then put '$href="https://www.agenziaentrate.gov.it".$href;$file=regextract($href,"P0[0-9]\.pdf")' >"$folder"/../dati/risorse/lista_pdf.jsonl
fi

# scarica PDF
while read -r line; do
  url=$(echo "$line" | jq -r '.href')
  file=$(echo "$line" | jq -r '.file')
  if [ ! -f "$folder"/../dati/risorse/"$file" ]; then
    curl -kL "$url" >"$folder"/../dati/risorse/"$file"
  fi
done < "$folder"/../dati/risorse/lista_pdf.jsonl

# estrai pagine test
pdftk "$folder"/../dati/risorse/P01.pdf cat 1-3 output "$folder"/../tmp/tmp.pdf


# cancella con find delete tutti i file csv presenti in "$folder"/../tmp
find "$folder"/../tmp -name "*.csv" -delete

estrai="no"

if [ "$estrai" = "si" ]; then
  # usa find per listare tutti i file pdf presenti in "$folder"/../dati/risorse/
  find "$folder"/../dati/risorse/ -name "*.pdf" | while read -r file; do
    # estrai nome file
    nomefile=$(basename "$file" .pdf)

    # estrai numero pagine
    pagine=$(pdftk $file  dump_data | grep NumberOfPages | awk '{print $2}')

    # estrai prima pagina
    java -jar ~/bin/tabula-java.jar -a 79.464,21.576,515.199,823.581 -p 1 "$file" | mlrgo --csv -N skip-trivial-records then clean-whitespace | mlrgo --csv put '$pagina=1;$file=sub("'"$file"'",".+/","")' >>"$folder"/../tmp/"$nomefile".csv
    # estrai le altre pagine
    for (( i=2; i<=pagine; i++ )); do
      java -jar ~/bin/tabula-java.jar  -a 117.354,21.576,513.094,823.581 -p "$i" "$file" | mlrgo --csv -S -N clean-whitespace then put '$pagina='"$i"';$file=sub("'"$file"'",".+/","")' >>"$folder"/../tmp/"$nomefile".csv
    done
  done
fi

find "$folder"/../tmp/ -name "*.csv" | sort | while read -r file; do
  nomefile=$(basename "$file" .csv)
  # if nomefile = "P01" normalizza i nomi delle colonne
  if [ "$nomefile" = "P01" ]; then
    qsv safenames "$file" >"$folder"/../dati/cinque_per_mille.csv
  else
    # aggiungi righe senza intestazioni da altri file
    mlrgo -S --csv --headerless-csv-output cat "$file" >>"$folder"/../dati/cinque_per_mille.csv
  fi
done

# correggi nomi colonne
sed -i '1s/__//g' "$folder"/../dati/cinque_per_mille.csv

# converti campi numerici da stringhe a numeri
mlrgo -S -I --csv sort -t file,pagina,prog then \
gsub -f numero_scelte,importo_delle_scelte_espresse,importo_proporzionale_per_le_scelte_generiche,importo_proporzionale_per_ripartizione_importi_inferiori_a_1,importo_totale_erogabile "\." "" then \
gsub -f numero_scelte,importo_delle_scelte_espresse,importo_proporzionale_per_le_scelte_generiche,importo_proporzionale_per_ripartizione_importi_inferiori_a_1,importo_totale_erogabile "," "." "$folder"/../dati/cinque_per_mille.csv

# estrai pr e comune, e rimuovi dai nomi dei comuni il doppio nome in lingua diversa
mlrgo --csv cut -f pr,comune then sub -f comune " \..+" "" then uniq -a "$folder"/../dati/cinque_per_mille.csv >"$folder"/../tmp/comuni_cinque_per_mille.csv

# aggiungi campo con nome comune corretto, e fai copia del vecchio nome
mlrgo -I --csv put '$old_name=$comune' then sub -f comune "^BAIARDO$" "Bajardo" then \
sub -f comune "^TONENGO$" "Moransengo-Tonengo" then \
sub -f comune "^MORANSENGO$" "Moransengo-Tonengo" then \
sub -f comune "^TRODENA$" "Trodena nel parco naturale" then \
sub -f comune "^BREGANO$" "Bardello con Malgesso e Bregano" then \
sub -f comune "^BARDELLO$" "Bardello con Malgesso e Bregano" then \
sub -f comune "^CASTELBELLO CIARDES$" "Castelbello-Ciardes" then \
sub -f comune "^MONTAGNA$" "Montagna sulla Strada del Vino" then \
sub -f comune "^SALORNO$" "Salorno sulla strada del vino" then \
sub -f comune "^MALGESSO$" "Bardello con Malgesso e Bregano" then \
sub -f comune "^SAN GIOVANNI DI FASSA-SEN JAN$" "San Giovanni di Fassa" then \
put '$comune=toupper($comune)' then uniq -a "$folder"/../tmp/comuni_cinque_per_mille.csv

# estrai da nomi comune Istat nome, codice e provincia
mlrgo --csv cut -f "Codice Comune formato alfanumerico","Denominazione in italiano","Sigla automobilistica" then label codice_comune,comune,pr "$folder"/../../risorse/Elenco-comuni-italiani.csv >"$folder"/../tmp/comuni.csv

# fai join tra elenco comuni 5 per mille e dati istat, per associare codice istat comune
csvmatch "$folder"/../tmp/comuni_cinque_per_mille.csv "$folder"/../tmp/comuni.csv --fields1 comune pr --fields2 comune pr --fuzzy levenshtein -r 0.90 -i -a -n --join left-outer --output 1.comune 1.pr 1.old_name 2.codice_comune >"$folder"/../tmp/codifica_comuni.csv

# correggi manualmente i codici comune per Cercenasco e Mercenasco
mlrgo -I --csv put 'if($comune=="CERCENASCO"){$codice_comune="001071"}else{$codice_comune=$codice_comune}' then \
put 'if($comune=="MERCENASCO"){$codice_comune="001150"}else{$codice_comune=$codice_comune}' then uniq -a "$folder"/../tmp/codifica_comuni.csv

# rinomina comune in nome_comune e old_name in comune
mlrgo -I --csv rename comune,nome_comune,old_name,comune "$folder"/../tmp/codifica_comuni.csv

# rimuovi dai nomi dei comuni il doppio nome in lingua diversa
mlrgo -I --csv put '$old_name=$comune' then sub -f comune " \..+" "" "$folder"/../dati/cinque_per_mille.csv

# fai il join tra i dati 5 per mille e la codifica dei comuni generata
mlrgo --csv join --ul -j comune,pr -f "$folder"/../dati/cinque_per_mille.csv then unsparsify then reorder -e -f pr,comune then sort -t file,pagina,prog then reorder -f prog,codice_fiscale,denominazione,regione,pr,nome_comune,codice_comune then cut -x -f comune then rename old_name,old_nome_comune "$folder"/../tmp/codifica_comuni.csv >"$folder"/tmp.csv

# rinomina file
mv "$folder"/tmp.csv "$folder"/../dati/cinque_per_mille.csv

# correggi nome campo
mlrgo -I -S --csv rename -r 'inferiori_a_.+,inferiori_a_100' "$folder"/../dati/cinque_per_mille.csv

# crea parquet
duckdb -c "COPY (select * from read_csv('$folder/../dati/cinque_per_mille.csv')) TO '$folder/../dati/cinque_per_mille.parquet' (FORMAT 'parquet', COMPRESSION 'zstd', ROW_GROUP_SIZE 100_000)"
