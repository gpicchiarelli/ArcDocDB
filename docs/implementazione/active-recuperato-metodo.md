# Metodo C4: recovery readonly del vecchio ACTIVE

Il driver `tools/recovery-active-bench.lisp` prepara un benchmark piccolo del
percorso pubblico `leggi-active-recuperato`, usando il backend in memoria di
`tests/recovery-active/support.lisp`. Misura aperture logiche/recovery con
allocazioni: ogni chiamata ricrea capacità del segmento, workspace, hash table
e array degli esiti. I byte e le decisioni della fixture sono già residenti.
Non è una misura del throughput DB, di I/O disco, di heap zero, P99 o una
conclusione sulla scalabilità. La qualifica resta COD-60; questo metodo non
attesta esecuzioni, compilazioni o risultati numerici.

## Invocazioni dopo il freeze del coordinatore

Dal checkout congelato, con SBCL senza init utente/sistema:

```sh
sbcl --noinform --disable-debugger --no-sysinit --no-userinit \
  --script tools/recovery-active-bench.lisp --self-test
sbcl --noinform --disable-debugger --no-sysinit --no-userinit \
  --script tools/recovery-active-bench.lisp --bench \
  --output spikes/out/active-verifica-bench-R1/
```

La directory finale deve essere nuova: `mkdir` esclusivo, nessun riuso o
sovrascrittura di un tentativo precedente. Sono ammessi suffissi di 1–64
lettere ASCII, cifre, trattini e underscore, con slash finale. Il main ricava
la radice dalla posizione del driver. Il coordinatore esegue il comando
attraverso `tools/record-command.lisp` per argv, ambiente, output, exit effettivo
e snapshot globali dei sorgenti; il capture wrapper esistente
`tools/get-series-capture.lisp`, con `--raw-root`, lega anche gli helper
esplicitamente invocati. Il driver non introduce un hash reader o un helper
evidence alternativo. Gli output sono sotto `spikes/out/`, escluso dallo snapshot dei sorgenti;
la stabilità va letta nel record del produttore concluso. Capture e recorder non forniscono un timeout di processo.

`--self-test` usa soltanto helper puri: parser CLI, matrice, aritmetica dei
conteggi, formulazione dell'oracolo, sink e classificazione con casi negativi.
Non carica ASDF, prodotto o supporto test; non crea file, fixture o worker e
non misura prestazioni. Il bootstrap riprende quello di
`tools/control-transition-bench.lisp`: un secondo LOAD sotto handler rende
fatali anche warning/style-warning nelle definizioni del driver. Il percorso
benchmark carica ASD e `arcdocdb/tests` una volta, senza `test-op` né `run`.
Le output translations ASDF sono private, sotto `<output>/fasl/`, ignorando
la configurazione ereditata. Nel solo caricamento ASDF, gli avvisi
`redefinition-warning` sono registrati con conteggio e fino a 16 messaggi,
poi muffled: compilare e caricare una macro nello stesso processo può
ridefinirla. Tutti gli altri warning restano fatali. La policy ha casi
negativi nei self-test; gli avvisi effettivi restano anche nello stderr.

## Caso fisso e oracolo

Si scelgono **24 record**, tutti in un lotto sigillato, anziché 32/36:

| Classe | Record | TXID distinti | Fonte dell'esito |
|---|---:|---:|---|
| PUT ordinary | 8 | — | stamp CSN 17, nessun prepared |
| PUT prepared locali | 4 | 4 | OUTCOME nel segmento |
| OUTCOME | 4 | gli stessi 4 locali | CSN esplicito |
| PUT prepared derivati | 4 | 4 | DECISION autorevole |
| PUT prepared presumed abort | 4 | 4 | assenza nella tabella completa della fixture |

Le PUT hanno chiave di 1 byte e valore di 1 byte; ogni cornice PUT occupa
26 byte, ogni OUTCOME 32. Il file è esattamente
`64 + 20×26 + 4×32 + 56 = 768` byte, sotto il limite 4096.
Header e SEAL sono esclusi dai 24 record. L'origine è writer, l'ID ACTIVE è
9, non ci sono coda, corruzione o short read. I formati v1 e v2 hanno lo
stesso caso logico e la stessa dimensione. Non si varia la dimensione dei dati.

Locali: TXID `0`, `1`, `#x8000000000000000`, `#xffffffffffffffff`.
Derivati: `2`, `3`, `#x8000000000000001`, `#xfffffffffffffffe`.
Abort: `4`, `5`, `#x8000000000000002`, `#xfffffffffffffffd`.
I quattro CSN, sia locali sia derivati, sono `0`, `7`,
`#x8000000000000000`, `#xffffffffffffffff`. Le decisioni contengono soltanto
i quattro derivati e nominano la Serie e un secondo partecipante: è la
tabella completa dell'Archivio sintetico dichiarato, non un'autorizzazione
generale a dedurre abort da una tabella parziale reale.

