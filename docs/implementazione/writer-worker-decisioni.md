# Decisioni del contesto worker dei writer

Inventario C1 dei quattro sorgenti
[`worker-types.lisp`](../../src/execution/worker-types.lisp),
[`worker-boundary.lisp`](../../src/execution/worker-boundary.lisp),
[`worker-claim.lisp`](../../src/execution/worker-claim.lisp) e
[`worker-run.lisp`](../../src/execution/worker-run.lisp), secondo il
[metodo preregistrato](writer-worker-metodo.md). Riferimenti:
REQ-CON-001/002/004/005, REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4;
[ADR-0005](../adr/0005-writer-logico-per-serie.md) e
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md).

Il contesto appartiene al thread che lo crea e non è rientrante. Le fasi
idle, claimed, running, batch, finishing e reschedule rappresentano
rispettivamente assenza di obblighi, obbligo pronto, lease attiva, batch
da confermare, termine da completare e obbligo da ricircolare. La settima
fase faulted è terminale e conserva la condizione originale. Il contesto
non possiede il payload del buffer del caller: conserva il numero di
messaggi da confermare. L'ack attesta l'elaborazione del caller e non
verifica gli effetti esterni.

## Decisioni e pre/postcondizioni

Nei quattro nuovi sorgenti letti non vi sono decisioni composte `and`/`or`
con più condizioni in `if`, `when`, `unless` o `cond`. Le unioni `or`
nei tipi non sono decisioni COD-54. I controlli composti delegati alle
API writer/ready rimangono nei loro inventari e nello scope raw execution.
L'assenza di nuovi predicati composti non dimostra MC/DC.

La tabella descrive le decisioni del codice rivisto dopo i finding della
prima lettura. Le fixture finali sono state lette e i loro esiti sono
compresi nella baseline execution di 89 test. La mappatura nominale
seguente distingue test reali, FI privata e limiti della prova; non
trasforma i percorsi scoperti in esclusioni.

