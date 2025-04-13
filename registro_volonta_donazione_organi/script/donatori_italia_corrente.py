from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from bs4 import BeautifulSoup
import pandas as pd
import time
import os

# Imposta il driver NON headless
chrome_options = Options()
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--no-sandbox")

driver = webdriver.Chrome(options=chrome_options)
url = "https://trapianti.sanita.it/statistiche/dichiarazioni_italia.aspx"

print("Apro la pagina...")
driver.get(url)

# Attendi i bottoni delle regioni
WebDriverWait(driver, 10).until(
    EC.presence_of_element_located((By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]"))
)

# Prendi tutti i bottoni delle regioni
regioni = driver.find_elements(By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]")
regioni_nomi = [r.text.strip() for r in regioni]

for nome_regione in regioni_nomi:
    print(f"\nClick su {nome_regione}...")

    # Ricarica i bottoni (dopo ogni "back")
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]"))
    )

    region_buttons = driver.find_elements(By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]")
    for b in region_buttons:
        if b.text.strip() == nome_regione:
            b.click()
            break
    time.sleep(2)

    # ✅ Estrai la tabella delle province
    html_province = driver.page_source
    soup_province = BeautifulSoup(html_province, "html.parser")
    province_rows = soup_province.select("tr.row-eq-height.myHeight8")
    dati_province = []

    for row in province_rows:
        celle = row.find_all("td")
        if len(celle) == 9:
            valori = [c.get_text(strip=True) for c in row.select("td")]
            provincia = row.find("button").text.strip()
            dati_province.append([provincia] + valori[1:])

    if dati_province:
        colonne_prov = ["provincia", "n_comuni_attivi", "consensi_num", "consensi_perc",
                        "opposizioni_num", "opposizioni_perc", "totale_comuni",
                        "iscrizioni_aido", "totale_dichirazioni"]
        df_prov = pd.DataFrame(dati_province, columns=colonne_prov)
        os.makedirs("output_province", exist_ok=True)
        path_prov = f"output_province/{nome_regione.lower().replace(' ', '_')}.csv"
        df_prov.to_csv(path_prov, index=False)
        print(f"✅ Salvata tabella province: {path_prov}")

    # Bottoni province per entrare nei comuni
    province_buttons = driver.find_elements(By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]")
    print(f"Trovate {len(province_buttons)} province.")

    for i in range(len(province_buttons)):
        province_buttons = driver.find_elements(By.XPATH, "//button[@type='submit' and contains(@class, 'btn-link')]")
        provincia_button = province_buttons[i]
        nome_provincia = provincia_button.text.strip().lower().replace(" ", "_")
        print(f"➡️  Click su provincia: {nome_provincia}")
        provincia_button.click()
        time.sleep(2)

        html = driver.page_source
        soup = BeautifulSoup(html, "html.parser")
        rows = soup.select("tr.row-eq-height.myHeight12")

        dati = []
        for row in rows:
            celle = row.find_all("td")
            if len(celle) == 7:
                dati.append([c.text.strip() for c in celle])

        if dati:
            colonne = ["comune", "inizio_attivita", "consensi_num", "consensi_perc",
                       "opposizioni_num", "opposizioni_perc", "totale"]
            df = pd.DataFrame(dati, columns=colonne)
            os.makedirs("output_comuni", exist_ok=True)
            path = f"output_comuni/{nome_provincia}.csv"
            df.to_csv(path, index=False)
            print(f"✅ Salvato: {path}")
        else:
            print(f"⚠️ Nessun dato trovato per {nome_provincia}")

        driver.back()
        time.sleep(2)

    driver.back()
    time.sleep(2)

driver.quit()
