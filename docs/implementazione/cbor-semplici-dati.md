# Scrittura dei valori semplici CBOR — lettura indipendente dei dati

Questa copia pubblica la lettura originaria, blob
`19c968cf4aab940c19b8e22e0b1d2c5ef53d1818`. Il testo conserva lo stato
delle verifiche al momento della lettura; gli esiti successivi sono nel
[resoconto delle campagne](cbor-semplici-risultati.md).
L'[originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-simple-write-final/raw/readings/data-review-draft.md.txt)
è conservato senza modifiche nel supplemento finale.

Lettura definitiva ignorata del 2026-10-11. Confronta i record completi
del preliminare, benchmark, self-test, mutazioni, coverage e audit con il
corpus congelato. I riscontri locali sono coerenti; MAKE CHECK completo
dopo la raccolta resta pendente. Nessun file tracciato è stato scritto
durante questa lettura; prodotto e test non sono stati caricati o chiamati
dai lettori dei dati.

## Metodo e provenienza

I record sono stati letti integralmente come dati tramite
`tools/evidence-storage.lisp`, blob
`fa2b5d36dca0837e2ed5e49b282887b2e110b2b7`. Il reader accetta una sola
plist con chiavi keyword e READ-EVAL NIL; un eventuale descriptor viene
verificato ed espanso tramite il medesimo strumento. I report benchmark
incorporati in STDOUT sono stati letti come una sola forma con READ-EVAL
NIL ed EOF finale. Non sono stati valutati dati del report.

| Record | Stato/exit | Secondi | Byte originali | SHA-256 dei byte originali |
|---|---|---:|---:|---|
| `spikes/out/4000713780-command-17360-0/report.lisp` | OK / 0 | 22.106124 | 695896 | d7a184fe1d77302fd0484f43f8e028264d327b2208d22eb7e9d2e7b5ea9e5428 |
| `spikes/out/4000713808-command-19171-0/report.lisp` | OK / 0 | 1.2138 | 183455 | 49e218bbe4a9eee8f137c381755929cab53c4cf298bb7df73a019ea0b7467e02 |
| `spikes/out/4000713806-command-19078-0/report.lisp` | OK / 0 | 0.898278 | 175469 | 9bbfcbbf3c198d87318f5b63db01416d2c2155c64edcf10b0bfae06f22695498 |

Tutti e tre registrano commit
`0865b2c3eaca5a0ea8a29b2de0f8e3d283ba2952`, working tree vuoto,
SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, memoria 17.179.869.184 byte,
10 CPU logiche e carico esterno non controllato. I 685 elementi
SOURCE-BLOBS-BEFORE/AFTER sono stati confrontati integralmente e sono
uguali, oltre al campo SOURCE-CONSISTENCY STABLE. Nel benchmark e nel
self-test sono uguali anche i 152 fingerprint MD5 interni del driver.
Questi confronti provano stabilità dell'inventario dichiarato, senza
attestare autenticità o un inventario chiuso dell'intero filesystem.

Nei due snapshot di ciascun record, e nei file correnti, coincidono:

| File congelato | Blob |
|---|---|
| `src/codec/cbor-simple-write.lisp` | 58c7a3a040ec814fae2dfe636f569b5623cba8f0 |
| `tests/codec/cbor-simple-write-support.lisp` | 10979b4a89af0b00d48abbc7bf6760afc3b5aa9b |
| `tests/codec/cbor-simple-write.lisp` | efaa31b8ea2d74af162fd00a3b4e923ae5f60cdd |
| `tests/codec/cbor-simple-write-threads.lisp` | a7bee65793fc3a3e0c89c9c73871d7c183669a3e |
| `tests/codec/cbor-string-write-support.lisp`, dopo fix delle ondate | 5a7f38de22be659787305441b65c689de4bd6dba |
| `tests/codec/cbor-string-write-threads.lisp`, dopo fix delle ondate | 43c4b1ffe8c3dee1a37e9f7b07f655ec3959896b |

