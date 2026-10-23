# Prima lettura C1 della composizione dei tag CBOR

Lettura statica del 2026-10-14 **prima della prima compilazione**, effettuata
da un revisore distinto dall'autore del prodotto. Nessun LOAD/EVAL, compile,
suite, benchmark, mutazione o campagna eseguito durante questa lettura.
Il corpus è stato congelato prima dei nuovi sorgenti; piano freddo
`71f0cbd4f4b9e2c180c2fe4dde208fa8d88a6787`.

## Fonti e perimetro

| Fonte | Blob letto |
| --- | --- |
| [cbor-tag-input.lisp](../../src/codec/cbor-tag-input.lisp) | `6dfad07035ac8040b2aec0a455c175ea15dfd9ad` |
| [cbor-tag-write.lisp](../../src/codec/cbor-tag-write.lisp) | `16b91fc27eabafd7ff12bfb0a56ed34208c2bd4b` |
| [Metodo](cbor-tag-metodo.md) | `3175390e496173398781bf8b39170cb33892125f` |
| `tests/codec/cbor-tag-write-support.lisp` | `15978d05251705387205d6468031a701ad95ec85` |
| `tests/codec/cbor-tag-write.lisp` | `df97950ec8d24157bb6566c7995262f7beea7742` |
| `tests/codec/cbor-tag-write-threads.lisp` | `def870295400af2c84ca00e7a9b5cd5b747ec315` |

REQ-CBR-007 deriva da ADR-0014, con ADR-0024/0035/0048 e invarianti
INV-A5, INV-A8, INV-P6. Il prodotto riferisce anche REQ-LIM-001/002 e
REQ-AFF-004/008. È un compositore MT6 strutturale minimo: verifica un solo
contenuto completo ed emette una testata minima con payload identico.
Non attesta semantica dei tag, ammissione documentale o determinismo globale.

## Esito statico e contratto

**Nessun difetto bloccante individuato nei due sorgenti letti.** Sei funzioni
con FTYPE completo, safety3, requisiti e docstring; massimo33 righe e otto
percorsi sintattici nella convenzione riportata sotto. Questa conclusione
statica non anticipa compilazione senza avvisi o risultati delle campagne.

Il preflight rispetta le dieci fasi preregistrate: range destinazione,
range/sorgente vuota, HIGH poi LOW, SPACE/alias, limiti, byte completo,
capacità logica, overlap completo, minimo due nodi e scansione. L'emissione
inizia solo dopo la scansione e tutte le postcondizioni del contenuto.
I rifiuti pubblici avvengono prima di scrivere dati; preflight senza reset,
parsing fallito con scratch sporco ma riusabile secondo lo scanner esistente.

HIGH/LOW restano parole u32 indipendenti. `seleziona-header-cbor` calcola la
dimensione1/2/3/5/9 senza ricomporre un u64; l'emissione passa major6 e le
stesse parole. Prima di sommare la dimensione della testata si verifica
SPAN<=MAX-BYTES<=16MiB. ITEM-SIZE viene poi confrontato col budget e con
END-START: NEXT=START+ITEM-SIZE è entro END già validato, senza usare la
coda fisica come capacità. Le somme sono limitate prima dei cast successivi.

BUFFER/SOURCE uguali a SPACE.KINDS sono rifiutati prima del reset. L'altro
array privato è simple u32 e non può essere uno dei simple u8 già validati.
BUFFER=SOURCE richiede che lo span sorgente non intersechi [START,NEXT),
testata compresa; i confini toccanti sono ammessi. La copia esistente riceve
span sorgente e destinazione della stessa lunghezza e disgiunti. A successo
cambia il solo footprint, conservando lo span SOURCE; su errore pubblico
sono preservati gli interi array fisici, anche quando coincidono.

MAX-NODES1 è una configurazione valida ma insufficiente: il compositore
rifiuta prima dello scanner. Con minimo2 si passa MAX-NODES-1, che è almeno1.
Lo scanner controlla il contenuto esatto e minimo, incluse UTF8 e larghezze
float, e restituisce nodi/picco/NEXT controllati prima dell'emissione.
Il nodo del nuovo tag è incluso nel budget, senza modificare lo scratch:
questo descrive soltanto il contenuto. MAX-DEPTH passa invariato; tag e
catene di tag non consumano frame o livelli array/map. Scalare a profondità0
e contenitore a profondità100 restano possibili entro gli altri budget.

I risultati dei callee sono usati o hanno solo semantica di verifica tramite
condizioni; nessun codice di errore ignorato. La copia restituisce RESULT,
confrontato con NEXT e restituito come unico valore lessicale. Gli invarianti
interni sono condizioni fail-stop senza rollback; la transizione della Serie
al confine runtime resta esterna alla primitiva, che non possiede una Serie.

## Decisioni composte e relazioni numeriche

**Cinque siti AND/OR, 11 operandi**, nessun AND/OR annidato. Le condizioni
sono riportate nell'ordine del corto circuito. I testimoni sono presenti
nel corpus congelato, non risultati eseguiti né prova MC/DC.

