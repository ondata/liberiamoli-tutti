# Script — Referendum e iniziative popolari

Script per la raccolta e l'elaborazione dei dati dalla piattaforma [firmereferendum.giustizia.it](https://firmereferendum.giustizia.it/referendum/open) del Ministero della Giustizia.

---

## Dipendenze

- `mlrgo` / `mlr` — da `bin/` nella root del repository
- `jq`
- `duckdb`
- `GNU parallel`
- Git con storia completa (`fetch-depth: 0`)

---

## Script

### `referendum_iniziative_popolare.sh`

Script principale di raccolta. Scarica i dati correnti dall'API pubblica del Ministero e aggiorna il log storico.

```bash
./referendum_iniziative_popolare.sh
```

**Funzionamento**:
1. Controlla che l'API risponda con HTTP 200
2. Scarica il JSON delle iniziative e lo converte in JSONL
3. Aggiunge un record al log storico (`referendum_iniziative_popolare_log.jsonl` / `.csv`)
4. Estrae il sotto-log per l'iniziativa 500020 (referendum con soglia 500.000 firme)
5. Se l'iniziativa 500020 ha superato 500.000 sostenitori, scrive `stop` in `data/alert.txt`

**Output**:
- `data/referendum_iniziative_popolare.json` — snapshot corrente
- `data/referendum_iniziative_popolare.jsonl` — stesso dato in formato JSONL
- `data/referendum_iniziative_popolare_log.jsonl` / `.csv` — log storico di tutte le iniziative
- `data/referendum_iniziative_popolare_500020_log.csv` — log storico dell'iniziativa 500020
- `data/alert.txt` — contiene `stop` quando la soglia 500k è stata superata

**Nota**: la raccolta automatica è terminata (soglia superata). Il workflow GitHub è disabilitato; lo script può essere eseguito manualmente se necessario.

---

### `update_timeline.sh`

Genera la timeline storica deduplicata leggendo la storia Git del repository.

```bash
# Ultimi 30 giorni (default)
./update_timeline.sh

# Tutta la storia disponibile
./update_timeline.sh --all
```

**Funzionamento**:
1. Estrae un file JSON per ogni giorno unico dalla storia Git
2. Converte e processa i file in parallelo con GNU parallel
3. Genera `data/timeline.csv` deduplicata con DuckDB: vengono mantenuti solo i record in cui almeno un campo è cambiato rispetto al giorno precedente

**Output**: `data/timeline.csv` — evoluzione storica di tutte le iniziative (riduzione ~30–47% rispetto a una timeline completa)

**Performance**: ~2 secondi per 30 giorni, ~1 minuto per la storia completa.

---

### `check_timeline.sh`

Verifica rapida dello stato del file `data/timeline.csv`.

```bash
./check_timeline.sh
```

**Output**: numero di righe, dimensione del file, prima e ultima data presente.

---

### `analizza_deduplicazione.sh`

Statistiche sul guadagno della deduplicazione applicata in `update_timeline.sh`.

```bash
./analizza_deduplicazione.sh
```

**Output**: giorni unici nella storia Git, iniziative uniche, stima della riduzione percentuale delle righe.

---

### `time_line.sh`

Versione precedente di `update_timeline.sh`, senza parallelizzazione e con logica di deduplicazione meno avanzata. Mantenuto per riferimento; usare `update_timeline.sh`.
