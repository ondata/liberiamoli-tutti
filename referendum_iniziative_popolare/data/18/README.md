# Dati — Referendum e iniziative popolari (numero #18)

Statistiche dei firmatari estratte dalla piattaforma [firmereferendum.giustizia.it](https://firmereferendum.giustizia.it/referendum/open) del Ministero della Giustizia. I dati — distribuzione per regione e per fascia d'età, con dettaglio di genere — sono accessibili solo dopo autenticazione con CIE o SPID e non sono disponibili in formato aperto.

I file sono denominati `YYYY-MM-DD_<tipo>.csv` in base alla data di estrazione.

---

## Snapshot disponibili

| Data estrazione | Iniziative | `regioni.csv` | `fasce_eta.csv` |
|---|---:|---|---|
| 2026-03-04 | 94 | [1.880 righe](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/referendum_iniziative_popolare/data/18/2026-03-04_regioni.csv) | [1.034 righe](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/referendum_iniziative_popolare/data/18/2026-03-04_fasce_eta.csv) |
| 2026-04-26 | 96 | [1.920 righe](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/referendum_iniziative_popolare/data/18/2026-04-26_regioni.csv) | [1.056 righe](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/referendum_iniziative_popolare/data/18/2026-04-26_fasce_eta.csv) |

---

## File

### `YYYY-MM-DD_regioni.csv`

Una riga per ogni combinazione iniziativa × regione (20 regioni).

| Colonna | Tipo | Descrizione |
|---|---|---|
| `id_iniziativa` | intero | ID numerico dell'iniziativa sulla piattaforma |
| `titolo` | testo | Titolo dell'iniziativa |
| `stato` | testo | Stato della raccolta (es. `IN RACCOLTA FIRME`, `MESSA A DISPOSIZIONE`) |
| `tipo` | testo | Tipo: `Referendum abrogativo`, `Referendum costituzionale`, `Legge di iniziativa popolare` |
| `quorum` | intero | Firme necessarie (50.000 per le leggi popolari, 500.000 per i referendum) |
| `data_inizio_raccolta` | data | Data di apertura della raccolta firme |
| `data_fine_raccolta` | data | Data di chiusura della raccolta firme |
| `firme_totali_nazionali` | intero | Totale firme a livello nazionale al momento dell'estrazione |
| `timestamp_estrazione` | datetime | Data e ora dell'estrazione (ISO 8601 UTC) |
| `regione` | testo | Nome della regione (maiuscolo) |
| `codice_istat` | testo | Codice ISTAT regione (es. `01`–`20`) |
| `nuts` | testo | Codice NUTS2 della regione (es. `ITC1`, `ITF1`) |
| `femmine` | intero | Firme di donne nella regione |
| `maschi` | intero | Firme di uomini nella regione |
| `firme_totali` | intero | Totale firme nella regione |

---

### `YYYY-MM-DD_fasce_eta.csv`

Una riga per ogni combinazione iniziativa × fascia d'età (11 fasce, da `18 - 22` a `68 e più`).

| Colonna | Tipo | Descrizione |
|---|---|---|
| `id_iniziativa` | intero | ID numerico dell'iniziativa sulla piattaforma |
| `titolo` | testo | Titolo dell'iniziativa |
| `stato` | testo | Stato della raccolta |
| `tipo` | testo | Tipo di iniziativa |
| `quorum` | intero | Firme necessarie |
| `data_inizio_raccolta` | data | Data di apertura della raccolta firme |
| `data_fine_raccolta` | data | Data di chiusura della raccolta firme |
| `firme_totali_nazionali` | intero | Totale firme a livello nazionale al momento dell'estrazione |
| `timestamp_estrazione` | datetime | Data e ora dell'estrazione (ISO 8601 UTC) |
| `fascia` | testo | Fascia d'età quinquennale (es. `18 - 22`, `23 - 27`, `68 e più`) |
| `femmine` | intero | Firme di donne nella fascia |
| `maschi` | intero | Firme di uomini nella fascia |
| `totali` | intero | Totale firme nella fascia |

---

## Fonti

- Piattaforma firme: [firmereferendum.giustizia.it](https://firmereferendum.giustizia.it/referendum/open)
- Metadati iniziative: endpoint pubblico `api-portal/iniziativa/public` (no autenticazione)
- Statistiche per regione e fascia: endpoint `/referendum/dettaglio/{id}/statistiche` (autenticazione CIE richiesta)

---

## Serie storica delle firme raccolte nel tempo

I file di questa cartella sono **snapshot statici** della distribuzione di firme per regione e fascia d'età. Non contengono l'evoluzione giornaliera dei totali raccolti.

Se sei interessato/a alla **serie storica del numero di firme nel tempo per ogni iniziativa** (senza info per regione e fascia d'età), c'è un repository dedicato:

👉 [**ondata/referendum_iniziative_popolari**](https://github.com/ondata/referendum_iniziative_popolari)

In particolare:

- [`source.jsonl`](https://github.com/ondata/referendum_iniziative_popolari/blob/main/data/source.jsonl) — anagrafica completa di tutte le iniziative (titolo, quorum, stato, date, ecc.), aggiornata 6 volte al giorno
- [`time_line.jsonl`](https://github.com/ondata/referendum_iniziative_popolari/blob/main/data/time_line.jsonl) — timeline storica giornaliera del numero di sostenitori per ogni iniziativa, dal 6 luglio 2025 in poi (chiave di join: `id`)

Il sito che visualizza questi dati è [ondata.github.io/referendum_iniziative_popolari](https://ondata.github.io/referendum_iniziative_popolari/).
