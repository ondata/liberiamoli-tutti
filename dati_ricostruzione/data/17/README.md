# Dati — Ricostruzione post-sisma 2016-2017 (numero #17)

Dataset sugli interventi di ricostruzione pubblica nelle quattro regioni del Centro Italia colpite dal sisma 2016-2017 (Abruzzo, Lazio, Marche, Umbria), ottenuti tramite richiesta FOIA presentata il 26 novembre 2025 al Commissario Straordinario per il sisma 2016.

Fonte originale: Commissario Straordinario per la ricostruzione sisma 2016 — piattaforma GE.DI.SI.
Dati aggiornati al 2 febbraio 2026.

---

## File

### `riscontro_action_aid.csv`

Elenco di **3.542 interventi** di ricostruzione pubblica con codice CUP, importi, fase di avanzamento e localizzazione.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `comune` | testo | Nome del comune |
| `prov` | testo | Sigla automobilistica della provincia |
| `ocos` | testo | Tipo di opera: `OC` = Opere Comunali, `OS` = Opere Statali |
| `eues_id` | testo | Identificativo univoco nel sistema GE.DI.SI.: `EU_` per OC, `ES_` per OS |
| `ordinanza_attuale` | testo | Ordinanza di riferimento (es. `OC_129`, `OS_31 e OS_48`) |
| `regione` | testo | Regione di localizzazione (ABRUZZO, LAZIO, MARCHE, UMBRIA) |
| `cupxall` | testo | Codice Unico di Progetto (CUP). Assente per 398 interventi |
| `denominazione_interventoxall` | testo | Descrizione dell'intervento |
| `categoria` | testo | Categoria tipologica (vedi tabella sotto) |
| `soggetto_attuatore` | testo | Ente responsabile dell'attuazione |
| `importo_totale_dellintervento_x_all_hp_1` | numero | Importo totale in euro (min: 0, max: 71.000.000, media: ~1.300.000) |
| `fase_di_avanzamento_al_30_aprile_2025` | testo | Fase procedurale raggiunta al 30 aprile 2025 (vedi tabella sotto) |
| `url_cup` | testo | URL della scheda progetto su OpenCUP |
| `cod_istat_comune` | testo | Codice ISTAT comune a 6 cifre (fonte: ISTAT SITUAS, agg. 22/02/2026). Assente per 28 voci aggregate o non riconducibili a singolo comune |
| `url_ordinanza` | testo | URL del PDF dell'ordinanza. Per valori multipli, URL separati da ` \| ` |

#### Fasi di avanzamento

I valori del campo `fase_di_avanzamento_al_30_aprile_2025` includono già codice e descrizione:

| Valore | Interventi |
|---|---:|
| `FA_0 - Rup non nominato` | 85 |
| `FA_1 - Rup nominato e cronoprogramma condiviso` | 183 |
| `FA_2 - Avvio procedure di affidamento contraente per i servizi` | 294 |
| `FA_3 - Incarico di progettazione affidato` | 762 |
| `FA_4 - Progetto definitivo/PFTE approvato` | 701 |
| `FA_5 - Progetto esecutivo approvato` | 294 |
| `FA_6 - Avvio procedure per l'aggiudicazione dei lavori` | 202 |
| `FA_7 - Inizio lavori` | 444 |
| `FA_8 - Fine lavori` | 164 |
| `FA_9 - Collaudo` | 410 |
| `FA_10 - Rinunce/Revoche` | 3 |

#### Categorie

| Categoria | Interventi |
|---|---:|
| 1 - Caserme | 44 |
| 2 - Chiese ed edifici di culto | 66 |
| 3 - Cimiteri | 423 |
| 4 - Dissesti | 231 |
| 5 - Edilizia residenziale pubblica | 323 |
| 6 - Edilizia sanitaria | 19 |
| 7 - Edilizia socio sanitaria | 72 |
| 8 - Municipi | 198 |
| 9 - Opere di urbanizzazione e infrastrutture | 786 |
| 10 - Scuole | 397 |
| 10 - Scuole (Palestre) | 69 |
| 10 - Università | 21 |
| 11 - Altre opere pubbliche | 810 |
| 12 - Solo Progettazione | 83 |

---

### `cup_cig.csv`

**12.847 righe**: per ogni CUP presente nel dataset, i Codici Identificativi Gara (CIG) corrispondenti, ottenuti tramite join con il dataset CUP-CIG pubblicato da ANAC. Coprono più dell'87% degli interventi della ricostruzione pubblica.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cup` | testo | Codice Unico di Progetto |
| `cig` | testo | Codice Identificativo Gara ANAC. A ogni CUP possono corrispondere più CIG |
| `url_cig` | testo | URL della scheda gara su ANAC Analytics |

---

### `ordinanze.csv`

**401 ordinanze** (256 commissariali + 145 speciali) estratte dal sito istituzionale sisma2016.gov.it.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `tipo_id` | testo | `OC` = ordinanze commissariali, `OS` = ordinanze speciali |
| `tipo_label` | testo | Etichetta testuale del tipo |
| `n` | intero | Numero ordinanza |
| `titolo` | testo | Titolo ordinanza |
| `data_pubblicazione` | data | Data di pubblicazione sul sito istituzionale |
| `download_titolo` | testo | Label del link di download |
| `download_url` | testo | URL del documento PDF |

---

## Fonti

- Commissario Straordinario sisma 2016: [sisma2016.gov.it](https://sisma2016.gov.it)
- Dataset CUP-CIG ANAC: [dati.anticorruzione.it](https://dati.anticorruzione.it/opendata/dataset/cup)
- Codici comuni ISTAT: [SITUAS ISTAT](https://situas-servizi.istat.it)
- OpenCUP: [opencup.gov.it](https://www.opencup.gov.it)
