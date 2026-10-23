# Decisioni della lista dei writer pronti

Inventario C1 di [`ready-types.lisp`](../../src/execution/ready-types.lisp) e
[`ready.lisp`](../../src/execution/ready.lisp), secondo il
[metodo preregistrato](writer-ready-metodo.md). Riferimenti:
REQ-CON-001/002/004/005, REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8, INV-V4;
[ADR-0005](../adr/0005-writer-logico-per-serie.md) e
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md).

La lista trasporta riferimenti e obblighi già prodotti da `:schedule`.
Non consulta né modifica lo stato del writer, non deduplica gli obblighi e
non implementa il pool o i risvegli. La pubblicazione una sola volta è una
precondizione del chiamante. Full/busy conservano l'obbligo al chiamante;
pubblicazione riuscita e prelievo lo trasferiscono rispettivamente al ring
e al worker. Le decisioni del writer restano nell'
[inventario della consegna locale](writer-handoff-decisioni.md).

## Predicati scalari, default e rami

Non vi sono nuove decisioni composte `and`/`or` in `if`, `when`, `unless` o
`cond` nei due sorgenti. L'`or` nel tipo dello slot guard e nei tipi dei
ritorni è un'unione di tipi, non una decisione composta di COD-54. I confronti
ternari `<=` controllano separatamente i due estremi nei test di configurazione
e nella fault injection; non si deduce MC/DC completa dal loro inventario.

I riferimenti seguenti indicano i suffissi dei test `test-REQ-…-ready-…` in
[`tests/execution/ready.lisp`](../../tests/execution/ready.lisp). Descrivono
fixture lette, non un esito di esecuzione. Le campagne raw e la lettura finale
devono attestare gli esiti effettivi senza sottrarre forme dal denominatore.

