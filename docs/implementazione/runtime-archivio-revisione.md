# Due letture statiche del bootstrap runtime

Revisore indipendente Russell, agente `01a145a0-029b-7b80-af19-35be4a3efe9f`:
prima lettura dello schema, seconda delle minacce sul sorgente stabile e
sul [metodo](runtime-archivio.md). Lo stesso revisore ha scritto solo le
FI `tests/runtime/guards.lisp`; le due letture non sono due revisori.
Il coordinatore ha riletto separatamente implementazione e fixture.
Nessun run è attribuito alla revisione statica.

| Lista C1 | Prima lettura | Seconda lettura |
|---|---|---|
| 1. Requisiti/ADR | REQ, ADR-0046, registri esistenti | Unicità per oggetto canonico, esclusione fisica esterna |
| 2. Invarianti | Configurazione, piano, legami e base prima del CAS | FI distinte; efficacia da verificare |
| 3. Errori | Condizioni tipizzate, nessuna cattura generica | Perdente non restituito, vincitore mai annullato |
| 4. Limiti | Nessun ciclo/retry/attesa nel modulo | Un solo tentativo CAS, capacità delegate limitate |
| 5. Allocazioni | Solo costruzione, getter senza allocazioni esplicite | Candidate concorrenti e GC da misurare |
| 6. Dati verificati | Preflight prima degli array, due campi readonly | Getter: un caricamento, acquire, tipo; nessuna fonte trattenuta |
| 7. Decisioni | RTA-D01…D08 allineate | Copertura/MC/DC da dimostrare |
| 8. Ownership | OWNER/SHARED, slot opaco privato | Unico writer produttivo CAS, FI seriali ripristinate |
| 9. Tracciabilità | ASDF e metodo presenti | Matrice e controllo completo successivi, non dedotti dalla statica |
| 10. Standard | Safety 3, FTYPE, tipi e funzioni brevi | Slot `t` evita ciclo ASDF; getter lo controlla |
| 11. Parallelismo | Nessuna nuova coordinazione per operazione | Release prima CAS, acquire getter; dopo successo solo ritorno |
| 12. Durevolezza | Nessun formato o I/O | Pubblicazione volatile; H=M non autorizza traffico |

## Precisazioni recepite prima dei run

Il revisore ha chiesto di distinguere il mancato cambiamento del binding
da un binding ancora libero: un altro tentativo può averlo pubblicato.
La docstring ora dice che l'errore pre-CAS non pubblica candidati. Il
costruttore usa i lock dei registri esistenti, non un protocollo aggiuntivo;
la docstring esplicita propagazione degli invarianti e arresto del bootstrap.
Sono precisazioni del coordinatore, senza cambiamenti al protocollo letto.

Il ramo CAS perdente non è forzato dalla partenza comune dei worker. La
copertura osservata sarà distinta dalla garanzia di scheduling. Recupero
dopo interruzione esattamente successiva al CAS: argomento statico, prova
dinamica dedicata aperta. Nessun hook o sostituzione di primitive CL.

Il revisore non ha individuato difetti funzionali sotto le precondizioni;
restano compilazione, run/FI, copertura, MC/DC, misure e piattaforma di
riferimento da verificare separatamente. Canonicalità, validità temporale
del piano, ricostruzione delle capacità e gate del traffico sono obblighi
del controller. Un invariante impedisce di proseguire il bootstrap.

La revisione non conferisce qualifica C1 completa.
