# Collegamento dal pool alla Serie

Il componente C3 `arcdocdb.scheduler.dispatch` collega la
[presa governata dal pool](pool-worker-claim.md) al
[routing preallocato](routing-worker.md), per REQ-THR-001,
REQ-CON-001/002/004/005 e REQ-AFF-008. Il governo delle risorse resta
fuori dalle barriere C1; non scrive campi di integrità, writer o controller.
Il [metodo preregistrato](pool-dispatch-metodo.md) delimita la qualifica.

## Binding e ingressi

`crea-dispatcher-writer-pool porta tabella` crea un binding immutabile sul
thread proprietario. Porta e tabella devono riferirsi EQ allo stesso contesto
execution completamente IDLE. Tipo della porta, owner, tipo della tabella
e identità del contesto sono verificati in quest'ordine, prima di leggere
la fase o applicare un comando. La barriera IDLE C1 è read-only.
La factory non assume obblighi, acquisisce lease o conferma il pool.
La porta può essere inattiva o avere un comando pendente.

| API | Esito |
|---|---|
| `prendi-collegamento-pool dispatcher` | Solo IDLE libero: nuova presa attraverso il gate, poi routing del CLAIMED. Restituisce link oppure NIL, status, cursore e azione lifecycle originali. |
| `collega-obbligo-pool dispatcher` | Solo CLAIMED già assunto: routing del writer corrente, senza leggere request/ack/active e senza conferme del pool. Restituisce il link preallocato. |
| `ricircola-collegamento-pool dispatcher` | Solo RESCHEDULE: un ricircolo, poi routing del nuovo CLAIMED se full; altrimenti pubblica e termina IDLE. Restituisce link/NIL, status e count della partizione. |
| `inizia-obbligo-pool dispatcher` | Solo CLAIMED: routing corrente e un begin del bridge; restituisce link, token, fase e ragione originali. |
| `passo-dispatcher-pool dispatcher` | Un solo passo: sceglie claim, current o recycle dalla fase verificata; cinque valori con origine esplicita, senza begin o seconda presa. |

Il primo ingresso restituisce un link solo con `:claimed`. Con `:empty`,
`:busy` o `:inactive` restituisce NIL senza routing. Il link è ancora IDLE:
`inizia-worker-serie`, token, pop, ack e chiusura rimangono passi espliciti
del [bridge](worker-serie.md). Nessuna acquisizione della Serie è implicita.
EMPTY e BUSY non dimostrano quiescenza globale né autorizzano park/shutdown.

Il secondo ingresso riprende un CLAIMED conservato dopo writer-busy, un
ricircolo full o un'adozione. Ogni selezione usa il writer attuale; non
riutilizza il collegamento del tratto precedente. È ripetibile finché il link
rimane IDLE, senza nuove capacità. Neppure parole lifecycle incoerenti
impediscono questo ingresso: l'obbligo esistente deve restare completabile.
Un binding incoerente o un owner estraneo sono invece sempre rifiutati.

## Ritiro, errore e responsabilità del caller

Il ritiro pendente viene confermato al prossimo ingresso IDLE attraverso il
gate. Non viene applicato durante CLAIMED, RUNNING, BATCH, FINISHING o
RESCHEDULE. Dopo `:schedule` il caller invoca esplicitamente
`ricircola-collegamento-pool`, oppure ricircola o cede l'obbligo con le API
execution. Se il ricircolo diretto assegna un nuovo CLAIMED, usa
`collega-obbligo-pool`; l'adattatore di ricircolo restituisce già il suo link.
Dopo una pubblicazione riuscita il contesto torna
IDLE e può applicare il ritiro con la successiva nuova presa.

Il [ricircolo esplicito](pool-recycle.md) risolve il singolo obbligo senza
consultare il pool. L'[avvio esplicito](pool-begin.md) usa un ingresso distinto
sui CLAIMED; gli ingressi di presa e ricircolo non includono begin. Pop, end,
retry, cleanup e rollback restano al caller. I rifiuti writer-busy e Serie-busy mantengono gli stati differenti
del bridge: il primo conserva CLAIMED, il secondo produce CLOSING e un
token da chiudere esplicitamente. Il caller conserva riferimenti e token
fino alla conclusione; non ignora alcun obbligo su errore.

Il [passo coordinato](pool-step.md) seleziona uno solo degli ingressi di presa,
collegamento corrente o ricircolo, senza un secondo stato mutabile C3.
L'origine distingue cursore e count; una pubblicazione termina il passo e
il ritiro resta applicabile soltanto al successivo ingresso IDLE esplicito.

Un routing invalido dopo claim conserva writer, home e obbligo nel contesto
FAULTED secondo la barriera C1 già presente. Nessuna lease della Serie
viene acquisita. L'ACK di attivazione già riuscito resta valido: non si
revocano generazioni. L'Archivio deve gestire la diagnosi, come nei contratti
execution/bridge. C3 non marca direttamente worker o controller.

Tipo della configurazione errato: `invalid-argument
:pool-dispatcher-configuration`; owner estraneo: `invalid-argument
:pool-worker-owner`; contesti diversi: `invalid-argument
:pool-dispatcher-binding`. Fase non-IDLE nella factory o nel gate:
`resource-exhausted :worker-state`, senza sostituire la prima causa.
I rifiuti di routing restano quelli dell'API C1. Un ritorno del gate
incoerente fra writer e status segnala `invariant-violation
:pool-dispatcher-state`, senza abbandonare o mutare il contesto.

## Costo e ambito

Il binding costa O(1) all'avvio, oltre alla tabella O(N) già preallocata.
Ogni ingresso verifica owner e identità EQ in O(1). Nuova presa: gate e
scansione ready O(K), con K massimo 64; solo dopo CLAIMED, routing O(1)
tramite ordinale. Obbligo corrente: solo routing O(1). Nessuna nuova
allocazione intenzionale nel percorso caldo, scansione delle Serie, hash,
scrittura condivisa tra Serie, attesa, thread, callback o I/O.

Il coupling privato legge soltanto owner/context della porta e context della
tabella. I protocolli C1 e lifecycle restano invariati. Il dispatcher è un
ingresso logico per writer, non il loop completo del server: avvio e arresto
dei thread, park/wake, sensori reali, admission dei messaggi, applicazione dei
payload e coordinamento dell'Archivio restano aperti. Nessun gate del motore
completo viene chiuso da questa qualifica.