| Punto | Condizione ed esiti | Fixture disponibile o limite |
|---|---|---|
| Default di `partizione-pronta` | Slots `#()`, capacity 1024, head/tail/count zero, guard NIL. La factory passa slots/capacity espliciti; gli indici partono da zero. | `configuration-and-limits`; i default strutturali rimangono nel denominatore raw. |
| Default di `lista-writer-pronti` | Partitions `#()`; la factory passa il vettore completo. Un oggetto privato con zero partizioni è rifiutato dal verificatore. | Factory pubblica; `rejects-invalid-private-partition-arrays`: vettore vuoto. |
| `%check-forma-pronta`: capacity | `1 <= capacity <= 65536`, altrimenti `:ready-queue-invariant`. | Factory minima/default/massima; `rejects-invalid-private-ring-shapes`: FI capacity 0 e 65537. |
| `%check-forma-pronta`: slots | Lunghezza slots uguale a capacity, altrimenti `:ready-queue-invariant`. | Pre/post validi; stessa FI: slots di lunghezza 1 con capacity 2. |
| `%check-forma-pronta`: head | Head sotto capacity, altrimenti `:ready-queue-invariant`. Il tipo `index` esclude negativi. | FIFO con wrap e capacity 1; stessa FI: head 2 con capacity 2. |
| `%check-forma-pronta`: tail | Tail sotto capacity, altrimenti `:ready-queue-invariant`. | FIFO con wrap e capacity 1; stessa FI: tail 2 con capacity 2. |
| `%check-forma-pronta`: count | Count non superiore a capacity, altrimenti `:ready-queue-invariant`. | Pieno/vuoto; stessa FI: count 3 con capacity 2. |
| `%check-forma-pronta`: relazione | `tail = (head + count) mod capacity`, altrimenti `:ready-queue-invariant`. | Oracoli a liste e wrap; stessa FI: tail 1, head/count zero, bounds ancora validi. |
| `%check-pronta`: proprietà | Guard uguale al thread corrente, altrimenti `:ready-queue-guard`; poi controllo della forma. | `helpers-reject-missing-and-foreign-guard`: guard assente e posseduta da altro thread; nessuna mutazione. |
| `%partizione-verificata`: cardinalità | Numero di partizioni 1..64, altrimenti `:ready-queue-invariant`. | Configurazioni 1, 3, 4, 64; `rejects-invalid-private-partition-arrays`: vettori di lunghezza 0 e 65. |
| `%partizione-verificata`: tipo indice | Shard di tipo `index`, altrimenti `invalid-argument`, `:ready-target`. | `shard-and-writer-preflight`: negativo, NIL, float e valore oltre fixnum, per publish e take. |
| `%partizione-verificata`: limite indice | Shard inferiore alla lunghezza, altrimenti `:ready-target`. | Stessa fixture: indice uguale alla cardinalità; ring conservato. |
| `%partizione-verificata`: riferimento | Slot della lista di tipo `partizione-pronta`, altrimenti `:ready-queue-invariant`. | Factory; stessa FI: vettore di lunghezza 1 con slot NIL. |
| Factory: tipo shards | `index`, altrimenti `:ready-configuration`; controllo antecedente al confronto. | `configuration-and-limits`: negativo, NIL e float. |
| Factory: range shards | 1..64, altrimenti `:ready-configuration`. | Zero, 65, 1 e 64; default 4. |
| Factory: tipo capacity | `index`, altrimenti `:ready-configuration`; controllo antecedente al confronto. | Negativo, NIL e float. |
| Factory: range capacity | 1..65536, altrimenti `:ready-configuration`. | Zero, 65537, 1 e 65536; default 1024. |
| Factory: default keyword | Shards 4, capacity 1024 quando gli argomenti sono assenti. | Saturazione e drain della partizione 3 della lista default. |
| Factory: ciclo | Esattamente shards costruzioni, con forma verificata prima della pubblicazione nel vettore; controllo finale della partizione 0. | 1..64 iterazioni; i vettori restano privati fino al ritorno. Nessun ciclo di retry. |
| `%prendi-guard-pronta`: CAS | Vecchio valore NIL acquisisce la guard; altro valore restituisce NIL senza mutazione. | `skips-busy-home-and-preserves-local-ring`, `busy-observations-and-scan-order-oracle`, guard estranea e worker reali. |
| `%prendi-guard-pronta`: postcondizione | Guard uguale al thread dopo CAS riuscito, altrimenti `:ready-queue-guard`. | Il ramo falso richiede un guasto del protocollo privato; non alterare una guard condivisa durante una prova concorrente. |
| `%rilascia-guard-pronta`: proprietà | Guard uguale al thread atteso, altrimenti `:ready-queue-guard`, prima del CAS. | Cleanup ordinario/full; `helpers-reject-missing-and-foreign-guard`, senza guard e con guard estranea. |
| `%rilascia-guard-pronta`: CAS | Vecchio valore del CAS uguale al thread, altrimenti `:ready-queue-guard`. | Rilascio ordinario; il ramo falso dopo il precontrollo richiede un guasto del protocollo. |
| `%pubblica-pronto`: pieno | Count uguale a capacity rifiuta con `resource-exhausted`, `:ready-queue-full`, prima delle scritture. | `configuration-and-limits`, `full-preserves-scheduling-obligation`, entrambi gli oracoli a liste. |
| `%pubblica-pronto`: slot tail | Slot tail NIL oppure `:ready-queue-invariant` prima della mutazione. | Slot riusati dopo drain/wrap; `rejects-inconsistent-occupied-and-free-slots`: count zero, slot tail occupato da writer. |
| `%pubblica-pronto`: pre/post | Guard/forma verificate prima e dopo; slot scritto, tail circolare, count incrementato di uno. | Count atteso e identità FIFO degli oracoli; il ring non interroga il writer. |
| `%preleva-pronto`: vuoto | Count zero restituisce NIL/`:empty`; count positivo procede al prelievo. | Liste vuote, drain, capacity 1 e scansione senza successo. |
| `%preleva-pronto`: payload | Riferimento al tipo `writer-programmabile` oppure `:ready-queue-invariant` prima delle scritture. | Identità dei riferimenti; stessa FI: count 1 con slot head NIL, keyword o vettore. |
| `%preleva-pronto`: pre/post | Guard/forma verificate, slot liberato, head circolare, count decrementato di uno, poi writer/`:writer`. | FIFO, wrap e successiva saturazione; nessun cleanup sullo stato del writer. |
| `pubblica-writer-pronto`: input | Partizione verificata prima della guard; writer del tipo richiesto oppure `:ready-writer`. | `shard-and-writer-preflight`: NIL, keyword, vettore e coda bassa rifiutati; successivo take/empty prova conservazione. |
| `pubblica-writer-pronto`: busy | Acquisizione verificata oppure `resource-exhausted`, `:ready-queue-busy`, senza inserimento. | `busy-publication-retains-obligation-and-payload` e `skips-busy-home-and-preserves-local-ring`: snapshot conservato, retry della sola pubblicazione. |
| `%prova-pronta`: busy | Guard indisponibile restituisce NIL/`:busy`; altrimenti delega al prelievo e installa cleanup. | `helpers-reject-missing-and-foreign-guard`, oracolo delle guard e worker reali; nessuna condizione allocata per il busy ordinario della scansione. |
| `preleva-writer-pronto`: start | `%partizione-verificata` controlla l'indice prima della scansione; `(the index start)` non disabilita safety. | `shard-and-writer-preflight`; cursori 0..K−1 degli oracoli. |
| `preleva-writer-pronto`: ciclo | Al più K tentativi di acquisizione, K <= 64; ogni acquisizione riuscita ha inoltre un CAS di rilascio; uscita anticipata al primo writer. | `cursor-rotates-first-choice-and-empty-scan`, `busy-observations-and-scan-order-oracle`: otto configurazioni di guard per ciascuno dei tre start. |
| `preleva-writer-pronto`: `case` | `:writer` ritorna subito; `:busy` conserva il fatto che una guard era occupata; `:empty` continua; `otherwise` segnala `:ready-queue-invariant`. | Writer/empty/busy negli oracoli e `skips-busy-home-and-preserves-local-ring`. `otherwise` è difensivo: nessuna modifica dei tipi o sostituzione di funzione per farlo apparire come input pubblico. |
| `preleva-writer-pronto`: cursor | Successo: successore modulo K dello shard servito; ogni tentativo senza successo avanza di uno modulo K. | Rotazione con tutte le partizioni piene, ricerca da cursori diversi, wrap e caso K=1. |
| `preleva-writer-pronto`: `if busy` | Dopo K insuccessi: `:busy` se almeno una guard era contesa, altrimenti `:empty`; riferimento NIL e cursore start+1 modulo K. | `busy-observations-and-scan-order-oracle`: guard libere, tutte occupate e miste, anche dopo drain. Empty rappresenta osservazioni locali, senza quiescenza globale. |

