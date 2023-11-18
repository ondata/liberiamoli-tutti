# Introduzione

Questo è un insieme di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti**](https://datibenecomune.substack.com/about)".

## Dati

Le [Legge Regionale n° 17 del 2003](https://normelombardia.consiglio.regione.lombardia.it/NormeLombardia/Accessibile/main.aspx?exp_coll=lr002003092900017&view=showdoc&iddoc=lr002003092900017&selnode=lr002003092900017) della **Regione Lombardia** prevede la creazione del "**Registro** **pubblico** degli **edifici** industriali e ad uso abitativo con **presenza** di **amianto**". Questo registro, istituito presso ogni ASL competente per territorio, contiene l'elenco di tutti gli edifici e siti contenenti amianto, con informazioni sul luogo di presenza, il relativo stato di conservazione e il quantitativo presunto.<br>

Qui i dati per l'anno 2022, per il territorio ....

Sono in formato `CSV`, con separatore `,` e con codifica `UTF-8`. Li abbiamo resi disponibili anche in [formato Google Sheet](https://docs.google.com/spreadsheets/d/1dNlByw2cMoqGorp4zPN6OULtG_jVRCe5xpl0YdKJxFE/edit?usp=sharing), ma la fonte più affidabile è quella dei file `CSV`.

La fonte è ...

👉 **Nota Bene**: questi sono rilasciati con **licenza** [**CC-BY 4.0**](https://creativecommons.org/licenses/by/4.0/deed.it): li **puoi usare liberamente**, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo semplicemente "Fonte: [Liberiamoli tutti!](https://datibenecomune.substack.com/)" e inserendo il link ipertestuale a `https://datibenecomune.substack.com/`.

### Registro pubblico degli edifici industriali ed ad uso abitativo con presenza di amianto

Si tratta dell'elenco dei luoghi elencati nel registro, con le informazioni su Comune, indirizzo, destinazione d'uso, condizione del materiale, stato di conservazione, tipo di supporto, superficie esposta e quantità di amianto presente.

Il file è [`notifiche_amianto_milano_ovest.csv`](./dati/notifiche_amianto_milano_ovest.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipo colonna | Descrizione |
| --- | --- | --- |
| comune | string | Nome del Comune |
| indirizzo | string | Indirizzo dell'edificio |
| civico | string | Numero civico |
| destinazione | string | Destinazione d'uso dell'edificio |
| condizione_materiale | string | Condizione del materiale |
| stato_conservazione | string | Stato di conservazione del materiale |
| tipo_supporto | string | Tipo di supporto |
| superfice_esposta | number | Superficie esposta in metri quadrati |
| quantita_kg | number | Quantità in chilogrammi |
| quantita_m2 | number | Quantità in metri quadrati |
| quantita_m3 | number | Quantità in metri cubi |
| comune_istat | string | Codice Istat del Comune |

## Note

### Tipologia dati

La colonna `Tipologia dati` indica il tipo di dato presente nella colonna. I tipi di dato sono:

- `date`: Questo tipo di campo è utilizzato per contenere date e/o orari. Nel contesto di questo dati si tratte di date in formato anno-mese-giorno (YYYY-MM-DD), come ad esempio `2020-01-18`;
- `number`: Il campo contiene numeri di qualsiasi tipo, compresi i decimali;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.
