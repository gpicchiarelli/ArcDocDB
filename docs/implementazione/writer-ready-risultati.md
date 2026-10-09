# Risultati della lista dei writer pronti

Campagne locali 2026-10-09, base iniziale `92d8b0e`, macOS ARM64/Apple M4,
SBCL 2.6.9, safety3. Le verifiche integrate usano prima `fd96fb3` (manifest),
poi `201562d` (header CBOR) e `33aa224` (registro CSN), contributi delle altre chat.
I due sorgenti ready, test e benchmark
restano identici; ASDF integra i componenti e il runner di mutazione viene
rafforzato. Ogni record conserva la propria versione; il carico esterno
non è controllato.
Il [contratto](writer-ready.md) conserva i confini del trasporto degli obblighi.

## Correttezza e fault injection

Sulla base iniziale, build forzata e suite completa senza warning/style-warning: 237 test dei
sette moduli più smoke, con 51 execution (34 precedenti e 17 nuovi).
L’oracolo a liste FIFO e cursori verifica 9000 passi su nove configurazioni,
con undici writer riusati, obblighi pending su full e completamento prima
del riuso. Il limite default usa 1025 writer distinti; il riferimento
rifiutato viene conservato e pubblicato dopo il drain.

Le prove coprono wrap, capacità e input, rotazione, 24 pattern busy/cursore,
sette forme di ring incoerenti, array/slot/payload invalidi e helper chiamati
senza guard o da altro thread. FI privata e fixture di ring opaco duplicato
restano distinte dagli oracoli pubblici con obblighi legali.

Quattro thread reali sono riusati su sei ondate e 36 payload: i producer
restano vivi durante il consumo, un consumer completa i tratti mentre la
partizione dell’altra Serie rimane occupata. Due ulteriori consumer
contendenti sono riusati su otto ondate e prendono un solo riferimento per
ondata. I controlli di payload/CRC avvengono fuori dalle guard della lista;
semafori, retry e join appartengono al harness con limiti espliciti.
Nessuna misura di throughput, speedup, P99 o fairness temporale.

## Copertura e mutazioni

| File execution | Espressioni raw | Esiti raw |
|---|---:|---:|
| package | 0/1 | 0/0 |
| queue | 142/184 | 24/34 |
| writer | 190/218 | 36/44 |
| handoff | 173/190 | 16/16 |
| ready-types | 170/187 | 30/30 |
| ready | 173/194 | 20/22 |
| Totale | 848/974 | 126/146 |

Il ricalcolo indipendente dei vettori raw concorda con l’indice HTML.
L’[inventario](writer-ready-decisioni.md) conserva dichiarazioni/default,
due controlli CAS difensivi e otherwise, insieme alle lacune legacy.
Nessuna forma sottratta, esclusione approvata o qualifica MC/DC completa.

La campagna iniziale ha baseline execution 51 riuscita. Dodici mutanti compilano e sono rilevati;
zero sopravvissuti, compilation failure o before-tests. Il set preregistrato
verifica FIFO, wrap, pieno, count, slot liberato, rilascio, busy, ultima
partizione e cursore; non rappresenta tutti i possibili difetti.

L’integrazione aggiunge la distinzione tra errore rilevato dai test e
fallimento del processo: segnale OS o exit nonzero dopo completion reale
sono `:worker-error`. Il self-test usa un proprio child terminato con
SIGKILL, conservando exit, signal, log e rapporto. La precedente campagna
e versione dello strumento rimangono preservate; i dodici mutanti non cambiano.
La ripetizione su `fd96fb3` passa con baseline 51 e 12/12 rilevamenti,
exit 1 e signal NIL per ogni mutante; zero worker error, sopravvissuti,
compilation failure o before-tests. Tutti i tredici log sono conservati.

## Allocazioni osservate

| Composizione preallocata | Campioni × cicli | Heap per campione | Sink esatto |
|---|---:|---:|---:|
| Una partizione, due writer, capacità 3 | 5 × 4096 | 0 byte | 9.246.720 |
| Quattro partizioni, otto writer, capacità 3 | 5 × 4096 | 0 byte | 12.797.952 |