| Sito | Operatore e condizioni | Testimone previsto |
| --- | --- | --- |
| input:15, `check-spazio-tag-cbor` | OR: BUFFER EQ SPACE.KINDS; SOURCE EQ SPACE.KINDS | `workspace-type-and-both-kinds-aliases`: due ruoli distinti e caso senza alias |
| input:49, `check-overlap-tag-cbor` | AND: START<NEXT; NEXT<=LENGTH(BUFFER) | precondizioni interne del footprint; esiti non pubblici restano nel denominatore |
| input:51, `check-overlap-tag-cbor` | AND: SOURCE-START<SOURCE-END; SOURCE-END<=LENGTH(SOURCE) | precondizioni interne del contenuto non vuoto; nessuna esclusione |
| input:53, `check-overlap-tag-cbor` | AND: BUFFER EQ SOURCE; START<SOURCE-END; SOURCE-START<NEXT | `overlap-including-only-header-and-touching-boundaries`: array distinti, disgiunti a sinistra/destra, toccanti e overlap testata/payload |
| write:15, `verifica-contenuto-tag-cbor` | AND: START<END; END<=LENGTH(SOURCE) | precondizioni interne del contenuto; controlli pubblici range/empty come testimoni esterni distinti |

I nomi abbreviati indicano `test-REQ-CBR-007-tag-*`. Non si equipara il
test di un rifiuto pubblico al raggiungimento del ramo IV interno che esso
protegge. Questi rami devono rimanere visibili nella copertura grezza.

**Due predicati numerici concatenati, quattro relazioni**:

| Sito | Relazioni ordinate | Proprietà |
| --- | --- | --- |
| write:19 | 2<=MAX-NODES; MAX-NODES<=16MiB | residuo almeno1 prima di sottrarre il nodo tag |
| write:26 | 1<=NODES; NODES<=MAX-NODES-1 | almeno un item e budget effettivo restituito dallo scanner |

Le relazioni concatenate non sono AND/OR scritti nel sorgente e non si
sommano ai percorsi sintattici; restano decisioni semantiche da leggere
condizione per condizione e da confrontare con SB-COVER.

## Inventario di tutte le guardie

**23 siti WHEN/UNLESS: input14 e write9. Nessun nuovo LOOP, IF, COND o CASE.**
IA=INVALID-ARGUMENT, RE=RESOURCE-EXHAUSTED, IV=INVARIANT-VIOLATION.
Tutti gli errori locali hanno offset NIL. Gli errori scanner e UTF8
mantengono il proprio tipo, motivo e offset assoluto SOURCE.

| Funzione | Siti e condizioni → rifiuto |
| --- | --- |
| `check-spazio-tag-cbor` | input:13 SPACE tipo corretto → IA `:cbor-workspace`; input:15 OR alias → IA `:cbor-tag-workspace-alias` |
| `dimensioni-tag-cbor` | input:27 START<=END → IV `:cbor-tag-dimension-range`; input:29 SPAN positivo → IV `:cbor-tag-dimension-empty`; input:31 SPAN>MAX-BYTES e input:36 ITEM-SIZE>MAX-BYTES → RE `:cbor-tag-byte-budget`; input:38 ITEM-SIZE>END-START → RE `:cbor-tag-capacity` |
| `check-overlap-tag-cbor` | input:49 footprint ordinato/non vuoto entro array → IV `:cbor-tag-target-span`; input:51 contenuto ordinato/non vuoto entro array → IV `:cbor-tag-source-span`; input:53 overlap completo → IA `:cbor-tag-overlap` |
| `check-input-tag-cbor` | input:69 SPAN zero → IA `:cbor-tag-source-empty`; input:77 MAX-NODES<2 → RE `:cbor-tag-node-budget`; input:79 SPAN=SOURCE-END-SOURCE-START → IV `:cbor-tag-input-span`; input:81 ITEM-SIZE<=END-START → IV `:cbor-tag-input-capacity` |
| `verifica-contenuto-tag-cbor` | write:15 range non vuoto entro SOURCE → IV `:cbor-tag-child-range`; write:17 SPAN=END-START → IV `:cbor-tag-child-span`; write:19 dominio MAX-NODES → IV `:cbor-tag-child-budget`; write:24 NEXT=END → IV `:cbor-tag-child-progress`; write:26 nodi1..MAX-NODES-1 → IV `:cbor-tag-child-nodes`; write:28 PEAK<=MAX-DEPTH → IV `:cbor-tag-child-depth` |
| `scrivi-tag-cbor-minimo` | write:61 PAYLOAD-START=BEGIN+HEADER-SIZE → IV `:cbor-tag-header-progress`; write:63 NEXT-PAYLOAD-START=SPAN → IV `:cbor-tag-payload-span`; write:66 RESULT=NEXT → IV `:cbor-tag-write-progress` |

Non sono aggiunti ERROR stringa, handler generici, guardie con effetti
collaterali o esclusioni dei rami IV. Le relazioni confrontano input,
capacità e risultati dei callee, non soltanto tipi già dichiarati.
Ogni funzione non banale mantiene almeno due verifiche attive.
Gli errori ereditati dai controlli range, parole, limiti, scanner,
header writer e copia rimangono propagati: l'inventario locale non li
riclassifica né elimina i loro punti dalle rispettive misure.

