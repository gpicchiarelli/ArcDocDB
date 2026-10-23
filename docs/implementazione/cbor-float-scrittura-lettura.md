# Scrittura dei float CBOR — seconda lettura C1

Lettura statica del responsabile del corpus cieco, il 2026-10-13, dopo
il congelamento del corpus e la successiva scrittura del prodotto,
prima della compilazione e delle campagne. Base
`07b26a0941bf48e0ec14d3391cb71455d7e8388f`; metodo preregistrato
[scrittura float](cbor-float-scrittura-metodo.md), blob
`755b13a91ab72f54383d96faee5780da36e750d6`.

| Prodotto esaminato | Blob Git |
|---|---|
| `src/codec/cbor-float-narrow.lisp` | `cd5749edc0a757ee3a5b470eda566a6685d32fd8` |
| `src/codec/cbor-float-write.lisp` | `03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c` |

Non sono emersi difetti funzionali o rilievi statici aperti nei blob
esaminati. Compilazione rigorosa, campagne, heap osservato, concorrenza,
copertura grezza e mutazioni restano pendenti. La lettura non qualifica
C1 o il motore, non attesta MC/DC e non è un'approvazione umana.

## Checklist C1

| Punto | Riscontro statico e verifica ancora necessaria |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-004, AFF-004/008, INV-F1/P6 e ADR-0014/0033/0035/0048 sono coerenti con una primitiva wire locale. AI25/26/27 identifica bit IEEE raw, non numeri Common Lisp. Sono accettate codifiche accorciabili, preservando segno, zero, infinito e significando NaN; profilo applicativo e budget documentale rimangono superiori. |
| 2. Invarianti | Le funzioni separano range/AI, tipo/coerenza delle parole, selezione esatta, capacità e mutazione. Le guardie verificano span, input accorciabile, significando/allineamento, ricostruzione delle due parole dal quoziente, segno, coerenza della parola alta e progresso. Il corpus confronta ogni byte fisico e NEXT; gli esiti runtime sono pendenti. |
| 3. Errori | Ordine range → AI → HIGH → LOW → parole → capacità. Motivi :cbor-range/:cbor-float-ai/:cbor-float-high/:cbor-float-low/:cbor-float-words per invalid-argument; :cbor-float-capacity per resource-exhausted. Offset NIL deriva dall'initform della condizione. Tutti i rifiuti pubblici precedono il primo write; invariant-violation interno richiede fail-stop del proprietario e non promette rollback. |
| 4. Limiti | Due riduzioni al massimo, nessun loop o ricorsione nei nuovi sorgenti. L'helper BE esistente esegue due o quattro passi per parola; output totale 3/5/9 byte. Nessuna attesa, retry, callback, creazione di worker o I/O nel prodotto. La capacità è END−START della forma già selezionata. |
| 5. Heap | Su target SBCL64, i campi e gli shift producono valori immediati: nessun u64 ricomposto, float, lista, closure, AST o nuova destinazione. Anche il significando53 rimane diviso HIGH21/LOW32. La lettura non prova heap zero: servono benchmark seriale, baseline nulla e controllo positivo. Le condizioni d'errore sono fuori dal successo da misurare. |
| 6. Uscita | La selezione può fare 64→32→16, senza saltare il secondo controllo. F9/FA/FB sono E0 OR AI25/26/27; HIGH viene emesso solo per size9 e LOW in due/quattro byte. La guardia CURSOR=NEXT precede `(values next)`, un solo risultato. Il corpus verifica arità esatta, NEXT fixnum e array completo. |
| 7. Decisioni composte | Sei AND/OR nei nuovi sorgenti, elencati sotto con le condizioni e i loro ruoli. CASE/COND, guardie interne, dichiarazioni e predicati primitivi concatenati rimangono espliciti nell'inventario; nessuna esclusione dal denominatore o inferenza di indipendenza dinamica. |
| 8. Proprietario | OWNER/SHARED dichiarano buffer esclusivo e parole/cursori locali. Non vi sono stato globale mutabile, scratch trattenuto o pubblicazione del buffer. Le destinazioni non simple/displaced/adjustable/fill-pointer sono rifiutate. L'esclusività tra chiamanti resta una precondizione. |
| 9. Integrazione | Export presente; ASDF seriale carica i due nuovi sorgenti dopo predicati IEEE e helper BE, poi i tre test e RUN. Scope coverage seleziona esattamente i due nuovi file, con positivi e negativi di suffisso. Catalogo e matrice contengono REQ-CBR-004 senza dichiarare :cov; make check completo è pendente. |
| 10. Standard | safety3, FTYPE completi, docstring Pre/Post/errori, REQ e controlli attivi presenti. Le sette funzioni occupano 14–26 righe e 6–9 percorsi, entro 60/10. Guardie e assenza di effetti collaterali sono discusse sotto; nessuna deviazione proposta. Assenza di warning/style-warning e lint richiedono esecuzione successiva. |
| 11. Parallelismo | Nessun lock, attesa o write condiviso tra Serie sul percorso della chiamata. Il corpus prevede due worker riusati, buffer privati e piani immutabili, con READY/GO/DONE distinti per ciascuna delle due ondate. Intervalli, sink, join e cleanup devono essere osservati senza dedurre scaling o simultaneità sui core. |
| 12. Durabilità | Solo mutazione in memoria esclusiva del chiamante: nessun punto di commit, I/O, eliminazione o pubblicazione durevole/atomica. Composizione, fail-stop e transizioni della Serie appartengono al livello proprietario. |