## Cleanup, proprietà e integrazione

| Percorso | Effetto e limite | Fixture disponibile o limite |
|---|---|---|
| Publish con guard verificata | `unwind-protect` rilascia la guard dopo successo, full o errore della forma/slot. Il busy d'ingresso non la acquisisce. | Saturazione e retry; FI di forma/slots con snapshot iniziale/finale che include guard NIL; pubblicazione busy. |
| Take con guard verificata | `%prova-pronta` rilascia dopo writer, empty o errore del prelievo. Busy conserva il contenuto e permette la scansione di altri shard. | Oracoli FIFO, FI di forma/payload con snapshot, guard estranea e `reused-workers-live-producers-and-independent-shards`. |
| Guasto dell'acquisizione o del rilascio | Un errore della postcondizione CAS richiede fail-stop del proprietario; nessun rollback o cleanup è promesso dopo una proprietà interna incoerente. | Rami difensivi mantenuti nel denominatore raw. Il controller FAULTED del motore resta da integrare. |
| Proprietà della lista | Il vettore delle partizioni è scritto soltanto dalla factory e rimane privato. Identità di slots/capacity/partitions read-only; nessun contatore globale. | Revisione dei tipi e della factory. |
| Proprietà del ring | Head/tail/count e contenuti slots mutati soltanto sotto la propria guard; la guard usa CAS. | Pre/post verificati; `helpers-reject-missing-and-foreign-guard`, oracolo busy e due prove con thread reali. |
| Proprietà dell'obbligo | Caller → ring soltanto al successo; ring → worker al pop. Un successo non si ritenta. Duplicati intenzionali non sono rilevati. | `per-shard-fifo-wrap-and-private-opaque-ring`: la prova pubblica usa obblighi legali; soltanto una fixture privata di ring isolato inserisce due riferimenti opachi identici, dichiaratamente fuori dal protocollo handoff. |
| Pubblicazione full | Nessun reinserimento di payload nel writer; l'obbligo conservato viene pubblicato quando si libera uno slot. | `full-preserves-scheduling-obligation`: payload `:a/:b` elaborati una sola volta su tratti successivi. |
| Avvio busy dopo dequeue | Il worker conserva il riferimento e ritenta l'avvio; nessuna ripubblicazione del riferimento estratto. | `dequeued-reference-survives-begin-busy`; ring empty durante il retry, payload elaborato una volta. |
| Producer prima della fine | Durante running l'enqueue ritorna `:queued`; la fine con backlog produce un nuovo `:schedule`. | `handoff-before-after-release-and-next-wave`, quattro ondate. |
| Producer dopo fine vuota | La fine ritorna `:idle`; il nuovo enqueue ritorna `:schedule` e può essere pubblicato subito. Nessun cleanup tardivo scheduler sul writer. | Stessa fixture; `reused-workers-live-producers-and-independent-shards`: quattro thread riusati su sei ondate, 36 payload con identità/checksum, producer vivi mentre il worker termina il tratto. |
| Consumer concorrenti | Una guard consente un solo pop del riferimento; l'altro consumer osserva empty o busy, senza duplicazione. | `competing-consumers-take-one-reference-per-wave`: due thread riusati su otto ondate, un solo vincitore e completamento prima del riuso. |
| Scelta dello shard e cursore | Mapping stabile prima del percorso caldo, mantenuto dal chiamante; cursore locale del worker. Nessun hashing del catalogo, wakeup o stato membership introdotto. | Contratto preregistrato; il pool deve ancora integrare queste responsabilità. |

