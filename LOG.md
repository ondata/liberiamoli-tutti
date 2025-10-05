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
