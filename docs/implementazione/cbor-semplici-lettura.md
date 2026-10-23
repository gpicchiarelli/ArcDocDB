# Scrittura dei valori semplici CBOR — seconda lettura C1

Lettura statica del responsabile del corpus cieco, il 2026-10-11, dopo
il congelamento delle prove e del prodotto, prima delle campagne. Base
`d155db3f977677fa95280f59c23fbe46a5e116d2`; prodotto esaminato
`src/codec/cbor-simple-write.lisp`, blob Git
`58c7a3a040ec814fae2dfe636f569b5623cba8f0`.
Il [metodo preregistrato](cbor-semplici-metodo.md) conserva il blob
`e8864f7c0124f86cebdcdbcb2449800e078e1cc8`.
L'[inventario delle decisioni](cbor-semplici-decisioni.md) è separato da
questa lettura; la prima lettura è affidata a un altro revisore.

Non sono emersi difetti funzionali o rilievi statici aperti nei blob
esaminati. Compilazione, risultati del corpus, sensori heap, concorrenza
osservata, copertura e mutazioni sono ancora pendenti. La lettura non
chiude i gate C1, non attesta MC/DC o copertura completa e non qualifica
il motore.

## Checklist C1

| Punto | Riscontro statico e verifica ancora necessaria |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-003 da ADR-0014, AFF-004/008 e INV-F1/P6 corrispondono a un codice wire locale MT7. Il dominio è integer 0..23 oppure 32..255; 24..31 è rifiutato. Nessuna conversione T/NIL, semantica dei codici non assegnati, float o composizione documentale. Il budget del documento rimane superiore secondo ADR-0048. |
| 2. Invarianti | Il preflight stabilisce simple u8, START/END index, ordine e limite fisico, codice ammesso e capacità sufficiente prima del write. Tre guardie interne controllano span, footprint e progresso. I confronti dell'intero array nel corpus falsificano modifiche al prefisso, al residuo e alla coda fisica; gli esiti runtime restano da registrare. |
| 3. Errori | Ordine conforme: destinazione/range → valore → capacità. I motivi sono :cbor-range e :cbor-simple-value per invalid-argument, :cbor-simple-capacity per resource-exhausted. Offset NIL deriva dall'initform della condizione. Tutti i rifiuti pubblici precedono ogni AREF/SETF di destinazione; le guardie interne non promettono rollback e il fail-stop appartiene al proprietario. |
| 4. Limiti | Il successo scrive esattamente uno o due byte. Il prodotto non contiene loop, ricorsione, attese, retry, creazione di worker o callback. La capacità usa END−START; lo spazio fisico dopo END non è disponibile. Nessun budget globale è applicato alla primitiva locale. |
| 5. Heap | Il successo usa scalari immediati, un descrittore di tipo costante, aritmetica limitata, LOGIOR e VALUES; nessun costruttore, lista, buffer, closure o AST. Una lettura statica non attesta heap zero: benchmark con baseline nulla e sensore positivo restano necessari. Le condizioni d'errore sono fuori dal percorso di successo da misurare. |
| 6. Uscita | Per VALUE<24, E0 ha i cinque bit bassi a zero: LOGIOR E0 VALUE coincide con 224+VALUE. Per VALUE≥32 scrive F8 e l'octet VALUE. Il cursore parte da START+1, avanza solo per il secondo byte e viene confrontato con NEXT prima di `(values next)`, che restituisce un valore. Il corpus verifica arità esatta e NEXT fixnum. |
| 7. Decisioni composte | Due forme AND di controllo: range con quattro condizioni, footprint con due. La relazione START≤END≤length(BUFFER) è interna al primo AND; il descrittore OR di TYPEP appartiene alla semantica del dominio e non è una forma di cortocircuito eseguibile scritta nel prodotto. L'inventario comprende anche questa unione. Guardie interne e rami negativi rimangono nel denominatore; nessuna esclusione o prova MC/DC. |
| 8. Proprietario | OWNER/SHARED dichiarano destinazione esclusiva fino al ritorno e nessuno stato condiviso tra Serie. Il prodotto usa il solo array ricevuto, non lo trattiene e non lo pubblica. Array displaced, adjustable, con fill-pointer o elemento diverso da u8 sono fuori dominio e rifiutati. L'esclusività fra chiamanti è una precondizione, non una proprietà verificabile dal codec. |
| 9. Integrazione | Export pubblico presente. ASDF seriale carica il prodotto dopo header/string writer e i tre file del corpus dopo gli helper CBOR, quindi invoca RUN del nuovo package. Le altre suite CBOR, MVCC, worker e index restano nel runner. REQ-CBR-003 è nel catalogo. Build rigorosa, matrice, lint e MAKE CHECK completo sono pendenti. |
| 10. Standard | safety3, FTYPE completi, docstring Pre/Post/errori, riferimenti REQ e guardie attive presenti. Due funzioni di 14/26 righe e 7/8 percorsi secondo il conteggio sotto, entro i limiti 60/10. Nessuna deroga proposta. Questa lettura non esegue compilazione o lint e non attesta assenza di warning/style-warning. |
| 11. Parallelismo | Il prodotto non introduce lock, contatori, attese o scritture condivise. Il nuovo corpus prevede due worker riusati con destinazioni private, piani freddi immutabili e semafori distinti per ondata; attese, join e cleanup sono limitati. La sovrapposizione degli intervalli deve essere osservata, senza inferire simultaneità sui core o scaling. |
| 12. Durabilità | Mutazione soltanto in memoria esclusiva del chiamante: nessun I/O, punto di commit, eliminazione o pubblicazione durevole. La primitiva non promette atomicità né rollback delle guardie interne. La transizione fail-stop resta al livello proprietario. |

