# Introduzione

Questo è un dataset di dati pubblicati nel contesto del progetto "[**Liberiamoli tutti!**](https://datibenecomune.substack.com/about)", e in particolare [nel "**numero 4**"](https://datibenecomune.substack.com/p/d3045d80-1379-4221-a78e-2aab12a6817e) della newsletter di progetto.

## Dati

Si tratta dell'elenco complessivo dei beneficiari del cinque per mille (5x1000) 2022.

La fonte dei dati è [questa pagina](https://www.agenziaentrate.gov.it/portale/elenco-complessivo-degli-enti-ammessi-in-una-o-piu-categorie-di-beneficiari) del sito dell'Agenzia delle Entrate.

Il file è [`cinque_per_mille.csv`](https://raw.githubusercontent.com/ondata/liberiamoli-tutti/main/cinque_per_mille/dati/cinque_per_mille.csv), ed è composto dalle colonne descritte a seguire.

| Nome colonna | Tipologia colonna | Descrizione colonna |
| --- | --- | --- |
| prog | integer | Numero progressivo dell'ente beneficiario nella lista |
| codice_fiscale | string | Codice fiscale dell'ente beneficiario, utilizzato per identificarlo univocamente |
| denominazione | string | Nome ufficiale dell'ente beneficiario, come riconosciuto dalla legge italiana |
| regione | string | Regione italiana in cui l'ente beneficiario ha la sua sede principale |
| pr | string | Sigla della provincia italiana in cui l'ente beneficiario ha la sua sede principale, indicata tramite la sua sigla ufficiale |
| nome_comune | string | Nome del Comune italiano in cui l'ente beneficiario ha la sua sede principale |
| codice_comune | string | Codice ISTAT che identifica univocamente il Comune italiano in cui l'ente beneficiario ha la sua sede principale |
| ets_e_onlus | string | Indica se l'ente è una Entità Terzo Settore (ETS) o una Organizzazione Non Lucrativa di Utilità Sociale (ONLUS) |
| asd | string | Indica se l'ente è un'Associazione Sportiva Dilettantistica |
| ricerca_scientifica | string | Indica se l'ente si occupa di ricerca scientifica |
| ricerca_sanitaria | string | Indica se l'ente si occupa di ricerca sanitaria |
| comuni | string | Indica se l'ente beneficiario è un Comune italiano |
| beni_culturali_e_paesaggistici | string | Indica se l'ente gestisce beni culturali e/o paesaggistici |
| enti_gestori_aree_protette | string | Indica se l'ente gestisce aree naturali protette |
| numero_scelte | integer | Numero totale di scelte fatte dai contribuenti a favore dell'ente |
| importo_delle_scelte_espresse | number | Totale dell'importo espresso dai contribuenti a favore dell'ente, in euro |
| importo_proporzionale_per_le_scelte_generiche | number | Importo assegnato all'ente in base alle scelte generiche, calcolato proporzionalmente, in euro |
| importo_proporzionale_per_ripartizione_importi_inferiori_a_100 | number | Importo assegnato all'ente dalla ripartizione degli importi inferiori a 100 euro, calcolato proporzionalmente |
| importo_totale_erogabile | number | Somma totale che l'ente può ricevere attraverso il 5 per mille, in euro |
| pagina | integer | Pagina del file PDF da cui è estratta l'informazione |
| file | string | Riferimento al nome del file PDF da cui è estratta l'informazione |
| old_nome_comune | string | Nome comune presente nel file PDF originale. In questo alcuni nomi sono errati. La versione corretta è nel campo 'nome_comune' |

La colonna `Tipologia colonna`, indica il tipo di dato presente nella colonna. I tipi qui sono:

- `number`: Il campo contiene numeri di qualsiasi tipo, compresi i decimali;
- `integer`: Il campo contiene numeri interi;
- `string`: Questo tipo di campo è utilizzato per testo o combinazioni di caratteri. Può contenere lettere, numeri e simboli.

## Note

Questi dati dovrebbero essere pubblicati anche in formati "leggibile meccanicamente", come `CSV` o `JSON`, e non solo in `PDF`. Lo prevedono le norme e linee guida italiane sui dati della Pubblica Amministrazione. Tra questi l'[articolo 6](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art6) del Decreto Legislativo 24 gennaio 2006, n. 36, che rimanda a sua volta all'[articolo 2](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2006-01-24;36!vig~art2), che stabilisce che gli enti pubblici devono utilizzare formati di dati che favoriscano la loro riutilizzazione, che siano appunto in formato leggibile meccanicamente


