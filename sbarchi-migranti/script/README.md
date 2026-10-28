# Script

**NOTA BENE**: gli script sono ancora da documentare. Al momento sono usabili bene soltanto da chi li ha creati.

```bash
git pull && ./archivia_pdf.sh && ./bulk_sbarchi-migranti.sh && ./bulk_sbarchi-migranti_accoglienza.sh && ./bulk_sbarchi-migranti_nazionalita.sh
```

## archivia_pdf.sh

Archivia in `rawdata/pdf` i PDF del Cruscotto statistico giornaliero, dalla pagina `https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero`.

- Idempotente: per gli URL già visti fa una richiesta condizionale (`If-None-Match` con l'ETag salvato) e il server risponde `304` senza rimandare il file. Un file viene scritto solo se il suo `sha256` non è già in archivio.
- Nomi: `YYYY-MM-DD_cruscotto_statistico_giornaliero.pdf`; se per la stessa data arriva un contenuto diverso, `_v2`, `_v3`, ...
- Tiene traccia di URL e file in `rawdata/pdf/manifest.csv`: `data_report`, `nome_file`, `sha256`, `url`, `sul_sito` (`si`/`no`), `etag`, `last_modified`, `content_length`, `prima_vista`. Gli URL spariti dal sito restano con `sul_sito=no`; i file senza URL sono quelli scaricati dal vecchio sito.
- Esce con errore se la pagina non risponde, se non contiene PDF, se un file non è un PDF o se non si ricava la data né dal nome né dal testo.
- Richiede `curl`, `perl`, `pdftotext`, `sha256sum`, `mlr` (Miller 6).

## bulk_download_pdf.sh

Superato da `archivia_pdf.sh`: punta al vecchio host, che non esiste più.

## bulk_sbarchi-migranti.sh

Estrai i dati sugli sbarchi giornalieri dai PDF.

## bulk_sbarchi-migranti_accoglienza.sh

Estrai i dati sull'accoglienza dai PDF.

## bulk_sbarchi-migranti_nazionalita.sh

Estrai i dati sulle nazionalità dai PDF.
