# Collegamento del worker alla Serie

Fondazione C1 autorizzata, conforme a REQ-CON-001/002/004/005 e
REQ-AFF-001/004/008; ADR-0005, ADR-0033 e ADR-0045. Il package
`arcdocdb.execution.series` viene caricato dopo execution e controller Serie.
Il [metodo preregistrato](worker-serie-metodo.md) fissa le verifiche;
l'[inventario delle decisioni](worker-serie-decisioni.md) conserva i denominatori.
Le [due letture C1](worker-serie-revisione.md) e i
[risultati locali](worker-serie-risultati.md) collegano le evidenze conservate.

Il caller configura all'avvio una sola associazione logica writer/Serie e
prealloca un `collegamento-worker-serie` per coppia contesto/associazione.
La configurazione è una precondizione: la factory non cerca duplicati in un
registro globale. Contesto, writer e controller restano read-only. Il binding
appartiene al thread del contesto, senza migrazione o rientranza. Un worker può
usare più binding preallocati, uno alla volta, secondo il writer preso dalla
lista pronta; claim, ricircolo e cessione restano nelle API del worker.

| API | Precondizione ed esito |
|---|---|
| `crea-collegamento-worker-serie` | Avvio sul thread del contesto; produce IDLE senza assumere un obbligo. |
| `inizia-worker-serie` | IDLE con worker CLAIMED del writer associato; acquisisce writer e poi Serie. Restituisce token, fase e ragione. |
| `lease-worker-serie` | ACTIVE e token corrente; restituisce la lease per le API del controller. |
| `preleva-worker-serie` | ACTIVE e token corrente; delega il pop e restituisce count/status/token batch. |
| `conferma-worker-serie` | ACTIVE e batch interamente elaborato; conferma solo il token batch corrente. |
| `termina-worker-serie` | ACTIVE senza debito, oppure CLOSING; libera Serie prima di concludere il worker. |
| `stato-worker-serie`, `errore-worker-serie` | Diagnosi owner-only, anche in FAULTED; nessun trasferimento di proprietà. |

Inizia restituisce `(token :active nil)` quando entrambe le lease sono presenti.
Se la seconda acquisizione rifiuta, restituisce `(token :closing :serie-busy)`
oppure `(token :closing :serie-lease-generation)`. La seconda ragione è un
esaurimento permanente: il caller deve chiudere il tratto e gestire la risorsa,
senza riprogrammarla indefinitamente. CLOSING non permette pop, ack, nuova
acquisizione o lettura della lease Serie. Il caller chiama esplicitamente termina;
il bridge non fa retry o cleanup impliciti. Busy del primo begin lascia IDLE e
worker CLAIMED, senza consumare un token di tratto.

Token di tratto e token batch sono capacità diverse, entrambe locali e monotone,
senza wrap. Il token di tratto vale solo con lo stesso binding. Esaurimento e
binding errato sono controllati prima del begin; token stale/zero o fuori tipo
sono rifiutati prima di mutazioni. Le lease catturate sono verificate contro
le capacità correnti: usare direttamente le API sottostanti durante un tratto
del bridge viola il protocollo e una capacità stale impedisce nuovi pop.

Il debito batch impedisce la fine prima di rilasciare Serie. Dopo la release
riuscita, il token Serie locale diventa zero: end busy conserva CLOSING e la
lease writer in FINISHING; la sola operazione permessa è ritentare termina.
Il retry non legge né libera di nuovo il controller, già utilizzabile da un
altro worker. Il risultato `:schedule` resta un obbligo unico nel worker,
da ricircolare o cedere con le sue API. Non si riapplica un prefisso di batch.

Il confine registra la stessa condizione inattesa in bridge e worker terminali,
conservando riferimenti e lease. Se il worker era già FAULTED, conserva la sua
prima causa; il bridge registra quella dell'operazione corrente. Marca il
controller FAULTED con ambito Archivio
soltanto quando owner e generazione della lease Serie sono ancora quelli
catturati. Dopo un handoff riuscito o una lease stale non tocca il controller
del tratto successivo: il caller deve fermare e coordinare l'Archivio sulla
diagnosi conservata. Nessun rollback, rilascio automatico o prova di quiescenza
è promesso. La salute non impedisce l'acquisizione: le API del controller
continuano a distinguere il drenaggio I/O consentito dalla nuova pubblicazione
vietata su fault. Fine I/O, ritiro e riuso restano regolati dal controller.

Il coupling interno a execution e Series è esplicito: controlli owner/lease,
generazione catturata e fault marking senza verificatori che possano mascherare
l'errore originario. Nessun I/O, thread, attesa, callback, lookup o contatore
globale viene aggiunto. Le API nuove sono O(1), oltre alla copia batch già
bounded. Il bridge cambia proprietà in memoria; non introduce atomicità durevole.
Routing, coordinatore Archivio, pool, admission, wake/park e applicazione dei
payload rimangono aperti. Le prove locali non qualificano il motore completo.
