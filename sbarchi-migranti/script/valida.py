"""Schema e controlli dei dati estratti dai PDF del Cruscotto, con pointblank.

valida() restituisce False e stampa i controlli falliti, con qualche riga d'esempio:
in quel caso estrai.py non scrive i CSV.
"""

from datetime import date
from pathlib import Path

import pointblank as pb
import polars as pl

COLONNE_ACCOGLIENZA = [
    "Migranti presenti negli hot spot",
    "Migranti presenti nei centri di accoglienza",
    "Migranti presenti nei centri SIPROIMI",
    "Migranti presenti nei centri SAI",
]


def data_valida(testo):
    try:
        date.fromisoformat(testo)
        return True
    except ValueError:
        return False


def coerenza_totali(controlli):
    """Una riga per report, sezione e colonna: somma delle righe estratte e totale stampato nel PDF."""
    righe = []
    for c in controlli:
        if c["sezione"] == "nazionalita":
            righe.append({
                "Data_Report": c["Data_Report"], "file": c["file"], "colonna": "Valore",
                "somma": sum(r["Valore"] for r in c["righe"]), "totale": c["totale"],
            })
            continue
        totale = c["totale"] or {}
        for chiave, nome in zip(["hot", "acc", "sip", "sai"], COLONNE_ACCOGLIENZA):
            if chiave not in totale:
                continue
            righe.append({
                "Data_Report": c["Data_Report"], "file": c["file"], "colonna": nome,
                "somma": sum(r[nome] or 0 for r in c["righe"]), "totale": totale[chiave],
            })
        # totale di riga: le colonne di una regione sommano alla sua colonna "Totale"
        for r in c["righe"]:
            if r["_totale"] is not None:
                righe.append({
                    "Data_Report": c["Data_Report"], "file": c["file"], "colonna": f"Totale riga {r['Regione']}",
                    "somma": sum(r[n] or 0 for n in COLONNE_ACCOGLIENZA), "totale": r["_totale"],
                })
    return pl.DataFrame(righe, schema={"Data_Report": pl.String, "file": pl.String, "colonna": pl.String, "somma": pl.Int64, "totale": pl.Int64})


# ultimo report in cui il Ministero pubblica la sezione; dopo cambia il formato del PDF
ULTIMO_REPORT = {"giorni": "2026-05-31", "accoglienza": "2026-10-15", "nazionalita": "9999-12-31"}


