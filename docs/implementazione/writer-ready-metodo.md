# Metodo della lista dei writer pronti

Registrato il 2026-10-09 prima delle campagne, base `92d8b0e`.
Componente C1: lista pronta preallocata a partizioni indipendenti, da
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md), REQ-CON-001/002/004/005
e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4.

## Contratto preregistrato

Ogni partizione è un ring FIFO con una guard locale acquisita con un solo
CAS. Nessuno spin, callback, I/O, contatore globale o allocazione per compito.
Il ring trasporta riferimenti ai writer, senza membership, generazioni o
cleanup dello stato del writer. Il protocollo di
[handoff](writer-handoff.md) resta invariato. La lista comune è toccata solo
per pubblicare o prendere un tratto, non per ciascun messaggio.

La costruzione accetta 1..64 partizioni, default 4, e 1..65536 slot per
partizione, default 1024; massimo 4194304 riferimenti preallocati. La scelta
della partizione di una Serie è un dato del chiamante, fissato prima del
percorso caldo. Non viene introdotto un algoritmo di hashing del catalogo.

`pubblica-writer-pronto(lista shard writer)` trasferisce un obbligo già
prodotto da `:schedule` e restituisce il count locale. Full/busy rifiutano
prima della mutazione: l'obbligo rimane al chiamante. Il retry riguarda
questa pubblicazione, senza accettare nuovamente il payload nel writer.
Un successo non si ritenta: l'API non deduplica pubblicazioni errate.

`preleva-writer-pronto(lista start)` prova al più K partizioni in ordine
circolare. Una guard contesa non impedisce di provarne un'altra. Restituisce
writer, `:writer` e cursore successivo alla partizione servita; senza successo
restituisce NIL, `:busy` se almeno una guard era contesa, altrimenti `:empty`,
e cursore successivo a start. Empty significa solo che ciascuna osservazione
locale era vuota: un producer concorrente può pubblicare subito dopo; non è
una prova di quiescenza globale né autorizza un parcheggio senza protocollo.
Ogni candidata ha un tentativo CAS di acquisizione; un'acquisizione riuscita
richiede anche il CAS di rilascio. Sono al più K acquisizioni e 2K CAS totali.

Il worker conserva il riferimento preso fino all'avvio riuscito del writer;
busy non lo duplica né lo perde. Non c'è cleanup tardivo di un flag scheduler
dopo `termina-tratto-writer`: una nuova ondata può già essere pubblicata.
Pool, risvegli, shutdown, controller FAULTED e adattività richiedono ancora
integrazione. Non si garantisce progresso se il chiamante abbandona un obbligo.

## Scelta e prove

Il ring con guard a tentativo singolo estende il protocollo già verificato
delle code locali. La partizione riduce il dominio di contesa; la scansione
circolare ha un limite statico e non introduce una ready queue globale per
richiesta. Non è una struttura lock-free e non viene dichiarata la soluzione
universalmente più veloce. I CAS seguono il
[contratto SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e servono
anche da [barriere di memoria](https://www.sbcl.org/manual/#Barriers).
L'alternativa MPMC con sequenza per slot richiederebbe un nuovo protocollo
di pubblicazione, overflow e riuso; non viene selezionata senza prove proprie.

- Oracolo indipendente con liste FIFO e cursore, sequenze finite con seme,
  capacity 1 e altre cardinalità, wrap, pieno, vuoto e rotazione tra partizioni.
- Limiti/default, input invalidi, rifiuti senza mutazione, cleanup dopo full,
  guard posseduta da altro thread e FI privata sugli invarianti del ring.
- Handoff integrato: obbligo conservato su pubblicazione full/busy e avvio
  busy; entrambi gli ordini enqueue/fine vuota, nuova ondata e riaccodamento.
- Worker reali riusati su ondate con producer vivi e più consumer; una
  partizione occupata mentre l'altra avanza. Retry e join del solo harness
  hanno limiti e gli errori dei worker sono rilanciati.
- Due letture C1, inventario delle decisioni, copertura raw completa di tutti
  i file execution. Nessuna forma sottratta, esclusione approvata o MC/DC
  implicita. Build senza warning/style-warning, lint e `make check`.
- Dodici mutanti semantici preregistrati nel runner prima della campagna:
  ring, proprietà, capienza, scansione, busy, cursore e pubblicazione. Baseline
  riuscita obbligatoria; compilation failure e before-tests non sono rilevamenti.
- Allocazioni: due scenari preallocati con una e quattro partizioni, cinque
  campioni di 4096 cicli ciascuno, warmup 128 e GC fuori dal contatore. Capacità 3 e due writer per partizione forzano wrap; ogni ciclo include
  accettazione del payload preallocato, pubblicazione, prelievo e fine del
  tratto. Si misura la composizione handoff/lista pronta. Identità,
  count, status e cursore contribuiscono a un sink esatto; controllo positivo
  heap, sink errato rifiutato e clock nullo distinto. Percorsi d'errore esclusi;
  zero osservato non è una garanzia universale, né throughput o P99.

Tutti i tentativi sono registrati con `tools/record-command.lisp`, argv,
ambiente, sorgenti stabili e output integrali. I C4 hanno self-test e rapporti
parziali; le prove congelate vivono in una clone separata. Dati grandi vengono
compressi senza perdita e verificati dal lettore delle evidenze. I gate del
motore e i target integrati restano aperti.

## Correzione del runner prima della campagna finale

Dopo l'integrazione di `fd96fb3`, il runner ready adotta la correzione della
classificazione di processo: un segnale OS o un exit nonzero dopo il marcatore
reale di completamento sono `:worker-error`, mai rilevamento. Exit e segnale
restano distinti nei dati e nella baseline; il self-test termina un proprio
child con SIGKILL e conserva runner, log e report. Il set dei dodici mutanti
resta invariato. La campagna viene ripetuta integralmente in
`ready-mutations-final`, conservando precedente driver e campagna; prodotto,
test e benchmark restano invariati; le prove mirate di copertura e allocazione
non richiedono ripetizione. La suite completa sarà rieseguita dal check integrato.
