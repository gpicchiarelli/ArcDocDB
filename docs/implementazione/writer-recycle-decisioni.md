# Decisioni del ricircolo dei writer pronti

Inventario C1 di [`ready-recycle.lisp`](../../src/execution/ready-recycle.lisp),
secondo il [metodo preregistrato](writer-recycle-metodo.md). Riferimenti:
REQ-CON-001/002/004/005, REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8, INV-V4;
[ADR-0005](../adr/0005-writer-logico-per-serie.md) e
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md).

Il ricircolo riceve un obbligo `:schedule` unico del chiamante e lo
trasferisce al ring. Con spazio restituisce NIL/`:published`; con ring
pieno trasferisce simultaneamente la vecchia testa al chiamante e il nuovo
riferimento al ring, restituendo testa/`:writer`. Busy conserva l'obbligo
originario. Il componente non legge lo stato dei writer e non aggiunge
membership, thread, attese, callback, I/O o uno stato globale.

## Decisioni scalari e pre/postcondizioni

Nel nuovo sorgente non vi sono decisioni composte `and`/`or` in `if`,
`when`, `unless` o `cond`. L'`or` nei tipi dei ritorni è un'unione di tipi,
non una decisione composta di COD-54. L'inventario non deduce MC/DC dalla
copertura dei rami o dalla sola assenza di nuovi predicati composti.

I suffissi seguenti si riferiscono ai test `test-REQ-…-recycle-…` in
[`tests/execution/ready-recycle.lisp`](../../tests/execution/ready-recycle.lisp).
Descrivono fixture lette; non attestano ancora una loro esecuzione.

| Punto | Condizione o obbligo | Fixture letta e limite |
|---|---|---|
| `%scambia-pronto`: pre/post | `%check-pronta` controlla proprietà della guard e forma del ring prima e dopo le scritture. | `helper-rejects-missing-and-foreign-guard`; FI di forma; oracoli FIFO e wrap. I rami dei verificatori appartengono all'inventario ready precedente. |
| `%scambia-pronto`: pieno | Count uguale a capacity; altrimenti `invariant-violation :ready-recycle-full` prima delle scritture. | `malformed-full-head-and-free-tail-pre-mutation`: helper full chiamato su ring vuoto con guard posseduta; snapshot conservato. |
| `%scambia-pronto`: tipo testa | Il riferimento a head deve essere `writer-programmabile`; altrimenti `:ready-queue-invariant`, prima delle scritture. | Stessa fixture: full con testa NIL o keyword; ring e writer entrante conservati. Non viene effettuata una scansione dei payload non toccati. |
| `%scambia-pronto`: FIFO | In full la relazione verificata `tail = (head + count) mod capacity` implica head=tail. Si sostituisce quello slot e si avanzano entrambi gli indici di uno; count invariato. | `capacity-one-transfers-old-and-keeps-new`, `full-wrap-preserves-independent-list-order`, oracolo con seme. `[C,B,…,Z]` diventa `[B,…,Z,A]`; capacity 1 è `[C]`→`[A]`. |
| `%scambia-pronto`: ritorni | Vecchia testa verificata, `:writer`, capacity. A appartiene al ring; C al chiamante. | Identità/count/status negli oracoli; `returned-obligation-survives-begin-busy` conserva C senza ripubblicare A. |
| `%ricircola-pronto`: scelta | Count uguale a capacity sceglie lo scambio; count inferiore sceglie `%pubblica-pronto`. La forma verificata esclude count superiore. | Full e room, capacità 1/2/3/9, confine esatto e wrap. |
| `%ricircola-pronto`: post | Le postcondizioni sono verificate da `%scambia-pronto` o `%pubblica-pronto`; room restituisce NIL/`:published` e il nuovo count. | `room-publishes-and-preserves-fifo`; per room il tail libero viene verificato dal helper precedente. |
| API: partizione | `%partizione-verificata` precede guard e scritture; verifica indice, cardinalità e riferimento privato. | `shard-writer-preflight-before-held-guard`, `private-ring-and-partition-shapes-pre-mutation`; input invalidi vengono rifiutati anche con guard occupata. |
| API: tipo entrante | Writer di tipo `writer-programmabile`; altrimenti `invalid-argument :ready-writer` prima della guard. | Preflight: NIL, keyword, vettore e coda bassa; snapshot conservato. L'oggetto non viene interrogato per eleggibilità. |
| API: CAS busy | Acquisizione NIL causa `resource-exhausted :ready-queue-busy`, prima della mutazione; nessun retry. | `busy-retains-obligation-and-both-ring-shapes`: full e room, stesso obbligo conservato e successivo trasferimento unico. |
| API: cleanup | `unwind-protect` rilascia soltanto la guard dopo acquisizione verificata; errori non nascosti. | Successi, rifiuti e FI; ripubblicazione/drain successivi verificano guard libera. I rami difensivi del CAS restano nella copertura ready precedente. |
| Obblighi unici | A è un obbligo del chiamante; C appartiene al ring prima dello scambio. Sotto il protocollo legale C≠A. | Oracoli pubblici con `:schedule`, completamento prima del riuso; `private-opaque-duplicate-is-outside-handoff-protocol` è solo FI privata, senza qualificazione di deduplicazione. |
| Pieno dei consumer | Tutti i consumer possono avere un obbligo mentre il ring è full. Ricircolo consegna una testa senza un dequeue esterno preliminare. | `all-consumers-reschedule-after-producer-refills-full` conserva il controesempio alla sola pubblicazione; poi due rotazioni e drain dei payload residui. |
| Handoff/new wave | Nessun cleanup scheduler sul writer dopo end; l'obbligo della nuova ondata non viene cancellato. | `handoff-before-release-and-new-wave-without-cleanup`: enqueue prima di end e nuova ondata dopo idle. |
| Concorrenza | Producer, consumer e ricircolo accedono al ring sotto la medesima guard; nessuna guard tra shard. | Due consumer e un producer riusati; `other-shard-progresses-while-first-guard-is-held`. Fixture lette, esiti ancora da registrare. |