## Riduzioni e conservazione dei bit

Binary32→16: il predicato esistente ammette soltanto lo zero quando
l'esponente è zero. Per esponente255, i tredici bit bassi della frazione
devono essere zero e il payload si riduce senza perdere quiet/signaling.
Per esponente113..142, l'esponente16 è E−112 e la frazione è F/2^13.
Per esponente103..112, il significando24 diventa subnormale16 con
divisione esatta per 2^(126−E). I campi del segno sono riportati al bit15.

Binary64→32: i casi zero e speciali seguono lo stesso schema; il
payload/frazione23 è HIGH-frazione×8 più LOW/2^29, con allineamento
già verificato. Per esponente897..1150, l'esponente32 è E−896.
Per esponente874..896, la divisione del significando53 richiede
SHIFT=926−E, quindi 30..52. Sotto32 il quoziente combina
HIGH×2^(32−SHIFT) e LOW/2^SHIFT; da32 in poi basta HIGH/2^(SHIFT−32),
perché il predicato di allineamento impone LOW=0. Il caso SHIFT32
cade nel secondo ramo e conserva HIGH senza shift. Nessuna operazione
ricompone il significando53 o l'intera parola64.

La selezione aggiorna LOW, azzera HIGH e porta AI a26 dopo la riduzione64.
Il successivo WHEN considera quindi anche questo nuovo binary32 e può
ridurlo a16. Input16 validi conservano i bit originali; input32/64 che
non ammettono riduzione conservano tutte le parole. L'oracolo del corpus
ricava classe e valore razionale, poi cerca una codifica esatta generale;
non riutilizza queste formule a shift né i predicati di prodotto.

## Preflight, footprint e COD-24

L'AND del range protegge LENGTH e aritmetica da tipo buffer/indici errati.
HIGH viene verificato prima di LOW; solo poi CASE controlla HIGH=0 per
AI25/26 e LOW≤65535 per AI25. Il tipo u32 ammette valori fino a 2^32−1,
così LOW=65536 in AI25 produce :cbor-float-words, non :cbor-float-low.
Il controllo di capacità avviene dopo la selezione: anche un input64
ridotto a16 riesce con soli tre byte disponibili.

SIZE≤SPAN e START≤END implicano NEXT=START+SIZE≤END, senza overflow
dell'index. CURSOR=START+1 è entro NEXT. Per size3/5 l'unico write BE
copre [START+1,NEXT); per size9 il primo copre quattro byte HIGH e il
secondo quattro LOW. L'helper BE riceve NEXT come limite e controlla
range, larghezza della parola e progresso. Prefisso, residuo dello span
e coda fisica restano fuori da tutte le scritture.

