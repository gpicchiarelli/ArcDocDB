# Metodo preregistrato: chiusura WAL con registro CSN

Registrato il 2026-10-09 prima di ogni esecuzione. Strumento C4:
`tools/wal-csn-bench.lisp`; prodotto C1: bridge nel package `arcdocdb.wal`.
REQ-WAL-002, REQ-WAL-005, REQ-WAL-006, REQ-MVC-005, REQ-MVC-008,
REQ-AFF-008, REQ-BEN-001, REQ-BEN-002, REQ-VAL-001.
La compilazione usa safety 3 e tratta warning/style-warning come errori.
Le due letture C1, prove negative, copertura e mutazioni del prodotto sono
responsabilità della campagna del parent; questo sensore non le sostituisce.

## Copertura e mutazioni preregistrate

Il parent esegue l'autoverifica C4, la copertura strumentale di `wal` e
`foundation` e il gate completo `make check` fuori dalle finestre benchmark.
`tools/wal-csn-mutation.lisp` isola quattro mutanti dei test d'integrazione:
omissione del limb alto nello stamp del record; riuso con token pendente;
pubblicazione accettata dopo fault del log; trasferimento del token a un altro
log con lo stesso file-id. Una baseline dei quattro test precede la campagna dei mutanti. Il mutante conta
come kill solo se compila e fallisce una pertinente asserzione d'integrazione:
un errore di compilazione rende la prova invalida, non un kill. Autoverifica,
baseline, output grezzi, fallimenti e copertura restano evidenze separate.

## Isolamento delle campagne e controlli del processo

Copertura e mutanti mappano esplicitamente `**/*.*` dal checkout alla propria
cache privata, dopo il caricamento dell’ASD. Un controllo verifica la destinazione
prima di compilare. L’autoverifica della copertura controlla anche il percorso
ricorsivo. Una mappatura della sola directory radice non garantiva l’isolamento:
la campagna iniziale lo ha rilevato e conserva quel fallimento. Le campagne
successive usano la mappatura verificata. I mutanti scoprono i sorgenti e test
Lisp del checkout integrato; ogni processo riceve una copia completa separata.

## Contratto e ciclo osservato

`sigilla-lotto-con-csn(lotto registro log file-start durable)` assegna un token
solo dopo preflight di forma, offset, capienza, identità e salute del log.
Prima del CSN verifica anche file aperto in append, `written <= file-start` e
budget di trasferimento/file, inclusi i byte futuri pianificati, tramite
`verifica-capienza-append`.
Si applica a segmenti non vuoti. Conserva registro, log, slot e due limb u32
nel lotto prima della sigillatura. I rifiuti prima dell'assegnazione preservano
byte e CSN. Un'interruzione inattesa dopo l'assegnazione richiede fail-stop;
non si presume rollback. L'API manuale e gli stamp prepared restano compatibili.

Il ciclo misurato aggiunge un PUT ordinario, chiude con il bridge, accoda il
lotto al gruppo, chiude il gruppo, esegue write e flush simulati, pubblica
atomicamente un riferimento a un descrittore d'indice preallocato, risolve con
`risolvi-lotto-pubblicato` al livello `:group`, rilascia il gruppo e riusa il
lotto. La pubblicazione è modellata da CAS su uno slot della fixture: è una
precondizione esterna della risoluzione, non un indice del motore completo.
Il callback usa la firma rafforzata
`risolvi-lotto-pubblicato(lotto registro slot high low :group)`: registro e
token atteso sono quelli catturati alla chiusura/lettura, conservati anche nel
descrittore pubblicato. `annulla-csn-lotto(lotto registro slot high low)`
ha lo stesso controllo d'identità. Un evento vecchio dopo riuso o un registro
diverso con token numerico uguale deve essere rifiutato con `:lotto-csn-stale`
prima di ogni mutazione; un doppio completamento risolto resta
`:lotto-csn-not-pending`. Le relative prove negative appartengono al parent.
Lo slot viene ritirato prima del riuso. Non si invoca `annulla-csn-lotto` sul
percorso sano. Busy/full interrompono il campione e conservano le osservazioni;
non ci sono retry nel ciclo né conferme implicite.

Oracoli sempre attivi nel ciclo: successore indipendente a due parole,
token leggibile e pendente dopo chiusura, byte del CSN nel PUT e nel SEAL,
copertura durevole, H uguale al CSN appena risolto, token risolto prima del
riuso e libero dopo il riuso. Alla fine si verificano frontiere del registro,
proprietà rilasciata, conteggi write/flush/pubblicazioni e byte scritti/durevoli.
Nessun u64 alto viene ricostruito nel ciclo. Il file-id massimo u64 viene
preboxed una volta per invocazione, prima delle finestre.

## Fixture e campagne seriali