## Limiti della prova

Lo scambio elimina il blocco dovuto alla sola capienza nel protocollo
modellato. Non garantisce progresso se la guard rimane contesa, il
chiamante abbandona l'obbligo o il writer è faulted. Una catena full può
servire continuamente lo stesso shard e lasciare i nuovi producer pending:
equità globale e admission richiedono un controller. `:empty` resta una
sequenza di osservazioni locali, senza autorizzare parcheggio o shutdown.

Non vi sono cicli nel nuovo sorgente: costo O(1), una acquisizione e un
rilascio CAS. Le verifiche transitive di lista/forma sono bounded e non
scansionano tutto il ring. Gli invarianti sono segnalati al proprietario
che deve applicare fail-stop; il modulo non implementa ancora FAULTED
della Serie. Nessun cambiamento persistente o punto di atomicità durevole.

## Prima lettura indipendente C1

Base `673987ad819dd48741a7c0a4ff259137a1ed0bef`. Sorgente iniziale letto
SHA-256 `51ddbf06d1639427317ac25d00140ec2020be14b315ed364fd1ae425ebed145c`;
test letto SHA-256
`c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae`.
La prima riga del sorgente conteneva il refuso testuale `publica`, che il
responsabile della modifica correggerà. Nessun difetto funzionale trovato
nella prima lettura; non è un esito di compilazione, test o copertura.
Il report completo sui dodici punti è conservato come dato UTF-8 in
`spikes/out/recycle-c1-initial.lisp`, senza cambiare i sorgenti di prodotto.

I requisiti e gli ADR sono coerenti con le tre funzioni. Tipo della testa,
guard/forma, scambio FIFO e conservazione dell'obbligo hanno fixture
dedicate. Ftype completi, safety 3, funzioni sotto 60 righe, proprietari e
accessi per tratto sono dichiarati. Le condizioni restano tipizzate e il
cleanup non nasconde i guasti. Misura delle allocazioni, esecuzione dei test,
raw coverage, mutanti, tracciabilità e `make check` sono ancora in attesa.

## Denominatori execution precedenti e campagna da leggere

I sei file precedenti rimangono nello scope della futura copertura raw,
insieme a `ready-recycle.lisp`. La precedente campagna ready riportava i
seguenti denominatori; sono dati storici, non risultati attribuiti alla
nuova campagna. L'export futuro deve conservare native, HTML e tutti i
percorsi mancanti, verificando nuovamente i conteggi.

| File execution precedente | Espressioni marcate / totali storiche | Esiti marcati / totali storici |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| `ready-types.lisp` | 170 / 187 | 30 / 30 |
| `ready.lisp` | 173 / 194 | 20 / 22 |
| Totale precedente | 848 / 974 | 126 / 146 |

