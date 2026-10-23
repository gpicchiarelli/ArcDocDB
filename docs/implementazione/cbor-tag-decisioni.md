# Decisioni della composizione dei tag CBOR

Inventario statico del 2026-10-14, prima della prima compilazione e delle
campagne. Input blob `6dfad07035ac8040b2aec0a455c175ea15dfd9ad`,
write blob `16b91fc27eabafd7ff12bfb0a56ed34208c2bd4b`:
[input](../../src/codec/cbor-tag-input.lisp),
[write](../../src/codec/cbor-tag-write.lisp),
[metodo](cbor-tag-metodo.md), [seconda lettura](cbor-tag-lettura.md).

I nomi abbreviati sotto indicano `test-REQ-CBR-007-tag-*` nel corpus
congelato `tests/codec/cbor-tag-write.lisp`, blob
`df97950ec8d24157bb6566c7995262f7beea7742`. I testimoni sono casi
previsti, non risultati di esecuzione. T/F sono valori logici delle
condizioni, anche quando il corto circuito impedisce di valutarne una.
Le coppie statiche indicano come cambia una sola condizione mantenendo
le altre verità; non attestano MC/DC dinamico.

Tutti i siti, incluse dichiarazioni, guardie interne, forme ERROR e
relazioni impedite dall'API pubblica valida, restano nei denominatori
delle osservazioni grezze future. Nessuna esclusione o qualifica C1.

## Cinque decisioni AND/OR, undici operandi

| ID/sito | Operatore e condizioni ordinate | Coppie e testimoni |
|---|---|---|
| D1 input:15, check-spazio-tag-cbor | OR A=BUFFER EQ SPACE.KINDS; B=SOURCE EQ SPACE.KINDS | `(T,F)` e `(F,F)` rendono A decisivo; `(F,T)` e `(F,F)` rendono B decisivo. `workspace-type-and-both-kinds-aliases` ruoli0/1 e buffer/source separati in `configured-limits-and-root-two-node-minimum`. |
| D2 input:49, check-overlap-tag-cbor | AND A=START<NEXT; B=NEXT<=LENGTH(BUFFER) | `(START,NEXT,LENGTH)=(3,5,12)` dà TT; `(5,5,12)` FT per A; `(3,13,12)` TF per B. Queste due false guardie interne sono impedite dal contenuto non vuoto e dal preflight capacità. `capacity-active-end-and-complete-byte-budget` e `destination-type-and-range-precedes-everything` proteggono i domini pubblici; non eseguono i due falsi interni. |
| D3 input:51, check-overlap-tag-cbor | AND A=SOURCE-START<SOURCE-END; B=SOURCE-END<=LENGTH(SOURCE) | `(SS,SE,LENGTH)=(7,8,13)` TT; `(8,8,13)` FT; `(7,14,13)` TF. Falsi interni già impediti dai validator source range/vuoto. `source-type-range-empty-and-backing-array-intact` verifica i rifiuti pubblici, senza attestare false guardie interne. |
| D4 input:53, check-overlap-tag-cbor | AND A=BUFFER EQ SOURCE; B=START<SOURCE-END; C=SOURCE-START<NEXT | TTT: stesso array, SS16/SE17, START8/NEXT18. FTT: array distinti, SS7/SE8, START7/NEXT9 nel probe tag0. TFT: stesso array, SS16/SE17, START17/NEXT27. TTF: stesso array, SS16/SE17, START6/NEXT16. Le tre coppie contro TTT rendono A/B/C distintamente decisivi; `overlap-including-only-header-and-touching-boundaries` e `u32-word-width-boundaries-and-all-wire-sentinels`. |
| D5 write:15, verifica-contenuto-tag-cbor | AND A=START<END; B=END<=LENGTH(SOURCE) | `(START,END,LENGTH)=(7,8,13)` TT; `(8,8,13)` FT; `(7,14,13)` TF. Falsi interni impediti dal preflight e dai risultati che passa. Il corpus source type/range/vuoto verifica i rifiuti pubblici prima dello scanner; gli errori interni restano da osservare, senza esclusione. |

