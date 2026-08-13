## 2026-08-13

- Workflow PNRR CUP/CIG: il commit in caso di fallimento non dice più "Aggiornamento automatico dati PNRR" ma "PNRR non aggiornato, script fallito" — prima ogni run fallito committava il solo `update_log.jsonl` sotto un messaggio di aggiornamento riuscito.
- Diagnosticata la causa dei fallimenti ricorrenti (2026-07-06 → 08-10): ANAC risponde **403** ai download da IP dei runner GitHub (Azure US, PoP F5 Dallas). Verificato che non dipende dallo User-Agent — wget/curl, nudi o con UA Chrome, sono tutti bloccati; dalla stessa URL con IP italiano si scarica. Dati PNRR fermi da 2026-07-06.
- ANAC: download instradato su un proxy, il cui URL sta nel secret `ANAC_PROXY_URL`. `redact()` nello script maschera l'URL prima che finisca in `update_log.jsonl`, che è committato.
- italiadomani: Akamai risponde 403 agli IP dei runner e pretende `User-Agent` browser **e** header `Range` insieme (uno solo dei due non basta). Una funzione serverless su Scaleway `fr-par` scarica i due CSV e li riversa su un bucket pubblico; il workflow invoca la funzione e poi legge dal bucket. URL in `ITALIADOMANI_REFRESH_URL` e `ITALIADOMANI_BUCKET_URL`. Sparisce `proxy.andybandy.it`, che era hardcoded nello script.
- Workflow di nuovo verde end-to-end dopo cinque settimane.

## 2026-06-22

- Aggiunta cartella `maidati_ivg_2026/` con i dati IVG (numeri e qualitativo) per regione, anni 2023-2025, da accesso civico 2026. Formati CSV e JSONL, README con schema e note, licenza CC BY 4.0.

## 2026-06-15

- Aggiunto log persistente JSONL per le cause di fallimento del workflow PNRR CUP/CIG e commit dei log anche in caso di errore.

## 2026-03-11

- Fix qualità dati ricostruzione #17: whitespace rimosso con `mlr clean-whitespace`, 582 duplicati eliminati da `cup_cig.csv` con `SELECT DISTINCT`, date `data_pubblicazione` in `ordinanze.csv` convertite in ISO 8601

## 2026-02-22

- Aggiornato `dati_ricostruzione/script/dati_ricostruzione.sh` con estrazione ordinanze da due fonti: ordinanze commissariali (OC) e ordinanze speciali (OS)
- Prodotto output unificato `dati_ricostruzione/data/ordinanze.csv` con colonne `tipo_id`, `tipo_label`, `n`, `titolo`, `data_pubblicazione`, `download_titolo`, `download_url`
- Aggiunta la colonna `url_ordinanza` a `dati_ricostruzione/data/riscontro_action_aid.csv`, valorizzata con join su `ordinanza_attuale` e supporto ai casi con ordinanze multiple

## 2025-10-05

- Risolto errore critico nel workflow GitHub Actions `referendum_iniziative_popolare.yml` che causava il fallimento del job "aggiorna timeline storica"
- Il problema era causato da una query DuckDB che non gestiva correttamente i cambiamenti dello schema JSON nel tempo
- Modificato lo script `referendum_iniziative_popolare/script/update_timeline.sh` per gestire colonne opzionali usando TRY_CAST e COALESCE
- Testato il fix localmente con successo su 30 giorni di dati storici

## 2025-08-21

*   Pubblicati i dati relativi al FOIA sui dati della ricostruzione post-sisma, come descritto nel numero 14 di "Liberemioli tutti!".

## 2025-07-13

- Creazione del file di `LOG.md` per tracciare le modifiche.
- Aggiunta la sezione `scioperi` per la raccolta, l'elaborazione e la pubblicazione dei dati sugli scioperi in Italia.
- Creati e documentati gli script per l'estrazione automatica dei dati da:

  - Ministero delle Infrastrutture e dei Trasporti (`mit.sh`)
  - Commissione di Garanzia Scioperi (`cgsse.sh`)
- Predisposti i dati in formato CSV e JSONL.
