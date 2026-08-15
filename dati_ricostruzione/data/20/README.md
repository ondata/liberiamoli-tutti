# Dati — Ricostruzione post-sisma 2016-2017 (numero #20)

Dataset sulla ricostruzione pubblica e privata nelle quattro regioni del Centro Italia colpite dal sisma 2016-2017 (Abruzzo, Lazio, Marche, Umbria), ottenuti tramite richiesta FOIA presentata al Commissario Straordinario per il sisma 2016 da ActionAid Italia.

Il 23 giugno 2026 il Commissario ha pubblicato il nuovo rapporto sulla ricostruzione, ripubblicandolo il 2 luglio con alcuni allegati, fra cui uno sulla ricostruzione pubblica privo di CUP, categorie e marcatori utili al monitoraggio. È seguita la richiesta FOIA, con riscontro nel luglio 2026.

Fonte originale: Commissario Straordinario per la ricostruzione sisma 2016 — piattaforma GE.DI.SI.

Il file di consegna è [`2026-07-23_dati_final_2026_opere_private_e_pubbliche.xlsx`](../../rawdata/2026-07-23_dati_final_2026_opere_private_e_pubbliche.xlsx) e contiene due fogli, che alimentano due file diversi:

| Foglio | Contenuto | Data di riferimento | Diventa |
|---|---|---|---|
| `OOPP_2026` | ricostruzione pubblica, un intervento per riga | 30 aprile 2026, da "FASE di avanzamento al 30 aprile 2026" | [`pubblica.csv`](pubblica.csv) |
| `Ric_Priv_All_1_2026` | ricostruzione privata, aggregata per comune | 31 maggio 2026, da "Allegato 1: DataBase della Ricostruzione Privata al 31 maggio 2026" | [`privata_comuni.csv`](privata_comuni.csv) |

Le date di riferimento sono diverse: un mese separa le due rilevazioni, che quindi non vanno confrontate come se fossero contemporanee.

Elaborazione: [`script/dati_ricostruzione_20.sh`](../../script/dati_ricostruzione_20.sh).

---

## File

### `pubblica.csv`

[`pubblica.csv`](pubblica.csv) elenca 3.667 interventi di ricostruzione pubblica, in 345 comuni, per un importo programmato complessivo di circa 4,86 miliardi di euro.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `comune` | testo | Nome del comune, come nella consegna |
| `prov` | testo | Sigla automobilistica della provincia, come nella consegna. Vuota in 2 righe, valorizzata a `Comuni vari` in 4 |
| `ocos` | testo | Tipo di opera: `OC` = opere comunali, `OS` = opere statali. Campo ricostruito, vedi sotto |
| `ocos_label` | testo | Descrizione estesa di `ocos`: `Opere comunali` o `Opere statali` |
| `eues_id` | testo | Identificativo dell'intervento nel sistema GE.DI.SI., come nella consegna |
| `eues_id_norm` | testo | Identificativo normalizzato, confrontabile con le altre edizioni. Campo aggiunto, vedi sotto |
| `ordinanza_attuale` | testo | Ordinanza di riferimento (`OC_nnn` per le commissariali, `OS_nnn` per le speciali). Valori multipli separati da `;` |
| `regione` | testo | Regione di localizzazione, come nella consegna: compare in grafie diverse (`MARCHE` e `Marche`). Per un valore normalizzato usare `cod_istat_comune` |
| `cupxall` | testo | Codice Unico di Progetto, come nella consegna. Assente in 93 righe, non valido in 7, e in 8 righe contiene più CUP nella stessa cella |
| `codice_usr` | testo | Riferimento interno dell'Ufficio Speciale per la Ricostruzione regionale. Non è una chiave, vedi sotto |
| `denominazione_interventoxall` | testo | Descrizione dell'intervento. In 1.052 righe è scritta tutta in maiuscolo, come nella consegna |
| `categoria` | testo | Categoria tipologica, codice e descrizione insieme. Il codice 10 non è univoco, vedi sotto |
| `importo_programmato_esclusi_oc_126` | numero | Importo in euro. Nella consegna la colonna si chiama per esteso "Importo  programmato  per  intervento  € (esclusa assegnazione con Decreti OC-126)": è quindi l'importo programmato, al netto delle assegnazioni disposte con i Decreti OC-126. Vuoto in 5 righe, pari a zero in 7 |
| `fase_di_avanzamento_al_30_aprile_2026` | testo | Fase procedurale al 30 aprile 2026, come nella consegna: codice e descrizione insieme, con descrizioni non uniformi |
| `cod_istat_comune` | testo | Codice Istat del comune a 6 cifre. Campo aggiunto, vedi sotto. Vuoto in 6 righe |
| `fase_id` | testo | Codice della fase (`FA_0` … `FA_10`). Campo aggiunto |
| `fase_label` | testo | Descrizione della fase, uniformata. Campo aggiunto |
| `soggetto_attuatore` | testo | Ente responsabile dell'intervento. Campo ricostruito da OpenCUP, vedi sotto. Valorizzato in 3.514 righe |
| `cf_piva_soggetto_attuatore` | testo | Codice fiscale o partita IVA del soggetto attuatore. Campo aggiunto |

