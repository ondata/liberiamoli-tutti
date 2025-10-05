# Sistema di Timeline Storica Referendum e Iniziative Popolari

Questo sistema genera una timeline storica deduplicata delle iniziative popolari e dei referendum in Italia, tracciando l'evoluzione delle raccolte firme nel tempo.

## Caratteristiche Principali

- **Estrazione dal Git log**: utilizza la storia Git del repository come unica fonte
- **Deduplicazione automatica**: rimuove record ridondanti (~30-47% di riduzione)
- **Parallelizzazione**: utilizza GNU parallel per performance ottimali
- **Nessun archivio permanente**: leggero e semplice da gestire
- **Aggiornamento automatico**: integrato nel workflow GitHub Actions

## Script Disponibili

### update_timeline.sh

Script principale per generare la timeline.

**Utilizzo**:
```bash
# Modalità standard - ultimi 30 giorni (default, veloce)
./update_timeline.sh

# Modalità completa - tutti i giorni disponibili
./update_timeline.sh --all
```

**Funzionamento**:
1. Estrae i dati dal Git log del repository
2. Processa in parallelo i file JSON estratti
3. Genera la timeline deduplicata con DuckDB
4. Pulisce i file temporanei

**Performance**:
- Modalità standard (30 giorni): ~2 secondi
- Modalità completa (390 giorni): ~1 minuto

### check_timeline.sh

Verifica lo stato della timeline.

**Output**:
- Numero di righe e dimensione del file
- Range di date coperto

### analizza_deduplicazione.sh

Analizza le statistiche della timeline.

**Output**:
- Giorni unici nella storia Git
- Numero di iniziative uniche
- Riduzione stimata dalla deduplicazione

## File Generati

- `data/timeline.csv` - Timeline deduplicata (solo cambiamenti effettivi)

## Deduplicazione

Il sistema rimuove automaticamente i record dove un'iniziativa non ha subito modifiche rispetto al giorno precedente. Vengono confrontati tutti i campi significativi:

- sostenitori
- dataUltimoAgg
- titolo
- dataApertura, dataFineRaccolta, dataGazzetta
- stato, categoria, tipo iniziativa
- ecc.

**Risultati**: riduzione stimata del 30-47% rispetto a una timeline completa.

## Integrazione nel Workflow

Il workflow GitHub Actions esegue quotidianamente:

1. `referendum_iniziative_popolare.sh` - scarica dati attuali
2. `update_timeline.sh` - rigenera timeline degli ultimi 30 giorni (default)
3. Commit e push automatico delle modifiche

**Nota**: Per rigenerare la timeline completa, modificare il workflow per usare `--all`.

## Dipendenze

- Git (con fetch-depth: 0 per storia completa)
- jq
- mlr (Miller)
- GNU parallel
- DuckDB

## Vantaggi dell'Approccio Semplice

- **Nessun archivio**: niente 1.9GB di dati duplicati
- **Git come unica fonte**: la storia Git è l'archivio
- **Semplice da rigenerare**: un comando per ricostruire tutto
- **Facile da debuggare**: niente cache da gestire
- **Modalità flessibile**: 30 giorni di default, `--all` quando serve

## Manutenzione

Per rigenerare la timeline completa:
```bash
./update_timeline.sh --all
```

Per verificare lo stato:
```bash
./check_timeline.sh
```

Per analizzare i dati:
```bash
./analizza_deduplicazione.sh
```