Il lavoro del writer avviene dopo il rilascio della guard della ready list.
La serializzazione riguarda soltanto il breve aggiornamento di un ring per
tratto. Una guard contesa non blocca il chiamante né altri shard; non si
promettono lock-freedom, assenza di starvation, bilanciamento globale o progresso
se l'obbligo viene abbandonato. Non vi sono cambiamenti durevoli, I/O, callback,
thread di prodotto o eliminazioni di file in questi sorgenti.

## Complessità e limiti

Il conteggio locale usa base 1, +1 per predicato scalare, +1 per ciclo e
numero di alternative meno 1 per `case`. Le decisioni dei callee sono
inventariate separatamente, senza nasconderle nel conteggio del chiamante.
`unwind-protect` è indicato come cleanup, non come decisione condizionale.

| Funzione | Decisioni locali | Percorsi indipendenti |
|---|---|---|
| `%check-forma-pronta` | 6 `unless` | 7 |
| `%check-pronta` | 1 `unless`, controllo della forma delegato | 2 |
| `%partizione-verificata` | 4 `unless` | 5 |
| `crea-lista-writer-pronti` | 4 `unless`, 1 ciclo bounded | 6 |
| `%prendi-guard-pronta` | 2 `unless` | 3 |
| `%rilascia-guard-pronta` | 2 `unless` | 3 |
| `%pubblica-pronto` | 1 `when`, 1 `unless` | 3 |
| `%preleva-pronto` | 1 `when`, 1 `unless` | 3 |
| `pubblica-writer-pronto` | 2 `unless`, cleanup e deleghe espliciti | 3 |
| `%prova-pronta` | 1 `unless`, cleanup e delega espliciti | 2 |
| `preleva-writer-pronto` | 1 ciclo, `case` con 4 alternative, 1 `if` | 6 |

Nessuna funzione supera i 10 percorsi di COD-13 o le 60 righe di COD-12.
La factory esegue <=64 iterazioni; una scansione esegue <=64 tentativi CAS
di acquisizione e un CAS di rilascio per ciascuna acquisizione riuscita:
massimo 2K, quindi 128 CAS totali. La pubblicazione usa un CAS di acquisizione
e, se riuscito, uno di rilascio.
Ogni ring contiene <=65536 riferimenti; il limite complessivo è 4194304
riferimenti, oltre alle strutture preallocate. Head+count è <=131071 dopo
la verifica dei bounds; l'aritmetica degli indici resta entro fixnum.
Le allocazioni della costruzione e delle condizioni d'errore non sono una
misura del percorso normale. La campagna composta congelata registra dieci
campioni con heap zero; i limiti di quella misura sono riportati più avanti.

## Prima lettura indipendente

Letti in sola lettura i sorgenti dopo la rinomina italiana del verificatore:

- `ready-types.lisp`: SHA-256 `75f153547af5b33e024d5f35e19fd15603c890f1f1616a62d02aa50e3309e4b0`.
- `ready.lisp`: SHA-256 `d295574baa35cd540a4176d738d5670b44a741f532c86071d82e7c2361af44b0`.

Nessun difetto funzionale identificato nella prima lettura. Sono state
segnalate due precisazioni testuali: il cleanup è installato dopo
l'acquisizione verificata della guard, non prima della sua postcondizione;
l'assenza di allocazioni riguarda il percorso normale, mentre full/busy di
pubblicazione segnalano condizioni. Entrambe sono state chiuse nelle sole docstring;
la rilettura indipendente conferma i sorgenti corretti:

- `ready-types.lisp`: SHA-256 `0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f`.
- `ready.lisp`: SHA-256 `a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327`.

Nessun rilievo della prima lettura rimane aperto. I 17 test finali sono stati
letti indipendentemente, SHA-256
`4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e`.
Gli oracoli pubblici producono `:schedule` prima della pubblicazione, completano
il writer prima del riuso e conservano pending dopo full. Il solo caso opaco
duplicato appartiene alla fixture privata dichiarata di ring isolato.
I thread sono quelli del harness: semafori con timeout, riuso finito, join
controllati e rilancio degli errori dei worker. La prima lettura non attestava
copertura, mutanti, allocazioni o `make check`; la lettura delle evidenze
congelate è registrata di seguito.

