# Revisione indipendente dell'avvio pool/Serie

Lettura statica del 2026-10-14, base
`ad829a40f6ce72837b59982d2e4f83e8c9ca9f3e`, eseguita da un agente diverso
dall'autore. Esito: **positivo per lo scope C3 letto**, senza rilievi aperti
sul prodotto. Il revisore ha modificato soltanto questo documento e non ha
eseguito le campagne: la lettura non attesta compilazione, test, copertura
o allocazioni.

Il quadro applicato comprende [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md) e lo
[standard di codifica](../affidabilita/standard-di-codifica.md).
Sono stati letti il [contratto](pool-begin.md), il
[metodo preregistrato](pool-begin-metodo.md), tutti i sei sorgenti dispatch,
l'ordine ASDF, le quattordici nuove prove e il sensore C4. La lettura delle
barriere C1 di routing, worker e bridge completa quella del componente C3;
non ne sostituisce le revisioni o le verifiche di classe.

## Identità dello scope

Il denominatore di qualificazione comprende tutti i sei file dispatch,
senza esclusioni manuali e senza limitarsi alle righe nuove. I risultati
devono conservare anche i conteggi per file e i missing del nuovo ingresso.
Le sonde dei delegati C1 non entrano nel denominatore C3; nessuna copertura
o equivalenza MC/DC è dedotta dai tipi o dalla lettura.

| Fonte letta | SHA-256 |
|---|---|
| `src/dispatch/package.lisp` | `34ecf62cd625f8af0a884d713563338c88635afd88fd0eaa0ab8ba43d5f19486` |
| `src/dispatch/types.lisp` | `cc44882c565a89de08f5add79333868ebfca4fc3f97bf9104d36375d014d4720` |
| `src/dispatch/build.lisp` | `c78d31a753db78baea520e9ea0cccf6e88cad9cca8bc75261a6ff26c2ac01fe5` |
| `src/dispatch/claim.lisp` | `224e4114b8b91affced874bea9c23cae5c79526e8ddae62e31a0cafcbb763682` |
| `src/dispatch/recycle.lisp` | `9fa3294cd28d1904cfb8db5153f93188b02f1bfbaf1800dad788731007c29ad0` |
| `src/dispatch/begin.lisp` | `4ae4bf8f6b7afe53af099a4b37ad75d253c05077f0cc7fbe39f4f1cab9f89a8d` |
| `arcdocdb.asd` | `c9f2d60f0e73f1d951504da145b192584300a161cfd4df90984536fa9a34ec53` |
| `tests/scheduler/pool-begin.lisp` | `ecb295cc76e3308f6e12e7a28b0fb46d517043709bffdac565ef8cbfd866b044` |
| `tools/measure-pool-begin.lisp` | `f572b29c9566c9ab282ef804c8136367beb574c7b57bee4a570bae961cb5c732` |
| `docs/implementazione/pool-begin.md` | `c3ca973e76cea42038adc378fcedb61c7688d50228eaac38821c245b7ed60b5e` |
| `docs/implementazione/pool-begin-metodo.md` | `70308477c656e8fa44334e14aac68458f9345c38feb988be939e5d61c042b7ac` |

Le barriere delegate determinanti per il nuovo ingresso sono invariate:

| Fonte C1 | SHA-256 |
|---|---|
| `src/series/routing-select.lisp` | `796e3ace762dd6c3d86119981a37c1904a637e664551ca0f5289544f0806714a` |
| `src/series/worker-run.lisp` | `f448442c5f9233f492bb8642206ec4913f7b2f5f3c9a1fdf05896a439f1d429f` |
| `src/series/worker-boundary.lisp` | `793d401d1b9acc7b67923d815560f277f3d390ca050740f735f07d88dbacfe73` |
| `src/series/worker-types.lisp` | `a366799fd9b938bfaa48b0ffda228ff8369ab9acb5b5ead7f081dfc66ab2c81a` |
| `src/execution/worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |
| `src/execution/worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |

Queste impronte identificano i byte letti. I record delle campagne devono
verificarne l'identità con la copia congelata; la tabella non è un risultato
di esecuzione.

## Avvio e conservazione delle capacità