Il documento statico conserva il blob
`46a0480b0bc29938f8654ce8f59cdaee5b720a4a`. I tre nuovi test mantengono
gli hash comunicati prima della scrittura del prodotto. Le copie prima/
dopo e il diff del precedente harness sono conservati in
`worker-protocol-fix/`; i vecchi archivi non sono stati riscritti.

## Preliminare: suite completa, compilazione, lint e trace

Il comando registrato è `make test lint trace`. STDOUT contiene 149.884
caratteri, STDERR 403.878. Le righe che iniziano esattamente con `ok    `
sono **854**, tutte distinte e senza duplicati: **852 test nominali e due
smoke**, `package ARCDOCDB presente` e `ARCDOCDB:*VERSION* è una stringa`.
La somma indipendente dei conteggi delle 23 suite è 852:

| Suite | Test nominali |
|---|---:|
| XXH64 | 28 |
| Fondazioni | 28 |
| UTF-8 | 17 |
| Header CBOR | 17 |
| Header minimo | 15 |
| Struttura CBOR | 24 |
| Struttura minima | 22 |
| Header writer | 17 |
| String writer | 21 |
| Simple writer | 16 |
| Registro CSN | 20 |
| MVCC snapshot/CSN | 43 |
| Epoche/reclaim | 34 |
| Compiti di lettura | 30 |
| Contratto GET benchmark | 19 |
| Code writer/execution | 89 |
| Metadati storage | 44 |
| I/O | 18 |
| Recovery | 95 |
| WAL | 48 |
| Controller Serie | 70 |
| Slot indice v2 | 64 |
| Indice primario | 73 |

I nomi dei 16 test congelati sono stati confrontati con le righe OK:
presenti tutti una volta. Questo include letterali, dominio esaustivo,
tutte le capacità, riservati, tipi/range, non-simple e backing displaced,
vuoti, estremo fisico, riuso, concatenazione, arità, fuzz, supplementi
reader/scanner e due worker. I conteggi interni 5.952 confronti esaustivi,
3.776 capacità insufficienti e 256 riservati sono asseriti dai test
congelati che risultano OK; non sono conteggi ricostruiti dal numero di
righe del log. Il fuzz registra esplicitamente seed 53494D43 e 2.048 casi:
768 successi, 512 valori invalidi, 256 capacità insufficienti e 512
destinazioni/range invalidi, come preregistrato.

Il build forza la ricompilazione del prodotto con WARNING e STYLE-WARNING
fatali; la sola eccezione nel handler sono gli avvisi di ridefinizione
ASDF. Nel record non compaiono `caught WARNING`, `caught STYLE-WARNING`,
`WARNING:`, `STYLE-WARNING:` o `Unhandled` in STDERR. Sono registrate
180 note di compilazione del prodotto e 612 dei test, distinte dagli
avvisi. Il marker finale riporta build/test senza avvisi. Lint: **150
file, zero violazioni**. Trace: **117 requisiti, 65 invarianti, 13 scenari
FI, 52 ADR, zero errori**. MAKE CHECK completo resta separato e pendente.

## Due ondate e controllo del precedente harness

Il test congelato usa due worker reali riusati, destinazioni private e
piani di otto item preparati prima dell'avvio. Sono 8.192 chiamate per
worker/ondata: 16.384 per ondata e **32.768 complessive**. Ogni chiamata
ripristina le sentinelle fredde e confronta arità uno, NEXT fixnum e
array fisico completo. Il padre confronta anche piano, sentinelle,
array finale, sink, intervalli e join; semafori distinti per ondata,
attese 15 s, join 20 s e cleanup limitato con terminazione verificata.