La matrice conserva i requisiti progettati: questo componente non qualifica
il pool, il controller FAULTED, il protocollo di parcheggio/risveglio o i target
di throughput/P99. Il denominatore raw completo, le forme non marcate e i
rami difensivi devono essere riportati nella lettura finale; nessuna esclusione
viene approvata da questo inventario.

## Copertura raw osservata e mappatura delle lacune

La clone congelata `arcdocdb-ready-verify-_dtdm24z` conserva il native
`spikes/out/ready-coverage/coverage-state.lisp`, l'HTML e l'export
`spikes/out/ready-coverage-export.lisp`. La lettura indipendente con
`*read-eval*` NIL conta i vettori dei percorsi e i bit del native: percorsi
inizianti con `:then` o `:else` sono esiti di ramo, gli altri espressioni.
Il confronto con le celle dell'HTML ricalcolate separatamente coincide per
tutti i sei file. Non viene sottratta alcuna forma dal denominatore.

| File execution | Espressioni marcate / totali | Esiti marcati / totali |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| `ready-types.lisp` | 170 / 187 | 30 / 30 |
| `ready.lisp` | 173 / 194 | 20 / 22 |
| Totale | 848 / 974 | 126 / 146 |

I percorsi native hanno indici inversi: l'ultimo indice identifica la forma
top-level; leggendo gli indici da destra a sinistra si scende nei sottoelementi.
La mappatura seguente usa le forme sorgente senza espanderne o eliminare i
default. Ogni condizione `error` elencata occupa quattro espressioni raw:
chiamata, designatore della condizione, keyword `:reason` e ragione.

| Nuovo file | Tutte le forme/esiti non marcati | Mappatura e limite |
|---|---|---|
| `ready-types.lisp`, 17 espressioni | 8 forme top-level `(0) (1) (2) (3) (6) (8) (10) (12)`; 7 forme slot `(3 4)`..`(8 4)` e `(3 5)`; 2 default keyword `(1 2 13) (2 2 13)`. | `in-package`, ottimizzazione, due costanti e quattro `ftype`; slots/capacity/head/tail/count/guard e partitions; default shards/capacity. Nessun errore operativo o esito di ramo strumentato scoperto; 30/30 non significa MC/DC completa. |
| `ready.lisp`, 21 espressioni | 9 forme top-level `(0) (1) (2) (4) (6) (8) (10) (12) (14)`; 4 espressioni nell'errore radice `(2 3 4 3)`; 4 nell'errore `(2 5 5)`; 4 nell'`otherwise` `(1 5 3 2 2 5 15)`. | `in-package`, ottimizzazione e sette `ftype`; errore della proprietà dopo acquisizione; errore del vecchio valore CAS al rilascio; statuto difensivo inatteso della scansione. |
| `ready.lisp`, 2 esiti | `(:else 1 3 4 3)` e `(:else 1 5 5)`. | Guard diversa dal thread dopo CAS riuscito in `%prendi-guard-pronta`; vecchio valore del CAS diverso dal thread dopo il precontrollo in `%rilascia-guard-pronta`. Richiedono un guasto del protocollo di proprietà; non vengono provocati alterando una guard condivisa durante il test concorrente. Nessuna esclusione approvata. |

Le nuove FI coprono i rifiuti della forma, del payload, della proprietà
assente/estranea prima del rilascio e i cleanup con guard acquisita. Questo
non chiude automaticamente le lacune delle primitive precedenti: sorgenti
queue/writer/handoff immutati, conteggi raw invariati.