Ogni chiamata verifica con query pubbliche frontiere
`(768 768 :complete versione)` e statistiche `(1 24 12 4 4 4)`:
lotti, record, prepared, locali, derivati, abort. Esegue poi **13 query** di
chiusura: i quattro derivati presenti con CSN esatto; i quattro locali,
i quattro abort e TXID 42 assenti con `nil/0`. Presenza con CSN zero resta
distinta dall'assenza. Gli attesi provengono dai fatti dichiarati, mai dal
decoder o dal risultato del prodotto. Il token consuma frontiere,
statistiche e CSN restituiti; il sink atteso è `completed × token(versione)`.
Il confronto completo precede l'accumulo: il sink non sostituisce l'oracolo.

Il supporto controlla immutabilità dei byte, identità, FD ancora readonly e
aperti, assenza di scritture/flush/rename/close. Il driver verifica anche due
letture per recovery (header e corpo). Svuota il recorder eventi prima di
ogni chiamata, mantenendo il suo consumo bounded. Questi controlli e le
allocazioni dell'harness sono inclusi in tempo e heap della finestra.

## Matrice e confini della misura

La matrice ordinata è **v1/v2 × 1/2/4 worker × 3 repliche = 18 finestre**.
Ogni worker esegue esattamente **200 chiamate verificate**, compresa la prima
che precede il gate; sono 8400 recovery e 201600 record nella campagna
completa. Prima della misura, il main prepara una fixture distinta per
worker e vi esegue **8 warmup verificati**, esclusi dai contatori misurati.
Sono esclusi costruzione dei byte, CONTROL recuperato, ricostruzione della
tabella decisioni, fixture, warmup, caricamento ASDF e persistenza del report.

Ogni fixture possiede backend, sorgenti, CONTROL, decisioni immutabili,
scratch e capacità/FD. I numeri virtuali 301/302 ricorrono solo dentro backend
distinti: non designano un FD condiviso. Nessuna sostituzione globale di
funzioni. I worker condividono soltanto codice, gate e canale delle condizioni.

Anche la cella a un worker crea un thread. Il wall aggregato comincia prima
di avvio dei thread e gestione del gate, finisce dopo i join e include
controlli, scheduling e sincronizzazione. Usa `get-internal-real-time`;
il report conserva tick e `internal-time-units-per-second`, senza imporre
una risoluzione in nanosecondi. L'heap è la differenza di
`sb-ext:get-bytes-consed` sull'intero processo nella stessa finestra, non un
contatore per worker né memoria residente. Non viene raccolta CPU worker.
Non sono calcolati percentili, speedup o throughput DB.

READY è segnalato da ciascun worker **dopo il primo recovery verificato**;
il main attende tutti i READY prima di aprire GO per i restanti 199. È un
rendezvous bounded, senza sleep o prova di concorrenza dedotta dai tempi.
Non dimostra esecuzione parallela su core distinti. I contatori includono
soltanto i recovery che hanno completato l'intero oracolo; attempted può
superare completed di uno per worker in un tentativo fallito.

## Errori, quiescenza e report

Ogni finestra ha una deadline cooperativa di **5 secondi**, controllata a
ogni iterazione e sulle attese al gate; i join hanno un unico termine
comune di ulteriori **30 secondi**, non 30 per worker. Un'operazione già
iniziata non viene interrotta. Non si usa `terminate-thread`. Il coordinatore
deve supervisionare il processo esternamente se serve un limite assoluto,
anche per bootstrap, setup, warmup e salvataggio fuori finestra.

Un canale mutex comunica la prima condizione originale e il primo errore
non-deadline senza consultare RAW concorrenti. Un errore noto prevale su
`:incomplete`; timeout e join successivi non rimpiazzano la causa d'errore.
Solo dopo tutti i join e il controllo di quiescenza si leggono i contatori.
La chiusura delle fixture avviene tornando dai wrapper del supporto dopo
questa barriera. Se qualche worker resta vivo, il main salva soltanto dati
propri e condizioni comunicate, marca counts/sink `:unavailable` ed esce
con `sb-ext:exit :abort t`, senza svolgere gli unwind-protect delle fixture.
L'eventuale supervisore conserva stdout/stderr e l'exit effettivo. Una
finestra fallita interrompe la campagna: non si promuovono campioni parziali.

`report.lisp` è una PLIST leggibile, `:schema-version 1`,
`:kind :recovery-active-benchmark`, scritta inizialmente come incomplete,
dopo ogni finestra e in caso di errore gestito. Comprende parametri, limiti,
clock, scope heap, finestre, contatori per worker, counts aggregati,
sink, wall, heap, stato e causa/first-condition. Il file temporaneo viene
rinominato nella directory esclusiva. Exit 0 indica campagna completa,
1 errore, 2 incomplete. Errori prima dell'acquisizione dell'output, nel
bootstrap o nella persistenza richiedono l'evidenza del recorder esterno;
non possono garantire un report locale finale. Nessun report è prova del
freeze: il coordinatore lega helper e sorgenti tramite recorder/capture.

Questo C4 copre un singolo file sintetico piccolo e sano. Non copre code,
corruzioni, fault I/O, persistenza, pubblicazione del checkpoint, traffico
DB, cache disco, documenti realistici o crescita del dataset. I tre tentativi
per cella e il wall con harness non autorizzano conclusioni generali sulla
latenza o sulla scalabilità. Tutta l'esecuzione resta successiva al freeze.
