# Revisione indipendente del ricircolo pool/Serie

Lettura statica del 2026-10-14 sulla base
`a5715a1aa0b2571d650d1b794e9bb7b7324e951e`, eseguita da un agente diverso
dall'autore del codice. Esito: **positivo per lo scope C3 letto**, senza
rilievi aperti sul prodotto. Il revisore ha modificato soltanto questo
documento; non ha eseguito le campagne e non attesta compilazione, risultati
dei test, copertura o allocazioni.

Il quadro applicato comprende [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md) e lo
[standard di codifica](../affidabilita/standard-di-codifica.md).
Sono stati letti il [contratto](pool-recycle.md), il
[metodo preregistrato](pool-recycle-metodo.md), i cinque sorgenti dispatch,
l'ordine ASDF, le tredici nuove prove, le fixture dispatch preesistenti e
le barriere C1 di ricircolo, contesto execution, routing e bridge Serie.

## Identità e denominatore

Lo scope di qualificazione è l'intero componente dispatch esteso: cinque
file, senza esclusioni manuali o limitazione alle righe nuove. I conteggi
devono essere pubblicati anche per ogni file, compreso `recycle.lisp`;
una soglia aggregata non sostituisce l'indicazione dei suoi percorsi mancanti.
I delegati C1 non entrano nel denominatore C3 e non sono riclassificati.

| Fonte letta | SHA-256 |
|---|---|
| `src/dispatch/package.lisp` | `7f1eea26b8d8fd34186a85cff9aebae5842dc731de45b361058e0af4788090e8` |
| `src/dispatch/types.lisp` | `cc44882c565a89de08f5add79333868ebfca4fc3f97bf9104d36375d014d4720` |
| `src/dispatch/build.lisp` | `c78d31a753db78baea520e9ea0cccf6e88cad9cca8bc75261a6ff26c2ac01fe5` |
| `src/dispatch/claim.lisp` | `224e4114b8b91affced874bea9c23cae5c79526e8ddae62e31a0cafcbb763682` |
| `src/dispatch/recycle.lisp` | `9fa3294cd28d1904cfb8db5153f93188b02f1bfbaf1800dad788731007c29ad0` |
| `arcdocdb.asd` | `ef5423225107a6b33e1eb71d4713dfd77ad441e5af6e07cdb2c95bf0bbb0ffb6` |
| `tests/scheduler/dispatch.lisp` | `600eb0b5fdf9a52d020e2f4c638f0f3dba43d9d9711be73eaffff208578821eb` |
| `tests/scheduler/pool-recycle.lisp` | `079a58b0c8850df0be62c71229e25d052fb716f36f1996e9e8ab2c4c2a38fa86` |
| `tools/measure-pool-recycle.lisp` | `f9f33a86334719cf22a0c6d9f27ccae426895c247c67044ddf52b70200b05c7a` |
| `docs/implementazione/pool-recycle.md` | `65da387e05a4179fc930e440f4068a6025c9afc5f22d7917ac5bc748457b44ff` |
| `docs/implementazione/pool-recycle-metodo.md` | `a3abb270ad16b8eb2262411faba5091dbe4fbaea54c6b30bf376f1339d56babb` |

Le fonti delegate determinanti per il nuovo passo sono rimaste invariate:

| Barriera | SHA-256 |
|---|---|
| `src/execution/worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |
| `src/execution/worker-types.lisp` | `62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317` |
| `src/execution/worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |
| `src/execution/ready-recycle.lisp` | `2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b` |
| `src/series/routing-select.lisp` | `796e3ace762dd6c3d86119981a37c1904a637e664551ca0f5289544f0806714a` |
| `src/series/worker-run.lisp` | `f448442c5f9233f492bb8642206ec4913f7b2f5f3c9a1fdf05896a439f1d429f` |

Le impronte identificano i byte di questa lettura. La successiva qualifica
deve confrontarli con quelli congelati, senza dedurre un PASS da questa tabella.

## Un trasferimento e obblighi conservati

La nuova API riusa il binding immutabile fra porta del pool e tabella
locale. `%check-dispatcher-binding` controlla tipo della porta, owner, tipo
della tabella e identità EQ dei contesti, prima di chiamare execution.
Legge soltanto riferimenti e owner della porta; non legge request, ack o
active e non chiama il gate lifecycle.

