#!/bin/bash

set -x
set -e
set -u
set -o pipefail

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Nomi partiti ###

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

# Verifica che sia stato passato un argomento (file PDF)
if [ $# -eq 0 ]; then
    echo "Errore: specificare il file PDF da elaborare"
    exit 1
fi

pdf_file="$1"

# Ottieni il numero totale di pagine
total_pages=$(pdfinfo "$pdf_file" | grep 'Pages:' | awk '{print $2}')

# Esegue il processamento in parallelo
# --keep-order mantiene l'ordine delle pagine
# --line-buffer fornisce output in tempo reale
# -j determina il numero di job paralleli (auto per rilevamento automatico)
seq 1 "$total_pages" | \
    parallel --keep-order --line-buffer \
    "process_page {} '$pdf_file'"
