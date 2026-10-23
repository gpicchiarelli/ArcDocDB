# CONTROL: metodo preregistrato della verifica di transizione C4

Stesura per il freeze del 2026-10-14. Questo documento registra il metodo,
senza risultati. Il sottoincarico scrive esclusivamente questo file e
`tools/control-transition-bench.lisp` nel worktree
`/Users/gpicchiarelli/.codex/worktrees/control-transizione/ArcDocDB`.
Compilazione, self-test e benchmark spettano al coordinatore dopo il freeze,
in processi registrati da `tools/record-command.lisp`. Il primo errore,
stdout/stderr e l'actual exit vanno conservati anche per tentativi falliti.

## Domanda e campione fissato

Si misura `arcdocdb.recovery.manifest:verifica-transizione-recovery` su coppie
valide di manifest completi, immutabili e posseduti dal singolo worker.
Le dimensioni del manifest precedente sono CLOSED C = 0, 16, 256 ed esiti
per CLOSED O = 0, 4. REMOVED R è deterministico: 0 se C=0, 4 altrimenti.
I regimi sono `:fixnum` e `:high-u64`; versioni di decodifica 1 e 2;
worker W = 1, 2, 4; tre repliche per cella.

La matrice è quindi `2 × 3 × 2 × 2 × 3 × 3 = 216` finestre, con 504
record di worker complessivi. L'ordine è versione, CLOSED, esiti, REMOVED
derivato, regime, worker, replica. Le finestre sono seriali tra loro.
C=0 rende O ininfluente alla traversata: le due celle restano nel campione
fissato. Nessuna calibrazione o selezione di finestre in base ai risultati.

## Manifest reali e oracoli indipendenti

Il caricamento iniziale usa ASDF `load-system "arcdocdb/tests" :force t`, con
cache FASL privata sotto la root nuova. Registra le definizioni dei test e
le fixture; non invoca `test-op` o alcun `run`. L'unico helper dei test
richiamato dal driver è `manifest-log-fixture`, da
`tests/recovery/manifest-support.lisp`, soltanto durante il build, prima del
clock. Il suo packing bytewise e CRC bitwise costruiscono EDIT completo e
SEAL in memoria. La ricostruzione chiama direttamente l'API pubblica
`ricostruisci-manifest`, con versione, EOF e budget espliciti: richiede
prefisso consumato esattamente e stato `:complete`. Non costruisce strutture
private del prodotto o mock del guard.

I fatti dell'oracolo sono liste dichiarate dal driver, senza query usate per
dedurre i valori attesi. Per ogni identità logica Serie S, unica tra tutte
le finestre e i worker, `base = 1024*S`, aggiungendo `2^63` nel regime alto.
CLOSED ha ID `base+1 … base+C`, valid-bytes ciclici 64/128/192/256;
REMOVED, quando presente, ha ID `base+513 … base+516`. Il precedente ACTIVE
è `base+768`, next-id ACTIVE+1. Il nuovo ACTIVE è esattamente il vecchio+1;
il nuovo next-id è ACTIVE precedente+2. Tutti i CLOSED e REMOVED precedenti
sono conservati e il vecchio ACTIVE diventa CLOSED con 64 byte e quattro
esiti dichiarati. Le sezioni sono disgiunte, senza riuso di ID.

Gli esiti piccoli sono `(0,0), (1,17), (2,0), (3,23)`. Nel regime alto sono
`(0,0), (2^64-1,2^64-1), (2^63,0), (1,2^63)`. TXID/CSN zero e l'intera
parola u64 sono quindi espliciti. Con O=0 gli esiti dei CLOSED precedenti
sono vuoti; quelli del vecchio ACTIVE appena chiuso restano quattro e sono
verificati dall'oracolo, ma non traversati dal guard di conservazione.
Il regime piccolo usa soltanto interi fixnum sul runtime SBCL a 64 bit;
quello alto esercita ID ed esiti bignum. I valid-bytes restano piccoli.

