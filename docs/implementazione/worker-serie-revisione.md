# Revisione del collegamento worker–Serie

Due letture C1 del 2026-10-11 secondo la
[lista di controllo](../affidabilita/standard-di-codifica.md#lista-di-controllo-di-revisione-c1).
La prima ha esaminato contratto, sorgenti e fixture durante le correzioni;
la seconda ha riletto i sorgenti finali e confrontato test, copertura nativa,
HTML e misure del congelamento v3. Sono letture di agenti, non una
attestazione di revisione umana. Nessun sorgente è stato modificato durante
la seconda lettura.

La base iniziale era `2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`;
v3 incorpora `8101eb856cbe9d7540682babb53afb00fde30f70`.
La consegna integra poi `96c0f4f4d6d1f1882723da1b631e78f89e613059`,
che aggiunge il nucleo GET senza cambiare execution/Series: la
qualificazione dedicata bridge resta quella v3 su `8101eb8`, mentre
`make check` è previsto sul pacchetto integrato su `96c0f4f`.
La successiva [integrazione reader](worker-serie-integrazione.md) su `65972a4`
non cambia alcun sorgente di prodotto; i raw su `96c0f4f` restano il primo
controllo generale, seguito da una nuova verifica delle suite aggiunte.
Questa verifica passa su `65972a4`: [record finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/full-check-reader-integration.lisp)
`4000710249-command-34111-0`, `:OK/:STABLE`, exit0, 796 test nominati e due
smoke, tutti i gate e dieci spike. Il root inserisce questo esito dopo le
due letture; non modifica sorgenti, test del bridge o C4.
I quattro SHA-256 del worktree finale e della copia congelata sono uguali
a quelli dell'[inventario delle decisioni](worker-serie-decisioni.md):
`worker-package`, `worker-types`, `worker-boundary`, `worker-run`.
ASDF carica i quattro file dopo `series/retirement`; il namespace
`arcdocdb.execution.series` dipende da execution e Series senza invertire
le dipendenze di caricamento. Sono stati letti anche il test
`tests/series/worker-bridge.lisp`, il C4 `tools/worker-series-bench.lisp`,
il [contratto](worker-serie.md) e il [metodo](worker-serie-metodo.md).

Le quattro osservazioni sul prodotto sono chiuse sul sorgente v3 e hanno
regressioni passate. Dopo la consegna delle due letture, il root ha letto il
gate generale `make check`: `4000709286-command-15279-0`, **PASS**,
`:OK`, `:STABLE`, exit 0 sul congelamento integrato `96c0f4f`.
La diagnosi preliminare del runner dell'audit coverage è conservata;
il nuovo runner senza avvisi chiude il relativo gate, come descritto sotto.

## Le due letture sui dodici punti C1

| Punto | Prima lettura: contratto e sorgente | Seconda lettura: sorgente finale ed evidenza |
|---|---|---|
| 1. REQ e ADR coerenti | Intestazioni REQ-CON-001/002/004/005, REQ-AFF-001/004/008; ADR-0005/0033/0045. Il bridge compone due capacità preesistenti, conserva il writer logico e non crea uno scheduler. | Confermata la composizione: writer prima di Serie, nessun pop prima delle due lease, Serie rilasciata prima di end worker. L'unicità logica writer/Serie resta una precondizione del caller dichiarata nella factory e nel contratto. |
| 2. Invarianti e test sensibili alla violazione | Individuati owner, binding immutabile, generazioni positive e monotone, debito batch, ordine delle release, obbligo schedule unico, fault senza rollback. WS-REV-02 richiedeva un controllo della generazione locale positiva. | Le 26 fixture finali controllano FIFO/identità/sentinelle, quantum e token, busy delle due acquisizioni, closing/end busy, debito e ack stale, wrong-thread, limiti delle generazioni, bypass delle lease, quattro scenari del gate di fault e competizione con thread reali. Rifiuti e FI confrontano gli stati; non si limita la verifica al solo segnale. I rami ancora non eseguiti restano nell'audit completo. |
| 3. Tipo, gestione e test degli errori | Allowlist letterali per classe, ragione e passo; `resource-exhausted` atteso distinto da `invalid-argument`. WS-REV-01/03/04 hanno individuato cause sovrascritte o errori di un sottopasso erroneamente recuperabili. | Rilette le allowlist di tutte le cinque API e i due boundary nil/nil di acquire/release. Le tre classi iniettate nei sottopassi restano fatali e propagano la stessa condizione EQ. Un worker già faulted conserva la prima causa; il bridge registra quella corrente. Un fault lower non può rientrare nell'allowlist esterna. Le regressioni specifiche passano; non si attribuisce una prova esaustiva a tutti i guasti arbitrari dei verificatori privati. |
| 4. Cicli, attese e ricorsione limitati | Nei tre corpi nuovi non ci sono cicli, ricorsione, retry, thread, callback o attese. Le liste `member` sono letterali e limitate. Copia batch, pop e ricircolo restano nel worker già bounded. | Confermato sul sorgente finale. Closing richiede una chiamata esplicita a termina; non riacquisisce Serie. I semafori e le deadline di cinque secondi sono nel solo harness concorrente. Il benchmark esegue un numero fissato di iterazioni. Nessuna proprietà di fairness del pool è dedotta. |
| 5. Allocazione calda misurata | Binding, contesto, controller e target sono preallocati; il handler locale è `dynamic-extent`. La lettura statica da sola non chiudeva il punto. | Cinque campioni da 4096 cicli dopo warmup128 rilevano `[0,0,0,0,0]` byte heap, sink `8800256` in ciascuno. Il sensore rileva il controllo positivo da `16777472` byte e rifiuta un sink errato. È evidenza del percorso di successo seriale preallocato su questa build, con i limiti dichiarati sotto. |
| 6. Dati verificati all'uscita | Ftype e slot typed, owner prima delle letture; token, fase, lease catturate e binding controllati. Pre/post significativi includono controlli delegati a execution/Series; payload e debito non vengono duplicati dal bridge. | Lease esposta soltanto ACTIVE/token corrente; pop e ack passano i controlli del bridge e poi quelli del worker. Target/span/alias e batch stale sono rifiutati prima del pop o dell'ack. Il begin espone i tre valori dichiarati; macro valutata una volta e valori multipli verificati. Il caller deve applicare il batch prima di ack: il bridge non certifica effetti esterni. |
| 7. Decisioni composte inventariate | Inventario delle forme `case`/default, token/pre/post, boundary e allowlist; una sola nuova decisione composta nel fault marking: lease positiva, owner EQ corrente, generazione uguale. | Inventario finale: 32 controlli locali più il controllo owner delegato, sette istanze della macro e tutte le allowlist. Quattro fixture rendono falsa ciascuna delle tre condizioni con le altre vere, più tutte vere. Il corto circuito è esplicito; i valori della fixture non attestano automaticamente l'esecuzione di ogni operando. Non si inferisce MC/DC da sb-cover, né copertura totale dai test passati. |
| 8. Proprietari dello stato condiviso | Tre riferimenti immutabili e campi locali al thread del contesto. Owner del controller rilevato soltanto tramite la sua capacità. Coupling privato a execution/Series elencato, senza registri o contatori globali. | Wrong-thread è rifiutato prima del handler e non avvelena gli oggetti. Il fault marker scrive sulla Serie soltanto con le tre condizioni vere; dopo release o lease stale non modifica il controller successivo. Il controllo scalare evita check-ring che potrebbero sostituire la causa. Il coordinamento Archivio dopo l'handoff resta un obbligo del caller. |
| 9. Tracciabilità e `make check` | REQ e invarianti sono associati alle intestazioni del sorgente e ai nomi dei test; gli stati globali dei requisiti restano `progettato`. Nessuna promozione dell'intero modello di esecuzione. | Test mirati, suite Series e C4 hanno raw finali PASS. Il root ha completato `make check` sul congelamento integrato: 732 test nominati e due smoke, tracciabilità, link, conservazione/evidenze e dieci spike PASS; record `4000709286-command-15279-0`, `:OK/:STABLE`, exit0. L'inserimento documentale di questo esito e i nuovi cataloghi richiedono il successivo gate documenti/evidenze. |
| 10. Regole e deviazioni | Safety3, ftype completi per funzioni, slot typed, docstring pre/post, REQ e OWNER/SHARED. Boundary unico per la classificazione, nessuna syscall introdotta. Correzioni richieste prima della chiusura. | Sorgenti finali entro 60 righe per funzione; massima complessità locale inventariata 9, nessuna nuova deviazione individuata. Il C4 è compilato interamente e caricato da FASL con avvisi fatali; il caricamento ASDF applica solo l'eccezione runtime `sb-kernel:redefinition-warning` già prevista da `tools/build.lisp`. Non si estende quell'eccezione agli avvisi del runner dell'audit coverage. Lacune di copertura conservate, senza esclusioni approvate. |
| 11. Serializzazione e INV-P6 | Nessun lock, attesa o scrittura globale tra Serie per operazione. Sono seriali il singolo contesto worker, il suo writer e il controller posseduto nel tratto; scheduling/ready restano nelle API esistenti. | Due controller sono mantenuti ACTIVE contemporaneamente da thread reali prima delle release. Due writer contendenti su un controller hanno una sola lease ACTIVE, l'altro chiude senza pop. La correttezza di queste fixture non è una misura di throughput o scalabilità. Il benchmark ha un solo worker, una sola Serie e capacità1. |
| 12. Atomicità durevole e scarto | Il bridge cambia proprietà e diagnosi in memoria; non scrive record durevoli, non modifica WAL, ritiro o regole di riuso. Nessun nuovo punto di atomicità durevole. | Nessun rollback o cleanup automatico dopo un fault. Riferimenti e token restano per la diagnosi; un prefisso di batch non è ripetuto. La fixture di drenaggio FINE I/O su controller FAULTED applica e annulla l'evento prima di ack/end. Durabilità reale, recovery e coordinamento Archivio non sono qualificati da questo modulo. |

## Osservazioni sul prodotto chiuse

| ID / priorità | Difetto individuato | Correzione riletta e regressione finale |
|---|---|---|
| WS-REV-01 / P1 | La classificazione bridge poteva sostituire la prima causa terminale di un worker già faulted con l'invariante del successivo uso raw. | `%fault-worker-serie` non riclassifica un worker già FAULTED. `preserves-earlier-worker-fault-on-raw-begin` verifica EQ della prima causa worker e della diagnosi corrente bridge; PASS nei 26 test. |
| WS-REV-02 / P2 | Generazione locale zero in ACTIVE/CLOSING non era un'invariante verificata: il token veniva soltanto rifiutato come argomento, lasciando le capacità senza diagnosi terminale. | `%check-writer-worker-serie` verifica `plusp generation` prima delle capacità. `zero-active-generation-faults-only-owned-controller` copre ACTIVE e CLOSING, compresa Serie già ceduta; PASS. |
| WS-REV-03 / P1 | Un errore inatteso di acquire Serie con una ragione ammessa dal begin writer poteva essere considerato ordinario dal boundary esterno. | Boundary nil/nil dentro `%acquire-worker-serie`; soltanto il handler-case interno converte le due ragioni Serie previste. `acquire-boundary-unknown-reasons-never-remain-recoverable` inietta resource/invalid/io-fault, conserva la condizione EQ, writer lease e token, senza acquisire Serie o estrarre payload; PASS. |
| WS-REV-04 / P1 | Lo stesso mascheramento era possibile nella release Serie; inoltre un fault lower con ragione `:worker-serie-token` poteva coincidere con il rifiuto benigno del pop bridge. | Boundary nil/nil nella release; allowlist applicate soltanto se il worker non è già FAULTED. `release-boundary-unknown-reasons-retain-both-leases` copre tre classi e conserva entrambe le lease; `lower-worker-fault-cannot-match-benign-outer-token-reason` conserva lo stato terminale e la causa EQ; entrambe PASS. |

I nomi abbreviati della tabella hanno il prefisso
`test-REQ-AFF-008-worker-serie-` nel file di test finale.
WS-REV-01/02 derivano dalla prima revisione; WS-REV-03 dalla lettura
dell'autore; WS-REV-04 dalla rilettura del sottopasso release e del fault
lower. La seconda lettura ha verificato tutte e quattro le correzioni
nel codice congelato. Nessuna osservazione sul prodotto resta aperta.

## Gate locali e rapporti grezzi

Gli identificatori sono quelli di `tools/record-command.lisp`, non nomi
attribuiti a posteriori. Ogni esito sotto è stato letto nel proprio raw,
con `:STATUS :OK`, `:SOURCE-CONSISTENCY :STABLE` ed exit0. Le copie
pubblicate sono nel
[catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/catalogo.lisp);
i tentativi preliminari restano separati dai risultati v3.

| Gate | Record v3 / raw pubblicato | Esito e ambito |
|---|---|---|
| Test mirati | `4000708313-command-79577-0`; [target-final.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/target-final.lisp) | 26 test bridge PASS. Il driver verifica anche che il numero selezionato sia esattamente 26. |
| Suite e sb-cover Series | `4000708333-command-80909-0`; [coverage-process.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-process.lisp) e [bundle](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-bundle.lisp) | 70 test PASS, comprendenti 44 del controller e 26 nuovi; raw nativo e dodici pagine HTML conservati. |
| Audit nativo contro HTML | `4000708823-command-7776-0`; [coverage-audit-final.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-audit-final.lisp) e [processo finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/coverage-audit-final-process.lisp) | COMPILE-FILE, caricamento FASL, self-test reader e inventario di tutti i missing PASS con warning fatali; stderr vuoto. Conteggi uguali al precedente audit, conservato come probe. |
| C4 strictcompile e self-test FASL | `4000708361-command-83427-0`; [c4-final.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/c4-final.lisp) | COMPILE-FILE completo con warning/style-warning fatali; FASL self-test PASS, inclusi sensori, ciclo composto, CLI invalida, destinazione esistente e raw parziale. |
| Heap locale | `4000708391-command-85710-0`; [benchmark-data.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/benchmark-data.lisp) e [processo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/benchmark-process.lisp) | Cinque campioni completi, heap0 e sink atteso in ciascuno; controllo positivo e diagnosi sink errato funzionanti. |
| Controllo generale integrato | `4000709286-command-15279-0`; [full-check.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/full-check.lisp) e [master spike](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series-spikes-check/report.lisp) | **PASS**, `:OK/:STABLE`, exit0; 732 test nominati e due smoke, tutti i gate ordinari e dieci spike con esiti verificati nei singoli raw. Aggiornamento del root dopo le due letture, senza mutare codice/test/C4. |

Il probe dell'audit `4000708506-command-97108-0` conserva due
`STYLE-WARNING` del runner `-eval` per riferimenti anticipati a
`coverage-reader-main` e `coverage-reader-self-test`. Exit0 non li elimina
e quel comando non viene promosso a gate privo di avvisi. Il successivo
`4000708823-command-7776-0` usa eval distinti e `funcall/fdefinition` dopo
il caricamento: handler warning fatale su compile, FASL, self-test e main;
raw letto con stdout PASS, stderr vuoto, stato OK/STABLE ed exit0.
La sorgente reader02 è conservata in
[orchestration-final.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-series/orchestration-final.lisp).
Il wrapper del publisher conserva separatamente un avviso anticipato per
`compact-finished-directory`: riusa un helper preesistente di copia e
compattazione, non è il C4 nuovo di benchmark o il reader qualificato.
I suoi esiti di conservazione non sono presentati come compilazione C4
priva di avvisi.

## Copertura conservata senza esclusioni

I valori seguenti sono stati letti dall'indice HTML e coincidono con
l'audit del formato nativo. Il denominatore include tutti i dodici file
del modulo Series, anche package e quattro file late. Non si attribuisce
allo scope Series la copertura delle implementazioni execution delegate.

| File | Espressioni hit/totale | Rami hit/totale |
|---|---:|---:|
| events.lisp | 288/335 | 38/46 |
| io-events.lisp | 185/220 | 23/32 |
| ownership.lisp | 223/279 | 42/52 |
| package.lisp | 0/1 | 0/0 |
| publication.lisp | 156/203 | 16/22 |
| query.lisp | 65/79 | 5/6 |
| retirement.lisp | 166/182 | 14/18 |
| types.lisp | 75/84 | 4/10 |
| worker-boundary.lisp | 74/86 | 18/20 |
| worker-package.lisp | 0/1 | 0/0 |
| worker-run.lisp | 145/161 | 12/14 |
| worker-types.lisp | 124/168 | 19/30 |
| Tutto Series | **1501/1799** | **191/250** |
| Quattro file nuovi | **343/416** | **49/64** |

Restano **298 espressioni e 59 rami** non eseguiti in tutto Series;
nei quattro file nuovi restano **73 espressioni e 15 rami**.
L'audit conserva per ciascuno file, kind e path nativo: non sono esclusi
né aggregati in una sola nota generica. Nei nuovi file i rami mancanti
sono 2 in boundary, 2 in run e 11 in types, incluse forme generate e
controlli interni. La lettura del sorgente non li promuove a impossibili
e non sostituisce una loro esecuzione. L'inventario statico e i casi
manuali della decisione a tre condizioni completano la descrizione,
senza dichiarare MC/DC o copertura completa.

## Limiti della misura e del protocollo

La misura usa SBCL 2.6.9 ARM64/Darwin, safety3, un worker, una Serie,
capacità writer/ready/Serie1 e payload5. Ogni ciclo osserva enqueue,
adozione, begin, lease, pop, identità del payload, ack ed end idle;
la formula indipendente è `N*101+N*(N-1)/2`.
GC, predisposizione della fixture e stampa sono fuori dalla finestra.
Il timer a zero ha diagnosi distinta `:BELOW-RESOLUTION` e secondi NIL;
il sink errato resta un rifiuto anche con clockzero. Il carico esterno
è `:UNCONTROLLED`.

Heap0 è un dato locale del contatore, non una prova universale di
assenza di allocazioni. Le finestre non misurano busy, closing, fault,
contenzione, quantum maggiore di 1, pool parallelo, dispositivo reale,
durabilità o recovery. I test concorrenti verificano il protocollo in
fixture finite; non misurano scalabilità, throughput, P99 o fairness.
Nessuna soglia temporale è usata per qualificare il prodotto.

Il caller deve mantenere mapping logico unico, non rientranza e uso
esclusivo delle capacità del tratto. Deve elaborare il batch prima di
ack, chiudere CLOSING prima del ricircolo, distinguere generation Serie
esaurita da busy e non riprogrammarla indefinitamente. Dopo un fault
fuori dalla lease Serie corrente deve fermare/coordinare l'Archivio:
il bridge non può scrivere sul controller del nuovo owner. Il boundary
registra errori; non promette quiescenza, rollback o cleanup per uscite
non locali arbitrarie. Applicazione dei payload, routing, admission,
pool e coordinatore restano fuori dall'ambito qualificato.
