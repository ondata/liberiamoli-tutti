# Mai dati IVG 2026 — Dati sulle interruzioni volontarie di gravidanza per regione

Questo dataset raccoglie i **numeri delle interruzioni volontarie di gravidanza (IVG)** — chirurgiche e farmacologiche — e le **modalità erogative** delle Regioni italiane e delle Province autonome, per gli anni **2023, 2024 e 2025**.

I dati provengono dalle risposte alle richieste di **accesso civico generalizzato** (art. 5 c. 2 D.Lgs. 33/2013) inviate a gennaio 2026 dalle giornaliste **Chiara Lalli** e **Sonia Montegiove** a tutte le Regioni italiane e all'ISS, nell'ambito dell'indagine **"Mai dati 2026"** per l'**Associazione Luca Coscioni**. La raccolta, la pulizia e la pubblicazione come dati aperti sono curate da [Ondata](https://www.ondata.it/) in collaborazione con le autrici.

## Perché questi dati

Mentre l'ultima relazione del Ministero della Salute sull'applicazione della legge 194 si ferma ai dati del **2023**, questo dataset rende disponibili numeri più recenti — **2024 e, in parte, 2025** — ottenuti regione per regione tramite accesso civico.

Ne emerge un quadro a forte **variabilità territoriale**. Nel 2024 il ricorso al **farmacologico** è ormai prevalente: supera il 50% delle IVG in 15 delle 17 Regioni che hanno fornito dati completi, con un picco dell'**88,7% in Molise** e i valori più bassi in Friuli-Venezia Giulia (40,2%) e Marche (41,5%). La crescita tra 2023 e 2024 è marcata ma disomogenea (fino a +16,5 punti in Sardegna).

Restano forti **disomogeneità nella disponibilità dei dati**: alcune Regioni non forniscono dati validati o numerici, altre rimandano alle singole strutture, altre ancora restituiscono dati parziali o non ancora completi per il 2025 (vedi [Note sui dati](#note-sui-dati)). I dati arrivano inoltre in **formati non uniformi e raramente aperti**, che rendono trascrizione, controllo e confronto nel tempo più difficili.

A dieci anni dal **FOIA** italiano (D.Lgs. 97/2016, in vigore dal 23 giugno 2016), l'accesso a dati su diritti fondamentali continua a passare da richieste alle singole amministrazioni invece che da una pubblicazione sistematica, aggiornata, aperta e confrontabile. Questo dataset nasce per colmare quella lacuna: **trascrivere, normalizzare e pubblicare in formato aperto** ciò che dovrebbe già essere pubblico.

## La richiesta

A ciascuna Regione/ASL sono state poste 5 domande:

1. **Dati numerici IVG** — numero totale di IVG chirurgiche e farmacologiche negli anni 2023, 2024 e 2025
2. **Ricovero ordinario** — per le IVG del I trimestre è previsto il ricovero ordinario?
3. **IVG ambulatoriali** — vengono effettuate? anche in consultorio?
4. **Misoprostolo a domicilio** — se si fanno IVG ambulatoriali, è possibile l'autosomministrazione?
5. **Rimborsi** — quali tariffe/rimborsi sono previsti per le varie procedure e regimi assistenziali?

Tutte le 20 Regioni più ISS hanno risposto. Nessuna ha ignorato la richiesta.

## Dati

I dati sono in formato `CSV` (separatore `,`, codifica `UTF-8`).

| File | Descrizione |
| --- | --- |
| [`ivg_numeri.csv`](data/ivg_numeri.csv) | Dati numerici IVG in formato semi-wide, una riga per regione/anno |
| [`ivg_qualitativo.csv`](data/ivg_qualitativo.csv) | Dati qualitativi: costi, regimi di ricovero, IVG ambulatoriali |

## Schema dei dati

### `ivg_numeri`

| Campo | Tipo | Descrizione | Esempio |
| --- | --- | --- | --- |
| `nome` | stringa | Denominazione ufficiale ISTAT della regione o provincia autonoma | Abruzzo |
| `tipo` | stringa | `Regione` o `Provincia autonoma` | Regione |
| `cod_reg` | stringa | Codice regione ISTAT (2 cifre) | 13 |
| `cod_uts` | stringa | Codice UTS ISTAT (3 cifre), valorizzato solo per le province autonome | 021 |
| `anno` | intero | Anno di riferimento | 2024 |
| `chirurgica` | intero | Numero di IVG chirurgiche | 444 |
| `farmacologica` | intero | Numero di IVG farmacologiche | 603 |
| `totale` | intero | Totale IVG, valorizzato solo dove il dato non è diviso per tipo | 521 |
| `altro` | intero | Numero di IVG con altra modalità | 1 |
| `note` | stringa | Annotazioni su dati parziali, mancanti o anomalie | dati parziali: risposta relativa a una sola struttura |

### `ivg_qualitativo`

| Campo | Tipo | Descrizione |
| --- | --- | --- |
| `nome` | stringa | Denominazione ufficiale ISTAT della regione o provincia autonoma |
| `tipo` | stringa | `Regione` o `Provincia autonoma` |
| `cod_reg` | stringa | Codice regione ISTAT (2 cifre) |
| `cod_uts` | stringa | Codice UTS ISTAT (3 cifre), solo per le province autonome |
| `costo_chirurgica` | stringa | Tariffe/rimborsi dichiarati per l'IVG chirurgica |
| `costo_farmacologica` | stringa | Tariffe/rimborsi dichiarati per l'IVG farmacologica |
| `tipo_ricovero_chirurgica` | stringa | Regime di ricovero per l'IVG chirurgica (es. Ordinario, Day hospital) |
| `tipo_ricovero_farmacologica` | stringa | Regime di ricovero per l'IVG farmacologica |
| `ambulatoriali` | stringa | Se e come vengono effettuate le IVG ambulatoriali |
| `motivo_mai_dati` | stringa | Eventuale motivazione fornita per la mancata o parziale comunicazione dei dati |

## Licenza

I dati sono rilasciati con licenza **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

Li puoi usare liberamente, anche per scopi commerciali, ma devi **citare la fonte**, scrivendo "Fonte: [Mai dati 2026](https://github.com/ondata/liberiamoli-tutti/tree/main/maidati_ivg_2026)" e inserendo il link a `https://github.com/ondata/liberiamoli-tutti/tree/main/maidati_ivg_2026`.

## Note sui dati

Alcune risposte presentano dati parziali, disomogenei o assenti. Il file `ivg_numeri` contiene **19 unità territoriali**: mancano **Calabria** e **Provincia autonoma di Trento**, che non hanno trasmesso dati numerici (sono comunque presenti nel file `ivg_qualitativo`, che copre tutte le 21 unità). Le anomalie sono riportate anche nella colonna `note` di `ivg_numeri` e si sintetizzano qui:

- **Calabria** — non ha trasmesso dati numerici: non compare in `ivg_numeri`.
- **Provincia autonoma di Trento** — rimanda alle singole strutture e non fornisce dati numerici: non compare in `ivg_numeri`.
- **Piemonte** — presente con le tre annualità ma **senza valori**: i dati 2023-2025 risultano non validati, in verifica o in lavorazione (dettaglio nella colonna `note`).
- **Liguria** — risposta parziale: i dati comunicati si riferiscono a una sola struttura. La nota è presente su tutte e tre le annualità.
- **Friuli-Venezia Giulia** — i dati pubblicati sono i totali regionali (una prima comunicazione conteneva i dati della sola ASUGI ed è stata corretta). Manca il 2025.
- **Veneto** — i dati 2025 sono relativi al solo primo semestre.
- **Provincia autonoma di Bolzano/Bozen** — fornisce il solo totale (colonna `totale`), non suddiviso tra chirurgiche e farmacologiche.
- **2025 non fornito** da alcune Regioni (es. Abruzzo, Emilia-Romagna, Marche, Sicilia, Toscana, Valle d'Aosta): per queste sono presenti solo le righe 2023 e 2024.
- La colonna `altro` indica una **modalità di IVG distinta** da chirurgica e farmacologica e va sommata a queste nel calcolo del totale regionale.
