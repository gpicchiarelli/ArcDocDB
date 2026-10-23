# Decisioni della composizione delle mappe CBOR

Inventario statico del 2026-10-14, prima della prima compilazione e delle campagne.
Fonti congelate: `src/codec/cbor-map-input.lisp`, blob
`d7a593badeb6e6b71f28dc4e80c641b07189d0b8`, e
`src/codec/cbor-map-write.lisp`, blob
`22e814ea68e606c5bc58033c2a31e945303a9d65`.
[Metodo](cbor-map-metodo.md) e [prima lettura C1](cbor-map-revisione.md).

I testimoni indicati sono casi presenti nel corpus congelato o proprietà interne
da confrontare con le prove future: non sono risultati di esecuzione o attestazioni
MC/DC. Tutti i siti, comprese dichiarazioni, guardie interne, forme di errore e
relazioni non raggiungibili dall'API pubblica valida, rimangono nei denominatori
delle future osservazioni grezze. Nessuna esclusione è approvata qui.

## Decisioni AND/OR

**Cinque siti, 14 operandi**, nessuna forma AND/OR annidata. Nel nuovo file write
non sono presenti AND/OR. Le condizioni sono riportate nell'ordine del corto circuito.

| File/riga e funzione | Operatore e condizioni | Testimoni previsti |
|---|---|---|
| input:16, `check-tabella-mappa-cbor` | AND: COUNT INDEX; COUNT<=FLOOR(LENGTH(ITEM-ENDS)/2); COUNT<=FLOOR(SPAN/2) | `table-type-count-domains-and-half-length-before-multiplication`: NIL/negativo/float/simbolo/bignum; tabella troppo corta; SPAN troppo corto con tabella sufficiente; valori validi |
| input:19, `check-tabella-mappa-cbor` | AND: COUNT zero; SPAN positivo | COUNT0/SPAN>0 rifiutato; vuoto valido; COUNT positivo valido |
| input:32–34, `check-spazio-mappa-cbor` | OR: BUFFER EQ SPACE.KINDS; SOURCE EQ SPACE.KINDS; ITEM-ENDS EQ SPACE.REMAINING | `workspace-type-and-all-scratch-aliases-even-empty`: tre ruoli separati, vuoto/non vuoto e caso senza alias |
| input:73–74, `check-overlap-mappa-cbor` | AND: BUFFER EQ SOURCE; SOURCE-START<SOURCE-END; START<SOURCE-END; SOURCE-START<NEXT | `overlap-entire-footprint-touching-and-empty`: array distinti, span vuoto, disgiunto/toccante a sinistra/destra, overlap di header/payload; END ampio con footprint disgiunto |
| input:94, `check-fini-mappa-cbor` | AND: PREVIOUS<STOP; STOP<=SPAN | `strict-active-ends-last-and-unread-even-or-odd-tail`: zero/duplicate/discendenti, fine oltre SPAN, crescita valida e code inattive pari/dispari |

I nomi abbreviati indicano `test-REQ-CBR-006-map-*` in
`tests/codec/cbor-map-write.lisp`, blob
`6ad0e9b5a48ba9c32c46d720f2f7f1821368d6c8`.
La presenza di testimoni per gli operandi non certifica che ogni condizione sia
già stata osservata decisiva indipendentemente.

## Relazioni numeriche concatenate

**Nove predicati con due relazioni ciascuno: 18 relazioni.** Come negli inventari
precedenti del codec, non sono AND/OR scritti nel sorgente e non vengono sommati
al conteggio sintattico dei percorsi. Restano inventariati separatamente per la
lettura condizione per condizione e per interpretare le forme di SB-COVER.

