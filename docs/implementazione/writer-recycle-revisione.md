# Revisione del ricircolo dei writer pronti

Ambito C1: nuovo `ready-recycle.lisp`, export/ASDF e composizione con handoff
ed elenco pronto. Le due letture indipendenti, iniziale e conclusiva, sono
conservate nell'[inventario](writer-recycle-decisioni.md) e nel
[catalogo](../../spikes/results/2026-10-09-writer-recycle/catalogo.lisp).

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Ricircolo della lista condivisa per tratto, senza coda comune per messaggio. |
| 2. Invarianti | Obbligo unico, FIFO locale, count e capacità invariati in full, guard esclusiva, lease singola. Oracolo 8.000 passi, regressione della saturazione e thread reali; undici mutanti rilevati. |
| 3. Errori | Input e busy prima della mutazione; invarianti typed/fail-stop, senza rollback dopo guasto interno. Busy conserva l'obbligo, anche nell'avvio del riferimento restituito; controller FAULTED ancora da integrare. |
| 4. Limiti | Nessun ciclo, retry, ricorsione o attesa nel nuovo sorgente. Una acquisizione CAS più rilascio, O(1); ring e shard mantengono i limiti esistenti. Harness/thread con timeout e numero di tentativi finito. |
| 5. Allocazioni | Nessuna allocazione esplicita nel normale ricircolo; composizione preallocata con heap osservato zero in 20 campioni locali. Controllo positivo riuscito; startup/errori fuori misura, nessuna promessa universale. |
| 6. Dati | Tipo del nuovo riferimento e vecchia testa verificati; indici/forma sotto guard. Il ring trasporta riferimenti opachi senza interpretare payload o dati persistenti. |
| 7. Decisioni | Cinque predicati scalari; nessuna nuova decisione composta. Copertura 81/86 espressioni, 8/8 esiti; top-level e lacune legacy restano nel denominatore 929/1060 e 134/154. Nessuna esclusione o MC/DC dedotta. |
| 8. Proprietà | Guard/ring locali; successo trasferisce A→ring e C→caller insieme. Caller capace di assumere C, obbligo unico come precondizione, nessuna membership o dedup nuova. |
| 9. Check | 309 test più smoke, lint53/zero violazioni, trace/link/evidenze e dieci spike. Processo4000528494-command-77199-0 OK/STABLE/exit0; chiusure editoriali controllate separatamente. |
| 10. Standard | Safety3, ftype completi, docstring, massimo20 righe per funzione e complessità locale≤3. Pre/post attraverso %check-pronta e helper delegati; unwind-protect solo rilascio. Due C4 compilati integralmente con avvisi fatali e self-test FASL. |
| 11. Parallelismo | Nessun nuovo lock globale o scrittura comune per messaggio. La guard serializza solo la breve operazione del proprio ring, una volta per tratto. Progresso dell'altro shard verificato; nessuna fairness o lock-freedom promessa. |
| 12. Atomicità | Nessun cambiamento durevole, I/O o eliminazione. Full sostituisce lo slot head=tail e avanza gli indici sotto guard; count invariato. Nessun cleanup può cancellare un'ondata successiva del writer. |

Il helper `%ricircola-pronto` verifica la precondizione e delega la
postcondizione ai due rami `%scambia-pronto` e `%pubblica-pronto`, entrambi
con controlli significativi prima e dopo la mutazione. La proprietà della
guard è verificata all'acquisizione e al rilascio della API pubblica.

La prima lettura indipendente non ha trovato difetti funzionali; il solo
commento `publica` è corretto in `pubblica` prima delle campagne. La seconda
lettura considera sorgenti congelati e raw di build, copertura, mutazioni e
allocazioni. Nessuna esclusione approvata o chiusura dei gate del motore.

La capacità piena non impedisce lo scambio nel protocollo modellato. Questo
non prova liveness con guard perpetuamente occupate, obblighi invalidi o
controller assente. Catene full sullo stesso shard possono affamare altre
attività. Pool, quote globali, risvegli, parcheggio, admission e shutdown
richiedono integrazione; empty resta un'osservazione locale.
