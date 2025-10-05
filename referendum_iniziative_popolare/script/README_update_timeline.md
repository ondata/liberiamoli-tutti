# Script update_timeline.sh

Questo script genera la timeline storica delle iniziative popolari e referendum estraendo i dati dal log Git del repository.

## Utilizzo

### Modalità standard (ultimi 30 giorni - default)
```bash
./update_timeline.sh
```

### Modalità completa (tutti i giorni disponibili)
```bash
./update_timeline.sh --all
```

## Funzionamento

Lo script esegue le seguenti operazioni:

1. **Estrazione dati dal Git log**: estrae i file JSON dalla storia Git per ogni giorno unico
2. **Processing parallelo**: utilizza GNU parallel per processare in parallelo tutti i file JSON estratti
3. **Deduplicazione**: usa DuckDB per rimuovere record identici consecutivi per la stessa iniziativa
4. **Pulizia**: rimuove automaticamente tutti i file temporanei

## Performance

- **30 giorni (default)**: ~2 secondi
- **390 giorni (storia completa)**: ~1 minuto

## Dipendenze

- Git (storia completa del repository)
- jq
- mlr (Miller)
- GNU parallel
- DuckDB

## Output

Il file generato `../data/timeline.csv` contiene l'evoluzione delle iniziative, con deduplicazione automatica dei record ridondanti.

## Deduplicazione

La timeline è automaticamente deduplicata rimuovendo record dove un'iniziativa non ha subito modifiche. Vengono confrontati i campi significativi (sostenitori, date, titolo, stato, ecc.) escludendo solo `data_download`.

**Vantaggi**: riduzione del 30-47% delle righe mantenendo tutti i cambiamenti reali.

## Note

- Non mantiene archivi permanenti: tutto viene rigenerato dal Git log
- La modalità di default (30 giorni) è ottimale per aggiornamenti quotidiani
- Usa `--all` per rigenerare la timeline completa quando necessario