| File/riga | Relazioni ordinate | Proprietà |
|---|---|---|
| input:69 | START<=NEXT; NEXT<=LENGTH(BUFFER) | ordine e limite fisico del footprint |
| input:71 | SOURCE-START<=SOURCE-END; SOURCE-END<=LENGTH(SOURCE) | ordine e limite fisico sorgente |
| input:88 | ITEMS<=SPAN; SPAN<=16MiB | clamp del loop sulle fini e della conversione |
| write:15 | START<=END; END<=LENGTH(SOURCE) | span del singolo item |
| write:28 | 1<=NODES; NODES<=REMAINING | almeno un nodo, budget residuo effettivo |
| write:44 | START<=END; END<=LENGTH(SOURCE) | span complessivo chiavi/valori |
| write:50 | 1<=MAX-DEPTH; MAX-DEPTH<=100 | dominio della radice prima di MAX-DEPTH-1 |
| write:62 | 1+ITEMS<=NODES; NODES<=MAX-NODES | radice e tutti gli item nel budget aggregato |
| write:64 | 1<=PEAK; PEAK<=MAX-DEPTH | livello radice e picco aggregato |

I rifiuti sono invarianti interni, senza escluderli dalle misure. I domini
pubblici vengono verificati prima di entrare nelle funzioni tipizzate; le
postcondizioni confrontano nodi/picco/progresso effettivamente restituiti dai callee.

## Tutte le guardie e i cicli

**40 siti WHEN/UNLESS e due LOOP.** IA=INVALID-ARGUMENT,
RE=RESOURCE-EXHAUSTED, IV=INVARIANT-VIOLATION. Tutti gli offset locali sono NIL,
tranne RE di write:17, che usa START assoluto del prossimo item. Gli errori
propagati dallo scanner mantengono tipo, motivo e offset assoluto SOURCE.

| Funzione | Siti e condizioni → rifiuto |
|---|---|
| `check-tabella-mappa-cbor` | input:14 tipo simple U32 → IA `:cbor-map-item-ends`; input:16 dominio COUNT e due confronti separati con metà tabella/SPAN → IA `:cbor-map-count`; input:19 COUNT0/SPAN positivo → stesso motivo |
| `check-spazio-mappa-cbor` | input:30 SPACE corretto → IA `:cbor-workspace`; input:32 OR dei tre alias → IA `:cbor-map-workspace-alias` |
| `dimensioni-mappa-cbor` | input:46 START<=END → IV `:cbor-map-dimension-range`; input:48 COUNT<=FLOOR(SPAN/2) → IV `:cbor-map-dimension-pairs`; input:50 SPAN>MAX-BYTES e input:56 ITEM-SIZE>MAX-BYTES → RE `:cbor-map-byte-budget`; input:58 ITEM-SIZE>END-START → RE `:cbor-map-capacity` |
| `check-overlap-mappa-cbor` | input:69/71 range → IV `:cbor-map-target-span` / `:cbor-map-source-span`; input:73 overlap del footprint completo → IA `:cbor-map-overlap` |
| `check-fini-mappa-cbor` | input:86 ITEMS<=LENGTH(ITEM-ENDS) → IV `:cbor-map-table-bound`; input:88 ITEMS<=SPAN<=16MiB → IV `:cbor-map-table-budget`; input:94 monotonia/bound → IA `:cbor-map-item-ends`; input:97 ultima fine=SPAN → stesso motivo |
| `check-radice-mappa-cbor` | input:107 ITEMS>MAX-NODES-1 → RE `:cbor-map-node-budget`; input:109 MAX-DEPTH0 → RE `:cbor-map-depth-budget`, in quest'ordine |
| `check-input-mappa-cbor` | input:133 SPAN=SOURCE-END-SOURCE-START → IV `:cbor-map-input-span`; input:135 ITEM-SIZE<=END-START → IV `:cbor-map-input-capacity`; input:137 ITEMS=2*COUNT → IV `:cbor-map-input-pairs` |
| `verifica-figlio-mappa-cbor` | write:15 range → IV `:cbor-map-child-range`; write:17 REMAINING0 → RE `:cbor-map-node-budget` con offset START; write:21 SPAN positivo → IV `:cbor-map-child-empty`; write:26 NEXT=END → IV `:cbor-map-child-progress`; write:28 1<=NODES<=REMAINING → IV `:cbor-map-child-nodes`; write:30 PEAK<=CHILD-DEPTH → IV `:cbor-map-child-depth` |
| `verifica-figli-mappa-cbor` | write:44 range → IV `:cbor-map-children-range`; write:46 ITEMS<=LENGTH(ITEM-ENDS) → IV `:cbor-map-children-bound`; write:48 ITEMS<=16MiB → IV `:cbor-map-children-budget`; write:50 dominio profondità radice → IV `:cbor-map-children-root-depth`; write:60 CURSOR=END → IV `:cbor-map-children-progress`; write:62 nodi aggregati → IV `:cbor-map-children-nodes`; write:64 picco aggregato → IV `:cbor-map-children-depth` |
| `scrivi-mappa-cbor-minima` | write:96 NODES<=MAX-NODES → IV `:cbor-map-result-nodes`; write:98 PEAK<=MAX-DEPTH → IV `:cbor-map-result-depth`; write:102 PAYLOAD-START=BEGIN+HEADER-SIZE → IV `:cbor-map-header-progress`; write:104 NEXT-PAYLOAD-START=SPAN → IV `:cbor-map-payload-span`; write:107 RESULT=NEXT → IV `:cbor-map-write-progress` |

