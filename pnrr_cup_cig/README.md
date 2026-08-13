# PNRR: il collegamento tra progetti e gare d'appalto

Questa cartella è stata creata per scaricare e incrociare alcuni dati dei progetti del PNRR (Piano Nazionale di Ripresa e Resilienza) con altri pubblicati dall'Autorità Nazionale Anticorruzione (ANAC).

Questo lavoro è utile perché, ad esempio, al 27 aprile 2025 i progetti del PNRR associati a un Codice Identificativo Gara (**CIG**) nel [catalogo dati ufficiale del PNRR](https://www.italiadomani.gov.it/content/sogei-ng/it/it/catalogo-open-data.html) sono circa **40.000**.<br>
Se invece si incrociano i dati aperti del PNRR con quelli pubblicati da ANAC sulle coppie Codice Unico Progetto (**CUP**) - Codice Identificativo Gara (CIG), i progetti associati salgono a circa **120.000**.

Questo permette quindi di seguire un numero molto maggiore di progetti e monitorare più da vicino la spesa pubblica.

Lo [script](script/pnrr_cup_cig.sh) recupera:

- i dati dei [**progetti PNRR**](https://www.italiadomani.gov.it/content/sogei-ng/it/it/catalogo-open-data/Progetti_del_PNRR.html) da Italia Domani;
- i dati delle [**gare PNRR**](https://www.italiadomani.gov.it/content/sogei-ng/it/it/catalogo-open-data/gare-dei-progetti-del-pnrr.html) da Italia Domani;
- i [**dati**](https://dati.anticorruzione.it/opendata/dataset/cup) sulle coppie di Codice Unico Progetto (**CUP**) e Codice Identificativo Gara (**CIG**) pubblicati da ANAC.

Gestire i dati sulle gare è complesso, non solo per i possibili disallineamenti tra le banche dati, ma anche per la presenza di relazioni non semplici tra CUP e CIG, che possono essere di tipo uno-a-molti (1:N) o molti-a-uno (N:1). Inoltre, alcune gare sono relative a servizi accessori o spese non direttamente collegate al progetto, come spiegato anche nelle [**FAQ ufficiali**](https://www.italiadomani.gov.it/content/sogei-ng/it/it/faq/opendata.html).

Alcune procedure di aggiudicazione, pur presenti nei dati ANAC, **potrebbero non risultare associate in Italiadomani** (il catalogo dati pubblico ufficiale sul PNRR).<br>
Questo può succedere:

- perché l'associazione è ancora in corso,
- oppure perché il Soggetto Attuatore o il RUP ha valutato che si tratta di **spese esterne al progetto principale**.

Infine, **alcune misure del PNRR non prevedono gare d'appalto**: ad esempio i progetti per assunzioni di personale, strumenti finanziari, attività di ricerca, formazione, crediti d'imposta o concessioni di incentivi.

## Come vengono scaricate le fonti

Entrambe le fonti bloccano le richieste che arrivano dagli indirizzi IP dei runner di GitHub Actions, dove lo script gira ogni lunedì. Sono due blocchi distinti, verificati il 13 agosto 2026, ed entrambi restituiscono **403**:

- **ANAC** (WAF F5/Volterra) blocca in base all'indirizzo IP. Non dipende dal client né dallo `User-Agent`: la stessa richiesta che dal runner riceve 403 va a buon fine da un IP italiano.
- **Italia Domani** (Akamai) blocca in base all'indirizzo IP e in più pretende che la richiesta abbia **sia** uno `User-Agent` da browser **sia** l'header `Range`: se manca uno dei due risponde 403 anche da un IP ammesso. L'header `Range: bytes=0-` richiede l'intero file mantenendo l'header presente.

Lo script quindi non scarica sempre dalle fonti originali:

- il file ANAC passa da un **proxy**, il cui indirizzo è nel secret `ANAC_PROXY_URL` del repository;
- i due CSV di Italia Domani vengono scaricati da una **funzione serverless ospitata in Francia**, che li preleva con gli header richiesti e li deposita su un bucket pubblico; lo script invoca la funzione e poi legge i file dal bucket. Gli indirizzi sono nei secret `ITALIADOMANI_REFRESH_URL` e `ITALIADOMANI_BUCKET_URL`.

Quando le variabili d'ambiente corrispondenti non sono presenti — cioè eseguendo lo script in locale da una connessione italiana — il download avviene direttamente dalle fonti originali, senza intermediari.

Ogni esecuzione, riuscita o fallita, aggiunge una riga a [`data/update_log.jsonl`](data/update_log.jsonl) con esito, codice HTTP e causa dell'errore. Gli indirizzi degli intermediari vengono oscurati prima della scrittura, perché quel file è versionato.

> **Nota per il futuro:** la chiave di accesso usata dalla funzione serverless scade il **13 agosto 2027**. Dopo quella data la funzione continuerà a scaricare da Italia Domani ma non riuscirà più a scrivere sul bucket, e lo script fallirà sul download dei CSV: la causa sarà la chiave scaduta, non un nuovo blocco della fonte.

## File di output

### cup_cig_anac_pnrr.csv

Contiene l'associazione tra CUP dei progetti PNRR e CIG presenti nei dati ANAC. È il risultato dell'incrocio tra i CUP dei progetti PNRR e i dati di ANAC.

Schema:

- `CUP`: Codice Unico di Progetto
- `CIG`: Codice Identificativo Gara

👉 [cup_cig_anac_pnrr.csv](data/cup_cig_anac_pnrr.csv)

L'URL raw è <https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/pnrr_cup_cig/data/cup_cig_anac_pnrr.csv>

### cup_cig_anac_pnrr_merge.csv

È il file finale che unisce i dati provenienti sia da ANAC che da Italia Domani, con l'indicazione della fonte. Dal file sono stati esclusi i record con CUP uguale a "N/A" o CIG uguale a "NULL".

Schema:

- `CUP`: Codice Unico di Progetto
- `CIG`: Codice Identificativo Gara
- `fonte`: Origine del dato ("anac" o "italiadomani")

👉 [cup_cig_anac_pnrr_merge.csv](data/cup_cig_anac_pnrr_merge.csv)

L'URL raw è <https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/pnrr_cup_cig/data/cup_cig_anac_pnrr_merge.csv>
