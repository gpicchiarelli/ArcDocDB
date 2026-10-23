# Composizione degli array CBOR — seconda lettura C1

Lettura statica del responsabile del corpus cieco, il 2026-10-13,
dopo il freeze dei test e la successiva scrittura del prodotto, prima
di compilazione, load o campagne. Il [metodo preregistrato](cbor-array-metodo.md)
ha blob `2f257c9e8a56a5182142934dada3f3b38b5bef65`; base comunicata
`13983d3`, ramo `codex/cbor-array-write`. Questa lettura e indipendente
dall'autore del prodotto e non ha consultato la prima lettura o il nuovo
inventario. Non modifica il prodotto o il corpus congelato.

| Prodotto esaminato | Blob Git |
| --- | --- |
| `src/codec/cbor-array-input.lisp` | `d3b3d07fc18bd2a077c1a2d79020a76263b2779e` |
| `src/codec/cbor-array-write.lisp` | `a410297c29c5d043ad60d3804bd3711e22c2833b` |

Nessun difetto funzionale o rilievo statico aperto individuato nei blob
esaminati. Build rigorosa, lint, risultati del corpus, heap, intervalli
paralleli, copertura e mutazioni restano pendenti. Questa lettura non
chiude un gate C1, non attesta MC/DC e non qualifica il motore.

## Checklist C1

| Punto | Riscontro statico e limite della lettura |
| --- | --- |
| 1. Requisiti e ADR | REQ-CBR-005 da ADR-0014, LIM-001/002, AFF-004/008, INV-F1/P6/A8 e ADR-0033/0035/0048 sono coerenti con un composer locale di item wire minimi. Non introduce semantica tag, ordinamento/deduplica mappe o normalizzazione NaN. |
| 2. Invarianti | Tipi e span, partizione relativa, budget completi, separazione dello scratch e footprint disgiunto precedono la scansione. Tutti i figli vengono verificati prima della testata. Le guardie controllano anche estremi, progresso, residui, statistiche e copia finale; il corpus confronta gli array fisici completi. |
| 3. Errori | I passi del metodo sono rispettati nell'ordine. Preflight produce INVALID-ARGUMENT o RESOURCE-EXHAUSTED con offset NIL; initform in conditions:8. Residuo nodi0 produce :cbor-array-node-budget all'inizio assoluto del prossimo figlio; il resto degli errori scanner viene propagato senza traduzione. Tutti i rifiuti pubblici precedono la prima scrittura. INVARIANT-VIOLATION interno richiede fail-stop del proprietario, senza rollback. |
| 4. Limiti | I due LOOP nuovi leggono al piu COUNT entry, con COUNT<=SPAN<=16MiB verificato. Ogni scanner riceve il proprio span come budget byte e il residuo dei nodi; reset/drain sono limitati a102 frame. Copia preesistente limitata a SPAN, header al piu5byte. Nessuna ricorsione, attesa, retry o creazione di worker nel prodotto. |
| 5. Heap | Nuovo successo con valori multipli, cursori e chiamate dirette, senza costruttori, closure, AST o array temporanei. Su SBCL64, valori index/u32 e somme limitate restano immediati. Chiamate keyword, scanner e copia richiedono comunque benchmark seriale con baseline nulla e sensore positivo; heap zero non e attestato staticamente. |
| 6. Dati verificati | Il risultato e MT4 minimo, COUNT in HIGH0/LOW, seguito dal payload gia verificato e copiato esattamente. Solo [START,NEXT) viene scritto. Progresso della testata, uguaglianza delle lunghezze e NEXT finale sono controllati; la variabile finale restituisce un solo valore. |
| 7. Decisioni composte | Cinque AND/OR e due LOOP nei nuovi file, elencati sotto. Relazioni concatenate, guardie interne e rami d'errore restano espliciti: nessuna esclusione dal denominatore, nessuna attestazione di indipendenza dinamica delle condizioni. |
| 8. Proprietario | OWNER/SHARED dichiarano destinazione e scratch esclusivi, SOURCE e ITEM-ENDS stabili condivisibili in lettura. Simple array escludono backing displaced. Gli alias dello scratch sono rifiutati anche vuoti; BUFFER=SOURCE e ammesso solo con span sorgente disgiunto dal footprint completo, testata inclusa. |
| 9. Integrazione | Export cbor-package:12; ASDF seriale carica i due nuovi file dopo scanner/header/copia, i tre test dopo i supporti precedenti e RUN:208. Coverage seleziona esattamente i due sorgenti, con positivi/negativi di suffisso e dispatch dedicato. Catalogo e matrice includono REQ-CBR-005 senza :cov; make check non e stato eseguito in questa lettura. |
| 10. Standard | Safety3, FTYPE completi, tipi array, docstring Pre/Post/errori, REQ e guardie attive presenti. Dieci funzioni di9–36 righe e3–8 percorsi secondo il conteggio sotto, entro60/10. Nessuna deviazione proposta. Assenza di warning/style-warning e lint devono essere osservati successivamente. |
| 11. Parallelismo | Nessun lock, attesa o scrittura condivisa tra Serie sul percorso del prodotto. Il corpus riusa due worker, destinazioni e scratch privati e input comuni immutabili, con semafori distinti per ciascuna delle due ondate. Sink, timeout, join, cleanup e sovrapposizione devono essere osservati; non dimostrano scaling o simultaneita sui core. |
| 12. Durabilita | Solo mutazione della memoria esclusiva del chiamante; nessun I/O, commit, eliminazione o pubblicazione durevole/atomica. Il codec non esegue transizioni della Serie: FAULTED e il fail-stop degli errori interni restano al confine proprietario. |

