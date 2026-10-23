# Avvio dell'obbligo pool sulla Serie

`arcdocdb.scheduler.dispatch:inizia-obbligo-pool` avvia esplicitamente un
obbligo CLAIMED gia acquisito dal [dispatcher](pool-dispatch.md), dal
[ricircolo full](pool-recycle.md) o dalle API execution. Incremento C3 di
REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008; non modifica sorgenti C1.
Il [metodo preregistrato](pool-begin-metodo.md) delimita le verifiche.

## Contratto

Owner corrente, assenza di rientranza, worker CLAIMED e link associato IDLE.
L'API verifica porta, owner, tabella e contesto come gli altri ingressi;
seleziona il link del writer attuale tramite il routing verificato e chiama
una sola volta `inizia-worker-serie`. Restituisce quattro valori:

| Valore | Significato |
|---|---|
| link | Collegamento preallocato selezionato sul CLAIMED corrente. |
| token | Token del nuovo tratto, valido soltanto con quel link. |
| fase | `:active` oppure `:closing`, originale del bridge. |
| ragione | NIL, `:serie-busy` o `:serie-lease-generation`, originale del bridge. |

Con ACTIVE il caller puo usare il bridge per lease, pop, conferma e fine.
Con CLOSING conserva link e token e chiama esplicitamente
`termina-worker-serie`: non puo fare pop o ritentare l'acquisizione della
Serie. L'esaurimento della generazione richiede gestione della risorsa,
senza riprogrammazione indefinita. Nessun cleanup viene aggiunto.

Writer-busy segnala la condizione originale, lascia il worker CLAIMED e
il link IDLE e non consuma un token del bridge; il caller conserva l'obbligo
e decide un successivo tentativo. Fasi errate, fault e guasti inattesi
mantengono le classificazioni e le capacita delle barriere C1. Un routing
fallito precede il begin; un errore durante begin non annulla acquisizioni
gia riuscite. La medesima condizione viene propagata senza handler C3.
Su un errore inatteso dopo acquisizione non sono restituiti i quattro
valori: riferimenti, capacita e diagnosi restano nel contesto e nel link C1,
per il coordinamento dell'Archivio. Il caller conserva i link gia ottenuti
da claim/recycle; dopo adozione puo selezionarli prima con
`collega-obbligo-pool`. Non viene promessa una nuova via di chiusura dopo
un fault terminale.

La nuova API ricalcola il link ad ogni ingresso: dopo full usa il nuovo
writer, senza accettare dal caller un link del tratto precedente. Non crea
un'obbligazione, non chiama claim o recycle, non legge comandi pool e non
conferma il ritiro. Inattivazione, ritiro pendente o parole lifecycle
incoerenti non impediscono il completamento di un obbligo esistente.

## Costo e ambito

Il passo e O(1): binding EQ, routing per ordinale e un tentativo di doppia
lease della sola Serie. Nessuna nuova allocazione intenzionale, scansione,
scrittura condivisa tra Serie, callback, I/O, thread o attesa. Il costo delle
barriere C1 resta incluso; non si rivendicano prestazioni del solo adapter.

Nuova presa, ricircolo e avvio restano ingressi distinti. Non sono introdotti
loop server, applicazione dei payload, admission, sensori, park/wake,
avvio/arresto fisico o coordinamento Archivio. I protocolli durevoli e i
gate del motore completo restano invariati.
