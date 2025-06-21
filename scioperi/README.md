# Introduzione

L'idea è quella di liberare i dati sugli **scioperi** in **Italia**. È un'idea di [Raffaele Mastrolonardo](https://www.linkedin.com/in/mastrolonardo/).

## Fonti

Al momento stiamo utilizzando queste:

- Ministero delle Infrastrutture e dei Trasporti <https://scioperi.mit.gov.it/mit2/public/scioperi/ricerca>
- Commissione di Garanzia Scioperi <https://www.cgsse.it/calendario-scioperi>

La Commissione di Garanzia Scioperi è *autorità amministrative indipendente**, che svolge funzioni amministrative per conto dello Stato, garantendo l'applicazione della legge e la tutela dei diritti dei cittadini.

## Script

Il progetto include due script automatizzati per il download e l'elaborazione dei dati sugli scioperi:

### Script MIT (`mit.sh`)

Questo script scarica i dati degli scioperi dal sito del **Ministero delle Infrastrutture e dei Trasporti**. Effettua una ricerca automatica per l'anno corrente (2025), estrae i dati dalla tabella HTML utilizzando XPath e li converte in formato JSON. I dati vengono poi elaborati con Miller per standardizzare le date in formato ISO e ordinati cronologicamente. L'output finale viene salvato sia in formato JSONL che CSV.

### Script CGSSE (`cgsse.sh`)

Questo script scarica i dati dal calendario scioperi della **Commissione di Garanzia Scioperi**. Utilizza Tor come proxy per garantire l'anonimato e include un sistema di retry robusto per gestire eventuali fallimenti di rete. Lo script naviga automaticamente tutte le pagine del calendario, estrae i dati degli scioperi (inclusi settore, azienda, sindacato, ambito geografico e stato di revoca) e li elabora per produrre file JSONL e CSV strutturati. Include anche una modalità debug per testare il download su un numero limitato di pagine.