`ricircola-collegamento-pool` invoca una sola `ricircola-worker`, che richiede
RESCHEDULE e obbligo unico senza lease o batch. Il C1 opera sulla sola
partizione home. Con spazio, il vecchio writer passa al ring e il contesto
torna IDLE: il nuovo ingresso restituisce NIL, `:published` e count, senza
routing, polling o seconda presa. Il ritiro può essere applicato soltanto
dalla successiva presa esplicita sul contesto libero.

Con ring pieno, il C1 pubblica il vecchio obbligo e consegna la testa al
worker nella stessa sezione protetta. Il nuovo ingresso risolve il link
del writer ora CLAIMED, mediante ordinale e identità verificati. Il link
rimane IDLE: nessun begin, token o lease Serie viene introdotto. Home e
cursore restano quelli di execution; count descrive il trasferimento locale,
senza essere un cursore o uno snapshot al momento del ritorno.

Il ritiro pendente o la porta inattiva non revocano l'obbligo. Una catena di
scambi full può continuare ad assegnare CLAIMED e non garantisce il ritorno
a IDLE sotto saturazione perpetua. Il dispatcher non acquisisce autorità su
park, wake, shutdown o coordinamento dell'Archivio.

Busy della guard conserva RESCHEDULE, writer e home; ogni retry è esplicito.
Un routing invalido dopo scambio conserva invece il trasferimento già
riuscito: vecchio writer nel ring, nuovo riferimento e home nel worker
FAULTED attraverso la barriera C1. Non esiste rollback, cessione, cleanup
o nuovo handler C3. Nessuna preimage immutata è promessa dopo tale successo
parziale; controller e lease Serie non vengono acquisiti dal routing.

## Guardia del risultato e compilatore

L'esito C1 è nominalmente ristretto dal suo ftype a `:claimed/:published`.
Una `case` applicata direttamente a quel risultato non basta a dimostrare
un rifiuto operativo di valori che violano il contratto: il compilatore
può eliminare il ramo che considera impossibile.

La versione letta introduce `%check-recycle-status`, con argomento T e
NOTINLINE, prima del dispatch sul risultato. La guardia verifica il dominio
nel proprio corpo e segnala `invariant-violation :pool-dispatcher-state`
senza scrivere fault o stato. Il suo ritorno ristretto permette poi di
specializzare la seconda `case`, che mantiene comunque un finale esplicito.
Le due guardie writer/NIL controllano separatamente la relazione fra valori
che il solo ftype non esprime.

La FI di uno status estraneo esercita questa barriera C3, non un ritorno
C1 nominale. La variante FAULTED sostituisce deliberatamente il delegato:
non dimostra che il vero C1 permetta il ricircolo da FAULTED. Tutte le
sostituzioni sono quiescenti e ripristinate. I denominatori nativi devono
restare quelli prodotti da SB-COVER, anche se un ramo difensivo successivo
non genera sonde; non si inferisce MC/DC o copertura dal solo sorgente.

## Lista di controllo

I dodici punti C1 sono usati come controllo aggiuntivo per il singolo
passaggio C3 previsto da ADR-0031. Questa lettura non sostituisce le due
revisioni o le altre verifiche dei delegati C1.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008 tracciati; un accesso ready per tratto e compiti senza sospensione coerenti con ADR-0045 §6/8. Il pool completo resta aperto. |
| 2. Invarianti | Binding verificato prima del trasferimento; una sola chiamata C1; routing soltanto per CLAIMED non-NIL; published termina IDLE senza nuova presa. Obbligo unico e bridge precedente chiuso restano precondizioni del caller. |
| 3. Errori | Ragioni binding/owner riusate; fase, busy e fault delegati senza occultamento. Stato e relazione writer/status hanno rifiuto C3 typed senza mutazione o sostituzione della prima causa. |
| 4. Limiti | Nessun ciclo, ricorsione, retry, callback o attesa nuovo. Ricircolo su home O(1), guard a tentativo singolo e routing O(1); nessuna scansione delle Serie o delle partizioni. |
| 5. Allocazione | Nessun costruttore, lista, closure, hash o nuovo stato nel percorso caldo. Zero heap richiede la campagna misurata: non deriva dalla lettura statica. |
| 6. Risultati | Tutti e tre i risultati sono usati; status validato con argomento T/NOTINLINE, writer verificato rispetto all'esito, count originale inoltrato senza inventare un nuovo significato. |
| 7. Decisioni | Helper nuovo: complessità 2, 7 righe di defun; API nuova: complessità 5, 22 righe. Binding 5, factory 2, claim 5 e lookup 1; nessuna funzione supera 60 righe o 10 percorsi. Nessuna nuova decisione composta C1. |
| 8. Proprietà | Dispatcher, contesto, tabella e link restano del thread creatore; owner e contesto EQ verificati prima della delega. Nessuna migrazione, reentrancy o struttura globale mutabile nuova. |
| 9. Tracciabilità | REQ sulle nuove definizioni e sui tredici test; export e ASDF dopo claim corretti. Build strict, lint, trace e controllo completo devono essere attestati dai loro processi separati. |
| 10. Standard | Safety 3, ftype espliciti, docstring e OWNER/SHARED; finali case typed. Nessun ignore-errors, handler generico, cleanup o rimozione di controlli C1. Nessuna deviazione individuata nel prodotto letto. |
| 11. Parallelismo | Una sola guard del proprio shard per tratto; nessun lock comune, contatore globale o scrittura condivisa fra Serie per messaggio. Questa lettura non dimostra equità, assenza di starvation o scalabilità. |
| 12. Durabilità | Nessun payload, controller, CSN o file modificato dal nuovo codice. Nessun cambiamento durevole o eliminazione; nessuna nuova atomicità persistente da qualificare. |

