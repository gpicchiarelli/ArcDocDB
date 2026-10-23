# Revisione indipendente del dispatcher pool/Serie

Lettura statica del 2026-10-13, sulla base
`14fd7738c216e3a0bd3ce9612576b9b57d648f74`, eseguita da un agente diverso
dall'autore. Esito sul codice letto: **positivo per lo scope C3**. Il revisore
non ha modificato codice di prodotto o test. La lettura non è una revisione
umana e non attesta build, esecuzione dei test, copertura o allocazioni.

Il quadro applicato comprende
[ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md) e lo
[standard di codifica](../affidabilita/standard-di-codifica.md).
Sono stati letti il [contratto](pool-dispatch.md), il
[metodo preregistrato](pool-dispatch-metodo.md), i quattro sorgenti nuovi,
l'ordine ASDF, i quattordici test nuovi e le barriere preesistenti di claim,
routing, worker execution e bridge Serie.

## Identità del codice letto

| File | SHA-256 |
|---|---|
| `src/dispatch/package.lisp` | `acb5fd19599e89e821a89bcca8f94064f33cdc71cdfcf204aadcd4fb52dd795f` |
| `src/dispatch/types.lisp` | `cc44882c565a89de08f5add79333868ebfca4fc3f97bf9104d36375d014d4720` |
| `src/dispatch/build.lisp` | `c78d31a753db78baea520e9ea0cccf6e88cad9cca8bc75261a6ff26c2ac01fe5` |
| `src/dispatch/claim.lisp` | `224e4114b8b91affced874bea9c23cae5c79526e8ddae62e31a0cafcbb763682` |
| `arcdocdb.asd` | `0128c4955e2682cf22400c2995e0769072a57530c6d289aa258c8bac9a96cd4c` |
| `tests/scheduler/dispatch.lisp` | `600eb0b5fdf9a52d020e2f4c638f0f3dba43d9d9711be73eaffff208578821eb` |
| `docs/implementazione/pool-dispatch.md` | `1e8ae257234afd483f46d5ce3e9f13e904721981270741abe6576899c694e433` |
| `docs/implementazione/pool-dispatch-metodo.md` | `c00510ab85c22fe7c542d37a0efc6fd7094885d3ec48a5a9478ae00f07455bb4` |

Le barriere delegate sono state verificate su queste fonti, senza modificarle:

| Fonte | SHA-256 |
|---|---|
| `src/scheduler/pool-claim.lisp` | `e384f6091a5fcb506e718e12e77b06ab8dd4233a41024bc57ca3b14425e10b14` |
| `src/scheduler/lifecycle-worker.lisp` | `ec8b462ff3f5f7a6435f0f0c01b62034d8de2a784a9e354d469a0adfec9cf837` |
| `src/series/routing-select.lisp` | `796e3ace762dd6c3d86119981a37c1904a637e664551ca0f5289544f0806714a` |
| `src/series/worker-run.lisp` | `f448442c5f9233f492bb8642206ec4913f7b2f5f3c9a1fdf05896a439f1d429f` |
| `src/execution/worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |
| `src/execution/worker-types.lisp` | `62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317` |
| `src/execution/worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |

Le campagne successive devono indicare se usano gli stessi byte. Il documento
separa questa identità dalla qualificazione eseguita da altri strumenti.

## Confine e conservazione degli obblighi

Il dispatcher contiene soltanto due riferimenti tipizzati e read-only: porta
del pool e tabella locale di routing. La factory controlla tipo della porta,
owner della porta, tipo della tabella e identità EQ dei due contesti, in
quest'ordine. Verifica poi fase IDLE e forma C1 completa in sola lettura,
prima della propria allocazione. Non applica un comando o assume un obbligo.

Le due API calde ripetono i controlli di binding prima della delega. Il loro
helper non legge stato execution, parole request/ack, ring, lease o stato vivo
della Serie. L'owner execution viene nuovamente verificato dalle API delegate.
Non si usa l'uguaglianza delle ready come sostituto dell'identità del contesto.

`prendi-collegamento-pool` delega esattamente una nuova presa al gate
`prendi-writer-pool`. Solo `:claimed` seleziona il link preallocato sul contesto
associato; gli altri tre esiti conservano NIL, cursore e azione del gate.
Nessun begin, pop, token del bridge o seconda lease viene introdotto. Se il
routing fallisce dopo un claim reale, execution conserva il proprio confine
di fault, writer, home e obbligo. Un ACK già riuscito resta valido. Il nuovo
codice non cancella la diagnosi e non esegue rollback, cessione o pubblicazione.