Ogni coppia viene decodificata separatamente; gli oggetti non sono condivisi
tra worker, repliche o finestre. Serie significa qui contesto logico di
ownership identificato da S: il guard non riceve un oggetto controller Serie.
Non si avviano worker del prodotto. Il main costruisce e riscalda gli input,
poi li trasferisce per sole letture al worker; riprende ownership dei raw
solo dopo quiescenza. Nessun contatore condiviso tra worker.

Prima e dopo la misura, query pubbliche confrontano ACTIVE, next-id, conteggi,
stati e tutti gli esiti con le liste dichiarate. Si verifica anche assenza
TXID 42, distinguendola dal CSN zero presente, e il segmento sconosciuto 0.
L'oracolo a liste verifica cardinalità, conservazione e ACTIVE+1. Il payload
massimo del nuovo snapshot è 21.644 byte; con EDIT e SEAL la fixture è
21.724 byte, entro il budget di 65.536. Le fixture restano in memoria.

## Conteggi e formule preregistrate

Per una chiamata valida, la versione congelata del guard esegue due
verifiche di forma, ciascuna con un lookup del vecchio ACTIVE; visita C
CLOSED, C*O esiti e R REMOVED. Le unità di lookup logico pubblico sono:

```text
L = 2 + C*(1+O) + R
n = ceil(10000 / (W*L))                 ripetizioni per worker
N = W*n                               guard richiesti nella finestra
10000 <= N*L < 10000 + W*L
```

Il numero massimo di ripetizioni per worker è 5.000. Non si adatta n alla
durata osservata. `attempted` cresce appena prima della chiamata;
`completed` soltanto dopo il ritorno. `verify0` conta ritorni NIL,
`nonempty` ritorni diversi da NIL. Il sink somma gli ordinali delle chiamate
completate: con K ritorni vale `K*(K+1)/2`, positivo per K>0.

Per ogni finestra i conteggi derivano dai cicli effettivamente completati,
con `K = sum(completed dei worker)`: guard K, verifiche forma 2K,
CLOSED C*K, REMOVED R*K, lookup segmento `(2+C+R)*K`, lookup esiti `C*O*K`,
lookup logici totali L*K. Non sono contatori strumentati di GETHASH interni.
I tentativi che lanciano un errore possono aver eseguito un prefisso della
traversata: quel lavoro non viene imputato alle unità dei ritorni completati.
Un errore, un ritorno non NIL o un oracolo discordante invalida la finestra.

Per finestre valide, throughput aggregato guard = K/(wall-ns/1e9), e
throughput delle unità logiche = K*L/(wall-ns/1e9). Costo interno del worker
i = cpu-ns_i/completed_i oppure wall-ns_i/completed_i. Le tre repliche
restano raw: eventuali riepiloghi devono mantenere distinta ciascuna cella.

## Clock, scope e budget

Ogni worker ha 32 chiamate di warmup sul main prima della misura, senza
includerle in attempted/completed. Un GC completo precede ogni finestra.
Build, decodifica, warmup, GC, oracoli, hash e persistenza sono esclusi dal
clock misurato. Dentro il ciclo: solo guard, contatori, sink e controlli
cooperativi ogni 32 passi, più il controllo finale della deadline.

`clock_gettime(CLOCK_MONOTONIC)` fornisce nanosecondi wall; il ciclo del
worker usa separatamente `CLOCK_THREAD_CPUTIME_ID`. Il driver dichiara ABI
timespec a 64 bit e ID clock Darwin 6/16, Linux 1/3; altri runtime sono
rifiutati. La finestra interna include overhead del ciclo e dei controlli.
La CPU è del thread corrente, non del processo intero, e le CPU dei worker
non vanno sommate come durata wall. Le due versioni di record influenzano
soltanto la decodifica esclusa dal clock: il guard non riceve una versione.