Ogni ciclo comprende accettazione di payload preallocato, pubblicazione,
prelievo, avvio, consumo e fine del writer; si misura la composizione
handoff/lista pronta, senza attribuire il tempo alla sola lista.
Warmup 128 e GC fuori dal contatore. Token indipendente
`27K²+154K+29` (210/1077), 13/49 chiamate API per ciclo; identità, count,
status, cursore e generazione vengono verificati. La somma attesa include
anche gli indici delle 4096 iterazioni.

Il controllo positivo rileva 16.777.472 byte su 16 × 1 MiB allocati
appositamente. Baseline del contatore zero; sink errato rifiutato, clock
zero distinto e report parziali/destinazioni preesistenti conservati.
Startup e condizioni d’errore sono esclusi; i campioni osservati non
provano assenza universale di allocazioni né prestazioni del pool.

## Verifiche integrate

`make check` su `fd96fb3` passa con sorgenti stabili e exit 0:
257 test dei sette moduli più smoke (26 foundation, 17 codec,
51 execution, 44 storage, 18 I/O, 82 recovery, 19 WAL).
Compilazione forzata senza warning/style-warning, lint su 48 file con
zero violazioni, trace, link, conservazione delle evidenze e relativi
self-test, più tutti i dieci spike di correttezza. Il rapporto completo
con output originali è [conservato](../../spikes/results/2026-10-09-writer-ready/check-integrato-processo.lisp)
insieme al [master degli spike](../../spikes/results/2026-10-09-writer-ready-fd96-spikes/spikes.lisp),
con payload compresso verificato senza perdita. Le aggiunte editoriali e
la pubblicazione finale dei rapporti ricevono poi il controllo link/evidence.
La verifica riguarda questa integrazione, senza promozione dei gate del motore.

Dopo l'integrazione degli header CBOR, `make check` su `201562d` passa
nuovamente, OK/STABLE/exit 0: 274 test degli otto moduli più smoke,
con 17 test CBOR aggiuntivi; lint su 50 file senza violazioni e tutti gli
altri controlli, inclusi i dieci spike, superati. Il
[catalogo](../../spikes/results/2026-10-09-writer-ready/catalogo.lisp) conserva
il processo finale e il master compresso degli spike insieme alla prima
integrazione. Il codice, i test ready e i due strumenti rimangono identici
alla versione verificata su `fd96fb3`; cambia ASDF per registrare CBOR.
Copertura, mutazioni e allocazioni mantengono la propria base di misura.

L'integrazione conclusiva del registro CSN su `33aa224` passa con
294 test dei nove moduli più smoke (20 CSN aggiuntivi), lint su 52 file
senza violazioni e tutti i dieci spike. Il processo è
OK/STABLE/exit 0; ASDF registra il nuovo modulo, mentre sorgenti ready,
test e strumenti sono invariati. Il catalogo conserva anche questo check
con il master degli spike; le due verifiche precedenti restano separate.
Le sole chiusure editoriali successive ricevono il controllo link/evidence.

## Riproduzione e conservazione

```sh
make test
sbcl --script tools/foundation-coverage.lisp --report directory-nuova/ execution
sbcl --script tools/writer-ready-mutation.lisp --self-test
sbcl --script tools/writer-ready-mutation.lisp --run altra-directory-nuova/
sbcl --script tools/writer-ready-bench.lisp --self-test
sbcl --script tools/writer-ready-bench.lisp --bench ulteriore-directory-nuova/
make check
```

Per conservare comando, ambiente, sorgenti e output integrali, anteporre
`sbcl --script tools/record-command.lisp --` al comando. Il
[catalogo](../../spikes/results/2026-10-09-writer-ready/catalogo.lisp)
conserva processi, copertura raw, baseline e tutti i log dei dodici mutanti,
misure, adapter e probe ispettivi. I due C4 sono compilati integralmente con
avvisi fatali e self-test dei FASL in processi/cache privati separati.
La [revisione](writer-ready-revisione.md) distingue le due letture C1 e
la successiva verifica integrata. I gate del motore restano aperti.
