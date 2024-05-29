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
| tipologia_apparecchio | string | Tipologia di apparecchio: A o B, o A/B (entrambi), secondo la descrizione dei comma 6a e 6b dell'articolo 110 del [testo unico delle leggi di pubblica sicurezza](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:regio.decreto:1931-06-18;773!vig=2024-05-28) |
| anagrafica_modificata | integer | Due valori possibili: 0 quando l'anagrafica di nome Comune e/o Provincia non è stata modificata/corretta, 1 quando lo è stata |
| istat_comune_nome | string | Nome del Comune secondo Istat |

La colonna `Tipologia colonna`, indica il tipo di dato presente nella colonna. I tipi qui sono:

- `number`: Il campo contiene numeri di qualsiasi tipo, compresi i decimali;
- `integer`: Il campo contiene numeri interi;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.

#### Tipologia apparecchi

La tipologia di apparecchi è definita nella colonna `tipologia_apparecchio` e può assumere i seguenti valori, secondo la descrizione dei comma 6a e 6b dell'articolo 110 del [testo unico delle leggi di pubblica sicurezza](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:regio.decreto:1931-06-18;773!vig=2024-05-28):

- A, "*quelli che, dotati di attestato di conformità alle disposizioni vigenti rilasciato dal Ministero dell'economia e delle finanze - Amministrazione autonoma dei Monopoli di Stato e obbligatoriamente collegati alla rete telematica di cui all'[articolo 14-bis, comma 4, del decreto del Presidente della Repubblica 26 ottobre 1972, n. 640](https://www.normattiva.it/uri-res/N2Ls?urn:nir:presidente.repubblica:decreto:1972-10-26;640~art14bis-com4), e successive modificazioni, si attivano con l'introduzione di moneta metallica ovvero con appositi strumenti di pagamento elettronico definiti con provvedimenti del Ministero dell'economia e delle finanze - Amministrazione autonoma dei monopoli di Stato, nei quali insieme con l'elemento aleatorio sono presenti anche elementi di abilità, che consentono al giocatore la possibilità di scegliere, all'avvio o nel corso della partita, la propria strategia, selezionando appositamente le opzioni di gara ritenute più favorevoli tra quelle proposte dal gioco, il costo della partita non supera 1 euro, la durata minima della partita è di quattro secondi e che distribuiscono vincite in denaro, ciascuna comunque di valore non superiore a 100 euro, erogate dalla macchina*".
- B, "*quelli, facenti parte della rete telematica di cui all'[articolo 14-bis, comma 4, del decreto del Presidente della Repubblica 26 ottobre 1972, n. 640](https://www.normattiva.it/uri-res/N2Ls?urn:nir:presidente.repubblica:decreto:1972-10-26;640~art14bis-com4), e successive modificazioni, che si attivano esclusivamente in presenza di un collegamento ad un sistema di elaborazione della rete stessa*".
- A/B, quando nell'esercizio sono presenti entrambe le tipologie di apparecchi.


In termini più semplici:

- A, in pubblici esercizi come accessorio di altra attività prevalente;
- B, Sale Videolottery Terminal (VLT) dedicate.

### Note

Questi dati dovrebbero essere pubblicati anche in formati "leggibile meccanicamente", come `CSV` o `JSON`, e non solo come pagine  `HTML`. Lo prevedono le norme e linee guida italiane sui dati della Pubblica Amministrazione. Tra questi l'[articolo 6](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art6) del Decreto Legislativo 24 gennaio 2006, n. 36, che rimanda a sua volta all'[articolo 2](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art2), che stabilisce che gli enti pubblici devono utilizzare formati di dati che favoriscano la loro riutilizzazione, che siano appunto in formato leggibile meccanicamente.

A ogni Comune andrebbe associato anche il codice Istat di ciascuno, per consentire la correlazione immediata con altri dati. Non era presente nelle pagine e lo abbiamo aggiunto. Abbiamo anche corretto alcuni nomi di Comuni e qualche associazione di Comune a Provincia.<br>
Un elenco di modifiche e errori è in [questo file](../risorse/comuni_correggere.csv).
