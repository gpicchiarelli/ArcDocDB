# Revisione indipendente del passo pool/Serie

Lettura statica del 2026-10-15, base
`5be241d8f295e3c82df06e75c9b12e0bf75eb202`, eseguita da un agente diverso
dall'autore. Esito: **positivo per lo scope C3 letto**, senza rilievi aperti
sul prodotto. Il revisore ha modificato soltanto questo documento e non ha
eseguito campagne: la lettura non attesta compilazione, test, copertura
o allocazioni.

Il quadro applicato comprende [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md) e lo
[standard di codifica](../affidabilita/standard-di-codifica.md).
Sono stati letti il [contratto](pool-step.md), il
[metodo preregistrato](pool-step-metodo.md), tutti i sette sorgenti dispatch,
l'ordine ASDF, le sedici nuove prove e il sensore C4. Le barriere delegate
rimangono distinte dalla nuova politica C3; questa lettura non sostituisce
la revisione o la qualificazione dei componenti C1.

## Identità dello scope

Il denominatore di qualificazione comprende tutti i sette file dispatch,
senza esclusioni manuali o limitazione alle righe nuove. Devono essere
pubblicati anche i conteggi per file e tutti i missing del nuovo ingresso.
I delegati C1 non entrano nel denominatore C3; nessuna copertura o
equivalenza MC/DC viene dedotta dai tipi o dal sorgente.

| Fonte letta | SHA-256 |
|---|---|
| `src/dispatch/package.lisp` | `98f56140a06f18597e125c13dfa9593f9594daf129bde17c26f75bf1f4252669` |
| `src/dispatch/types.lisp` | `cc44882c565a89de08f5add79333868ebfca4fc3f97bf9104d36375d014d4720` |
| `src/dispatch/build.lisp` | `c78d31a753db78baea520e9ea0cccf6e88cad9cca8bc75261a6ff26c2ac01fe5` |
| `src/dispatch/claim.lisp` | `224e4114b8b91affced874bea9c23cae5c79526e8ddae62e31a0cafcbb763682` |
| `src/dispatch/recycle.lisp` | `9fa3294cd28d1904cfb8db5153f93188b02f1bfbaf1800dad788731007c29ad0` |
| `src/dispatch/begin.lisp` | `4ae4bf8f6b7afe53af099a4b37ad75d253c05077f0cc7fbe39f4f1cab9f89a8d` |
| `src/dispatch/step.lisp` | `0d7653e6cbc0d93295f2ee1f84d142602af795933bf3147de9fc462c476212de` |
| `arcdocdb.asd` | `35df1308676510bde78858c31c756b3f976f8ee0aeb17d8e520d51f7f8506fd0` |
| `tests/scheduler/pool-step.lisp` | `d3e71761c6c27e3f90fb445eb1994e3c567812ea5e512acf10e36232ef26fc31` |
| `tools/measure-pool-step.lisp` | `91cc73d2d1550312c60b9ff5b3e74561ce38dbcd3960ff013613ff811b86862c` |
| `docs/implementazione/pool-step.md` | `d01df081f65cd39a2bbff0377bfc737a76e3e098aae4f99702d1575df3a5775c` |
| `docs/implementazione/pool-step-metodo.md` | `a4eca30aab6b238a4367cbacadee9a88e9b7c517315c29ead4a178ae25f232d2` |

Le fonti delegate determinanti per la scelta e il trasporto sono invariate:

| Fonte delegata | SHA-256 |
|---|---|
| `src/scheduler/pool-claim.lisp` | `e384f6091a5fcb506e718e12e77b06ab8dd4233a41024bc57ca3b14425e10b14` |
| `src/execution/worker-types.lisp` | `62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317` |
| `src/execution/worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |
| `src/execution/worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |
| `src/execution/ready-recycle.lisp` | `2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b` |
| `src/series/routing-select.lisp` | `796e3ace762dd6c3d86119981a37c1904a637e664551ca0f5289544f0806714a` |

Le impronte identificano i byte letti. La qualifica successiva deve
confrontarli con quelli congelati, senza dedurre un PASS dalla tabella.

## Scelta esclusiva e metadati

Il nuovo ingresso coordina la scelta fra tre operazioni preesistenti,
senza aggiungere stato mutabile per obblighi, lease o token. Verifica tipo
della porta, owner, tipo della tabella e identità EQ dei contesti prima di
leggere la fase con il getter pubblico execution. La chiusura del bridge
precedente e l'assenza di rientranza rimangono precondizioni del caller:
non viene introdotta una scansione di tutti i link o una prova di quiescenza.