| Ciclo | Limite e progresso |
|---|---|
| input:92, `check-fini-mappa-cbor` | POSITION<ITEMS, ITEMS=2*COUNT<=SPAN<=16MiB; prima entry dopo preflight byte/capacità/overlap; STOP crescente entro SPAN |
| write:54, `verifica-figli-mappa-cbor` | POSITION<ITEMS<=16MiB; fini già validate, STOP assoluto crescente entro SOURCE-END; per item scanner bounded, reset/drain102, nodi residui e MAX-DEPTH-1 |

COUNT viene confrontato con FLOOR delle due lunghezze prima del raddoppio.
SPAN viene verificato contro MAX-BYTES<=16MiB prima di cast u32/somma e dei
loop. Non si limita la coda inattiva della tabella al valore di SPAN. Gli item
sono chiave e valore alternati: l'header riceve COUNT, il loop riceve 2*COUNT.
La destinazione viene scritta soltanto dopo la scansione completa. ITEMS0 non
chiama né resetta lo scanner e restituisce nodi 1/picco 1.

## Righe e percorsi sintattici

Conteggio DEFUN fino alla sua parentesi finale inclusa, comprese docstring e
dichiarazioni. Percorsi: base1 più WHEN/UNLESS, corto circuiti AND/OR aggiuntivi
e LOOP. Nessun IF/COND/CASE nuovo. Le relazioni concatenate sopra hanno il loro
inventario semantico distinto; questo conteggio non sostituisce la copertura grezza.

| File/funzione | Righe | Numero righe | Percorsi |
|---|---|---:|---:|
| input, `check-tabella-mappa-cbor` | 9–21 | 13 | 7 |
| input, `check-spazio-mappa-cbor` | 26–36 | 11 | 5 |
| input, `dimensioni-mappa-cbor` | 41–60 | 20 | 6 |
| input, `check-overlap-mappa-cbor` | 65–76 | 12 | 7 |
| input, `check-fini-mappa-cbor` | 81–99 | 19 | 7 |
| input, `check-radice-mappa-cbor` | 103–111 | 9 | 3 |
| input, `check-input-mappa-cbor` | 116–139 | 24 | 4 |
| write, `verifica-figlio-mappa-cbor` | 10–32 | 23 | 7 |
| write, `verifica-figli-mappa-cbor` | 38–66 | 29 | 9 |
| write, `scrivi-mappa-cbor-minima` | 72–109 | 38 | 6 |

Massimi: **38 righe, nove percorsi**, entro COD-12/13 nella convenzione dichiarata.
Guardie: input 22 + write 18 = 40; LOOP 1+1; AND/OR 5 con 14 operandi;
confronti concatenati 9 con 18 relazioni. Nessun sito viene rimosso perché interno,
ridondante rispetto al percorso pubblico o associato a una forma di errore.