`collega-obbligo-pool` ripete il binding e delega direttamente il routing di un
CLAIMED già posseduto. Non legge request, ack o active: busy all'inizio del
tratto, ricircolo full e adozione non dipendono da un nuovo consenso del pool.
Il lookup è ripetibile finché il link rimane IDLE. Dopo ricircolo full seleziona
il writer corrente, che può essere diverso da quello del tratto precedente.
Le fasi non CLAIMED e FAULTED mantengono i rifiuti e la prima causa delle API
C1 esistenti; non vengono adattate al dispatcher con cleanup impliciti.

Il caller continua a iniziare e completare il bridge, confermare i batch e
ricircolare gli obblighi attraverso le API esistenti. La richiesta di ritiro
non revoca un CLAIMED, non impedisce il drain e non garantisce il ritorno a
IDLE con ring perpetuamente pieno. Le API C1 dirette rimangono disponibili:
questa integrazione non rende impossibile un caller che aggira il gate.

## Lista di controllo

I dodici punti della lista C1 sono applicati come controllo aggiuntivo. La
lettura resta il singolo passaggio C3 previsto da ADR-0031, senza riclassificare
i delegati C1 né sostituire le loro revisioni e verifiche.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008 indicati sulle API; l'ammissione avviene tra compiti secondo ADR-0045. Il requisito del pool completo resta aperto. |
| 2. Invarianti | Owner prima della tabella, contesto identico prima del gate, IDLE C1 completo alla factory; link soltanto per un claim, routing degli obblighi senza lifecycle. Le quattordici fixture lette verificano identità e immagini complete su rifiuto; non viene attribuito alla lettura il loro risultato di esecuzione. |
| 3. Errori | Factory e binding hanno ragioni typed; fase e invarianti delegate senza occultamento. Non esiste handler o nuovo fault marking C3. Le incoerenze tra writer restituito ed esito hanno una ragione distinta `:pool-dispatcher-state`. |
| 4. Limiti | Nessun ciclo, ricorsione, attesa, callback, syscall o retry nuovo. Binding e routing O(1); il gate può delegare la scansione pronta bounded su al più 64 partizioni. |
| 5. Allocazione | Una struttura creata solo all'avvio; nessun costruttore, lista, closure o hash nel percorso caldo. L'assenza di heap deve essere misurata e non è dedotta dalla sintassi. |
| 6. Risultati | Esito, cursore e azione del gate inoltrati; writer sostituito dal link verificato solo dopo `:claimed`. Coerenza writer/NIL controllata e ramo inatteso esplicito; nessun valore che indica errore viene ignorato. |
| 7. Decisioni | Predicati semplici, nessuna nuova decisione composta. Complessità: helper binding 5, factory 2, claim 5, lookup di obbligo 1; nessuna funzione supera 60 righe o 10 percorsi. MC/DC non richiesto a C3. |
| 8. Proprietà | Dispatcher e tabella del thread creatore; porta/contesto e registro già posseduti secondo i loro contratti. Riferimenti read-only, nessun nuovo stato globale o protocollo di sincronizzazione. |
| 9. Tracciabilità | REQ su definizioni, package e nomi dei quattordici test; ASDF carica dispatch dopo series/routing e inserisce le fixture scheduler dopo pool-claim. Esecuzione di build, lint, trace e check completo resta distinta da questa lettura. |
| 10. Standard | Safety 3, ftype e slot tipizzati, docstring e OWNER/SHARED; case con otherwise typed, nessun ignore-errors, cleanup o rimozione di controlli. Nessuna deviazione individuata. |
| 11. Parallelismo | Nessun lock o contatore globale nuovo. ACK per ondata e ready partizionata restano delegati; il mapping è indicizzato e preallocato per worker. La lettura non dimostra equità o scalabilità. |
| 12. Durabilità | Nessuna scrittura su payload, controller, CSN o file; nessun cambiamento durevole o eliminazione. Atomicità persistente non applicabile. |

## Lettura delle prove nuove

Il revisore ha letto i quattordici test nominati nella versione identificata
sopra, senza eseguirli. Le prove distinguono esecuzione delle API reali,
contesa della vera guardia e FI deliberate del protocollo o della forma.

