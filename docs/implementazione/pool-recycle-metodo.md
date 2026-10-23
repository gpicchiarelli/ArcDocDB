# Metodo del ricircolo pool/Serie

Preregistrazione del 2026-10-14 sulla base
`a5715a1aa0b2571d650d1b794e9bb7b7324e951e`, prima delle campagne formali.
Il [contratto](pool-recycle.md) definisce una sola operazione ready per passo.
Scope C3 completo del dispatcher esteso: `src/dispatch/package.lisp`,
`types.lisp`, `build.lisp`, `claim.lisp` e nuovo `recycle.lisp`.
Nessun sorgente C1 è modificato; ricircolo, worker, routing e bridge sono delegati.

## Prove e revisione

- Room: pubblicazione FIFO dell'obbligo, NIL/status/count esatti e IDLE.
  Nessun routing, seconda presa o conferma del ritiro; distinguere count da cursore.
- Full: scambio reale A→B, A in coda, count invariato e link corrente B IDLE,
  senza begin. Home e cursore conservati.
- Porta inattiva, ritiro pendente e parole lifecycle incoerenti: ricircolo
  indipendente dal pool. Completamento del nuovo CLAIMED, ritorno a IDLE e
  ritiro confermato soltanto dalla successiva presa esplicita.
- Guard ready realmente occupata: errore busy e preimage di ring, contesto,
  writer, collegamenti, controller e parole pool; retry solo esplicito.
- Owner estraneo e binding fra contesti diversi: rifiuto prima del trasferimento.
- Tutte le fasi coerenti diverse da RESCHEDULE, FAULTED compresa: rifiuti
  delegati e diagnosi/debito/lease conservati, prima causa EQ.
- Writer sconosciuto o link invalido dopo full: trasferimento già avvenuto,
  vecchio obbligo in ready e nuovo riferimento conservato in FAULTED, controller
  e lease Serie intatti. Nessun rollback dedotto da un'eccezione.
- FI quiescenti e ripristinate per writer/status contraddittori e sentinelle
  che distinguono assenza di gate/routing da un semplice risultato NIL.
  Uno status fuori ftype è un guasto di contratto, non un ritorno nominale:
  la guardia separata NOTINLINE deve rifiutarlo prima del routing, preservando
  contesto, ring e prima causa. La FI non qualifica un ritorno C1 reale.
- Lettura indipendente C3 del componente esteso e dei test, con lista di
  controllo, compilazione strict, safety 3, lint e tracciabilità.

## Copertura

Almeno 95% di espressioni e rami sull'intero componente di cinque file,
senza esclusioni manuali. Pubblicare anche tutti i conteggi per file e i
missing, compresi i rami difensivi fuori dominio del delegato se SBCL li
mantiene. Denominatore zero significa solo nessuna sonda nativa di quel tipo,
non assenza di decisioni nel sorgente. Nessuna inferenza MC/DC o copertura
dei delegati C1 nel denominatore C3.

Conservare SB-COVER nativo, HTML originali e audit esatto native/HTML.
Riutilizzare il reader verificato con adattatore esplicito allo scope esteso,
test negativi su file, shape, duplicati, denominatori e missing paths.

## Memoria e misura locale

Sensore C4 con campionamento già verificato, self-test dedicati e due
campagne reali. Ogni replica ha una fixture nuova: cinque repliche da
4096 cicli, 128 warmup, queue preallocate con abbastanza payload simbolici
immutabili e quantum uno. Factory, API lookup, GC e drain finale sono fuori
clock; nessun reset di stati o generazioni privati.

| Campagna | Ciclo misurato |
|---|---|
| ROOM | Ricircolo pubblicato, nuova presa esplicita, begin execution, pop di un payload, ack e fine in RESCHEDULE; link IDLE. |
| FULL | Ricircolo su ring pieno, link alternato del nuovo CLAIMED, begin execution, pop di un payload, ack e fine in RESCHEDULE; link IDLE. |

Sono cicli integrati: comprendono il protocollo C1 execution e gli oracoli scalari,
senza attribuire il tempo al solo adapter. La nuova presa ROOM appartiene
alla fixture esplicita, non è una chiamata nascosta nel ricircolo.
Il bridge Serie non viene iniziato nel clock e nessuna lease Serie viene
acquisita dalla misura; le prove funzionali verificano separatamente il bridge.
Count, status e identità del link contribuiscono all'oracolo.
Cleanup pubblico bounded risolve tutti gli obblighi della fixture prima
di chiudere i backend I/O; nessun abbandono è qualificato come arresto valido.

Conservare tick, heap, sink e cicli completati. Il sensore deve rilevare
allocazione positiva deliberata, ritorni difformi, sink errato, clock sotto
risoluzione, CLI invalida, raw parziali e destinazioni preesistenti.
Carico esterno incontrollato, nessuna taratura, soglia o conclusione sul
throughput del motore. Heap zero osservato non prova assenza universale di
allocazione né correttezza di un coordinatore concorrente.

Qualifica in copia congelata con `record-command.lisp`, cache dedicate,
argv/output/exit e impronte iniziali/finali. Fallimenti e versioni preliminari
restano distinti dagli originali congelati. Conservazione byte per byte,
nuovi manifesti esclusivi e controllo completo con i dieci spike esistenti.
