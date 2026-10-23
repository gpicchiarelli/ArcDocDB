# Ricircolo dal dispatcher alla Serie

`arcdocdb.scheduler.dispatch:ricircola-collegamento-pool` completa il
[dispatcher pool/Serie](pool-dispatch.md) quando un tratto chiuso lascia
un obbligo RESCHEDULE. È un incremento C3 di REQ-THR-001,
REQ-CON-001/002/004/005 e REQ-AFF-008: riusa le barriere C1 di
[ricircolo](writer-recycle.md), worker e routing senza modificarle.
Il [metodo preregistrato](pool-recycle-metodo.md) delimita la verifica.

## Contratto del passo

Il proprietario corrente chiama l'API sul dispatcher preallocato, senza
rientranza, con worker RESCHEDULE, obbligo unico, lease e debito nulli e
bridge precedente già chiuso. Binding porta/tabella e owner vengono
verificati prima di qualsiasi trasferimento. Il contesto è quello immutabile
della porta: non esiste un secondo argomento context da disallineare.

Il passo esegue **una sola** `execution:ricircola-worker` sulla partizione
home, quindi restituisce tre valori:

| Valore | Significato |
|---|---|
| link oppure NIL | Link preallocato del nuovo writer CLAIMED; NIL se pubblicato. |
| `:claimed` oppure `:published` | Esito originale del ricircolo. |
| count | Occupazione della singola partizione al punto del ricircolo; non cursore né snapshot globale. |

Con spazio nel ring, pubblica il writer precedente e torna IDLE. Restituisce
NIL e termina immediatamente: non seleziona un link, non interroga il pool e
non prende un nuovo writer. La successiva presa rimane una chiamata esplicita.

Con ring pieno, lo scambio FIFO C1 consegna la vecchia testa al contesto e
pubblica in coda il writer precedente, conservando count. L'API seleziona
il link del **nuovo** CLAIMED mediante ordinale ed identità writer verificati.
Il link rimane IDLE; begin, token, pop, ack e fine del bridge sono espliciti.
Non riutilizza il link del tratto precedente e non modifica home o cursore.

## Ritiro e guasti

Il passo non legge request/ack/active e non applica comandi lifecycle.
Ritiro pendente, porta inattiva o parole pool incoerenti non impediscono di
risolvere un obbligo già assunto. Dopo una pubblicazione riuscita, il caller
può invocare separatamente `prendi-collegamento-pool`: la barriera IDLE
permette allora di confermare il ritiro prima di una nuova presa.
Uno scambio full assegna invece un altro obbligo da completare. Non si
promette convergenza del ritiro sotto saturazione perpetua del ring.

Owner e binding errati hanno gli stessi rifiuti del dispatcher esistente,
prima del trasferimento. Le fasi diverse da RESCHEDULE e i verificatori di
execution restano nelle barriere C1. FAULTED conserva la prima causa.
Una guard ready occupata segnala `resource-exhausted :ready-queue-busy`,
con RESCHEDULE e obbligo intatti: ogni retry appartiene al caller.

Un routing invalido dopo full non annulla lo scambio: il vecchio writer è
già nel ring; il nuovo riferimento e home restano nel worker FAULTED con la
condizione originale, senza lease della Serie. Il caller coordina la diagnosi
dell'Archivio. Non si rivendica preimage immutata dopo un trasferimento riuscito.
Il nuovo componente non scrive direttamente fault, writer, ring o controller.

Ritorni writer/status incoerenti del delegato segnalano
`invariant-violation :pool-dispatcher-state`, prima del routing; anche lo
status inatteso passa una guardia separata con argomento T e NOTINLINE,
che mantiene il controllo anche se il delegato viola il proprio ftype.
Il case successivo conserva il ramo finale difensivo. Non ci sono handler che nascondano un
errore, rollback, cleanup, cessione o pubblicazione aggiuntivi.

## Costo e ambito

Il passo è O(1): controllo owner e identità EQ, una partizione home, un
tentativo di guard e, solo dopo full, routing indicizzato. Nessuna scansione,
hash, nuova allocazione intenzionale, scrittura condivisa tra Serie per
messaggio, callback, attesa, thread o I/O. Il count descrive il trasferimento
appena concluso; altri worker possono già aver cambiato il ring al ritorno.

Il dispatcher ora espone separatamente nuova presa, collegamento di un
CLAIMED già posseduto e ricircolo di RESCHEDULE. Non è il loop completo del
server: applicazione dei payload, sensori, admission, park/wake, avvio e
arresto fisici e coordinamento dell'Archivio restano aperti. Non cambia
protocolli durevoli e non chiude i gate del motore completo.
