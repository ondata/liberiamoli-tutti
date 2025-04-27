# PNRR: il collegamento tra progetti e gare d'appalto

Questo strumento automatico scarica e incrocia i dati dei progetti del PNRR (Piano Nazionale di Ripresa e Resilienza) con quelli delle gare d'appalto pubbliche.

Lo script recupera:

- i dati dei progetti PNRR da Italia Domani
- i dati delle gare PNRR da Italia Domani
- i dati delle gare d'appalto dall'ANAC (Autorità Nazionale Anticorruzione)

Il risultato finale è un dataset che mostra come i progetti PNRR (identificati dal codice CUP) sono collegati alle gare d'appalto (identificate dal codice CIG), permettendo di capire meglio come vengono spesi i fondi del PNRR attraverso le gare pubbliche.

## File di output

### cup_cig_anac_pnrr.csv

Contiene l'associazione tra CUP dei progetti PNRR e CIG presenti nei dati ANAC. È il risultato dell'incrocio tra i CUP dei progetti PNRR e i dati di ANAC.

Schema:

- `CUP`: Codice Unico di Progetto
- `CIG`: Codice Identificativo Gara

👉 [cup_cig_anac_pnrr.csv](data/cup_cig_anac_pnrr.csv)

### cup_cig_anac_pnrr_merge.csv

È il file finale che unisce i dati provenienti sia da ANAC che da Italia Domani, con l'indicazione della fonte. Dal file sono stati esclusi i record con CUP uguale a "N/A" o CIG uguale a "NULL".

Schema:

- `CUP`: Codice Unico di Progetto
- `CIG`: Codice Identificativo Gara
- `fonte`: Origine del dato ("anac" o "italiadomani")

👉 [cup_cig_anac_pnrr_merge.csv](data/cup_cig_anac_pnrr_merge.csv)