Nessun AND/OR annidato, nessun LOOP nuovo. Per D2/D3/D5 le coppie
numeriche sono obblighi statici significativi, non invocazioni presenti
del helper con precondizioni violate. Una campagna solo sull'API valida
può lasciare scoperti quei falsi: si conserverà il dato grezzo completo.

## Relazioni numeriche concatenate

Due predicati con due relazioni ciascuno: quattro relazioni. Non sono
AND/OR scritti nel sorgente; inventario distinto dai percorsi sintattici.

| Sito | Relazioni ordinate | Coppie statiche e limiti dei testimoni |
|---|---|---|
| write:19 | A=2<=MAX-NODES; B=MAX-NODES<=16MiB | MAX-NODES2 dà TT;1 dà FT;16777217 dà TF. `configured-limits-and-root-two-node-minimum` e `all-preflight-phase-precedences` coprono i rifiuti pubblici per1 e oltre massimo. Il helper non viene raggiunto su quei falsi; la sua forma ERROR resta in copertura. |
| write:26 | A=1<=NODES; B=NODES<=MAX-NODES−1 | Residuo1/NODES1 dà TT (`configured-limits-and-root-two-node-minimum`, scalare con budget2). Residuo1/NODES0 darebbe FT; residuo1/NODES2 darebbe TF. Questi due risultati violerebbero il contratto dello scanner e richiedono un suo guasto interno per raggiungere ERROR. `root-and-content-node-residue-long-tag-chains-no-frame` verifica residui1 e insufficienza, ma l'errore scanner precede la postcondizione sul falso B. |

Gli altri ventuno predicati relazionali sono binari: input:27/31/36/38,
49x2/51x2/53x2,77/79/81; write:15x2/17/24/28/61/63/66.
In totale23 forme `<`/`<=`/`=`/`>` con25 relazioni elementari contando
le due catene. `PLUSP SPAN` input:29 e `ZEROP SPAN` input:69 sono
altri due predicati numerici, inventariati nelle guardie seguenti.

## Tutte le guardie e le forme di errore

23 siti WHEN/UNLESS,23 forme ERROR: input14, write9. IA=INVALID-ARGUMENT,
RE=RESOURCE-EXHAUSTED, IV=INVARIANT-VIOLATION. Tutti gli errori nuovi
locali omettono OFFSET quindi NIL; gli errori scanner mantengono l'offset
assoluto SOURCE. L'API non intercetta condizioni del parser.