## Righe e percorsi

Conteggio da DEFUN alla parentesi finale inclusa, comprese docstring e
dichiarazioni. Percorsi: base1 + WHEN/UNLESS + un corto circuito per ogni
operando AND/OR oltre il primo. Nessun nuovo ciclo o altro costrutto di ramo.
Questa convenzione non sostituisce la copertura grezza o MC/DC.

| File/funzione | Righe | Numero righe | Percorsi |
| --- | --- | ---: | ---: |
| input, `check-spazio-tag-cbor` | 9–17 | 9 | 4 |
| input, `dimensioni-tag-cbor` | 22–40 | 19 | 6 |
| input, `check-overlap-tag-cbor` | 45–55 | 11 | 8 |
| input, `check-input-tag-cbor` | 60–83 | 24 | 5 |
| write, `verifica-contenuto-tag-cbor` | 10–30 | 21 | 8 |
| write, `scrivi-tag-cbor-minimo` | 36–68 | 33 | 4 |

## Lista di controllo C1 — dodici punti

1. **Requisiti/ADR:** REQ-CBR-007 e requisiti di limiti/affidabilità sono su
   ciascun DEFUN. Metodo, ADR-0014/0024/0035/0048 e perimetro strutturale coerenti.
2. **Invarianti/testimoni:** INV-A5/A8/P6 identificati; corpus con oracoli
   freddi, sentinelle, limiti, alias, nodi/depth, errore/riuso e worker privati.
   L'esecuzione dei testimoni resta futura.
3. **Errori:** IA/RE/IV tipizzati, precedenze e offset dichiarati; scanner
   propagato invariato. I rifiuti pubblici e la conservazione degli array
   hanno testimoni; guardie IV e relativo contributo alla qualifica restano aperti.
4. **Limiti:** nessun nuovo ciclo/ricorsione/attesa; dipendenze bounded da
   SPAN<=16MiB, nodi e stack fisso102. Header al massimo9 byte e copia lineare.
5. **Heap caldo:** nessun AST, oggetto u64, buffer o struttura creato nel
   nuovo codice; nessuna misura eseguita qui. Benchmark, baseline nulla
   e controllo positivo devono ancora produrre i dati richiesti da COD-30.
6. **Dati verificati:** item completo/minimo controllato prima della prima
   emissione; payload conservato, nessuna semantica applicativa implicitamente aggiunta.
7. **Decisioni:** tutti i5 AND/OR,11 operandi,2 catene/4 relazioni e23 guardie
   inventariati sopra. Nessuna esclusione o copertura integrale dedotta dalla statica.
8. **Proprietà:** destinazione/scratch esclusivi, SOURCE stabile; alias
   respinti prima del reset. Scratch non conserva ownership della sorgente.
9. **Integrazione:** ASDF carica input poi write dopo le dipendenze, support/
   seriale/thread e RUN globale presenti, export presente. Coverage diretto
   esatto sui due file, dispatch, CLI e RUN aggregato codec presenti; self-test
   aggiunge2 positivi e4 negativi (test, fake, child, sorgente map).
   REQ-CBR-007 è implementato, senza :cov o promozione a verificato.
   Al primo passaggio la matrice riportava ancora progettato: segnalato al
   coordinatore per la rigenerazione prima del freeze. Trace/make check non eseguiti qui.
10. **Regole:** FTYPE6/6, safety3, docstring/requisiti, massimo33 righe/8 percorsi;
    nessuna nuova macro, stato globale mutabile, syscall o costrutto vietato.
    Compilazione senza avvisi e lint restano verifiche successive.
11. **Parallelismo:** nessun lock, attesa, thread o scrittura condivisa fra
    Serie nel prodotto. Il corpus pianifica due worker con SOURCE read-only
    e destinazioni/scratch privati; nessuno scaling attestato dalla lettura.
12. **Durabilità:** nessuna pubblicazione/eliminazione durevole o nuovo punto
    di atomicità storage. Errori pubblici prima degli effetti; IV fail-stop
    senza rollback, da gestire al confine della Serie secondo ADR-0033.

Integrazione letta: ASDF `805550e9053aef5671d28a6fdda62c8eee0ab2e2`,
export `f20d93e9a0cd5cc5387a12d1668968e07cf30d89`,
coverage C4 `8e32ee2ba7b758eb5b0cea349ab8b3d53bd9f2c8`.
Il delta coverage è limitato alla selezione/dispatch/CLI/fixture tag e
all'aggiunta del RUN tag nell'aggregato codec; scope precedenti preservati.

Il piano freddo riporta20 nominali,9658 chiamate API,1024 fuzz e8192
composizioni parallele, più116 scansioni di controllo: conteggi statici,
non esiti osservati. Seconda lettura C1, freeze effettivo, compilazione,
campagne, letture DATA e make check integrato devono ancora avvenire.
**REQ-LIM-001/002, qualifica C1 e MC/DC restano aperti.**
