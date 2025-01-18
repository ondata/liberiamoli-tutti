# Script per il progetto Soldi e Politica

Questi script servono per scaricare ed elaborare i dati sulle erogazioni ai partiti politici italiani.

## Script disponibili

### download.sh

Scarica i file PDF contenenti i dati sulle erogazioni ai partiti politici dal sito della Camera dei Deputati.

Cosa fa:
1. Verifica la raggiungibilità del sito
2. Crea la cartella `raw_data` se non esiste
3. Scarica la lista dei file PDF disponibili
4. Scarica i singoli file PDF (solo se non già presenti)

Come usarlo:
```bash
./download.sh
```

I file verranno salvati nella cartella `../raw_data`

### extract_nomi_partiti.sh

Estrae i nomi dei partiti e la pagina di riferimento dai file PDF scaricati.

Cosa fa:
1. Prende in input un file PDF
2. Estrae il testo da ogni pagina
3. Cerca i nomi dei partiti
4. Produce un output in formato JSONL con pagina e testo estratto

Come usarlo:
```bash
./extract_nomi_partiti.sh FILE_PDF > output.jsonl
```

Opzioni:
- `-h` o `--help`: mostra l'aiuto sull'uso dello script

### merge.sh

Unisce i dati estratti dai CSV con i nomi dei partiti estratti dai PDF.

Cosa fa:
1. Prende in input una cartella contenente i file CSV
2. Unisce i dati con i nomi dei partiti estratti
3. Produce un file CSV finale con tutte le informazioni

Come usarlo:
```bash
./merge.sh /path/to/input_folder
```

Il nome del file di output sarà basato sul nome della cartella di input.

## Dipendenze

Gli script richiedono:
- `curl` per il download
- `jq` per processare JSON
- `pdf2txt` (da poppler-utils) per estrarre testo da PDF
- `parallel` per l'elaborazione parallela
- `pdfinfo` per ottenere informazioni sui PDF
- `mlr` (Miller) per l'elaborazione di file CSV

Per installare le dipendenze su Debian/Ubuntu:
```bash
sudo apt install curl jq poppler-utils parallel miller
```

## Note

I dati sono pubblicati dalla Camera dei Deputati all'indirizzo:
https://parlamento18.camera.it/199