Il sink viene dai byte effettivi e NEXT; il risultato freddo del piano
è 3.715/3.747 per giro di otto item, moltiplicato per 1.024. Il log
registra **3.804.160 / 3.836.928** in entrambe le ondate, con overlap
**2.098 e 2.077 tick**, frequenza 1.000.000 tick/s. Questi sono intervalli
della fixture, comprendenti ripristino e confronti; non provano
simultaneità sui core, scaling o tempo isolato della primitiva.

Il vecchio corpus stringhe corretto passa anch'esso nella medesima suite:
due ondate di 16.384 item, sink **9.707.520 / 9.969.664** per ondata,
overlap **48.278 e 48.460 tick**. I blob support/thread corrispondono al
fix dei soli semafori, prima e dopo il comando. I risultati precedenti
rimangono storici; questi sono i riscontri del protocollo corretto.

## Benchmark seriale e sensori

Driver esaminato in sola lettura, blob
`07e5b0b7773f95ddae9458267b285c0ccb24dba9`. Il report contiene sei fixture
0/20/22/23/32/255, ciascuna con **cinque campioni**, 4.096 chiamate e
warmup 128: **30 campioni, 122.880 chiamate misurate**. Heap osservato
**zero in tutti i 30 campioni**. Status OK sia nel wrapper sia nel
report interno. STDERR del benchmark e del self-test è vuoto.

Gli expected sono stati ricontrollati senza chiamare il prodotto:
wire 224+VALUE oppure 248/VALUE; START=2; NEXT=2+dimensione;
END=NEXT+2; due sentinelle 165 prima e quattro dopo il wire, di cui
due oltre END. Tutto l'array atteso, non solo il wire, coincide nei
report. COLD-VALUES è esattamente la lista del singolo NEXT per ogni
fixture. Token indipendente = NEXT + somma BYTE[i]×(i+1) sull'intero
array. Sink = 4.096×TOKEN + 4.096×4.095/2. Tutti i 30 sink, token,
conteggi, heap, RAW-TICKS/SECONDS e CALLS-PER-SECOND sono coerenti.

| VALUE | Wire | NEXT | Token completo | Sink per campione |
|---:|---|---:|---:|---:|
| 0 | E0 | 3 | 4800 | 28047360 |
| 20 | F4 | 3 | 4860 | 28293120 |
| 22 | F6 | 3 | 4866 | 28317696 |
| 23 | F7 | 3 | 4869 | 28329984 |
| 32 | F8 20 | 4 | 5661 | 31574016 |
| 255 | F8 FF | 4 | 6553 | 35227648 |

La somma dei tempi misurati è **22.090 tick = 0,02209 s**, minore della
durata del wrapper 1,2138 s. Ogni tempo è positivo e rapportato alla
frequenza 1.000.000 tick/s. Nessuna soglia di velocità è applicata.

Il self-test separato e quello incluso nel benchmark riportano:

- Baseline 4.096 chiamate, warmup 128: heap 0, token 0,
  sink 8.386.560 coerente con la somma degli indici.
- Sensore positivo 16 allocazioni da 1 MiB, warmup 0: heap osservato
  16.777.472 byte, almeno 16 MiB; token 1.048.576 e sink 16.777.336.
- Output checker: token positivo 5.661, NEXT alterato e cinque
  alterazioni distinte di prefisso/lead/valore/residuo/coda rifiutati.
- Arity checker: un singolo valore accettato, quattro casi di arità
  o NEXT errati rifiutati; sensor checker rifiuta sink errato e heap
  nonzero, entrambi con status OK.

La lettura del driver conferma buffer/expected preallocati, confronto
dell'intero buffer per chiamata, warmup e GC fuori dalle misure, sink
osservabile e baseline/sensore positivo. L'arità esatta del benchmark
è controllata sulla chiamata fredda; il ciclo caldo usa il valore
primario, mentre il corpus funzionale controlla arità su ogni successo.
Il tempo include il checker; sono misure seriali del solo successo con
carico esterno non controllato, senza throughput di pool/dispositivo,
scaling o prova assoluta di assenza di allocazione.