## Lettura delle prove e del sensore

Le tredici nuove prove sono state lette senza eseguirle. Le fixture usano
primitive C1 e bridge reali dove indicato; le FI del protocollo e delle
funzioni restano distinte dagli interleaving concorrenti.

| Gruppo | Evidenza prevista dalle fixture e limite |
|---|---|
| Room | Tre shard e capacity 2 separano home/count/cursore; FIFO B poi A, una chiamata al ricircolo e sentinelle su routing, gate e ACK. Controller intatti e link finali IDLE. |
| Full | Scambio reale A→B su home diversa dal cursore, count invariato, link B IDLE senza begin; altri shard e stati writer/controller confrontati. Il successivo bridge è esplicito. |
| Ready busy | Guardia reale detenuta tramite CAS; confronto di ring, contesto, writer, link, controller e parole pool. Retry soltanto successivo al rifiuto. Non è uno stress di contesa casuale. |
| Fasi e prima causa | IDLE, CLAIMED, RUNNING, BATCH e FINISHING ottenuti da operazioni reali; FAULTED iniettato separatamente. Rifiuti conservano debito, lease e causa EQ. |
| Indipendenza dal pool | Porta inattiva, parole corrotte e ritiro pendente quiescenti, con sentinelle sul gate; completamento del nuovo CLAIMED e ACK soltanto alla presa IDLE successiva. Prova room distinta per assenza di ACK implicito. |
| Binding e owner | Contesti diversi e owner su thread reale distinto rifiutati prima del trasferimento; snapshot e sentinella sul ricircolo. Non è una prova di migrazione consentita. |
| Fault dopo full | Writer estraneo al routing: vero scambio già riuscito, riferimento/home e causa conservati, vecchio A osservato nel ring. Controller e lease Serie intatti; nessun rollback dedotto dall'errore. |
| Risultati e tipo | Writer/status contraddittori entro i tipi, dispatcher invalido e sei status fuori ftype. Rifiuto prima del routing, una sola chiamata interposta e immagini uguali; prima causa FAULTED conservata nella FI separata. |
| Invariante ready | Head invalido dentro il tipo INDEX, verificato sotto vera guard: causa C1 originale, writer e dati diagnostici conservati; rifiuto successivo senza sostituire la causa. |

Il sensore C4 letto usa fixture nuove per replica, payload preallocati,
quantum uno e un ricircolo per ciclo. ROOM aggiunge una presa esplicita;
FULL alterna i due writer. Begin, pop, ack ed end nel clock sono quelli
execution: il bridge rimane IDLE e non viene acquisita una lease Serie.
Gli oracoli scalari, il protocollo C1 e il routing fanno parte del tempo;
non si misura il solo adapter. Factory, risoluzione API, GC e drain pubblico
bounded restano fuori clock. Il drain nominale non qualifica l'arresto
dell'Archivio dopo un fault.

I self-test del sensore prevedono heap positivo deliberato, sink errato,
clock sotto risoluzione, tre risultati difformi, CLI/destinazioni rifiutate
e raw parziali conservati. La lettura di tali controlli non ne attesta
l'esecuzione. La soglia C3, il confronto SB-COVER/HTML, i conteggi per file,
le repliche e la conservazione degli originali richiedono record separati.
Non si qualificano payload del motore, sensori reali, admission, park/wake,
worker morti, avvio/arresto fisici o un coordinatore concorrente.