`inizia-obbligo-pool` non accetta un link dal caller. Verifica prima il
binding immutabile porta/tabella con gli stessi controlli degli altri
ingressi: tipo porta, owner, tipo tabella e identità EQ dei contesti.
Il successivo routing richiede il CLAIMED completo e seleziona il link IDLE
del writer attuale, tramite ordinale e identità. Dopo scambio full o
adozione non può quindi selezionare il link del tratto precedente.

Il codice chiama una sola `inizia-worker-serie` e inoltra link, token,
fase e ragione. Non introduce decisioni, controlli o handler dopo il begin:
nessun nuovo rifiuto C3 può separare una normale acquisizione riuscita
dalla consegna del token. I tre risultati del bridge mantengono il loro
contratto C1; il caller gestisce ACTIVE e CLOSING con le API esplicite.
Gli oracoli negativi del sensore verificano il sensore, senza attribuire
al prodotto una nuova validazione dei ritorni C1 fuori contratto.

Writer busy conserva CLAIMED e link IDLE senza consumare la generazione
del bridge. Serie busy ed esaurimento della lease Serie restituiscono
CLOSING con token corrente: il caller chiude esplicitamente, senza pop o
nuova acquisizione. Il limite del token bridge è distinto e viene rifiutato
prima della lease writer. Nessuna ragione permanente autorizza retry
indefiniti, reset delle generazioni o wrap.

Un routing invalido precede il begin. Gli errori successivi conservano
la stessa condizione e le capacità secondo le barriere C1, senza rollback
o nuovo fault marking C3. Un errore inatteso dopo l'acquisizione non
restituisce i quattro valori: contesto e link preallocato conservano la
diagnosi e gli eventuali riferimenti/lease per il coordinamento Archivio.
Il caller mantiene i link già ottenuti; dopo adozione può selezionarli prima
con `collega-obbligo-pool`. Non viene introdotta una chiusura del fault.

Il nuovo ingresso non legge request/ack/active e non chiama gate, claim o
ricircolo. Porta inattiva, ritiro pendente o parole pool incoerenti non
revocano l'obbligo esistente. Il ritiro resta applicabile soltanto dalla
presa esplicita sul contesto IDLE, dopo aver concluso tutti gli obblighi.

## Lista di controllo

I dodici punti C1 sono impiegati come controllo aggiuntivo nel singolo
passaggio C3 previsto da ADR-0031.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008 indicati; avvio di un compito per Serie senza thread dedicato o attesa, coerente con ADR-0045 §6/8. Il pool completo resta aperto. |
| 2. Invarianti | Binding prima di routing e acquisizione; CLAIMED corrente e link IDLE verificati dal C1; un solo begin, tutti i quattro risultati inoltrati. Le capacità non vengono duplicate né abbandonate da cleanup impliciti. |
| 3. Errori | Ragioni binding/owner riusate; fase, busy e generazioni delegate senza riclassificazione. La condizione originale attraversa C3 senza handler o sostituzione della prima causa. |
| 4. Limiti | Nessun ciclo, ricorsione, retry o attesa nuovo. Controlli EQ, routing e tentativo di doppia lease sono O(1); nessuna scansione ready, Serie o callback. |
| 5. Allocazione | Nessun costruttore, lista, closure, hash o nuovo stato sul percorso caldo. Zero heap richiede la misura separata e non deriva dalla sintassi del wrapper. |
| 6. Risultati | Token, fase e ragione vengono inoltrati integralmente con il link selezionato; CLOSING non perde il token. Nessun risultato di errore viene ignorato o trasformato in successo. |
| 7. Decisioni | Nuova funzione: 14 righe di defun, complessità 1. Binding 5, factory 2, claim 5, lookup 1 e ricircolo 5 con guardia 2 restano entro i limiti; nessuna nuova decisione composta C1. |
| 8. Proprietà | Dispatcher, contesto, tabella e link del thread creatore, non rientranti; riferimenti del dispatcher read-only. Nessuna struttura condivisa o variabile globale mutabile nuova. |
| 9. Tracciabilità | REQ su definizione e quattordici prove; export e caricamento ASDF dopo recycle e routing corretti. Build strict, lint, trace e regressione completa restano verifiche di processo separate. |
| 10. Standard | Safety 3, ftype, docstring, OWNER e SHARED espliciti. Nessun handler generico, ignore-errors, macro nuova, controllo C1 rimosso o deviazione individuata nel prodotto. |
| 11. Parallelismo | Si acquisiscono soltanto il writer e la propria Serie per tratto, senza lock o scrittura globale fra Serie per messaggio. La lettura non dimostra scalabilità o assenza di starvation. |
| 12. Durabilità | Il nuovo codice non modifica payload, CSN, file o protocolli durevoli. Le lease sono capacità in memoria; nessuna nuova atomicità persistente o eliminazione. |

