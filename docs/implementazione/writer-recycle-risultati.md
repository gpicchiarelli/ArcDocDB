# Risultati del ricircolo dei writer pronti

Campagne locali del 2026-10-09, base `673987a`, macOS ARM64/Apple M4,
SBCL 2.6.9, safety3. Sorgenti, test e strumenti sono congelati nella copia
`arcdocdb-recycle-verify-7meus4m5`; ogni processo conserva argv, ambiente,
output integrali e snapshot prima/dopo. Il carico esterno è non controllato.
Il [metodo preregistrato](writer-recycle-metodo.md) e il
[contratto](writer-recycle.md) fissano l'ambito della verifica.

## Correttezza e concorrenza

La build forzata e `make check-core`, eseguito tramite record-command come
`make check`, passano senza warning/style-warning: 309 test dei nove moduli
più smoke. Execution passa da 51 a 66 test, con 15 nuove prove.
L'oracolo a liste indipendenti verifica 8.000 passi su otto configurazioni:
capacity 1/2/3/9 × shard 1/4, 11 writer riusati e payload unici.
Ogni obbligo pubblico proviene da handoff, viene trasferito una volta e
completato prima del riuso; i soli duplicati opachi sono FI private dichiarate.

La regressione avvia due consumer A/B con backlog, svuota il ring, lo
riempie di C/D mentre A/B sono running e termina entrambi con `:schedule`.
La pubblicazione semplice rifiuta entrambi senza mutazione; due ricircoli
trasferiscono C/D ai caller e conservano A/B nel ring in FIFO, senza pop
intermedio. Tutti i payload sono elaborati una volta e i writer tornano idle.

Tre thread reali, due consumer contendenti e un producer vivo, vengono
riusati per otto ondate e 48 payload con identità/CRC. Il retry dopo busy è
coordinato e bounded nel harness. Un'ulteriore prova conserva la guard del
primo shard mentre un altro thread ricircola e completa il secondo.
Le prove controllano input prima della guard, busy senza effetti, forma e
payload incoerenti, helper senza guard/guard estranea, avvio busy dopo il
trasferimento e nuova ondata senza cleanup tardivo.

## Copertura e mutazioni

| File execution | Espressioni raw | Esiti raw |
|---|---:|---:|
| package | 0/1 | 0/0 |
| queue | 142/184 | 24/34 |
| writer | 190/218 | 36/44 |
| handoff | 173/190 | 16/16 |
| ready-types | 170/187 | 30/30 |
| ready | 173/194 | 20/22 |
| ready-recycle | 81/86 | 8/8 |
| Totale | 929/1060 | 134/154 |

Il native e l'indice HTML concordano con due ricalcoli separati. Le cinque
forme non marcate nel nuovo file sono top-level: package, declaim optimize
e tre ftype. L'[inventario](writer-recycle-decisioni.md) conserva tutte le
lacune precedenti e le decisioni; nessuna forma sottratta dal denominatore,
nessuna esclusione approvata o qualifica MC/DC completa.

Baseline completa con 66 test execution; undici mutanti compilano e sono
rilevati dai test. Ogni mutante termina con exit1/signal NIL; zero
sopravvissuti, compilation failure, before-tests o worker-error. Il set
include il mancato avanzamento di head/tail: la forma del ring resta valida,
ma l'oracolo scopre la violazione FIFO. La campagna copre gli undici difetti
preregistrati e conserva baseline più tutti gli undici log.

Un child del self-test viene realmente terminato con SIGKILL: signal9,
exit137, `:worker-error`, zero rilevamenti. Anche un fallimento dopo
completion autentica è worker-error. Questi controlli evitano di contare un
guasto di processo come difetto rilevato dai test.

## Allocazioni osservate

| Shard × capacità | Writer totali | Campioni × cicli | Heap per campione | Sink esatto |
|---|---:|---:|---:|---:|
| 1 × 1 | 2 | 5 × 4096 | 0 byte | 9.439.232 |
| 1 × 3 | 4 | 5 × 4096 | 0 byte | 10.672.128 |
| 4 × 1 | 8 | 5 × 4096 | 0 byte | 13.395.968 |
| 4 × 3 | 16 | 5 × 4096 | 0 byte | 21.620.736 |

Ogni ciclo composto handoff/ready/ricircolo usa C+1 writer distinti per
shard, ruota i ruoli, pubblica C riferimenti, scambia il ring pieno e
consuma il riferimento restituito più quelli rimanenti. Identità, count,
status, cursore, payload e generazione sono verificati. Warmup 128 e GC
precedono la finestra; nessun I/O nel ciclo. I token indipendenti e le
12/24/45/93 chiamate API per ciclo sono derivati nel metodo.

Il controllo positivo misura 16.777.472 byte su 16 × 1 MiB deliberatamente
allocati; baseline del contatore zero. Sink errato respinto, clock zero
riportato come below-resolution, destinazione preesistente intatta e
rapporto parziale verificato. Startup e condizioni d'errore sono fuori dalla
finestra. Venti campioni seriali non provano zero heap universale, speedup,
throughput del pool, P99, equità o qualificazione del motore.

## Check e conservazione

Il check completo è OK/STABLE/exit0, processo `4000528494-command-77199-0`:
26 foundation, 17 UTF-8, 17 CBOR, 20 CSN, 66 execution, 44 storage,
18 I/O, 82 recovery e 19 WAL, più smoke. Lint su 53 file con zero violazioni;
trace, link, self-test degli strumenti/evidenze, conservazione e tutti i
dieci spike passano. Il master `4000528568-check-78100-0` è conservato con
compressione senza perdita. I due nuovi C4 ricevono compilazione integrale
rigorosa e self-test dei FASL in processi/cache privati separati.

Il [catalogo](../../spikes/results/2026-10-09-writer-recycle/catalogo.lisp)
conserva processi, native/HTML, log, misure, due letture C1, controlli negativi
e sorgenti degli adapter. Le chiusure editoriali e la pubblicazione ricevono
poi il controllo link/evidence. Pool, risvegli, admission, controller e
shutdown restano da integrare; i gate del motore rimangono aperti.

## Riproduzione

```sh
make check
sbcl --script tools/foundation-coverage.lisp --report directory-nuova/ execution
sbcl --script tools/writer-recycle-mutation.lisp --self-test
sbcl --script tools/writer-recycle-mutation.lisp --run altra-directory-nuova/
sbcl --script tools/writer-recycle-bench.lisp --self-test
sbcl --script tools/writer-recycle-bench.lisp --bench ulteriore-directory-nuova/
```

Per conservare argv, ambiente, sorgenti e output, anteporre
`sbcl --script tools/record-command.lisp --` al comando. La
[revisione](writer-recycle-revisione.md) conserva i dodici punti C1 e i limiti.
