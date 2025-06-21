# Introduzione

L'idea è quella di liberare i dati sugli **scioperi** in **Italia**. È un'idea di [Raffaele Mastrolonardo](https://www.linkedin.com/in/mastrolonardo/).

## Fonti

Al momento stiamo utilizzando queste:

- Ministero delle Infrastrutture e dei Trasporti <https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca>
- Commissione di Garanzia Scioperi <https://www.cgsse.it/calendario-scioperi>

La Commissione di Garanzia Scioperi è *autorità amministrative indipendente**, che svolge funzioni amministrative per conto dello Stato, garantendo l'applicazione della legge e la tutela dei diritti dei cittadini.

## Script

Il progetto include due script automatizzati per il download e l'elaborazione dei dati sugli scioperi:

### Script MIT (`mit.sh`)

Questo script scarica i dati degli scioperi dal sito del **Ministero delle Infrastrutture e dei Trasporti**. Effettua una ricerca automatica per l'anno corrente (2025), estrae i dati dalla tabella HTML utilizzando XPath e li converte in formato JSON. I dati vengono poi elaborati con Miller per standardizzare le date in formato ISO e ordinati cronologicamente. L'output finale viene salvato sia in formato JSONL che CSV.

### Script CGSSE (`cgsse.sh`)

Questo script scarica i dati dal calendario scioperi della **Commissione di Garanzia Scioperi**. Utilizza Tor come proxy per garantire l'anonimato e include un sistema di retry robusto per gestire eventuali fallimenti di rete. Lo script naviga automaticamente tutte le pagine del calendario, estrae i dati degli scioperi (inclusi settore, azienda, sindacato, ambito geografico e stato di revoca) e li elabora per produrre file JSONL e CSV strutturati. Include anche una modalità debug per testare il download su un numero limitato di pagine.

## Dati

I dati vengono estratti da entrambe le fonti e standardizzati in formati CSV e JSONL per facilitarne l'utilizzo.

Per ogni output i dati sono resi disponibili in due formati:

- MIT
  - [`mit_data.csv`](data/mit/mit_data.csv)
  - [`mit_data.jsonl`](data/mit/mit_data.jsonl)
CGSSE
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
| `data_sort` | Data da usare per ordinamento | Stringa (YYYY-MM-DD) | "2025-06-20" |
| `data_dal_iso` | Data di inizio periodo in formato ISO | Stringa (YYYY-MM-DD) | "2025-05-31" |
| `data_al_iso` | Data di fine periodo in formato ISO | Stringa (YYYY-MM-DD) | "2025-06-07" |
