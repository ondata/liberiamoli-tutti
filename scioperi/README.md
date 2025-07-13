# Introduzione

Qui vengono liberati i dati sugli **scioperi** in **Italia**. È un'idea di [Raffaele Mastrolonardo](https://www.linkedin.com/in/mastrolonardo/).

## Fonti

Sono queste due:

- Scioperi dei trasporti, a cura del Ministero delle Infrastrutture e dei Trasporti <https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca>
- "Calendario scioperi", a cura della Commissione di Garanzia Scioperi <https://www.cgsse.it/calendario-scioperi>

La Commissione di Garanzia Scioperi è un'**autorità amministrative indipendente**, che svolge funzioni amministrative per conto dello Stato, garantendo l'applicazione della legge e la tutela dei diritti dei cittadini.

### 👉 Nota bene

Entrambi le fonti pubblicano i **dati** sugli **scioperi soltanto in formato HTML**, mentre le "**Linee Guida recanti regole tecniche per l'apertura dei dati e il riutilizzo dell'informazione del settore pubblico**" impongono con il [**requisito 2**](https://ondata.github.io/linee-guida-opendata/capitolo-4.html#req-2) che i dati siano pubblicati anche in formati aperti e strutturati, come CSV o JSON (ecc.), in **formati leggibili meccanicamente** e **facilmente riutilizzabili**.

## Script

Il progetto include due script automatizzati per il download e l'elaborazione dei dati sugli scioperi:

### Script MIT (`mit.sh`)

[Questo script](scripts/mit.sh) scarica i dati degli scioperi dal sito del **Ministero delle Infrastrutture e dei Trasporti**. Effettua una ricerca automatica per l'anno corrente (2025), estrae i dati dalla tabella HTML utilizzando XPath e li converte in formato JSON. I dati vengono poi elaborati con Miller per standardizzare le date in formato ISO e ordinati cronologicamente. L'output finale viene salvato sia in formato JSONL che CSV.

### Script CGSSE (`cgsse.sh`)

[Questo script](scripts/cgsse.sh) scarica i dati dal calendario scioperi della **Commissione di Garanzia Scioperi**. Lo script è progettato per essere eseguito periodicamente:

- **Intervallo di date**: Effettua una ricerca dal 1 Gennaio dell'anno corrente fino a 30 giorni successivi alla data di esecuzione, per includere anche gli scioperi futuri già programmati.
- **Connettività**: Utilizza **Tor** come proxy quando eseguito in ambienti automatizzati come GitHub Actions per garantire l'anonimato e prevenire blocchi IP, mentre usa chiamate dirette in locale. Include un sistema di retry per gestire fallimenti di rete.
- **Estrazione ed Elaborazione**: Naviga automaticamente tutte le pagine del calendario, estrae i dati (settore, azienda, sindacato, ecc.) e li salva in un file JSONL temporaneo.
- **Standardizzazione con Miller**: Utilizza `mlr` (Miller) per una pulizia approfondita:
  - Converte le date e gli intervalli di date ("Dal... al...") in campi `data_iso`, `data_dal_iso` e `data_al_iso` in formato standard `YYYY-MM-DD`.
  - Pulisce e standardizza il contenuto dei campi `sindacato` e `modalita`.
- **Aggiornamento Incrementale**: Aggiunge i nuovi dati a quelli già esistenti, rimuovendo eventuali duplicati. L'output finale viene salvato sia in formato JSONL che CSV.

## Dati

I dati vengono estratti da entrambe le fonti e standardizzati in formati CSV e JSONL per facilitarne l'utilizzo.

Per ogni output i dati sono resi disponibili in due formati:

- MIT
  - [`mit_data.csv`](data/mit/mit_data.csv)
  - [`mit_data.jsonl`](data/mit/mit_data.jsonl)
- CGSSE
  - [`cgsse_data.csv`](data/cgsse/cgsse_data.csv)
  - [`cgsse_data.jsonl`](data/cgsse/cgsse_data.jsonl)

### Schema dati MIT (Ministero delle Infrastrutture e dei Trasporti)

| Nome Campo | Descrizione | Tipo | Esempio |
|------------|-------------|------|---------|
| `stato` | Stato dello sciopero | Stringa | "Effettuato", "In Programma", "Revocato" |
| `inizio` | Data di inizio dello sciopero | Stringa (DD/MM/YYYY) | "20/06/2025" |
| `fine` | Data di fine dello sciopero | Stringa (DD/MM/YYYY) | "20/06/2025" |
| `sindacati` | Organizzazioni sindacali proclamanti | Stringa | "FILT-CGIL/FIT-CISL/UILT-UIL" |
| `settore` | Settore lavorativo interessato | Stringa | "Trasporto pubblico locale", "Aereo" |
| `categoria` | Categoria di lavoratori | Stringa | "PERSONALE SOC. ANM DI NAPOLI" |
| `modalita` | Modalità e durata dello sciopero | Stringa | "4 ORE: DALLE 12.45 ALLE 16.45" |
| `rilevanza` | Ambito territoriale | Stringa | "Nazionale", "Regionale", "Locale" |
| `note` | Note aggiuntive | Stringa | "ESCLUSI I VOLI DA E PER L'AEROPORTO DI PALERMO" |
| `data_proclamazione` | Data di proclamazione | Stringa (DD/MM/YYYY) | "04/06/2025" |
| `regione` | Regione interessata | Stringa | "Campania", "Italia" |
| `provincia` | Provincia interessata | Stringa | "Napoli", "Tutte" |
| `data_ricezione` | Data di ricezione della comunicazione | Stringa (DD/MM/YYYY HH:MM) | "04/06/2025 11:49" |
| `inizio_iso` | Data di inizio in formato ISO | Stringa (YYYY-MM-DD) | "2025-06-20" |
| `fine_iso` | Data di fine in formato ISO | Stringa (YYYY-MM-DD) | "2025-06-20" |

### Schema dati CGSSE (Commissione di Garanzia Scioperi)

| Nome Campo | Descrizione | Tipo | Esempio |
|------------|-------------|------|---------|
| `data` | Data dello sciopero (formato originale) | Stringa | "20-06-2025", "Dal 31-05-2025 al 07-06-2025" |
| `settore` | Settore lavorativo | Stringa | "Trasporto pubblico locale", "Servizio sanitario nazionale" |
| `azienda` | Nome dell'azienda o ente | Stringa | "ANM", "COMUNE DI GENOVA" |
| `sindacato` | Organizzazione sindacale | Stringa | "Filt Cgil", "Fp Cgil, Fit Cisl, Uiltrasporti" |
| `ambito_geografico` | Ambito territoriale | Stringa | "NAPOLI", "NAZIONALE", "LOMBARDIA" |
| `modalita` | Modalità dello sciopero | Stringa | "dalle ore 12.45 alle ore 16.45", "intera giornata" |
| `dettagli_link` | Link ai dettagli | Stringa (URL) | "https://www.cgsse.it/calendario-scioperi/dettaglio-sciopero/368896" |
| `revocato` | Indica se lo sciopero è stato revocato | Booleano | true, false |
| `data_iso` | Data singola in formato ISO | Stringa (YYYY-MM-DD) | "2025-06-20" |
| `data_sort` | Campo data unificato (usa `data_iso` se disponibile, altrimenti `data_dal_iso`) per garantire un ordinamento cronologico. | Stringa (YYYY-MM-DD) | "2025-06-20" |
| `data_dal_iso` | Data di inizio periodo in formato ISO. Per scioperi di un solo giorno, questo campo contiene la stessa data di `data_iso`. | Stringa (YYYY-MM-DD) | "2025-05-31" |
| `data_al_iso` | Data di fine periodo in formato ISO. Per scioperi di un solo giorno, questo campo contiene la stessa data di `data_iso`. | Stringa (YYYY-MM-DD) | "2025-06-07" |