## Audit del benchmark e verificatore dei dati

L'audit benchmark registrato
`spikes/out/4000714388-command-46985-0/report.lisp` è OK/exit 0/STABLE,
1,009074 s, **20.409 controlli**. I byte del wrapper benchmark prima e
dopo l'audit sono identici, 183.455 byte e SHA-256
`49e218bbe4a9eee8f137c381755929cab53c4cf298bb7df73a019ea0b7467e02`.
Il risultato conferma sei celle, 30 campioni, heap zero, arità fredda
uno, baseline zero, controllo positivo 16.777.472 byte, 152 fingerprint
interni, 0,022090000000000002 s di campioni e 0,000064 s di controlli.
La differenza dall'espressione 0,02209 s è la somma floating point.
Il verificatore controlla consistenza dei dati; non carica prodotto o
driver e non prova autenticità o esecuzione. Le impronte attese del
prodotto sono fornite dal chiamante e qui coincidono col freeze cieco.

Il helper distinto di mutazioni/coverage è
`spikes/out/cbor-simple-write-20261011/data-audit.lisp`, blob
`4ca865ddfca6da36a73c81fb5041df4df60d79ab`. Il suo self-test registrato
`spikes/out/4000714391-command-47195-0/report.lisp` è OK/exit 0/STABLE,
1,073152 s, **529 controlli su 27 casi sintetici**. Comprende processi,
catalogo e risultati delle mutazioni, lettore/preambolo, coverage,
chiusura implicita delle righe HTML, associazione delle lacune e
sostituzione unica/ambigua. Il report
`audit-self-test/report.lisp` conserva una osservazione del prodotto
prima/dopo identica; nessuna campagna o prodotto viene eseguito dal
self-test del verificatore.

I sei record successivi a quelli iniziali registrano commit
`7bfd3bf01c753fe6cdf228cdc74533c127e32bad`, working tree vuoto, 685
snapshot prima/dopo uguali e SOURCE-CONSISTENCY STABLE. Metodo, prodotto,
tre file ciechi e precedente harness corretto coincidono col freeze
nei record e nei file correnti. Il cambio di commit conserva il freeze
del prodotto/corpus e comprende la revisione del catalogo mutazioni
prima della campagna; non è un cambiamento durante i comandi.

| Record sotto `spikes/out/` | Secondi | Byte originali | SHA-256 dei byte originali |
|---|---:|---:|---|
| `4000714190-command-35834-0/report.lisp` | 165.36714 | 205648 | 940cb518692cea9c32dd1f372cb20dcb06a96c211447c0ef7a5aef92c264d649 |
| `4000714357-command-44709-0/report.lisp` | 10.309638 | 143512 | e0a78c97970b94febf0881a047cb4249d581cf118d022c829825b614d8dc4a79 |
| `4000714388-command-46985-0/report.lisp` | 1.009074 | 143614 | 8a5877d924feafb5fd573bc920661a30ac425d295487b04098df3366e332c015 |
| `4000714391-command-47195-0/report.lisp` | 1.073152 | 141867 | ad88bc22762608e2dfd911f910d8f1867ba6a030c4fbf0eeca3b2fda7991100d |
| `4000714393-command-47353-0/report.lisp` | 6.516856 | 141997 | 1ab2161173596210de8240858fb56da56f1fccbc2ea8a23b840130a0efef67ef |
| `4000714401-command-47888-0/report.lisp` | 1.613452 | 141993 | be5d11d83c9d70d71db8205dd5c4cbf4de4c46e9adf96741eabfc08cfbe40b5e |

Tutti sono OK/exit 0; STDERR è vuoto. L'audit benchmark registrato usa
`tools/cbor-simple-write-audit.lisp`, esaminato anche in sola lettura,
blob corrente `6acfcc656bfed5f8b4c59e487cffb5325d30d790`.

## Mutazioni: copie, baseline e tutti gli otto log