IDLE delega la nuova presa governata e restituisce il suo link/status,
origine `:claim`, cursore e azione originali. CLAIMED delega soltanto il
collegamento dell'obbligo corrente: `:claimed/:current` descrive il writer
già posseduto, senza affermare una nuova presa. Dettaglio e azione sono NIL.
RESCHEDULE delega un solo ricircolo e restituisce origine `:recycle`, count
della partizione e azione NIL. Quest'ultimo NIL significa che il pool non
è stato consultato, senza inventare un'osservazione `:unchanged`.

Ogni ramo invoca un solo ingresso operativo e al più un trasferimento ready.
Room termina il passo IDLE senza cadere in una presa successiva; full
restituisce il link del nuovo CLAIMED, senza iniziarlo. Un passo successivo
può quindi scegliere current, mentre il caller avvia e chiude il bridge
esplicitamente. Ripetere current non produce avanzamento da solo.

Il passo non legge lifecycle negli obblighi CLAIMED/RESCHEDULE e non
revoca quelli già assunti. Il ritiro pending è applicabile soltanto in
un successivo passo IDLE. Scambi full perpetui non garantiscono il ritorno
a IDLE; EMPTY e BUSY rimangono osservazioni locali senza autorità su park
o arresto. Count e cursore non sono intercambiabili né snapshot globali.

## Rifiuti, barriere e compilatore

RUNNING, BATCH, FINISHING e FAULTED sono rifiutati prima di qualsiasi
ingresso operativo con `resource-exhausted :worker-state`. Il getter
controlla owner e legge la fase, senza verificare lease o debito: il nuovo
rifiuto C3 non sostituisce la prima causa o rivalida i campi di un contesto
attivo/terminale. Le forme delle fasi accettate vengono invece controllate
dai delegati originali, con i loro confini C1.

`%passo-dispatcher-fase` è NOTINLINE e accetta la fase come T. Le quattro
fasi note non ammesse sono distinte dal finale che segnala
`invariant-violation :pool-dispatcher-state`. Una FI oltre il ftype del
getter esercita così una difesa operativa, senza attribuirla al contratto
nominale C1 o promuovere il compilatore a runtime qualificato.

BUSY del claim è un ritorno con cursore; busy della guard nel ricircolo
rimane una condizione con RESCHEDULE e obbligo conservati. Non esistono
handler, conversioni in successo, retry, cleanup o rollback nuovi.
Un routing fallito dopo full conserva lo scambio già riuscito; dopo claim
con attivazione conserva l'ACK precedente. Riferimento, home e causa
restano nel contesto secondo le barriere originali. C3 non scrive fault,
campi writer, ring o controller e non applica ulteriori controlli ai
risultati dopo il trasferimento.

## Lista di controllo

I dodici punti C1 sono usati come controllo aggiuntivo nel singolo
passaggio C3 previsto da ADR-0031.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008 tracciati; scelta bounded fra compiti e trasporto per tratto coerenti con ADR-0045 §6/8. Il motore completo resta aperto. |
| 2. Invarianti | Binding prima della fase; un ingresso esclusivo; nessuna nuova ammissione con obbligo corrente; published termina il passo. Il precedente bridge chiuso è precondizione, senza nuova prova globale. |
| 3. Errori | Owner/binding e condizioni delegate mantengono ragioni e ordine; fasi note e inattese hanno rifiuti distinti. Nessun nuovo fault marking o sostituzione della causa C1. |
| 4. Limiti | Nessun ciclo, ricorsione, retry, callback o attesa nuovo. Selezione O(1), current/recycle O(1); soltanto claim può scansionare al più 64 shard. |
| 5. Allocazione | Nessuna struttura, lista, closure, hash o stato nuovo nel percorso caldo. Zero heap richiede misura separata e non deriva dalla lettura del wrapper. |
| 6. Risultati | Cinque valori con origine esplicita: cursor/count/NIL e lifecycle/NIL mantengono significati distinti. Nessun risultato di errore ignorato, nessun token o capacità nuova. |
| 7. Decisioni | Helper nuovo: 17 righe di defun, complessità 5; ingresso pubblico: 11 righe, complessità 1. Le altre funzioni restano nei limiti di 60 righe e 10 percorsi; nessuna nuova decisione composta C1. |
| 8. Proprietà | Dispatcher e contesto del solo thread creatore, riferimenti immutabili; nessuna duplicazione dello stato execution o nuova condivisione. Owner execution ricontrollato dal getter/delegati. |
| 9. Tracciabilità | REQ sulle due definizioni e sedici prove; export e ordine ASDF dopo gli ingressi originali corretti. Build strict, lint, trace e controllo completo sono attestazioni di processo separate. |
| 10. Standard | Safety 3, ftype, docstring, OWNER/SHARED e finale case typed; NOTINLINE conserva il dominio T al confine. Nessun handler generico, macro nuova, controllo C1 rimosso o deviazione individuata. |
| 11. Parallelismo | Nessun lock, contatore globale o scrittura condivisa per messaggio nuovo; accessi ready delegati per tratto. La scelta owner-only non dimostra overlap, equità o scalabilità. |
| 12. Durabilità | Nessun payload, CSN, file o protocollo durevole modificato dal nuovo codice. Nessuna nuova atomicità persistente o eliminazione da qualificare. |