## Preflight, budget e preservazione

`check-input-array-cbor` (input:116–126) compone: range destinazione,
range sorgente, tipo tabella/COUNT, tipo spazio/alias, limiti configurati,
SPAN e dimensione completa contro byte, capacita, overlap, entry,
minimo nodi e livello radice. LENGTH e aritmetica sui dati esterni sono
protetti dai controlli di tipo. Non viene fatto alcun reset o write.

SPAN e controllato prima della somma e del cast COUNT a u32 (input:44–48):
COUNT<=SPAN e MAX-BYTES<=16MiB rendono sicuri il cast e la testata1/2/3/5.
ITEM-SIZE include la testata; capacita END−START e verificata prima di
NEXT=START+ITEM-SIZE. NEXT<=END evita overflow index. Fini relative
non vuote, crescenti, <=SPAN e ultima=SPAN limitano ogni STOP assoluto
a SOURCE-END; solo le prime COUNT celle sono lette (input:86–92).

L'overlap usa [START,NEXT), non l'intero intervallo fino a END
(input:67–69). Disuguaglianze strette ammettono confini toccanti;
il test SOURCE-START<SOURCE-END ammette il vuoto. Con BUFFER=SOURCE,
il successo modifica il solo footprint destinazione e conserva lo span
sorgente disgiunto. Sugli errori pubblici tutti gli array fisici restano
intatti. Lo scratch intatto nel preflight e garantito anche dagli alias
di KINDS e REMAINING rifiutati prima di ogni scanner.

La radice richiede1 nodo e1 livello (input:101–104). Il ciclo figli
inizia NODES=1, PEAK=1, CHILD-DEPTH=MAX-DEPTH−1 (write:50). Ogni figlio
usa MAX-NODES−NODES e poi aggiunge i propri nodi, inclusi tag; il picco
e MAX(PEAK,1+CHILD-PEAK). Residuo1 e passato allo scanner, residuo0
e rifiutato prima del suo reset (write:17–25). Per 8100/00, budget3
esaurisce il residuo al secondo figlio, budget4 accetta. Figlio con99
container aggiunge la radice e raggiunge100; figlio con100 viene
rifiutato con il limite figlio99. COUNT0 non chiama alcuno scanner.
Lo scratch descrive quindi l'ultimo figlio, non gli aggregati locali.

Solo dopo la scansione completa e le guardie delle statistiche il writer
chiama l'header MT4 e la copia preesistenti (write:90–104). Il primo write
e nel writer della testata, dopo tutto il parsing; la copia ha soltanto
errori interni. Le guardie successive al write non promettono rollback.
Nessun byte non verificato viene esposto come risultato riuscito.

## Guardie significative e dimensione

Le guardie non ripetono soltanto il dominio dichiarato: tipo tabella e
COUNT/partizione; tipo spazio e separazione fisica; byte e capacita;
range interni e disgiunzione; bounds/budget del loop e fini; minimo nodi
e profondita radice; span/capacita restituiti dal preflight; figlio non
vuoto, progresso e statistiche; convergenza degli aggregati; header,
payload e copia finale. I confronti di progresso e bilancio verificano
relazioni tra ingressi e risultati, non costanti TRUE. Ogni funzione
non banale mantiene almeno due controlli attivi; gli errori interni
propagano invariant-violation al proprietario.

La versione letta separa `COUNT<=LENGTH(ITEM-ENDS)` da `COUNT<=16MiB`
(write:46–49): il prefisso attivo e limitato, la coda ignorata della
tabella puo essere piu lunga del budget. Non pretende che l'intera
lunghezza fisica della tabella sia <=16MiB. Il coordinatore ha dichiarato
la correzione e la conservazione dell'originale prima di ogni compile;
questa lettura riguarda soltanto il blob finale sopra. I due bounds
non sono implicati dal solo tipo u32. Guardie non falsificabili attraverso
il contratto pubblico restano da inventariare e misurare, senza esclusioni.