I controlli di ingresso e uscita hanno ruoli distinti: range/AI e
ricomposizione dello span; tipi HIGH/LOW e coerenza della forma restituita;
coerenza HIGH prima/dopo selezione; accorciabilità e conservazione del
segno nei riduttori; larghezza/allineamento e ricostruzione delle parole nel
riduttore di significando; capacità/footprint e avanzamento nel writer.
Non sono guardie di ritorno costante o assert TRUE. Le guardie di segno
e ricostruzione possono risultare non visitabili con input pubblici validi
e formule locali corrette: questo non le esclude dalla
copertura e non prova che proteggano da qualsiasi difetto aritmetico.
L'esattezza completa dei bit è affidata anche all'oracolo freddo e alle
mutazioni. Le condizioni di guardia non modificano il buffer; la
transizione C1 a FAULTED resta al confine proprietario, non nel codec.

Durante le letture, prima di ogni compilazione, il primo revisore ha
segnalato che la guardia `RESULT≤#x7fffff` del riduttore di significando
ripeteva soltanto il tipo u23 dichiarato. Il coordinatore l'ha sostituita
con due postcondizioni: HIGH deve coincidere con RESULT×2^(SHIFT−32),
e LOW con i bit bassi di RESULT riportati alla posizione originale
quando SHIFT<32, oppure zero negli altri casi. Per SHIFT30/31 il primo
confronto elimina rispettivamente due/un bit bassi; per SHIFT32 conserva
RESULT; per SHIFT33..52 ricostruisce HIGH tramite shift a sinistra.
Il secondo confronto usa una maschera di due/un bit, senza ricomporre u64.
Questi controlli verificano il quoziente rispetto alle parole originali,
non solo rispetto al suo tipo. La seconda lettura finale riguarda questa
revisione `cd5749ed...`; originale `31a61d565...`, revisione e nota sono
conservati in `spikes/out/cbor-float-write-20261013/precompile-quotient-guard/`.
Il corpus non è stato modificato e non vi è stata una campagna sul blob
originario.

## Dimensione e decisioni

Conteggio sintattico: un percorso iniziale, un incremento per IF/WHEN/
UNLESS, per ogni ramo non finale di COND/CASE e per ogni argomento AND/OR
aggiuntivo. Non comprende espansioni del compilatore di TYPEP o dei
confronti primitivi. Righe DEFUN inclusive, con docstring e dichiarazioni.

| Funzione | Sorgente, righe | Righe | Percorsi |
|---|---|---:|---:|
| `riduci-binary32-cbor` | narrow, 10–31 | 22 | 7 |
| `riduci-significando64-cbor` | narrow, 37–55 | 19 | 7 |
| `riduci-binary64-cbor` | narrow, 59–81 | 23 | 7 |
| `check-float-cbor-range` | write, 9–22 | 14 | 7 |
| `check-float-cbor-words` | write, 27–41 | 15 | 8 |
| `seleziona-float-cbor` | write, 47–61 | 15 | 9 |
| `scrivi-float-cbor-minimo` | write, 65–90 | 26 | 6 |

| Decisione composta in write | Condizioni | Riscontro nel corpus |
|---|---|---|
| 13–14, AND range | octets; START index; END index; START≤END≤length | tipi di destinazione, tipi/limiti indici, range invertiti e oltre coda, validi/esatti/vuoti |
| 36, AND parole16 | HIGH=0; LOW≤65535 | HIGH nonzero, LOW65536/2^32−1, half validi, LOW errato prima della coerenza |
| 51, OR ingresso selezione | AI27; HIGH=0 | input16/32 coerenti e input64 con HIGH zero/nonzero; esito falso della guardia interno pendente |
| 55, AND riduzione64 | AI27; accorciabile64 | tutti gli half espansi64, zero/inf/NaN, solo32/solo64, input16/32 |
| 57, AND riduzione32 | AI26; accorciabile32 | half espansi32, riduzione64→32→16, 64→32 mantenuto, input16 e64 mantenuti |
| 59, OR uscita selezione | AI27; HIGH=0 | forme16/32 a HIGH zero e64 mantenuti; esito falso della guardia interno pendente |

L'AI `(member 25 26 27)` è un descrittore di tipo, non un AND/OR eseguibile.
Il confronto concatenato alla riga14 esprime due relazioni, quello alla
riga81 tre; sono predicati primitivi espliciti e restano da confrontare
con la copertura grezza. COND dei riduttori conserva il ramo finale
invariant-violation; CASE parole conserva AI25/26/27 e OTHERWISE interno.
Questa tabella non dimostra MC/DC né rende lecite esclusioni delle guardie.

## Provenienza e riesame del corpus

