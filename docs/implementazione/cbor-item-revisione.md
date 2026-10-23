# Primo item CBOR minimo — prima revisione C1

Lettura statica del responsabile del corpus freddo il 2026-10-15, dopo
il freeze del corpus e la successiva scrittura del prodotto, prima della
prima compilazione, load o campagna. Il revisore è distinto dall'autore
del prodotto e non consulta la seconda lettura C1. Sorgente esaminato:
[cbor-item-read.lisp](../../src/codec/cbor-item-read.lisp), blob
`b9099dc8a8c96281063811e686deb4dcb2b1d39b`. Metodo preregistrato
[cbor-item-metodo.md](cbor-item-metodo.md), blob
`a67a79bf4fefe11c4778cd881eb5279a006966ca`.

Nessun difetto funzionale o rilievo statico aperto individuato nel blob.
Prodotto e corpus non sono modificati da questa lettura. Compilazione
rigorosa, lint, risultati del corpus, heap, intervalli paralleli,
copertura e mutazioni restano pendenti. Questa revisione non chiude
la qualifica C1/MC/DC né qualifica il motore.

## Checklist C1

| Punto | Riscontro statico e limite |
| --- | --- |
| 1. Requisiti e ADR | REQ-CBR-008, LIM-001/002, AFF-004/008 e INV-A5/A8/P6 descrivono la primitiva strutturale bounded derivata da ADR-0014/0024/0035/0048. Il risultato è frontiera e conteggi del primo item, senza AST o interpretazione della coda. Il profilo documentale e la semantica dei tag restano aperti. |
| 2. Invarianti | Preflight identico allo scanner, prima del reset. Guardie nuove su SPAN, esaurimento del ciclo, progresso START<NEXT e NEXT<=END; drain e risultato preesistenti verificano root/conteggi/stato. Nessuna dipendenza dalla validità della coda. |
| 3. Errori | Ordine range/workspace/alias/limiti byte-nodi-depth/byte-budget preservato, offset NIL e scratch immutato. Parsing propaga header minimo, UTF8, nodi/depth con offset assoluti. Vuoto e troncamenti arrivano al lettore `[END,END)`: `:cbor-truncated` a END. Nessun risultato parziale; buffer immutato anche dopo errore e scratch riusabile. |
| 4. Limiti | SPAN<=16MiB prima del ciclo, al più SPAN passi con progresso verificato. Ogni drain al più102 frame. Tag senza frame e profondità soltanto array/map. END originario sempre passato al passo; il controllo di completamento usa il cursore. Nessuna ricorsione, attesa o retry nuovo. |
| 5. Heap | Variabili tipizzate locali e tre valori, nessun array/cons/AST/closure nuovo nel successo. Reset lavora sui due array preallocati; valori wire restano in parole. Keyword call e dipendenze richiedono benchmark con baseline nulla e controllo positivo; heap zero non è attestato staticamente. |
| 6. Dati verificati | MINIMAL=T nel passo, intera finestra per MAX-BYTES, conteggi del solo item. Risultato chiamato con NEXT=CURSOR e non END fisico: restituisce esattamente NODES/PEAK/NEXT. Tre valori fissati da FTYPE e callee, nessuna ricostruzione u64 o copia buffer. |
| 7. Decisioni composte | Sei predicati espliciti, cinque siti ERROR, un LOOP, zero AND/OR, quattro confronti binari e zero catene. Inventario completo nella [tabella](cbor-item-decisioni.md), incluse guardie interne e tre default keyword. Nessuna esclusione, coppia statica o assenza di AND/OR presentata come MC/DC misurato. |
| 8. Proprietario | OWNER/SHARED dichiarano buffer stabile condivisibile read-only e spazio esclusivo della chiamata/worker. Preflight rifiuta BUFFER=KINDS prima di reset. Il tipo simple u8 esclude displaced/backing condivisi; REMAINING è simple u32 distinto su SBCL. Nessuna scrittura al buffer o stato globale. |
| 9. Integrazione | Export package riga13; ASDF prodotto riga36 dopo gli scanner, tre file corpus righe171–172 e RUN incluso nel test-system. Scope coverage esatto del solo nuovo sorgente, un positivo/quattro negativi di selezione, RUN diretto e aggregato codec. REQ-CBR-008 e matrice già rigenerata risultano implementato con test/diff/fuzz/bench/mut/rev, senza :cov. Nessun make check eseguito da questa lettura. |
| 10. Standard | Safety3, FTYPE completo con arità tre, REQ, docstring Pre/Post/errori e tipi ristretti dopo preflight. Una funzione34 righe/8 percorsi sintattici, entro60/10; almeno due controlli significativi. Nessuna deviazione proposta; warning/style-warning/lint devono ancora essere osservati. |
| 11. Parallelismo | Nessun thread, lock, attesa o scrittura condivisa nuova nel prodotto. Corpus con due worker reali riusati, buffer condiviso read-only e scratch privati, due ondate, rendezvous dopo il primo item verificato, sink, timeout e cleanup. Timestamp/overlap devono ancora essere osservati; nessuna inferenza su core o scaling. |
| 12. Durabilità | Solo memoria del chiamante, nessun I/O o pubblicazione atomica/durevole. La primitiva non cambia la Serie; la gestione FAULTED per invarianti interni resta del confine proprietario. |

## Finestra, completamento e coda

`check-input-struttura-cbor` restituisce END−START e verifica tutti gli
argomenti prima di leggere byte o cambiare lo scratch. MAX-BYTES riguarda
l'intera finestra autorizzata, anche se il primo item termina subito.
Una finestra di cinque byte `00 FF 1C 18 00` richiede budget5; budget1
deve fallire prima del reset. Il chiamante può restringere END a1.

