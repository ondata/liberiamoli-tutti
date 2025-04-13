from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
from pathlib import Path
import csv
import re

regioni = {
    "130": "ABRUZZO", "170": "BASILICATA", "180": "CALABRIA", "150": "CAMPANIA",
    "080": "EMILIA_ROMAGNA", "060": "FRIULI_VENEZIA_GIULIA", "120": "LAZIO", "070": "LIGURIA",
    "030": "LOMBARDIA", "110": "MARCHE", "140": "MOLISE", "010": "PIEMONTE",
    "041": "PABOLZANO", "042": "PATRENTO", "160": "PUGLIA", "200": "SARDEGNA",
    "190": "SICILIA", "090": "TOSCANA", "100": "UMBRIA", "020": "VALLE_DAOSTA", "050": "VENETO"
}

html_dir = Path("asl_html")
csv_dir = Path("asl_csv")
html_dir.mkdir(exist_ok=True)
csv_dir.mkdir(exist_ok=True)

# pulizia file vuoti
for f in html_dir.glob("*.html"):
    if f.stat().st_size == 0:
        print(f"🗑️ Rimuovo HTML vuoto: {f.name}")
        f.unlink()
for f in csv_dir.glob("*.csv"):
    if f.stat().st_size == 0:
        print(f"🗑️ Rimuovo CSV vuoto: {f.name}")
        f.unlink()

def salva_tabella_html_come_csv(html: str, path_csv: Path):
    soup = BeautifulSoup(html, "html.parser")
    table = soup.find("table", {"id": "tab_risultati"})
    if not table:
        print(f"⚠️ Nessuna tabella trovata per {path_csv.name}")
        return
    rows = []
    for tr in table.find_all("tr"):
        td = tr.find_all("td")
        values = [cell.get_text(strip=True) for cell in td]
        if len(values) == 6:
            rows.append(values)
    if not rows:
        print(f"⚠️ Nessun dato valido per {path_csv.name}")
        return
    with path_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["anno", "consensi_num", "consensi_perc", "opposizioni_num", "opposizioni_perc", "totale"])
        writer.writerows(rows)
    print(f"✅ Salvato CSV: {path_csv.name}")

with sync_playwright() as p:
    browser = p.chromium.launch(headless=False)
    page = browser.new_page()

    page.goto("https://trapianti.sanita.it/statistiche/approfondimento.aspx")
    page.wait_for_selector('select[name="ctl00$ContentPlaceHolder1$regioni"]')

    for reg_code, reg_name in regioni.items():
        nome_file = f"{reg_code}_{reg_name.replace(' ', '_')}"
        output_csv = csv_dir / f"{nome_file}.csv"
        output_html = html_dir / f"{nome_file}.html"

        if output_csv.exists() and output_html.exists():
            print(f"⏭️ Già presente: {nome_file}")
            continue

        print(f"\n🌍 Regione: {reg_name}")
        page.select_option('select[name="ctl00$ContentPlaceHolder1$regioni"]', reg_code)
        page.wait_for_timeout(1000)

        print("🔍 Eseguo query...")
        with page.expect_navigation():
            page.click('#ContentPlaceHolder1_SubmitBtn')

        try:
            page.wait_for_selector("#tab_risultati", timeout=10000)
        except Exception:
            print(f"❌ Nessun risultato per {reg_name}")
            continue

        html = page.content()
        output_html.write_text(html, encoding="utf-8")
        salva_tabella_html_come_csv(html, output_csv)

    browser.close()
