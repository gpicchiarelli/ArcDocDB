# Composizione dei tag CBOR — seconda lettura C1

Lettura statica del responsabile del corpus cieco il 2026-10-14, dopo il
freeze dei test e la successiva scrittura del prodotto, prima della prima
compilazione, load o campagna. L'autore è distinto dall'autore del prodotto
e non ha consultato la nuova prima lettura C1. Il
[metodo preregistrato](cbor-tag-metodo.md) ha blob
`3175390e496173398781bf8b39170cb33892125f`, ramo `codex/cbor-tag-write`.
Prodotto e corpus congelati non sono stati modificati da questa lettura.

| Prodotto esaminato | Blob Git |
|---|---|
| src/codec/cbor-tag-input.lisp | 6dfad07035ac8040b2aec0a455c175ea15dfd9ad |
| src/codec/cbor-tag-write.lisp | 16b91fc27eabafd7ff12bfb0a56ed34208c2bd4b |

Nessun difetto funzionale o rilievo statico aperto individuato nei due blob.
Compilazione rigorosa, lint, risultati del corpus, heap, intervalli paralleli,
copertura e mutazioni restano pendenti. Questa lettura non chiude un gate C1,
non attesta MC/DC e non qualifica il motore. Il catalogo requisiti aggiornato
è stato letto; la rigenerazione della matrice resta attività d'integrazione
del coordinatore prima di `trace`.

## Checklist C1

| Punto | Riscontro statico e limite |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-007, LIM-001/002, AFF-004/008, INV-A5/A8/P6 e ADR-0014/0024/0033/0035/0048 sono coerenti con una primitiva locale MT6 strutturale minima. Tutti i numeri wire u64 in due parole sono ammessi; tag applicativi, sentinelle documentali e determinismo semantico restano al profilo superiore. |
| 2. Invarianti | Preflight protegge tipi, range, contenuto non vuoto, parole, scratch/alias, limiti, dimensione completa, capacità, overlap e minimo due nodi. Scansione completa prima della testata; guardie attive confrontano dimensioni, nodi, picco e progresso effettivi. |
| 3. Errori | Le dieci fasi del metodo mantengono l'ordine. IA/RE del preflight hanno offset NIL; scanner propaga errori typed e offset assoluti SOURCE. Ogni errore pubblico precede la scrittura e conserva gli interi array. Preflight conserva lo scratch; parser può sporcarlo, poi riusabile. Invarianti interni fail-stop senza rollback. |
| 4. Limiti | Nessun ciclo, ricorsione, attesa o retry nuovo. SPAN<=16MiB prima della somma; scanner riceve SPAN, MAX-NODES−1 e MAX-DEPTH invariato. Stack/reset/drain preesistenti102; tags senza frame, copia<=SPAN e testata<=9byte. |
| 5. Heap | Variabili locali e valori multipli, senza AST, closure o array temporanei nel nuovo successo. Limiti su SBCL64 mantengono somme fixnum; nessun u64 ricomposto. Keyword call e dipendenze richiedono benchmark con baseline nulla e controllo positivo; heap zero non attestato staticamente. |
| 6. Dati verificati | MT6 e parole HIGH/LOW originarie, selezione minima preesistente e byte di un singolo item minimo completo. Solo [START,NEXT) cambia. Progresso header, span payload e NEXT finale verificati; ultimo risultato è una variabile, un solo valore. |
| 7. Decisioni composte | Cinque AND/OR con11 operandi, due confronti numerici concatenati con4 relazioni e23 guardie/error forms. Inventario completo e coppie sotto e nella [tabella](cbor-tag-decisioni.md). Nessun sito escluso, neppure interno o dichiarazione; indipendenza dinamica non attestata. |
| 8. Proprietario | OWNER/SHARED dichiarano BUFFER/SPACE esclusivi e SOURCE stabile condivisibile read-only. Simple u8 escludono displaced/backing condivisi. BUFFER/SOURCE EQ KINDS rifiutati; REMAINING è simple u32 e non può essere un argomento simple u8 valido. BUFFER=SOURCE ammesso solo se disgiunto dal footprint completo, testata inclusa. |
| 9. Integrazione | Export cbor-package:12; ASDF prodotto:35 dopo scanner/header/copia, tre file corpus:164–165 dopo i vecchi supporti, RUN:234. Coverage dedicato seleziona esattamente i due sorgenti e RUN tag; aggregato codec:295 include RUN tag. Self-test contiene due positivi e quattro negativi di scope. Catalogo REQ-CBR-007 senza :cov; matrice da rigenerare. Nessun make check eseguito da questa lettura. |
| 10. Standard | Safety3, FTYPE completi con arità esatta, REQ, docstring Pre/Post/errori, tipi specializzati e almeno due controlli significativi per ogni funzione. Sei funzioni di9–33 righe e4–8 percorsi nella convenzione dichiarata: entro60/10. Nessuna deviazione proposta; warning/style-warning/lint restano da osservare. |
| 11. Parallelismo | Nessuna attesa, thread, lock o scrittura condivisa nuova nel prodotto. Corpus con due worker riusati, SOURCE read-only, buffer/scratch privati, due ondate, sink, timeout e cleanup. Durate e overlap devono essere osservati; nessuna inferenza di scaling o simultaneità sui core. |
| 12. Durabilità | Solo memoria del chiamante, nessun I/O o pubblicazione durevole/atomica. Il codec non cambia la Serie: FAULTED per invarianti interni resta responsabilità del confine proprietario. |

