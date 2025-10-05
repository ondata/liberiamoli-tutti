#!/bin/bash

# Script per analizzare l'efficacia della deduplicazione

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
timeline="${folder}/../data/timeline.csv"
repopath="${folder}/../.."
filepath_from_repo_root="referendum_iniziative_popolare/data/referendum_iniziative_popolare.json"

if [[ ! -f "$timeline" ]]; then
  echo "Errore: timeline non trovata"
  exit 1
fi

echo "=== Analisi Deduplicazione Timeline ==="
echo

# Conta giorni unici nel Git log
echo "Calcolo record totali dal Git log..."
total_days=$(git -C "${repopath}" log --pretty=format:'%cI' -- "${filepath_from_repo_root}" | cut -d'T' -f1 | sort -u | wc -l)
echo "Giorni unici nella storia Git: $total_days"

# Conta iniziative uniche
unique_initiatives=$(mlr --csv cut -f id "$timeline" | tail -n +2 | sort -u | wc -l)
echo "Iniziative uniche nella timeline: $unique_initiatives"

# Stima record totali senza deduplicazione (approssimativa)
estimated_total=$((total_days * unique_initiatives / 2))  # Divisione per 2 perché non tutte le iniziative esistono in tutti i giorni

dedup=$(wc -l < "$timeline")
dedup=$((dedup - 1))  # Rimuovi header

echo
echo "Record nella timeline deduplicata: $dedup"
echo "Record stimati senza deduplicazione: ~$estimated_total"
echo "Riduzione stimata: ~$(awk "BEGIN {printf \"%.1f\", 100.0 * ($estimated_total - $dedup) / $estimated_total}")%"
echo

# Mostra alcune iniziative di esempio
echo "=== Esempi di Iniziative nella Timeline ==="
mlr --csv stats1 -a count -f id -g id then top -n 5 -f id_count then cut -f id,id_count "$timeline" | mlr --icsv --opprint cat

