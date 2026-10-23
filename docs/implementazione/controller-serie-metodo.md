# Metodo preregistrato: controller bounded di pubblicazione della Serie

Registrato il 2026-10-09, prima di eseguire prove o misure. Strumento C4:
`tools/series-controller-bench.lisp`; prodotto C1: `arcdocdb.series`.
Riferimenti: [ADR-0037](../adr/0037-lotto-sigillato.md),
[ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md),
[ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) e
[standard di codifica](../affidabilita/standard-di-codifica.md), COD-01,
COD-30, COD-40, COD-42, COD-60 e COD-61.

**Stato della preregistrazione: nessuna esecuzione.** Il parent autorizza
la campagna soltanto dopo il congelamento del worktree condiviso. Durante
le finestre non si svolgono compilazioni, altre prove, benchmark, raccolta
di metadata, stampa o formazione di rapporti. Il carico esterno della
macchina resta non controllato; non si dichiara un isolamento del sistema
operativo. La stabilità dei sorgenti è una condizione del successo.

## Copertura e mutazioni preregistrate

Il parent esegue le campagne di verifica in processi separati dalle misure,
solo dopo il congelamento. Il driver C4
[series-controller-mutation.lisp](../../tools/series-controller-mutation.lisp)
deriva dal sensore WAL/CSN: `*mutants*` contiene sorgente, sostituzione esatta
e test selezionato; `*test-names*` e `run-probes` dichiarano i quattro test
di `ARCDOCDB.SERIES.TESTS`. Le loro definizioni sono in
[tests/series/controller.lisp](../../tests/series/controller.lisp).
Sono preregistrate queste quattro ipotesi di rilevamento:

| Mutante | Sorgente e modifica | Test selezionato |
|---|---|---|
| `ignore-event-generation` | `src/series/events.lisp`: omette l'uguaglianza della generazione catturata con quella dell'evento. | `TEST-REQ-AFF-004-SERIES-FREE-AND-STALE-PREALLOCATED-EVENT-AFTER-WRAP` |
| `ignore-publication-fifo` | `src/series/events.lisp`: omette la guardia FIFO dei commit non risolti. | `TEST-REQ-WAL-006-SERIES-PUBLICATION-FIFO-UNRESOLVED-AND-RETURNED-H` |
| `retry-root-cas` | `src/series/publication.lisp`: ripete il CAS della root nella fase `:pubblicato` quando si ritenta dopo busy. | `TEST-REQ-MVC-008-SERIES-BUSY-AFTER-CAS-KEEPS-ROOT-ONCE-AND-CAPTURED-TOKEN` |
| `reuse-before-io-retirement` | `src/series/retirement.lisp`: omette la guardia consumer `:retired` prima del riuso. | `TEST-REQ-WAL-006-SERIES-ASYNC-SEPARATE-PUBLICATION-AND-RETIREMENT-CURSORS` |

Prima dei mutanti deve passare la baseline dei quattro test, nell'ordine
dichiarato dal driver, su una copia integra. Una baseline fallita rende
la campagna invalida e impedisce l'avvio dei mutanti. Ogni mutante usa una
copia completa di sorgenti/test, un processo nuovo e FASL isolati tramite
mapping ricorsivo dopo il caricamento dell'ASD. La sostituzione deve avere
un bersaglio unico; assenza o ambiguità rendono la prova invalida.

Un kill (`:detected`) richiede compilazione riuscita, fase `:tests`, exit 1
e `:failed-test` uguale al test selezionato per quel mutante. Compilazione
fallita, timeout (deadline del figlio 30 secondi), fallimento di un altro
test, rapporto illeggibile o guasto infrastrutturale sono `:invalid`.
Un test selezionato che passa è `:survived`: anche questo impedisce il
successo della campagna. Copie, argv, stdout/stderr, risultati grezzi,
fingerprint prima/dopo e diagnosi restano conservati. L'autoverifica C4,
la baseline e ogni esito mutante sono evidenze distinte; nessun kill è
ancora osservato.

Per la copertura si usa
[foundation-coverage.lisp](../../tools/foundation-coverage.lisp), con
autoverifica del sensore e scope esplicito `series`. Questo scope esegue
`ARCDOCDB.SERIES.TESTS:RUN` e filtra il rapporto sui sorgenti `src/series/`,
escludendo i test. Si conservano stato di copertura e rapporti grezzi per
file, con build rigoroso e cache privata, fuori dalle finestre benchmark.
Le decisioni e condizioni da verificare sono censite in
[controller-serie-decisioni.md](controller-serie-decisioni.md): copertura
strumentale dei rami e quattro mutanti mirati non garantiscono MC/DC,
né copertura completa delle condizioni o dei percorsi di interruzione.