| Punto | Decisione o obbligo | Fixture letta e limite |
|---|---|---|
| `%check-owner-worker` | Identità con il thread corrente; altrimenti `invalid-argument :worker-owner`, prima delle scritture. | Chiamate da thread diverso in ogni fase con snapshot del contesto, writer e ready. Il riferimento restituito dai getter non trasferisce proprietà. |
| `%check-libero-worker` | Tre verifiche scalari: writer NIL, lease zero, pending zero. | FI indipendente dei tre campi in idle; nessuna cancellazione per riparare un'incoerenza. |
| `%check-obbligo-worker` | Writer del tipo atteso, lease zero, pending zero in claimed/reschedule. | FI di riferimento, lease e debito; adozione/cessione e ricircolo legalmente senza lease. |
| `%check-lease-worker` | Tipo del writer, poi lease/owner/generation/quota delegati a `%check-lease`. | FI del riferimento e della lease privata; condizioni delegate non vanno classificate tutte come contese. |
| `%check-attivo-worker` | Lease corrente e pending zero in running/finishing. | FI pending positivo; prima contesa del termine e retry successivi conservano lease/ref. |
| `%check-batch-worker` | Lease corrente, pending positivo e ≤extracted, batch-generation positiva. | FI indipendente pending zero/eccessivo e generation zero; extracted≤quantum viene verificato dal delegato lease. Conservazione del debito durante operazioni fuori fase. |
| `%check-worker` | Owner, fault NIL, cursor/home<size verificati come invarianti private, poi validazione ready; `case` delle sei fasi operative con errore esplicito per stato inatteso. | FI separata cursor/home fuori range e fault non NIL in fase operativa; un indice privato malformato non viene classificato come input adozione recuperabile. I verificatori transitivi restano nello scope. |
| `%richiedi-worker` | Fase uguale a quella richiesta; altrimenti `resource-exhausted :worker-state`. | Ogni API nelle fasi vietate: nessuna mutazione. Questo motivo non identifica una guard busy. |
| Factory | Start validato prima della costruzione; postcondizioni idle verificate. | Limiti shard, owner creatore, riferimento ready read-only e assenza di nuovi thread. Allocazione ammessa all'avvio. |
| Getter | Solo owner preflight; stato o riferimento locale senza verificare il writer sotto guard. | Diagnostiche anche su contesto incoerente; nessuna adozione implicita, deduplicazione o revoca. |
| Classifier: tipo resource | Solo `resource-exhausted` passa al confronto con la lista resources del passo. | Tipo diverso con la stessa ragione non è recuperabile; ragione resource non prevista è fault permanente. |
| Classifier: ragione resource | `member` nella allowlist letterale del passo termina senza scritture. | Busy attesi e worker-state, overflow locale solo su pop; not-ready e writer-generation diventano faulted. Liste con al più tre elementi, nessun retry. |
| Classifier: tipo invalid | Solo `invalid-argument` passa al confronto con la lista arguments del passo. | Input typed errato con ragione attesa conserva il contesto; invalid-argument :writer-lease privata diventa faulted. |
| Classifier: ragione invalid | `member` nella allowlist letterale del passo termina senza scritture. | Target/ack/adozione invalidi; ragioni uguali nella classe errata e ragioni inattese diventano faulted. Liste con al più due elementi. |
| Classifier: fault | Condizione originale memorizzata e fase faulted; identità della condizione e stato terminale verificati separatamente dopo le scritture. | Errori interni e runtime: stessa condition propagata, ref/lease/debito/generation conservati; nessuna riparazione o reset. |
| Macro: preflight | Contesto valutato una volta; owner verificato prima del handler; gate faulted rifiuta prima del corpo e non sostituisce la diagnosi. | Test di espansione e comportamento: valutazione unica, wrong-thread, gate terminale, preservazione dei valori multipli e identità della condition. |
| Macro: handler | `handler-bind (error …)` al confine worker, handler `dynamic-extent`; registra/transiziona e lascia propagare l'errore. | Eccezione COD-21 con stato/diagnosi definiti; strict compile e heap misurati. Nessun callback applicativo o errore nascosto. |
| `%assegna-worker` | Writer valido; solo idle/reschedule; commit ref/home/claimed e verifica finale. | Take riuscito e ricircolo full con identità/home; errore interno dopo trasferimento è fail-stop, senza rollback promesso. |
| Take: esiti | `:writer` trasferisce al contesto; `:empty/:busy` conservano idle; esito inatteso è invariante. Cursor viene aggiornato per tutti gli esiti. | Scansione ruotata, shard occupato e shard indipendente, sentinel ready; empty è osservazione locale. |
| Take: home | Home è `(next−1) mod K`, ricavata dall'esito ready, senza lookup del writer. | K=1 e K>1, candidato oltre shard iniziale, wrap del cursore. |
| Begin | Solo claimed; handoff restituisce lease, poi commit running e postcheck. | Busy conserva tutti i campi; not-ready/writer-generation causano faulted locale e impediscono di consumare un'onda futura. Nessun messaggio è estratto da begin. |
| Ricircolo: full | Vecchia testa validata dalle API ready diventa claimed nello stesso home; il writer uscente appartiene al ring. | Capacity 1, wrap e più consumer con obblighi e ring pieno; conservazione esatta del numero di obblighi. |
| Ricircolo: room | Risultato writer NIL verificato, ref eliminato e idle; `otherwise` è invariante. | Room, count/status/identità, busy senza ripetere end, nessun cleanup del writer dopo la pubblicazione. |
| Adozione | Solo idle; tipo del writer e home validati prima delle scritture. | Input invalidi anche in presenza di guard occupata; obbligo unico non nel ring è precondizione del caller, senza ricerca membership. |
| Cessione | Solo claimed/reschedule; writer valido; commit idle e restituzione writer/home. | Nessuna cessione da running/batch/finishing; generation persistente, trasferimento esplicito a nuovo contesto dopo esaurimento. |
| Pop: preflight | Running senza debito; target/span/alias controllati prima dell'overflow della generation. | Tipo/range/buffer alias malformati e ordine delle condizioni; nessuna estrazione o modifica del buffer al rifiuto. |
| Pop: overflow | Generation uguale a `most-positive-fixnum` rifiuta con `:worker-generation` prima di pop. | Nessun wrap o incremento, anche quando il pop sarebbe empty/yield; end e successiva cessione restano disponibili. |
| Pop: messages | Count positivo verificato; incremento unico della generation; pending=count e batch. | Token crescente su tranche e writer diversi, quota cumulativa, buffer sentinel; nessun token globale tra contesti. |
| Pop: empty/yield | Count deve essere zero; running, pending e generation conservati; token restituito zero. | Entrambi gli esiti e quota esaurita dopo ack; esito/count inattesi sono invarianti. |
| Ack | Token del tipo index, positivo e uguale alla generation corrente, tre verifiche scalari prima delle scritture. | Zero, negativo, tipo errato, stale dal batch precedente e token diverso; ack corretto cancella solo pending e torna running. |
| `%concludi-worker` | Dopo end: owner, finishing, pending zero; lease azzerata e `:idle/:schedule` espliciti. | Idle libera ref; schedule conserva obbligo in reschedule. Non si ricontrolla la vecchia lease già rilasciata dall'handoff. |
| End | Solo running/finishing; latch finishing prima di handoff, poi conclusione locale. | Primo busy cambia solo fase; retry conserva tutto; vietati nuovi pop/ack e cessione. End non viene ripetuto dopo reschedule. |
| Nuova onda | Nessuna scrittura sul writer dopo end per correggere membership o scheduling. | Enqueue prima del rilascio e nuova onda dopo idle; conservazione dell'obbligo del nuovo producer. |

