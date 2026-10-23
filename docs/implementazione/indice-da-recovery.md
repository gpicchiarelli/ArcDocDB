# Materializzazione dell'indice dal recovery

Collega il [selettore di versioni](selezione-versioni-recovery.md) al
[primary index](indice-primario.md), senza modificare ADR-0015, ADR-0042,
ADR-0048 o il formato dello slot. Requisiti REQ-REC-001, REQ-IDX-001,
REQ-IDX-003, REQ-IDX-005, REQ-IDX-006, REQ-LIM-003, REQ-AFF-004,
REQ-AFF-008; invarianti INV-D1, INV-C11 e INV-I2.

## Una chiave completa, poi una voce

```lisp
(arcdocdb.recovery.selection:materializza-chiave-recuperata
 selector primary context source)
;; => :inserted | :present | :absent
```

Il coordinatore deve aver considerato **tutti** i candidati committed
della chiave nella stessa Serie. Il primary è un candidato privato di
bootstrap, con ammissione e reader applicativi ancora chiusi. Il writer
mantiene l'esclusività su indice, selettore, contesto e scratch per tutta
la chiamata. `source` è un buffer preallocato di cinque u64, distinto
dallo scratch del `contesto-indice`. Nessun array nuovo per la chiave.

La funzione usa la chiave privata del selettore e il seme immutabile
dell'indice: non accetta un digest esterno e non conserva un riferimento
al buffer originario. Il selettore ambiguo è rifiutato. Un contesto occupato,
un alias o il seme assente sono rifiutati prima di scrivere lo scratch.

| Vincitore del selettore | Effetto nel candidato primario |
|---|---|
| PUT, chiave assente | Inserimento tramite preflight e writer canonici |
| PUT, stessa voce già presente | `:present`, nessuna nuova mutazione |
| PUT, voce presente diversa | Rifiuto, nessuna sovrascrittura |
| TOMBSTONE o nessun candidato, chiave assente | `:absent`, nessuna entry |
| TOMBSTONE o nessun candidato, voce presente | Rifiuto, nessuna rimozione |

Il tombstone rimane nel selettore fino al termine della chiave e non
entra nell'indice dei vivi, secondo ADR-0042. Il primario non riceve
versioni provvisorie da correggere successivamente. Se contiene già
una voce diversa, non è il candidato atteso per questa materializzazione:
il coordinatore deve risolvere il problema prima dell'ammissione.

Il raggruppamento e la completezza delle chiavi sono ancora responsabilità
del coordinatore. Reset e consegna anticipati possono violare quelle
precondizioni: questa funzione non attesta il replay dell'intera Serie
o dell'Archivio.

## Payload e compatibilità

Per PUT si preparano CSN effettivo, location, lunghezza della chiave,
lunghezza del record e fine-validità zero. L'offset dell'arena è
ricostruito dal writer canonico. Per TOMBSTONE/NONE il buffer viene
azzerato e il primary riceve NIL, che significa **assenza attesa**.
Lo scratch non è una prova di commit e non deve essere pubblicato da solo.

Prima di scriverlo, il ponte verifica i vincoli del destinatario attuale:
CSN positivo, ID segmento positivo rappresentabile in u32, offset e fine
record entro u32. Un vincitore non rappresentabile è rifiutato, mai
troncato. Il selettore e i reader conservano ID/CSN u64, incluso zero;
questo incremento non ne restringe il contratto né amplia il formato
del primary/GET. Un tombstone, che non produce entry, non richiede una
location rappresentabile nel primary.

Formato e flag del record restano responsabilità delle fonti GET.
La materializzazione di un PUT prepared conserva il CSN già risolto;
non elimina la necessità delle prove OUTCOME/EDIT/DECISION e non
costruisce o pubblica le mappe GET.

## Ripristino canonico nel primary

`arcdocdb.index.primary:ripristina-chiave-indice` riceve indice, span
chiave, digest fidato, source viva oppure NIL e contesto esclusivo.
È l'ingresso in memoria a uso del bootstrap; il writer in esercizio
continua a usare il normale protocollo transazionale.

Un probe writer completo verifica la presenza, con al massimo C slot
del frammento. Una source viva già presente deve coincidere per CSN,
location, lunghezza record, fine-validità e lunghezza chiave: soltanto
l'offset dell'arena è ignorato, perché può cambiare con rebuild/split.
Questo confronto non è una verifica del body: il record e la sua
immutabilità devono essere già attestati dal recovery.

In caso di nuova voce si usa il normale preflight, che ripete il probe,
controlla carico, arena, crediti e revisione, quindi applica la normale
pubblicazione dello slot. Il secondo probe deve confermare l'assenza
sotto lo stesso writer. La rilettura finale verifica stato LIVE e
identità del payload. Il nuovo inserimento costa al massimo due probe;
assenza e voce identica ne costano uno. Nessun retry illimitato o
fallback al reader con otto crediti.

La ripetizione di un ripristino già riuscito restituisce `:present` o
`:absent` senza consumare nuova revisione, sequenza, arena o capacità.
Una root diversa dopo manutenzione viene risolta nuovamente, senza
conservare uno slot o l'offset dell'arena fra chiamate.

## Errori, concorrenza e confini

Input, compatibilità o capacità insufficienti sono rifiutati prima
della mutazione dell'indice. Lo scratch privato può cambiare; dopo
RESOURCE-EXHAUSTED il coordinatore può completare rebuild/split o
ampliamento dell'arena e ripetere la stessa chiave. Nessuna crescita
automatica, soglia nuova o limite totale dei documenti è introdotto.

Un'invariante del primary lo rende FAULTED prima della propagazione
della causa originale; il ponte rende FAULTED anche il selettore.
Il contesto viene liberato in ogni uscita. Le interruzioni della
mutazione seguono il fail-stop del writer canonico, senza rollback.
La costruzione privata non deve essere confusa con pubblicazione
della root applicativa, durata EBR o apertura del traffico.

Sono operazioni a freddo, serializzate dal writer della singola Serie;
Serie indipendenti non condividono nuovi lock, registri o scritture.
Il ponte riusa i cinque u64 del chiamante e lo scratch esistente;
non conserva nuovi oggetti per documento e non esegue I/O. Non sono
misure di allocazioni, GC, RSS, throughput o latenza.

## Decisioni e qualifica aperta

| ID | Decisione da qualificare | Stato |
|---|---|---|
| IMR-D01 | Contesto libero, source valida, lunghezza chiave e alias | Aperta |
| IMR-D02 | Probe trovato, posto esaurito e assenza valida anche a tabella piena | Aperta |
| IMR-D03 | Voce identica / diversa; NIL come assenza, mai cancellazione | Aperta |
| IMR-D04 | Secondo probe, budget canonici e rilettura finale | Aperta |
| IMR-D05 | Selettore vuoto, PUT, TOMBSTONE o ambiguo | Aperta |
| IMR-D06 | CSN/ID/offset compatibili prima dello scratch | Aperta |
| IMR-D07 | Payload valido, azzeramento non PUT e seme dell'indice | Aperta |
| IMR-D08 | Invarianti, fail-stop e rilascio del contesto | Aperta |

[Metodo preregistrato e risultati locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-index-materialization/README.md).
Test funzionali dedicati, permutazioni, fault injection, MC/DC, copertura,
revisione indipendente e misure di prestazione restano aperti. Restano
anche il replay completo per chiave, le fonti GET, la pubblicazione delle
radici e il gate del coordinatore. I controlli statici non chiudono questi
obblighi né la qualifica C1.