Capacità primaria del registro 256; lotto da 512 byte con un solo record,
chiave di 16 byte e valore opaco di 64 byte. Gli offset di formato sono letti
dalle costanti del prodotto. Backend, file simulato, log, gruppo, registro,
lotto, buffer e descrittore pubblicato sono costruiti prima del clock.
Warmup di 1024 cicli su fixture separata e GC completo prima della finestra.
Ogni finestra usa una nuova fixture: il carry resta nel lavoro misurato.

Si eseguono prima tutte le campagne seriali, senza sovrapposizioni: cinque
repliche con base `(0, 0)`, poi cinque con base
`(#x80000000, #xfffffff0)`. Nel secondo caso il sedicesimo ciclo misurato
attraversa il carry. File-id `#xffffffffffffffff` in entrambe le campagne.
Ogni campione parte da 20000 cicli. Se dura meno di 20 tick si raddoppia,
al massimo cinque finestre: 20000, 40000, 80000, 160000, 320000.
Si conservano tutti i tentativi, inclusi quelli sotto risoluzione e falliti.
Nessuna soglia di throughput. Regressione seriale: anche un solo byte heap
osservato sul successo rende l'invocazione fallita con exit nonzero.

## Autoverifica del sensore e conservazione delle metriche

Prima delle campagne: finestra vuota da 20000 chiamate, heap esattamente zero;
controllo positivo con 16 array vivi da 1 MiB, almeno 16 MiB osservati.
Queste finestre verificano il contatore, non stimano throughput, e possono
essere sotto risoluzione. Si dimostra inoltre il rifiuto di clock non valido,
heap nonzero quando richiesto zero e metrica mancante.

Tutte le chiavi aggiornate con `getf` esistono prima della misura: nessuna
aggiunta può cambiare la testa di una plist già condivisa. L'autoverifica
conserva un record con metriche impostate attraverso un alias, lo rilegge
con `*read-eval* nil` e controlla identità in memoria e valori persistiti.
Le metriche obbligatorie di ogni successo includono heap, tick, tempo, sink,
lavoro completato e, per le campagne, cicli/s e byte/s. La consegna finale
rilegge anche il rapporto completo e rifiuta campi mancanti/incoerenti.

## Campagna parallela limitata

Dopo i seriali: 1, 2 e 4 worker reali, tre repliche per numerosità, base alta
con carry. Ogni worker possiede registro, file, log, lotto, gruppo, buffer e
slot pubblicato indipendenti; nessun archivio condiviso. Stessi 20000 cicli e
calibrazione limitata a cinque finestre. Warmup, costruzione dei thread e
GC precedono l'apertura della barriera. Deadline della replica 30 secondi,
attese start/ready e join limitate; cleanup e join finale entro 2 secondi
per thread. Non si leggono i campi di thread ancora vivi dopo il cleanup.

Si riportano tentativi busy/full e retry effettivi (sempre zero: fail-first),
esiti per worker, lavoro totale e throughput aggregato calcolato dall'inizio
del primo worker alla fine dell'ultimo. Il contatore heap di SBCL è globale
al processo: le finestre dei worker si sovrappongono e non sono sommabili o
attribuibili al singolo worker. La finestra globale comprende start e join;
i suoi byte possono includere coordinamento del runtime. L'heap parallelo è
osservazionale; il gate zero heap riguarda le finestre seriali di successo.
Si rifiutano metriche mancanti, esiti errati e tempo sotto 20 tick al budget.

## Evidenza e limiti

Rapporti plist schema 1, metadata ambiente, fingerprint dei sorgenti prima
e dopo, tentativi e diagnosi sono conservati anche al fallimento. Una modifica
dei sorgenti durante il run impedisce il successo. La directory è esclusiva,
configurabile come figlia diretta di `spikes/out/`; nessun output è sovrascritto
da una successiva invocazione. Il parent usa `tools/record-command.lisp` per
argv, ambiente, stdout/stderr, exit code e conservazione finale delle prove.

Budget massimo: 10 campioni seriali × 5 finestre e 9 repliche parallele × 5
finestre; fino a 620000 cicli per worker/campione sommando la calibrazione.
Solo dati aggregati, nessuna traccia per record. Il sensore non prova assenza
assoluta di allocazioni. Il carico esterno non è controllato. Il backend non
effettua syscall di dati: nessuna conclusione su NVMe, latenza client,
durability reale, recovery, snapshot o prestazioni del database.

Nessuna esecuzione automatica fino al congelamento dei sorgenti da parte del
parent. Uso dal worktree congelato (nomi di directory nuovi a ogni comando):

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/wal-csn-bench.lisp \
  --self-test --output-dir spikes/out/wal-csn-self-test-UNIQUE/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/wal-csn-bench.lisp \
  --bench --output-dir spikes/out/wal-csn-bench-UNIQUE/
```

Senza `--output-dir`, il tool sceglie un nome esclusivo con tempo/PID/tentativo.
Output: `report.lisp` e `self-test-metrics.lisp` nella directory indicata;
il rapporto completo viene emesso anche su stdout. La campagna `--bench`
include automaticamente l'autoverifica del sensore.