## Aritmetica, preflight e footprint

L'AND del range precede LENGTH e sottrazione: un buffer di tipo errato o
START/END non index non vengono usati come destinazione o indici.
La sottrazione di index ordinati produce SPAN non negativo; la guardia
START+SPAN=END conferma lo span. La validazione di VALUE esclude anche
float, razionali, complessi, simboli e interi fuori dal dominio prima del
cast a u8. Il dominio contiene 24 codici diretti e 224 estesi.

SIZE≤SPAN implica START+SIZE≤END. NEXT viene calcolato solo dopo questa
verifica, quindi resta index e non può superare l'estremo fisico già
validato. CURSOR=START+1 è entro NEXT; se SIZE=2 il secondo write è
all'indice NEXT−1. Le sole destinazioni scritte sono START ed eventualmente
START+1. La guardia finale controlla CURSOR=NEXT prima del singolo ritorno.
Per uno span vuoto, SIZE≥1 produce un rifiuto di capacità, dopo l'eventuale
rifiuto di VALUE. Non viene emesso F8 con codice sotto 32, float o break.

## Dimensione e inventario

Conteggio sintattico: uno iniziale, un incremento per controllo di flusso
e per ciascuna condizione AND/OR di controllo aggiuntiva. Non include le
espansioni di TYPEP o confronti primitivi. Il confronto con il sorgente
conferma l'inventario del coordinatore.

| Funzione | Righe DEFUN inclusive | Percorsi |
|---|---:|---:|
| `check-input-simple-cbor-write` (10–23) | 14 | 7 |
| `scrivi-semplice-cbor-minimo` (28–53) | 26 | 8 |

Le due decisioni AND sono alle righe 14–15 e 45. Il confronto concatenato
alla riga 15 è già interno al primo AND, quindi non è una terza decisione
logica autonoma. L'unione di intervalli nella riga 17 conserva entrambe
le regioni, il gap e gli estremi nel corpus, senza contarla come OR di
controllo scritto. L'inventario resta sintattico/semantico e non costituisce
una misura dinamica di indipendenza delle condizioni.

## Provenienza del corpus cieco

I tre file seguenti sono stati scritti dal metodo e dalle dipendenze già
esistenti, senza leggere il nuovo prodotto. Sono stati congelati e
comunicati al coordinatore prima che il prodotto fosse scritto. Una
revisione indipendente di sola lettura ha verificato fixture, contratto,
sintassi visibile, conteggi e sink; non è stato eseguito un reader,
compilatore o test. Solo dopo il freeze è iniziata questa lettura del
prodotto. Gli hash ricontrollati restano uguali a quelli comunicati.

| File cieco | Blob Git | SHA-256 |
|---|---|---|
| `tests/codec/cbor-simple-write-support.lisp` | `10979b4a89af0b00d48abbc7bf6760afc3b5aa9b` | `53ceafc72a027a2ff1f787900558ff26f2ff70bbb212f1b37926a6d520fbe86e` |
| `tests/codec/cbor-simple-write.lisp` | `efaa31b8ea2d74af162fd00a3b4e923ae5f60cdd` | `958bdd3901cfc41032c09d6c9023b192799981884e09ce3573256ff45bc5329a` |
| `tests/codec/cbor-simple-write-threads.lisp` | `a7bee65793fc3a3e0c89c9c73871d7c183669a3e` | `77074033e75a224fd02e890f98dffa8e97d3a1f8bedd510b00ea55d8ff8687b2` |

L'oracolo calcola 224+VALUE o la coppia 248/VALUE, confrontata anche con
otto vettori letterali 0/19/20/21/22/23/32/255. Nessun expected proviene
da encoder, lettore o scanner di prodotto. Ogni successo confronta
l'intera destinazione e un solo NEXT fixnum; ogni rifiuto controlla tipo,
motivo, offset NIL e array fisico invariato, incluso l'intero backing
della destinazione displaced e lo spazio oltre il fill-pointer.

I quindici test seriali prevedono:

- 248 codici × 8 offset × 3 configurazioni di capacità esatta/residua e
  coda fisica: 5.952 confronti di successo.
- Ogni capacità da zero a SIZE−1 per tutti i codici e gli otto offset:
  3.776 rifiuti, con suffisso fisico disponibile ma escluso da END.
