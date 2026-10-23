# Decisioni della composizione degli array CBOR

Inventario statico del 2026-10-13, prima della compilazione e delle campagne:
`src/codec/cbor-array-input.lisp` blob
`d3b3d07fc18bd2a077c1a2d79020a76263b2779e` e
`src/codec/cbor-array-write.lisp` blob
`a410297c29c5d043ad60d3804bd3711e22c2833b`.
Riferimenti: [metodo](cbor-array-metodo.md) e
[prima lettura C1](cbor-array-revisione.md).

I testimoni sono casi presenti nel corpus congelato o proprietà interne
da confrontare con le prove future. Non sono risultati di esecuzione né
una dimostrazione MC/DC. Tutti i siti, incluse guardie interne e forme di
errore, rimangono nei denominatori delle future misure grezze. Non si
escludono automaticamente dichiarazioni, invarianti o rami irraggiungibili
dall'API pubblica.

## Tutte le nuove decisioni AND/OR

Cinque siti, 14 operandi; nessuna forma composta annidata. Nel file write
non sono presenti AND/OR. Le condizioni sono elencate nell'ordine di
valutazione, compreso il corto circuito.

| File/riga, funzione | Forma e condizioni | Testimoni previsti o limite |
|---|---|---|
| input:15, `check-tabella-array-cbor` | AND: COUNT INDEX; COUNT<=LENGTH(ITEM-ENDS); COUNT<=SPAN | `table-type-and-count-domains`: NIL/negativo/float/bignum; COUNT2 con tabella1 e SPAN2; COUNT1 con tabella1 e SPAN0; casi validi e COUNT0 |
| input:17, `check-tabella-array-cbor` | AND: COUNT zero; SPAN positivo | COUNT0/SPAN1 rifiutato; COUNT0/SPAN0 accettato; COUNT positivo valido |
| input:30–32, `check-spazio-array-cbor` | OR: BUFFER EQ SPACE.KINDS; SOURCE EQ SPACE.KINDS; ITEM-ENDS EQ SPACE.REMAINING | `workspace-type-and-all-scratch-aliases-even-empty` esercita separatamente i tre ruoli; caso valido senza alias |
| input:67–68, `check-overlap-array-cbor` | AND: BUFFER EQ SOURCE; SOURCE-START<SOURCE-END; START<SOURCE-END; SOURCE-START<NEXT | `overlap-entire-footprint-touching-and-empty`: array distinti, sorgente vuota, span prima/toccanti/dopo, overlap della testata o payload |
| input:88, `check-fini-array-cbor` | AND: PREVIOUS<STOP; STOP<=SPAN | `strict-entry-order-bounds-last-and-unread-tail`: zero/duplicate/discendenti; fine oltre SPAN; crescita valida e coda ignorata |

Questi nomi abbreviati indicano i test
`test-REQ-CBR-005-array-*` in `tests/codec/cbor-array-write.lisp`,
blob `b13f58264f3cd97e1947ee52936732a7fcebe672`.
La presenza di un caso per ciascun operando non attesta che tutti gli
operandi siano già risultati decisivi indipendentemente.

## Relazioni numeriche concatenate

Otto predicati, ciascuno con due confronti matematici. Non sono AND/OR
scritti nel sorgente e non si sommano al conteggio sintattico dei percorsi.
Restano esplicitamente inventariati per la lettura condizione per
condizione e per l'interpretazione delle forme osservate da SB-COVER.

| File/riga | Relazione | Proprietà controllate |
|---|---|---|
| input:63 | START<=NEXT<=LENGTH(BUFFER) | ordine del footprint e limite fisico |
| input:65 | SOURCE-START<=SOURCE-END<=LENGTH(SOURCE) | ordine della sorgente e limite fisico |
| input:82 | COUNT<=SPAN<=16MiB | lavoro sulla tabella e clamp prima di cast/somma |
| write:15 | START<=END<=LENGTH(SOURCE) | intervallo del singolo figlio |
| write:28 | 1<=NODES<=REMAINING | almeno un nodo e rispetto del residuo effettivo |
| write:44 | START<=END<=LENGTH(SOURCE) | intervallo complessivo dei figli |
| write:60 | 1+COUNT<=NODES<=MAX-NODES | minimo radice/figli e limite aggregato |
| write:62 | 1<=PEAK<=MAX-DEPTH | livello della radice e limite aggregato |

Gli errori di queste otto relazioni sono interni. Il dominio pubblico
valida prima gli intervalli e i budget; la scansione fornisce nodi e
picchi che vengono confrontati, senza presumere che i rami di errore
interni possano essere raggiunti da una chiamata pubblica valida.

## Inventario completo delle guardie e dei cicli

36 siti WHEN/UNLESS e due LOOP. IA=INVALID-ARGUMENT,
RE=RESOURCE-EXHAUSTED, IV=INVARIANT-VIOLATION. Gli offset dei controlli
di preflight e degli invarianti sono NIL; l'unico RE locale durante la
scansione, write:17, usa l'inizio assoluto del prossimo figlio.