Dopo l'export delle preflight WAL si raccolgono anche nuove osservazioni
del WAL esistente sul checkout integrato: suite `ARCDOCDB.WAL.TESTS:RUN`,
rapporto con scope `wal` e campagne C4 di
[wal-csn-bench.lisp](../../tools/wal-csn-bench.lisp), secondo il suo
[metodo](wal-csn-metodo.md). Si osservano il contesto di
`verifica-token-lotto`, `verifica-pubblicazione-lotto`, `verifica-riuso-lotto`
e `marca-log-faulted`, e il resolver preservato. Il rapporto `series` non
attribuisce copertura alle preflight in `src/wal/`: i dati WAL vanno
esaminati separatamente, esplicitando eventuali rami non esercitati.
Le evidenze WAL precedenti all'export non attestano il nuovo checkout.
Anche queste campagne restano preregistrate e ineseguite fino al congelamento.

## Contratto e ambito

Si osserva il controller bounded per una Serie, con registro CSN e log
segmento dedicati. La radice è un riferimento opaco immutabile: due simboli
preesistenti alternati, senza indice hash, snapshot o pool del motore.
Il controller adotta un lotto già `:sealed`, prima di avviare I/O.
La lease si acquisisce nel thread proprietario e copre l'intero tratto di
warmup o misura; rilascio e acquisizione restano fuori dal clock. Nel
parallelo nessuna lease acquisita nel main viene trasferita a un worker.

Il ciclo legge la radice corrente come expected-root e sceglie l'altro
simbolo come new-root. Include: PUT, `sigilla-lotto-con-csn`, cattura del token WAL,
`registra-commit-serie`, cattura dell'evento e della sua generazione,
costruzione/chiusura del gruppo, `inizia-io-commit-serie`, write e flush,
`completa-io-commit-serie`, `pubblica-commit-serie`, risoluzione del CSN,
`riusa-gruppo`, `riusa-commit-serie`. Il riuso del lotto è effettuato dal
controller; il sensore non lo richiama una seconda volta. Il livello
misurato è `:group`.

Il backend simulato esegue write/flush nello stesso thread proprietario.
La fine sincrona di `esegui-gruppo`, seguita da una barriera di memoria,
precede il completamento I/O del controller. Questo modello rende esplicito
l'ordine della fine del compito; non prova un handoff tra thread o un pool
reale. Il contatore locale deve passare `0 → 1 → 0`; il solo stato
`:written` non viene usato come completamento.

L'API aggiuntiva `ritira-io-commit-serie` riguarda il percorso di guasto
con dispatch mai accettato o ritirato definitivamente tramite handoff
sincronizzato: Serie faulted, gruppo già annullato e lotto ancora sealed.
Ritira l'obbligo I/O senza write/flush e conserva il token pendente;
non revoca autonomamente un compito né abilita il riuso del buffer.
Le sue guardie e il rifiuto sulla Serie sana appartengono alle prove del
parent e al rapporto di copertura `series`. Il ciclo sano misurato continua
a usare `completa-io-commit-serie` dopo write/flush.

Questo aggiornamento cambia i sorgenti del prodotto e le relative impronte.
Il driver benchmark include già ricorsivamente tutti i file `src/**/*.lisp`
nel confronto SHA-256 prima/dopo, quindi comprende anche l'API e il nuovo
export. Le impronte della campagna si raccoglieranno sul contenuto congelato;
nessuna impronta della fase di integrazione viene promossa a evidenza runtime.

Ogni errore o `:pendente` inatteso interrompe la finestra e l'invocazione,
senza retry, annullamento implicito o ricircolo di buffer guasti. Una
interruzione inattesa dopo assegnazione non è trattata come rollback.
Busy/full e reason effettive vengono conservati; `:pendente` restituito
dal controller è registrato esplicitamente come CSN busy normalizzato.
Le prove negative del prodotto (rifiuti, lease stale, FIFO, fault Serie/
Archivio, annullamenti quiescenti, pubblicato/busy senza doppio CAS, async
durante flush, esaurimento delle generazioni e interruzioni) restano
responsabilità del parent; il percorso sano del sensore non le sostituisce.

## Compilazione e fixture