## Lettura delle sedici prove

Le prove sono state lette senza eseguirle. I contatori di chiamata inoltrano
alle vere API selezionate; le sentinelle e le FI sono quiescenti e
ripristinate. L'owner distinto è una prova negativa, senza rivendicare
nuovo lavoro positivo concorrente o overlap da una barriera di partenza.

| Gruppo | Evidenza prevista dalle fixture e limite |
|---|---|
| IDLE attivo | Attivazione/ACK precedono la presa reale; cinque valori, home distinta dal cursore, link IDLE senza lease. EMPTY e vera guard busy verificano una sola chiamata e rotazione originale. |
| IDLE inattivo/ritiro | Lavoro reale nel ring, sentinella sulla scansione e cursore conservato; ritiro confermato prima della ready. Nessuna quiescenza globale dedotta. |
| CURRENT | Adozione con porta inattiva, parole corrotte o ritiro pending; immagini uguali, un lookup, metadati NIL e nessun gate/begin. Completamento e ACK restano espliciti. |
| Room | Capacity 2 e tre shard distinguono count 2 da cursor 0; un ricircolo, FIFO B poi A e ACK pending conservato. Solo il successivo passo IDLE conferma il ritiro. |
| Full | Scambio reale A→B e link B IDLE, poi passo current senza nuove mutazioni; vecchio A resta nel ring ed è concluso dal caller. |
| Ricircolo busy | Guardia CAS realmente detenuta, condizione originale e immagini complete uguali; distinto dal ritorno BUSY del claim, senza retry interno. |
| Fasi e priorità dei controlli | RUNNING/BATCH/FINISHING reali e FAULTED diagnostico rifiutati con zero ingressi; binding e owner estraneo precedono getter e operazioni. Prima causa EQ e capacità conservate. |
| Fault dopo trasferimento | Full con writer estraneo conserva il vecchio A nel ring e il nuovo riferimento/home in FAULTED; claim con attivazione conserva ACK e causa. Controller e lease rimangono intatti. |
| Confine getter e tipo | Sei valori fuori ftype rifiutati con invariant e zero ingressi, anche con causa FAULTED preesistente; FI del getter distinta dallo stato nominale. Dispatcher di tipo invalido ha una prova separata. |

## Sensore e limiti della qualifica

Il sensore letto prevede due campagne, ciascuna di cinque repliche con
una fixture nuova, 4096 cicli e 128 warmup. Ogni ciclo EMPTY esegue quattro
passi su quattro shard vuoti e controlla cursori 1/2/3/0. CURRENT-INACTIVE
mantiene un CLAIMED reale con porta inattiva e verifica quattro lookup,
cinque valori, identità, cursore 1 e link IDLE, senza nuove lease.

Factory, risoluzione API, claim iniziale, GC e cleanup restano fuori clock.
Il drain pubblico finale CURRENT consuma e conferma il payload e conclude
il writer IDLE; non viene presentato come arresto del motore. Il clock
include i delegati e gli oracoli scalari, senza misura isolata del wrapper.
INACTIVE IDLE è soltanto nei self-test; RECYCLE ha un oracolo sintetico del
sensore e prove prodotto, senza latenza misurata. Begin, CLOSING, payload,
contese e coordinatore concorrente non vengono misurati dalle campagne.

I self-test prevedono cinque ritorni difformi, heap deliberato, sink errato,
clock sotto risoluzione, CLI/destinazioni rifiutate e raw parziali conservati.
La lettura non ne attesta l'esecuzione. Sono necessari record separati per
copertura native/HTML, conteggi per file, gate C3, heap, repliche e copie
degli originali. Nessuna nuova garanzia su admission dei messaggi, sensori,
park/wake, avvio/arresto fisici, worker morti o coordinamento Archivio;
nessun requisito del motore completo è chiuso da questa revisione.
