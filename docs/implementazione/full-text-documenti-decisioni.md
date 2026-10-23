# Preparazione documentale full text — decisioni e due letture

Perimetro: [preparazione dei documenti](full-text-documenti.md), ADR-0054,
REQ-SEC-003/006/007/010; nessuna modifica al formato o alla decisione durevole.
Due letture dello stesso autore il 16 ottobre 2026, distinte da revisione indipendente,
MC/DC completa e qualifica C1 del motore.

| Decisione composta | Condizioni e prove |
|---|---|
| Configurazione | Vettori semplici, 1…16 campi, ID u64 positivi e field-id u16 ordinati; forma/ordine/duplicati/zero e token oltre u32 rifiutati |
| Alias e percorsi | UTF-8, alias 1…64 byte, percorsi 1…100 con chiavi anche vuote; copia posseduta e test di mutazione delle sorgenti |
| Memoria fredda | Misure prima delle copie, bound META <=64KiB e scratch complessivo; budget minimo e capacita zero rifiutati |
| Limiti u64 | Dichiarati conservati, ID codificati freddi e limiti caldi fixnum; misura con UINT64_MAX senza estrazione ripetuta di raw slot u64 |
| Inizio | Task libero, simple u8, span e row u32, budget positivi; errori/alias/busy non invalidano DONE precedente |
| Scanner | Header minimi e UTF-8 dal kernel comune; root mappa, span esatto, frame e nodi entro limiti; troncamenti, coda, indefiniti e payload ostili rifiutati |
| Maschere | Solo chiavi semplici non tagged, bit per campo e livello del percorso; chiavi complesse/estranee e riuso dei frame non selezionano falsi campi |
| Duplicati | Seen-mask di ciascuna mappa; secondo passaggio su una chiave selezionata rifiutato anche per antenati condivisi |
| Valori | Foglia MT3 e antenato MT5, entrambi senza tag; null, array, bytes, tag e numeri non diventano assenze |
| Campo presente | Input sommato prima di conservare lo span; presenti vuoti hanno LENGTHS, assenti no |
| Analisi/copia | Contatore token sommato e staging entro limite prima della copia; sotto-budget di analisi/run e addebito globale senza underflow |
| Sort e bound | SEALED prima della misura, distinzione campo/termine, ripetizioni contate solo nelle posizioni; attesi manuali e 128 confronti col file |
| Risultato | File bound ammesso e tutti gli stadi conclusi prima di DONE; parziali/falliti/cancellati non accessibili |
| Cleanup | Input e prestiti analitici rilasciati, run invalidato; cancellazione idempotente in sette fasi e riuso dopo rifiuto |
| Parallelismo | Configurazione condivisa readonly, task per worker; quattro task con binding privato e rendezvous limitato |

## Lettura 1: dati e costi

Riletti scanner e selettore contro le transizioni del kernel CBOR: la parita del
numero di figli distingue chiave/valore, i tag non consumano prematuramente la coppia,
un nuovo frame azzera tutte le maschere. Gli span sono relativi all'inizio del documento,
entro 16 MiB, anche quando il buffer ha un prefisso. Solo gli span delle foglie testuali
verificate entrano nell'analizzatore. Duplicati e tipi non compatibili sono rifiuti.
Il modulo non certifica ordine/deduplica di mappe estranee o il contratto generale.

Riletti tutti i budget: memoria prima delle copie, cinque limiti dichiarati e limiti
effettivi senza boxing caldo, token e staging cumulativi fra campi, lavoro comprensivo
dei confronti di byte e del sort. Il bound usa una sola entry dizionario/posting per
coppia campo/termine nel documento e una posizione per ogni occorrenza. META usa un
limite conservativo che ammette i futuri metadati fisici massimi senza conoscerli.

## Lettura 2: ownership e integrazione

Riletti input immutabile preso in prestito, configurazione copiata e run del task.
Nessun dato parziale pubblico; il riuso invalida il prestito del risultato precedente.
Il completamento rilascia l'input, ma il writer dovra ancora legare la preparazione
agli esatti byte del PUT e copiare/trasferire il run nelle proprie riserve prima
di rilasciare lo scratch del worker. Non esiste qui un percorso di commit autorizzato.

Nessun lock, I/O, schedulatore o contatore globale per operazione. Il kernel CBOR
puo verificare una stringa intera in un passo: quantum e contatori non sono deadline
realtime. Scadenza del task, fault injection dei confini del worker, riserve prima
della decisione, pubblicazione prima di H/ACK e MVCC restano da integrare/qualificare.
Le misure di heap sono separate dalla copertura; due mutanti non dimostrano una
campagna esaustiva o MC/DC completa. INV-I4/INV-I6 restano aperti nel loro insieme.
