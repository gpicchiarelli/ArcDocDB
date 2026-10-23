# Preparazione del tratto: rilettura C3/C4

Lettura dell'autore il 2026-10-15, dopo le fixture di sviluppo e prima delle
campagne formali. Una lettura C3 con checklist ADR-0031/0034; non è una nuova
revisione C1 né una revisione indipendente. Esito statico favorevole, senza
rilievi aperti. Copertura, misure e controlli completi restano evidenze separate.

| Controllo | Riscontro |
|---|---|
| Requisiti e ambito | REQ-THR-001, REQ-CON-001/002/004/005, REQ-AFF-008; sole modifiche C3/C4. |
| Stato e owner | Nessun nuovo stato; passo pubblico verifica porta/owner/binding/fase prima della selezione. |
| Flusso limitato | Un passo e al più un begin; nessun ciclo o attesa nuovi nel prodotto. |
| Routing | Il link scelto viene usato direttamente; spy verifica un routing e zero chiamate al secondo adapter. |
| Risultati | Sette valori scalari; token originale con ACTIVE/CLOSING, zero con esiti senza begin; metadati originali. |
| CLOSING e busy | Distinti ritorni gate e condizioni writer/ready; chiusura esplicita con token vivo, nessun retry implicito. |
| Errori dopo trasferimento | Test con writer busy e routing invalido conservano claim/ACK riusciti; nessun rollback. |
| Difese operative | Link/status T e helper NOTINLINE; FI su dieci coppie/status, prima del begin. |
| Guasto terminale | Causa EQ, riferimenti e lease writer conservati; nessun handler o fault marking C3; limiti del caller documentati. |
| Memoria e parallelismo | Nessuna nuova allocazione intenzionale o stato globale; nessuna scrittura condivisa per messaggio. Misura formale separata. |
| C4 | Sette oracoli negativi; sensore heap/sink/clock condiviso, driver CLI/partial verificato; cinque fixture fresche per campagna. |
| Copertura e conservazione | Reader nativo/HTML a otto file, fixture indipendente 8/9 e 1/2 rami; raw, missing e tentativi conservati senza esclusioni. |

Identità SHA-256 dei file letti (il documento stesso non è autoreferenziale):

| File | SHA-256 |
|---|---|
| `src/dispatch/begin.lisp` | `4ae4bf8f6b7afe53af099a4b37ad75d253c05077f0cc7fbe39f4f1cab9f89a8d` |
| `src/dispatch/build.lisp` | `c78d31a753db78baea520e9ea0cccf6e88cad9cca8bc75261a6ff26c2ac01fe5` |
| `src/dispatch/claim.lisp` | `224e4114b8b91affced874bea9c23cae5c79526e8ddae62e31a0cafcbb763682` |
| `src/dispatch/package.lisp` | `6b791437e5b6c7c21dc9cf1be85b81ec0498725c307512b5978d4c8ed04e7255` |
| `src/dispatch/recycle.lisp` | `9fa3294cd28d1904cfb8db5153f93188b02f1bfbaf1800dad788731007c29ad0` |
| `src/dispatch/start.lisp` | `087fd623a51a89d4f5fe4d917ba7f563c8062b6e24ead3618d7f2501e0335b5d` |
| `src/dispatch/step.lisp` | `0d7653e6cbc0d93295f2ee1f84d142602af795933bf3147de9fc462c476212de` |
| `src/dispatch/types.lisp` | `cc44882c565a89de08f5add79333868ebfca4fc3f97bf9104d36375d014d4720` |
| `arcdocdb.asd` | `023ad35a7263ca41ba9a58abd4f5bb0983e80c459fa4b4eea9ee45275e0af194` |
| `tests/scheduler/pool-start.lisp` | `a6647dc88a69d58437ee8d738bf14b7d2dea94f17b24067a4fb3b4532f9a0bdd` |
| `tools/measure-pool-start.lisp` | `72dad0204d67d2d2596ee60dc252f939fc1bec2b82eeac8f19854299e48e73cf` |
| `spikes/out/pool-start/coverage-run.lisp` | `3b869030b495ae7a0532685f614670ca347bc392137bbf0687623862e402c4c2` |
| `spikes/out/pool-start/dispatch-coverage-reader.lisp` | `561ef6d1dbb9b17e8221d3085ebec6202940c033cbb94ae047c765a1b032939d` |
| `spikes/out/pool-start/reader-run.lisp` | `7de22c68baace90fad6e1e3037d597f703f7efa3d6e68b6d2da8e15144d15aef` |
| `spikes/out/pool-start/tool-run.lisp` | `83e717a03a89cc099e33092811f236462be151fbab773262883c33331e5b873b` |
