#!/bin/bash

set -x
set -e
set -u
set -o pipefail

# Ricostruzione post-sisma 2016 — numero #20 di "Liberiamoli tutti!"
#
# Trasforma il riscontro FOIA di luglio 2026 (XLSX, due fogli) nei file
# pubblicati in data/20/, arricchendoli con tre fonti esterne.
#
#
# DIPENDENZE
#
# - DuckDB CLI  https://github.com/duckdb/duckdb   elaborazione, lettura XLSX
#               (l'estensione 'excel' viene caricata con LOAD: la prima volta
#               DuckDB la scarica da sé, quindi serve rete)
# - qsv         https://github.com/dathere/qsv     conteggi e controlli
# - curl, unzip, iconv, xargs, jq                  download e conversioni
# - openipa-pp-cli                                 anagrafica enti da IPA (FASE 11)
#     Se manca:  npx -y @mvanhorn/printing-press install openipa --cli-only
#     oppure:    go install github.com/mvanhorn/printing-press-library/library/developer-tools/openipa/cmd/openipa-pp-cli@latest
#     Va installato in una cartella che sta nel PATH (di norma $HOME/go/bin).
#     Verifica: openipa-pp-cli --version
#
#
# VARIABILI D'AMBIENTE — tutte obbligatorie, lo script si ferma se mancano
#
# - OPENCUP_API_CLIENT_ID
# - OPENCUP_API_CLIENT_SECRET
#     Credenziali dell'API OpenCUP, servono alla FASE 8. Si richiedono dal
#     portale OpenCUP. Senza, l'API risponde 401.
#
# - IPA_auth_id
#     Credenziale dell'Indice delle Pubbliche Amministrazioni, serve alla
#     FASE 11. Si richiede gratuitamente su indicepa.gov.it e viene rilasciata
#     subito. Verifica dell'installazione: openipa-pp-cli doctor
#
# - BDAP_TMP
#     Cartella di lavoro per i dump BDAP, che pesano un centinaio di MB e non
#     vanno dentro il repository. Deve esistere: lo script non la crea, per
#     non seminare cartelle in giro per il filesystem.
#
#     Cosa ci finisce dentro (FASE 9), scaricato automaticamente se assente:
#
#       bdap_gar_reg10.csv … reg13.csv    ~100 MB in tutto, gare
#       bdap_sal_reg10.csv … reg13.csv    ~8 MB in tutto, pagamenti
#       utf8_bdap_*.csv                   gli stessi file convertiti in UTF-8
#
#     I file vengono riusati se già presenti: cancellarli forza il riscarico.
#     reg10 Umbria, reg11 Marche, reg12 Lazio, reg13 Abruzzo (codici ISTAT).
#
#     Esempio:  BDAP_TMP=/mnt/c/tmp ./dati_ricostruzione_20.sh
#
#
# ALTRI FILE SCARICATI, questi dentro tmp/ del progetto (git-ignored)
#
# - tmp/cup_csv.zip          82 MB, dataset CUP-CIG di ANAC, riusato se c'è.
#                            Da rete italiana passa; dai runner GitHub il WAF
#                            di ANAC risponde 403 e serve il proxy usato in
#                            pnrr_cup_cig
# - tmp/opencup_20/*.json    3.482 file, uno per CUP: l'API OpenCUP non
#                            accetta liste. La prima esecuzione richiede circa
#                            due ore, le successive riusano i file
#
#
# OUTPUT in data/20/
#
#   pubblica.csv         3.667 interventi di ricostruzione pubblica
#   privata_comuni.csv     429 comuni, ricostruzione privata aggregata
#   cup.csv              3.482 CUP distinti e formalmente validi
#   cup_cig.csv         14.204 coppie CUP-CIG da ANAC
#   opencup.csv          3.457 anagrafiche di progetto da OpenCUP
#   pagamenti.csv        2.371 righe di pagamenti per anno da BDAP MOP
#   gare.csv             8.163 gare con aggiudicatario da BDAP MOP
#   enti.csv               357 enti attuatori da IPA, con PEC
#
# Più un file di lavoro, non destinato alla pubblicazione:
#   tmp/20_cup_presenza.csv   per ogni CUP, se è in OpenCUP, ANAC e MOP

folder="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rawdata="${folder}/../rawdata/2026-07-23_dati_final_2026_opere_private_e_pubbliche.xlsx"
vocabolario="${folder}/../risorse/vocabolario_comuni.csv"
situas="${folder}/../risorse/2026-08-14_situas_comuni.csv"
tmp="${folder}/../../tmp"
data="${folder}/../data/20"

# --- Prerequisiti, controllati prima di elaborare qualsiasi cosa ---

if [[ -z "${OPENCUP_API_CLIENT_ID:-}" || -z "${OPENCUP_API_CLIENT_SECRET:-}" ]]; then
  echo "Servono OPENCUP_API_CLIENT_ID e OPENCUP_API_CLIENT_SECRET (credenziali API OpenCUP)." >&2
  exit 1
fi