- Tutti gli otto riservati a otto offset e quattro capacità: 256 rifiuti;
  tipi/limiti di VALUE, destinazioni non simple, range invalidi, span
  vuoti anche all'estremo fisico, arità, sentinelle, priorità multi-invalid.
- Riuso dopo errori e successi, concatenazione dei 248 codici in 472 byte
  e fixture con START zero/END coincidente con la lunghezza fisica.
- Fuzz 2.048 casi seed `53494D43`, con offset, capacità e sentinelle
  fisiche deterministici: 768 successi, 512 valori invalidi, 256 capacità
  insufficienti e 512 destinazioni/range invalidi attesi.
- Lettore minimo e scanner su tutti i codici soltanto dopo il confronto
  dei byte freddi, controllando anche i loro sei/tre valori e il buffer
  immutato. Questi controlli sono supplementari.

Il sedicesimo test prevede due worker reali riusati, due ondate di 8.192
item per worker, 32.768 chiamate. Ciascun piano ha otto codici, ripetuti
1.024 volte per ondata; NEXT, token e tutti i byte attesi sono preparati
prima dell'avvio. Ogni destinazione privata viene ripristinata dalle
sentinelle fredde prima della chiamata, così una mancata scrittura non
può passare grazie a byte già corretti. Il worker verifica arità, NEXT e
array completo; il sink usa NEXT, primo e ultimo byte effettivamente
osservati. I sink freddi sono 3.804.160 e 3.836.928 per ciascuna ondata.
Il padre controlla piani e sentinelle immutati, buffer finale, sink,
intervalli e join. Attese entro 15 secondi, join entro 20 secondi,
cleanup limitato con terminazione verificata. Gli intervalli comprendono
ripristino e confronti della fixture; non misurano la sola primitiva.

## Correzione separata del precedente harness parallelo

La revisione del nuovo corpus ha rilevato che il precedente harness
delle stringhe riusava GO/DONE fra le due ondate. Un worker veloce poteva
consumare due permessi in ondate diverse prima dell'ingresso dell'altro,
mescolando i completamenti osservati dal padre. Questo poteva produrre
falsi fallimenti o timeout dipendenti dallo scheduling.

Il coordinatore ha autorizzato, dopo il freeze dei nuovi test, una
correzione minima dei soli semafori: READY/GO/DONE distinti per ondata,
accessi per indice WAVE e rilascio di entrambi i GO nel cleanup. Le
fixture, i confronti, i sink e le quantità del corpus precedente sono
rimasti uguali. Non è una modifica del prodotto. Le campagne precedenti
e i loro archivi non sono stati riscritti; il protocollo corretto deve
essere verificato nelle nuove campagne.

| File precedente | Blob prima | Blob dopo |
|---|---|---|
| `tests/codec/cbor-string-write-support.lisp` | `e45437a508fc7893c4df06f3129ab064d3a4dbdd` | `5a7f38de22be659787305441b65c689de4bd6dba` |
| `tests/codec/cbor-string-write-threads.lisp` | `33c7e6a9a0d6bbd551d4171ece6681b66bf87657` | `43c4b1ffe8c3dee1a37e9f7b07f655ec3959896b` |

Originali esatti, copie finali, diff e spiegazione sono conservati in
`spikes/out/cbor-simple-write-20261011/worker-protocol-fix/`; README blob
`b15175416d37980ed9dd280a39952b4ecc3aed09`, SHA-256
`0c85c9e8d4a0a76cbbbe7ceb90b376df3aecf126c64f90cebbbd4abaeef7647d`.
Il test parallelo delle testate ha una sola ondata e resta identico,
blob `878f0fa10825ae3d49e9cac2f94d9992c06f2d20`. I tre nuovi blob ciechi
non sono cambiati durante il fix.

## Riscontri e verifiche pendenti

Altri blob esaminati: package
`0a75ef778c3d5ea490ec0a61f11bf6c65a3183ee`, ASDF
`2a4f3cf6dd800e5e9c3d624c23971bec352d7988`, catalogo requisiti
`19223d1767a6b7eebb9636d99cea7d898560cbd2`, inventario
`3ec66f8edebd79a128969e0b398e7700a2b1c5cd`, tipi foundation
`2d514f6fe2e81eecb29fa53de611fa5e28696904` e condizioni
`edbe5eaa88c50dc13af8e367b73f7f41fd7bd724`. Tipi, condizioni e helper
CBOR condivisi non risultano modificati rispetto alla base.

Nessuna compilazione, chiamata al prodotto/test, misura heap, copertura
o mutazione è stata eseguita dal responsabile di questa lettura. Restano
necessarie campagne registrate con sorgenti stabili, controlli dei
sensori, baseline e otto mutazioni, coverage grezza senza esclusioni e
regressioni complete. Le qualifiche delle dipendenze mantengono i loro
limiti storici; questa lettura non è un'approvazione umana.