## Limiti del protocollo

Ogni passo mutante usa il confine worker. Le allowlist sono per tipo e
operazione, senza recupero generico di resource-exhausted:

| API | Ragioni resource recuperabili | Ragioni invalid recuperabili |
|---|---|---|
| Take | worker-state | Nessuna |
| Begin | worker-state, writer-queue-busy | Nessuna |
| Ricircolo | worker-state, ready-queue-busy | Nessuna |
| Adozione | worker-state | worker-writer, ready-target del parametro home |
| Cessione | worker-state | Nessuna |
| Pop | worker-state, worker-generation, writer-queue-busy | writer-target |
| Ack | worker-state | worker-batch |
| End | worker-state, writer-queue-busy | Nessuna |

Factory e getter non hanno handler. Wrong-thread precede il confine e non
può avvelenare il contesto di un altro proprietario. Il gate faulted
restituisce resource-exhausted :worker-state; la diagnosi originale resta
accessibile da errore-worker-writer e non viene sovrascritta.

L'uniquità degli obblighi è una precondizione del caller e del protocollo
handoff. Adozione, cessione e getter non verificano membership globale.
Il buffer deve essere privato al caller e deve essere elaborato prima
dell'ack. La coppia contesto/token identifica un batch locale; lo stesso
intero può comparire su contesti diversi e non è una capacità globale.

Busy di begin/pop/recycle conserva i campi locali. Take può ruotare cursor
anche su empty/busy. End imposta finishing prima della chiamata, così un
busy non permette di estrarre o rielaborare altri messaggi. Gli altri
resource-exhausted, inclusi fase, not-ready e generation, non sono
automaticamente retry di contesa.

La versione rivista implementa il fault locale persistente e impedisce
anche cessione/adozione dopo errori permanenti; non implementa il
controller FAULTED della Serie. L'handler di confine applica la
transizione e registra la condizione originale secondo COD-21; il
controller dovrà applicare il fail-stop alla Serie secondo COD-24.
Nessun rollback è promesso dopo una mutazione o un trasferimento già
riuscito; i campi conservati sono diagnostici e non autorizzano replay.

Il ricircolo full evita il blocco dovuto alla sola capienza nel protocollo
modellato. Catene full possono restare sullo stesso shard: equità globale,
admission, wake/park, shutdown e adattamento dei pool rimangono da integrare.
Empty non autorizza park o arresto. Non vi sono nuovi cicli, attese,
callback, I/O o scritture globali per messaggio; la scansione ready e la
copia bounded sono delegate. Nessun cambiamento durevole viene introdotto.

## Prima lettura indipendente C1

Base `cf6091367853ec311fed7b05961a2812fd05a8f1`. Hash SHA-256 esatti
della prima lettura con le API adotta/cede:

| Sorgente | SHA-256 letto |
|---|---|
| `worker-types.lisp` | `db42690ceabe1c2ed0dd28c2aeaa99244ed745565197cf52fb127c1356194e3b` |
| `worker-claim.lisp` | `b8e35a594f8b225ca69ca06310efb3ae7683460c2480781acebd2f68197553ab` |
| `worker-run.lisp` | `feedbeb14815d546d234bf9eed69002aa6bf0d1a82daad81d3f154b41410c379` |

Le seguenti conclusioni sono lettura indipendente del codice; non sono
esiti di test, compilazione, mutazioni o misure.

1. REQ e ADR sono indicati e coerenti con il componente locale a tratti;
   nessuna qualificazione del pool intero.
2. Invarianti di owner, fase, lease, obbligo e debito sono espliciti; serve
   rafforzare il limite superiore del debito batch e leggere le fixture finali.
3. Condizioni tipizzate; input invalidi precedono le mutazioni, contese
   conservano gli obblighi. Il fail-stop è affidato al caller: nessun poison
   locale protegge da retry dopo fault permanente.