if [[ -z "${IPA_auth_id:-}" ]]; then
  echo "Serve IPA_auth_id (credenziale IPA, si richiede su indicepa.gov.it)." >&2
  exit 1
fi

if [[ -z "${BDAP_TMP:-}" ]]; then
  echo "Serve BDAP_TMP: la cartella dove tenere i dump BDAP (~110 MB), fuori dal repository." >&2
  echo "Esempio: BDAP_TMP=/mnt/c/tmp $0" >&2
  exit 1
fi

if [[ ! -d "${BDAP_TMP}" ]]; then
  echo "BDAP_TMP punta a '${BDAP_TMP}', che non esiste: crearla prima di lanciare lo script." >&2
  exit 1
fi

bdap_tmp="${BDAP_TMP}"

for cmd in duckdb qsv curl unzip iconv jq openipa-pp-cli; do
  command -v "${cmd}" >/dev/null || { echo "Manca il comando '${cmd}' (vedi DIPENDENZE nella testata)." >&2; exit 1; }
done

mkdir -p "${tmp}"
mkdir -p "${data}"

# --- FASE 1: Estrazione dati sorgente ---

# Esporta il foglio delle opere pubbliche dall'XLSX in CSV grezzo, senza
# trasformazioni: tutte le colonne come testo, per non perdere gli zeri
# iniziali degli identificativi e la formattazione dei CUP.
duckdb -c "
LOAD excel;
COPY (
  SELECT *
  FROM read_xlsx('${rawdata}', sheet = 'OOPP_2026', all_varchar = true)
) TO '${tmp}/20_pubblica_raw.csv' (FORMAT csv, HEADER true);
"

# --- FASE 2: Pulizia whitespace, rinomina colonne, derivazione ocos ---

# Pulizia degli spazi, su tutte le colonne: gli spazi non significativi a
# inizio e fine cella spariscono, le sequenze di due o più spazi diventano un
# solo spazio. La sequenza comprende anche gli a capo dentro la cella, che qui
# sono numerosi (436 celle) e che spezzerebbero i CUP. Lo spazio unificatore
# (U+00A0) non rientra in \s e va sostituito prima.

# I nomi colonna seguono quelli del numero #17, così il confronto fra le due
# edizioni resta un join diretto. Fa eccezione l'importo: nel #17 è l'importo
# totale dell'intervento, qui è l'importo programmato al netto delle
# assegnazioni dei Decreti OC-126, quindi cambia significato e cambia nome.
#
# Il campo ocos, che nel #17 era una colonna a sé, qui non c'è più: si ricava
# dal prefisso dell'identificativo (EU_ = opere comunali, ES_ = opere statali).
# Nel #17 la corrispondenza è esatta su tutte le righe.
#
# L'identificativo resta in eues_id come nella consegna, e accanto compare
# eues_id_norm, che è la versione confrontabile con le altre edizioni:
#
# - senza gli zeri iniziali del numero. Nella consegna 2026 sono zero-paddati
#   in 777 righe (EU_0587), nel #17 no (EU_587). Verificato che è sola
#   formattazione: di quelle righe 761 ritrovano l'id nel #17 e 747 hanno CUP
#   identico. Senza normalizzare il confronto perderebbe 761 interventi
# - vuoto dove al posto dell'identificativo c'è un segnaposto: 14 righe in
#   tutto, fra "xx" (3) e le varianti "ES_XX", "ES_XXX", "ES_xxx", "ES_xx",
#   "ES_xxxxxx" (11). Sono segnaposto condivisi da più righe, non identificano
#   niente. L'ocos però resta per le 11 che hanno il prefisso: dice che sono
#   opere statali
duckdb -c "
LOAD excel;
CREATE OR REPLACE TABLE pulito AS
  SELECT nullif(trim(regexp_replace(replace(COLUMNS(*), chr(160), ' '), '\s+', ' ', 'g')), '')
  FROM read_xlsx('${rawdata}', sheet = 'OOPP_2026', all_varchar = true, normalize_names = true);

COPY (
  SELECT
    comune,
    prov,
    CASE left(eu_id, 3)
      WHEN 'EU_' THEN 'OC'
      WHEN 'ES_' THEN 'OS'
    END AS ocos,
    CASE left(eu_id, 3)
      WHEN 'EU_' THEN 'Opere comunali'
      WHEN 'ES_' THEN 'Opere statali'
    END AS ocos_label,
    eu_id AS eues_id,
    CASE
      WHEN regexp_matches(eu_id, '^(EU|ES)_[0-9]+$')
      THEN regexp_replace(eu_id, '_0+([0-9])', '_\1')
    END AS eues_id_norm,
    ordinanza_attuale,
    regione,
    cup AS cupxall,
    codice_usr,
    intervento_nome AS denominazione_interventoxall,
    categoria,
    importo_programmato_per_intervento_esclusa_assegnazione_con_decreti_oc126
      AS importo_programmato_esclusi_oc_126,
    fase_di_avanzamento_al_30_aprile_2026
  FROM pulito
) TO '${tmp}/20_pubblica_rinominata.csv' (FORMAT csv, HEADER true);
"

