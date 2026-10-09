(:SCHEMA-VERSION 1 :KIND :C1-REVIEW-IMPORT :ROLE :AUTHOR :BASE
 "4215fca415c15d64bd56b1aa17d5c09fe6083713" :SOURCE :AUTHOR-DOCUMENT-SNAPSHOT
 :REPORT
 (:PATH "docs/implementazione/writer-handoff-revisione.md" :GIT-BLOB
  "1d324a6a6b11dd6b7122313d01a50cd59bb2934e" :TEXT
  "# Revisione della consegna locale dei writer

Lettura dell'autore sul codice finale e sui dati della copia congelata;
lettura indipendente e verifica integrata conservate nel
[catalogo](../../spikes/results/2026-10-09-writer-handoff/catalogo.lisp).
I due rilievi della prima lettura sono conservati nella
[tabella delle decisioni](writer-handoff-decisioni.md#prima-lettura-indipendente-e-correzioni):
contratto dei retry e complessità del controllo degli stati, entrambi corretti.

| Sorgente | SHA-256 |
|---|---|
| `queue.lisp` | `244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90` |
| `handoff.lisp` | `ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607` |
| `tests/execution/handoff.lisp` | `7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e` |

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0045 §§6/8. Nessun cambio di requisito o formato. |
| 2. Invarianti | INV-P1/P2: FIFO, lease e quantum cumulativo; INV-P5/P6: solo guard locale, nessun blocco o stato fra Serie. INV-A8/V4: budget e proprietari espliciti. Oracolo di 7200 passi e prove su thread reali; nessuna qualifica dell'intero motore. |
| 3. Errori | Full/busy precedono l'accettazione; busy al termine conserva la lease e non richiede rielaborazione. Gettoni vecchi/estranei e target invalidi rifiutati. Generation permanente, not-ready non eleggibile/duplicato. FI privata sulle guardie e sette stati incoerenti; invarianti al controller per fail-stop. |
| 4. Limiti | Nessun nuovo ciclo/ricorsione/attesa nel prodotto; un tentativo CAS per guard. Prelievo delegato bounded dal quantum e dallo span. I timeout e le attese con lease nelle fixture forzano interleaving, non costituiscono compiti del prodotto. |
| 5. Allocazioni | Oggetti e ring all'avvio; nessuna allocazione esplicita nel percorso normale. Dieci campioni preallocati osservano zero heap; controllo positivo rileva 16.777.472 byte. Misura seriale locale, esclusi startup, errori e controller; nessuna prova universale. |
| 6. Dati verificati | Payload interno opaco, ownership trasferita al conteggio riuscito; FIFO/span/lease delegati alle primitive. Nessun dato persistente decodificato o restituito da questo componente. |
| 7. Decisioni | Inventario scalari/CASE/cleanup completo; nessun nuovo and/or composto in handoff. Raw 173/190 espressioni e 16/16 esiti; 17 forme non marcate incluse, nessuna esclusione o MC/DC completa. Tutti i 16 mutanti compilano e sono rilevati. |
| 8. Proprietà | Wrapper e ring privati di una Serie. Guard del ring protegge anche stato/count; lease lega owner/generation al thread. Coda interna non esposta, copier assente; nessuna seconda guard. |
| 9. Tracciabilità/check | Annotazioni REQ coerenti; build forzata senza avvisi, suite execution riuscita. `make check` finale passa sulla base `4215fca`, con sorgenti stabili; record e output nel catalogo. Nessun requisito promosso. |
| 10. Standard | Safety 3, ftype completi, slot tipizzati, docstring pre/post/errori, funzioni sotto 60 righe. Helper degli stati con otto e quattro percorsi, entro COD-13; nessuna deviazione approvata o introdotta. |
| 11. Parallelismo | Messaggi modificano solo la propria Serie. Obbligo comune futuro solo su avvio/riaccodamento del tratto. B avanza con A che mantiene guard e lease nella fixture; nessuna misura di throughput, fairness o latenza del database. |
| 12. Atomicità | Nessun cambiamento durevole o eliminazione. Count e decisione ready/idle sono coordinati nella stessa sezione locale; release owner precede stato finale e rilascio guard. |

Nessun rilievo funzionale residuo nel contratto locale. Il chiamante deve
conservare ed eseguire una sola volta il compito restituito da `:schedule`;
il wrapper non implementa lista pronta, risvegli, shutdown o pool adattivo.
Non garantisce progresso se il chiamante abbandona l'obbligo o la lease.

## Strumenti e tentativi conservati

Gli strumenti C4 sono compilati per intero con warning/style-warning fatali.
I self-test verificano marker autentici, target mancanti/ambigui, sink errato,
clock nullo, destinazione esistente e persistenza dei report parziali.
Baseline, log dei sedici mutanti e misure sono conservati integralmente.

I primi due tentativi dell'adattatore di compilazione hanno fallito prima
delle campagne: contrib `sb-md5` non precaricato durante `compile-file`,
poi argv SBCL non impostato per il main del FASL. L'adattatore corretto
precarica i contrib e imposta entrambi gli argv. Il primo esportatore della
copertura cercava `index.html` invece di `cover-index.html`: il path è corretto,
senza modificare o ripetere la campagna di copertura. Output e sorgenti di
questi tentativi sono conservati; non vengono conteggiati come mutanti rilevati.
")
 :LIMITS
 (:LOCAL-CONTRACT-ONLY :NO-COVERAGE-EXCLUSIONS :NO-ENGINE-QUALIFICATION
  :UTF8-INTEGRATION-VERIFICATION-PENDING)
 :FINAL-INTEGRATION-BASE "7f8ca93499090b2a4f515015372046f16ac574cf")