La campagna `4000714190-command-35834-0` e il report
`mutations/report.lisp` sono OK. Il report finale su disco coincide
integralmente con la forma finale di STDOUT dopo l'unico preambolo
esatto del self-test worker. I 255 fingerprint interni prima/dopo sono
uguali; catalogo ALIGNED sul blob prodotto congelato e otto nomi
preregistrati. Sono **otto rilevati, zero sopravvissuti/invalidi/errori
worker**. Tutti i mutanti hanno exit 1 e SIGNAL NIL.

Il mutatore congelato per la campagna è
`ec2fe6b3235591ec5b3bb82b32046e906b045bf6`. Il target physical-capacity
usa `(max span (- (length bytes) begin))`, conservando l'uso di SPAN:
il difetto è di capacità runtime, senza introdurre un avviso da variabile
inutilizzata. Per extra-return-value, la sostituzione unica del frammento
pubblico aggiorna anche FTYPE nella copia per dichiarare il secondo NIL;
il difetto runtime è l'arità extra, senza farne un errore di compilazione.
Le versioni precedenti e i diff restano conservati separatamente dal
coordinatore in `physical-capacity-revision/`.

L'audit registrato `4000714393-command-47353-0` riporta **15.320 controlli**,
OK, `audit-mutations.lisp` con 36 osservazioni byte/SHA prima/dopo
identiche. La baseline e le otto copie contengono ciascuna **254 file
dell'inventario dichiarato**: baseline identica e ciascuna mutazione
cambia soltanto `src/codec/cbor-simple-write.lisp`, esattamente secondo
la sostituzione unica dichiarata. Runner e cache FASL privati verificati;
il runner della baseline letto usa ASDF output translations verso la
propria directory FASL, IGNORE-INHERITED-CONFIGURATION e la build rigorosa
originale. Questo non è un inventario chiuso delle directory delle copie.

La baseline è stata letta integralmente: **854 OK distinti**, smoke esatto
alla riga 2, completamento esatto alla riga **925**, exit 0, SIGNAL NIL,
nessun Unhandled, warning/style-warning o errore di compilazione. Per
ciascuno degli otto log è stato verificato separatamente che lo smoke
esatto riga 2 precede Unhandled e il backtrace del test REQ-CBR-003:

| Copia / mutazione | Primo Unhandled, riga | Origine osservata nel test congelato |
|---|---:|---|
| 0 / reserved-codes-accepted | 232 | CSW-REJECT, ALL-EIGHT-RESERVED-BEFORE-CAPACITY, VALUE24 e capacità0: classe della condizione diversa da invalid-argument |
| 1 / one-byte-threshold-22 | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE23: NEXT diverso dall'atteso; wire osservato F8 17 invece di F7 |
| 2 / wrong-major | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE0: array diverso, C0 invece di E0 |
| 3 / wrong-extended-lead | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE32: array diverso, F9 20 invece di F8 20 |
| 4 / physical-capacity | 231 | CSW-REJECT, EVERY-INSUFFICIENT-CAPACITY-AND-PHYSICAL-SUFFIX, VALUE0 e capacità0: classe diversa da resource-exhausted |
| 5 / extended-value-zeroed | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE32: array diverso, F8 00 invece di F8 20 |
| 6 / next-one-too-far | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE0: NEXT diverso, byte E0 presente |
| 7 / extra-return-value | 229 | CSW-ACCEPT, LITERAL-VECTORS, VALUE0: LENGTH ACTUAL diverso da1, byte E0 presente |

Ogni log contiene l'asserzione e il frame del proprio test
`ARCDOCDB.CBOR.SIMPLE.WRITE.TESTS::TEST-REQ-CBR-003-...`, senza marker di
completamento. Non compaiono `caught WARNING`, `caught STYLE-WARNING`,
`WARNING:`, `STYLE-WARNING:`, `COMPILE-FILE-ERROR`, `COMPILE-FILE-WARNED`
o `compilation aborted`. Nessun segnale OS o guasto worker è contato
come rilevamento. Le due mutazioni di preflight falliscono sulla classe
della condizione catturata: la lettura del solo difetto con l'input del
backtrace spiega il successivo controllo capacità o guardia interna,
senza inferire un write fuori span dal log.