# --- FASE 3: Codice Istat del comune ---

# I nomi di regione arrivano in grafie diverse (ABRUZZO e Abruzzo), i nomi di
# comune non sempre coincidono con quelli ufficiali e in qualche riga la
# provincia è sbagliata o assente. Invece di normalizzare i testi si aggancia
# il codice Istat del comune: da quello chiunque ricava regione, provincia e
# denominazioni vigenti, senza che siamo noi a scegliere una grafia.
#
# L'aggancio è su comune + sigla provincia, non sul solo nome: il nome da solo
# aggancerebbe qualche riga in più, ma accetterebbe in silenzio le province
# sbagliate invece di farle emergere. Le differenze note fra il testo del
# sorgente e la denominazione ufficiale passano per il vocabolario.
#
# Restano senza codice le righe che non si riferiscono a un comune solo
# ("Comuni vari", "Vallo di Nera, Preci", "Palmiano - Rocca Fluvione -
# Comunanza", "Santa Vittoria in Matenano - Montefalcone Appennino"): lì il
# codice non esiste, e il campo resta vuoto.
duckdb -c "
CREATE OR REPLACE TABLE base AS
  SELECT * FROM read_csv('${tmp}/20_pubblica_rinominata.csv', all_varchar = true);
CREATE OR REPLACE TABLE voc AS
  SELECT * FROM read_csv('${vocabolario}', all_varchar = true);
