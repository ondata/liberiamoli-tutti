# /// script
# requires-python = ">=3.12"
# dependencies = ["pdfplumber==0.11.10", "polars", "pointblank==1.1.1"]
# ///
"""Estrae dai PDF del Cruscotto statistico giornaliero i dati di sbarchi per giorno,
accoglienza per regione e nazionalità, li valida e scrive i CSV in dati/.

Uso: uv run script/estrai.py

Per ogni data di report si usa la versione del PDF (_vN) che contiene la sezione
cercata, a parità la più recente. Sono esclusi i report precedenti al 2019-09-30.
L'estrazione di ogni PDF è salvata in rawdata/estratti/<nome>.json e riusata.
"""

import csv
import json
import re
import sys
from pathlib import Path

import pdfplumber

CARTELLA = Path(__file__).resolve().parent.parent
ARCHIVIO = CARTELLA / "rawdata" / "pdf"
ESTRATTI = CARTELLA / "rawdata" / "estratti"
DATI = CARTELLA / "dati"

# da incrementare quando cambia l'estrazione: invalida la cache in rawdata/estratti
VERSIONE_ESTRATTORE = 3

SEZIONI = ["giorni", "accoglienza", "nazionalita", "mensili", "msna", "rimpatri"]
RISORSE = CARTELLA / "script" / "risorse"
REGIONI = CARTELLA.parent / "risorse" / "Elenco-regioni.csv"

DATA_MINIMA = "2019-09-30"

MESI = ["gen", "feb", "mar", "apr", "mag", "giu", "lug", "ago", "set", "ott", "nov", "dic"]

NOTA_GIORNI = "*I dati si riferiscono agli eventi di sbarco rilevati entro le ore 8:00 del giorno di riferimento"
NOTA_GIORNI_24 = "*I dati si riferiscono agli eventi di sbarco rilevati entro le ore 24:00 del giorno di riferimento"
FONTE = "Fonte: Dipartimento della Pubblica sicurezza. I dati sono suscettibili di successivo consolidamento."

COLONNE_ACCOGLIENZA = {
    "hot": "Migranti presenti negli hot spot",
    "acc": "Migranti presenti nei centri di accoglienza",
    "sip": "Migranti presenti nei centri SIPROIMI",
    "sai": "Migranti presenti nei centri SAI",
}

NUMERO = re.compile(r"\d{1,3}(?:\.\d{3})*|\d+")


def intero(testo):
    return int(testo.replace(".", ""))


def versioni_per_data():
    """{data_report: [pdf, ...]} con la versione più recente per prima."""
    per_data = {}
    for pdf in ARCHIVIO.glob("*_cruscotto_statistico_giornaliero*.pdf"):
        data = pdf.name[:10]
        if data < DATA_MINIMA:
            continue
        v = re.search(r"_v(\d+)\.pdf$", pdf.name)
        per_data.setdefault(data, []).append((int(v.group(1)) if v else 1, pdf))
    return {d: [p for _, p in sorted(vv, reverse=True)] for d, vv in sorted(per_data.items())}


def estrai_pdf(pdf):
    """Le tre sezioni di un PDF: {"illeggibile": bool, "sezioni": {sezione: {"righe", "totale"} | None}}."""
    data = pdf.name[:10]
    if pdf.read_bytes()[:40].startswith(b"version https://git-lfs"):
        sys.exit(f"{pdf.name} è un puntatore Git LFS senza estrazione in cache: serve git lfs pull, oppure lanciare estrai.py in locale")
    try:
        documento = pdfplumber.open(pdf)
    except Exception as errore:
        print(f"PDF illeggibile: {pdf.name} ({errore})", file=sys.stderr)
        return {"illeggibile": True, "sezioni": {s: None for s in SEZIONI}}
    with documento:
        sezioni = {}
        pagina = pagina_giorni(documento)
        sezioni["giorni"] = {"righe": estrai_giorni(pagina, data), "totale": None} if pagina else None
        pagina = pagina_con(documento, "spot")
        if pagina:
            righe, totale = estrai_accoglienza(pagina, data)
            sezioni["accoglienza"] = {"righe": righe, "totale": totale}
        else:
            sezioni["accoglienza"] = None
        pagina = pagina_con(documento, "azional")
        if pagina:
            righe, totale = estrai_nazionalita(pagina, data)
            sezioni["nazionalita"] = {"righe": righe, "totale": totale}
        else:
            sezioni["nazionalita"] = None
        sezioni["mensili"] = estrai_mensili(documento, data)
        sezioni["msna"] = estrai_msna(documento, data)
        sezioni["rimpatri"] = estrai_rimpatri(documento, data)
    return {"illeggibile": False, "sezioni": sezioni}


