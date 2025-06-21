#!/bin/bash

# Configurazione rigorosa dello script
set -x  # Debug: mostra i comandi eseguiti
set -e  # Interrompe lo script se un comando fallisce
set -u  # Interrompe se viene usata una variabile non definita
set -o pipefail  # Considera fallita una pipeline se uno dei comandi fallisce

# Ottieni il percorso assoluto della cartella dello script
folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Crea le cartelle di lavoro necessarie
mkdir -p "$folder"/tmp
mkdir -p "$folder"/tmp/cgsse
mkdir -p "$folder"/../data/cgsse

# data di oggi in formato YYYY-MM-DD
oggi=$(date +%Y-%m-%d)


# Scarica la prima pagina per determinare il numero totale di pagine
curl -ksL 'https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine='"${oggi}"'&page=0' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: it,en-US;q=0.9,en;q=0.8' \
  -H 'cache-control: no-cache' \
  -b 'cgsee_cookie-version=1.0.0; cgsee_cookie=2' \
  -H 'pragma: no-cache' \
  -H 'priority: u=0, i' \
  -H 'referer: https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine=2025-06-21&page=2' \
  -H 'sec-ch-ua: "Google Chrome";v="137", "Chromium";v="137", "Not/A)Brand";v="24"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "Windows"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' > "$folder"/tmp/cgsse/cgsse_page_000.html

# Estrai il numero dell'ultima pagina dall'attributo href usando XPath e regex
pagine=$(<"$folder"/tmp/cgsse/cgsse_page_000.html scrape -e '//a[contains(@title, "ultima pagina")]/@href' | grep -oP 'page=\K\d+')

echo "Numero di pagine: $pagine"

#pagine=2 # per test, scarica solo le prime 3 pagine

# Rimuovi il file di output precedente se esiste per evitare duplicati
if [ -f "$folder"/tmp/cgsse/cgsse_data.jsonl ]; then
  rm "$folder"/tmp/cgsse/cgsse_data.jsonl
fi

# Scarica tutte le pagine del calendario scioperi iterando da 0 al numero massimo
for ((i = 0; i <= pagine; i++)); do
  echo "Scaricando pagina $i"
  curl -ksL "https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine='"${oggi}"'&page=$i" \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
    -H 'accept-language: it,en-US;q=0.9,en;q=0.8' \
    -H 'cache-control: no-cache' \
    -b 'cgsee_cookie-version=1.0.0; cgsee_cookie=2' \
    -H 'pragma: no-cache' \
    -H 'priority: u=0, i' \
    -H 'referer: https://www.cgsse.it/calendario-scioperi?data_inizio=2025-01-01&data_fine=2025-06-21&page=2' \
    -H 'sec-ch-ua: "Google Chrome";v="137", "Chromium";v="137", "Not/A)Brand";v="24"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Windows"' \
    -H 'sec-fetch-dest: document' \
    -H 'sec-fetch-mode: navigate' \
    -H 'sec-fetch-site: same-origin' \
    -H 'sec-fetch-user: ?1' \
    -H 'upgrade-insecure-requests: 1' \
    -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36' > "$folder"/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html
  sleep 1  # Pausa di cortesia per evitare sovraccarico del server

  # Estrai i dati dalla pagina HTML usando scrape (XPath) e xq (trasformazione JSON)
  <"$folder"/tmp/cgsse/cgsse_page_$(printf "%03d" "$i").html scrape -be '//ul[@class="responsive-table"]/li[@class="table-row views-row"]' | xq -c '[
  .html.body.li[] | {
    data: .div.div[0]."#text",
    settore: .div.div[1]."#text",
    azienda: .div.div[2]."#text",
    sindacato: .div.div[3]."#text",
    ambito_geografico: (
      if .div.div[4]["#text"] then
        .div.div[4]["#text"]
      elif .div.div[4].img["@alt"] == "sciopero nazionale" then
        "NAZIONALE"
      else
        null
      end
    ),
    modalita: .div.div[5].p,
    dettagli_link: (
      .div.div[6].div
      | map(select(has("a")))
      | ("https://www.cgsse.it" + .[0].a["@href"]) // null
    ),
    revocato: (
      .div.div[6].div
      | map(
          if (.img | type) == "array" then
            any(.img[]?; .["@alt"] == "sciopero revocato")
          elif (.img | type) == "object" then
            .img["@alt"] == "sciopero revocato"
          else
            false
          end
        )
      | any
    )
  }
]|.[]' >> "$folder"/tmp/cgsse/cgsse_data.jsonl

done

# Elaborazione finale dei dati estratti con Miller (mlr)
# Pulisce spazi bianchi, rimuove duplicati e converte le date in formato ISO
mlr -I --jsonl --from "$folder"/tmp/cgsse/cgsse_data.jsonl clean-whitespace then uniq -a then put 'if ($data =~ "^Dal (\d{2}-\d{2}-\d{4}) al (\d{2}-\d{2}-\d{4})$") {
    $data_dal_raw = "\1";  # Prima data in formato DD-MM-YYYY
    $data_al_raw = "\2";   # Seconda data in formato DD-MM-YYYY

    # Converti in formato YYYY-MM-DD per compatibilità ISO
    $data_dal_iso = strftime(strptime($data_dal_raw, "%d-%m-%Y"), "%Y-%m-%d");
    $data_al_iso = strftime(strptime($data_al_raw, "%d-%m-%Y"), "%Y-%m-%d");
}' then put 'if ($data =~ "^\d{2}-\d{2}-\d{4}$") {
    # Converti la data singola in formato YYYY-MM-DD per compatibilità ISO
    $data_iso = strftime(strptime($data, "%d-%m-%Y"), "%Y-%m-%d");

}' then cut -x -f data_dal_raw,data_al_raw then put 'if (!is_null($data_iso)) {$data_sort = $data_iso} else {$data_sort = $data_dal_iso}' then sort -tr data_sort

cp "$folder"/tmp/cgsse/cgsse_data.jsonl "$folder"/../data/cgsse/cgsse_data.jsonl

mlr --ijsonl --ocsv unsparsify "$folder"/../data/cgsse/cgsse_data.jsonl > "$folder"/../data/cgsse/cgsse_data.csv