## Lettura delle prove

Le quattordici nuove prove sono state lette senza eseguirle. I casi di
contesa usano le vere primitive; le FI sono quiescenti, dichiarate e
ripristinate, distinte dagli interleaving concorrenti.

| Gruppo | Evidenza prevista dalle fixture e limite |
|---|---|
| ACTIVE reale | Quattro valori, una chiamata al begin e doppia lease; payload ancora accodato, nessun pop/chiusura implicito. Il caller esegue pop, ACK ed end e dimostra il rilascio della Serie. |
| Full A→B | Scambio C1 reale, avvio di B, A nel ring e relativo link/controller intatti; A e B vengono poi conclusi esplicitamente. |
| Adozione e pool | Obbligo adottato con porta inattiva, parole corrotte o ritiro pendente; sentinelle su gate, ACK, claim, ricircolo, pop ed end. Ritiro confermato solo alla successiva presa IDLE. |
| Writer busy | Vera guardia occupata: immagini complete uguali, CLAIMED/link IDLE e generazione conservati; retry successivo del caller. Non è uno stress di contesa casuale. |
| Serie busy | Controller realmente posseduto, un solo tentativo, CLOSING/token senza pop; end non libera la lease altrui. Ricircolo e nuovo avvio avvengono soltanto dopo chiusura esplicita. |
| Generazioni | Limite lease Serie iniettato produce CLOSING/token; limite token bridge iniettato rifiuta prima delle acquisizioni. I reset ripristinano soltanto le FI della fixture. |
| Binding e owner | Contesti diversi e thread proprietario reale distinto rifiutati prima di routing/begin; immagini e sentinelle verificano l'ordine. Dispatcher di tipo invalido ha una prova distinta. |
| Fasi e causa | IDLE, RUNNING, BATCH, FINISHING e RESCHEDULE ottenuti da passi reali; FAULTED diagnostico iniettato separatamente. Capacità, debito e prima causa EQ conservati. |
| Routing e not-ready | Writer estraneo rifiutato prima del begin; bypass pubblico deliberato rende un altro writer not-ready e prova la propagazione EQ nei fault C1. Il bypass non è un uso nominale consentito. |
| Errore dopo lease writer | FI nel secondo acquire, prima di acquisire la Serie: errore originale, writer lease e riferimento conservati, bridge/worker FAULTED e controller intatti. Cleanup C4 della lease reale non ripristina i contesti né qualifica una recovery del prodotto. |

## Sensore e limiti della qualifica

Il sensore letto prevede una sola campagna ACTIVE e cinque repliche,
ciascuna con una fixture nuova, 4096 cicli e 128 warmup. Un vero payload simbolico resta
accodato: il clock non include pop, ACK o applicazione di payload. Ogni
ciclo comprende il nuovo avvio con oracolo dei quattro valori e doppia
lease, end del bridge, ricircolo room C1 e presa C1 esplicita. Token atteso
monotono, identità e stati sono controllati senza reset privati.

Factory, lookup API, GC e drain finale rimangono fuori clock. Il drain
pubblico consuma e conferma l'unico payload e conclude IDLE prima della
chiusura del backend. Non si misura il costo isolato del wrapper, CLOSING,
busy, un coordinatore concorrente o il throughput del motore.

I self-test prevedono quattro risultati difformi, un oracolo CLOSING con
token, heap positivo deliberato, sink errato, clock sotto risoluzione,
CLI/destinazioni rifiutate e raw parziali conservati. La lettura di questi
controlli non ne attesta l'esecuzione. Servono record separati per gate C3,
confronto native/HTML, conteggi per file, heap, repliche e originali.
Non sono qualificati applicazione dei payload, admission, sensori reali,
park/wake, worker morti, avvio/arresto fisici o coordinamento Archivio;
nessun requisito del motore completo viene chiuso da questa revisione.