def estrazione(pdf):
    """Estrazione di un PDF, letta dalla cache in rawdata/estratti se fatta con questa versione
    dell'estrattore. In CI i PDF già archiviati sono puntatori Git LFS: si leggono solo dalla cache."""
    cache = ESTRATTI / f"{pdf.stem}.json"
    if cache.exists():
        dati = json.loads(cache.read_text(encoding="utf-8"))
        if dati.get("versione_estrattore") == VERSIONE_ESTRATTORE:
            return dati
    dati = {"versione_estrattore": VERSIONE_ESTRATTORE, "file": pdf.name, **estrai_pdf(pdf)}
    ESTRATTI.mkdir(exist_ok=True)
    cache.write_text(json.dumps(dati, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return dati


def pagina_con(documento, parola):
    for pagina in documento.pages:
        if parola in (pagina.extract_text() or ""):
            return pagina
    return None


ETICHETTA_GIORNO = re.compile(r"(\d{2})-([a-z]{3})")


def pagina_giorni(documento):
    """La pagina con più etichette dd-mmm: il titolo è a volte stampato due volte
    sovrapposto e il testo estratto non contiene "per giorno"."""
    migliore, n_migliore = None, 0
    for pagina in documento.pages:
        n = sum(1 for p in pagina.extract_words() if ETICHETTA_GIORNO.fullmatch(p["text"]))
        if n > n_migliore:
            migliore, n_migliore = pagina, n
    return migliore if n_migliore >= 10 else None


def estrai_giorni(pagina, data_report):
    """Tabella dei giorni: etichetta dd-mmm e valore alla stessa altezza, in carattere normale.

    I numeri in grassetto sulla stessa pagina sono le etichette del grafico a barre e si ignorano.
    Alla stessa altezza di una riga può cadere l'asse del grafico (1 2 3 ...): il valore è il numero
    più vicino all'etichetta allineato al bordo destro della colonna. Il bordo è quello più frequente
    fra i numeri più vicini alle etichette della stessa colonna.
    """
    parole = pagina.extract_words(extra_attrs=["fontname"])
    normali = [p for p in parole if "bold" not in p["fontname"].lower()]
    numeri = [p for p in normali if NUMERO.fullmatch(p["text"])]
    mese = MESI[int(data_report[5:7]) - 1]
    giorno_report = int(data_report[8:10])

    candidati = {}
    for etichetta in normali:
        m = ETICHETTA_GIORNO.fullmatch(etichetta["text"])
        if not m or m.group(2) != mese or int(m.group(1)) > giorno_report:
            continue
        candidati[int(m.group(1))] = (round(etichetta["x0"] / 20), sorted(
            (p for p in numeri if abs(p["top"] - etichetta["top"]) <= 2 and 0 < p["x0"] - etichetta["x1"] < 100),
            key=lambda p: p["x0"],
        ))

    bordi = {}
    for colonna, cc in candidati.values():
        if cc:
            bordi.setdefault(colonna, []).append(round(cc[0]["x1"]))
    bordo = {c: max(set(xx), key=xx.count) for c, xx in bordi.items()}

    righe = {}
    for giorno, (colonna, cc) in candidati.items():
        allineati = [p for p in cc if abs(round(p["x1"]) - bordo[colonna]) <= 3]
        if allineati:
            righe[giorno] = intero(allineati[0]["text"])
    nota = NOTA_GIORNI_24 if "24:00" in (pagina.extract_text() or "") else NOTA_GIORNI
    return [
        {
            "Data": f"{data_report[:8]}{g:02d}",
            "Valore": v,
            "Note": nota,
            "Fonte": FONTE,
            "Data_Report": data_report,
        }
        for g, v in sorted(righe.items())
    ]


def chiave_colonna(intestazione):
    t = intestazione.lower()
    if "totale" in t:
        return "totale"
    if re.search(r"hot ?spot", t):
        return "hot"
    if "siproimi" in t:
        return "sip"
    if "sai" in t:
        return "sai"
    if "accoglienza" in t:
        return "acc"
    return None


def tabella_principale(pagina):
    tabelle = pagina.extract_tables()
    if not tabelle:
        return []
    tabella = max(tabelle, key=len)
    return [[(c or "").replace("\n", " ").strip() for c in riga] for riga in tabella]


def estrai_accoglienza(pagina, data_report):
    righe, totale, intestazione = [], None, None
    for celle in tabella_principale(pagina):
        etichetta = next((c for c in celle if c and not NUMERO.fullmatch(c)), "")
        if etichetta == "Regione":
            intestazione = [chiave_colonna(c) for c in celle]
            continue
        if intestazione is None or not etichetta:
            continue
        valori = {}
        for chiave, cella in zip(intestazione, celle):
            if chiave and NUMERO.fullmatch(cella):
                valori[chiave] = intero(cella)
        if not valori:
            continue
        if etichetta.lower().startswith("totale"):
            totale = valori
            continue
        riga = {"Regione": etichetta, "Data_Report": data_report}
        for chiave, nome in COLONNE_ACCOGLIENZA.items():
            riga[nome] = valori.get(chiave)
        riga["_totale"] = valori.get("totale")
        righe.append(riga)
    return righe, totale


def estrai_nazionalita(pagina, data_report):
    righe, totale = [], None
    for celle in tabella_principale(pagina):
        piene = [c for c in celle if c]
        if len(piene) != 2 or not NUMERO.fullmatch(piene[1]):
            continue
        etichetta, valore = piene[0], intero(piene[1])
        if etichetta.lower().startswith("totale"):
            totale = valore
            continue
        righe.append({"Data_Report": data_report, "Nazione_PDF": etichetta, "Valore": valore})
    return righe, totale


MESI_NOMI = ["gennaio", "febbraio", "marzo", "aprile", "maggio", "giugno", "luglio", "agosto", "settembre", "ottobre", "novembre", "dicembre"]
MESE_RE = "|".join(MESI_NOMI)
ANNO = re.compile(r"(20\d\d)\*?")
NUM = r"\d{1,3}(?:\.\d{3})*|\d+"
# "dal 1° gennaio al 26 ottobre 2026", "dal 1° gennaio all'11 giugno 2026"
PERIODO = rf"dal 1° gennaio all?['’ ]\s*(\d{{1,2}}) ({MESE_RE}) (20\d\d)"


def centro(parola):
    return (parola["x0"] + parola["x1"]) / 2


def data_it(giorno, mese, anno):
    return f"{anno}-{MESI_NOMI.index(mese.lower()) + 1:02d}-{int(giorno):02d}"


def righe_testo(pagina):
    return [r.strip() for r in (pagina.extract_text() or "").splitlines()]


def pagina_mensile(documento):
    for pagina in documento.pages:
        t = pagina.extract_text() or ""
        if all(m in t for m in ("gennaio", "giugno", "dicembre")) and ("Comparazione" in t or re.search(r"20\d\d\s+20\d\d\s+20\d\d", t)):
            return pagina
    return None


def griglia_mensile(pagina):
    """{(anno, mese): valore} dalla tabella mensile, in entrambi i formati.

    Formato vecchio: anni in colonna (intestazione in grassetto in alto), mesi in riga, e sotto
    un grafico con i mesi in orizzontale. Formato nuovo: mesi in colonna, anni in riga.
    Ogni numero va alla riga della sua altezza e alla colonna più vicina; si tengono solo i numeri
    con carattere e corpo più frequenti, perché le etichette del grafico cadono a volte sulle righe.
    """
    parole = pagina.extract_words(extra_attrs=["fontname", "size"])
    mesi = [p for p in parole if p["text"].lower() in MESI_NOMI]
    per_x0, per_top = {}, {}
    for m in mesi:
        per_x0.setdefault(round(m["x0"]), []).append(m)
        per_top.setdefault(round(m["top"]), []).append(m)
    riga_mesi = max(per_top.values(), key=len) if per_top else []
    if max((len(v) for v in per_x0.values()), default=0) < 10 and len(riga_mesi) >= 10:
        colonne = {MESI_NOMI.index(m["text"].lower()) + 1: m for m in riga_mesi}
        righe = {}
        for p in parole:
            a = ANNO.fullmatch(p["text"])
            if a and p["top"] > riga_mesi[0]["top"] and p["x1"] < min(m["x0"] for m in riga_mesi):
                righe.setdefault(int(a.group(1)), p)
        chiave = lambda r, c: (r, c)  # noqa: E731
    else:
        anni = [p for p in parole if ANNO.fullmatch(p["text"]) and "bold" in p["fontname"].lower()]
        per_top = {}
        for a in anni:
            per_top.setdefault(round(a["top"]), []).append(a)
        intestazioni = [v for v in per_top.values() if len(v) >= 3]
        if not intestazioni:
            return {}
        riga_anni = min(intestazioni, key=lambda v: v[0]["top"])
        colonne = {int(ANNO.fullmatch(a["text"]).group(1)): a for a in riga_anni}
        righe = {}
        for m in mesi:
            if m["x1"] < min(a["x0"] for a in riga_anni):
                righe.setdefault(MESI_NOMI.index(m["text"].lower()) + 1, m)
        chiave = lambda r, c: (c, r)  # noqa: E731

    xs = sorted(centro(c) for c in colonne.values())
    passo = min(b - a for a, b in zip(xs, xs[1:]))
    candidati = []
    for r, etichetta in righe.items():
        for p in parole:
            if abs(p["top"] - etichetta["top"]) > 2 or not NUMERO.fullmatch(p["text"]) or p["x0"] < etichetta["x1"]:
                continue
            c, col = min(colonne.items(), key=lambda kv: abs(centro(kv[1]) - centro(p)))
            distanza = abs(centro(col) - centro(p))
            if distanza < passo / 2:
                candidati.append((chiave(r, c), distanza, p))
    if not candidati:
        return {}
    stili = [(p["fontname"], round(p["size"], 1)) for _, _, p in candidati]
    stile = max(set(stili), key=stili.count)
    valori = {}
    for k, _, p in sorted(candidati, key=lambda x: x[1]):
        if (p["fontname"], round(p["size"], 1)) == stile and k not in valori:
            valori[k] = intero(p["text"])
    return valori


def serie_annuale(righe):
    """Una riga di soli anni (almeno 10) seguita da una riga con altrettanti valori: {anno: valore}.
    Il trattino ("-") vale dato non disponibile."""
    for i, r in enumerate(righe[:-1]):
        anni = re.findall(r"20\d\d", r)
        if len(anni) >= 10 and re.fullmatch(r"(?:20\d\d\*?\s*)+", r):
            valori = re.findall(rf"(?<![\d.])({NUM}|-)(?![\d.])", righe[i + 1])
            if len(valori) == len(anni):
                return {int(a): (None if v == "-" else intero(v)) for a, v in zip(anni, valori)}
    return {}


def estrai_mensili(documento, data_report):
    """Sbarchi per mese e anno; verifiche: somma dei mesi = totale annuo stampato nel PDF, per gli
    anni chiusi. I mesi successivi a quello del report sono tolti (il PDF li riporta a 0)."""
    pagina = pagina_mensile(documento)
    if pagina is None:
        return None
    anno_report, mese_report = int(data_report[:4]), int(data_report[5:7])
    righe = [
        {"Data_Report": data_report, "Anno": a, "Mese": m, "Valore": v,
         "Mese_in_corso": "si" if (a, m) == (anno_report, mese_report) else "no"}
        for (a, m), v in sorted(griglia_mensile(pagina).items())
        if (a, m) <= (anno_report, mese_report)
    ]
    # totali annui: formato vecchio, etichette "2023: 157.651" sul grafico della stessa pagina;
    # formato nuovo, pagina della serie annuale 2014-...
    totali = {}
    parole = " ".join(p["text"] for p in pagina.extract_words())
    # "2023:157.651" in una parola, oppure "2017:" "119.369" in due; le intestazioni della tabella
    # non hanno i due punti
    for a, v in re.findall(rf"(?<!\S)(20\d\d): ?({NUM})\*?(?!\S)", parole):
        totali[int(a)] = intero(v)
    pagina_annuale = pagina_con(documento, "numero annuale dei migranti sbarcati")
    if pagina_annuale:
        totali.update(serie_annuale(righe_testo(pagina_annuale)))
    verifiche = []
    for anno, totale in sorted(totali.items()):
        mesi = [r["Valore"] for r in righe if r["Anno"] == anno]
        if anno < anno_report and len(mesi) == 12 and totale is not None:
            verifiche.append({"colonna": f"sbarchi {anno}", "somma": sum(mesi), "totale": totale})
    return {"righe": righe, "verifiche": verifiche}


def estrai_msna(documento, data_report):
    """Minori stranieri non accompagnati sbarcati, dal 1° gennaio a Fino_Al di ogni anno."""
    for pagina in documento.pages:
        testo = pagina.extract_text() or ""
        if re.search(r"Anno 20\d\d: ?\d", testo):
            # formato vecchio: fa fede la frase "Anno 2023: 382"; anni passati interi, anno in corso
            # fino alla data dell'intestazione ("2023 (al 28 agosto)", "2020 (all' 8 marzo)")
            valori = {}
            for a, v in re.findall(rf"Anno (20\d\d): ?({NUM})", testo):
                valori.setdefault(int(a), intero(v))
            corrente = max(valori)
            m = re.search(rf"{corrente}\s*\((?:dato )?all?['’ ]\s*(\d{{1,2}})°?\s+({MESE_RE})", testo, re.I)
            fino = data_it(m.group(1), m.group(2), corrente) if m else None
            righe = [{"Data_Report": data_report, "Anno": a, "Fino_Al": f"{a}-12-31" if a < corrente else fino, "Valore": v}
                     for a, v in sorted(valori.items())]
            return {"righe": righe, "verifiche": []}
    # formato nuovo: stesso periodo di tre anni + serie annuale
    righe = {}
    pagina = pagina_con(documento, "MSNA sbarcati")
    if pagina is None:
        return None
    testo = pagina.extract_text() or ""
    m = re.search(PERIODO, testo)
    for a, v in re.findall(rf"^(20\d\d) ({NUM})$", testo, re.M):
        fino = data_it(m.group(1), m.group(2), a) if m else None
        righe[(int(a), fino)] = v
    pagina = pagina_con(documento, "numero annuale dei minori")
    if pagina:
        for a, v in serie_annuale(righe_testo(pagina)).items():
            righe.setdefault((a, f"{a}-12-31"), str(v))
    return {"righe": [{"Data_Report": data_report, "Anno": a, "Fino_Al": f, "Valore": intero(v)} for (a, f), v in sorted(righe.items())], "verifiche": []}


def estrai_rimpatri(documento, data_report):
    """Rimpatri forzati e volontari assistiti, dal 1° gennaio a Fino_Al; verifiche: la somma dei due
    tipi = riga Totale del PDF."""
    righe, verifiche = [], []
    pagina = pagina_con(documento, "migranti rimpatriati dal 1° gennaio")
    if pagina is None:
        return None
    for pagina, periodo in [(pagina, True), (pagina_con(documento, "Comparazione annuale dei migranti rimpatriati"), False)]:
        if pagina is None:
            continue
        testo = " ".join(righe_testo(pagina))
        # gli anni sono quelli subito prima di "Rimpatri forzati"; non quelli del titolo
        # ("2024 e 2025", "negli anni 2014-2025")
        intestazione = re.search(r"((?:(?<![\d-])20\d\d\*?\s+)+)Rimpatri forzati", testo)
        if intestazione is None:
            continue
        anni = [int(a) for a in re.findall(r"20\d\d", intestazione.group(1))]
        # solo la coda di anni consecutivi: "degli anni 2024 e 2025 2024 2025 2026"
        inizio = len(anni) - 1
        while inizio > 0 and anni[inizio - 1] == anni[inizio] - 1:
            inizio -= 1
        anni = anni[inizio:]
        if periodo:
            m = re.search(PERIODO, testo)
            fine = {a: data_it(m.group(1), m.group(2), a) if m else None for a in anni}
        else:
            fine = {a: f"{a}-12-31" for a in anni}
        valori = rf"((?:(?:{NUM}|-)\s+){{{len(anni) - 1}}}(?:{NUM}|-))"
        tipi = {}
        for tipo, etichetta in [("forzati", r"Rimpatri forzati"), ("volontari assistiti", r"Rimpatri volontari(?:\s+assistiti)?\*?"), ("totale", r"Totale")]:
            m = re.search(rf"{etichetta}\s+{valori}", testo)
            if m:
                tipi[tipo] = [None if v == "-" else intero(v) for v in m.group(1).split()]
        for i, a in enumerate(anni):
            for tipo in ("forzati", "volontari assistiti"):
                if tipo in tipi and tipi[tipo][i] is not None:
                    righe.append({"Data_Report": data_report, "Tipo": tipo, "Anno": a, "Fino_Al": fine[a], "Valore": tipi[tipo][i]})
            if "totale" in tipi:
                verifiche.append({"colonna": f"rimpatri {a} al {fine[a]}",
                                  "somma": sum(tipi[t][i] or 0 for t in ("forzati", "volontari assistiti") if t in tipi),
                                  "totale": tipi["totale"][i]})
    return {"righe": righe, "verifiche": verifiche}


def chiave_regione(nome):
    return re.sub(r"[^a-z]", "", nome.lower())[:5]


def leggi_csv(percorso):
    with open(percorso, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def scrivi_csv(percorso, righe, colonne):
    with open(percorso, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=colonne, extrasaction="ignore", lineterminator="\n")
        w.writeheader()
        for r in righe:
            w.writerow({c: ("" if r.get(c) is None else r[c]) for c in colonne})


def main():
    regioni = {chiave_regione(r["DenominazioneRegione"]): r for r in leggi_csv(REGIONI)}
    nazioni = {r["Nazione"]: r for r in leggi_csv(RISORSE / "nations.csv")}

    dati = {s: [] for s in SEZIONI}
    controlli, verifiche, trovate = [], [], []

    for data, versioni in versioni_per_data().items():
        estratti = [estrazione(pdf) for pdf in versioni]
        for sezione in SEZIONI:
            trovate.append({"Data_Report": data, "sezione": sezione, "trovata": False})
            for e in estratti:
                trovata = e["sezioni"][sezione]
                if trovata is None:
                    continue
                trovate[-1]["trovata"] = True
                dati[sezione] += trovata["righe"]
                if sezione in ("accoglienza", "nazionalita"):
                    controlli.append({"Data_Report": data, "sezione": sezione, "file": e["file"], "righe": trovata["righe"], "totale": trovata["totale"]})
                for v in trovata.get("verifiche", []):
                    verifiche.append({"Data_Report": data, "file": e["file"], **v})
                break

    giorni, accoglienza, nazionalita = dati["giorni"], dati["accoglienza"], dati["nazionalita"]

    for r in accoglienza:
        regione = regioni.get(chiave_regione(r["Regione"]))
        r["CodiceRegione"] = regione["CodiceRegione"] if regione else None
        r["DenominazioneRegione"] = regione["DenominazioneRegione"] if regione else None
        if regione:
            r["Regione"] = re.sub(r"/.*", "", regione["DenominazioneRegione"])

    for r in nazionalita:
        nazione = nazioni.get(r["Nazione_PDF"]) or nazioni.get(r["Nazione_PDF"].rstrip("*").strip())
        r["Nazione"] = nazione["Nation"] if nazione else r["Nazione_PDF"]
        r["ISO_3166-1"] = nazione["ISO_3166-1"] if nazione else None

    # importato qui: la validazione usa pointblank, l'estrazione no
    from valida import valida

    if not valida(dati, controlli, verifiche, trovate, regioni, nazioni, RISORSE / "anomalie_fonte.csv", RISORSE / "sezioni_assenti.csv"):
        sys.exit(1)

    giorni.sort(key=lambda r: (r["Data_Report"], r["Data"]))
    accoglienza.sort(key=lambda r: (r["Data_Report"], r["Regione"]))
    nazionalita.sort(key=lambda r: (r["Data_Report"], r["Nazione"]))
    dati["mensili"].sort(key=lambda r: (r["Data_Report"], r["Anno"], r["Mese"]))
    dati["msna"].sort(key=lambda r: (r["Data_Report"], r["Anno"], r["Fino_Al"]))
    dati["rimpatri"].sort(key=lambda r: (r["Data_Report"], r["Tipo"], r["Anno"], r["Fino_Al"]))

    scrivi_csv(DATI / "sbarchi-per-giorno.csv", giorni, ["Data", "Valore", "Note", "Fonte", "Data_Report"])
    scrivi_csv(DATI / "accoglienza.csv", accoglienza, ["Regione", "Data_Report", *COLONNE_ACCOGLIENZA.values(), "CodiceRegione", "DenominazioneRegione"])
    scrivi_csv(DATI / "nazionalita.csv", nazionalita, ["Data_Report", "Nazione", "ISO_3166-1", "Valore"])
    scrivi_csv(DATI / "sbarchi-mensili.csv", dati["mensili"], ["Data_Report", "Anno", "Mese", "Valore", "Mese_in_corso"])
    scrivi_csv(DATI / "minori-non-accompagnati.csv", dati["msna"], ["Data_Report", "Anno", "Fino_Al", "Valore"])
    scrivi_csv(DATI / "rimpatri.csv", dati["rimpatri"], ["Data_Report", "Tipo", "Anno", "Fino_Al", "Valore"])
    aggiorna_readme(max(versioni_per_data()), len(versioni_per_data()))


def aggiorna_readme(ultimo, n_report):
    """Data dell'ultimo report fra i due commenti del README dei dati. Solo la data del report e
    non quella di esecuzione: il README cambia soltanto quando arriva un report nuovo."""
    readme = DATI / "README.md"
    testo = readme.read_text(encoding="utf-8")
    riga = f"<!-- ultimo-report -->\nUltimo report incluso: **{ultimo[8:]}/{ultimo[5:7]}/{ultimo[:4]}** ({n_report} report dal 30/09/2019).\n<!-- /ultimo-report -->"
    nuovo = re.sub(r"<!-- ultimo-report -->.*?<!-- /ultimo-report -->", riga, testo, flags=re.S)
    if nuovo == testo and "<!-- ultimo-report -->" not in testo:
        sys.exit("README dei dati senza i commenti <!-- ultimo-report --> e <!-- /ultimo-report -->")
    readme.write_text(nuovo, encoding="utf-8")


if __name__ == "__main__":
    main()