CREATE OR REPLACE TABLE istat AS
  SELECT
    lower(\"Comune\") AS comune_key,
    upper(\"Sigla automobilistica\") AS prov_key,
    \"Codice Comune (alfanumerico)\" AS cod_istat_comune
  FROM read_csv('${situas}', delim = ';', all_varchar = true);

COPY (
  WITH corretto AS (
    SELECT
      b.*,
      lower(coalesce(v.comune_fix, b.comune)) AS comune_key,
      upper(coalesce(v.prov_fix, b.prov)) AS prov_key
    FROM base b
    LEFT JOIN voc v
      ON lower(b.comune) = lower(v.comune_orig)
     AND coalesce(upper(b.prov), '') = coalesce(upper(v.prov_orig), '')
  )
  SELECT c.* EXCLUDE (comune_key, prov_key), i.cod_istat_comune
  FROM corretto c
  LEFT JOIN istat i
    ON c.comune_key = i.comune_key
   AND c.prov_key = i.prov_key
) TO '${tmp}/20_pubblica_istat.csv' (FORMAT csv, HEADER true);
"

# --- FASE 4: Fase di avanzamento, codice separato dalla descrizione ---

# Il campo di consegna unisce codice e descrizione in una stringa sola
# ("FA_7 - Inizio lavori"), ma la descrizione non è scritta sempre allo stesso
# modo: "FA_7 - Inizio Lavori" compare 234 volte e "FA_7 - Inizio lavori" 314,
# e lo stesso vale per FA_8. Sono 13 valori distinti per 11 fasi reali, quindi
# chi raggruppa per il testo conta 314 interventi in inizio lavori invece di
# 548. Si separano quindi fase_id e fase_label, tenendo il campo di consegna.
#
# La descrizione viene uniformata prendendo, per ogni codice, la forma più
# frequente: nessuna riscrittura a mano, e se la consegna cambierà grafia il
# criterio resta valido.
duckdb -c "
CREATE OR REPLACE TABLE base AS
  SELECT * FROM read_csv('${tmp}/20_pubblica_istat.csv', all_varchar = true);
CREATE OR REPLACE TABLE label_per_fase AS
  SELECT fase_id, arg_max(fase_label, n) AS fase_label
  FROM (
    SELECT
      split_part(fase_di_avanzamento_al_30_aprile_2026, ' - ', 1) AS fase_id,
      trim(split_part(fase_di_avanzamento_al_30_aprile_2026, ' - ', 2)) AS fase_label,
      count(*) AS n
    FROM base GROUP BY 1, 2
  ) GROUP BY fase_id;

COPY (
  SELECT
    b.* EXCLUDE (ordinanza_attuale),
    -- Le ordinanze multiple arrivano con quattro convenzioni diverse
    -- ('OS_15 e OS_48', 'OS_16+ OS 106', 'OS_20+OS_126', 'OS_31 + OS_104'):
    -- cambia il separatore e cambia la forma del codice, con underscore o
    -- spazio. Si estraggono i codici e si riscrivono come OS_nnn separati da
    -- punto e virgola. Riguarda 9 righe; le ordinanze singole non cambiano.
    array_to_string(
      list_transform(
        regexp_extract_all(b.ordinanza_attuale, '(OC|OS)[ _]?[0-9]+'),
        x -> regexp_replace(x, '[ ]+', '_')
      ), ';') AS ordinanza_attuale,
    f.fase_id,
    f.fase_label
  FROM base b
  LEFT JOIN label_per_fase f
    ON split_part(b.fase_di_avanzamento_al_30_aprile_2026, ' - ', 1) = f.fase_id
) TO '${tmp}/20_pubblica_fasi.csv' (FORMAT csv, HEADER true);
"

# --- FASE 5: Elenco dei CUP distinti ---

# Serve per le lavorazioni che partono dal CUP, a cominciare dal recupero dei
# CIG. Due accortezze:
#
# - in 8 righe la cella contiene più CUP, separati da spazio o da trattino
#   ("B31B20000510001 B31B20000710002"). Senza spezzarli si perderebbero CUP
#   validi, quindi la cella viene divisa e ogni codice conta per sé
# - si tengono solo i CUP formalmente validi, cioè 15 caratteri alfanumerici.
#   Restano fuori i 5 troncati a 14 caratteri, il segnaposto "????" e
#   "PROV0000043240", che non è un CUP
duckdb -c "
COPY (
  SELECT DISTINCT upper(cup) AS cup
  FROM (
    SELECT unnest(regexp_split_to_array(cupxall, '[[:space:]-]+')) AS cup
    FROM read_csv('${tmp}/20_pubblica_fasi.csv', all_varchar = true)
    WHERE cupxall IS NOT NULL
  )
  WHERE regexp_matches(upper(cup), '^[A-Z0-9]{15}\$')
  ORDER BY cup
) TO '${data}/cup.csv' (FORMAT csv, HEADER true);
"

# --- FASE 6: Ricostruzione privata ---

# Il foglio della privata non è un elenco di interventi ma un aggregato per
# comune, e ha una intestazione su tre righe con celle unite: la riga 1 è il
# titolo dell'allegato, le righe 2-4 sono i tre livelli di intestazione
# ("TOTALE DANNI LIEVI +DANNI GRAVI" > "RCR (n)" / "IMPORTI (€)" / "CANTIERI" >
# i nomi veri delle colonne). Nessun lettore CSV se la cava da solo: si legge
# quindi l'area dei soli dati, A5:J433, assegnando i nomi a mano.
#
# La provincia qui è per esteso ("L'Aquila"), non in sigla come nella
# pubblica: l'aggancio del codice Istat usa quindi la denominazione della
# provincia. Il vocabolario si applica al solo nome del comune, perché le sue
# correzioni di provincia sono espresse in sigla.
duckdb -c "
LOAD excel;
CREATE OR REPLACE TABLE priv AS
  SELECT
    trim(A) AS regione,
    trim(B) AS provincia,
    trim(C) AS comune,
    D AS rcr_presentate,
    E AS rcr_approvate,
    F AS importo_richiesto,
    G AS importo_concesso,
    H AS importo_liquidato,
    I AS cantieri_in_corso,
    J AS cantieri_chiusi
  FROM read_xlsx('${rawdata}', sheet = 'Ric_Priv_All_1_2026',
                 range = 'A5:J433', header = false, all_varchar = true);
CREATE OR REPLACE TABLE voc AS SELECT * FROM read_csv('${vocabolario}', all_varchar = true);
CREATE OR REPLACE TABLE istat AS
  SELECT
    lower(\"Comune\") AS comune_key,
    lower(\"Provincia/Uts\") AS prov_key,
    \"Codice Comune (alfanumerico)\" AS cod_istat_comune
  FROM read_csv('${situas}', delim = ';', all_varchar = true);

COPY (
  WITH corretto AS (
    SELECT p.*, lower(coalesce(v.comune_fix, p.comune)) AS comune_key
    FROM priv p
    LEFT JOIN (SELECT DISTINCT lower(comune_orig) AS orig, comune_fix FROM voc) v
      ON lower(p.comune) = v.orig
  )
  SELECT c.* EXCLUDE (comune_key), i.cod_istat_comune
  FROM corretto c
  LEFT JOIN istat i
    ON c.comune_key = i.comune_key
   AND lower(c.provincia) = i.prov_key
) TO '${data}/privata_comuni.csv' (FORMAT csv, HEADER true);
"

# --- FASE 7: CIG associati ai CUP, dal dataset ANAC ---

# I CIG non sono stati trasmessi nel riscontro FOIA: si recuperano dal dataset
# "cup" di ANAC, che è il ponte fra CUP e CIG (due sole colonne, 7,1 milioni di
# righe). La relazione è molti-a-molti: un CUP ha più CIG e uno stesso CIG può
# essere associato a più CUP, quindi da questo file non si sommano importi
# senza una regola esplicita di deduplicazione.
#
# Il download è di circa 82 MB: si riusa il file se è già in tmp. Da rete
# italiana risponde a qualunque client; dai runner GitHub il WAF di ANAC
# risponde 403 e serve il proxy usato in pnrr_cup_cig.
cup_zip="${tmp}/cup_csv.zip"
cup_anac="${tmp}/cup_csv.csv"
cup_url="https://dati.anticorruzione.it/opendata/download/dataset/cup/filesystem/cup_csv.zip"

if [[ ! -f "${cup_zip}" ]]; then
  curl -sSL "${cup_url}" -o "${cup_zip}"
fi

if [[ ! -f "${cup_anac}" ]]; then
  unzip -p "${cup_zip}" > "${cup_anac}"
fi

# Il file scaricato è una pagina di errore se il WAF ha bloccato la richiesta.
if head -c 200 "${cup_zip}" | grep -qi '<html'; then
  echo "ANAC ha risposto con una pagina HTML, non con i dati" >&2
  exit 1
fi

duckdb -c "
COPY (
  SELECT DISTINCT
    n.cup,
    a.CIG AS cig,
    'https://dati.anticorruzione.it/superset/dashboard/dettaglio_cig/?cig=' || a.CIG AS url_cig
  FROM read_csv('${data}/cup.csv', all_varchar = true) n
  INNER JOIN read_csv_auto('${cup_anac}') a ON n.cup = a.CUP
  ORDER BY n.cup, a.CIG
) TO '${data}/cup_cig.csv' (FORMAT csv, HEADER true);
"

# --- FASE 8: Anagrafica dei progetti da OpenCUP ---

# Il riscontro FOIA 2026 non contiene più il soggetto attuatore, che c'era
# nelle consegne precedenti. OpenCUP, che è il registro dei progetti e non un
# sistema di monitoraggio, pubblica per ogni CUP il soggetto titolare: su 12
# CUP di controllo, presenti anche nel #17, la corrispondenza con il soggetto
# attuatore del #17 è risultata esatta, e in 2 casi OpenCUP valorizza il campo
# dove il #17 riportava "0".
#
# Si interroga un CUP alla volta (l'API non accetta liste). Le risposte sono
# salvate una per file e riusate nelle esecuzioni successive: rilanciare lo
# script non ripete le chiamate già fatte.
#
# Un CUP sconosciuto torna HTTP 200 con corpo VUOTO, non un 404: senza questo
# controllo un solo codice non trovato interrompe il ciclo. I non trovati
# vengono marcati, così si distinguono da quelli non ancora interrogati.
#
# ATTENZIONE: un corpo vuoto non significa per forza "CUP inesistente". Sotto
# carico l'API risponde 200 e corpo vuoto anche per codici che esistono: in una
# prima esecuzione con 4 richieste parallele, 29 CUP su 54 marcati come non
# trovati sono poi risultati regolarmente presenti (per esempio
# H67H21005000001, Comune di Roccafluvione, la cui scheda è pubblicata sul
# portale). Per questo ogni codice viene ritentato tre volte con una pausa
# prima di essere dato per assente, e le richieste parallele sono ridotte a 2.
opencup_dir="${tmp}/opencup_20"
mkdir -p "${opencup_dir}"

export OPENCUP_DIR="${opencup_dir}"

qsv behead "${data}/cup.csv" | xargs -P 2 -I{} bash -c '
  cup="$0"; out="${OPENCUP_DIR}/${cup}.json"
  [[ -s "$out" ]] && exit 0
  for tentativo in 1 2 3; do
    curl -sS -o "$out" "https://api.sogei.it/rgs/opencup/o/extServiceApi/v1/opendataes/cup/${cup}" -H "x-ibm-client-id: ${OPENCUP_API_CLIENT_ID}" -H "x-ibm-client-secret: ${OPENCUP_API_CLIENT_SECRET}" -H "Accept: application/json"
    [[ -s "$out" ]] && exit 0
    sleep 3
  done
  printf "{\"results\":[{\"CUP\":\"%s\",\"NON_TROVATO\":true}]}" "$cup" > "$out"' {}

# I JSON hanno 69 campi: se ne tengono quelli che servono al dataset.
duckdb -c "
COPY (
  SELECT
    r.CUP AS cup,
    r.DESC_SOGGETTO AS soggetto_titolare,
    r.CF_PIVA_SOGGETTO AS cf_piva_soggetto,
    r.DESC_CATEGORIA_SOGGETTO AS categoria_soggetto,
    r.DESC_SOTTO_CATEGORIA_SOGGETTO AS sotto_categoria_soggetto,
    r.DESC_NATURA AS natura,
    r.DESC_TIPOLOGIA_INTERVENTO AS tipologia_intervento,
    r.DESC_SETTORE_INTERVENTO AS settore_intervento,
    r.DESC_SOTTO_SETTORE_INTERVENTO AS sotto_settore_intervento,
    r.DESC_CATEGORIA_INTERVENTO AS categoria_intervento,
    r.DESCRIZIONE_CUP AS descrizione_cup,
    r.ANNO_DECISIONE AS anno_decisione,
    r.IMPORTO_COSTO_PROGETTO AS importo_costo_progetto,
    r.IMPORTO_FINANZIAMENTO AS importo_finanziamento,
    r.DESC_TIPO_COPERTURA AS tipo_copertura,
    r.DESC_STRUMENTO AS strumento,
    r.NUMERO_CUP_COLLEGATI AS numero_cup_collegati,
    r.COD_CUP_MASTER_COLLEGATO AS cup_master_collegato,
    'https://opencup.gov.it/portale/progetto/-/cup/' || r.CUP AS url_opencup
  FROM (
    SELECT unnest(results) AS r
    FROM read_json('${opencup_dir}/*.json', union_by_name = true)
  )
  WHERE r.NON_TROVATO IS NULL
  ORDER BY cup
) TO '${data}/opencup.csv' (FORMAT csv, HEADER true);
"

# --- FASE 9: Pagamenti e gare da BDAP MOP ---

# Il riscontro FOIA dà solo importi programmati: quanto sia stato davvero
# speso non c'è. Il Monitoraggio Opere Pubbliche del MEF-RGS lo pubblica nella
# famiglia "sal", pagamenti per progetto e per anno; SIOPE non può rispondere
# perché non contiene il CUP. La famiglia "gar" aggiunge le gare con
# aggiudicatario e importo di aggiudicazione.
#
# Le famiglie sono partizionate in 21 file regionali: qui servono solo le
# quattro regioni del cratere (reg10 Umbria, reg11 Marche, reg12 Lazio,
# reg13 Abruzzo).
#
# MOP copre solo gli investimenti nazionali non monitorati da ReGiS (PNRR) e
# BDU (coesione): dei nostri CUP ne intercetta 847 in "sal" e 1.272 in "gar".
# L'assenza da MOP non significa che il progetto non esista.
#
# I dump finiscono in BDAP_TMP (vedi la testata dello script): sono in
# latin-1 con separatore ';' e vanno convertiti prima di darli in pasto a
# DuckDB. Se i file ci sono già non vengono riscaricati.
while read -r fam reg pkg; do
  out="${bdap_tmp}/bdap_${fam}_${reg}.csv"
  [[ -s "${out}" ]] || curl -sS "https://bdap-opendata.rgs.mef.gov.it/SpodCkanApi/api/3/datastore/dump/${pkg}.csv" -o "${out}"
  # I dump sono in latin-1 con separatore ';': vanno convertiti prima di DuckDB.
  [[ -s "${bdap_tmp}/utf8_bdap_${fam}_${reg}.csv" ]] || iconv -f latin1 -t utf8 "${out}" > "${bdap_tmp}/utf8_bdap_${fam}_${reg}.csv"
done <<'EOF'
gar reg10 f3d54366-a91f-4675-88bf-dec13baabff1
gar reg11 16e8ae35-1c89-43f2-a891-4ae3e96bfd8d
gar reg12 372f630c-d7fb-47ba-9173-4bde3d9d1f96
gar reg13 cac73cc4-7eb9-4219-a4ff-2ba6614e5205
sal reg10 5527b971-7a53-420f-9e31-1c953eca8190
sal reg11 886c05c2-bd41-4c2b-a8d4-f000f51c8836
sal reg12 59017a93-b264-4ed3-bf31-698c74d99c2d
sal reg13 3b9ef833-5fa2-42dd-9a78-4c53bc122625
EOF

duckdb -c "
CREATE OR REPLACE TABLE nostri AS
  SELECT cup FROM read_csv('${data}/cup.csv', all_varchar = true);

COPY (
  SELECT
    \"Codice CUP\" AS cup,
    \"Anno Pagamenti\" AS anno,
    try_cast(\"Importo Pagamenti\" AS DOUBLE) AS importo_pagato
  FROM read_csv_auto('${bdap_tmp}/utf8_bdap_sal_reg1*.csv', union_by_name = true, all_varchar = true)
  WHERE \"Codice CUP\" IN (SELECT cup FROM nostri)
  ORDER BY cup, anno
) TO '${data}/pagamenti.csv' (FORMAT csv, HEADER true);

-- In 'gar' c'è una riga per aggiudicatario: negli accordi quadro con più
-- operatori lo stesso importo si ripete, e sommare le righe grezze gonfia il
-- totale di un ordine di grandezza. Qui si tiene una riga per CUP-CIG-
-- aggiudicatario, e gli importi vanno sommati deduplicando su CUP e CIG.
COPY (
  SELECT DISTINCT
    \"Codice CUP\" AS cup,
    \"Codice CIG\" AS cig,
    \"Oggetto Gara\" AS oggetto_gara,
    \"Data Pubblicazione Gara\" AS data_pubblicazione_gara,
    \"Tipo Scelta Contraente\" AS tipo_scelta_contraente,
    \"Descrizione Ente\" AS ente,
    \"Descrizione Soggetto\" AS aggiudicatario,
    \"Codice Fiscale Soggetto\" AS cf_aggiudicatario,
    try_cast(\"Importo Base d'Asta\" AS DOUBLE) AS importo_base_asta,
    try_cast(\"Importo Aggiudicazione\" AS DOUBLE) AS importo_aggiudicazione
  FROM read_csv_auto('${bdap_tmp}/utf8_bdap_gar_reg1*.csv', union_by_name = true, all_varchar = true)
  WHERE \"Codice CUP\" IN (SELECT cup FROM nostri)
  ORDER BY cup, cig
) TO '${data}/gare.csv' (FORMAT csv, HEADER true);
"

# --- FASE 10: Soggetto attuatore dentro il file principale ---

# Il soggetto attuatore è l'informazione che la consegna 2026 ha tolto rispetto
# alle precedenti, ed è il punto sollevato dall'editoriale: lasciarla solo in
# opencup.csv la renderebbe poco visibile. Viene quindi riportata anche in
# pubblica.csv, con il nome che aveva nel #17.
#
# L'aggancio passa per il CUP, e le 8 righe che ne contengono più d'uno non
# creano ambiguità: verificato che nessun intervento risulta associato a più di
# un soggetto, nemmeno quelli con più CUP nella stessa cella.
duckdb -c "
CREATE OR REPLACE TABLE base AS
  SELECT * FROM read_csv('${tmp}/20_pubblica_fasi.csv', all_varchar = true);
CREATE OR REPLACE TABLE oc AS
  SELECT cup, soggetto_titolare, cf_piva_soggetto
  FROM read_csv('${data}/opencup.csv', all_varchar = true);

COPY (
  SELECT
    b.*,
    (SELECT max(o.soggetto_titolare) FROM oc o
      WHERE o.cup IN (SELECT unnest(regexp_split_to_array(upper(b.cupxall), '[[:space:]-]+')))
    ) AS soggetto_attuatore,
    (SELECT max(o.cf_piva_soggetto) FROM oc o
      WHERE o.cup IN (SELECT unnest(regexp_split_to_array(upper(b.cupxall), '[[:space:]-]+')))
    ) AS cf_piva_soggetto_attuatore
  FROM base b
) TO '${data}/pubblica.csv' (FORMAT csv, HEADER true);
"

# --- FASE 11: Anagrafica degli enti attuatori da IPA ---

# Il soggetto attuatore ricostruito da OpenCUP arriva con una denominazione
# non normalizzata ("COMUNE DI PIEVE TORINA - MC -") e con il codice fiscale.
# Da quel codice fiscale l'Indice delle Pubbliche Amministrazioni restituisce
# la denominazione ufficiale, il codice IPA e i domicili digitali (PEC).
#
# La PEC non è un ornamento: è l'indirizzo a cui si presenta un accesso civico
# sul singolo intervento, e il codice IPA è la chiave verso le altre banche
# dati della pubblica amministrazione.
#
# Le risposte sono salvate una per file e riusate, come per OpenCUP.
ipa_dir="${tmp}/ipa_20"
mkdir -p "${ipa_dir}"
export IPA_DIR="${ipa_dir}"

duckdb -c "
COPY (
  SELECT DISTINCT cf_piva_soggetto_attuatore AS cf
  FROM read_csv('${data}/pubblica.csv', all_varchar = true)
  WHERE cf_piva_soggetto_attuatore IS NOT NULL
  ORDER BY cf
) TO '${tmp}/20_cf_enti.csv' (FORMAT csv, HEADER false);
"

# Primo passaggio: il servizio dei domicili digitali, che dà in un colpo
# codice IPA, denominazione ufficiale e PEC.
xargs -P 3 -I{} bash -c 'cf="$0"; out="${IPA_DIR}/${cf}.json"; [[ -s "$out" ]] && exit 0; openipa-pp-cli domicilio cf --cf "$cf" --agent > "$out" 2>/dev/null || printf "{\"data\":{\"data\":[]}}" > "$out"' {} < "${tmp}/20_cf_enti.csv"

# Secondo passaggio: alcuni enti esistono in IPA ma il servizio dei domicili
# non li restituisce per codice fiscale — verificato su ANAS, ATER dell'Aquila,
# ASP di Teramo e Comunità Montana della Laga. Per questi si cerca l'ente sul
# portale (che risponde per codice fiscale) e da lì si recupera la PEC con il
# codice IPA. Senza questo passaggio la copertura è sottostimata.
mkdir -p "${ipa_dir}/fallback"
export IPA_FALLBACK="${ipa_dir}/fallback"

grep -L '"cod_amm"' "${ipa_dir}"/*.json 2>/dev/null | sed 's|.*/||;s|\.json$||' | \
xargs -P 3 -I{} bash -c '
  cf="$0"; out="${IPA_FALLBACK}/${cf}.json"
  [[ -s "$out" ]] && exit 0
  cod=$(openipa-pp-cli sede enti --cf "$cf" --agent 2>/dev/null | jq -r ".data[0].codEnte // empty")
  if [[ -n "$cod" ]]; then
    openipa-pp-cli pec ente "$cod" --agent 2>/dev/null > "$out" || printf "[]" > "$out"
  else
    printf "[]" > "$out"
  fi' {}

# Una riga per ente: denominazione ufficiale, codice IPA, PEC separate da ';'.
# La colonna fonte_ipa dice da quale dei due passaggi arriva il dato.
duckdb -c "
CREATE OR REPLACE TABLE primo AS
  SELECT
    regexp_extract(filename, '([0-9A-Za-z]+)\.json\$', 1) AS cf,
    any_value(d.cod_amm) AS cod_ipa,
    any_value(d.des_amm) AS denominazione_ipa,
    string_agg(DISTINCT d.domicilio_digitale, ';') AS pec,
    'domicili digitali' AS fonte_ipa
  FROM (
    SELECT filename, unnest(data.data) AS d
    FROM read_json('${ipa_dir}/*.json', filename = true, union_by_name = true)
  )
  GROUP BY 1;

CREATE OR REPLACE TABLE secondo AS
  SELECT
    regexp_extract(filename, '([0-9A-Za-z]+)\.json\$', 1) AS cf,
    any_value(cod_amm) AS cod_ipa,
    any_value(denominazione) AS denominazione_ipa,
    string_agg(DISTINCT pec, ';') AS pec,
    'portale IPA' AS fonte_ipa
  FROM read_json('${ipa_dir}/fallback/*.json', filename = true, union_by_name = true)
  WHERE cod_amm IS NOT NULL
  GROUP BY 1;

COPY (
  SELECT cf AS cf_piva_soggetto_attuatore, cod_ipa, denominazione_ipa, pec, fonte_ipa FROM primo
  UNION ALL
  SELECT cf, cod_ipa, denominazione_ipa, pec, fonte_ipa FROM secondo WHERE cf NOT IN (SELECT cf FROM primo)
  ORDER BY 1
) TO '${data}/enti.csv' (FORMAT csv, HEADER true);
"

# --- FASE 12: Presenza di ogni CUP nelle tre banche dati (file di lavoro) ---
#
# Non è un file da pubblicare: serve all'analisi e alle segnalazioni ai
# gestori delle banche dati, quindi resta in tmp/.

# Una riga per CUP e tre colonne: se il codice è nel registro dei progetti
# (OpenCUP), se ha gare associate in ANAC, se è nel monitoraggio delle opere
# pubbliche (BDAP MOP). Serve a vedere a colpo d'occhio dove un intervento è
# tracciabile e dove no, e a isolare i casi limite: i CUP che non compaiono in
# nessuna delle tre esistono solo nel file consegnato con il FOIA.
#
# Per MOP si usa la famiglia 'prg', cioè i progetti monitorati: è la domanda
# giusta ("il progetto è nel sistema?"), mentre gare e pagamenti dicono solo
# se è arrivato alla fase che li produce.
duckdb -c "
CREATE OR REPLACE TABLE opencup AS SELECT DISTINCT cup FROM read_csv('${data}/opencup.csv', all_varchar = true);
CREATE OR REPLACE TABLE anac AS SELECT DISTINCT cup FROM read_csv('${data}/cup_cig.csv', all_varchar = true);
CREATE OR REPLACE TABLE mop AS
  SELECT DISTINCT \"Codice CUP\" AS cup
  FROM read_csv_auto('${bdap_tmp}/utf8_bdap_prg_reg1*.csv', union_by_name = true, all_varchar = true);

COPY (
  SELECT
    n.cup,
    CASE WHEN n.cup IN (SELECT cup FROM opencup) THEN 'X' END AS opencup,
    CASE WHEN n.cup IN (SELECT cup FROM anac) THEN 'X' END AS anac,
    CASE WHEN n.cup IN (SELECT cup FROM mop) THEN 'X' END AS mop
  FROM read_csv('${data}/cup.csv', all_varchar = true) n
  ORDER BY n.cup
) TO '${tmp}/20_cup_presenza.csv' (FORMAT csv, HEADER true);
"

# --- Controlli ---

qsv headers "${data}/pubblica.csv"
qsv count "${data}/pubblica.csv"
QSV_STATSCACHE_MODE=none qsv frequency -s ocos,ocos_label "${data}/pubblica.csv"

# Righe rimaste senza codice Istat: devono essere solo quelle che non si
# riferiscono a un comune singolo.
duckdb -c "
SELECT comune, prov, count(*) AS righe
FROM read_csv('${data}/pubblica.csv', all_varchar = true)
WHERE cod_istat_comune IS NULL
GROUP BY ALL ORDER BY righe DESC;
"

qsv count "${data}/cup.csv"

qsv count "${data}/cup_cig.csv"

# Copertura dei CIG sui CUP del dataset.
duckdb -c "
SELECT
  (SELECT count(*) FROM read_csv('${data}/cup.csv', all_varchar = true)) AS cup_totali,
  count(DISTINCT cup) AS cup_con_almeno_un_cig,
  count(DISTINCT cig) AS cig_distinti,
  count(*) AS coppie
FROM read_csv('${data}/cup_cig.csv', all_varchar = true);
"

qsv count "${data}/privata_comuni.csv"
qsv stats --everything --cache-threshold 0 "${data}/privata_comuni.csv" | qsv select field,type,nullcount,min,max

# Frammenti scartati dall'elenco dei CUP: devono essere solo codici malformati.
duckdb -c "
SELECT DISTINCT cup AS scartato
FROM (
  SELECT unnest(regexp_split_to_array(cupxall, '[[:space:]-]+')) AS cup
  FROM read_csv('${data}/pubblica.csv', all_varchar = true)
  WHERE cupxall IS NOT NULL
)
WHERE NOT regexp_matches(upper(cup), '^[A-Z0-9]{15}\$')
ORDER BY 1;
"
