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
VERSIONE_ESTRATTORE = 1
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
        return {"illeggibile": True, "sezioni": {"giorni": None, "accoglienza": None, "nazionalita": None}}
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

    giorni, accoglienza, nazionalita, controlli, trovate = [], [], [], [], []

    for data, versioni in versioni_per_data().items():
        estratti = [estrazione(pdf) for pdf in versioni]
        for sezione, destinazione in [("giorni", giorni), ("accoglienza", accoglienza), ("nazionalita", nazionalita)]:
            trovate.append({"Data_Report": data, "sezione": sezione, "trovata": False})
            for e in estratti:
                trovata = e["sezioni"][sezione]
                if trovata is None:
                    continue
                trovate[-1]["trovata"] = True
                destinazione += trovata["righe"]
                if sezione != "giorni":
                    controlli.append({"Data_Report": data, "sezione": sezione, "file": e["file"], "righe": trovata["righe"], "totale": trovata["totale"]})
                break

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

    if not valida(giorni, accoglienza, nazionalita, controlli, trovate, regioni, nazioni, RISORSE / "anomalie_fonte.csv", RISORSE / "sezioni_assenti.csv"):
        sys.exit(1)

    giorni.sort(key=lambda r: (r["Data_Report"], r["Data"]))
    accoglienza.sort(key=lambda r: (r["Data_Report"], r["Regione"]))
    nazionalita.sort(key=lambda r: (r["Data_Report"], r["Nazione"]))

    scrivi_csv(DATI / "sbarchi-per-giorno.csv", giorni, ["Data", "Valore", "Note", "Fonte", "Data_Report"])
    scrivi_csv(DATI / "accoglienza.csv", accoglienza, ["Regione", "Data_Report", *COLONNE_ACCOGLIENZA.values(), "CodiceRegione", "DenominazioneRegione"])
    scrivi_csv(DATI / "nazionalita.csv", nazionalita, ["Data_Report", "Nazione", "ISO_3166-1", "Valore"])


if __name__ == "__main__":
    main()
