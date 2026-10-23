# Presa dei lavori governata dal pool

`arcdocdb.scheduler:prendi-writer-pool` collega l'attivazione logica del
[pool](pool-worker-lifecycle.md) alla presa di un writer dalla lista pronta.
È un incremento C3 di REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008:
governa quando chiamare la barriera C1 esistente, senza sostituirla.
Il [metodo preregistrato](pool-worker-claim-metodo.md) delimita le prove.

## API e proprietà

La funzione riceve soltanto la `porta-worker-pool`: usa il contesto immutabile
associato alla porta, evitando una coppia porta/contesto estranea. La chiamata
appartiene al proprietario del worker, non è rientrante e avviene tra compiti
a completamento, senza epoca di lettura o risorse esterne ancora acquisite.
Il contesto deve essere IDLE e completamente libero.

Restituisce quattro valori:

| Valore | Significato |
|---|---|
| writer oppure NIL | Obbligo assunto soltanto con `:claimed`. |
| `:claimed`, `:empty`, `:busy`, `:inactive` | Esito della presa; i primi tre sono quelli dell'API execution. |
| cursore | Cursore restituito da execution se attivo; cursore conservato se inattivo. |
| azione lifecycle | Conferma applicata o `:unchanged`; il dominio dichiarato conserva quello di `applica-stato-worker-pool`. |

Il chiamante usa questa API per ogni nuova presa dal pool. Le API execution
dirette restano disponibili per i loro contratti; non consultano una porta.
Il nuovo gate non può impedire a un caller che lo aggira di prendere lavoro.
Il [dispatcher pool/Serie](pool-dispatch.md) lega questa porta alla tabella
del medesimo contesto e restituisce il collegamento del writer appena preso.

## Ordine del passo

1. Verifica il proprietario della porta.
2. Legge la fase execution e rifiuta ogni fase diversa da IDLE, compreso
   FAULTED, prima di leggere le lease di un compito in corso.
3. Esegue in sola lettura il verificatore C1 completo `%richiedi-worker :idle`.
   Un esito lifecycle `:unchanged` da solo non prova IDLE né salute.
4. Applica l'eventuale comando di attivazione o ritiro sull'owner reale.
5. Se attivo, delega un solo `execution:prendi-writer-worker`. Se inattivo,
   restituisce NIL, `:inactive` e il cursore corrente, senza interrogare
   i ring, acquisire guardie, scansionare o modificare la lista pronta.

La barriera C1 del punto 3 legge comunque la forma immutabile di ready e
verifica i riferimenti alle partizioni del contesto. Non legge head, tail,
count o slots del ring, non acquisisce una guardia e non cerca lavoro.

Il solo trasferimento di un obbligo rimane nell'API C1. Nessun campo writer,
lease, batch, Serie o ready viene scritto direttamente dal nuovo componente.
I controlli C3 restano fuori dal confine `%passo-worker`: un difetto della
porta non introduce una nuova scrittura di fault nel contesto C1.
La presa delegata conserva invece il suo confine e la diagnosi originaria.

## Ritiro e compiti in corso

Una richiesta di ritiro osservata al passo IDLE viene confermata prima del
polling di ready: anche con lavoro pronto il worker non assume un nuovo obbligo.
Una richiesta arrivata dopo la lettura active può lasciare partire quel singolo
claim. Rimane pendente finché il worker completa il compito e torna a IDLE;
la conferma non è anticipata né revocata.

Pop, conferma dei payload, chiusura del bridge Serie, ricircolo, cessione e
adozione mantengono i contratti esistenti e non sono sottoposti a questo gate.
Un RESCHEDULE deve pubblicare o trasferire l'obbligo unico prima del ritiro.
Il ricircolo a ring pieno può assegnare subito un altro writer CLAIMED: il
worker completa anche quell'obbligo, selezionando di nuovo il routing. Non
si promette convergenza del ritiro sotto saturazione perpetua del ring.
EMPTY e BUSY sono osservazioni locali, senza prova di quiescenza globale.

La conferma di un comando lifecycle resta valida se la successiva presa
delegata fallisce. Non si fa rollback dell'ACK, non si azzerano generazioni
e il conteggio active continua a rappresentare attivazioni logiche, non salute.
Il coordinatore deve gestire la diagnosi del worker e l'Archivio.

## Rifiuti e costo

Owner della porta estraneo: `invalid-argument :pool-worker-owner`.
Fase diversa da IDLE: `resource-exhausted :worker-state`, conservando fase,
prima causa, riferimenti, lease, batch, cursore e parole del pool.
Un IDLE incoerente fallisce nella barriera C1 prima di qualunque ACK o pop.
Parole o CAS del pool incoerenti propagano il rifiuto del lifecycle prima
della presa. Le condizioni della presa delegata restano quelle di execution.
Non ci sono retry, cleanup o handler che nascondano un errore.

Il gate è O(1), oltre ai verificatori C1 bounded. Solo il ramo attivo aggiunge
la scansione ready esistente O(K), con K massimo 64. Non introduce hash,
allocazioni intenzionali, callback, thread, attese o contatori globali.
Le conferme condivise avvengono per ondata, e ready usa le proprie partizioni.
Il passo non sospende un compito, secondo ADR-0045.

Il componente integra la presa logica, non il dispatcher completo del server.
Avvio graduale, park/wake persistente, sensori, coordinamento Archivio,
admission dei messaggi, worker morti e arresto fisico restano da realizzare.
REQ-THR-001 e QA-12/19 restano aperti a livello del motore completo.