Con W=1 il main esegue direttamente il worker. Con W>1 il wall aggregato
include creazione dei thread, gate ready/start, chiamate e join. Gate,
semafori stop ed entry point sono preparati prima del clock; la misura
interna del worker esclude avvio e join. `sb-ext:get-bytes-consed` registra
la differenza dell'intero processo nella finestra aggregata, compresi
coordinamento ed eventuali errori. Non è heap vivo, RSS o allocazione per
thread. Nessuna conclusione zero allocazioni o allocazioni garantite.

La deadline cooperativa è 30 secondi per finestra, a partire dal setup,
limitata dalla deadline di campagna di 180 secondi. Quest'ultima include
caricamento, build, warmup, oracoli, hash, join e finalizzazione. Le attese
dei gate e join usano il tempo residuo della medesima deadline; nessuna
estensione per cleanup. Un fallimento interrompe la campagna e conserva il
prefisso completato. Non si usa terminate-thread, timeout asincrono o retry
del carico. Letture, compilatore e processi SHA possono bloccare oltre un
checkpoint: il coordinatore deve supervisionare esternamente il processo;
il budget cooperativo non è un limite duro OS.

Se tutti i thread sono quiescenti, il main può leggere i raw e finalizzare
il report. Altrimenti conserva soltanto osservazioni già proprie, senza
leggere raw vivi o rilasciare fixture. Emette su stdout stato e diagnostiche
del main, con contatori `:unavailable`, senza persistere una fotografia
concorrente. Un errore già osservato dal main conserva `:failed` e exit 1;
un timeout senza errore noto conserva `:incomplete` e exit 2. L'evidenza
rimane nel recorder esterno. In un gruppo quiescente anche un errore del
worker prevale sui timeout. Soltanto una campagna completa e coerente ha
stato `:ok` ed exit 0.

## Evidenza, helper congelato e dimensione

La CLI accetta esattamente `--self-test`, oppure
`--bench --output spikes/out/control-transition-bench-X/`, con X di 1…64
caratteri ASCII alfanumerici, trattino o underscore. Il checkout deriva
dalla posizione del driver, senza cwd ereditato. LSTAT verifica gli antenati;
mkdir 0700 della root è esclusivo, EEXIST fallisce. Nessuna cancellazione
automatica. L'ownership del namespace richiede assenza di sostituzioni
esterne degli antenati durante il run.

Prima di compilare l'helper, il driver copia i byte di
`tools/evidence-storage.lisp` in `evidence-storage-source.lisp` nella root
privata, con EOF e dimensione verificati. Carica esclusivamente questa copia una sola volta sotto handler: SBCL
compila le definizioni durante LOAD. Questo evita la doppia definizione delle
macro causata da COMPILE-FILE seguito da LOAD nello stesso processo; i FASL
del prodotto restano nella cache privata. Dopo il caricamento usa il medesimo
`arcdocdb.evidence:file-sha256` canonico per attestare SHA della copia uguale
allo SHA dell'originale nello snapshot prima del load ASDF. Dopo la campagna
confronta ancora copia e originale nello snapshot finale, e SHA della copia
prima/dopo. Nessun nuovo algoritmo o lettore di hash. Il primo snapshot
dell'helper è dunque la copia fatta prima della compilazione; la sua
identificazione SHA avviene dopo il caricamento. Il normale snapshot blob
del recorder esterno precede l'intero comando, inclusa questa copia e il
load del driver. I due livelli hanno scope diversi e dichiarati.