Il metodo precede il corpus; i tre file sono stati scritti senza leggere
i nuovi sorgenti e congelati prima che il coordinatore scrivesse il
prodotto. La preparazione ha letto le forme dei test fino a EOF e
controllato aritmetica di fixture e sink in un processo Common Lisp
isolato, senza chiamare o compilare il prodotto. Questa seconda lettura
ha ricontrollato i blob, senza modificare il corpus.

| File cieco | Blob Git | SHA-256 |
|---|---|---|
| `tests/codec/cbor-float-write-support.lisp` | `6ba7c20701b60789d92ff232fc02b0f476334911` | `158f18dcf4b2d7e5562713caa3625aeba16dd1eba21f4413345e8a10b616c748` |
| `tests/codec/cbor-float-write.lisp` | `747cd8a72445a3ea638cd1910bc9faa63f4cdc33` | `2d163a64bff4b9d9b9de576c4a4df05f4d8853f1c3d039e790cbb827be98c8b6` |
| `tests/codec/cbor-float-write-threads.lisp` | `f95bf450148fa2aab9bb28c178b986dee049de6e` | `96a1b205c01f75e271684132ff3e48b4da5cf8a01210257b591ec4951f097043` |

I 17 test seriali prevedono tutti i 65.536 half e le espansioni32/64,
196.608 successi; ogni half prova capacità 0/1/2, ruotando gli input
25/26/27, per 196.608 rifiuti. Otto offset e tre configurazioni di
capacità esatta/residua/coda sono ruotati nell'esaustivo, non incrociati
integralmente. Le 278 fixture letterali/di bordo eseguono invece tutti
gli otto offset, tre configurazioni e ogni capacità sotto SIZE, comprese
forme32/64 mantenute. Vi sono controlli razionali dell'oracolo, NaN
allineati/non allineati, segni, soglie e adiacenze, attraversamento delle
parole nei subnormali64, precedenze multi-invalid, arità, backing
displaced/fill-pointer, riuso e concatenazione di 38 byte.

Il fuzz di 2.048 casi usa seed `464C5434` e categorie prefissate: 768 successi,
256 capacità, 128 AI, 128 HIGH, 128 LOW, 256 parole e 384 range/destinazioni.
Byte attesi e condizioni non vengono ricavati da decoder o writer.
Lettore/scanner sono controlli supplementari dopo il confronto freddo.

Il 18° test prevede due worker, due ondate per worker da 8.192 chiamate,
32.768 totali. Ogni piano ha otto input16/32/64 con riduzioni e forme
mantenute, ripetuti 1.024 volte per ondata. Prima di ciascuna chiamata
il buffer privato è ripristinato dalle sentinelle; sono verificati
un solo NEXT, tutti i byte e sink 2.115.584/2.148.352 per ondata.
Snapshot annidati dei piani e delle sentinelle sono confrontati dal padre,
insieme ai buffer finali. READY/GO/DONE sono distinti fra ondate, quindi
un worker veloce non può consumare il permesso GO dell'altra ondata.
Attese entro 15 secondi, join entro 20, cleanup limitato con cessazione
verificata. Gli intervalli comprendono ripristino e confronti dei test;
non misurano soltanto la primitiva né simultaneità sui core.

## Altri riscontri e verifiche pendenti

Blob esaminati: package `bc701cf1f21d4fc218e7ab1d44a5f68240cba24a`,
ASDF `fac53c00bd4c8809437ec86dae3bff35d25f23ac`, coverage
`6262967597ab1c0c142ce1a988ec2ecf49543865`, catalogo requisiti
`145d43eb1a68e851de602dc87a60d77c8703c100` e matrice
`70c15b290ccd686e550392fff60ba8ef9796e47d`.
Le dipendenze IEEE `ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f`,
helper BE `61f0d6e2783e4790ed7e19a45bba6407d6e5b3de` e condizioni
`edbe5eaa88c50dc13af8e367b73f7f41fd7bd724` mantengono i limiti delle
loro qualifiche precedenti.

Questa lettura non ha eseguito compilazione, load del prodotto, test,
benchmark, coverage o mutazioni. Rimangono necessari campagne registrate
con sorgenti/indice/HEAD stabili, self-test dei driver, letture dei dati,
copertura completa senza esclusioni e regressioni globali prima del push.