La funzione pubblica mutata non è un frame attivo quando l'asserzione del
helper fallisce: ha già restituito, oppure il suo errore è stato catturato.
L'attribuzione alla primitiva deriva dal callsite diretto congelato di
CSW-ACCEPT/REJECT, dal solo file prodotto modificato e dagli effetti
osservati coerenti con la sostituzione. Non viene inventato un frame del
prodotto assente dal backtrace.

Il classificatore automatico e il log-check dell'audit ereditato verificano
presenza dei marker e assenza di errori di compilazione, ma non provano
ordine smoke→rifiuto o causalità del rifiuto. Queste proprietà dei nove
log reali sono state controllate qui separatamente; il PASS automatico
non è promosso a una capacità generale del verificatore.

| Log sotto `mutations/` | Byte originali | SHA-256 |
|---|---:|---|
| `baseline/test.log` | 59871 | b45fa4fe6652976ecbc941033db5576fce22c821b4c7982e1f200f5e13314c89 |
| `0/test.log` | 25594 | 2c69ddc9ace30a4c0df6d50279e37c8381f22bd155f632c1d2769923c0d3a3e9 |
| `1/test.log` | 25430 | db6dc67bb2371f77cedfe891f75ab1614825cf74e4f45c1f3ebafa176fd88bea |
| `2/test.log` | 25435 | 1c8fa126dadf4474048a460a568d3aa2ef6e108ab528510a0e44536de5f8b07c |
| `3/test.log` | 25441 | 2c7493a39069a9df9f9e6c7fade52ad7d4cfb42ec847a96ed941c2a67c65009c |
| `4/test.log` | 25534 | ad65161fb400dec9d8df06795591e7e1746a37b8aa98edfc28f69007dd3cca00 |
| `5/test.log` | 25438 | 28f1bd17d9d16b27c21cd827386198c07850cbd26c0e9ad27701f2d3f59577b1 |
| `6/test.log` | 25429 | e6fca97134acb741cd5271679cd4d5b785e4d84fa8675922d98ced9461026183 |
| `7/test.log` | 25332 | aacbaff8c0915f8b5c75dd1976323d9d874fceeab92e96220d6871de848de7b0 |

Il self-test worker incorporato conserva il report
`spikes/out/4000714191-cbor-simple-write-worker-self-test-35886/report.lisp`,
PASSED. I due difetti infrastrutturali deliberati sono worker-error con
DETECTED NIL: SIGKILL exit137/signal9 e fallimento dopo completamento
exit7/signalNIL. Le fixture baseline-copy e baseline-transport sono
PASSED, ciascuna con un worker-error, exit/signal NIL e diagnosi
INFRASTRUCTURE-ERROR. Questi quattro guasti deliberati appartengono ai
self-test, non alle otto mutazioni del prodotto. Il dispatcher registra
due ingressi validi e sei rifiuti prima della creazione delle directory;
missing/ambiguous target, compilazione e marker citati nel backtrace
restano INVALID.

## Coverage: raw, HTML e associazione delle lacune

La campagna `4000714357-command-44709-0` è OK/exit 0/STABLE, 10,309638 s.
Il revisore indipendente dei dati ha letto il raw come singola forma con
READ-EVAL NIL attraverso evidence-storage, senza LOAD del prodotto:
**248 file salvati**, un solo target esatto
`src/codec/cbor-simple-write.lisp`, blob congelato. I **135 path/bit** del
target sono 111 espressioni e 24 esiti di ramo: **95/111 espressioni
coperte (85,6%) e 20/24 esiti di ramo (83,3%)**. Indice e sorgente HTML
riportano gli stessi conteggi; tutte le 53 righe del sorgente HTML
corrispondono al file congelato dopo decodifica entità/NBSP e spazi di
presentazione. Non si confondono i 248 file salvati con l'unico sorgente
nuovo oggetto della campagna.

