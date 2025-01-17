#!/bin/bash

# Abilita debug solo se non stiamo mostrando l'help
if [[ "$1" != "-h" && "$1" != "--help" ]]; then
    set -x
fi

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

# Funzione per mostrare l'help
show_help() {
    echo "Uso: $(basename "$0") FILE_PDF"
    echo
    echo "Estrae i nomi dei partiti da un file PDF contenente dati finanziari politici."
    echo "Il file PDF deve essere quello ufficiale del Ministero dell'Interno."
    echo
    echo "Argomenti:"
    echo "  FILE_PDF    Percorso al file PDF da elaborare"
    echo
    echo "Esempio:"
    echo "  $(basename "$0") ART_5_DL_149_2013_L_3_2019_fino_31072020_agg.07092023.pdf"
    echo
    echo "Output:"
    echo "  JSON con pagina e testo estratto per ogni partito trovato"
    exit 1
}

# Mostra help se richiesto o se non ci sono argomenti
if [ $# -eq 0 ] || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# Verifica che il file esista
pdf_file="$1"
if [ ! -f "$pdf_file" ]; then
    echo "Errore: il file '$pdf_file' non esiste o non è un file regolare" >&2
    exit 1
fi

# Ottieni il numero totale di pagine
total_pages=$(pdfinfo "$pdf_file" | grep 'Pages:' | awk '{print $2}')

# Esegue il processamento in parallelo
# --keep-order mantiene l'ordine delle pagine
# --line-buffer fornisce output in tempo reale
# -j determina il numero di job paralleli (auto per rilevamento automatico)
seq 1 "$total_pages" | \
    parallel --keep-order --line-buffer \
    "process_page {} '$pdf_file'"