4. Nessun nuovo ciclo o attesa; bounded sono i delegate ready e writer.
5. Campagna heap non ancora letta; costruzione all'avvio e percorso locale
   scalare non sostituiscono la misura.
6. Esiti/count/token sono controllati e hanno tipi completi. Getter sono
   diagnostiche owner-only, senza trasferimento implicito.
7. Nessuna nuova decisione composta; controlli scalari/case inventariati
   sopra, nessuna inferenza MC/DC.
8. Owner immutabile locale, ready read-only; accesso ai ring tramite i loro
   protocolli. Work/ack fuori dalle guard condivise.
9. Commenti REQ presenti; trace/check congelati e test finali ancora da leggere.
10. Safety 3, ftype e slot typed, pre/post delegate, funzioni brevi. Nessun
    handler generico aggiunto. Il confine FAULTED non è realizzato qui.
11. Ready è toccata per tratto, nessuna coda globale per messaggio e nessuna
    nuova attesa. Fairness e scalabilità non sono misurate da questa lettura.
12. Nessuna operazione durevole, rimozione o punto di atomicità persistente.

La prima lettura e i due finding iniziali sono conservati integralmente in
`spikes/out/worker-c1-initial.lisp`. Prima delle campagne sono stati
aggiunti il confine terminale e pending≤extracted. Nella rilettura del
confine è stato segnalato un terzo rischio: :ready-target di adotta
comprendeva anche cursor/home privati corrotti. Il responsabile ha
separato questi errori con verifiche private che segnalano invariant-violation
:worker-state prima della validazione delegata. Le tre correzioni sono
presenti nei sorgenti riletti; gli esiti FI restano da leggere.

Hash esatti della rilettura preliminare con il confine corretto:

| Sorgente | SHA-256 letto |
|---|---|
| `worker-types.lisp` | `6f3209f1ba390e4fb38d9bd6250dc1f1a5d34daa0510e65f7b8ef85310777754` |
| `worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |
| `worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |
| `worker-run.lisp` | `60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847` |

La nuova lettura chiude sul codice i finding dei punti 2/3/10, senza
attribuirgli esiti non ancora misurati. Occorrono fixture del confine,
espansione della macro, classi/ragioni incrociate, fault permanente e
indici privati corrotti. I dodici punti saranno completati sui dati finali.

## Denominatori execution da conservare

L'ultima campagna recycle conserva i sette file precedenti. I seguenti
conteggi sono storici e non attribuiti al nuovo worker; la campagna nuova
deve rileggere tutti e undici i file, senza sottrarre forme o rami.

| File execution precedente | Espressioni marcate / totali storiche | Esiti marcati / totali storici |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| `ready-types.lisp` | 170 / 187 | 30 / 30 |
| `ready.lisp` | 173 / 194 | 20 / 22 |
| `ready-recycle.lisp` | 81 / 86 | 8 / 8 |
| Totale precedente | 929 / 1060 | 134 / 154 |

La mappatura integrale delle forme e degli esiti scoperti è conservata
nell'[inventario recycle](writer-recycle-decisioni.md#copertura-raw-della-copia-congelata).
I denominatori dei quattro file worker, i percorsi raw nuovi, il confronto
native/HTML/export e la seconda lettura attendono i dati congelati.
Nessuna esclusione approvata, promozione dei requisiti o MC/DC dedotta.

## Seconda lettura indipendente C1

La copia `arcdocdb-worker-verify-hzghjzb6` conserva il codice congelato
sulla base `cf60913`. I quattro SHA finali sono quelli della rilettura
preliminare sopra, salvo `worker-types.lisp`, ora
`62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317`:
la successiva correzione cambia soltanto la docstring sugli indici privati.
Test finale SHA
`ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06`.
Report completo sui dodici punti: `spikes/out/worker-c1-final.lisp`.
Nessun finding funzionale aperto; qualificazione C1 del motore ancora aperta.

Le 23 fixture nuove di
[`tests/execution/worker.lisp`](../../tests/execution/worker.lisp) sono
identificate qui dal suffisso dopo `test-REQ-…-worker-`:

| Controlli | Fixture lette e natura della prova |
|---|---|
| Factory/idle/cursor | `factory-preflight-and-empty-cursor-rotation`, `claim-batch-ack-and-idle-release`; start/bounds, idle senza obblighi, rotazione anche su empty. |
| Lease/quota/batch | `quantum-yield-reschedule-and-monotone-tokens`, `batch-debt-blocks-more-pop-finish-and-transfer`; quota cumulativa e divieto di abbandonare debito. |
| Ack e target | `current-token-required-and-stale-ack-keeps-debt`, `buffer-range-and-private-alias-preflight`; token corrente, input invalidi e sentinelle. |
| Contese | `begin-busy-retains-claimed-reference`, `pop-busy-retains-lease-buffer-and-generation`, `end-busy-is-finishing-and-blocks-new-pop`; snapshot, latch iniziale e retry senza rielaborazione. |
| Home/full/room/nuova onda | `scanned-home-and-full-recycle-retained-on-busy`, `two-contexts-full-refill-preserves-all-obligations`, `empty-observation-and-new-wave-after-idle`; capienza piena, trasferimenti FIFO e obblighi conservati. |
| Owner e trasferimenti | `foreign-thread-refuses-all-six-phases`, `cede-adopt-validates-home-and-single-caller-obligation`; wrong-thread pre-mutation, nessuna cessione di lease/batch. |
| Esaurimento | `local-generation-limit-can-cede-into-fresh-context`, `generation-overflow-precedes-empty-and-yield-pop`; FI scalare senza reset di generation durante i benchmark, fine e trasferimento senza lease ancora disponibili. |
| Oracolo | `seeded-independent-obligations-payloads-and-batch-debt`: 13 writer, 8 configurazioni, 8000 passi e drain contro liste indipendenti. È un oracolo con seme, non esplorazione esaustiva del pool. |
| FI interna | `private-shapes-and-pending-count-invariants`: 14 forme private corrotte, checker senza confine e ripristino quiescente della sola FI. `private-index-corruption-poisons-before-adopt`: cursor/home/fault incoerenti attraverso la API pubblica, senza trasferire l'obbligo del caller. |
| Macro/classifier | `boundary-expansion-values-once-and-error-identity`: espansione, valutazione unica, valori multipli, errori recuperabili e permanenti sintetici, runtime error, identità della condition e tutti i gate terminali. |
| Fault/nuova onda | `stale-not-ready-reference-cannot-steal-new-wave`: FI dichiarata di riferimento stale; il vecchio contesto resta faulted prima/dopo enqueue della nuova onda e wrong-thread, mentre il contesto fresco la consuma. Nessuna deduplicazione pubblica qualificata. |
| Concorrenza | `reused-owner-contexts-live-producers-and-independent-shards`: quattro thread riusati, sei ondate, 36 payload CRC e progresso dello shard indipendente. `competing-owner-contexts-claim-one-obligation-per-wave`: due consumer riusati, otto ondate e un solo vincitore per obbligo. |

## Copertura raw e tutte le lacune

Il probe `4000547296-command-98426-0`, OK/STABLE/exit0, ricalcola native
e confronta HTML ed export, inclusi tutti i percorsi mancanti. Dati:
`worker-review-coverage-data.lisp`; adapter `worker-review-coverage.lisp`
e `worker-review-html.py`. Native SHA
`2a9d546c77fc1a43690497bf7b46ff261a3ea8cde77766de5f91b8074e2b42d6`,
export SHA
`787b1ad0604b98c46690dd4655638d7ff7de4d4cf5f71864235fdc4c5244f09b`.
Copertura `4000547204-command-93188-0` ed export con fixture del
denominatore `4000547249-command-95826-0`: OK/STABLE/exit0.

| File execution | Espressioni marcate / totali | Esiti marcati / totali |
|---|---|---|
| `package.lisp` | 0 / 1 | 0 / 0 |
| `queue.lisp` | 142 / 184 | 24 / 34 |
| `writer.lisp` | 190 / 218 | 36 / 44 |
| `handoff.lisp` | 173 / 190 | 16 / 16 |
| `ready-types.lisp` | 170 / 187 | 30 / 30 |
| `ready.lisp` | 173 / 194 | 20 / 22 |
| `ready-recycle.lisp` | 81 / 86 | 8 / 8 |
| `worker-types.lisp` | 195 / 224 | 36 / 38 |
| `worker-boundary.lisp` | 40 / 51 | 10 / 12 |
| `worker-claim.lisp` | 143 / 175 | 5 / 8 |
| `worker-run.lisp` | 120 / 150 | 14 / 18 |
| Nuovi quattro file | 498 / 600 | 65 / 76 |
| Totale | 1427 / 1660 | 199 / 230 |

