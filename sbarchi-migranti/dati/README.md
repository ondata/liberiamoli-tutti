# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "**Liberiamoli tutti**".

## Dati

Sono in formato `CSV`, con separatore `,` e con codifica `UTF-8`. Li abbiamo resi disponibili anche in [formato Google Sheet](https://docs.google.com/spreadsheets/d/1dNlByw2cMoqGorp4zPN6OULtG_jVRCe5xpl0YdKJxFE/edit?usp=sharing), ma la fonte più affidabile è il file `CSV`.

La fonte è il "[Cruscotto statistico](http://www.libertaciviliimmigrazione.dlci.interno.gov.it/it/documentazione/statistica/cruscotto-statistico-giornaliero)" del Ministero dell'Interno.

### Accoglienza

Si tratta dei numeri dell'**accoglienza**, per **regione** di accoglienza e per tipologia.

Il file è [`accoglienza.csv`](accoglienza.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Regione | string | La regione di accoglienza, così come riportata nei report |
| Data_Report | date | La data del report PDF, da cui sono estratti i dati |
| Immigrati presenti negli hot spot | integer | Il numero di persone migranti presenti negli hotspot nella regione |
| Immigrati presenti nei centri di accoglienza | integer | Il numero di persone migranti presenti nei centri di accoglienza nella regione |
| Immigrati presenti nei centri SIPROIMI | integer | Il numero di persone migranti presenti nei centri SIPROIMI (Sistema di Protezione per Richiedenti Asilo e Rifugiati) nella regione |
| Immigrati presenti nei centri SAI | integer | Il numero di persone migranti presenti nei centri SAI (Sistema di Accoglienza e Integrazione) nella regione |
| CodiceRegione | string | Il codice identificativo Istat della regione |
| DenominazioneRegione | string | La denominazione ufficiale della Regione |

### Nazionalità

Si tratta delle **nazionalità** dichiarate al momento dello sbarco per l'anno del report, alla data del report.

Il file è [`nazionalita.csv`](nazionalita.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data_Report | date | La data del report PDF, da cui sono estratti i dati |
| Nazione | string | Nazionalità dichiarate al momento dello sbarco, per l'anno della data del report, espressa come nome della nazione |
| ISO_3166-1 | string | Il codice `ISO 3166-1 alpha-2` della nazione |
| Valore | integer | Il numero di persone migranti provenienti dalla nazione |


### Sbarchi giornalieri

Si tratta dei numeri degli **sbarchi giornalieri** per anno, mese e giorno.

Il file è [`sbarchi-per-giorno.csv`](sbarchi-per-giorno.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data | date | La data dello sbarco |
| Valore | integer | Il numero di persone migranti sbarcate quel giorno |
| Note | string | Eventuali note presente nel report |
| Fonte | string | Fonte dei dati, così come da report |
| Data_Report | string | La data del report PDF, da cui sono estratti i dati |

### Anagrafica report

Abbiamo inserito anche il file [`anagrafica_report.csv`](anagrafica_report.csv), che contiene i dati di anagrafica dei report PDF: per ogni data di report, l'URL del report PDF.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data_Report | string | La data del report PDF, da cui sono estratti i dati |
| URL | string | L'URL del report di quella data |

## Note

### Tipologia dati

La colonna `Tipologia dati` indica il tipo di dato presente nella colonna. I tipi di dato sono:

- `date`: Questo tipo di campo è utilizzato per contenere date e/o orari. Nel contesto di questo dati si tratte di date in formato anno-mese-giorno (YYYY-MM-DD), come ad esempio `2020-01-18`;
- `integer`: Un campo di tipo integer contiene numeri interi, senza decimali;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.