Conteggio sintattico:1 iniziale,1 per IF/WHEN/UNLESS o LOOP, piu1 per
ogni operando AND/OR dopo il primo. Non conta come rami aggiuntivi le
relazioni concatenate; sono comunque riportate per la copertura.
Controllato su forme READ-EVAL NIL/EOF, senza valutarle (chunk c4e979).

| Funzione | File e righe inclusive | Righe | Percorsi |
| --- | --- | ---: | ---: |
| check-tabella-array-cbor | input:9–19 | 11 | 7 |
| check-spazio-array-cbor | input:24–34 | 11 | 5 |
| dimensioni-array-cbor | input:39–54 | 16 | 4 |
| check-overlap-array-cbor | input:59–70 | 12 | 7 |
| check-fini-array-cbor | input:75–93 | 19 | 7 |
| check-radice-array-cbor | input:97–105 | 9 | 3 |
| check-input-array-cbor | input:110–131 | 22 | 3 |
| verifica-figlio-array-cbor | write:10–32 | 23 | 7 |
| verifica-figli-array-cbor | write:38–64 | 27 | 8 |
| scrivi-array-cbor-minimo | write:70–105 | 36 | 6 |

`input` e [cbor-array-input.lisp](../../src/codec/cbor-array-input.lisp),
`write` e [cbor-array-write.lisp](../../src/codec/cbor-array-write.lisp).
AND/OR: input:15 (COUNT index, table length, SPAN),17 (COUNT0 e SPAN>0),
30–32 (tre alias scratch),67–68 (EQ, sorgente non vuota e intersezione
stretta),88 (crescita e bound STOP). LOOP input:86 e write:52.
Relazioni concatenate: input:63/65/82; write:15/28/44/60/62. Tutte le
guardie, anche postcondizioni interne, fanno parte della lettura.

## Riesame del corpus congelato

| File cieco | Blob Git |
| --- | --- |
| tests/codec/cbor-array-write-support.lisp | eb1fccadb205e375b4a2324a6b6725a860bb546f |
| tests/codec/cbor-array-write.lisp | b13f58264f3cd97e1947ee52936732a7fcebe672 |
| tests/codec/cbor-array-write-threads.lisp | 5720110265b67019937f08cbd949b4469a04b867 |

Impronte ricontrollate e invariate. Il corpus resta indipendente dalle
formule del nuovo prodotto: testata aritmetica e figli letterali, una
verifica scanner solo aggiuntiva.19 test seriali coprono tipologia,
range, precedenze, budget completo e radice, partizione, overlap,
capacita esatta/meno1, errori assoluti, arita, sentinelle e riuso.
258 chiamate non fuzz previste; fuzz1024 seed41525235 con512 successi
e64 per ciascuna delle otto classi di rifiuto. Sono conteggi statici,
non risultati runtime. Le code non lette sono provate con sentinelle
FFFFFFFF; non si dichiara una prova runtime con tabella oltre16Mi celle.

Il20esimo test riusa2 worker per2 ondate da2048 chiamate ciascuno:
8192 composizioni. READY/GO/DONE distinti per ondata, buffer e scratch
privati, SOURCE/ITEM-ENDS condivisi immutabili. Token freddi25478/36728,
sink per worker/ondata52178944/75218944; interi array e arita verificati
in ogni chiamata. Attesa15s, join20s, cleanup bounded con cessazione
verificata. Totale previsto seriale+parallelo9474 chiamate. Gli intervalli
comprendono confronti del corpus, non soltanto il lavoro della primitiva.

## Integrazione e verifiche pendenti

Blob letti: package `aa15f62ba6e27f46922cbbb9f48d565168e40f49`, ASDF
`266cad8de58c60925a4d4f7078128d6d72406bc5`, coverage
`00700ae049d451a0d8371fba26099c2513e47895`, catalogo
`807b9193ede9191b4dfbeb5e1ea0b81507acb90d`, matrice
`5eadbdeb6b02ce57c8862c3aae0ecc8402b251e6`.
Dipendenze preesistenti lette: copia/stringa `a2c5c77dd51bff760bff4508e998d94370921eda`,
limiti scanner `57ffc48cc688a4de8ebec5cb14c1e69c4209704a`, nucleo scanner
`e3d7d77407046338d23e26eb0b8a2e8fdc3d699d`, wrapper minimo
`f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6`, spazio
`a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`, header writer
`61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`, condizioni
`edbe5eaa88c50dc13af8e367b73f7f41fd7bd724`.

Rimangono necessari compilazione senza warning/style-warning, lint,
campagne registrate con sorgenti/indice/HEAD stabili, self-test dei
driver, benchmark heap, copertura senza esclusioni, mutazioni, letture
distinte dei dati e make check integrato. Nessuna di queste attivita
e stata eseguita da questa lettura statica.