def valida(giorni, accoglienza, nazionalita, controlli, trovate, regioni, nazioni, anomalie_note, sezioni_assenti):
    """anomalie_note: CSV di discrepanze fra righe e totali già verificate a mano sul PDF.
    Passano solo se report, colonna, somma e totale sono identici a quelli annotati.
    sezioni_assenti: CSV dei report in cui una sezione attesa manca in tutte le versioni del PDF."""
    g = pl.DataFrame(giorni).with_columns(
        data_ok=pl.col("Data").map_elements(data_valida, return_dtype=pl.Boolean)
    )
    per_report = g.group_by("Data_Report").agg(n=pl.len(), ultimo=pl.col("Data").max())

    a = pl.DataFrame(accoglienza, infer_schema_length=None)
    n = pl.DataFrame(nazionalita, infer_schema_length=None)
    note = pl.read_csv(anomalie_note, schema_overrides={"Data_Report": pl.String, "somma": pl.Int64, "totale": pl.Int64})
    t = coerenza_totali(controlli).join(
        note.select("Data_Report", "colonna", "somma", "totale", nota=pl.lit(True)),
        on=["Data_Report", "colonna", "somma", "totale"], how="left",
    ).with_columns(pl.col("nota").fill_null(False))

    assenti = pl.read_csv(sezioni_assenti, schema_overrides={"Data_Report": pl.String})
    copertura = (
        pl.DataFrame(trovate)
        .with_columns(attesa=pl.col("Data_Report") <= pl.col("sezione").replace_strict(ULTIMO_REPORT))
        .join(assenti.select("Data_Report", "sezione", nota=pl.lit(True)), on=["Data_Report", "sezione"], how="left")
        .with_columns(pl.col("nota").fill_null(False))
    )

    codici = [r["CodiceRegione"] for r in regioni.values()]
    iso = {r["ISO_3166-1"] for r in nazioni.values()}

    validazioni = [
        (
            "sbarchi-per-giorno",
            pb.Validate(g, tbl_name="sbarchi-per-giorno")
            .col_vals_expr(pl.col("data_ok"), brief="Data è una data valida")
            .col_vals_expr(pl.col("Data") <= pl.col("Data_Report"), brief="Data non successiva a Data_Report")
            .col_vals_expr(pl.col("Data").str.slice(0, 7) == pl.col("Data_Report").str.slice(0, 7), brief="Data nel mese del report")
            .col_vals_ge("Valore", 0, brief="Valore >= 0")
            .rows_distinct(["Data", "Data_Report"], brief="una riga per giorno e report"),
        ),
        (
            "sbarchi-per-giorno, completezza",
            pb.Validate(per_report, tbl_name="giorni per report")
            .col_vals_expr(pl.col("n") == pl.col("Data_Report").str.slice(8, 2).cast(pl.Int64), brief="tutti i giorni dal 1 alla data del report")
            .col_vals_expr(pl.col("ultimo") == pl.col("Data_Report"), brief="ultimo giorno = data del report"),
        ),
        (
            "accoglienza",
            pb.Validate(a, tbl_name="accoglienza")
            .col_vals_in_set("CodiceRegione", codici, brief="regione riconosciuta")
            .rows_distinct(["Data_Report", "Regione"], brief="una riga per regione e report")
            .col_vals_ge(COLONNE_ACCOGLIENZA, 0, na_pass=True, brief="valori >= 0")
            .col_vals_expr(pl.len().over("Data_Report") == 20, brief="20 regioni per report"),
        ),
        (
            "nazionalita",
            pb.Validate(n, tbl_name="nazionalita")
            .col_vals_expr((pl.col("Nazione") == "altre") | pl.col("ISO_3166-1").is_in(list(iso)), brief="nazione riconosciuta in nations.csv")
            .rows_distinct(["Data_Report", "Nazione"], brief="una riga per nazione e report")
            .col_vals_ge("Valore", 0, brief="Valore >= 0"),
        ),
        (
            "sezioni per report",
            pb.Validate(copertura, tbl_name="copertura")
            .col_vals_expr(pl.col("trovata") | ~pl.col("attesa") | pl.col("nota"), brief="sezione attesa presente, salvo assenze note")
            .col_vals_expr(~(pl.col("trovata") & pl.col("nota")), brief="nessuna assenza annotata che invece c'è"),
        ),
        (
            "totali stampati nel PDF",
            pb.Validate(t, tbl_name="totali")
            .col_vals_not_null("totale", brief="totale presente")
            .col_vals_expr((pl.col("somma") == pl.col("totale")) | pl.col("nota"), brief="somma delle righe = totale del PDF, salvo anomalie note della fonte"),
        ),
    ]

    tutto_ok = True
    for nome, v in validazioni:
        v = v.interrogate()
        falliti = v.n_failed()
        estratti = v.get_data_extracts()
        for passo, info in enumerate(v.validation_info, start=1):
            stato = "ok" if falliti[passo] == 0 else f"FALLITO su {falliti[passo]} righe"
            print(f"[{nome}] {info.brief}: {stato}")
            if falliti[passo]:
                tutto_ok = False
                esempio = estratti.get(passo)
                if esempio is not None:
                    print(pl.from_dataframe(esempio).head(10) if not isinstance(esempio, pl.DataFrame) else esempio.head(10))
    print(f"[totali stampati nel PDF] anomalie note della fonte: {t['nota'].sum()} su {note.height} annotate")
    nuove = t.filter((pl.col("somma") != pl.col("totale")) & ~pl.col("nota"))
    if nuove.height:
        # elenco completo, da verificare sul PDF ed eventualmente annotare in anomalie_fonte.csv
        nuove.drop("nota").write_csv(Path(anomalie_note).parent.parent.parent / "tmp" / "totali_discordanti.csv")
    return tutto_ok
