# Revisione del contesto worker dei writer

Ambito C1: quattro nuovi sorgenti worker, export/ASDF e composizione con
writer, handoff, ready e recycle. Prima lettura indipendente e chiusura dei
finding conservate; seconda lettura sul codice e sulle campagne congelate.
[Inventario delle decisioni](writer-worker-decisioni.md),
[risultati](writer-worker-risultati.md) e
[catalogo](../../spikes/results/2026-10-09-writer-worker/catalogo.lisp)
mantengono denominatori e dati originali, senza esclusioni approvate.

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Contesto locale per tratto, senza coda globale per messaggio. |
| 2. Invarianti | Obbligo unico, owner immutabile, lease singola, debito batch positivo≤extracted e ack corrente; stati controllati prima/dopo. Oracolo 8000 passi, fixture parallele e 12 mutanti rilevati. |
| 3. Errori | Recuperabili solo tipo/ragione espliciti per API; owner e faulted prima del handler. Inattesi/permanenti conservano condition originale e campi in faulted terminale; nessun retry cieco o reset. |
| 4. Limiti | Nuove API senza cicli, ricorsione, retry o attese. Take delegato≤64 shard/128 CAS; altri passi O(1), oltre copia batch bounded. Fixture bounded e thread con timeout. |
| 5. Allocazioni | Contesto e buffer preallocati, handler interno dynamic-extent. Venti campioni locali composti heap0 e controllo positivo 16777472 byte; startup/errori esclusi dalla misura, nessuna promessa universale. |
| 6. Dati | Riferimenti typed opachi; target/span/alias verificati prima dell'overflow e del pop. Token locale alla coppia contesto/token, generazioni monotone senza wrap; payload e buffer restano al caller. |
| 7. Decisioni | Inventario di quattro file, predicati nuovi scalari; macro con fixture espansione/valori/errore originale. Raw 11 file: 1427/1660 espressioni e 199/230 esiti, nuovi 498/600 e 65/76; tutte le lacune nel denominatore, nessuna MC/DC dedotta. |
| 8. Proprietà | Owner read-only uguale al thread creatore, non rientrante. Claim/recycle assumono obbligo; cede/adopt lo trasferiscono solo senza lease/batch. Getter diagnostici non trasferiscono proprietà; unicità obbligo precondizione caller. |
| 9. Check | Processo 4000547204-command-93189-0 OK/STABLE/exit0: 387 test più smoke, lint 63/zero, trace/link/evidenze e 10 spike. Integrazione distinta4000548048-command-40192-0 su e2f7a75: 400 test più smoke, lint66/zero. C4 strict compile/FASL self-test e 12/12 mutanti; copertura e benchmark in cache separate. |
| 10. Standard | Safety3, ftype per funzioni, slot typed, docstring pre/post/condition; corpi≤60 righe e complessità ≤10. Macro boundary conserva valori multipli/valutazione unica e intercetta errori solo per stato/diagnosi definiti (COD-21). |
| 11. Parallelismo | Nessuna scrittura globale per messaggio, nuovo lock o thread di prodotto. Contesti locali; guard ready una volta per tratto. Thread riusati/produttori vivi e progresso su shard indipendente; fairness e scalabilità del pool non qualificate. |
| 12. Atomicità | Nessun I/O o modifica durevole. Finishing latched prima di end; busy conserva lease. Dopo end si cambiano soltanto campi locali: nessun cleanup del writer può cancellare una nuova ondata. Ricircolo full atomico delegato; fault interno fail-stop senza rollback promesso. |

La prima lettura ha chiuso tre finding prima del congelamento: fault
permanente che deve impedire retry su una nuova ondata, debito batch oltre
extracted e indici privati malformati che non devono essere classificati
come input adozione recuperabile. Le regressioni usano FI dichiarata,
conservano la condition originale e verificano i gate terminali.
Una correzione della fixture macro alle keyword delle allowlist avviene
nella bozza, prima di qualsiasi esecuzione o congelamento.

La postcondizione dopo end non consulta una lease già rilasciata: il
helper locale verifica finishing/debito, elimina la lease locale e passa
idle o reschedule. Busy del primo end cambia solo la fase in finishing;
retry successivi non permettono pop/ack o cessione. La generazione batch
esaurita impedisce pop, ma lascia disponibile end e cessione senza lease,
seguita da adozione in un contesto fresco.

Faulted è il confine di questo contesto, non il controller della Serie.
Il caller deve elaborare tutto il batch prima dell'ack e non abbandonare
obblighi ceduti. Wake/park, admission, quote globali, fairness, retirement
del pool, shutdown, fault cleanup e applicazione WAL restano da integrare.
Nessuna esclusione, gate del motore o qualificazione globale viene chiuso.