Gli snapshot canonici comprendono tutti i `.lisp` di src e tests, ASDF,
driver, metodo e helper. Il walk cold rifiuta profondità oltre 32, oltre
4.096 file (inclusi i quattro espliciti e gli eventuali file non Lisp
incontrati) o oltre 4.096 directory. Gli SHA non sorvegliano continuamente le letture.
Il bootstrap rilegge il driver una sola volta sotto handler (massimo due
LOAD totali), così anche gli avvisi delle definizioni compilate dal loader
sono fatali prima di MAIN. Il polling dello stop usa TRY-SEMAPHORE, senza
un timeout zero non ammesso dal contratto SBCL. Warning e style-warning sono fatali; l'unica eccezione durante il load ASDF
è `SB-KERNEL:REDEFINITION-WARNING`, registrata con conteggio totale e prime
16 diagnostiche nel report, tutte su stderr. L'helper non ha tale eccezione.
Non si aggiungono dipendenze Lisp esterne; il lettore canonico esistente
invoca `shasum` fuori clock, conservando i suoi limiti operativi.

`report.lisp` è una PLIST schema 1 di soli dati, scritta senza pretty print,
con massimo 1.048.576 byte UTF-8, rinominata e riletta dal lettore comune
con read-eval disabilitato. `report.sha256` identifica il file canonico.
Ogni finestra conserva cella, ripetizioni, clock, bytes-consed, operation
counts, stato, oracolo e riepiloghi dei worker; nessun elenco per chiamata,
payload o dataset di fixture sul filesystem. I raw parziali non sono misure
valide di una finestra completa. Se l'helper non è stato attestato o la
persistenza fallisce, stderr/stdout e actual exit del recorder sono
necessari. Un superamento tardivo del budget invalida anche un report appena
scritto come `:ok`; il file e il digest vengono aggiornati a `:incomplete`.

La valutazione statica sul checkout durante la stesura conta 360 path Lisp
src/tests e 10.345 byte nel loro elenco con newline, più quattro file
espliciti. Per la matrice ridotta si riservano 640 byte per ciascuno dei
504 record worker senza diagnostica, 512 byte per ciascuna delle 216
finestre oltre ai worker, 96 KiB ai due snapshot sorgente, 40 KiB ai warning,
16 KiB alle diagnostiche del singolo tentativo terminale e 8 KiB alla
radice: complessivamente meno di 608 KiB. Le diagnostiche sono limitate a
512 caratteri; la riserva considera escaping e UTF-8 fino a quattro byte
per carattere. È un dimensionamento statico, non una serializzazione
eseguita; il controllo reale del limite resta vincolante dopo freeze.

## Suite pura e invocazioni dopo freeze

`--self-test` non carica prodotto, ASDF/tests o helper, non crea worker,
fixture filesystem o benchmark. Usa solamente dati propri per matrice
esatta 216, target e formule, oracolo a liste, mutazioni di CSN zero e
REMOVED, contatori/sink, campioni parziali, errori prima dei timeout,
nonquiescenza con errore noto del main, worker/Serie duplicati, campi mancanti,
argv e namespace letterale, e roundtrip PLIST in memoria. Emette una sola
PLIST su stdout. SB-POSIX è un modulo del runtime, non il prodotto.

Comandi previsti dal checkout congelato, ciascuno in un processo distinto:

```sh
sbcl --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --no-userinit --no-sysinit --script tools/control-transition-bench.lisp --self-test
sbcl --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --no-userinit --no-sysinit --script tools/control-transition-bench.lisp \
  --bench --output spikes/out/control-transition-bench-FROZEN-A/
```

Non sono state eseguite compilazioni, Lisp, self-test o benchmark durante
la stesura. Restano alla qualifica centrale il primo eventuale errore del
compilatore, arità/load delle fixture, disponibilità dei clock nativi e del
lettore SHA, dimensione serializzata e completamento entro i budget.
Il campione non copre REMOVED=4 con CLOSED=0 o REMOVED=0 con CLOSED>0,
transizioni invalide/esaurimento ID, manifest concorrenti mutabili, più di
quattro worker, distribuzioni di latenza, p99, storage pipeline o recovery
da crash. Cache e carico esterno non sono controllati. Nessuna soglia
prestazionale e nessuna promozione dei prefissi parziali a campagna completa.
