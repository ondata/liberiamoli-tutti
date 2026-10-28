# Note sui dati

I dati sono estratti dai PDF del [Cruscotto statistico giornaliero](https://libertaciviliimmigrazione.dlci.interno.gov.it/documentazione/dati-e-statistiche/cruscotto-statistico-giornaliero) del Ministero dell'Interno. Un PDF non è un formato pensato per essere letto da un programma: errori, incoerenze e cambi di impaginazione della fonte vanno gestiti caso per caso. Qui si annota cosa abbiamo trovato e come lo abbiamo trattato.

Indice:

- Come si estraggono i dati
- Più versioni dello stesso report
- Anomalie della fonte
- Correzioni ai dataset del 28 ottobre 2026
- Cambi di formato del PDF
- Controlli automatici

## Come si estraggono i dati

- Archivio dei PDF in [`rawdata/pdf`](../rawdata/pdf), con un [manifest](../rawdata/pdf/manifest.csv) che tiene per ogni file URL, impronta `sha256` e se è ancora sul sito.
- Estrazione con [`script/estrai.py`](../script/estrai.py) e validazione con [`script/valida.py`](../script/valida.py). Se un controllo fallisce, i CSV non vengono scritti.
- Report considerati: dal 30 settembre 2019. I report dal 2017 al 15 settembre 2019 sono archiviati ma non estratti.
- Sbarchi per giorno: si legge la tabella dei giorni, abbinando ogni etichetta (`19-set`) al valore sulla stessa riga. Non si usano le etichette del grafico a barre, che a volte mancano o si sovrappongono.
- Accoglienza e nazionalità: tabelle lette con `pdfplumber`.
- Per ogni report si tengono solo i giorni fino alla data del report.

## Più versioni dello stesso report

Per 16 date l'archivio ha due PDF diversi con la stessa data: quello scaricato a suo tempo e quello oggi sul sito, che finisce in `_v2`. Per ogni sezione si usa la versione che la contiene e, se la contengono entrambe, la più recente (`_v2`).

Le versioni con dati diversi:

| Report | Differenza |
|---|---|
| 2020-11-30 | sbarchi del 29 novembre: 21 nella prima versione, 0 nella `_v2`; nazionalità: Costa d'Avorio 1.739 → 1.737, altre 6.514 → 6.495 |
| 2022-12-31 | la prima versione conta gli sbarchi entro le ore 24:00, la `_v2` entro le 8:00; sbarchi del 26, 27 e 31 dicembre: 483, 650, 672 → 486, 653, 674; nazionalità: altre 17.561 → 17.572 |
| 2023-03-15 | accoglienza: valori SAI di 13 regioni e hot spot di Puglia e Sicilia |
| 2024-04-30 | accoglienza: Lazio, centri di accoglienza 10.141 → 10.154 |
| 2025-01-15 | accoglienza: Abruzzo 3.159 → 2.972, Lombardia 15.131 → 15.133, hot spot Calabria 31 → 32 |

In sei casi la `_v2` ha 6 pagine invece di 8 e le manca qualche sezione: per quelle sezioni si usa la prima versione. Per il 15 luglio 2021 la nostra copia era illeggibile; la versione oggi sul sito si apre e il report è ora nei dati.

## Anomalie della fonte

Lasciate come sono nel PDF, annotate perché i controlli non le scambino per errori di estrazione.

- Totali che non tornano: in 22 casi la somma delle righe non è uguale al totale stampato nel PDF. Elenco in [`script/risorse/anomalie_fonte.csv`](../script/risorse/anomalie_fonte.csv), ogni caso verificato sul testo del PDF.
  - 2020-11-30: totale hot spot 899, mentre le regioni sommano 230;
  - 2021-01-15, 2021-01-31, 2021-02-15: totale dei centri di accoglienza fermo a 54.343 e dei SAI a 25.574 in tre report di fila, mentre le regioni cambiano;
  - 14 totali di riga (Sicilia, Calabria, Puglia, 2022-2025) diversi dalla somma delle colonne della regione. Per esempio, il 15 agosto 2022 i 260 presenti negli hot spot stanno sulla riga della Calabria, ma i totali di riga tornano solo se sono della Puglia.
- Report senza tabella dell'accoglienza: 2020-10-15, 2021-03-15, 2023-10-13, 2025-05-21, tutti PDF di 6 pagine. Elenco in [`script/risorse/sezioni_assenti.csv`](../script/risorse/sezioni_assenti.csv).
- Titolo sovrapposto: in alcuni report (fine 2020, agosto 2022 - gennaio 2023) il titolo della pagina dei giorni è stampato due volte e il testo estratto è illeggibile. La pagina si riconosce dalla tabella dei giorni.
- Asse del grafico sulla riga della tabella: nel gennaio-marzo 2024 l'asse "1 2 3 ..." del grafico cade alla stessa altezza della riga del 19. Si tiene il numero allineato alla colonna dei valori.
- Ora di riferimento: di norma gli sbarchi sono quelli rilevati entro le ore 8:00 del giorno; i report del 31 dicembre 2022 (prima versione) e del 31 dicembre 2023 dichiarano le ore 24:00. La colonna `Note` riporta quella del PDF.
- Nomi di nazione: refusi e varianti (`Ngeria`, `Costa D'Avorio`, `Altre*`) sono ricondotti a un nome unico con [`script/risorse/nations.csv`](../script/risorse/nations.csv).
- Report fuori calendario: il 21 maggio 2025 il Ministero ha pubblicato un report fuori dalla cadenza quindicinale. È nei dati con la sua data.
- Report non più sul sito: 2022-05-15, 2023-10-13, 2024-07-15, 2024-07-31, 2025-05-31. Sono nel nostro archivio e nei dati.

## Correzioni ai dataset del 28 ottobre 2026

I dataset sono stati rigenerati con il nuovo estrattore. Rispetto alle versioni precedenti:

- `sbarchi-per-giorno.csv`:
  - tolte 1.095 righe con giorni successivi alla data del report, registrati come 0 sbarchi. La tabella del PDF elenca tutti i giorni del mese e lascia a 0 quelli non ancora avvenuti. Tra queste c'erano 7 date inesistenti (`2024-04-31`, `2024-09-31`, `2025-02-29`, `2025-02-30`, `2025-02-31`, `2025-04-31`, `2025-06-31`) e un valore `0[VALORE]0`;
  - aggiunti i report del 15 luglio 2021, del 13 ottobre 2023 e del 21 maggio 2025, e quelli dal 30 settembre 2025 al 31 maggio 2026;
  - per il 31 dicembre 2023 la nota ora riporta le ore 24:00, come nel PDF.
- `accoglienza.csv`:
  - Valle d'Aosta, 28 febbraio 2022: colonne sfasate di una. Ora hot spot vuoto, centri di accoglienza 28, SAI 23, come nel PDF;
  - recuperato il report del 31 marzo 2024, prima perso perché il file aveva la data scritta con i punti;
  - aggiunti i report dal 30 settembre 2025 al 15 ottobre 2026.
- `nazionalita.csv`:
  - tolto il report "2024-05-02", doppione del 30 aprile 2024 con la data di pubblicazione al posto di quella del report;
  - aggiunti i report fino al 28 ottobre 2026.
- In tutti e tre, i valori delle date con due versioni vengono ora dalla `_v2` (vedi sopra).

## Cambi di formato del PDF

- Dal 15 giugno 2026 il PDF non ha più gli sbarchi per giorno, solo i totali mensili, e ha nuove sezioni su minori stranieri non accompagnati e rimpatri. `sbarchi-per-giorno.csv` si ferma al 31 maggio 2026.
- Dal 28 ottobre 2026 il PDF non ha più la tabella dell'accoglienza per regione. `accoglienza.csv` si ferma al 15 ottobre 2026.

## Controlli automatici

Prima di scrivere i CSV, `script/valida.py` verifica con [pointblank](https://posit-dev.github.io/pointblank/):

- date valide, giorni non successivi alla data del report e nello stesso mese;
- tutti i giorni dal 1 alla data del report, una riga per giorno e report;
- regioni riconosciute e 20 per report, nazioni riconosciute;
- valori non negativi, nessuna riga doppia;
- somma delle righe uguale ai totali stampati nel PDF, salvo le anomalie annotate;
- presenza delle sezioni attese in ogni report, salvo le assenze annotate.