Il vecchio drain impone EOF rispetto al proprio parametro END.
Passargli il CURSOR corrente rende quel requisito identico al cursore
già raggiunto, senza leggere la coda: root completa termina, root non
completa ritorna NIL. In entrambi i punti del nuovo wrapper, il drain
riceve CURSOR; il passo riceve invece LIMIT=END originario. Quest'ultimo
deve poter leggere l'intero header/payload dell'item entro la finestra
e conservare gli offset assoluti di errore.

Esempio `C0 81 00 FF`: tag consuma un nodo senza frame, array un nodo
e un livello, scalare un nodo. Dopo lo scalare il drain chiude array
e root a NEXT3; FF non viene letto. `risultato-struttura-cbor` riceve3
e verifica cursor=3, nodi3, peak1 e stato vuoto prima dei tre valori.
Gli scanner esatti preesistenti continuano a passare END4 al drain e
rifiutano FF con `:cbor-trailing` a3. Non sono stati modificati.

Ogni passo avanza almeno un byte e non supera END. Se il ciclo termina
per esaurimento di SPAN senza root completa, il cursore deve essere END;
il lettore header `[END,END)` produce il troncamento pubblico. La guardia
ERROR successiva rileverebbe un ritorno impossibile del lettore.
Per SPAN0 la stessa strada produce il troncamento, senza accettare
l'item vuoto o restituire valori parziali. Nessun byte oltre NEXT è
letto dopo la radice completa; le letture interne necessarie a decidere
la lunghezza di un item non completo restano bounded da END.

La root completata, il singolo passo progressivo e le guardie esplicite
implicano START<NEXT<=END. Tag1024+scalare usa1025 nodi, profondità0 e
nessun frame per tag; cento array ammettono peak100, il101esimo fallisce
sul suo lead. Node/depth non comprendono item nella coda.

## Corpus congelato e lettura DATA

| File del corpus freddo | Blob Git |
| --- | --- |
| tests/codec/cbor-item-read-support.lisp |0326100362a1c4b24d2c7e511e45357f09a56d33|
| tests/codec/cbor-item-read.lisp |b2cbdcb4255c51d9da4fe73b28939c1cb923fefe|
| tests/codec/cbor-item-read-threads.lisp |a0da65545ed80ede0a967cadbb337731f6fe1ce9|

Piano freddo `review/blind-plan.md` nel supporto ignored, blob
`63a749b0e8737f49d400f40b0a98c454c2dc3cfc`:17 nominali,
**9901 chiamate** attese alla nuova API:685 non-fuzz (551 successi/134
rifiuti),1024 fuzz (512/512),8192 parallele. Totale9255/646.
Sono conteggi statici del corpus, non risultati PASS. Scanner esatti
secondari separati:520 sul prefisso,390 trailing e due sul concatenato.

LCG32 seme49544538 e finale6CB25938 sono ricomputati senza prodotto.
Il finale provvisorio errato è corretto prima del freeze, conservando
il seriale originario. Le34 forme del corpus sono state lette DATA,
READ-EVAL NIL fino a EOF;17 nomi DEFTEST unici e stderr vuoto.
Il corpus include MT0..7, float raw, UTF8, parole/lunghezze, buffer
non validi e fisici, tutte le precedenze, alias, limiti16MiB/0/100/101,
tag lunghi, ogni troncamento composito, arità e riuso dopo errore.

Parallelo: due ondate da2048 letture per ciascuno dei due worker,
fixture `C0 A1 61 61 82 F4 F5` e coda `FF 1C 18 00`, START7/END18,
attesi6/2/NEXT14, token36196, sink74129408 per worker/ondata.
START/FIRST/END, sink e overlap stampati prima delle asserzioni.
Il rendezvous dopo la prima lettura verificata include controlli e
attesa nel WALL; nessuna conclusione su tempo puro decoder o scaling.
Attesa15s, join20s e cleanup con cessazione verificata.

Il lettore meccanico `review/read-product-decisions-v2.lisp` legge
quattro forme del prodotto come DATA con READ-EVAL NIL fino a EOF;
conferma1 funzione,5UNLESS/1WHEN,1LOOP,5ERROR,0AND/OR,
4 confronti binari e0 catene. Stdout conservato, stderr vuoto, exit0.
Prima variante del solo lettore con parentesi mancante conservata
con stdout/stderr; nessun LOAD/EVAL/COMPILE del prodotto.

## Integrazione e dipendenze lette

Package `64b3a838f6d5b432148e64604d5e1dfa4a3c32d4`, ASDF
`8e36893806e499946cbffcc2c8475690ea40cba0`, coverage
`19369e3ea8f944a420efa1918383c7ac28544c6d`.
La matrice letta contiene REQ-CBR-008 implementato; la successiva
verifica trace resta responsabilità dell'integrazione.

Dipendenze: preflight `57ffc48cc688a4de8ebec5cb14c1e69c4209704a`,
spazio/reset `a8330e50a77b52a6b9044ebbb48f62bb4b3222a3`,
stack/drain `c574e87af5e195ddf3f596a4ae527e69c7a3c6a6`,
passo/items `70272936e323b3e0cb05173c9fb68cb2b614c355`,
scanner/risultato `e3d7d77407046338d23e26eb0b8a2e8fdc3d699d`,
wrapper minimo esatto `f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6`.

Rimangono compilazione senza warning/style-warning, lint, self-test e
campagne con sorgenti/indice/HEAD stabili, heap, copertura completa
senza esclusioni, otto mutazioni, letture distinte dei dati e make check
integrato. Nessuna di queste misure è attestata dalla presente lettura.