Gli indici sono inversi: l'ultimo identifica la forma top-level, poi si
scende da destra a sinistra. Il probe `4000547596-command-16195-0`,
OK/STABLE/exit0, legge i quattro sorgenti con read-eval NIL, senza
valutarli, ed enumera tutti i top-level e ogni forma scoperta in
`worker-review-forms-data.lisp`. I percorsi di claim/run attraversano il
nodo sorgente `%passo-worker` prima del corpo; la macro non viene eseguita
dal lettore. I conteggi sb-cover non certificano separatamente ogni
istruzione generata dal gate/handler della macro. La fixture di espansione
e comportamento verifica quel protocollo, senza inferire MC/DC.

Ogni radice di errore sotto indicata contiene quattro espressioni raw:
chiamata, designatore, keyword :reason e ragione. Le seguenti righe
mappano tutte le 233 espressioni non marcate, incluse le 131 precedenti:

| File | Tutte le forme non marcate |
|---|---|
| `package.lisp`, 1 | Top-level `(0)`, defpackage con le nuove esportazioni. |
| `queue.lisp`, 42 | 22 definizioni/default: top-level `(0) (1) (2) (3) (5) (7) (9) (11) (13) (15)`; dieci slot `(3 4)`..`(12 4)`; keyword `(1 2 12) (2 2 12)`. Venti forme nei cinque errori radice `(2 2 4 6) (2 3 4 6) (2 3 4 8) (2 4 10) (2 5 10)`: forma/FIFO, proprietà dopo acquisizione, proprietà/CAS del rilascio. |
| `writer.lisp`, 28 | Otto top-level `(0) (1) (2) (4) (6) (8) (10) (12)`. Venti forme negli errori radice `(2 5 3) (2 4 5) (2 5 5) (2 1 1 3 4 7) (2 6 2 1 2 4 3 5 11)`: quota, proprietà/CAS owner, acquisizione e postcondizione del prelievo. |
| `handoff.lisp`, 17 | Nove top-level `(0) (1) (3) (5) (7) (9) (11) (13) (15)`; due slot `(3 2) (4 2)`; due default `(1 2 8) (2 2 8)`. Quattro forme nell'otherwise dello stato, radice `(1 5 4 4 6)`. |
| `ready-types.lisp`, 17 | Otto top-level `(0) (1) (2) (3) (6) (8) (10) (12)`; sette slot `(3 4)`..`(8 4)` e `(3 5)`; due default factory `(1 2 13) (2 2 13)`. |
| `ready.lisp`, 21 | Nove top-level `(0) (1) (2) (4) (6) (8) (10) (12) (14)`. Dodici forme in tre errori radice `(2 3 4 3) (2 5 5) (1 5 3 2 2 5 15)`: proprietà dopo acquisizione, CAS rilascio, esito inatteso della scansione. |
| `ready-recycle.lisp`, 5 | Solo top-level `(0) (1) (2) (4) (6)`: in-package, ottimizzazione, tre ftype. |
| `worker-types.lisp`, 29 | Quattordici top-level: `(0) (1)` e dispari `(3)`..`(25)`; dieci slot `(3 2)`..`(12 2)`; default start `(2 2 20)`. Quattro forme nell'otherwise di `%check-worker`, radice `(1 6 9 16)`: stato fuori dalle sei fasi operative, non raggiunto attraverso il gate pubblico faulted. |
| `worker-boundary.lisp`, 11 | Tre top-level `(0) (1) (2)`. Otto forme in due errori radice `(2 7 3) (2 8 3)`: postcondizioni dell'identità della condition appena registrata e della fase appena impostata. Non provocate corrompendo il contesto durante il handler. |
| `worker-claim.lisp`, 32 | Otto top-level `(0) (1) (2) (4) (6) (8) (10) (12)`. Ventiquattro forme in sei errori radice: `(2 5 3)` e `(1 3 6 3)` tipo/fase di `%assegna-worker`; `(1 4 4 2 3 4 5)` esito take inatteso; `(2 1 3 3 3 4 9)` writer non NIL su published; `(1 4 3 3 4 9)` esito ricircolo inatteso; `(2 2 4 4 13)` tipo writer di cessione dopo precheck. |
| `worker-run.lisp`, 30 | Sei top-level `(0) (1) (2) (4) (6) (8)`. Ventiquattro forme in sei errori radice: `(2 1 2 3 5 4 3)` count non positivo per messages; `(2 1 3 3 5 4 3)` count non zero per empty/yield; `(1 4 3 5 4 3)` esito pop inatteso; `(2 5 7)` e `(2 6 7)` fase/debito incoerenti di `%concludi-worker`; `(1 4 8 7)` esito end inatteso. Sono difese dopo verificatori/esiti dei delegate, non nuove esclusioni. |