Ogni invocazione esplicita, anche `--self-test`, carica l'ASD prima di
installare la traduzione ASDF ricorsiva `**/*.* → fasl/**/*.*` nella
directory esclusiva del run. Prima della compilazione si controllano le
destinazioni di tutti i sorgenti del prodotto, inclusi i moduli annidati.
Si forza il build del prodotto e si compila anche il sorgente C4 nella
cache privata, con warning e style-warning trattati come errori, safety 3.
Il FASL C4 è conservato come evidenza di compilazione, senza ricaricare
il driver né eseguire una seconda invocazione. La tabella delle funzioni viene risolta solo dopo il build;
un'esportazione assente rende il run fallito. Nessuna risoluzione di API
o costruzione di fixture entra nelle finestre.

Ogni fixture prealloca file/backend, log, registro da 256 slot, lotto da
512 byte con un solo record, gruppo da un lotto e controller con la
capacità default di 64 eventi. Chiave di 16 byte, valore di 64 byte,
file-id massimo u64 preboxed prima della misura. Si preallocano anche
descrittore del token, storico delle identità evento e delle generazioni,
contatori e record grezzi. Il sensore richiede un SBCL in cui ogni u32
sia rappresentabile come fixnum.

## Oracoli entro il clock

Ogni ciclo verifica il successore indipendente del CSN a due u32, il token
WAL pendente e identico al token dell'evento catturato, lo stamp nei byte
del PUT e del SEAL, evento `:preparato`, radice attesa, generazione positiva
uguale al successore della generazione globale precedente e strettamente
crescente per la stessa identità evento. Lo storico è una
scansione limitata a 64 elementi, senza allocazioni né interi u64 CSN.
Il controllo dei conteggi osserva adozione, dispatch, completamento,
risoluzione e ritiro, entro il clock e sotto la stessa lease.

Dopo write/flush devono coincidere end atteso, byte del backend e frontiere
scritta/durevole; lotto e gruppo devono essere durevoli, log sano. Dopo
pubblicazione la radice è l'altro simbolo, evento/token sono risolti,
`H = ultimo-CSN = CSN atteso`. Dopo rilascio del gruppo e ritiro il lotto
è aperto e vuoto, token/evento liberi, gruppo building, conteggi del
controller `(count, unresolved, active-io) = (0, 0, 0)` e radice ancora
pubblicata. Le osservazioni finali conservano anche conteggi write/flush,
byte, adozioni/pubblicazioni/ritiri e generazione/eventi osservati.

## Campagne seriali e parallele

Warmup di 1024 cicli su fixture separata, seguita da GC completo fuori
dalla misura. Fixture misurata nuova per ogni tentativo. Prima tutti i
seriali: cinque repliche con base CSN `(0, 0)`, poi cinque con base
`(#x80000000, #xfffffff0)`. La sedicesima iterazione della seconda base
attraversa il carry nella finestra misurata, senza ricostruire un u64.

Ogni campione parte da 20000 cicli, minimo 20 tick del timer. Solo una
finestra corretta ma sotto risoluzione consente il raddoppio. Al massimo
cinque tentativi: 20000, 40000, 80000, 160000, 320000; si conservano
tutti, senza scartare anomalie o scegliere la replica migliore.
Il gate seriale richiede esattamente zero byte heap sul successo, per
l'intera finestra con oracoli. Nessuna soglia di throughput.

Poi 1, 2 e 4 worker reali, tre repliche per numerosità, base alta con
carry. Ogni worker possiede un Archivio simulato indipendente: registro,
file, log, lotto, gruppo, controller e storico eventi. Le fixture vengono
scaldate separatamente; costruzione dei thread, ready gate e GC precedono
lo start. La deadline comune di lavoro/join è 30 secondi, e anche ogni
finestra seriale ha limite di 30 secondi, controllato ogni 256 iterazioni.
Le attese del ready gate sono limitate; il cleanup ha un budget comune
di 2 secondi. Campi di worker ancora vivi non vengono letti, i loro file
non vengono chiusi e il run fallisce. La terminazione di un worker non
asserisce il rilascio della sua lease né il rollback dei suoi token.

Le finestre parallele conservano i dati di ogni worker e un aggregato
temporale dal primo start all'ultimo end. Il contatore heap SBCL è globale
al processo: le osservazioni dei worker si sovrappongono, non si sommano
e non sono attribuite al singolo thread. L'heap del processo tra start
gate e join, incluso il coordinamento del runtime, è osservazionale.
Le repliche e i tentativi si susseguono senza altre attività del sensore
dentro una finestra.

