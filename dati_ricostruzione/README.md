# Dati sulla ricostruzione post-sisma

I dati sulla ricostruzione post-sisma, che sono stati ricavati grazie al FOIA che ha fatto Action Aid, come descritto nel numero 14 di "Liberemioli tutti!", suddivisi per interventi su edifici privati e pubblici.
Fonte: Dipartimento della Protezione Civile.

## `privata.csv`

[Questo file](data/privata.csv) contiene i dati relativi agli interventi di ricostruzione su edifici privati.

### Schema

* **provincia**: _Provincia_ di riferimento.
* **comune**: _Comune_ di riferimento.
* **numero_fascicolo**: _Numero_ identificativo del fascicolo.
* **regione**: _Regione_ di riferimento.
* **indirizzo**: _Indirizzo_ dell'intervento.
* **stato**: _Stato_ attuale dell'intervento (es. concluso, in corso).
* **cup**: _Codice Unico di Progetto_ associato all'intervento.
* **tipologia_beneficiario**: _Tipologia_ del beneficiario (es. persona fisica, impresa).
* **tipologia_intervento**: _Tipologia_ specifica dell'intervento (es. ricostruzione, riparazione).
* **importo_richiesto**: _Importo_ richiesto per l'intervento.
* **importo_concesso**: _Importo_ concesso per l'intervento.
* **importo_liquidato**: _Importo_ liquidato per l'intervento.
* **flag_superbonus**: _Flag_ che indica se l'intervento rientra nel Superbonus (0/1).
* **area_kmq**: _Area_ in kmq del comune.
* **popolazione_residente**: _Popolazione_ residente nel comune.
* **pro_com_t**: _Codice_ ISTAT del comune (formato testo).
* **url_opencup**: _URL_ al dettaglio del CUP su OpenCUP.

### Esempio di dati

```csv
provincia,comune,numero_fascicolo,regione,indirizzo,stato,cup,tipologia_beneficiario,tipologia_intervento,importo_richiesto,importo_concesso,importo_liquidato,flag_superbonus,area_kmq,popolazione_residente,pro_com_t,url_opencup
AQ,CAPITIGNANO,1306602100000149602020,ABRUZZO,VIA SAN CARLO,Chiuso,B93E22000920008,Delegato,RCR-CI-L0,43838.07,43742.55,47096.78,no,30.6391,623,066021,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/B93E22000920008
AQ,CAPITIGNANO,1306602100000025322019,ABRUZZO,PIAZZA DEL MUNICIPIO,Chiuso,B93E23000440001,Singolo Proprietario,RCR-CI-L0,25547.45,24997.34,28158.62,no,30.6391,623,066021,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/B93E23000440001
AQ,CAPITIGNANO,1306602100000006042018,ABRUZZO,via Angelo Maria Ricci,Chiuso,B91G19000610001,Delegato di condominio non registrato,RCR-CI-L0,143550.84,139190.87,82706.05,no,30.6391,623,066021,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/B91G19000610001
```

## `pubblica.csv`

Questo file contiene i dati relativi agli interventi di ricostruzione su edifici pubblici.

### Schema

* **eu_es**: _Identificativo_ europeo dell'intervento.
* **ordinanza_attuale**: _Numero_ dell'ordinanza attuale.
* **oc_os**: Se OC/OS, OC Ordinanza Commissariale e OS Ordinanza Straordinaria
* **regione**: _Regione_ di riferimento.
* **prov**: _Provincia_ di riferimento.
* **comune**: _Comune_ di riferimento.
* **cup**: _Codice Unico di Progetto_ associato all'intervento.
* **cup_master_unico**: _Codice Unico di Progetto Master_ (se aggregato).
* **intervento_nome**: _Nome_ dell'intervento.
* **soggetto_attuatore**: _Soggetto_ attuatore dell'intervento.
* **importo_programmato**: _Importo_ programmato per l'intervento.
* **fase_di_avanzamento_al_22_dicembre_2024**: _Fase_ di avanzamento dell'intervento alla data specificata.
* **url_opencup**: _URL_ al dettaglio del CUP su OpenCUP.
* **pro_com_t**: _Codice_ ISTAT del comune (formato testo).

### Esempio di dati

```csv
eu_es,ordinanza_attuale,oc_os,regione,prov,comune,cup,cup_master_unico,intervento_nome,soggetto_attuatore,importo_programmato,fase_di_avanzamento_al_22_dicembre_2024,url_opencup,pro_com_t
EU_1000,OC_109,OC,MARCHE,MC,Visso,E63H19000300001,,OPERE DI SOSTEGNO SOPRA ABITAZIONI L.GO GREGORIO XIII,Comune di Visso,827160.0,FA_7 - Inizio lavori,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/E63H19000300001,043057
EU_1001,OC_109,OC,MARCHE,MC,Visso,E63H19000280001,,VIA USSITA - CADUTA MASSI,Comune di Visso,1100000.0,FA_7 - Inizio Lavori,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/E63H19000280001,043057
EU_1002,OC_109,OC,MARCHE,MC,Visso,E63H19000290001,,S.P. 209 - CADUTA MASSI,Comune di Visso,1250000.0,FA_3 - Incarico di progettazione affidato,https://www.opencup.gov.it/portale/it/web/opencup/home/progetto/-/cup/E63H19000290001,043057
```