| File precedente | Tutte le forme non marcate | Tutti gli esiti non marcati |
|---|---|---|
| `package.lisp` | Una forma `(0)`, `defpackage` con export. | Nessun esito strumentato. |
| `queue.lisp`, 42 espressioni | 22 definizioni/default: top-level `(0) (1) (2) (3) (5) (7) (9) (11) (13) (15)`, dieci slot `(3 4)`..`(12 4)`, keyword `(1 2 12) (2 2 12)`. Venti espressioni in cinque errori: forma e relazione FIFO, proprietà post-acquisizione, proprietà prima del rilascio e CAS di rilascio; radici `(2 2 4 6) (2 3 4 6) (2 3 4 8) (2 4 10) (2 5 10)`. Il nuovo helper handoff `%accoda-sotto-guard` non ha esiti mancanti. | Dieci: entrambi gli esiti dell'unione di tipo guard `(:then 3 9 4)`/`(:else 3 9 4)`; falsi di capacity `(:else 1 1 2 4 6)`, lunghezza `(:else 2 1 2 4 6)`, head `(:else 3 1 2 4 6)`, predicato composto della forma `(:else 1 2 4 6)` e relazione `(:else 1 3 4 6)`; proprietà post-acquisizione `(:else 1 3 4 8)`, proprietà prima del rilascio `(:else 1 4 10)`, vecchio valore CAS `(:else 1 5 10)`. |
| `writer.lisp`, 28 espressioni | Otto definizioni `(0) (1) (2) (4) (6) (8) (10) (12)`; venti espressioni in cinque errori: quota della lease, proprietà e CAS di rilascio owner, postcondizioni di acquisizione e prelievo; radici `(2 5 3) (2 4 5) (2 5 5) (2 1 1 3 4 7) (2 6 2 1 2 4 3 5 11)`. | Otto: range quantum `(:else 1 1 5 3)` e quota composta `(:else 1 5 3)`; proprietà owner `(:else 1 4 5)` e CAS owner `(:else 1 5 5)`; proprietà acquisita `(:else 1 1 1 1 3 4 7)` e postcondizione composta `(:else 1 1 1 3 4 7)`; taken <= remaining `(:else 1 1 6 2 1 2 4 3 5 11)` e postcondizione composta del prelievo `(:else 1 6 2 1 2 4 3 5 11)`. |
| `handoff.lisp`, 17 espressioni | Nove forme top-level `(0) (1) (3) (5) (7) (9) (11) (13) (15)`, due slot `(3 2) (4 2)`, due default keyword `(1 2 8) (2 2 8)`, quattro espressioni nell'errore `otherwise` dello stato, radice `(1 5 4 4 6)`. | Nessun esito strumentato scoperto: 16/16. Default e `otherwise` restano nelle espressioni raw; nessuna deduzione di MC/DC completa. |

## Evidenze congelate iniziali lette, base 92d8b0e

I rapporti command sono stati letti tramite `arcdocdb.evidence:read-evidence`,
anche quando il file esterno è un descriptor compresso. Il lettore verifica
il payload e mantiene `*read-eval*` NIL; nessun rapporto viene eseguito come codice.

- Build/test `4000520747-command-93257-0`: `:ok`, sorgenti `:stable`, exit 0,
  stderr vuoto; 237 test nei sette moduli, oltre allo smoke, con 51 execution.
  Compilazione senza warning/style-warning secondo il runner rigoroso.
- Coverage `4000520828-command-97914-0` ed export
  `4000520903-command-1709-0`: `:ok/:stable`, exit 0; self-test export passato.
  I conteggi indipendenti e l'HTML coincidono come sopra.
- Self-test rigorosi C4 `4000520791-command-94820-0` (mutazioni) e
  `4000520791-command-94821-0` (bench): `:ok/:stable`, exit 0; COMPILE-FILE
  completo e self-test del FASL, non soltanto caricamento del sorgente.
- Mutazioni `4000520822-command-96904-0` e dati `ready-mutations/report.lisp`:
  baseline completa con 51 eventi start/ok e `execution-tests-complete 51`;
  12/12 mutanti rilevati, zero sopravvissuti, compilation-failures e before-tests.
  Letti tutti i 13 log: ogni mutante ha avviato un test ready prima del guasto,
  senza diagnostiche del compilatore. I dodici bersagli restano FIFO, wrap
  head/tail, full, count, riferimento liberato, guard liberata, memoria di busy,
  skip busy, ultimo shard e i due avanzamenti del cursore.
- Bench `4000520933-command-3549-0` e dati `ready-allocations/report.lisp`:
  `:ok/:stable`, exit 0; due scenari seriali composti handoff/lista, K=1 e K=4,
  capacity 3 e due writer per shard. Cinque campioni di 4096 cicli per scenario,
  warmup 128 e GC prima del contatore, heap zero in tutti i dieci campioni.
  Sink esatti 9246720 e 12797952, token indipendenti 210 e 1077. Controllo
  positivo 16777472 byte; wrong sink rifiutato, clock zero distinto, rapporto
  parziale e destinazione preesistente conservati. Nessuna prova universale di
  non allocazione, contesa, scalabilità, throughput, P99 o pool adattivo.

Queste evidenze iniziali appartengono alla base `92d8b0e`, ASDF SHA-256
`53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3`,
runner mutazioni ready SHA-256
`e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829`.
Sono conservate come prove mirate del componente, senza attribuirle
retroattivamente alla successiva integrazione.

