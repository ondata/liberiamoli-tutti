# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti**](https://datibenecomune.substack.com/about)", e in particolare nel "[numero zero](https://datibenecomune.substack.com/p/il-numero-zero)".

## Dati

Sono in formato `CSV`, con separatore `,` e con codifica `UTF-8`. Li abbiamo resi disponibili anche in [formato Google Sheet](https://docs.google.com/spreadsheets/d/1dNlByw2cMoqGorp4zPN6OULtG_jVRCe5xpl0YdKJxFE/edit?usp=sharing), ma la fonte più affidabile è quella dei file `CSV`.

La fonte è il "[Cruscotto statistico giornaliero](https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero)" del Ministero dell'Interno.<br>
Copia dei PDF del cruscotto è disponibile in [questa cartella](https://github.com/ondata/liberiamoli-tutti/tree/main/sbarchi-migranti/rawdata/pdf), con un [manifest](../rawdata/pdf/manifest.csv) che per ogni file riporta URL, impronta `sha256` e se è ancora pubblicato sul sito.

Anomalie della fonte, correzioni e scelte fatte nell'estrazione sono descritte in [`note-sui-dati.md`](note-sui-dati.md).

👉 **Nota Bene**: questi sono rilasciati con **licenza** [**CC-BY 4.0**](https://creativecommons.org/licenses/by/4.0/deed.it): li **puoi usare liberamente**, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo semplicemente "Fonte: [Liberiamoli tutti!](https://datibenecomune.substack.com/)" e inserendo il link ipertestuale a `https://datibenecomune.substack.com/`.

### Accoglienza

Si tratta dei numeri dell'**accoglienza**, per **regione** di accoglienza e per tipologia.

Il dato si ferma al report del 15 ottobre 2026: dal 28 ottobre 2026 il PDF non contiene più questa tabella.

Il file è [`accoglienza.csv`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/sbarchi-migranti/dati/accoglienza.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Regione | string | La regione di accoglienza, così come riportata nei report |
| Data_Report | date | La data del report PDF, da cui sono estratti i dati |
| Immigrati presenti negli hot spot | integer | Il numero di persone migranti presenti negli hotspot nella regione |
| Immigrati presenti nei centri di accoglienza | integer | Il numero di persone migranti presenti nei centri di accoglienza nella regione |
| Immigrati presenti nei centri SIPROIMI | integer | Il numero di persone migranti presenti nei centri SIPROIMI (Sistema di Protezione per Richiedenti Asilo e Rifugiati) nella regione |
| Immigrati presenti nei centri SAI | integer | Il numero di persone migranti presenti nei centri SAI (Sistema di Accoglienza e Integrazione) nella regione |
| CodiceRegione | string | Il codice identificativo Istat della regione. È un'informazione non presente nel report, che abbiamo aggiunto per rendere i dati più "usabili" |
| DenominazioneRegione | string | La denominazione ufficiale della Regione. È un'informazione non presente nel report, che abbiamo aggiunto per rendere i dati più "usabili" |

Alcune note sulle tipologie di accoglienza:

- **Hotspot**
  - Sono i cosiddetti "centri di crisi", ossia centri governativi situati presso le aree di sbarco con lo scopo di fornire una primissima assistenza sanitaria, di effettuare e procedure di pre-identificazione e fotosegnalamento e per la somministrazione delle informazioni sulle procedure dell'asilo
- **Centri di accoglienza**, si dividono in:
  - CENTRI GOVERNATIVI: centri dedicati ai richiedenti asilo, con funzioni di assistenza sanitaria, sociale e mediazione linguistica/culturale. Questi centri sono atti ad avviare la procedura di verifica della domanda di protezione internazionale;
  - CENTRI DI ACCOGLIENZA STRAORDINARIA (CAS): centri attivati dalle prefetture in caso di esaurimento dei posti nei centri governativi i cui servizi di prima accoglienza ricalcano questi ultimi.
- **SAI (Sistema di Accoglienza e Integrazione)**
  - Sistema dedicato quasi esclusivamente ai titolari di protezione e ad alcune categoria di migranti (minori stranieri non accompagnati, vulnerabili, richiedenti ucraini e afghani, ecc.). Il sistema è gestito dal Servizio Centrale dell'ANCI e i progetti sono assegnati agli enti locali, con funzioni di orientamento lavorativo e integrazione.
- **SIPROIMI (Sistema di Protezione per Richiedenti Asilo e Rifugiati)**
  - Era costituito dalla rete degli enti locali per la realizzazione di progetti di accoglienza integrata. Il sistema, ad oggi sostituito dal SAI, escludeva la possibilità di accogliere anche i richiedenti asilo, essendo dedicato solo a coloro che beneficiavano già di protezione o a categorie particolari (come i minori non accompagnati anche se richiedenti asilo).

### Nazionalità

Si tratta delle **nazionalità** dichiarate al momento dello sbarco per l'anno del report, alla data del report.

Il file è [`nazionalita.csv`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/sbarchi-migranti/dati/nazionalita.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data_Report | date | La data del report PDF, da cui sono estratti i dati |
| Nazione | string | Nazionalità dichiarate al momento dello sbarco, per l'anno della data del report, espressa come nome della nazione, così come riportate nel report |
| ISO_3166-1 | string | Il codice [`ISO 3166-1 alpha-2`](https://it.wikipedia.org/wiki/ISO_3166-1_alpha-2) della nazione. È un'informazione non presente nel report, che abbiamo aggiunto per rendere i dati più "usabili" |
| Valore | integer | Il numero di persone migranti provenienti dalla nazione |


### Sbarchi giornalieri

Si tratta dei numeri degli **sbarchi giornalieri** per anno, mese e giorno.

Ogni report riporta i giorni del suo mese fino alla data del report. Il dato si ferma al report del 31 maggio 2026: dal 15 giugno 2026 il PDF riporta solo i totali mensili.

Il file è [`sbarchi-per-giorno.csv`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/sbarchi-migranti/dati/sbarchi-per-giorno.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data | date | La data dello sbarco |
| Valore | integer | Il numero di persone migranti sbarcate quel giorno |
| Note | string | Eventuali note presente nel report |
| Fonte | string | Fonte dei dati, così come da report |
| Data_Report | string | La data del report PDF, da cui sono estratti i dati |

### Anagrafica report

Abbiamo inserito anche il file [`anagrafica-report.csv`](anagrafica-report.csv), che contiene i dati di anagrafica dei report PDF: per ogni data di report, l'URL del report PDF. Gli URL puntano al vecchio sito del Ministero, che non è più raggiungibile: gli URL attuali sono nel [manifest](../rawdata/pdf/manifest.csv).

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data_Report | string | La data del report PDF, da cui sono estratti i dati |
| URL | string | L'URL del report di quella data |

## Note

### Tipologia dati

La colonna `Tipologia colonna` indica il tipo di dato presente nella colonna. I tipi sono:

- `date`: Questo tipo di campo è utilizzato per contenere date e/o orari. Nel contesto di questo dati si tratte di date in formato anno-mese-giorno (YYYY-MM-DD), come ad esempio `2020-01-18`;
- `integer`: Un campo di tipo integer contiene numeri interi, senza decimali;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.
