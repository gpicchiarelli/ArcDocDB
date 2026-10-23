# Metodo del ricircolo dei writer pronti

Registrato il 2026-10-09 prima delle campagne, base `673987a`.
Il componente C1 integra la [lista pronta](writer-ready.md) con il
trasferimento di obblighi del [writer](writer-handoff.md), senza creare
thread o implementare un pool. REQ-CON-001/002/004/005 e REQ-AFF-008;
INV-P1/P2/P5/P6, INV-A8 e INV-V4; ADR-0005 e ADR-0045 §§6/8.

## Contratto

`ricircola-writer-pronto(ready, shard, writer)` riceve un obbligo unico
`:schedule` che appartiene al chiamante. Richiede che il chiamante possa
prendere in carico un altro writer. Non legge lo stato dei writer e non
rileva deduplicazione o eleggibilità: valgono le precondizioni già adottate.
Una sola acquisizione CAS della guard locale, nessuna attesa o retry.

- Se il ring ha spazio, pubblica il riferimento in FIFO e restituisce
  NIL, `:published`, nuovo count: l'obbligo passa al ring.
- Se il ring è pieno, trasferisce al chiamante il riferimento in testa e
  inserisce il nuovo in coda nella medesima sezione: restituisce il writer
  estratto, `:writer`, capacity. Head e tail avanzano di uno modulo capacity;
  count resta invariato. In full head=tail, quindi basta sostituire uno slot.
- Busy è `resource-exhausted :ready-queue-busy` prima della mutazione;
  l'obbligo originario resta al chiamante. Indice/riferimento errati sono
  `invalid-argument`; guasti di forma/proprietà/payload sono invarianti
  fail-stop, senza rollback promesso dopo un guasto interno.

Full `[C,B,...,Z]` diventa `[B,...,Z,A]`: A passa al ring e C al chiamante
insieme. Capacity 1 è `[C]`→`[A]`. Un ritorno `:writer` non autorizza a
pubblicare di nuovo A. Il chiamante conserva C durante busy di avvio.
La guard rende lo scambio atomico rispetto a producer e consumer sul ring.
Un pop e una pubblicazione separati non realizzano questo contratto.

## Problema e confini

Con la sola pubblicazione, tutti i consumer possono terminare un tratto
con backlog mentre i ring sono già pieni e restare impegnati a ritentare:
nessuno consuma i riferimenti già pronti. Il modello conserva il
controesempio. Il ricircolo consegna invece una nuova testa direttamente
al consumer, senza una seconda coda o una capacità variabile.

Questo risolve il blocco dovuto alla sola capienza dei ring nel protocollo
modellato. Non qualifica la liveness generale del pool: guard perpetuamente
contese, obblighi abbandonati o duplicati, fault di Serie e admission richiedono
un controller. Una catena full resta sullo stesso shard; non dimostra equità
fra partizioni o assenza di starvation per nuovi producer. Il caller deve
governare le quote e gli altri compiti. Empty resta un'osservazione locale,
mai una prova per parcheggio, arresto o ritiro del worker. Nessun cleanup
sul writer dopo end: una nuova ondata può essere già pubblicata.

Costo O(1), un'acquisizione e un rilascio CAS, nessuno stato globale nuovo
né scrittura comune per messaggio. Factory, ready e handoff restano invariati.

## Prove preregistrate

- Oracolo FIFO indipendente con seme, 8 configurazioni (capacity 1/2/3/9 e
  1/4 shard), writer distinti, obblighi legali, wrap e riuso dopo completamento.
- Modello/fixture con ring riempiti durante tratti in corso: controesempio
  alla sola pubblicazione e avanzamento bounded con ricircolo; proprietà
  unica dell'obbligo, lease singola e elaborazione unica dei payload.
- Full/room, input invalidi, rifiuto busy senza effetti, FI private su forma,
  tipo del riferimento e proprietà; due consumer riusati, producer vivo,
  avanzamento di altra partizione mentre una guard resta occupata.
- Due letture C1, inventario completo delle decisioni e copertura raw dei
  file execution. Nessuna forma sottratta o esclusione approvata; sb-cover
  non prova MC/DC. Compilazione senza warning/style-warning e make check.
- Undici mutanti del nuovo sorgente: fifo-next-slot, head-wrap-two,
  tail-wrap-two, full-count-decrement, full-keeps-old-slot, full-boundary,
  full-returns-new-writer, room-returns-writer, full-status-published,
  release-skipped, full-no-rotation. Baseline completa obbligatoria;
  compilation failure, before-tests e worker-error (segnali OS o guasti dopo
  completion autentica) non contano come rilevamento.
- Misura composta handoff/ready/ricircolo: shard 1/4 × capacity 1/3,
  cinque campioni da 4096 cicli, warmup 128 e GC fuori dal contatore.
  C+1 writer distinti per shard, ruolo iniziale ruotato a ogni ciclo;
  pubblicazione room, scambio full e drain di C riferimenti restanti.
  Identità, count, status, payload e generation controllati; sink esatto
  ricalcolato indipendentemente, controllo heap positivo, sink errato
  rifiutato, clock zero distinto e report parziali preservati.
  I campioni non provano zero allocazioni universale, speedup, throughput
  del pool o P99. Startup e condizioni d'errore sono fuori dalla finestra.

Ogni tentativo di verifica usa record-command, con argv, ambiente, sorgenti
stabili e output integrali. I C4 sono compilati interamente e i FASL eseguono
self-test in processi/cache separati. Campagne su copia congelata; dati grandi
compressi senza perdita, validati dal lettore delle evidenze.

## Oracoli e modifiche esatte preregistrati

Le undici sostituzioni uniche sono fissate in
[`tools/writer-recycle-mutation.lisp`](../../tools/writer-recycle-mutation.lisp)
prima dell'esecuzione. FIFO legge lo slot successivo; head e tail avanzano di
due separatamente; count full decrementa; lo slot conserva OLD usando
`(if (eq writer old) writer old)` per evitare warning estranei; la soglia
full usa `>`; il riferimento restituito diventa WRITER; room restituisce
WRITER invece di NIL; status full diventa `:published`, anche nella ftype;
il cleanup diventa NIL; NEXT diventa HEAD conservando la forma full ma
violando la rotazione FIFO. Ciascun mutante cambia solo il nuovo sorgente.

Derivazione indipendente del benchmark: M=K(C+1), enqueue contribuisce 12M,
consume 45M+5Σid e il trasferimento delle identità 17M+5Σid, con id da 1 a M.
Room aggiunge K(31C+3C(C+1)/2), full K(13+3C); i cursori del drain aggiungono
7CK(K−1)/2 e empty 29. Il token fisso è quindi
`74M+5M(M+1)+K(31C+3C(C+1)/2+13+3C)+7CK(K−1)/2+29`.
Per (K,C)=(1,1)/(1,3)/(4,1)/(4,3): 257/558/1223/3231.
Il sink dei 4096 cicli include Σi: 9439232/10672128/13395968/21620736.
Le chiamate per ciclo sono `K(6C+5)+1`: 12/24/45/93.