### `privata_comuni.csv`

[`privata_comuni.csv`](privata_comuni.csv) contiene i dati sulla ricostruzione privata aggregati per comune: 429 comuni, con 36.149 richieste di contributo presentate, 17,82 miliardi di euro richiesti, 12,59 concessi e 8,05 liquidati.

Non è un elenco di interventi: nel foglio di consegna ogni riga è un comune, con i totali delle richieste di contributo per la ricostruzione (RCR). Le voci sommano danni lievi e danni gravi, come indicato nell'intestazione originale ("TOTALE DANNI LIEVI +DANNI GRAVI").

| Colonna | Tipo | Descrizione |
|---|---|---|
| `regione` | testo | Regione |
| `provincia` | testo | Provincia, per esteso (`L'Aquila`, non `AQ`) |
| `comune` | testo | Nome del comune, come nella consegna |
| `rcr_presentate` | numero | Richieste di contributo presentate ("Tot. Pres.") |
| `rcr_approvate` | numero | Richieste approvate |
| `importo_richiesto` | numero | Importo richiesto in euro |
| `importo_concesso` | numero | Importo concesso in euro |
| `importo_liquidato` | numero | Importo liquidato in euro |
| `cantieri_in_corso` | numero | Cantieri in corso |
| `cantieri_chiusi` | numero | Cantieri chiusi |
| `cod_istat_comune` | testo | Codice Istat del comune a 6 cifre. Campo aggiunto, valorizzato su tutte le righe |

### `cup.csv`

[`cup.csv`](cup.csv) elenca i 3.482 CUP distinti presenti nel dataset, in una sola colonna `cup`. È la base per le lavorazioni che partono dal codice progetto, a cominciare dal recupero dei CIG.

Le celle che contengono più CUP sono state spezzate, così i 19 codici che stanno lì dentro non vanno persi. Sono inclusi solo i CUP formalmente validi, cioè di 15 caratteri alfanumerici: restano quindi fuori i 7 codici malformati elencati più avanti.

### `cup_cig.csv`

[`cup_cig.csv`](cup_cig.csv) associa i CUP del dataset ai CIG (Codice Identificativo Gara) delle procedure collegate: 14.204 coppie, 13.417 CIG distinti su 3.051 CUP.