Al momento della lettura iniziale la verifica integrata finale `make check`
era ancora in attesa. I probe indipendenti di lettura e le loro correzioni sono
conservati nella clone in `spikes/out/ready-review-probes.lisp`: il lettore
iniziale mancava del preload ASDF/UIOP; un percorso baseline errato e una
selezione iniziale degli eventi sono stati corretti. Questi probe non sono
campagne e non vengono attribuiti al prodotto o ai C4. I relativi comandi e
output tool sono conservati senza dedurre metadati assenti.

## Integrazione successiva e classificatore C4

Il main `fd96fb3145f593f31552de26a8fd93478b69fc8f` integra il manifest
recovery e una correzione del runner mutazioni handoff. La verifica indipendente
di worktree e clone conferma i medesimi hash di package execution, queue,
writer, handoff, ready-types, ready, test ready e bench. Il solo ASDF fra
questi file cambia, SHA-256
`4fc264ec2638b5d3b778890405942fadb3857180ab7c3818d8377e6a2f50e458`:
registrazioni execution e ready conservate accanto alle nuove componenti
manifest. Non è una nuova lettura C1 del codice manifest.

Il nuovo runner ready aveva ereditato il classificatore precedente: un
processo segnalato dall'OS oppure un exit nonzero dopo l'evento di completion
non deve essere contato come mutante rilevato. Serve l'esito separato
`:worker-error`, con segnale e contatore conservati. La classificazione
iniziale resta storica: i suoi tredici log sono stati letti e i dodici guasti
avvengono dopo start di test ready e prima di completion, ma i metadati del
segnale non erano registrati e non vengono dedotti come NIL.

Alla prima lettura dell'integrazione, la correzione del classificatore ready,
il self-test rigoroso e la nuova campagna sulla base integrata erano in attesa. Il report
indipendente iniziale rimane conservato nella clone in
`spikes/out/ready-independent-review.lisp`; la successiva chiusura deve essere
un'appendice distinta, senza riscrivere la lettura o i risultati storici.
La chiusura C4 e i due check integrati successivi sono attestati di seguito,
senza riscrivere i report precedenti.

## Chiusura del classificatore e dell'integrazione

La lettura indipendente del runner finale SHA-256
`06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb`
conferma la precedenza del segnale OS, il rifiuto dell'exit nonzero dopo
completion autentica e la conservazione distinta di exit/signal. I marker
citati o prefissati in un backtrace non sono eventi autentici. Baseline e
mutanti riportano i segnali; il contatore `worker-errors` è distinto dal
rilevamento e il gate finale richiede tutti i dodici `detected`.

Lo strict finale `4000521809-command-41045-0` è `:ok/:stable`, exit 0,
stderr vuoto: preload contrib, COMPILE-FILE intero senza warning/failure e
self-test del FASL con argv espliciti. Letti i dati originali della fixture
`4000521810-ready-signal-self-test-41080`: runner che emette start e flush,
poi SIGKILL; log corrispondente; report `:passed/:stable`, exit 137, signal 9,
`:worker-error`, zero detected e un worker-error. Baseline pending appartiene
soltanto alla fixture di segnale e non rappresenta una campagna fallita.

La campagna finale `4000521918-command-45102-0`, base `fd96fb3`, è
`:ok/:stable`, exit 0. Dati `ready-mutations-final/report.lisp` SHA-256
`c1db98e2b8538444381254f0fc79cf3ebc1fdfa4ffc2445f101d6ccb49ac6d87`:
baseline completata con 51 test, exit 0/signal NIL; dodici mutanti rilevati,
ciascuno exit 1/signal NIL; zero sopravvissuti, compilation-failures,
before-tests e worker-errors. Letti indipendentemente tutti i tredici log:
baseline con 51 start/ok e completion 51; guasti dei mutanti dopo start di
un test ready e prima di completion, senza failure del compilatore. Il probe
registrato `4000522063-command-47453-0` conferma integrità dei tredici log e
conteggi, `:ok/:stable`, exit 0. Il rilievo C4 ereditato è chiuso; le prove
iniziali restano attribuite alla loro versione del runner.

Il primo check integrato, base `fd96fb3`, è
`4000521907-command-44843-0`, `:ok/:stable`, exit 0, wall 96.821713 s:
257 test dei sette moduli oltre allo smoke, lint 48 file/zero violazioni,
trace 114 REQ/65 INV/13 FI/52 ADR/zero errori, links 187 file/1880 link/zero
rotti. Il master `4000521968-check-46180-0` contiene dieci run e dieci artifact:
SPK-01..10 tutti exit 0 e sorgenti `:stable`; nove `:ok`, SPK-07 `:pass`, con
statuti interni normalizzati corrispondenti. È conservato come prima
integrazione locale, senza attribuirlo al main successivo.

