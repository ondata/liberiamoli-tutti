---
html:
  toc: false

---

# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti**](https://datibenecomune.substack.com/about).

## Dati

Sono in formato `CSV`, con separatore `,` e con codifica `UTF-8`.

La fonte sono le pagine web della [sezione "**Istituti penitenziari**"](https://www.giustizia.it/giustizia/page/it/istituti_penitenziari), presente nel sito del Ministero della Giustizia.

👉 **Nota Bene**: questi sono rilasciati con **licenza** [**CC-BY 4.0**](https://creativecommons.org/licenses/by/4.0/deed.it): li **puoi usare liberamente**, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo semplicemente "Fonte: [Liberiamoli tutti!](https://datibenecomune.substack.com/)" e inserendo il link ipertestuale a `https://datibenecomune.substack.com/`.

L'elenco dei dati è il seguente:

    - [Anagrafica](#anagrafica)
    - [Capienza e presenze](#capienza-e-presenze)
    - [Spazi d'incontro con i visitatori](#spazi-dincontro-con-i-visitatori)
    - [Spazi comuni e impianti](#spazi-comuni-e-impianti)
    - [Stanze](#stanze)
    - [Personale](#personale)


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

## Note

### Tipologia dati

La colonna `Tipologia colonna` indica il tipo di dato presente nella colonna. I tipi sono:

- `date`: Questo tipo di campo è utilizzato per contenere date e/o orari. Nel contesto di questo dati si tratte di date in formato anno-mese-giorno (YYYY-MM-DD), come ad esempio `2020-01-18`;
- `number`: il campo contiene numeri di qualsiasi tipo, compresi i decimali;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.