## Autoverifica C4 e persistenza

Prima delle campagne si misura una finestra vuota: heap esattamente zero.
Il controllo positivo alloca 16 array da 1 MiB e mantiene tutti gli array
vivi attraverso la fine della lettura del contatore: almeno 16 MiB devono
essere rilevati. Questi controlli verificano il sensore, senza pretendere
20 tick o attribuire loro throughput del prodotto.

Il self-test dimostra che il validatore rifiuta heap nonzero quando
richiesto zero, tempo negativo o sotto la risoluzione richiesta e una
metrica mancante. Si controlla inoltre la conservazione delle metriche
modificate attraverso un alias della stessa plist, dopo salvataggio e
rilettura. Tutte le chiavi modificate esistono prima della condivisione.
Il rapporto finale è riletto con `*read-eval* nil`, confrontato integralmente
e validato nuovamente; la persistenza è un gate, non una nota diagnostica.

Rapporti schema 1: argv, SBCL/OS/CPU/memoria/numero di CPU, commit e stato
del checkout, SHA-256 dei sorgenti prima e dopo, mapping FASL verificato,
finestre grezze (tick e heap prima/dopo, sink, lavoro concluso), tutte le
repliche e i tentativi, oracoli finali, reason e diagnosi dei fallimenti.
Un cambio dei file o della loro lista impedisce il successo. Il rapporto
iniziale è scritto prima del build; un errore conserva il rapporto finale
e produce exit nonzero con nome dello strumento e regola.

## Chiusura della verifica sul congelamento

La chiusura (closure) è responsabilità del parent dopo aver dichiarato
congelato il contenuto integrato. Si correlano a quel contenuto i registri
strutturati di build/check, autoverifiche C4, suite di integrazione,
baseline e quattro mutanti preregistrati, copertura `series` e osservazioni
WAL, oltre alle campagne benchmark con tutti i tentativi conservati.
Il gate completo del repository è `make check`, con il registro previsto
dal Makefile; le campagne specifiche restano processi separati e non si
sovrappongono alle misure. Un fallimento o una prova invalida resta esplicito
e impedisce di dichiarare conclusa la relativa verifica.

La checklist e la chiusura dei riscontri C1 sono documentate in
[controller-serie-revisione.md](controller-serie-revisione.md), confrontando
le correzioni effettive e le prove pertinenti sul prodotto congelato,
incluso il ritiro I/O senza dispatch. Questo metodo registra gli obblighi
futuri: non chiude riscontri per conto del revisore, non attribuisce esiti
runtime e non garantisce MC/DC tramite mutazioni o copertura strumentale.

## Esecuzione futura e limiti delle conclusioni

Dal worktree congelato, directory nuova figlia diretta di `spikes/out/`:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/series-controller-bench.lisp \
  --self-test --output-dir spikes/out/series-self-test-UNIQUE/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script tools/series-controller-bench.lisp \
  --bench --output-dir spikes/out/series-bench-UNIQUE/
```

Le campagne aggiuntive si registrano con lo stesso wrapper, usando directory
nuove e processi distinti: driver delle mutazioni prima con `--self-test`,
poi con `--check spikes/out/series-mutations-UNIQUE/`; driver di copertura
prima con `--self-test spikes/out/series-coverage-self-test-UNIQUE/`, poi
con `--report spikes/out/series-coverage-UNIQUE/ series` e, separatamente,
`--report spikes/out/series-wal-coverage-UNIQUE/ wal`. Le osservazioni C4
WAL seguono i comandi preregistrati nel metodo WAL/CSN. Tutte precedono
o seguono le campagne benchmark senza sovrapporsi alle loro finestre.

Senza directory esplicita, il tool sceglie un nome esclusivo. Output:
`report.lisp`, `self-test-metrics.lisp`, `build.log`, cache privata `fasl/`;
il rapporto finale è emesso anche su stdout. Il registro esterno conserva
il comando completo, stdout/stderr e codice di uscita. `--bench` include
il self-test. Budget massimo: 10 campioni seriali e 9 repliche parallele,
ciascuno con cinque finestre; somma massima 620000 cicli per campione/worker.

Il backend non effettua I/O dati reale. Cicli/s e byte/s sono metriche del
percorso simulato con oracoli; non provano prestazioni NVMe, throughput del
database, latenza client, durability reale, recovery, snapshot o pool.
Il contatore heap non dimostra assenza assoluta di allocazioni.
