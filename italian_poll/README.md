- [Introduzione](#introduzione)
  - [Modifiche introdotte](#modifiche-introdotte)
  - [Altre modifiche introdotte](#altre-modifiche-introdotte)
    - [Date in formato AAAA-MM-GG](#date-in-formato-aaaa-mm-gg)
    - [Normalizzazione dei nomi dei campi](#normalizzazione-dei-nomi-dei-campi)
    - [Numero di partiti per sondaggio](#numero-di-partiti-per-sondaggio)
    - [Normalizzazione nome "Realizzatore"](#normalizzazione-nome-realizzatore)
  - [I dati estratti](#i-dati-estratti)
  - [Se usi questi dati](#se-usi-questi-dati)

# Introduzione

Qui pubblichiamo i dati sui sondaggi politici nazionali, derivati da quelli estratti da **Ruggero Marino Lazzaroni** (grazie mille), descritti nel [**numero 8 di Liberiamoli tutti!**](https://datibenecomune.substack.com/p/305694d9-dd32-472f-b23a-8ebbd87129d1) e pubblicati in [questo *repository*](https://github.com/ruggsea/llm_italian_poll_scraper).

## Modifiche introdotte

Ruggero pubblica **un solo dataset**, in **due formati**: [`JSON Lines`](https://raw.githubusercontent.com/ruggsea/llm_italian_poll_scraper/refs/heads/main/italian_polls.jsonl) e [`CSV`](https://raw.githubusercontent.com/ruggsea/llm_italian_poll_scraper/refs/heads/main/italian_polls.csv).

Ha scelto una **rappresentazione _wide_** dei dati, in cui per ogni sondaggio ci sono i relativi metadati e una colonna per ogni partito politico, con il relativo risultato.<br>
Per dare soltanto un'idea, non è la struttura esatta, sono come nel seguente esempio:

| Data Inserimento | Realizzatore | Committente | Titolo | domanda | Partito 1 | Partito 2 | Partito 3 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01/09/2024 | Istituto ABC | Committente X | Sondaggio Elezioni | Quale partito voti? | 30 | 25 | 45 |
| 02/09/2024 | Istituto XYZ | Committente Y | Opinione Pubblica | Sei favorevole a...? | 35 | 40 | 25 |
| 03/09/2024 | Sondaggista Zeta | Committente Z | Indagine Politica | Qual è il leader? | 28 | 32 | 40 |
| 04/09/2024 | Istituto Alfa | Committente W | Preferenze 2024 | Cosa ne pensi di...? | 22 | 38 | 40 |
| 05/09/2024 | Istituto Beta | Committente V | Elezioni | Chi voti alle ....? | 34 | 30 | 36 |

Noi abbiamo scelto di **suddividere** la **tabella** originale **in due** - una per i metadati e una per i risultati - e di passare **da** una rappresentazione ***wide*** a una ***long***.

Quindi rispetto al dataset originale, è disponibile una prima **tabella** con soltanto i **metadati**:

| id_sondaggio | Data Inserimento | Realizzatore | Committente | Titolo | domanda |
| --- | --- | --- | --- | --- | --- |
| 1 | 01/09/2024 | Istituto ABC | Committente X | Sondaggio Elezioni | Quale partito voti? |
| 2 | 02/09/2024 | Istituto XYZ | Committente Y | Opinione Pubblica | Sei favorevole a...? |
| 3 | 03/09/2024 | Sondaggista Zeta | Committente Z | Indagine Politica | Qual è il leader? |
| 4 | 04/09/2024 | Istituto Alfa | Committente W | Preferenze 2024 | Cosa ne pensi di...? |
| 5 | 05/09/2024 | Istituto Beta | Committente V | Elezioni | Chi voti alle ....? |

E una seconda **tabella** con i **risultati**, in formato *long*, con una sola colonna per i partiti politici, una per i risultati, una per la data (che era comodo avere anche qui) e una per il riferimento al sondaggio:

| id_sondaggio | Data Inserimento | partito | valore |
| --- | --- | --- | --- |
| 1 | 01/09/2024 | Partito 1 | 30 |
| 1 | 01/09/2024 | Partito 2 | 25 |
| 1 | 01/09/2024 | Partito 3 | 45 |
| 2 | 02/09/2024 | Partito 1 | 35 |
| 2 | 02/09/2024 | Partito 2 | 40 |
| 2 | 02/09/2024 | Partito 3 | 25 |
| 3 | 03/09/2024 | Partito 1 | 28 |
| 3 | 03/09/2024 | Partito 2 | 32 |
| 3 | 03/09/2024 | Partito 3 | 40 |
| 4 | 04/09/2024 | Partito 1 | 22 |
| 4 | 04/09/2024 | Partito 2 | 38 |
| 4 | 04/09/2024 | Partito 3 | 40 |
| 5 | 05/09/2024 | Partito 1 | 34 |
| 5 | 05/09/2024 | Partito 2 | 30 |
| 5 | 05/09/2024 | Partito 3 | 36 |

Questa scelta è stata fatta perché per diversi utenti potrà essere più comodo lavorare con i dati rappresentati in questa forma.

## Altre modifiche introdotte

Abbiamo introdotto nei nostri dati derivati altre piccole modifiche.

### Date in formato AAAA-MM-GG

I dati originali hanno la data espressa come nel sito di origine, in formato `GG/MM/AAAA` (giorno/mese/anno). Noi abbiamo scelto di rappresentarle in formato `AAAA-MM-GG` (anno-mese-giorno), perché è un formato che evita un possibile passaggio di trasformazione, perché la forma `AAAA-MM-GG` è quella tipicamente di default per i *software* di analisi dati.

### Normalizzazione dei nomi dei campi

Nel file originale sono presenti ad esempio (tra gli altri) questi nomi di campi: `Data Inserimento`, `Realizzatore`, `Committente`, `Titolo`, `text`, ecc..

Li abbiamo normalizzati scegliendo lo snake_case, in cui i nomi dei campi sono scritti in minuscolo e separati da un trattino basso `_`: `data_inserimento`, `realizzatore`, `committente`, `titolo`, `text`, ecc..

### Numero di partiti per sondaggio

Nella tabella dei metadati abbiamo aggiunto una colonna con il numero di partiti politici presenti in ogni sondaggio. È il campo `numero_partiti`.

### Normalizzazione nome "Realizzatore"

Abbiamo applicato una normalizzazione al campo `realizzatore`, perché spesso il nome della stessa azienda è scritto in modi diversi, per un carattere maiuscolo o minuscolo in più o in meno, per la presenza o meno di spazi, ecc.: "Istituto ABC", "istituto ABC", "Istituto    Abc", "Istituto ABC ", "Istituto ABC.", ecc..

Non è una normalizzazione completa, ma è una prima scrematura.

È realizzata nel campo `realizzatore_normalizzato`, presente nella tabella dei metadati.

## I dati estratti

Anche noi abbiamo scelto i formati [`JSON Lines`](https://jsonlines.org/) e `CSV` per i nostri dati derivati. Il `JSON Lines` è un file di testo in cui ogni riga è un oggetto JSON, è una sorta di CSV "intelligente" (in cui ad esempio è possibile distinguere un numero decimale da una stringa di testo).

Tutti i file hanno codifica dei campi in `UTF-8`. Il separatore di campo per i file `CSV` è la virgola `,` e il separatore decimale è il punto `.`.

Questi file:

- i metadati
  - in formato [`JSON Lines`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/refs/heads/main/italian_poll/data/italian_polls_metadata.jsonl)
  - in formato [`CSV`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/refs/heads/main/italian_poll/data/italian_polls_metadata.csv)
- i risultati
  - in formato [`JSON Lines`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/refs/heads/main/italian_poll/data/italian_polls_clean.jsonl)
  - in formato [`CSV`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/refs/heads/main/italian_poll/data/italian_polls_clean.csv)

## Se usi questi dati

Sono dati aperti, rilasciati con licenza [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.it), quindi puoi usarli come vuoi, anche per scopi commerciali, ma citando la fonte.

Se li usi, cita la fonte scrivendo qualcosa come: "dati raccolti da [Ruggero Marino Lazzaroni](https://github.com/ruggsea/llm_italian_poll_scraper) e [rielaborati da OnData](https://github.com/ondata/liberiamoli-tutti/blob/main/italian_poll/README.md#L87)".
