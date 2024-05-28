# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti!**](https://datibenecomune.substack.com/about)", e in particolare [nel "**numero 5**"](https://datibenecomune.substack.com/p/liberiamoli-tutti-numero-5) della newsletter di progetto.

## Dati

L'Agenzia delle Dogane e dei Monopoli, pubblica in centinaia di pagine HTML l'elenco dei soggetti abilitati alle attività funzionali alla raccolta del gioco mediante apparecchi con vincita in denaro.

Questi dati sono in particolare quelli relativi all'"[Elenco soggetti per esercizi](https://www.adm.gov.it/portale/monopoli/giochi/apparecchi_intr/elenco_soggetti_ries?el=2)", con informazioni su denominazione, indirizzo, comune, provincia, tipologia esercizio, superficie del locale in metri quadrati e i codici di censimento esercizio e iscrizione soggetto.

Li abbiamo estratti il 26 aprile 2024 dal sito di origine, e ripubblicati in [formato `CSV`](ries.csv), con separatore `,`, con codifica `UTF-8` e con il `.` come separatore dei decimali.

👉 **Nota Bene**: sono rilasciati con **licenza** [**CC-BY 4.0**](https://creativecommons.org/licenses/by/4.0/deed.it). Li **puoi usare liberamente**, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo semplicemente "Fonte: [Liberiamoli tutti!](https://datibenecomune.substack.com/)" e inserendo il link ipertestuale a `https://datibenecomune.substack.com/`.

### Elenco degli esercizi dei soggetti abilitati alle attività funzionali alla raccolta del gioco mediante apparecchi con vincita in denaro

Il file è [`ries.csv`](ries.csv), ed è composto dalle colonne descritte a seguire:

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| codice_comune_alfanumerico | string | Codice comune Istat |
| provincia | string | Sigla provincia |
| comune | string | Nome del Comune, così come riportato sul sito dell'Agenzia delle Dogane e dei Monopoli |
| codice_censimento_esercizio | string | Codice di censimento dell'esercizio |
| denominazione | string | Denominazione dell'esercizio |
| indirizzo | string | Indirizzo dell'esercizio |
| comune_e_provincia | string | Comune e provincia |
| tipologia_esercizio | string | Tipologia dell'esercizio |
| superficie_del_locale_in_mq | number | Superficie del locale in metri quadrato |
| codice_iscrizione_soggetto | string | Codice di iscrizione del soggetto titolare dell'esercizio |
| tipologia_apparecchio | string | Tipologia di apparecchio |
| anagrafica_modificata | integer | Due valori possibili: 0 quando l'anagrafica di nome Comune e/o Provincia non è stata modificata/corretta, 1 quando lo è stata |
| istat_comune_nome | string | Nome del Comune secondo Istat |

La colonna `Tipologia colonna`, indica il tipo di dato presente nella colonna. I tipi qui sono:

- `number`: Il campo contiene numeri di qualsiasi tipo, compresi i decimali;
- `integer`: Il campo contiene numeri interi;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.

### Note

Questi dati dovrebbero essere pubblicati anche in formati "leggibile meccanicamente", come `CSV` o `JSON`, e non solo come pagine  `HTML`. Lo prevedono le norme e linee guida italiane sui dati della Pubblica Amministrazione. Tra questi l'[articolo 6](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art6) del Decreto Legislativo 24 gennaio 2006, n. 36, che rimanda a sua volta all'[articolo 2](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art2), che stabilisce che gli enti pubblici devono utilizzare formati di dati che favoriscano la loro riutilizzazione, che siano appunto in formato leggibile meccanicamente.

A ogni Comune andrebbe associato anche il codice Istat di ciascuno, per consentire la correlazione immediata con altri dati. Non era presente nelle pagine e lo abbiamo aggiunto. Abbiamo anche corretto alcuni nomi di Comuni e qualche associazione di Comune a Provincia.<br>
Un elenco di modifiche e errori è in [questo file](../risorse/comuni_correggere.csv).
