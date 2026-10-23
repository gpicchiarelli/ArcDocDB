# Preparazione bounded di un tratto pool/Serie: metodo

Preregistrazione C3/C4 del 2026-10-15, base
`7f1cc54477483039bd98bd8c3f6508416f5c0ced`, prima del codice e delle prove.
REQ-THR-001, REQ-CON-001/002/004/005, REQ-AFF-008; ADR-0031/0034/0045.

## Contratto fissato

`prepara-tratto-pool dispatcher` esegue un solo
[passo di selezione](pool-step.md). Soltanto con CLAIMED avvia direttamente
il bridge del link restituito: owner non rientrante e nessun altro passo
interposto rendono inutile un secondo routing. Al più un trasferimento
ready e un begin; nessun pop, ACK batch, end, retry o cleanup implicito.

Sette valori: **link, token, stato, ragione, origine, dettaglio, azione**.
I primi quattro conservano la forma dell'[avvio](pool-begin.md): ACTIVE o
CLOSING con token positivo e ragione originale. EMPTY, BUSY, INACTIVE e
PUBLISHED restituiscono NIL/0/stato/NIL senza begin; gli ultimi tre valori
provengono dal passo, distinguendo cursore, count e assenza di trasferimento.
Una pubblicazione termina subito; il ritiro rimane al successivo ingresso IDLE.

Fasi già attive, owner/binding invalidi e guasti dei delegati mantengono le
condizioni originali. Writer busy conserva CLAIMED/link IDLE; Serie busy o
generazione esaurita restituiscono CLOSING da terminare esplicitamente.
Errori dopo un trasferimento non lo annullano e non autorizzano replay.
Un helper NOTINLINE con link/status T conserva i controlli della coppia:
CLAIMED richiede un link, gli esiti senza lavoro richiedono NIL; status
inattesi segnalano `invariant-violation :pool-dispatcher-state`.

## Qualifica prevista

- Test della nuova presa con attivazione, CLAIMED corrente con pool inattivo,
  ricircolo full/room, ritiro pendente, tutti i sette valori e FIFO reale.
- Conteggio delle chiamate: un solo passo, un begin solo con CLAIMED; nessun
  secondo routing o avvio del bridge, pop, ACK, end o nuova presa dopo published.
- Rifiuti owner/binding/fase prima degli effetti; BUSY della coda ready e del
  writer, Serie busy e limiti di generazione; causa EQ e capacità conservate.
- FI fuori contratto della coppia link/status e status inattesi, distinguendole
  dalle prove nominali dei delegati C1. Cleanup delle sole risorse di fixture.
- Compilazione stretta, suite completa, lint/tracciabilità/link; copertura
  nativa dell'intero `src/dispatch/`, soglia C3 ≥95%, senza escludere missing.
- Sensore C4 con fixture e cleanup fuori clock: EMPTY e ciclo ACTIVE reale
  con payload, pop/ACK/end fuori dal solo ingresso ma inclusi nel ciclo
  misurato. Cinque fixture fresche per campagna, 4096 cicli e 128 warmup.
  Self-test di oracoli, rilevamento heap/sink/clock e conservazione dei guasti.
- Rilettura C3/C4 con checklist e identità dei file; registri e tentativi
  originali conservati. Nessuna modifica ai sorgenti C1.

Le misure includono controlli e delegati e non isolano il costo dell'adapter.
Non si promettono speedup, nuova concorrenza positiva, fairness o loop server.
Restano applicazione payload del motore, I/O durevole, park/wake e governo
dell'Archivio; nessun gate del motore completo viene chiuso.
