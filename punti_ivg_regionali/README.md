- [Dati sui Punti IVG Regionali (Progetto CCM 2022)](#dati-sui-punti-ivg-regionali-progetto-ccm-2022)
  - [Contesto](#contesto)
  - [Modifiche apportate ai dati originali](#modifiche-apportate-ai-dati-originali)
  - [Dati](#dati)
  - [Schema dei dati](#schema-dei-dati)
  - [Licenza](#licenza)
  - [Note](#note)
    - [Dati sorgente](#dati-sorgente)


# Dati sui Punti IVG Regionali (Progetto CCM 2022)

Questo repository contiene i dati dei **Punti Interruzione Volontaria di Gravidanza (IVG) regionali** raccolti nel contesto del [**progetto CCM 2022**](https://www.epicentro.iss.it/ivg/progetto-ccm-2022):

>
> *"Interventi per migliorare la qualità dei dati, la prevenzione e l'appropriatezza delle procedure per l'Interruzione Volontaria di Gravidanza (IVG)".*

La fonte dati è la pagina ufficiale dell'Istituto Superiore di Sanità:👉 [https://www.epicentro.iss.it/ivg/progetto-ccm-2022-mappa-punti-ivg](https://www.epicentro.iss.it/ivg/progetto-ccm-2022-mappa-punti-ivg)

## Contesto

Il [**progetto**](https://www.epicentro.iss.it/ivg/progetto-ccm-2022) ha previsto un aggiornamento e miglioramento della rete nazionale dei punti IVG, sia in termini di qualità dei dati raccolti, sia come offerta informativa per i cittadini. I dati raccolti hanno valore epidemiologico e operativo, e sono parte integrante della sorveglianza nazionale IVG.

## Modifiche apportate ai dati originali

I dati originali sono distribuiti su diverse pagine HTML, qui unificati in un unico file CSV per facilitarne l'accesso e l'utilizzo.

Rispetto alla fonte originale, i dati in questo repository includono:

- **Codici ISTAT dei comuni**
- **Campi aggiuntivi**:
  - `n`
  - `struttura_nome`
  - `indirizzo`
  - `cap`
  - `comune`
  - `provincia`
- **Separatore decimale normalizzato a** `.` (punto) per facilitare l'importazione nei software di analisi dati

## Dati

Qui i dati estratti:

- [`punti_ivg_regionali.csv`](dati/punti_ivg_regionali.csv): file CSV contenente i dati aggiornati dei punti IVG regionali
- [Google Sheet](https://docs.google.com/spreadsheets/d/1Si80dFrgBhZbTyLq3LMhSOxQYuIWbyJwJjCdDJHoV4o/edit?usp=sharing)

Il progetto si chiama "Progetto CCM 2022", ma nelle note è riportato "Fonte dati: ISTAT 2023. I dati verranno aggiornati annualmente".

## Schema dei dati

| Campo | Tipo | Descrizione | Esempio |
| --- | --- | --- | --- |
| n | intero | Identificativo progressivo del record | 1 |
| struttura | stringa | Nome e indirizzo della struttura | "P.O.SAN SALVATORE L'AQUILA VIA VETOIO COPPITO, 67100 L'AQUILA AQ" |
| struttura\_nome | stringa | Nome della struttura | "Ospedale Bassini" |
| indirizzo | stringa | Indirizzo fisico della struttura | Via Gorki 50 |
| cap | stringa | Codice di Avviamento Postale | 20092 |
| comune | stringa | Nome del comune della struttura | Cinisello Balsamo |
| provincia | stringa | Sigla della provincia | MI |
| regione\_pa | stringa | Regione o provincia autonoma | Lombardia |
| url | stringa | URL della struttura o pagina informativa | http://esempio.it |
| n\_totale\_ivg | intero | Numero totale di IVG annuali effettuate nella struttura | 145 |
| n\_ivg\_farmacologiche | intero | Numero di IVG farmacologiche effettuate | 98 |
| perc\_ivg\_farmacologiche | float | Percentuale di IVG farmacologiche sul totale | 67.6 |
| perc\_ivg\_leq\_8\_sett | float | Percentuale di IVG effettuate entro 8 settimane | 71.2 |
| perc\_ivg\_9\_10\_sett | float | Percentuale di IVG effettuate tra 9-10 settimane | 18.3 |
| perc\_ivg\_11\_12\_sett | float | Percentuale di IVG effettuate tra 11-12 settimane | 10.5 |
| perc\_certificazione\_consultorio | float | Percentuale di certificazioni rilasciate da consultori | 52.4 |
| territorio | stringa | Nome regione o provincia autonoma | Distretto 3 |
| anno | intero | Anno di riferimento dei dati | 2023 |
| comune\_codice\_istat | stringa | Codice ISTAT del comune | 015055 |

## Licenza

I dati sono rilasciati con [licenza **Creative Commons Attribution 4.0 International (CC BY 4.0)**](LICENSE.md).

## Note

### Dati sorgente

- La pagina dell'Emilia-Romagna ha i separatori decimali (.) e non le virgole (,), a differenza delle altre regioni.
- La pagina della Liguria ha i separatori decimali (.) e non le virgole (,), a differenza delle altre regioni.
- Ci sono tre strutture, ripetute due volte, però con dati numerici diversi e a volte con URL diversi:
  - AZIENDA OSPEDALIERO-UNIVERSITARIA Dl PARMA VIA GRAMSCI 14, 1.13100 PARMA PR
  - AZIENDA OSPEDALIERO-UNIVERSITARIA Dl FERRARA VIA ALDO MORO 8, FERRARA FE
  - STABILIMENTO Dl URBINO VIA COMANDINO 70, 61029 URBINO PIJ
- di una struttura non c'è l'URL
- Nelle note della pagina sorgente è riportato "Fonte dati: ISTAT 2023. I dati verranno aggiornati annualmente", e perché non ci sono i dati 2024?.