Le forme e i rami scoperti precedenti sono mappati integralmente nell'
[inventario ready](writer-ready-decisioni.md#copertura-raw-osservata-e-mappatura-delle-lacune).
Non vengono sottratti dal denominatore del ricircolo. I nuovi conteggi e la
loro mappatura attendono i dati congelati. Nessuna esclusione approvata,
nessuna promozione dei requisiti o inferenza di MC/DC completa.

## Copertura raw della copia congelata

La copia `arcdocdb-recycle-verify-7meus4m5`, base `673987a`, conserva native,
HTML ed export. Il probe indipendente `4000528971-command-81260-0` ricalcola
i vettori di percorsi e i bit del native con `*read-eval*` NIL e confronta
separatamente le celle HTML tramite `HTMLParser`: coincidono tutti i sette
file. Non viene sottratta alcuna forma. Il processo è `:ok/:stable`, exit 0.

| File execution | Espressioni marcate / totali | Esiti marcati / totali |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| `ready-types.lisp` | 170 / 187 | 30 / 30 |
| `ready.lisp` | 173 / 194 | 20 / 22 |
| `ready-recycle.lisp` | 81 / 86 | 8 / 8 |
| Totale | 929 / 1060 | 134 / 154 |

Il native conserva tutti i percorsi. Gli indici sono inversi: l'ultimo
identifica la forma top-level; leggendoli da destra a sinistra si scende nei
sottoelementi. Ogni errore radice sotto elencato contiene quattro forme raw:
chiamata, designatore, keyword `:reason` e ragione. Le radici e le forme di
definizione/default seguenti mappano tutte le 131 espressioni non marcate.

| File | Tutte le forme non marcate e mappatura |
|---|---|
| `package.lisp`, 1 | `(0)`: `defpackage`, inclusa la nuova esportazione. |
| `queue.lisp`, 42 | 22 definizioni/default: top-level `(0) (1) (2) (3) (5) (7) (9) (11) (13) (15)`; dieci slot `(3 4)`..`(12 4)`; keyword `(1 2 12) (2 2 12)`. Venti forme nei cinque errori radice `(2 2 4 6) (2 3 4 6) (2 3 4 8) (2 4 10) (2 5 10)`: forma/FIFO, proprietà dopo acquisizione, proprietà e CAS del rilascio. |
| `writer.lisp`, 28 | Otto top-level `(0) (1) (2) (4) (6) (8) (10) (12)`. Venti forme negli errori radice `(2 5 3) (2 4 5) (2 5 5) (2 1 1 3 4 7) (2 6 2 1 2 4 3 5 11)`: quota lease, proprietà/CAS owner, proprietà di acquisizione e postcondizione del prelievo. |
| `handoff.lisp`, 17 | Nove top-level `(0) (1) (3) (5) (7) (9) (11) (13) (15)`; due slot `(3 2) (4 2)`; due default `(1 2 8) (2 2 8)`. Quattro forme nell'errore `otherwise` dello stato, radice `(1 5 4 4 6)`. |
| `ready-types.lisp`, 17 | Otto top-level `(0) (1) (2) (3) (6) (8) (10) (12)`; sette slot `(3 4)`..`(8 4)` e `(3 5)`; due default factory `(1 2 13) (2 2 13)`: definizioni, slots/capacity/head/tail/count/guard/partitions, default shards/capacity. |
| `ready.lisp`, 21 | Nove top-level `(0) (1) (2) (4) (6) (8) (10) (12) (14)`. Dodici forme in tre errori radice `(2 3 4 3) (2 5 5) (1 5 3 2 2 5 15)`: proprietà dopo acquisizione, vecchio valore CAS di rilascio, stato difensivo inatteso della scansione. |
| `ready-recycle.lisp`, 5 | Solo top-level `(0) (1) (2) (4) (6)`: `in-package`, ottimizzazione e tre `ftype`. Nessuna forma operativa mancante nel native; le definizioni restano nel denominatore. |

Tutti i venti esiti strumentati non marcati appartengono ai file precedenti:

| File | Tutti i percorsi degli esiti non marcati |
|---|---|
| `queue.lisp`, 10 | `(:then 3 9 4)`, `(:else 3 9 4)`, `(:else 3 1 2 4 6)`, `(:else 2 1 2 4 6)`, `(:else 1 1 2 4 6)`, `(:else 1 2 4 6)`, `(:else 1 3 4 6)`, `(:else 1 3 4 8)`, `(:else 1 4 10)`, `(:else 1 5 10)`: unione tipo guard, limiti/forma/FIFO, proprietà e CAS. |
| `writer.lisp`, 8 | `(:else 1 1 5 3)`, `(:else 1 5 3)`, `(:else 1 4 5)`, `(:else 1 5 5)`, `(:else 1 1 1 1 3 4 7)`, `(:else 1 1 1 3 4 7)`, `(:else 1 1 6 2 1 2 4 3 5 11)`, `(:else 1 6 2 1 2 4 3 5 11)`: quota, proprietà/CAS owner, pre/post acquisizione e prelievo. |
| `ready.lisp`, 2 | `(:else 1 3 4 3)` e `(:else 1 5 5)`: proprietà dopo CAS riuscito e vecchio valore CAS al rilascio dopo precontrollo. Non provocati alterando una guard condivisa durante prove concorrenti. |
| Gli altri quattro file | Nessun esito strumentato non marcato. Questo non qualifica MC/DC o tutti i controlli sorgente. |

La copertura `4000528494-command-77200-0` e l'export con self-test
`4000528526-command-77598-0` sono `:ok/:stable`, exit 0. Il primo probe
indipendente `4000528942-command-81018-0` è fallito perché il native,
che non è una plist, era stato passato al lettore delle evidenze. La prima
versione dell'adapter e il fallimento sono conservati; il probe corretto
legge direttamente il native con `*read-eval*` NIL. Non è un guasto di
prodotto, export o C4, e non sostituisce la campagna di copertura.

## Seconda lettura indipendente C1

Sorgente finale SHA-256
`2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b`;
test invariato `c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae`.
La sola correzione rispetto alla prima lettura è `publica`→`pubblica` nel
commento iniziale. Report indipendente completo sui dodici punti:
`spikes/out/recycle-c1-final.lisp`. Nessun finding funzionale aperto.

Letti i record tramite `evidence:read-evidence`, con payload compressi
validati. Gli strict C4 `4000528528-command-77652-0` e
`4000528528-command-77653-0` sono `:ok/:stable`, exit 0: COMPILE-FILE
intero e self-test dei FASL. La fixture SIGKILL
`4000528529-recycle-signal-self-test-77690` riporta exit 137, signal 9,
un worker-error e zero detected; baseline pending riguarda solo la fixture.

Mutazioni `4000528603-command-78553-0`, dati `recycle-mutations/report.lisp`:
baseline completa con 66 start/ok e completion 66; 11/11 detected,
zero survived/compilation-failures/before-tests/worker-errors. Letti tutti
i dodici log: i guasti avvengono dopo start di un test recycle e prima
completion, ciascuno exit 1/signal NIL; baseline exit 0/signal NIL.

Benchmark `4000528603-command-78552-0`, dati
`recycle-allocations/report.lisp`: quattro configurazioni K=1/4 e C=1/3,
cinque campioni di 4096 cicli ciascuna; tutti i venti riportano heap zero.
Token e sink ricalcolati indipendentemente: 257/9439232, 558/10672128,
1223/13395968, 3231/21620736, nell'ordine (1,1)/(1,3)/(4,1)/(4,3).
Controllo positivo 16777472 byte, sink errato rifiutato; clock zero,
report parziale e destinazione preesistente restano controlli distinti.
Nessuna prova universale di non allocazione, speedup, throughput o P99.

Il check `4000528494-command-77199-0`, `:ok/:stable`, exit 0,
wall 107.748252 s, riporta 309 test dei nove moduli oltre allo smoke:
26+17 UTF-8+17 CBOR+20 CSN+66 execution+44 storage+18 I/O+82 recovery+19 WAL.
Lint 53 file/zero violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/zero errori;
links 199 file/1921 link/zero rotti. Nessuna riga di warning/style-warning
reale rilevata. Il master `4000528568-check-78100-0` è complete con dieci
run e dieci artifact: tutti exit 0/stable, nove `:ok` e SPK-07 `:pass`.
I guasti attesi dei self-test del repository rimangono dati attesi.

Questa chiusura riguarda il ricircolo locale sulla base congelata.
Non qualifica gli altri componenti letti soltanto per integrazione, il
pool completo, wake/park, shutdown, admission o il controller FAULTED.
Tutti i denominatori e le lacune raw restano visibili, senza esclusioni
approvate, promozioni dei requisiti o MC/DC dedotta.
