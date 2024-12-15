# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti**](https://datibenecomune.substack.com/about).

## Dati

Sono in formato `CSV`, con separatore `,` e con codifica `UTF-8`.

La fonte sono le pagine web della [sezione "**Istituti penitenziari**"](https://www.giustizia.it/giustizia/page/it/istituti_penitenziari), presente nel sito del Ministero della Giustizia.

👉 **Nota Bene**: questi sono rilasciati con **licenza** [**CC-BY 4.0**](https://creativecommons.org/licenses/by/4.0/deed.it): li **puoi usare liberamente**, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo semplicemente "Fonte: [Liberiamoli tutti!](https://datibenecomune.substack.com/)" e inserendo il link ipertestuale a `https://datibenecomune.substack.com/`.

### Anagrafica

Il file è [`anagrafica.csv`](../data/anagrafica.csv) ed è quello con le principali informazioni anagrafiche.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| codiceIstituto | string | Codice istituto dell'istituto penitenziario |
| titolo | string | Titolo dell'istituto penitenziario |
| nome | string | Nome dell'istituto penitenziario |
| tipo | string | Tipo di istituto penitenziario (ad es. Casa circondariale) |
| latitude | number | Latitudine dell'istituto penitenziario |
| longitude | number | Longitudine dell'istituto penitenziario |
| indirizzo | string | Indirizzo dell'istituto penitenziario |
| telefono | string | Numero di telefono dell'istituto penitenziario |
| url | string | indirizzo web della pagina sorgente dei dati |
| data_aggiornamento | date | Data di ultimo aggiornamento dei dati |
| comune_istat | string | Codice ISTAT del comune in cui si trova l'istituto |
| comune | string | Nome del comune in cui si trova l'istituto |
| cod_reg | string | Codice regionale ISTAT del Comune |

### Capienza e presenze

Il file è [`capienza_presenze.csv`](../data/capienza_presenze.csv) ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| posti regolamentari | number | Numero di posti regolamentari disponibili nell'istituto penitenziario |
| posti non disponibili | number | Numero di posti non disponibili nell'istituto penitenziario |
| totale detenuti | number | Numero totale di detenuti nell'istituto penitenziario |

### Spazi d'incontro con i visitatori

Il file è [`spazi_incontro.csv`](../data/spazi_incontro.csv) ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| sale colloqui | number | Numero di sale per colloqui disponibili nell'istituto |
| conformi alle norme | number | Numero di spazi conformi alle norme per le strutture carcerarie |
| aree verdi | string | Numero di aree verdi all'interno dell'istituto, o semplicemente presenza/assenza (con sì/no) |
| ludoteca | string | Numero di ludoteche all'interno dell'istituto, o semplicemente presenza/assenza (con sì/no) |

### Spazi comuni e impianti

Il file è [`spazi_comuni.csv`](../data/spazi_comuni.csv) ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| campi sportivi | number | Numero di campi sportivi presenti nell'istituto |
| teatri | number | Numero di teatri presenti nell'istituto |
| laboratori | number | Numero di laboratori presenti nell'istituto |
| palestre | number | Numero di palestre presenti nell'istituto |
| officine | number | Numero di officine presenti nell'istituto |
| biblioteche | number | Numero di biblioteche presenti nell'istituto |
| aule | number | Numero di aule presenti nell'istituto |
| locali di culto | number | Numero di locali di culto presenti nell'istituto |
| mense detenuti | number | Numero di mense per detenuti presenti nell'istituto |

### Stanze

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| numero complessivo | number | Numero totale di unità all'interno dell'istituto |
| numero non disponibili | number | Numero di unità non disponibili all'interno dell'istituto |
| doccia | number | Numero di docce disponibili all'interno dell'istituto |
| bidet | number | Numero di bidet disponibili all'interno dell'istituto |
| portatori di handicap | number | Numero di stanze adatte alle esigenze dei portatori di handicap all'interno dell'istituto |
| servizi igienici con porta | number | Numero di servizi igienici con porta all'interno dell'istituto |
| accensione luce autonoma | number | Numero di posti con accensione luce autonoma all'interno dell'istituto |
| prese elettriche | number | Numero di prese elettriche disponibili all'interno dell'istituto disponibili per le persone detenute |

### Personale

Il file è [`personale.csv`](../data/personale.csv) ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| id_pagina | string | Identificativo univoco della pagina web sorgente |
| polizia penitenziaria - effettivi | number | Numero di effettivi di polizia penitenziaria |
| polizia penitenziaria - previsti | number | Numero di previsti di polizia penitenziaria |
| amministrativi - effettivi | number | Numero di effettivi di personale amministrativo |
| amministrativi - previsti | number | Numero di previsti di personale amministrativo |
| educatori - effettivi | number | Numero di effettivi di educatori |
| educatori - previsti | number | Numero di previsti di educatori |


### Accoglienza

Si tratta dei numeri dell'**accoglienza**, per **regione** di accoglienza e per tipologia.

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

Il file è [`sbarchi-per-giorno.csv`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/sbarchi-migranti/dati/sbarchi-per-giorno.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| ---- | ---- | ----------- |
| Data | date | La data dello sbarco |
| Valore | integer | Il numero di persone migranti sbarcate quel giorno |
| Note | string | Eventuali note presente nel report |
| Fonte | string | Fonte dei dati, così come da report |
| Data_Report | string | La data del report PDF, da cui sono estratti i dati |

### Anagrafica report

Abbiamo inserito anche il file [`anagrafica-report.csv`](anagrafica-report.csv), che contiene i dati di anagrafica dei report PDF: per ogni data di report, l'URL del report PDF.

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
