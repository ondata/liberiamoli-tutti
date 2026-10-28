# Script

Due passi, lanciati dal workflow [`sbarchi_migranti_archivio.yml`](../../.github/workflows/sbarchi_migranti_archivio.yml) il lunedì e il giovedì:

```bash
./script/archivia_pdf.sh
uv run script/estrai.py
```

## archivia_pdf.sh

Archivia in `rawdata/pdf` i PDF del Cruscotto statistico giornaliero, dalla pagina `https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero`.

- Idempotente: per gli URL già visti fa una richiesta condizionale (`If-None-Match` con l'ETag salvato) e il server risponde `304` senza rimandare il file. Un file viene scritto solo se il suo `sha256` non è già in archivio.
- Nomi: `YYYY-MM-DD_cruscotto_statistico_giornaliero.pdf`; se per la stessa data arriva un contenuto diverso, `_v2`, `_v3`, ...
- Tiene traccia di URL e file in `rawdata/pdf/manifest.csv`: `data_report`, `nome_file`, `sha256`, `url`, `sul_sito` (`si`/`no`), `etag`, `last_modified`, `content_length`, `prima_vista`. Gli URL spariti dal sito restano con `sul_sito=no`; i file senza URL sono quelli scaricati dal vecchio sito.
- L'impronta dei file già archiviati viene dal manifest: in CI i PDF sono puntatori Git LFS e non serve scaricarli.
- Esce con errore se la pagina non risponde, se non contiene PDF, se un file non è un PDF o se non si ricava la data né dal nome né dal testo.
- Richiede `curl`, `perl`, `pdftotext`, `sha256sum`, `mlr` (Miller 6).

## estrai.py

Estrae dai PDF sbarchi per giorno, accoglienza per regione, nazionalità, sbarchi mensili, minori stranieri non accompagnati e rimpatri, li valida con `valida.py` e scrive i CSV in `dati/` solo se tutti i controlli passano. Dipendenze dichiarate nello script: `uv run` crea l'ambiente da solo.

- Report dal 2019-09-30 in poi.
- Per ogni data usa la versione del PDF che contiene la sezione cercata, a parità la più recente (`_vN` più alto).
- Sbarchi per giorno: la pagina è quella con più etichette `dd-mmm`; ogni etichetta è abbinata al valore sulla stessa riga, allineato al bordo destro della colonna dei valori. Si ignorano i numeri in grassetto, che sono le etichette del grafico.
- Accoglienza e nazionalità: tabelle lette con `pdfplumber` dalla pagina che contiene `spot` e `azional`.
- Sbarchi mensili: griglia mesi per anni costruita dalle posizioni delle parole, in entrambi i formati del PDF; solo i numeri con il carattere dei valori della tabella. Verifica: somma dei mesi uguale al totale annuo del PDF.
- Minori non accompagnati e rimpatri: testo della pagina, riga per riga. Verifica per i rimpatri: forzati più volontari uguale alla riga Totale.
- L'estrazione di ogni PDF è salvata in `rawdata/estratti/<nome>.json` e riusata ai giri successivi. Se cambia il modo di estrarre, si incrementa `VERSIONE_ESTRATTORE` e si rilancia in locale, dove ci sono i PDF veri.

## valida.py

Controlli con [pointblank](https://posit-dev.github.io/pointblank/): date valide e non successive al report, giorni e mesi completi, regioni e nazioni riconosciute, chiavi uniche, valori non negativi, somme uguali ai totali stampati nel PDF, presenza delle sezioni attese.

Le anomalie della fonte già verificate a mano sono in due file, letti dalla validazione:

- `risorse/anomalie_fonte.csv`: totali del PDF che non coincidono con la somma delle righe. Un caso passa solo se report, colonna, somma e totale sono identici a quelli annotati. Le discrepanze nuove sono scritte in `tmp/totali_discordanti.csv`, da verificare sul PDF prima di annotarle.
- `risorse/sezioni_assenti.csv`: report in cui una sezione attesa manca in tutte le versioni del PDF.

## Risorse

- `risorse/nations.csv`: nome della nazione come compare nel PDF, refusi compresi, verso nome normalizzato e codice ISO 3166-1. Un nome nuovo fa fallire la validazione finché non viene aggiunto.
- `../../risorse/Elenco-regioni.csv`: codici ISTAT delle regioni.

Le note sui dati, con anomalie e correzioni, sono in [`../dati/note-sui-dati.md`](../dati/note-sui-dati.md).
