# Dati — Ricostruzione post-sisma 2016-2017

Dataset sugli interventi di ricostruzione pubblica nelle quattro regioni del Centro Italia colpite dal sisma 2016-2017 (Abruzzo, Lazio, Marche, Umbria), ottenuti tramite richiesta FOIA ad ActionAid Italia.

Fonte originale: Commissario Straordinario per la ricostruzione sisma 2016 — piattaforma GE.DI.SI.
Dati aggiornati al 30 aprile 2025.

---

## File

### `riscontro_action_aid.csv`

Elenco degli interventi di ricostruzione pubblica con codice CUP, importi, fase di avanzamento e localizzazione.

| Colonna | Descrizione |
|---|---|
| `ocos` | Tipo di opera: `OC` = Opere Comunali (gestite dai comuni), `OS` = Opere Statali (gestite dal Commissario Straordinario) |
| `eues_id` | Identificativo univoco dell'intervento nel sistema GE.DI.SI.: `EU_` per le Opere Comunali, `ES_` per le Opere Statali |
| `ordinanza_attuale` | Ordinanza di riferimento (es. `OC_129`, `OS_31`). `OC` = ordinanze commissariali, `OS` = ordinanze speciali |
| `regione` | Regione di localizzazione dell'intervento |
| `prov` | Sigla automobilistica della provincia |
| `comune` | Nome del comune |
| `cupxall` | Codice Unico di Progetto (CUP) dell'intervento. Identificatore univoco assegnato a ogni progetto di investimento pubblico in Italia |
| `denominazione_interventoxall` | Descrizione dell'intervento |
| `categoria` | Categoria tipologica dell'intervento (es. `2 - Chiese ed edifici di culto`, `10 - Scuole`, `4 - Dissesti`) |
| `soggetto_attuatore` | Ente responsabile dell'attuazione dell'intervento (comune, provincia, ufficio speciale, ecc.) |
| `importo_totale_dellintervento_x_all_hp_1` | Importo totale dell'intervento in euro |
| `fase_di_avanzamento_al_30_aprile_2025` | Fase procedurale raggiunta al 30 aprile 2025. Valori possibili: `FA_0` RUP non nominato → `FA_9` Collaudo → `FA_10` Rinunce/Revoche |
| `url_cup` | URL della scheda progetto su OpenCUP |
| `cod_istat_comune` | Codice ISTAT del comune a 6 cifre (fonte: ISTAT SITUAS, aggiornato al 21/02/2026). Assente per voci aggregate o non riconducibili a un singolo comune. |
| `url_ordinanza` | URL del testo dell'ordinanza associata a `ordinanza_attuale`. Per valori multipli (es. `OS_15 e OS_48`) contiene più URL separati da ` \| ` |

#### Anomalie rilevate nel sorgente per `cod_istat_comune`

Il file sorgente presenta diversi tipi di errori nella localizzazione dei comuni. L'assegnazione del codice ISTAT avviene tramite fuzzy match (strumento `tometo_tomato`) e correzioni manuali documentate in `risorse/vocabolario_comuni.csv`.

Anomalie risolte:

- **Provincia errata** (corrette via vocabolario): Sarnano (AP→MC), Capitignano (TE→AQ), Farindola (TE→PE), Montereale (TE→AQ), Ancarano (AP→TE)
- **Nome comune errato** (corretti via vocabolario): Popoli (→Popoli Terme), Silvi Marina (→Silvi)
- **Provincia assente** (NULL o `#N/A`, match solo su nome comune): Giove, Guardea, Umbertide, Valtopina, Corridonia, Montalto delle Marche, Pioraco
- **Case diverso** (risolti dal fuzzy match): MONTEMONACO, SERRAVALLE DEL CHIENTI, Serra De' Conti, Francavilla D'Ete, Torre De' Passeri, Ponzano Di Fermo, Vallo Di Nera, Campello Sul Clitunno, Giano Dell'Umbria
- **Preposizione diversa** (risolto dal fuzzy match): Montopoli in Sabina (→Montopoli di Sabina)
- **Nome incompleto** (risolto dal fuzzy match): Isola del gran Sasso (→Isola del Gran Sasso d'Italia)

Restano senza codice le voci aggregate o con nomi multipli (es. `Comuni vari`, `Palmiano - Rocca Fluvione - Comunanza`), non riconducibili a un singolo comune.

#### Fasi di avanzamento

| Codice | Descrizione |
|---|---|
| `FA_0` | RUP non nominato |
| `FA_1` | RUP nominato e cronoprogramma condiviso |
| `FA_2` | Avvio procedure di affidamento contraente per i servizi |
| `FA_3` | Incarico di progettazione affidato |
| `FA_4` | Progetto definitivo/PFTE approvato |
| `FA_5` | Progetto esecutivo approvato |
| `FA_6` | Avvio procedure per l'aggiudicazione dei lavori |
| `FA_7` | Inizio lavori |
| `FA_8` | Fine lavori |
| `FA_9` | Collaudo |
| `FA_10` | Rinunce/Revoche |

---

### `cup_cig.csv`

Elenco dei Codici Identificativi Gara (CIG) associati ai CUP presenti nel dataset, ottenuto tramite join con il dataset CUP-CIG pubblicato da ANAC.

| Colonna | Descrizione |
|---|---|
| `cup` | Codice Unico di Progetto |
| `cig` | Codice Identificativo Gara (CIG) ANAC. A ogni CUP possono corrispondere più CIG (più gare d'appalto per lo stesso progetto) |
| `url_cig` | URL della scheda gara su ANAC Analytics |

---

### `ordinanze.csv`

Tabella unificata delle ordinanze estratte dal sito istituzionale, con distinzione tra ordinanze commissariali e ordinanze speciali.

| Colonna | Descrizione |
|---|---|
| `tipo_id` | Tipo ordinanza: `OC` (ordinanze commissariali), `OS` (ordinanze speciali) |
| `tipo_label` | Etichetta testuale del tipo ordinanza |
| `n` | Numero ordinanza |
| `titolo` | Titolo ordinanza |
| `data_pubblicazione` | Data di pubblicazione sul sito istituzionale |
| `download_titolo` | Titolo/label del link di download |
| `download_url` | URL del documento ordinanza |

---

## Fonti

- Commissario Straordinario sisma 2016: [sisma2016.gov.it](https://sisma2016.gov.it)
- Dataset CUP-CIG ANAC: [dati.anticorruzione.it](https://dati.anticorruzione.it/opendata/dataset/cup)
- Codici comuni ISTAT: [SITUAS ISTAT](https://situas-servizi.istat.it)
- OpenCUP: [opencup.gov.it](https://www.opencup.gov.it)
