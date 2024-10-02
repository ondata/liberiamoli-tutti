# Dati sui sondaggi politici nazionali

Questo dataset è il frutto di estrazione automatizzata a partire da dati unstructured a cura di [Ruggero Marino Lazzaroni](https://twitter.com/ruggsea) (per maggiori informazioni puoi leggere il [numero 8 della newsletter di Liberiamoli tutti](https://datibenecomune.substack.com/p/305694d9-dd32-472f-b23a-8ebbd87129d1)). L'ulteriore pulizia e normalizzazione dei dati è stata effettuata dall'[associazione onData](https://www.ondata.it/).

## Folders structure 
```
🌳 /liberiamoli-tutti/italian_polls/
├── 📄 README.md
├── 📁 data
├── 📄 datapackage.yaml
├── 📁 metadata
└── 📁 script
```

## Data Dictionary
### 📄 [Anagrafica](data/anagrafica.csv)
Sono presenti i dati di base di ogni sondaggio, come il titolo, la data di inserimento, il realizzatore, il committente, la domanda posta, il testo non strutturato contenente i risultati del sondaggio (per partito) espressi in percentuale, il numero di partiti presenti nel sondaggio...

Esistono 2 distribuzioni (aventi la stessa struttura) di questi dati (CSV e jsonl):
- Path: 
  - `data/anagrafica.csv`
  - `data/anagrafica.jsonl`
- URL:
  - https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/italian_polls/data/anagrafica.csv
  https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/italian_polls/data/anagrafica.jsonl
- Encoding: `utf-8`

| Field | Type | Description | Example |
| --- | --- | --- | --- |
| n | integer | ID sondaggio: ID del sondaggio (può cambiare nel tempo ma sarà sempre sincronizzato con la tabella dei risultati) | 1394 |
| data_inserimento | date | Data di inserimento del sondaggio nella piattafoma https://www.sondaggipoliticoelettorali.it/ (vd. sources) | 2024-10-01 |
| realizzatore | string | Realizzatore del sondaggio | SWG spa |
| committente | string | Committente del sondaggio | La7 |
| titolo | string | Titolo del sondaggio | intenzioni di voto |
| testo | string | Testo non strutturato contenente i risultati del sondaggio (per partito) espressi in percentuale | FRATELLI D'ITALIA 29,8 PARTITO DEMOCRATICO 22,4 MOVIMENTO 5 STELLE 11,8 LEGA 8,4 FORZA ITALIA 8,3 VERDI E SINISTRA 7,1 AZIONE 3,0 ITALIA VIVA 2,5 +EUROPA 1,7 SUD CHIAMA NORD 1,2 NOI MODERATI 1,0 ALTRE LISTE 2,8 NON SI ESPRIME 33% |
| domanda | string | Domanda posta nel sondaggio | Se dovesse votare oggi alle elezioni nazionali, a quale dei seguenti partiti darebbe il suo voto più probabilmente? |
| national_poll_rationale | string | Motivazione (in lingua inglese) per cui è stato considerato un sondaggio nazionale. I valori di questo campo sono generati da un LLM. | The poll includes all major parties such as Fratelli d'Italia, Partito Democratico, Movimento 5 Stelle, Lega, Forza Italia, and others. It refers to nationwide voting intentions, making it a national voting intention poll. The percentages for 'Altri' (other parties) are calculated by summing the percentages of parties not listed explicitly, which includes 'NOI MODERATI' and 'ALTRE LISTE'. |
| national_poll | integer | Indicatore: 1 se il sondaggio è considerato nazionale, 0 altrimenti. I valori di questo campo sono generati da un LLM. | 1 |
| numero_partiti | integer | Numero di partiti presenti nel sondaggio | 11 |
| realizzatore_normalizzato | string | Nome del realizzatore del sondaggio normalizzato tramite tecniche di clustering. | SWG spa |

### 📄 [Risultati](data/risultati.csv)
Sono presenti i risultati di ogni sondaggio, espressi in percentuale per partito politico.

Esistono 2 distribuzioni (aventi la stessa struttura) di questi dati (CSV e jsonl):

- Path:
  - `data/risultati.csv`
  - `data/risultati.jsonl`
- URL:
  - https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/italian_polls/data/risultati.csv
  - https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/italian_polls/data/risultati.jsonl
- Encoding: `utf-8`

| Field | Type | Description | Example |
| --- | --- | --- | --- |
| n | integer | ID sondaggio: ID del sondaggio (può cambiare nel tempo ma sarà sempre sincronizzato con la tabella dell'anagrafica) | 1394 |
| data_inserimento | date | Data di inserimento del sondaggio nella piattaforma https://www.sondaggipoliticoelettorali.it/ (vd. sources) | 2024-10-01 |
| partito | string | Partito politico: Nome del partito politico a cui si riferiscono i risultati | Partito Democratico |
| valore | number | Risultato del sondaggio per il partito politico espresso in percentuale. | 22.4 |

## 👥 Contributors
| Name | Role |
| --- | --- | 
| Ruggero Marino Lazzaroni | creator | 
| Andrea Borruso | dataCurator |

