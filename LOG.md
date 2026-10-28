## 2026-10-28

- `sbarchi-migranti`: il sito del Viminale è stato rifatto (Drupal 11). Il vecchio host `www.libertaciviliimmigrazione...` non risolve più, e `bulk_download_pdf.sh` usciva con `exit 0` senza scaricare niente dal 15/09/2025. Nuova pagina: `https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero`.
- Nuovo `sbarchi-migranti/script/archivia_pdf.sh`, solo archiviazione e idempotente: GET condizionale con `If-None-Match` (ETag di nginx), file scritto solo se lo sha256 è nuovo, manifest in `rawdata/pdf/manifest.csv` (affiancato ad `anagrafica-report.csv`). Secondo lancio: 210 risposte 304, nessun file scritto, ~30 s. Provato con Miller 6.12, come in CI.
- PDF in `rawdata/pdf` rinominati con `git mv` in `YYYY-MM-DD_cruscotto_statistico_giornaliero[_vN].pdf`. Tolto un doppione identico (15/09/2020); le due copie diverse di 15/12/2024 e 30/06/2025 diventano `_v2`.
- Archiviati 83 PDF nuovi: 41 dal 2017 al 15/09/2019, 28 dal 21/05/2025 al 28/10/2026, 14 `_v2` per date in cui il sito restituisce un file con contenuto diverso dal nostro (in sei casi 6 pagine invece di 8; per il 15/07/2021 il nostro era rovinato). Cinque report (15/05/2022, 13/10/2023, 15/07/2024, 31/07/2024, 31/05/2025) non sono più sul sito: li abbiamo solo noi.
- Formato dei PDF cambiato due volte: dal 15/06/2026 niente più sbarchi giornalieri (solo mensili) e nuove sezioni su minori non accompagnati e rimpatri; dal 28/10/2026 niente più accoglienza per regione. Gli script di estrazione vanno riscritti e, dopo la rinomina, non sono rilanciabili.

## 2026-10-23

- Workflow `cgsse.yml` fallito il 23/10 alla prima pagina (e il 14/10 a `page=147`): la prima `curl` partiva 2 s dopo il riavvio di Tor, senza attendere un circuito verso un'uscita italiana (`ExitNodes {it} StrictNodes 1`), e 4 tentativi in ~90 s non bastavano. In `cgsse.sh`: attesa di Tor pronto su `check.torproject.org/api/ip` (max ~5 min), `-S` alla curl per vedere l'errore nel log, pause tra i tentativi Tor da `attempt*3` a `attempt*15` s.
- Run di verifica verde, ma il controllo su `check.torproject.org` non è mai riuscito e la prima pagina è passata solo dopo ~10 min dall'avvio di Tor. Il controllo ora interroga direttamente `www.cgsse.it`, con attesa massima portata a ~15 min.
- Secondo run di verifica fallito a `page=27`: Tor pronto subito, ma il circuito si è perso a metà raccolta e i 4 tentativi passavano dallo stesso nodo d'uscita. Ora ogni tentativo usa credenziali SOCKS diverse, che per Tor significano un circuito nuovo (IsolateSOCKSAuth); tentativi da 4 a 6.
- Terzo run fallito a `page=32` dopo 53 min: cambiando credenziali a ogni tentativo, anche il primo di ogni pagina apriva un circuito nuovo, che spesso non si costruiva entro il `--connect-timeout` di 15 s; quasi ogni pagina falliva al primo colpo. Ora lo stesso circuito resta finché funziona e si cambia solo dopo un fallimento.

## 2026-10-11

- Workflow `cgsse.yml` fallito dall'1 all'8 ottobre su `sudo apt install tor` (404 e 502 su libevent: l'indice apt dell'immagine del runner puntava a una versione non più servita dal mirror). Aggiunto `sudo apt-get update` prima di `sudo apt-get install -y tor`.

## 2026-08-17

