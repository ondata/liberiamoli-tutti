# Istruzioni per Gemini - Progetto Liberiamoli Tutti

Questo documento fornisce le linee guida essenziali per interagire con questo repository. La tua aderenza a queste regole è fondamentale per mantenere la coerenza e la qualità del progetto.

## Architettura del Progetto

**Pattern Fondamentale**:

Ogni dataset risiede in una cartella dedicata con una struttura standard. Quando crei o modifichi un dataset, DEVI rispettare questa organizzazione:

- `data/` o `dati/`: Contiene i dati elaborati e puliti (CSV, JSONL).
- `rawdata/`: Contiene i file sorgente originali (PDF, Excel, ecc.).
- `script/` o `scripts/`: Contiene gli script di estrazione e processamento.
- `README.md`: Documenta le fonti, la metodologia e lo schema dei dati.
- `LICENSE.md`: Specifica la licenza dei dati (di default CC-BY 4.0).

**Esempi chiave da cui imparare**:

`scioperi/`, `amianto_ats_milano/`, `cinque_per_mille/`.

## Logging del Progetto

**Requisito Fondamentale**:

Dopo ogni modifica significativa (es. aggiunta di un nuovo dataset, correzione di uno script, aggiornamento dei dati), DEVI aggiornare il file `LOG.md` nella root del progetto.

- Aggiungi una nuova voce sotto la data corrente (`## YYYY-MM-DD`).
- Descrivi brevemente la modifica in un nuovo punto dell'elenco.

## Strumenti e Dipendenze Essenziali

Questo progetto si basa su una toolchain specifica. Utilizza **sempre** questi strumenti tramite `run_shell_command` per la manipolazione dei dati:

- `mlr`/`mlrgo`: Lo strumento primario per l'elaborazione di dati CSV/JSON.
- `duckdb`: Per operazioni SQL sui dataset.
- `scrape-cli`, `yq`, `xq`: Per il web scraping e l'estrazione di dati da HTML/JSON/YAML.

Tutti gli script bash che crei DEVONO iniziare con questa configurazione rigorosa per la gestione degli errori:

```bash
set -x          # Debug: mostra i comandi eseguiti
set -e          # Interrompe lo script se un comando fallisce
set -u          # Interrompe se viene usata una variabile non definita
set -o pipefail # Considera fallita una pipeline se uno dei comandi fallisce
```

## Workflow di Elaborazione Dati

Il flusso di lavoro standard per l'estrazione è una pipeline **HTML → JSON → CSV**.

1. Usa `curl` e `scrape-cli` per l'estrazione dei dati da pagine web tramite selettori XPath.
2. Usa `xq` o `yq` per la conversione da HTML a JSON, gestendo correttamente i valori nulli.
3. Usa `mlr` per la pulizia dei dati, la standardizzazione e la deduplicazione.

**Standardizzazione delle Date**:

Converti **sempre** le date nel formato `YYYY-MM-DD` usando `mlr`. Il comando di riferimento è:

```bash
mlr put '$data_iso=strftime(strptime($data,"%d/%m/%Y"),"%Y-%m-%d")'
```

## Standard dei Dati

- **Formati di Output**: Fornisci sempre i dati sia in formato `CSV` che `JSONL`.
- **Codifica**: UTF-8.
- **Licenza**: CC-BY 4.0 con attribuzione a "Liberiamoli tutti!".
- **Documentazione**: Per ogni dataset, assicurati che il `README.md` contenga un dizionario dei dati (schema) che descriva ogni colonna.

## Risorse Comuni

La cartella `risorse/` contiene dati di riferimento condivisi (es. elenchi di comuni e regioni ISTAT). Utilizzali quando necessario per arricchire i dataset.

## Interazione con il Progetto

- **Prima di modificare**: Leggi sempre il `README.md` e gli script esistenti nella cartella di un dataset per comprendere la metodologia attuale.
- **Quando aggiungi un nuovo dataset**: Crea la struttura di cartelle standard, sviluppa lo script seguendo i pattern definiti e documenta tutto nel `README.md`.

## Note di output markdown

Si prega di rispettare la formattazione Markdown più standard per garantire la compatibilità e la leggibilità.

In particolare:

- Dopo ogni titolo (es. `# Titolo`, `## Sottotitolo`), inserire sempre una riga vuota.
- Dopo il carattere di un elenco numerato (es. `1.`, `2.`), inserire un solo spazio.
- Dopo il carattere di un elenco puntato (es. `-`, `*`), inserire un solo spazio.
- Dopo i due punti (`:`) che precedono un elenco puntato o numerato, inserire sempre una riga vuota.
- Per l'indentazione di un elenco puntato o numerato, usa **due spazi**, non quattro.