| Funzione | Sito: condizione e motivo | Testimone/proprietà |
|---|---|---|
| check-spazio-tag-cbor | input:13 tipo SPACE → IA `:cbor-workspace`;15 OR alias → IA `:cbor-tag-workspace-alias` | workspace-type-and-both-kinds-aliases, invalidi e due ruoli; prima dei limiti invalidi |
| dimensioni-tag-cbor | input:27 START<=END → IV `:cbor-tag-dimension-range`;29 SPAN positivo → IV `:cbor-tag-dimension-empty` | Range/source-vuoto pubblici precedono il helper; falsi interni restano nel perimetro |
| dimensioni-tag-cbor | input:31 SPAN>MAX-BYTES;36 ITEM-SIZE>MAX-BYTES → RE `:cbor-tag-byte-budget`;38 ITEM-SIZE>END-START → RE `:cbor-tag-capacity` | full-16MiB-with-one-and-nine-byte-header-and-over include SPAN oltre massimo; capacity-active-end-and-complete-byte-budget distingue payload e tag completo, capacità fisica ignorata oltre END |
| check-overlap-tag-cbor | input:49 target span → IV `:cbor-tag-target-span`;51 source span → IV `:cbor-tag-source-span`;53 intersezione completa → IA `:cbor-tag-overlap` | D2/D3 interne; D4 array distinti/disgiunti/toccanti/overlap di sola testata e payload |
| check-input-tag-cbor | input:69 SPAN0 → IA `:cbor-tag-source-empty`;77 MAX-NODES<2 → RE `:cbor-tag-node-budget` | Source-vuoto prima di parole; minimo2 prima di parse, ma dopo byte/capacità/overlap |
| check-input-tag-cbor | input:79 SPAN=SOURCE-END−SOURCE-START → IV `:cbor-tag-input-span`;81 ITEM-SIZE<=END−START → IV `:cbor-tag-input-capacity` | Bilanci dei risultati dei validator/dimensioni; guardie attive di progresso, non false chiamate pubbliche |
| verifica-contenuto-tag-cbor | write:15 range → IV `:cbor-tag-child-range`;17 SPAN=END−START → IV `:cbor-tag-child-span`;19 2<=MAX-NODES<=16MiB → IV `:cbor-tag-child-budget` | Range/budget preflight dimostrati, D5 e prima catena; tutti gli ERROR mantenuti |
| verifica-contenuto-tag-cbor | write:24 NEXT=END → IV `:cbor-tag-child-progress`;26 1<=NODES<=MAX-NODES−1 → IV `:cbor-tag-child-nodes`;28 PEAK<=MAX-DEPTH → IV `:cbor-tag-child-depth` | Statistiche effettive scanner, seconda catena; scratch-content-only-statistics-after-success, root-and-content-node-residue-long-tag-chains-no-frame, depth-unchanged-zero-scalars-and-100-101-containers; falsi interni non dichiarati eseguiti |
| scrivi-tag-cbor-minimo | write:61 PAYLOAD-START=BEGIN+HEADER-SIZE → IV `:cbor-tag-header-progress`;63 NEXT−PAYLOAD-START=SPAN → IV `:cbor-tag-payload-span`;66 RESULT=NEXT → IV `:cbor-tag-write-progress` | Testate fredde, whole buffer, concatenazione, arità e source immutabile confrontano risultati; gli ERROR interni sono dopo la prima scrittura, senza rollback |

Fasi preflight ed errori parser sono testimoniati separatamente:
`all-preflight-phase-precedences`, `parser-failures-absolute-offset-and-complete-single-item`,
`every-truncation-nonzero-source-start-and-exact-end`,
`scratch-reuse-after-parser-and-preflight-errors` e
`fixed-seed-1024-fuzz-and-frozen-class-counts`. Lo scratch del contenuto
non include il tag radice emesso. Ogni successo controlla un solo NEXT.

## Righe e percorsi sintattici

DEFUN fino alla parentesi finale inclusa, con docstring/dichiarazioni.
Percorsi=1+WHEN/UNLESS+operandi AND/OR oltre il primo. Le catene numeriche
sono inventariate separatamente; nessun IF/COND/CASE/LOOP nuovo.

| Funzione | File/righe | Righe | Guardie | Percorsi |
|---|---|---:|---:|---:|
| check-spazio-tag-cbor | input:9–17 |9|2|4|
| dimensioni-tag-cbor | input:22–40 |19|5|6|
| check-overlap-tag-cbor | input:45–55 |11|3|8|
| check-input-tag-cbor | input:60–83 |24|4|5|
| verifica-contenuto-tag-cbor | write:10–30 |21|6|8|
| scrivi-tag-cbor-minimo | write:36–68 |33|3|4|

Massimi33 righe e8 percorsi, entro COD-12/13 nella convenzione dichiarata.
Sei funzioni,23guardie/ERROR,5AND/OR11operandi,2catene4relazioni e0cicli
sono confermati anche dalla lettura delle forme come DATA, READ-EVAL NIL
ed EOF, senza compilare o eseguire prodotto. Nessuna guardia viene rimossa
perché interna, ridondante rispetto al percorso pubblico o legata a ERROR.