Il main successivo `201562dffd8c48e5d2047f73ef905f64b447e663` integra
le testate CBOR. ASDF finale SHA-256
`3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde`;
ready-types, ready, test, benchmark e runner restano byte-identici, e le
registrazioni execution/ready sono conservate accanto a codec e manifest.
Le campagne mirate iniziali e la nuova campagna mutazioni non vengono
attribuite retroattivamente al nuovo ambiente; sorgenti identici e check
integrato successivo conservano le rispettive provenienze. Non è una nuova
lettura C1 dei sorgenti CBOR o manifest.

Il check finale `4000522514-command-56618-0` è `:ok/:stable`, exit 0,
wall 102.063356 s. Il Makefile registra `make check` tramite il comando
interno `check-core`. Conteggi letti nel rapporto: 274 test degli otto moduli
(26+17 UTF-8+17 CBOR+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre
allo smoke; lint 50 file/zero violazioni; trace 114 REQ/65 INV/13 FI/52 ADR,
zero errori; links 193 file/1899 link, zero rotti. Stderr contiene note del
compilatore e progresso spike; nessun warning/style-warning reale. I guasti
sintetici previsti nei self-test delle evidenze restano dati attesi.

Il master finale `4000522582-check-59441-0`, letto tramite il lettore delle
evidenze, è `:complete`, mode `--check`, dieci run e dieci artifact. Tutti
SPK-01..10 sono exit 0/`:stable`; nove statuti `:ok`, SPK-07 `:pass`, e gli
statuti dei risultati interni normalizzati coincidono. Metadati raw:
SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, 17179869184 byte RAM, dieci CPU
logiche, dynamic-space 4096 MiB, carico esterno `:uncontrolled`, load-average
`{ 3.89 3.37 3.63 }`, commit `201562dffd8c48e5d2047f73ef905f64b447e663`,
date-universal-time 4000522586. Tempo del check e ambiente non sono risultati
di throughput/P99 o scalabilità.

La lettura indipendente sui dodici punti è chiusa per questo componente,
senza finding funzionali aperti: i due rilievi testuali iniziali e il rilievo
C4 sono chiusi. Il report storico verbatim e le appendici successive sono
conservati nella clone in `spikes/out/ready-main-independent-review.lisp`;
i nuovi probe di sola lettura in `spikes/out/ready-main-review-probes.lisp`.
Restano tutti i denominatori e le lacune raw sopra mappate, senza esclusioni
approvate o MC/DC dedotta. Pool, parcheggio/risvegli, shutdown, controller
FAULTED e target integrati del motore non sono qualificati da questi dati.

La chiusura locale definitiva segue il main
`33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691`, che registra anche il modulo CSN.
ASDF SHA-256 `6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc`;
i sorgenti execution/ready, i test e i due strumenti ready restano
byte-identici alle letture precedenti. Le registrazioni ASDF di ready sono
conservate. I check fd96 e 201562 sopra restano evidenze storiche delle
rispettive integrazioni; le campagne mirate conservano la loro provenienza.

Letto con `evidence:read-evidence`, il nuovo record
`4000522904-command-41347-0` è `:ok/:stable`, exit 0, wall 109.725672 s:
294 test dei nove moduli (26+17 UTF-8+17 CBOR+20 CSN+51 execution+44 storage+
18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 52 file/zero violazioni;
trace 114 REQ/65 INV/13 FI/52 ADR/zero errori; links 198 file/1918 link/zero
rotti. Nessuna riga di warning o style-warning reale nello stderr.

Il master `4000522979-check-41982-0` è `:complete`, mode `--check`, dieci run
e dieci artifact; SPK-01..10 exit 0/`:stable`, nove `:ok` e SPK-07 `:pass`,
con statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0,
ARM64 Apple M4, RAM 17179869184 byte, dieci CPU logiche, dynamic-space
4096 MiB, carico esterno `:uncontrolled`, load-average `{ 2.10 2.88 3.34 }`,
commit `33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691`, date-universal-time
4000522983. Si conferma la chiusura locale C1 senza finding ready aperti;
la lettura non qualifica i sorgenti CSN né il pool o il motore integrato.
Report originale e appendici fd96/201562/33 restano conservati verbatim;
nessuna riduzione dei denominatori raw o esclusione MC/DC è approvata.