Tutti i 31 esiti strumentati non marcati sono esplicitati di seguito:

| File | Tutti i percorsi degli esiti non marcati |
|---|---|
| `queue.lisp`, 10 | `(:then 3 9 4)`, `(:else 3 9 4)`, `(:else 3 1 2 4 6)`, `(:else 2 1 2 4 6)`, `(:else 1 1 2 4 6)`, `(:else 1 2 4 6)`, `(:else 1 3 4 6)`, `(:else 1 3 4 8)`, `(:else 1 4 10)`, `(:else 1 5 10)`: tipo guard, limiti/forma/FIFO, proprietà/CAS. |
| `writer.lisp`, 8 | `(:else 1 1 5 3)`, `(:else 1 5 3)`, `(:else 1 4 5)`, `(:else 1 5 5)`, `(:else 1 1 1 1 3 4 7)`, `(:else 1 1 1 3 4 7)`, `(:else 1 1 6 2 1 2 4 3 5 11)`, `(:else 1 6 2 1 2 4 3 5 11)`: quota, proprietà/CAS e pre/post del prelievo. |
| `ready.lisp`, 2 | `(:else 1 3 4 3)`, `(:else 1 5 5)`: proprietà dopo acquisizione e vecchio valore CAS al rilascio. |
| `worker-types.lisp`, 2 | `(:then 3 7 2)`, `(:else 3 7 2)`: unione del tipo dello slot writer `(or null writer-programmabile)`, non predicato operativo COD-54. Restano nel denominatore. |
| `worker-boundary.lisp`, 2 | `(:else 1 7 3)`, `(:else 1 8 3)`: fallimento delle due postcondizioni dopo registrazione del fault. |
| `worker-claim.lisp`, 3 | `(:else 1 5 3)`, `(:else 1 1 3 3 3 4 9)`, `(:else 1 2 4 4 13)`: tipo assegnato, NIL del risultato published, tipo ceduto dopo precheck. |
| `worker-run.lisp`, 4 | `(:else 1 1 2 3 5 4 3)`, `(:else 1 1 3 3 5 4 3)`, `(:else 1 5 7)`, `(:else 1 6 7)`: count messages/empty-yield e fase/debito della conclusione dopo end. |
| Gli altri quattro file | Nessun esito strumentato non marcato; nessuna inferenza MC/DC. |

## Campagne lette e dodici punti finali

Il probe `4000547689-command-21967-0`, OK/STABLE/exit0, legge i record
con evidence:read-evidence e tutti i tredici log. Baseline 89 start/ok e
completion 89, exit0/signal NIL; 12/12 detected, ciascuno exit1/signal NIL,
avvio autentico di test worker e nessun completion. Zero survived,
compilation-failures, before-tests e worker-errors. Campagna
`4000547268-command-97067-0`, dati `worker-mutations/report.lisp`.

Benchmark `4000547268-command-97066-0`, dati
`worker-allocations/report.lisp`: quattro configurazioni, cinque campioni
completi di 4096 cicli ciascuna, tutti heap0. La derivazione indipendente
dal ciclo dà full `189+115C+3C(C+1)/2+5Σpayload+7(C+1)next`, room
`227+14next`; complessivamente payload 1..M, M=K(C+1), e somma cursori
K(K−1)/2. Il token è quello del metodo, le chiamate
`1+K(27+7C)` e i batch `K(C+4)`. Token/sink:
578/10754048, 858/11900928, 2520/18708480, 4084/25114624;
chiamate 35/49/137/193. Generazioni vere persistono attraverso warmup e
repliche; non sono azzerate per ottenere il sink. Controllo positivo
16777472 byte, sink errato respinto; clockzero, report parziale e
destinazione precedente restano controlli distinti.

Strict C4 `4000547221-command-94073-0` e `94074-0`: COMPILE-FILE intero
e self-test dei FASL, OK/STABLE/exit0. Il marker ereditato contiene
RECYCLE, ma argv e tool identificano worker; dato originale preservato.
Fixture reale SIGKILL `4000547222-worker-signal-self-test-94121`:
segnale9/exit137, un worker-error, zero detected. Non è detection.

Check `4000547204-command-93189-0`, OK/STABLE/exit0, wall112.229559s:
387 test dei dieci moduli oltre smoke, con conteggi
28/17/17/24/20/89/44/18/82/48. Lint63/zero; trace114 REQ/65 INV/13 FI/52 ADR
senza errori; links221 documenti/2007 link/zero rotti. Nessuna riga reale
warning/style-warning nei record letti. Master `4000547284-check-97964-0`:
complete, dieci run/artifact, tutti exit0/stable; nove ok e SPK-07 pass.
Questi snapshot di documenti sono precedenti alle conclusioni finali;
non vengono descritti come verifica della successiva versione editoriale.

