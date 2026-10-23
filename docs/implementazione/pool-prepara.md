# Preparare un tratto dal pool alla Serie

`arcdocdb.scheduler.dispatch:prepara-tratto-pool` unisce il
[passo del dispatcher](pool-step.md) e un solo begin del bridge, sul link
appena selezionato. Incremento C3 di REQ-THR-001, REQ-CON-001/002/004/005 e
REQ-AFF-008; [metodo preregistrato](pool-prepara-metodo.md),
[rilettura C3/C4](pool-prepara-revisione.md). Nessuna modifica ai protocolli C1.

## Sette valori, un solo passo

Owner corrente non rientrante, binding coerente e bridge precedente chiuso.
Il passo seleziona claim, current o recycle dalla fase del contesto.
Con CLAIMED il link restituito è già quello corrente: viene avviato direttamente
senza un secondo routing. Il primo gruppo di valori segue l'avvio esplicito;
il secondo conserva i metadati della selezione senza reinterpretarli.

| Stato | Link | Token | Ragione | Origine/dettaglio/azione |
|---|---|---|---|---|
| ACTIVE | Link selezionato | Positivo, originale del bridge | NIL | Originali del passo |
| CLOSING | Link selezionato | Positivo, originale del bridge | `:serie-busy` o `:serie-lease-generation` | Originali del passo |
| EMPTY, BUSY, INACTIVE | NIL | 0 | NIL | `:claim`, cursore originale, azione lifecycle |
| PUBLISHED | NIL | 0 | NIL | `:recycle`, count della partizione, NIL |

Ordine: **link, token, stato, ragione, origine, dettaglio, azione**.
Per un CLAIMED già esistente: origine `:current`, dettaglio e azione NIL.
Per un full: origine `:recycle`, count e azione NIL. L'azione NIL non prova
che il comando pool sia immutato: in questi due casi il pool non è consultato.
Il ritiro pendente non impedisce il completamento dell'obbligo corrente.

Ogni chiamata esegue al più **un trasferimento ready e un tentativo di begin**.
Una pubblicazione termina subito: nessuna seconda presa o conferma del ritiro.
EMPTY/BUSY/INACTIVE non provano quiescenza e non autorizzano park o shutdown.
Non si eseguono pop, applicazione payload, ACK batch o end del bridge.

## Rifiuti e guasti

Con ACTIVE il caller usa link/token per prelevare, applicare, confermare e
terminare esplicitamente. Con CLOSING chiude il tratto prima del ricircolo;
non ritenta l'acquisizione della Serie. L'esaurimento della generazione
richiede gestione della risorsa e non una riprogrammazione indefinita.

BUSY restituito dal gate non avvia nulla. La condizione
`resource-exhausted :writer-queue-busy` durante begin conserva invece CLAIMED
e link IDLE senza consumare un token del bridge. Se la presa e l'ACK di
attivazione erano già riusciti, rimangono validi. Ready busy durante recycle
conserva RESCHEDULE e l'obbligo. Il caller decide eventuali tentativi successivi.

Owner, binding e fasi attive sono verificati dal passo prima di nuove azioni.
La coppia link/status incoerente o uno status inatteso segnala
`invariant-violation :pool-dispatcher-state` prima del begin. I controlli
NOTINLINE con argomenti T restano operativi anche nelle FI fuori contratto.

I guasti inattesi dei delegati propagano la medesima condizione. Non sono
restituiti i sette valori quando begin fallisce: il caller conserva in anticipo
dispatcher, contesto, tabella e riferimenti alle risorse configurate. Lease,
link e diagnosi restano nelle strutture C1, anche quando terminali; non viene
promessa una nuova API di recupero delle capacità dopo FAULTED. Il coordinamento
dell'Archivio resta necessario. Nessun handler, rollback o cleanup C3 viene aggiunto.

## Costo e confini

Scelta dell'esito e avvio sono O(1); solo il claim può scandire K partizioni,
K ≤64. Routing eseguito una sola volta. Nessun nuovo stato mutabile, ciclo,
thread, callback, I/O, attesa o scrittura condivisa tra Serie per messaggio.
Nessuna nuova allocazione intenzionale: le misure includono i controlli C1
e il ciclo reale della fixture, senza isolare il solo costo dell'adapter.
Applicazione dei payload del motore, park/wake, sensori reali, lifecycle fisico
e coordinamento Archivio restano aperti; il motore completo non è qualificato.