| Funzione / righe | Guardie, esito di errore e limite |
|---|---|
| `check-tabella-array-cbor`, input:13/15/17 | tipo simple U32 → IA `:cbor-array-item-ends`; AND sul COUNT → IA `:cbor-array-count`; COUNT0 con SPAN positivo → stesso motivo |
| `check-spazio-array-cbor`, input:28/30 | tipo SPACE → IA `:cbor-workspace`; OR dei tre alias → IA `:cbor-array-workspace-alias` |
| `dimensioni-array-cbor`, input:44/50/52 | SPAN>MAX-BYTES, poi ITEM-SIZE>MAX-BYTES → RE `:cbor-array-byte-budget`; ITEM-SIZE>END-START → RE `:cbor-array-capacity` |
| `check-overlap-array-cbor`, input:63/65/67 | range destinazione/sorgente → IV `:cbor-array-target-span` / `:cbor-array-source-span`; AND overlap completo → IA `:cbor-array-overlap` |
| `check-fini-array-cbor`, input:80/82/86/88/91 | COUNT<=lunghezza → IV `:cbor-array-table-bound`; COUNT<=SPAN<=16MiB → IV `:cbor-array-table-budget`; LOOP COUNT; crescita/bound e ultima fine=SPAN → IA `:cbor-array-item-ends` |
| `check-radice-array-cbor`, input:101/103 | COUNT>MAX-NODES-1 → RE `:cbor-array-node-budget`; MAX-DEPTH0 → RE `:cbor-array-depth-budget`, in quest'ordine |
| `check-input-array-cbor`, input:127/129 | SPAN=SOURCE-END-SOURCE-START → IV `:cbor-array-input-span`; ITEM-SIZE<=END-START → IV `:cbor-array-input-capacity` |
| `verifica-figlio-array-cbor`, write:15/17/21/26/28/30 | range → IV `:cbor-array-child-range`; REMAINING0 → RE `:cbor-array-node-budget` con offset START; SPAN positivo → IV `:cbor-array-child-empty`; NEXT=END → IV `:cbor-array-child-progress`; 1<=NODES<=REMAINING → IV `:cbor-array-child-nodes`; PEAK<=CHILD-DEPTH → IV `:cbor-array-child-depth` |
| `verifica-figli-array-cbor`, write:44/46/48/52/58/60/62 | range → IV `:cbor-array-children-range`; COUNT<=lunghezza → IV `:cbor-array-children-bound`; COUNT<=16MiB → IV `:cbor-array-children-budget`; LOOP COUNT; CURSOR=END → IV `:cbor-array-children-progress`; nodi aggregati → IV `:cbor-array-children-nodes`; picco aggregato → IV `:cbor-array-children-depth` |
| `scrivi-array-cbor-minimo`, write:92/94/98/100/103 | NODES<=MAX-NODES / PEAK<=MAX-DEPTH → IV `:cbor-array-result-nodes` / `:cbor-array-result-depth`; PAYLOAD-START=BEGIN+HEADER-SIZE → IV `:cbor-array-header-progress`; NEXT-PAYLOAD-START=SPAN → IV `:cbor-array-payload-span`; RESULT=NEXT → IV `:cbor-array-write-progress` |

I LOOP hanno COUNT verificato prima della prima entry: COUNT<=SPAN,
SPAN<=MAX-BYTES<=16MiB. Il secondo LOOP deriva ogni fine assoluta da una
fine relativa già verificata entro SOURCE-END; passa il residuo nodi e
MAX-DEPTH-1 allo scanner. Nessun percorso scrive la destinazione prima
del completamento della scansione. COUNT0 non chiama né resetta lo scanner.

I percorsi sintattici per le sette funzioni di input sono
7/5/4/7/7/3/3; per le tre funzioni di write sono 7/8/6. Il massimo è
otto, includendo i corto circuiti e i LOOP. Il rapporto grezzo futuro
mantiene tutti i rami interni, indipendentemente da questi conteggi.

## Decisioni riusate e precedenza

`check-span-string-cbor-write` viene chiamata per destinazione e sorgente;
`check-limiti-struttura-cbor` mantiene l'ordine byte/nodi/profondità.
Selezione/emissione testata, scanner minimo e copia non sono duplicati:
valgono i loro controlli, condizioni e motivi di errore esistenti. Per
le forme riusate consultare gli inventari
[stringhe](cbor-stringhe-decisioni.md) e
[scanner minimo](cbor-minimo-struttura-decisioni.md).
Lo scope grezzo dei due nuovi file non è una misura di tutte le dipendenze.

La precedenza è range destinazione, range sorgente, tabella/COUNT,
workspace/alias, limiti configurati, byte, capacità, overlap, entry,
minimo nodi, profondità radice, scanner dei figli in ordine. Errori dello
scanner sono propagati con motivo e offset assoluto SOURCE. Le guardie
del writer dopo la prima emissione sono fail-stop senza rollback.