L'audit registrato `4000714401-command-47888-0` è OK/exit 0/STABLE,
1,613452 s e **1.178 controlli**, `audit-coverage.lisp`. Le cinque
osservazioni byte/SHA prima/dopo sono identiche e corrispondono ai file
letti. Il confronto indipendente raw/HTML/AST conferma tutte le lacune:

- **16 espressioni**: quattro dichiarazioni top-level ai path (0), (1),
  (2), (4), e dodici forme nei tre ERROR interni :cbor-simple-span
  (riga 22), :cbor-simple-target-span (46), :cbor-simple-progress (52).
- **Quattro esiti di ramo**: la guardia span alla riga 21, due esiti
  nell'AND target-span alla riga 45 e la guardia progresso alla riga 51.
- **OTHER=0**: nessun default o parametro scoperto da riclassificare.

Le associazioni sono sintattiche e verificabili sul prodotto congelato,
senza escludere dichiarazioni/errori interni dai denominatori. Non
costituiscono una prova di irraggiungibilità, indipendenza dei predicati,
MC/DC o completezza funzionale; le guardie restano attive e visibili.

| Artefatto sotto `spikes/out/cbor-simple-write-20261011/` | SHA-256 dei byte originali |
|---|---|
| `coverage/coverage-state.lisp` | 370f3694f1361132877df4dca8140e24160f338318d69dc108783f76585da6c8 |
| `coverage/cover-index.html` | f5bbcc1b6dfe30392a712c320ca2fd3b55836cad907d3b61bee00db21b477d58 |
| `coverage/9ae2ab0021850480ee0bbfa07aef40ba.html` | 469e9a0b9e88da57ccbe5cd6a9e20fa4629205324da252d811e61af535f2bfa7 |
| `audit-coverage.lisp` | 28b53b238befbfde84d51ba1fb915a3c68c9e1d28c8285e4a4fc520d1a4228a5 |
| `audit-mutations.lisp` | e0dc3942dedefbe00024317bdd8c76244e5666a1960667c9bf62e7fdf7e9c58d |
| `audit-self-test/report.lisp` | bd8bc14f3e01f854191c4cc2615b60500514cf00a687fd5628ac39c883d0a32d |

Il coordinatore conserva i grandi file ignored anche come descriptor
più gzip senza perdita. Le impronte sopra riguardano i byte originali:
la variazione della rappresentazione fisica non cambia il contenuto
logico letto con evidence-storage e non riscrive le campagne storiche.

## Tentativi errati dei lettori ad hoc

È conservata qui la diagnostica disponibile di un tentativo inline
errato, distinto dai comandi registrati del prodotto e dai verificatori.
Il frammento tentava di riunire i controlli freeze/benchmark/conteggi
in un unico DOLIST su STDIN e aveva una parentesi di chiusura mancante.
Non è stato caricato o eseguito prodotto/test; l'errore è del lettore
ad hoc. Nessun output mancante è ricostruito.

Tool chunk `b6c9c7`, exit 1, wall 0.178726959 s, estratto originale:

```text
Unhandled SB-C::INPUT-ERROR-IN-LOAD in thread #<SB-THREAD:THREAD tid=259 "main thread" RUNNING
                                                 {80086A0423}>:
  READ error during LOAD:

    end of file on #<SB-SYS:FD-STREAM for "file /dev/stdin" {8008680043}>

    (in form starting at line: 13, column: 96, file-position: 813)
```

La correzione ha separato i controlli in due letture più brevi:
chunk `f12a33`, exit 0, controlli snapshot/freeze, 854 OK distinti,
852 nominali e tutti i 16 nomi; chunk `a43a7b`, exit 0, byte freddi,
30 campioni, tempi e sensori. Sono verifiche dei dati, non nuove
campagne runtime né self-test registrati dei driver.