| Punto C1 | Seconda lettura indipendente e limite |
|---|---|
| 1 | REQ/ADR coerenti con il contesto locale a tratti; scope frozen cf60913. |
| 2 | Invarianti e tre finding chiusi nel codice e nelle fixture; oracolo, contese, nuova onda e cessione conservano obblighi/debito. Nessuna prova esaustiva del pool. |
| 3 | Boundary COD-21 registra condition originale e transizione terminale; ragioni recuperabili per API, owner/gate prima del handler, fault non cancellabile. Controller della Serie ancora assente. |
| 4 | Nessun nuovo ciclo esplicito/attesa/ricorsione; member su liste letterali bounded, scan/copia delegate bounded. Thread delle sole fixture con timeout. |
| 5 | Venti misure composte heap0, controllo positivo rilevato e sink indipendente; solo successo preallocato, nessuna prova universale. |
| 6 | Ftype/esiti/count/token/buffer verificati; ack attesta il caller. Getter diagnostici non trasferiscono obblighi né autorizzano replay. |
| 7 | Decisioni inventariate, macro con prova di espansione/comportamento; native=HTML=export su undici file. 233 forme/31 esiti scoperti conservati, nessuna esclusione o MC/DC dedotta. |
| 8 | Owner e ready immutabili, campi locali non rientranti; trasferimenti solo senza lease/debito. Quattro thread/produttori vivi e due consumer concorrenti verificati. |
| 9 | Check congelato 387 test+smoke, lint/trace/link e dieci spike verdi; baseline execution89, strict C4 e 12/12 mutanti. Nuova integrazione della base distinta, sotto. |
| 10 | Safety3, ftype/slot/docstring, pre/post, funzioni brevi; handler di errore limitato al confine con diagnosi/transizione. Nessuna qualificazione globale C1 o FAULTED Serie. |
| 11 | Ready per tratto, nessuna nuova scrittura globale per messaggio/attesa. Progresso indipendente nelle fixture; nessuna misura di speedup, fairness o P99. |
| 12 | Nessun cambiamento durevole. Finishing prima di end; dopo end solo stato locale, nessun cleanup può cancellare una nuova onda. Nessun rollback dopo fault interno. |

Il primo audit risultati conserva anche i run completi del master e ha
dimensione elevata; non è stato cancellato. La proiezione compatta
`worker-review-summary-data.lisp` rimanda ai suoi byte originali.
Il primo adapter della proiezione fallisce nel probe
`4000547809-command-24892-0` perché applica getf a una entry tagged che
non è una plist; adapter e fallimento preservati. La versione corretta
`4000547879-command-29495-0` è OK/STABLE/exit0, controlla anche gli esiti
dei dieci run e conserva tutti i venti campioni. È un errore del probe,
non del prodotto o delle campagne congelate.

## Integrazione della base successiva

Dopo le campagne scoped la primaria avanza a `e2f7a75` con componenti
recovery indipendenti. I byte execution/test worker e dei due tool worker
rimangono invariati: questa seconda lettura e le campagne scoped restano
riferite alla copia cf60913. Il check completo della nuova integrazione
è distinto: `4000548048-command-40192-0`, OK/STABLE/exit0, wall116.613258s,
400 test più smoke, execution89/recovery95, lint66/zero,
trace114 REQ/65 INV/13 FI/52 ADR senza errori e links224 file/2017 link/zero
rotti. Master dei dieci spike: `4000548134-check-44515-0`.

Il record di scope `4000548017-command-37007-0`, OK/STABLE/exit0,
confronta i byte di venti file execution/test/tool con la copia precedente
e conserva i componenti recovery upstream. L'addendum indipendente
`worker-c1-integration-addendum.lisp`, letto/generato dal probe
`4000548534-command-60644-0` OK/STABLE/exit0, conserva SHA dei due record
e dei quattro sorgenti worker, tutti identici alla seconda lettura.
Il report C1 originale mantiene il suo congelamento temporale; l'addendum
non rinomina le campagne scoped né attribuisce ai check la successiva
versione editoriale dei documenti. Nessun gate o campagna del prodotto
rieseguito dalla revisione, nessuna nuova qualificazione C1/MC/DC,
requisito promosso o lacuna di copertura sottratta.
