# Passo bounded del dispatcher pool/Serie

`arcdocdb.scheduler.dispatch:passo-dispatcher-pool` coordina un singolo passo
prima dell'avvio del bridge. Incremento C3 di REQ-THR-001,
REQ-CON-001/002/004/005 e REQ-AFF-008: riusa il [dispatcher](pool-dispatch.md)
e non introduce un secondo stato mutabile per lease, token o obblighi.
Il [metodo preregistrato](pool-step-metodo.md) delimita la qualifica.

## Contratto e risultati

Owner corrente, assenza di rientranza, bridge precedente chiuso e contesto
coerente. Binding porta/tabella e owner sono controllati prima della fase.
Il getter pubblico del contesto determina un solo ingresso operativo:

| Fase in ingresso | Operazione | Origine | Dettaglio | Azione lifecycle |
|---|---|---|---|---|
| IDLE | Nuova presa governata | `:claim` | Cursore originale | Originale del gate |
| CLAIMED | Collegamento dell'obbligo corrente | `:current` | NIL | NIL |
| RESCHEDULE | Un ricircolo | `:recycle` | Count della partizione | NIL |

Cinque valori: **link/NIL, status, origine, dettaglio, azione lifecycle**.
Lo status è `:claimed`, `:empty`, `:busy`, `:inactive` o `:published`,
originale dell'ingresso selezionato; current restituisce `:claimed`.
NIL negli ultimi due valori di current indica assenza di trasferimento e
di osservazione lifecycle. NIL per l'azione recycle non significa comando
immutato: il pool non è stato consultato.

Ogni chiamata esegue **un solo ingresso operativo e al più un trasferimento
ready**. Binding, getter e routing di sola lettura non sono trasferimenti.
EMPTY, BUSY e INACTIVE sono esiti della sola nuova presa; il cursore resta
quello restituito dal gate, senza essere reinterpretato come occupazione.
Non provano quiescenza globale, park o arresto sicuro.

CLAIMED non fa nuove prese, ricircoli o ACK del pool: seleziona il link
corrente IDLE e conserva l'obbligo, anche con pool inattivo, ritiro pendente
o comandi incoerenti. Ripetere current non produce avanzamento da solo.
Il caller usa separatamente l'[avvio esplicito](pool-begin.md), poi le API
del bridge per pop, conferma e fine.

RESCHEDULE riusa il [ricircolo](pool-recycle.md): room pubblica e termina
immediatamente IDLE, senza cadere in una seconda presa. Full restituisce
il nuovo CLAIMED e il suo link, mai il precedente. Non legge lifecycle né
conferma il ritiro: questo appartiene alla successiva chiamata IDLE.
Sotto saturazione permanente non si promette convergenza del ritiro.

## Rifiuti e guasti

RUNNING, BATCH, FINISHING e FAULTED segnalano `resource-exhausted
:worker-state` prima di qualsiasi ingresso operativo, conservando debiti,
lease, ring e prima causa. Non vengono validati nuovamente i campi di un
contesto attivo o terminale dal governo C3. Owner e binding mantengono
l'ordine e le diagnosi degli ingressi esistenti.

Una fase inattesa segnala `invariant-violation :pool-dispatcher-state`.
Il case è in un helper NOTINLINE con argomento T: anche una FI del getter
fuori dal suo ftype passa un controllo operativo, senza scambiare questa
prova di confine per un ritorno nominale C1.

BUSY della nuova presa è un ritorno con origine claim e cursore.
`resource-exhausted :ready-queue-busy` del ricircolo rimane invece la
condizione originale, con RESCHEDULE e obbligo conservati. Nessun retry,
handler, cleanup o rollback viene aggiunto. Un routing fallito dopo full
non annulla lo scambio riuscito: riferimento e home del nuovo writer
rimangono nel contesto FAULTED con la causa originale; il vecchio è già
nel ring. Il caller conserva i riferimenti e coordina la diagnosi Archivio.

## Costo e limiti

Scelta della fase O(1); lookup current e ricircolo home O(1). Solo il claim
può eseguire la scansione ready O(K), con K massimo 64. Nessun ciclo nuovo,
allocazione intenzionale, callback, thread, attesa, I/O o scrittura
condivisa tra Serie per messaggio. Il costo dei delegati C1 è incluso.

Il passo non inizia o chiude il bridge, non applica payload e non è il loop
del server. Admission dei messaggi, sensori, park/wake, avvio/arresto fisici
e coordinamento Archivio restano aperti. Nessun protocollo durevole cambia
e nessun gate del motore completo viene chiuso.