| Gruppo | Evidenza prevista dal codice e limite |
|---|---|
| Factory e binding | Tipi invalidi, contesti diversi, CLAIMED reale e IDLE incoerente FI; rifiuti confrontati con immagini di porta, contesto, ready, writer, link e controller. Factory non applica comandi. |
| Owner estraneo | Porta creata su worker reale distinto; owner viene rifiutato prima di tabella invalida, fase e parole corrotte FI. Le due API calde conservano le immagini. |
| Nessun routing senza claim | Sentinella quiescente ripristinata sul routing, INACTIVE con lavoro reale accodato, EMPTY e BUSY su guardia pronta realmente acquisita. Quattro valori e cursori confrontati con gli attesi. |
| Due writer reali | Ordinali distinti, link ancora IDLE e controller acquisibile dopo la selezione; begin, pop, ACK ed end espliciti attraverso il bridge. Nessuna acquisizione implicita attribuita al dispatcher. |
| Obbligo indipendente dal pool | Lookup ripetuto sul CLAIMED con parole lifecycle corrotte FI e sentinella sul gate; immagini uguali, poi completamento reale del tratto. |
| Ritiro dopo drain | Comando pending pubblicato in modo quiescente FI, rifiuto della nuova presa durante CLAIMED, termine reale e ACK del ritiro soltanto alla nuova presa IDLE. Non è un test della pubblicazione concorrente del coordinatore. |
| Ricircolo full | Ring pieno e trasferimento reali; nuovo CLAIMED seleziona il secondo link, entrambe le Serie restano indipendenti, ACK pending conservato. Il primo obbligo nel ring viene poi completato esplicitamente. |
| Begin writer-busy | Contesa FI sulla vera guardia con CAS/rilascio; begin reale conserva CLAIMED e link IDLE. Lookup ripetuto senza gate, retry begin esplicito, drain e ACK del ritiro dopo IDLE. Non è uno stress di contesa casuale. |
| Fasi e diagnosi | Tutte le fasi non-IDLE rifiutate dal gate prima di lease/debito incoerenti FI; lookup dell'obbligo rifiutato su stati coerenti ottenuti da begin/batch/end reali. Prima causa EQ conservata nella fase terminale. |
| Fault dopo attivazione | Writer legacy, identità estranea e ordinale fuori range: vera attivazione/ACK e claim precedono il fault routing. Writer/home e causa EQ conservati; nessuna mutazione di controller o acquisizione Serie. La pubblicazione request è FI quiescente. |
| Binding e link corrotti | Dispatcher FI con contesto diverso rifiutato prima dell'ACK pending 3/0 e del claim, anche durante l'obbligo corrente; slot link NIL provoca il fault C1 dopo claim conservando il riferimento e lasciando ready senza falsa ripubblicazione. |
| Output incoerenti | Ritorni del gate sostituiti temporaneamente, con combinazioni writer/status incoerenti ma valori nei tipi dichiarati; sentinella sul routing e immagini uguali. Queste prove non sono interleaving reali né autorizzano una nuova diagnosi sul contesto C1. |

La prima lettura delle fixture aveva individuato l'assenza di una prova
dedicata di begin writer-busy e di un binding incoerente con attivazione
pending. La versione finale introduce entrambe; il codice di prodotto è
rimasto identico. Le prove non simulano Serie-busy attraverso il nuovo
dispatcher: begin rimane esplicito e il suo contratto C1 resta quello del
bridge preesistente.

## Limite dei rami difensivi

Un delegate che rispetta il proprio ftype restituisce sempre uno dei quattro
esiti noti; `otherwise` non è un caso nominale. Le guardie writer/esito
proteggono una coerenza non espressa dalla sola dichiarazione dei valori
multipli: una FI può produrre NIL con `:claimed`, oppure un writer con un esito
senza claim, restando nei tipi dichiarati. Uno status estraneo viola invece
il contratto ftype del delegate.

Un'eventuale FI di sostituzione della funzione deve essere quiescente e
ripristinare l'originale. La campagna di copertura deve conservare il
denominatore nativo, dichiarare quali rami difensivi il compilatore mantiene e
distinguere queste prove da risultati nominali. La lettura non esclude rami
dal denominatore, non attesta la soglia C3 e non deduce un PASS dal fatto che
il ritorno inatteso sia impossibile per una funzione corretta.

## Limiti di qualificazione

L'integrazione non esegue i payload e non decide la gestione di un Archivio
FAULTED. Avvio e arresto fisici, park/wake, worker morti, sensori, admission dei
messaggi e dispatcher completo del server restano fuori dallo scope. I gate
di fase, il motore completo e REQ-THR-001 non sono chiusi da questa revisione.