- Workflow PNRR fallito il 17/08 con **401** sull'invocazione della funzione Scaleway: il token era stato ruotato il 13/08 (nuovo valore nel secret `SCW_PROXY_TOKEN`, creato alle 10:12, e nella funzione, aggiornata alle 10:18) ma `ITALIADOMANI_REFRESH_URL` era rimasto alle 09:28, con il token vecchio. Riscritto il secret con l'URL completo (`https://<dominio-funzione>/?token=<PROXY_TOKEN>`, token nella query string perché lo script fa una `curl` nuda senza header di autenticazione), workflow di nuovo verde.
- La funzione è `staging-italiadomani` (namespace omonimo, `fr-par`, node22, timeout 900s, `privacy: public`), il bucket è `liberiamoli-tutti-staging`. Il 401 non lo genera Scaleway ma il codice della funzione, che valida `PROXY_TOKEN`: una funzione `private` risponderebbe 403 dal gateway. Per il debug basta `scw function function list`, che mostra env var e `updated_at`, più `curl` sul bucket pubblico per vedere la data dei CSV.
- Nel run del 17/08 le fonti erano tutte raggiungibili (precheck progetti e gare 200, zip ANAC scaricato e scompattato): a far uscire lo script con `exit 1` prima dell'elaborazione è stato il solo `DOWNLOAD_FAILED=true` acceso dal refresh. Da valutare se degradare `italiadomani_refresh` a warning, lasciando decidere il fallimento ai download veri.
- Rimosso il secret `SCW_PROXY_TOKEN`, non usato da nessun workflow: era la copia nuda del token che il 13/08 ha ricevuto il valore nuovo mentre `ITALIADOMANI_REFRESH_URL` restava indietro. Il token vive ora in un posto solo. Alla prossima rotazione va ricomposto a mano l'URL intero, dominio più `?token=`.
- Il `PROXY_TOKEN` è una stringa scelta da noi e non scade: si cambia solo per decisione o per esposizione. Le due scadenze reali sono altrove — 2027-08-13 la chiave S3 con cui la funzione scrive sul bucket (si rigenera nelle env var della funzione, i secret GitHub non c'entrano), 2026-11-11 la chiave della CLI `scw` usata per il debug da terminale, ininfluente per il workflow.

## 2026-08-15

- Dati ricostruzione, numero #20: nuova cartella `dati_ricostruzione/data/20/` dal riscontro FOIA ActionAid di luglio 2026 (`rawdata/2026-07-23_dati_final_2026_opere_private_e_pubbliche.xlsx`). Pubblica al 30 aprile 2026, privata al 31 maggio 2026 — **due date di riferimento diverse nella stessa consegna**.
- Otto file: `pubblica.csv` (3.667 interventi, 19 colonne), `privata_comuni.csv` (429 comuni, aggregata), `cup.csv` (3.482 CUP validi), `cup_cig.csv` (14.204 coppie da ANAC), `opencup.csv` (3.457 anagrafiche), `pagamenti.csv` (2.371 righe, 385,6 mln effettivamente pagati da BDAP MOP), `gare.csv` (8.163 gare con aggiudicatario, 998 imprese), `enti.csv` (357 enti attuatori da IPA con denominazione ufficiale, codice IPA e PEC). Script unico `script/dati_ricostruzione_20.sh`, undici fasi.
- IPA interrogato in due passaggi con `openipa-pp-cli`: il servizio dei domicili digitali copre 352 enti, l'indice del portale ne recupera altri 5 che il primo non espone per codice fiscale (fra cui ANAS e ATER dell'Aquila) e riconduce la soppressa USL 10 di Camerino all'AUSL Umbria 1. Tutti i 357 enti hanno almeno una PEC, che è l'indirizzo per un accesso civico sul singolo intervento.
- **Soggetto attuatore ricostruito**: la consegna 2026 non lo contiene più. Recuperato da OpenCUP e verificato su 12 CUP presenti anche nel #17, dove coincide in tutti i 10 casi valorizzati. Copre 3.514 interventi su 3.667 (95,8%), meglio del #17 stesso (94%).
- Fasi di avanzamento: `FA_7 - Inizio Lavori` e `FA_7 - Inizio lavori` erano due valori distinti (234 + 314 righe). Separati `fase_id` e `fase_label`: chi contava per testo trovava 314 interventi in inizio lavori invece di 548.
- Identificativi zero-paddati solo in questa edizione (`EU_0587` contro `EU_587` del #17), 777 righe. `eues_id` resta come da consegna, aggiunto `eues_id_norm`: senza, il confronto fra le due edizioni perdeva 761 interventi.
- Codice Istat del comune agganciato via SITUAS invece di normalizzare le grafie di `regione`: 3.661 righe su 3.667. `risorse/vocabolario_comuni.csv` da 7 a 15 casi (Popoli → Popoli Terme, Montopoli in Sabina → di Sabina, apostrofo tipografico in Sant'Anatolia di Narco).
- Verificato cosa contengono le tre banche dati d'origine: OpenCUP risolve 3.457 CUP su 3.482 (25 mancanti, di cui 6 revocati o cancellati); dei 431 CUP senza CIG in ANAC **nessuno ha una gara in BDAP**, quindi manca la gara, non l'associazione; su BDAP MOP c'è il 37,3% dei CUP, di cui solo 84 esclusi per perimetro normativo (d.lgs. 229/2011) e oltre duemila opere pubbliche non trasmesse. A parità di fase avanzata la copertura per ente va dallo 0% (ATER Teramo, 18 interventi) al 90% (Ascoli Piceno). Escluso che stiano in BDU: sul Parquet di OpenCoesione solo 11 dei 3.482 CUP, uno solo fuori da MOP.
- Attenzione per le prossime edizioni: l'API OpenCUP sotto carico risponde 200 con corpo vuoto anche per CUP esistenti. Con 4 richieste parallele 29 codici su 54 risultavano falsamente assenti; lo script ora ritenta tre volte e usa parallelismo 2. Dieci CUP non risultano in nessuna delle tre banche dati, segnalati a DIPE, ANAC e RGS.
- Note di lavorazione in `tmp/ri_2026/note.md` (non versionato).

## 2026-08-13

- Workflow PNRR CUP/CIG: il commit in caso di fallimento non dice più "Aggiornamento automatico dati PNRR" ma "PNRR non aggiornato, script fallito" — prima ogni run fallito committava il solo `update_log.jsonl` sotto un messaggio di aggiornamento riuscito.
- Diagnosticata la causa dei fallimenti ricorrenti (2026-07-06 → 08-10): ANAC risponde **403** ai download da IP dei runner GitHub (Azure US, PoP F5 Dallas). Verificato che non dipende dallo User-Agent — wget/curl, nudi o con UA Chrome, sono tutti bloccati; dalla stessa URL con IP italiano si scarica. Dati PNRR fermi da 2026-07-06.
- ANAC: download instradato su un proxy, il cui URL sta nel secret `ANAC_PROXY_URL`. `redact()` nello script maschera l'URL prima che finisca in `update_log.jsonl`, che è committato.
- italiadomani: Akamai risponde 403 agli IP dei runner e pretende `User-Agent` browser **e** header `Range` insieme (uno solo dei due non basta). Una funzione serverless su Scaleway `fr-par` scarica i due CSV e li riversa su un bucket pubblico; il workflow invoca la funzione e poi legge dal bucket. URL in `ITALIADOMANI_REFRESH_URL` e `ITALIADOMANI_BUCKET_URL`. Sparisce `proxy.andybandy.it`, che era hardcoded nello script.
- Workflow di nuovo verde end-to-end dopo cinque settimane.

## 2026-06-22

- Aggiunta cartella `maidati_ivg_2026/` con i dati IVG (numeri e qualitativo) per regione, anni 2023-2025, da accesso civico 2026. Formati CSV e JSONL, README con schema e note, licenza CC BY 4.0.

## 2026-06-15

- Aggiunto log persistente JSONL per le cause di fallimento del workflow PNRR CUP/CIG e commit dei log anche in caso di errore.

## 2026-03-11

- Fix qualità dati ricostruzione #17: whitespace rimosso con `mlr clean-whitespace`, 582 duplicati eliminati da `cup_cig.csv` con `SELECT DISTINCT`, date `data_pubblicazione` in `ordinanze.csv` convertite in ISO 8601

## 2026-02-22

- Aggiornato `dati_ricostruzione/script/dati_ricostruzione.sh` con estrazione ordinanze da due fonti: ordinanze commissariali (OC) e ordinanze speciali (OS)
- Prodotto output unificato `dati_ricostruzione/data/ordinanze.csv` con colonne `tipo_id`, `tipo_label`, `n`, `titolo`, `data_pubblicazione`, `download_titolo`, `download_url`
- Aggiunta la colonna `url_ordinanza` a `dati_ricostruzione/data/riscontro_action_aid.csv`, valorizzata con join su `ordinanza_attuale` e supporto ai casi con ordinanze multiple

## 2025-10-05

- Risolto errore critico nel workflow GitHub Actions `referendum_iniziative_popolare.yml` che causava il fallimento del job "aggiorna timeline storica"
- Il problema era causato da una query DuckDB che non gestiva correttamente i cambiamenti dello schema JSON nel tempo
- Modificato lo script `referendum_iniziative_popolare/script/update_timeline.sh` per gestire colonne opzionali usando TRY_CAST e COALESCE
- Testato il fix localmente con successo su 30 giorni di dati storici

## 2025-08-21

*   Pubblicati i dati relativi al FOIA sui dati della ricostruzione post-sisma, come descritto nel numero 14 di "Liberemioli tutti!".

## 2025-07-13

- Creazione del file di `LOG.md` per tracciare le modifiche.
- Aggiunta la sezione `scioperi` per la raccolta, l'elaborazione e la pubblicazione dei dati sugli scioperi in Italia.
- Creati e documentati gli script per l'estrazione automatica dei dati da:

  - Ministero delle Infrastrutture e dei Trasporti (`mit.sh`)
  - Commissione di Garanzia Scioperi (`cgsse.sh`)
- Predisposti i dati in formato CSV e JSONL.
