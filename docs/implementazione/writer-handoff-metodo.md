# Metodo della consegna locale dei writer

Registrato il 2026-10-09, prima delle prove. Base `85a4e05`. Componente C1:
`src/execution/handoff.lisp` e helper di accettazione estratto da `queue.lisp`.
Contratto da [ADR-0045, punti 6 e 8](../adr/0045-modello-di-esecuzione.md),
REQ-CON-001/002/004/005 e REQ-AFF-008; invarianti INV-P1/P2/P5/P6, INV-A8, INV-V4.

## Meccanismo e ambito

Un wrapper possiede una coda privata e lo stato `idle/ready/running`. Ring e
stato usano la stessa guard locale già presente; ogni acquisizione tenta un
solo CAS. Nessuna nuova guard, stato globale, allocazione per messaggio,
callback, attesa, I/O o thread. La coda interna non viene esposta e non si
mescolano le API basse con quelle del wrapper.

L'accettazione da idle restituisce `:schedule`; ulteriori messaggi restituiscono
`:queued`. L'avvio acquisisce la lease e passa da ready a running. Il termine
osserva count, rilascia la lease e passa a ready se resta lavoro, a idle se
vuoto, mantenendo la guard per l'intera transizione. La quota è cumulativa
per tratto. Il termine può essere anticipato: i messaggi residui richiedono
comunque un prossimo tratto.

`:schedule` trasferisce al chiamante un obbligo da eseguire una sola volta.
Una notifica fallita richiede di conservare e ritentare quell'obbligo; non
si ripete l'accettazione del payload. Busy al termine conserva la lease:
si ritenta solo il termine. Non viene implementata qui la lista pronta,
il risveglio dei worker o la gestione del loro arresto. La proprietà locale
non garantisce progresso se il chiamante abbandona il compito o la lease.

La coordinazione queue/stato di una mailbox è un pattern consolidato
([Akka Mailbox](https://github.com/akka/akka/blob/main/akka-actor/src/main/scala/akka/dispatch/Mailbox.scala));
questo protocollo è una realizzazione distinta, sotto guard, e richiede prove
proprie. I CAS e il loro ordinamento sono quelli di
[SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e delle
[barriere](https://www.sbcl.org/manual/#Barriers).

## Prove di correttezza

- Compilazione forzata senza warning/style-warning e suite execution precedente.
- Oracolo indipendente con liste FIFO, numero di notifiche e stati logici;
  sequenze finite su capacità/quantum diversi, wrap, NIL, quota cumulativa,
  conclusione anticipata, nuova ondata dopo idle e target intatto fuori span.
- Due ordini della race dopo l'ultimo prelievo: accettazione prima del termine
  produce `:queued` seguito da `:schedule`; termine prima dell'accettazione
  produce `:idle` seguito da `:schedule`. Nessun payload duplicato o perso.
- Full/busy senza mutazione o accettazione; busy al termine conserva lease,
  quota e lavoro. Avvio duplicato, lease vecchia/altro thread, generazione
  esaurita senza wrap e ready conservato. Guardie interne provate con FI privata.
- Thread reali riusati su più ondate; producer aperti durante il consumo,
  passaggio del writer a thread diversi e una Serie che avanza mentre un'altra
  conserva la guard. Semafori e join hanno timeout; errori dei worker rilanciati.
  Questo harness non è il pool adattivo del prodotto né una misura di scalabilità.

## Verifica C1 e strumenti

Due letture, autore e revisore distinto, con i dodici punti dello standard.
Inventario delle decisioni e rami difensivi; raw `sb-cover` di tutti i quattro
file execution, senza sottrarre dichiarazioni o rami non marcati. Si conservano
raw, conteggi, denominatori e limiti; nessuna deroga o MC/DC completa implicita.

Mutation testing su copie isolate, baseline compilata e riuscita; mutanti
semantici relativi a notifica, passaggio di stato, quota e conteggio. Ogni
mutante deve compilare prima di essere rilevato dai test. Compilation failure,
prima-dei-test, sopravvivenza e rilevamento restano esiti distinti. Il set viene
fissato prima dell'esecuzione nel sorgente dello strumento. Self-test del runner
su bersagli mancanti/ambigui e marcatori di risultato.

Allocazioni seriali: input, wrapper e target preallocati, warmup esterno al
contatore, cinque campioni di 4096 cicli per percorso (idle→ready→running→idle,
backlog/quantum/riaccodamento). Sink e notifiche confrontati con l'oracolo.
Contatore con controllo positivo di allocazione; campione zero non è una prova
universale. Nessuna misura throughput/P99 o selezione di algoritmi da questa
campagna. Carico esterno non controllato, piattaforma locale macOS ARM64/SBCL.

Tutte le prove passano tramite il registro strutturato, con sorgenti stabili,
argv/ambiente, stdout/stderr integrali e fallimenti. Evidenze pubblicate in
`spikes/results/2026-10-09-writer-handoff/`; verifica finale `make check`.
I gate del motore e i target integrati restano aperti.