Durante la lettura delle mutazioni un ulteriore tentativo inline aveva
una costante di percorso errata, scritta con `\u002f` come se fosse
un escape JSON dentro una stringa Common Lisp. Estratto disponibile
chunk `621acd`, exit 1, wall 0.200004583 s:

```text
The assertion
(EQUAL (GETF (GETF DATA :SELF-TEST) :SIGNAL-FIXTURE-REPORT)
       "u002fUsers/gpicchiarelli/.codex/worktrees/cbor-simple-write/ArcDocDB/spikes/out/4000714191-cbor-simple-write-worker-self-test-35886/report.lisp")
failed with (GETF (GETF DATA :SELF-TEST) :SIGNAL-FIXTURE-REPORT) =
"/Users/gpicchiarelli/.codex/worktrees/cbor-simple-write/ArcDocDB/spikes/out/4000714191-cbor-simple-write-worker-self-test-35886/report.lisp".
```

Il frammento sbagliato era il confronto del percorso con la costante
`"\u002fUsers/..."`. Il retry `c76a28`, exit0, confronta il preambolo
direttamente con il percorso realmente contenuto nel report: forma
STDOUT/report finale uguale, 255 fingerprint uguali e fixture dei guasti
baseline correttamente classificate. Nessun dato è stato modificato.

Il revisore coverage ha comunicato anche tre tentativi errati del proprio
reader, con i frammenti/diagnostiche originali disponibili:

| Chunk / exit / wall | Errore del reader e frammento effettivo | Correzione riuscita |
|---|---|---|
| `fab4e0` / 1 / 0.379981959 s | `READ error during LOAD: unmatched close parenthesis. Line: 17, Column: 140, File-Position: 1428.` Il FORMAT finale del LET aveva una chiusura extra: `(format t "~&HELPER PATH ~A ~D bytes SHA ~A~%~S~%" path (arcdocdb.evidence:file-bytes path) (arcdocdb.evidence:file-sha256 path) data)))`. Wrapper e helper erano già letti e stampati. | Letture successive separate completate; nessuna ripetizione del fallimento. |
| `18cee0` / 1 / 0.30530525 s | `The value #*000 is not of type LIST`. Il reader usava `(subseq (first data) 0 (min 5 (length (first data))))` su una entry SB-COVER dotted; frame disponibile `(LENGTH ("/Users/gpicchiarelli/.codex/worktrees/cbor-simple-write/ArcDocDB/src/package.lisp" #((0) (1) (2)) . #*000))`. | `abe41d`, exit0: CAR/CADR/CDDR, senza assumere lista propria. |
| `94014c` / 1 / 0.564907917 s | `The assertion (EQUAL SOURCE-LINES HTML-LINES) failed`. Frammento `(assert (equal source-lines html-lines))`; il testo HTML usava NBSP U+00A0, assenti dal sorgente. | `109a71`, exit0: normalizzazione della sola presentazione e 53 righe uguali. |

Il reader AST/raw `9fe8ab` e quello finale HTML/hash `109a71` terminano
exit0. Questi sono errori dei lettori ad hoc, distinti dai risultati
registrati e dal prodotto. Gli estratti sono parziali e non ricostruiscono
output mancanti; nessun nuovo guasto è stato deliberatamente rieseguito
per produrre un log sostitutivo.

## Pendenti e limiti

I dati disponibili sono coerenti col corpus cieco e con il contratto
locale. MAKE CHECK completo dopo la raccolta resta pendente. Stabilità
dei fingerprint, associazione sintattica delle lacune, inventario delle
copie dichiarato e classificazione automatica conservano i limiti sopra.
Questa lettura non chiude gate C1, non rinnova qualifiche delle dipendenze,
non attesta MC/DC o autenticità dei report e non è un'approvazione umana.