## Preflight, parole e dimensioni

`check-input-tag-cbor` esegue range BUFFER, range SOURCE, span vuoto,
parole HIGH/LOW, SPACE e alias, limiti byte/nodi/profondità, budget byte
SPAN poi dimensione completa, capacità, overlap completo e minimo due
nodi, prima di reset o lettura del contenuto. Il validator delle testate
preesistente ricontrolla il range già valido e MT6 costante prima di
HIGH e LOW; non controlla la capacità, che resta nella fase prevista.
L'offset omesso è NIL per il costruttore preesistente della condizione.

`dimensioni-tag-cbor` controlla SPAN>0 e SPAN<=MAX-BYTES<=16MiB prima
della selezione MT6 e della somma. `seleziona-header-cbor` usa HIGH/LOW
separati:1/2/3/5byte se HIGH0,9byte se HIGH nonzero. ITEM-SIZE massimo
prima del controllo byte è16MiB+9, entro fixnum/index su SBCL64.
La capacità è confrontata con END−START prima di NEXT=START+ITEM-SIZE:
NEXT<=END rende sicura la somma nel dominio index anche con START alto.
Il corpus verifica capacità dichiarata contro la lunghezza fisica con
sentinelle e budget completo16MiB per entrambe le testate1/9byte.

Gli accessi agli slot SPACE seguono il controllo del suo tipo. Gli alias
BUFFER/SOURCE EQ KINDS vengono rifiutati prima dei limiti o reset.
`REMAINING` specializzato u32 non è un simple u8 valido; array displaced
sono già esclusi dal validator dei range. SOURCE non vuoto è verificato
prima degli alias, come richiesto dalla precedenza del metodo.

Overlap confronta SOURCE con [START,NEXT), non con l'intero [START,END).
Disuguaglianze strette ammettono i due confini toccanti. Con MT6 da9byte,
SOURCE=[16,17), START8/NEXT18 interseca soltanto la testata: deve essere
rifiutato anche se la copia payload [17,18) sarebbe disgiunta. Il corpus
contiene questo caso, START6/NEXT16 e START17/NEXT27 accettati. Su
successo BUFFER=SOURCE preserva lo span sorgente disgiunto e modifica il
solo footprint; sugli errori pubblici conserva l'intero array fisico.

## Scansione, residuo nodi e statistiche

MAX-NODES deve essere almeno2 prima di entrare nello scanner: un nodo tag
radice piu almeno un nodo di contenuto. Il residuo esatto è MAX-NODES−1;
non esistono aggregati o cicli su piu item. MAX-DEPTH passa invariato,
perché MT6 non è un contenitore array/map. La scansione chiede un solo
item minimo esatto; trailing, tag senza contenuto, UTF8 e rappresentazioni
non minime mantengono i motivi e gli offset assoluti del parser.

Tag su scalare o catena tag è ammesso a profondità0. La fixture1024 tag
sorgente piu scalare ha1025 nodi e picco0; il budget completo minimo è1026.
Con1025 la scansione fallisce sullo scalare a SOURCE-START+1024. Non si
consuma un frame per ciascun tag. Il contenuto con100 array annidati passa
MAX-DEPTH100 e102 nodi completi; con101 fallisce a SOURCE-START+100.

Si controllano NEXT=END,1<=NODES<=MAX-NODES−1 e PEAK<=MAX-DEPTH prima
di scrivere. Lo scratch rimane quello dello scanner: conta il contenuto,
non il tag emesso, e al successo cursor=SOURCE-END, top/depth0,
pending-tag NIL. Il parser fallito può averlo modificato; ogni nuova
scansione lo resetta. I rifiuti di preflight non lo resettano.

La prima scrittura è dentro `scrivi-header-cbor-minimo`, dopo tutta la
scansione. Seguono guardie su progresso della testata e span payload,
copia preesistente con precondizioni già dimostrate e NEXT finale.
Le guardie dopo la prima scrittura segnalano invarianti interni senza
rollback; non sono nuovi rifiuti pubblici ammessi dal contratto.
Lavoro bounded O(SPAN*102); nessun AST o interpretazione dei tag.

