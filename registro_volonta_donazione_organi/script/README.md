# Dichiarazione volontà donazioni di organi - Scraping per Comune e ASL Regionali

Questo progetto contiene due script Python per scaricare automaticamente i dati pubblicati sul sito del [Centro Nazionale Trapianti](https://trapianti.sanita.it/statistiche/approfondimento.aspx), relativi alle **dichiarazioni di volontà per anno**.

## 📁 Script disponibili

### `donatori_italia_comuni.py`

📍 Estrae i dati **per ogni comune italiano**, organizzati per regione e provincia.

Si tratta delle dichiarazioni di volontà presso gli Uffici Anagrafe dei Comuni che hanno aderito al progetto ‘Una scelta in Comune’.

- Seleziona ogni regione
- Attiva la modalità **Comune**
- Scorre tutte le province e i comuni
- Esegue la query
- Estrae la tabella e la salva come:
  - `comuni_html/{regione}_{provincia}_{comune}.html`
  - `comuni_csv/{regione}_{provincia}_{comune}.csv`

🔁 Lo script **evita di riscaricare** i dati già presenti.

---

### `donatori_italia_asl.py`

🏥 Estrae i dati **delle ASL regionali**.

Si tratta delle dichiarazioni di volontà presso le ASL.

- Scorre tutte le regioni italiane
- Mantiene attiva la modalità **ASL** (già selezionata di default)
- Esegue la query per ciascuna regione
- Estrae la tabella e la salva come:
  - `asl_html/{regione}.html`
  - `asl_csv/{regione}.csv`

🧼 Pulisce automaticamente i file vuoti prima di partire.

### `donatori_italia_corrente.py`

Estrae i dati **attuali** delle dichiarazioni di volontà dai comuni italiani, come mostrati nella sezione "Italia" del sito.

- Apre la pagina [https://trapianti.sanita.it/statistiche/dichiarazioni_italia.aspx](https://trapianti.sanita.it/statistiche/dichiarazioni_italia.aspx)
- Scorre tutte le regioni
- Per ogni regione:

  - Estrae e salva la **tabella delle province** in `output_province/{regione}.csv`
  - Per ogni provincia:
    - Apre la pagina dettagliata
    - Estrae la **tabella dei comuni** e la salva in `output_comuni/{provincia}.csv`

📦 Le colonne salvate per le province includono: `provincia`, `n_comuni_attivi`, `consensi_num`, `consensi_perc`, `opposizioni_num`, `opposizioni_perc`, `totale_comuni`, `iscrizioni_aido`, `totale_dichirazioni`

📦 Le colonne salvate per i comuni includono: `comune`, `inizio_attivita`, `consensi_num`, `consensi_perc`, `opposizioni_num`, `opposizioni_perc`, `totale`

---

## ✅ Requisiti

- Python 3.9+
- [Playwright](https://playwright.dev/python/)
- [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/)