I CIG non fanno parte del riscontro FOIA — la loro assenza è una delle lacune segnalate — e sono stati recuperati dal [dataset `cup` di ANAC](https://dati.anticorruzione.it/opendata/dataset/cup), il ponte fra CUP e CIG della Banca Dati Nazionale dei Contratti Pubblici, nella versione del 6 agosto 2026.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cup` | testo | CUP, come in `cup.csv` |
| `cig` | testo | CIG associato al CUP secondo ANAC |
| `url_cig` | testo | URL della scheda del CIG sul portale dati ANAC |

La relazione è molti-a-molti: un CUP può avere più CIG e uno stesso CIG può essere associato a più CUP. Sommare importi lungo questo join senza una regola esplicita di deduplicazione porta a conteggi gonfiati.

Va inoltre tenuto presente che ANAC non è l'unica fonte di associazione CUP-CIG, e le fonti non coincidono del tutto: BDAP MOP, limitata alle opere pubbliche, associa qualche coppia in più. Qui è stata usata ANAC per copertura e aggiornamento.

#### Quanti interventi hanno un CIG

3.131 interventi su 3.667 hanno almeno un CIG: l'85,4%. L'assenza però non è distribuita a caso.

| Fase | Interventi | Senza CIG | % senza |
|---|---:|---:|---:|
| `FA_0` Rup non nominato | 93 | 79 | 84,9% |
| `FA_1` Rup nominato e cronoprogramma condiviso | 207 | 114 | 55,1% |
| `FA_2` Avvio procedure di affidamento contraente per i servizi | 218 | 80 | 36,7% |
| `FA_3` Incarico di progettazione affidato | 601 | 67 | 11,1% |
| `FA_4` Progetto definitivo/PFTE approvato | 713 | 34 | 4,8% |
| `FA_5` Progetto esecutivo approvato | 367 | 55 | 15,0% |
| `FA_6` Avvio procedure per l'aggiudicazione dei lavori | 233 | 9 | 3,9% |
| `FA_7` Inizio lavori | 548 | 14 | 2,6% |
| `FA_8` Fine lavori | 196 | 31 | 15,8% |
| `FA_9` Collaudo | 488 | 52 | 10,7% |
| `FA_10` Rinunce/Revoche | 3 | 1 | 33,3% |

Nelle prime fasi l'assenza è attesa: senza RUP nominato non c'è procedura di gara, quindi non c'è CIG. Nelle ultime no: 83 interventi risultano a lavori conclusi o collaudati senza alcun CIG associato (31 in fine lavori, 52 in collaudo), ai quali si aggiungono 14 con il cantiere già aperto. Sono opere realizzate che non risultano collegate ad alcuna procedura nella banca dati nazionale dei contratti pubblici.

### `opencup.csv`

[`opencup.csv`](opencup.csv) contiene l'anagrafica dei progetti, una riga per CUP: 3.457 progetti sui 3.482 CUP del dataset. Fonte: [API OpenCUP](https://opencup.gov.it), il registro nazionale dei progetti di investimento pubblico.

Serve soprattutto a ricostruire il soggetto attuatore, che la consegna 2026 non contiene più (vedi sotto), ma porta anche una classificazione dell'intervento indipendente da quella della consegna e gli importi di progetto.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cup` | testo | Codice Unico di Progetto |
| `soggetto_titolare` | testo | Ente titolare del progetto |
| `cf_piva_soggetto` | testo | Codice fiscale o partita IVA dell'ente: chiave di aggancio verso IPA e ANAC |
| `categoria_soggetto`, `sotto_categoria_soggetto` | testo | Classificazione dell'ente |
| `natura` | testo | Natura dell'intervento (es. `REALIZZAZIONE DI LAVORI PUBBLICI`) |
| `tipologia_intervento` | testo | Tipologia (es. `MANUTENZIONE STRAORDINARIA DI ADEGUAMENTO SISMICO`) |
| `settore_intervento`, `sotto_settore_intervento`, `categoria_intervento` | testo | Classificazione ufficiale dell'opera |
| `descrizione_cup` | testo | Descrizione del progetto secondo OpenCUP |
| `anno_decisione` | numero | Anno della decisione di finanziamento |
| `importo_costo_progetto` | numero | Costo del progetto in euro |
| `importo_finanziamento` | numero | Finanziamento in euro: non sempre uguale al costo |
| `tipo_copertura` | testo | Fonte di copertura (`STATALE` 2.401, `REGIONALE` 438, `ALTRA PUBBLICA` 319, più combinazioni) |
| `strumento` | testo | Strumento di programmazione |
| `numero_cup_collegati`, `cup_master_collegato` | testo | Legami con altri CUP: 77 progetti hanno CUP collegati, 48 hanno un CUP master |
| `url_opencup` | testo | Scheda del progetto su OpenCUP |

25 CUP su 3.482 (0,7%) non sono presenti in OpenCUP e non compaiono qui. Per questi codici la risposta dell'API è vuota e la pagina pubblica del progetto risponde "non disponibile". Una parte è spiegabile: 6 risultano nell'elenco dei CUP revocati e cancellati, che escono dal registro principale. Per gli altri non è stata trovata una spiegazione — non sono revocati, non sono cancellati e non risultano collegati ad altri codici come predecessori o successori.

La classificazione dei soggetti conferma la natura comunale della ricostruzione: 3.211 progetti su 3.457 fanno capo a enti territoriali, 99 a enti di gestione del patrimonio immobiliare pubblico (le ATER), 59 ad amministrazioni dello Stato.

### `enti.csv`

[`enti.csv`](enti.csv) contiene l'anagrafica dei soggetti attuatori: 357 enti su 361 (98,9%), con denominazione ufficiale, codice IPA e domicili digitali. Fonte: [IPA](https://indicepa.gov.it), l'Indice dei domicili digitali della Pubblica Amministrazione gestito da AgID.

Si aggancia a `pubblica.csv` tramite `cf_piva_soggetto_attuatore`.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cf_piva_soggetto_attuatore` | testo | Codice fiscale o partita IVA dell'ente, come in `pubblica.csv` |
| `cod_ipa` | testo | Codice IPA dell'ente: chiave stabile per raggruppare, al posto delle denominazioni scritte in modi diversi |
| `denominazione_ipa` | testo | Denominazione ufficiale (`Comune di Matelica`, non `COMUNE DI MATELICA - MC -`) |
| `pec` | testo | Domicili digitali dell'ente. Valori multipli separati da `;` |
| `fonte_ipa` | testo | Da quale servizio IPA arriva il dato: `domicili digitali` (352 enti) o `portale IPA` (5) |

La PEC è l'indirizzo a cui si presenta una richiesta di accesso civico sul singolo intervento. Tutti i 357 enti ne hanno almeno una.

Il recupero avviene in due passaggi, perché una sola strada non basta. Il servizio dei domicili digitali risponde per 352 enti; per gli altri si cerca l'ente sull'indice del portale IPA, che risponde per codice fiscale anche dove il primo servizio non trova nulla, e da lì si recupera la PEC. Il secondo passaggio recupera 5 enti che altrimenti risulterebbero assenti — fra cui ANAS e l'ATER dell'Aquila — e riconduce la soppressa *Azienda Sanitaria USL 10 di Camerino* all'Azienda USL Umbria 1, che ne ha ereditato le funzioni.

I 4 enti non risolti, da tenere presenti:

| Valore nel dato | Interventi | Nota |
|---|---:|---|
| `soggetto privato` | 7 | non è un codice fiscale ma una stringa segnaposto nella fonte |
| ATER della Provincia di Teramo | 50 | codice fiscale che non risolve in nessuno dei due servizi |
| Terna Rete Italia | 1 | società, non presente in IPA per quel codice fiscale |
| CCIAA di Teramo | 1 | non risolve per codice fiscale |

### `pagamenti.csv`

[`pagamenti.csv`](pagamenti.csv) riporta i pagamenti per progetto e per anno, come registrati nel monitoraggio: 2.371 righe su 847 CUP, dal 2017 al 2026, per 385,6 milioni di euro complessivi. Fonte: [BDAP-MOP](https://bdap-opendata.rgs.mef.gov.it), il Monitoraggio Opere Pubbliche della Ragioneria Generale dello Stato, che pubblica i dati in famiglie di file distinte: questa viene da `sal` (Stato Avanzamento Lavori), che contiene i pagamenti per progetto e per anno. I file sono divisi per regione e sono state usate le partizioni di Umbria, Marche, Lazio e Abruzzo.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cup` | testo | Codice Unico di Progetto |
| `anno` | numero | Anno di riferimento dei pagamenti |
| `importo_pagato` | numero | Importo pagato nell'anno, in euro |

È l'unico dato di spesa disponibile su questi interventi: la consegna FOIA riporta soltanto importi programmati.

Il file contiene i dati dei soli CUP presenti nel MOP, che sono 1.299 dei 3.482 del dataset; di questi, 847 hanno righe di pagamento. Per tutti gli altri il MOP non ha nulla da restituire, e questo non dice niente sull'intervento: l'assenza di un CUP dal MOP non significa che il progetto non esista né che non sia stato pagato, così come l'assenza di righe di pagamento per un CUP presente non significa che non ci siano stati esborsi.

La copertura parziale dipende dall'architettura del monitoraggio italiano, diviso per fonte di finanziamento fra tre sistemi — MOP per gli investimenti nazionali, ReGiS per il PNRR, BDU per la coesione fino al 2014-2020 — e da quanto gli enti titolari alimentano il sistema.

### `gare.csv`

[`gare.csv`](gare.csv) riporta le gare con aggiudicatario e importi, come registrate nel monitoraggio: 8.163 righe, 7.326 CIG su 1.272 CUP, con 998 imprese aggiudicatarie distinte, 6,1 miliardi di euro aggiudicati a fronte di 6,5 miliardi a base d'asta. Stessa fonte BDAP-MOP, famiglia `gar`, quella che raccoglie le gare.

Vale anche qui quanto detto per i pagamenti: sono i dati dei soli CUP presenti nel MOP, e l'assenza di un intervento non dice nulla sulle sue gare, che infatti per la gran parte si ritrovano in `cup_cig.csv`.

| Colonna | Tipo | Descrizione |
|---|---|---|
| `cup` | testo | Codice Unico di Progetto |
| `cig` | testo | Codice Identificativo Gara |
| `oggetto_gara` | testo | Oggetto della gara |
| `data_pubblicazione_gara` | data | Data di pubblicazione |
| `tipo_scelta_contraente` | testo | Procedura di scelta del contraente |
| `ente` | testo | Ente che ha bandito |
| `aggiudicatario` | testo | Impresa aggiudicataria |
| `cf_aggiudicatario` | testo | Codice fiscale dell'aggiudicataria |
| `importo_base_asta` | numero | Importo a base d'asta in euro |
| `importo_aggiudicazione` | numero | Importo di aggiudicazione in euro |

Attenzione a sommare gli importi. La fonte pubblica una riga per aggiudicatario, quindi negli accordi quadro con più operatori lo stesso importo compare ripetuto: sommando le righe grezze il totale sale a 50 miliardi contro i 6,1 reali. Prima di aggregare va fatta una deduplicazione su `cup` e `cig`.

Questo file è anche un secondo ponte CUP-CIG, diverso da `cup_cig.csv`: delle sue 7.475 coppie distinte, 7.392 sono anche in ANAC e 83 esistono solo qui. Il contrario è molto più frequente — 6.812 coppie sono solo in ANAC — perché MOP copre appena 1.272 dei nostri CUP. Quando serve completezza, la somma delle due fonti è più affidabile di ciascuna.

---

## Interventi per categoria

| Categoria | Interventi |
|---|---:|
| `11 - Altre opere pubbliche` | 870 |
| `9 - Opere di urbanizzazione e infrastrutture` | 801 |
| `3 - Cimiteri` | 432 |
| `10 - Scuole` | 405 |
| `5 - Edilizia residenziale pubblica` | 332 |
| `4 - Dissesti` | 233 |
| `8 - Municipi` | 201 |
| `12 - Solo Progettazione` | 111 |
| `2 - Chiese ed edifici di culto` | 75 |
| `7 - Edilizia socio sanitaria` | 61 |
| `10 - Scuole (Palestre)` | 48 |
| `1 - Caserme` | 46 |
| `6 - Edilizia sanitaria` | 34 |
| `10 - Università` | 18 |

## Interventi per fase di avanzamento

| `fase_id` | `fase_label` | Interventi |
|---|---|---:|
| `FA_0` | Rup non nominato | 93 |
| `FA_1` | Rup nominato e cronoprogramma condiviso | 207 |
| `FA_2` | Avvio procedure di affidamento contraente per i servizi | 218 |
| `FA_3` | Incarico di progettazione affidato | 601 |
| `FA_4` | Progetto definitivo/PFTE approvato | 713 |
| `FA_5` | Progetto esecutivo approvato | 367 |
| `FA_6` | Avvio procedure per l'aggiudicazione dei lavori | 233 |
| `FA_7` | Inizio lavori | 548 |
| `FA_8` | Fine lavori | 196 |
| `FA_9` | Collaudo | 488 |
| `FA_10` | Rinunce/Revoche | 3 |

---

## Come sono stati lavorati i dati

Il criterio seguito è duplice: non si riscrive quello che la fonte ha consegnato, e dove il dato consegnato è inservibile così com'è si aggiunge una colonna che lo rende utilizzabile, senza cancellare l'originale. Un nome di colonna viene riusato dall'edizione precedente solo se il campo ha lo stesso significato.

Le uniche modifiche fatte sul posto riguardano la forma, mai il contenuto: gli spazi non significativi a inizio e fine cella, le sequenze di due o più spazi ridotte a uno (comprese le 436 celle che contenevano un a capo), e i separatori delle ordinanze multiple.

### Campi ricostruiti o aggiunti

`ocos` e `ocos_label`. Nel numero #17 il tipo di opera era una colonna a sé; qui non c'è più. È stato ricostruito dal prefisso dell'identificativo — `EU_` per le opere comunali, `ES_` per le statali — dopo aver verificato che nel #17 la corrispondenza è esatta su tutte e 3.542 le righe. Risultato: 2.682 opere comunali e 982 statali; restano vuote 3 righe prive di prefisso.

`ocos_label` esiste perché `OC` e `OS` compaiono anche in `ordinanza_attuale`, dove però significano *ordinanza commissariale* e *ordinanza speciale*: due sigle uguali per due concetti diversi nello stesso file.

`eues_id_norm`. Nella consegna 2026 gli identificativi sono zero-paddati in 777 righe (`EU_0587`), mentre nelle edizioni precedenti no (`EU_587`). Non è una rinumerazione ma una diversa formattazione: delle righe paddate, 761 ritrovano il proprio identificativo nel #17 e 747 hanno CUP identico.

Poiché sul solo identificativo di consegna il confronto fra le due edizioni si fermerebbe a 2.768 interventi invece di 3.502, `eues_id` conserva il valore ricevuto e `eues_id_norm` porta quello confrontabile. Per confrontare questa edizione con le precedenti si usa `eues_id_norm`.

Il campo è vuoto in 14 righe, dove al posto dell'identificativo la fonte ha lasciato un segnaposto: `xx` in 3 righe, e `ES_XX`, `ES_XXX`, `ES_xxx`, `ES_xx`, `ES_xxxxxx` in altre 11, ciascuno condiviso da più interventi diversi.

`cod_istat_comune`. I nomi di regione arrivano in grafie diverse, i nomi di comune non sempre coincidono con quelli ufficiali e in alcune righe la provincia è errata o assente. Invece di normalizzare i testi si è agganciato il codice Istat del comune: da quello si ricavano regione, provincia e denominazioni vigenti secondo la fonte ufficiale.

L'aggancio è fatto su comune più sigla della provincia — non sul solo nome, che accetterebbe in silenzio le province sbagliate — usando l'elenco Istat SITUAS in [`risorse/2026-08-14_situas_comuni.csv`](../../risorse/2026-08-14_situas_comuni.csv) e le correzioni note in [`risorse/vocabolario_comuni.csv`](../../risorse/vocabolario_comuni.csv). Il codice è valorizzato su 3.661 righe su 3.667, e la regione che se ne ricava non contraddice mai quella dichiarata nella consegna.

Restano senza codice 6 righe che non si riferiscono a un comune singolo: `Vari`, `Comuni vari`, `Vallo di Nera, Preci`, `Palmiano - Rocca Fluvione - Comunanza`, `Santa Vittoria in Matenano - Montefalcone Appennino`.

`soggetto_attuatore` e `cf_piva_soggetto_attuatore`. La consegna 2026 non contiene più il soggetto attuatore, che era presente nelle precedenti. Il campo è stato ricostruito dal soggetto titolare del progetto pubblicato da OpenCUP, agganciato tramite il CUP.

Il metodo è stato verificato prima di applicarlo, su 12 CUP presenti anche nel numero #17, dove il soggetto attuatore è dichiarato: il dato OpenCUP coincide in tutti i 10 casi in cui il #17 lo valorizza, e nei 2 casi in cui il #17 riporta `0` — Mogliano e Camporotondo di Fiastrone — OpenCUP il soggetto ce l'ha comunque.

Il risultato copre 3.514 interventi su 3.667, il 95,8%, con 361 soggetti distinti. Per confronto, il numero #17 valorizzava il campo su 3.331 righe su 3.542, il 94%: la ricostruzione copre quindi una quota di interventi leggermente superiore a quella della consegna che il dato lo conteneva.

Nessun intervento risulta associato a più di un soggetto, nemmeno le 8 righe che contengono più CUP nella stessa cella. Le 153 righe senza soggetto sono quelle il cui CUP non è in OpenCUP o che non hanno un CUP utilizzabile.

> Il soggetto titolare del CUP e la stazione appaltante che bandisce la gara sono concetti diversi e non sempre coincidono. Qui è stato scelto il primo perché è quello che corrisponde al «soggetto attuatore» delle consegne precedenti, come confermato dal controllo sui 12 CUP.

`fase_id` e `fase_label`. Nella consegna la fase è una stringa che unisce codice e descrizione, ma la descrizione non è scritta sempre allo stesso modo: `FA_7 - Inizio Lavori` compare 234 volte e `FA_7 - Inizio lavori` 314, e lo stesso vale per `FA_8`. Chi raggruppa per il testo conta quindi 314 interventi in inizio lavori invece di 548.

Codice e descrizione sono stati separati, uniformando l'etichetta alla forma più frequente di ciascun codice. Per contare o confrontare le fasi si usa `fase_id`, mai il testo.

### Modifiche di forma

Ordinanze multiple. Nove righe indicano due ordinanze nella stessa cella, con quattro convenzioni diverse (`OS_15 e OS_48`, `OS_16+ OS 106`, `OS_20+OS_126`, `OS_31 + OS_104`). Sono state riscritte in forma `OS_nnn` separate da `;`, per esempio `OS_16;OS_106`. Nessun codice è andato perso.

---

## Limiti dei dati

Vanno tenuti presenti prima di usare il dataset.

Manca il soggetto attuatore. La colonna c'era nelle consegne precedenti e in questa non compare. Il dato è stato ricostruito da OpenCUP e riportato nella colonna `soggetto_attuatore` (vedi sopra): è quindi un'informazione ricavata da una fonte terza, non trasmessa dal Commissario.

Mancano i CIG. Il dato non è stato trasmesso, nonostante fosse fra le informazioni richieste. Senza CIG non è possibile collegare gli interventi alle procedure di gara e ai contratti.

Sette CUP dichiarati non sono CUP. Non si tratta di righe con il campo vuoto (quelle sono altre 93), ma di righe che indicano un codice che non è utilizzabile: chi cerca il progetto su OpenCUP non trova nulla.

| `eues_id` | Comune | Codice indicato | Intervento | Fase |
|---|---|---|---|---|
| `ES_823` | Ascoli Piceno (AP) | `C31B2100608000` | Asilo nido Lo Scarabocchio | `FA_3` |
| `EU_0055` | Cortino (TE) | `F39D1800007000` | Rifugio montano | `FA_9` |
| `ES_128` | Fiastra (MC) | `F27H2104930001` | Rifacimento sottoservizi e delocalizzazione depuratore | `FA_2` |
| `ES_919` | Macerata (MC) | `????` | Scuola materna "Lino Liviabella" | `FA_1` |
| `ES_703` | Montereale (AQ) | `PROV0000043240` | Sottoservizi e opere di ripristino nel capoluogo | `FA_1` |
| `ES_172` | Teramo (TE) | `D49F1800057000` | Istituto musicale "G. Braga" | `FA_7` |
| `ES_170` | Teramo (TE) | `D48E1800024000` | Scuola media "Francesco Savini" | `FA_7` |

Cinque sono codici di 14 caratteri invece di 15, quindi errori di trascrizione; uno è il segnaposto `????`; uno è un numero di protocollo finito nella colonna del CUP. Due di questi interventi hanno già il cantiere aperto.

Il codice categoria 10 vale per tre categorie diverse: `10 - Scuole`, `10 - Scuole (Palestre)` e `10 - Università`, in 471 righe complessive. Raggruppando per il numero le tre voci si sommano, raggruppando per il testo restano distinte. Il campo è stato lasciato come nella consegna perché lo stesso comportamento è presente anche nel #17, quindi la serie storica è coerente; riassegnare un codice avrebbe significato inventare un dato che la fonte non fornisce.

141 righe condividono un CUP con altre righe, in 50 gruppi: 40 coppie, 6 terne, due gruppi da cinque, uno da sette e uno da ventisei righe con lo stesso codice. Nella gran parte dei casi le denominazioni sono diverse, quindi si tratta verosimilmente di stralci o lotti dello stesso progetto; in 3 gruppi la denominazione è identica. Sommare gli importi raggruppando per CUP porta a contare più volte gli stessi interventi.

Dodici interventi hanno importo pari a zero o assente. Fra questi ci sono opere in fasi avanzate, come la scuola materna G. Leopardi di Sarnano e la scuola primaria di Crognaleto, entrambe in collaudo.

`codice_usr` non è un identificativo utilizzabile. Gli USR sono gli Uffici Speciali per la Ricostruzione, uno per regione, istituiti dall'articolo 3 del DL 189/2016. Il campo contiene il loro riferimento di pratica, ma ogni ufficio adotta una convenzione propria: nel file convivono almeno dieci formati diversi (`1017`, `P23.0047-0001`, `ID_N00001`, `14_001_ABR_001`), e in 2 righe compare la dicitura `Non Trovato`. È valorizzato in 2.108 righe su 3.667, con 57 valori ripetuti, e l'Umbria non lo compila quasi mai.

Gli importi non sono confrontabili con quelli delle edizioni precedenti. Qui la voce è l'importo *programmato* al netto delle assegnazioni disposte con i Decreti OC-126, mentre nel numero #17 era l'importo totale dell'intervento. Per questo la colonna ha un nome diverso da quello usato in precedenza.

### Sulla ricostruzione privata

Non è confrontabile con il dato del numero #14. Là c'erano 12.668 righe, una per fascicolo, con CUP, indirizzo, stato della pratica, tipologia di beneficiario e di intervento e flag superbonus. Qui ci sono 429 righe, una per comune, con otto misure aggregate. Il confronto è possibile solo riaggregando per comune il file del #14, tenendo però presente che le due rilevazioni distano un anno e mezzo.

Un importo liquidato è negativo: Montebuono (Rieti) riporta −9.064,81 €, a fronte di 98.014,76 € concessi. Probabilmente si tratta di uno storno o di un recupero di somme, ma nel dato non c'è nulla che lo espliciti.

In 28 comuni l'importo liquidato è maggiore di quello concesso. Può dipendere da anticipazioni, conguagli o da date di rilevazione diverse fra le due colonne: la consegna non lo chiarisce.

Il foglio di consegna ha una intestazione su tre righe con celle unite, sotto il titolo dell'allegato. Chi lo riapre con le impostazioni predefinite di un lettore CSV prende per intestazione il titolo e perde le tre righe successive, insieme al primo comune dell'elenco.

---

## Confronto con l'edizione precedente

Rispetto al numero #17 (dati al 30 aprile 2025), usando `eues_id_norm`:

- 3.502 interventi presenti in entrambe le edizioni
- 154 interventi compaiono solo qui. Di questi, 129 appartengono a due ordinanze che nel #17 non comparivano affatto, `OC_250` e `OC_263`
- 30 interventi presenti nel #17 non sono più rintracciabili
- 40 interventi cambiano CUP a parità di identificativo, senza che sia fornita una tabella di raccordo; altri 4 perdono il CUP che avevano. Fra questi, due interventi di Contigliano si scambiano i rispettivi codici
- 49 interventi regrediscono di fase, cioè risultano a una fase precedente rispetto all'anno prima, escluse rinunce e revoche

---

## Fonti dei dati

I file di questa cartella nascono da una consegna FOIA e da tre banche dati pubbliche, ciascuna con una competenza istituzionale distinta.

| Fonte | Gestita da | Cosa ne abbiamo preso | File |
|---|---|---|---|
| Riscontro FOIA, piattaforma GE.DI.SI. | Commissario Straordinario ricostruzione sisma 2016 | interventi pubblici e privati | [`pubblica.csv`](pubblica.csv), `privata_comuni.csv`, `cup.csv` |
| Sistema CUP, via portale e API OpenCUP | DIPE, Presidenza del Consiglio dei ministri | anagrafica dei progetti e soggetto titolare | [`opencup.csv`](opencup.csv), colonne `soggetto_attuatore` |
| BDNCP, Banca Dati Nazionale Contratti Pubblici | ANAC | associazione CUP-CIG | [`cup_cig.csv`](cup_cig.csv) |
| BDAP-MOP, Monitoraggio Opere Pubbliche | Ragioneria Generale dello Stato, MEF | pagamenti per anno, gare e aggiudicatari | [`pagamenti.csv`](pagamenti.csv), `gare.csv` |
| IPA, Indice dei domicili digitali della PA | AgID | denominazioni ufficiali, codici IPA, PEC degli enti | [`enti.csv`](enti.csv) |
| SITUAS | ISTAT | codici e denominazioni dei comuni | `cod_istat_comune` |


### Quando due fonti non concordano

Capita, ed è documentato in questi dati: le coppie CUP-CIG di ANAC e quelle di BDAP non coincidono del tutto. La divergenza va segnalata e approfondita, non risolta scegliendo d'ufficio una fonte: può dipendere da date di aggiornamento diverse, da fasi diverse del progetto, da livelli di dettaglio o da errori di registrazione. Le due catene amministrative sono distinte, quindi per la completezza vale l'unione, non l'intersezione.

---

## Licenza

I dati sono rilasciati con licenza [CC BY 4.0](../../../LICENSE.md), con attribuzione a "Liberiamoli tutti!".