## Righe, percorsi e inventario

Conteggio DEFUN dalla prima alla parentesi finale inclusa, comprese
docstring/dichiarazioni. Percorsi: base1 piu WHEN/UNLESS e ciascun
operando AND/OR oltre il primo. Nessun LOOP/IF/COND/CASE nuovo.
Le relazioni concatenate hanno inventario distinto e non sono
sommate al conteggio sintattico dei percorsi. Non è MC/DC o il conteggio
dei branch strumentati.

| Funzione | File/righe inclusive | Righe | Percorsi | Guardie |
|---|---|---:|---:|---:|
| check-spazio-tag-cbor | input:9–17 |9|4|2|
| dimensioni-tag-cbor | input:22–40 |19|6|5|
| check-overlap-tag-cbor | input:45–55 |11|8|3|
| check-input-tag-cbor | input:60–83 |24|5|4|
| verifica-contenuto-tag-cbor | write:10–30 |21|8|6|
| scrivi-tag-cbor-minimo | write:36–68 |33|4|3|

`input` è [cbor-tag-input.lisp](../../src/codec/cbor-tag-input.lisp),
`write` è [cbor-tag-write.lisp](../../src/codec/cbor-tag-write.lisp).
AND/OR input:15/49/51/53 e write:15. Confronti concatenati write:19/26.
Guardie input14+write9=23, ciascuna con una forma ERROR. Sono controlli
attivi fra dati, dimensioni, risultati e limiti, non costanti TRUE.
Ogni funzione ha almeno due controlli significativi oltre i soli FTYPE.
False guardie interne impedite dal preflight o da callee corretti restano
nel denominatore; le coppie statiche non ne dichiarano l'esecuzione.

Il lettore C4 `review/read-product-decisions.lisp`, conservato nel supporto
ignored dell'incremento, legge le forme come DATA con READ-EVAL NIL ed EOF,
senza LOAD/EVAL/COMPILE del prodotto. Conferma6 funzioni,23guardie/ERROR,
5AND/OR11operandi,2catene/4relazioni,0cicli e percorsi4/6/8/5/8/4;
stdout preservato, stderr vuoto. La dimensione in righe è conteggio manuale.

## Corpus congelato e integrazione

| File cieco | Blob Git |
|---|---|
| tests/codec/cbor-tag-write-support.lisp |15978d05251705387205d6468031a701ad95ec85|
| tests/codec/cbor-tag-write.lisp |df97950ec8d24157bb6566c7995262f7beea7742|
| tests/codec/cbor-tag-write-threads.lisp |def870295400af2c84ca00e7a9b5cd5b747ec315|

Pins immutati. Piano freddo blob `71f0cbd4f4b9e2c180c2fe4dde208fa8d88a6787`:
20 nominali,442 chiamate non fuzz (144 accettate/298 rifiutate), fuzz1024
(512/512), due worker riusati8192. Totale9658 chiamate alla nuova API,
8848 successi previsti/810 rifiuti, piu116 scanner secondari con scratch
distinti. Seme54414737, finaleF8004B37 ricomputato separatamente; non
sono risultati PASS. Frontiere parole/testate, precedenze, tipi, source
vuoto, alias, capacità/budget completo, overlap, parser, nodi, depth,
stats, arità, sentinelle e riuso sono coerenti col contratto letto.

Parallelo: due ondate x2048 chiamate per ciascuno dei due worker reali,
SOURCE comune read-only e scratch/destinazioni privati. NEXT13/17,
token32601/47515, sink66766848/97310720 per worker/ondata, check byte
fisici completi e statistiche contenuto6/2. Attesa15s, join20s, cleanup
limitato con cessazione verificata. Overlap positivo atteso viene misurato;
nessuna conclusione di scaling. Timestamp individuali non stampati.

Integrazione letta: package `f20d93e9a0cd5cc5387a12d1668968e07cf30d89`,
ASDF `805550e9053aef5671d28a6fdda62c8eee0ab2e2`, coverage
`8e32ee2ba7b758eb5b0cea349ab8b3d53bd9f2c8`. Scope esatto tag input/write,
due positivi/quattro negativi nel self-test, RUN dedicato e aggregato codec.

Dipendenze lette: header writer `61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`,
range/copia `a2c5c77dd51bff760bff4508e998d94370921eda`, limiti
`57ffc48cc688a4de8ebec5cb14c1e69c4209704a`, scanner
`e3d7d77407046338d23e26eb0b8a2e8fdc3d699d`, wrapper minimo
`f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6`, spazio
`a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`.

Rimangono compile senza warning/style-warning, lint, self-test/campagne
con sorgenti/indice/HEAD stabili, heap, copertura completa senza esclusioni,
mutazioni, letture distinte dei dati e make check integrato. Nessuna di
queste attività è stata eseguita da questa lettura statica.
