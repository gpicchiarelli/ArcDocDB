# Metodo preregistrato C4: directory GET CLOSED

Il driver [get-directory-bench.lisp](../../tools/get-directory-bench.lisp) misura
due cicli GET corrente attraverso `arcdocdb.get.directory`. Questa consegna è
stata preparata mediante sole letture statiche e modifiche dei due file
assegnati: nessuna compilazione, caricamento Lisp, suite, benchmark, mutazione
o check è stato eseguito. Le esecuzioni e la registrazione dei risultati spettano
al padre dopo il congelamento dei sorgenti. `6eeb501` è l'antenato concordato;
l'integrazione main `644e53f` sarà registrata dal padre prima del freeze.
Non ci sono risultati prestazionali osservati in questo documento.

Il driver è autonomo per CLI, sensori, validazione, deadline e persistenza.
Carica `arcdocdb/tests` mediante `asdf:load-system`, senza invocare `test-op`,
e usa il supporto condiviso `tests/get-directory/support.lisp`. Se il supporto
non è già incluso dal sistema, lo carica esplicitamente. Entrambe le operazioni,
come eventuali compilazioni ASDF, avvengono fuori dalle finestre. **Questa
campagna carica il sistema dei test e non rivendica un processo prod-only.**

## Conteggi fissati prima delle esecuzioni

| Parametro | Preregistrazione |
|---|---|
| N: segmenti CLOSED / chiavi presenti | 1, 8, 32, 64 |
| V: byte per valore | 16, 256 |
| Formato | v2, PUT ordinario compaction, flags 0, prova NIL |
| CSN | `#xffffffffffffffff`, in tutti i profili |
| Chiavi | 16 byte; una chiave e un PUT per segmento |
| Casi | `:resolve`, `:cache-hit` |
| COUNT | 20.000 cicli per worker per finestra |
| WARMUP | 1.000 cicli per worker, prima di ogni finestra |
| Repliche | 5, ID 0..4 |
| Seriale | main, un contesto, nessun thread creato |
| Parallelo | nuovi thread per ogni finestra, 1/2/4 worker |
| Self-test | T=8, warmup=8, una replica, tutte le celle |
| Cache per fixture | una classe 1024 B, 256 insiemi, 8 posti/insieme, stripes=1 |
| Budget tempo | run 600 s; finestra 30 s; join di cleanup 2 s complessivi |

Sono 16 profili N × V × caso, 80 finestre seriali e 240 parallele: **12.800.000
cicli misurati**, con 640.000 cicli di warmup. `:resolve` include avvio e
abbandono; `:cache-hit` include risposta privata e conclusione. Il self-test
ha 64 finestre, 1.024 cicli misurati e 1.024 di warmup. Prima delle campagne
sono inoltre effettuati, per ciascuna campagna, 210 GET nativi per scaldare
tutte le chiavi delle otto fixture e 210 hit directory per verificarne la
permanenza dopo l'ultimo inserimento. `--self-test` costruisce otto fixture
in successione; `--bench` ne costruisce sedici, otto per il self-test e otto
nuove per il benchmark, per 420 GET nativi e 420 verifiche iniziali. Queste
operazioni sono fuori dalle finestre e non entrano nei conteggi della
campagna o del warmup per finestra.

L'ordine è fisso: N crescente, V crescente, seriale poi parallelo nel singolo
profilo N/V, resolve poi cache-hit, replica crescente, worker 1/2/4. La
campagna piccola completa precede quella benchmark. COUNT, WARMUP, repliche,
profili e dimensionamento cache non sono configurabili da CLI. Non ci sono
calibrazione adattiva, conteggi dedotti dal timer, retry o selezione delle
repliche riuscite. La validazione finale esige ciascuna cella esattamente una
volta e rifiuta duplicati o campagne parziali.

## Fixture e routing della cache

La firma consumata è `make-directory-fixture :count N :value-bytes V :workers 4
:version 2 :csn MAX-u64 :cache-p t`; la liberazione usa
`close-directory-fixture`. Il driver legge gli accessor concordati view,
directory, maps, keys, values, contexts, outputs, epochs e gli oracoli pubblici
ids, ends, images, files, cache. Non modifica il supporto, la directory o le
mappe e non crea celle pubbliche, CAS o thread di manutenzione.

Ogni fixture possiede un namespace temporaneo esclusivo, N FD readonly aperti,
una sola vista canonica, un registro EBR con quattro slot e quattro contesti
con scratch/output privati. Il supporto costruisce immagini e manifest con
encoding e CRC di riferimento; i PUT sono a offset 64. L'ultimo ID è
`#xffffffff`, gli altri `17 + 2*i`, strettamente crescenti. La frontiera
autorizzata è `104 + V`; gli undici byte invalidi successivi dimostrano che
END è un dato del manifest, non la dimensione del file. L'ACTIVE richiesto
dal formato del manifest è un ID esterno al dominio u32 CLOSED e non viene
inserito nella directory o interrogato dalla campagna.

È viva una sola fixture N/V alla volta: setup, warmup, finestre seriali e
parallele, join e chiusura precedono il profilo successivo. Il massimo è
64 FD readonly della fixture, oltre ai FD di processo/checkpoint; la
costruzione non trattiene i 210 FD di tutte le configurazioni. Una
campagna successiva ricostruisce i dati in nuovi namespace mantenendo
identici contenuti, oracoli, configurazione e conteggi.

La capacità cache è fissa anche per N=1. Il payload dichiarato dall'API deve
essere esattamente 2.156.816 B: `8 + 256*8*(1024+29) + 256 + 8`, esclusi header
Lisp e oggetti mutex. È vivo il payload cache di una sola fixture, 2.156.816 B;
oggetti delle fixture chiuse possono restare nello heap fino al GC. La
classe 1024 B contiene entrambi i record di 56/296 B;
dimensione della classe e partizione non cambiano tra i profili.

La lettura statica di `src/cache/core.lisp` stabilisce che il routing cache
usa high/low del segmento e offset, distinto dal digest XXH64 delle chiavi
nel primary. L'oracolo cold del driver riproduce il mix u32 e calcola
`mix(mix(0) xor mix(ID xor #x9e3779b9) xor mix(64 xor #x85ebca6b)) and 255`.
Prima delle misure confronta ogni risultato con `insieme-cache`, verifica
la configurazione reale e registra la massima occupazione per insieme;
nessun insieme può richiedere più di otto posti. Questo controllo è una
precondizione dell'esecuzione registrata, non un risultato già ottenuto.
Gli accessor interni cache e quello map→segment sono usati in sola lettura
per configurazione/oracoli fuori dalle finestre; il percorso GET usa API
pubbliche risolte prima del clock.

Il warmup iniziale usa `avvia-get` e `leggi-record-get` del nucleo con il
segmento/END noto della fixture per ogni chiave. Richiede i cinque ritorni
`:segment :miss :inserted NIL NIL`, oppure `:cache :hit :not-attempted NIL NIL`
se già caldo, copia, verifica il valore e conclude. Dopo aver scaldato tutte
le chiavi, un giro completo N via directory richiede hit su ciascuna. I
campioni cache successivi richiedono hit a ogni iterazione, anche nel
self-test e nel warmup. Un miss, eviction o scan inatteso causa FAILED;
nessuna lettura dal file rimpiazza una sonda fallita nella finestra.

## Operazioni e oracoli nel ciclo

Ogni ciclo installa il cleanup prima dell'avvio e chiama
`avvia-get(ctx, view, key[i], NIL, 0, 0)`. Richiede ritorno/stato CANDIDATE ed
EBR attivo. Copia le cinque word del candidato in un array u64 privato già
allocato; confronta CSN in due word u32 massime, ID, offset 64 e record-size
`40 + V`. Solo a questo punto legge la directory tramite l'accessor della
fixture, rappresentando l'acquisizione del controller sotto la stessa epoca.
Il riferimento fisico resta nel compito e non viene inoltrato tra pool.

1. **Resolve.** `trova-mappa-directory-get` deve restituire per EQ la mappa
   dell'oracolo fixture. `risolvi-candidato-directory-get` deve restituire il
   segmento della stessa mappa, END della fixture, flags 0 e prova NIL,
   lasciando il contesto CANDIDATE. Il resolver CLOSED ricontrolla CSN, size,
   owner e lifetime FD. Seguono abbandono e verifica IDLE/EBR libero;
   l'output deve conservare tutte le sentinelle. Questo ciclo comprende
   **due selezioni directory**: la selezione esplicita e quella interna
   all'API di risoluzione. Non autorizza o consegna un valore.
2. **Cache-hit.** `sonda-cache-directory-get` deve restituire `:hit`. Il driver
   copia con `copia-valore-get` nell'output privato da offset 3, richiede fine
   `3 + V`, poi `concludi-get(ctx, 1)` deve restituire `:found,V`. NOW=1 è il
   valore fresco del tempo logico della fixture, successivo al NOW=0
   d'avvio; il timer di misura è indipendente. Verifica tutti i V byte
   dell'oracolo e tutte le sei sentinelle, stato IDLE e annuncio EBR libero.
   Segue comunque cleanup idempotente. È una sola selezione directory.

I valori attesi, CSN, ID e END provengono dalle immagini/array indipendenti
creati dal supporto; il driver non deriva l'oracolo dai ritorni del resolver
che sta misurando. La corrispondenza immagine/valore viene controllata cold.
Contatori e checksum aumentano solo dopo i controlli e il cleanup. Per
resolve il contributo è `1 + END + ID + 2*#xffffffff + somma(valore atteso)`;
per cache-hit è `1 + somma(byte realmente copiati)`. Il checksum resolve è
un contatore di operazioni validate e usa metadati dell'oracolo: l'esito è
accettato per i confronti espliciti di ogni ciclo, non per una somma del
risultato. Il confronto integrale impedisce che una collisione della somma
accetti una risposta cache errata.

Il cursore parte da `worker-id mod N` e procede modulo N. La closure del
warmup è distinta da quella misurata, che riparte dal cursore prescritto.
COUNT=20.000 non è divisibile per N=64: l'oracolo del checksum calcola anche
il resto per ciascun worker, senza assumere un numero intero di giri. CSN
viene controllato high/low senza ritornare un u64 generico nel ciclo; le
somme calde stanno nel dominio fixnum SBCL64. Lo heap osservato può comunque
includere allocazioni del prodotto, dei thread e del driver.

## Finestre e sensori

Fixture, oracoli, contesti, output, buffer candidato, closure, raw, checksum
attesi, nomi thread e semafori sono allocati prima della finestra. Seguono
warmup e full GC. Il main legge `get-internal-real-time` e
`sb-ext:get-bytes-consed` prima/dopo l'intero gruppo: ordine tick-start,
heap-start, heap-end, tick-end. Il report conserva tick e unità originali,
secondi e qualità del tempo. Zero tick dà `:below-resolution`, secondi zero
e rate NIL. Il rate esiste soltanto per una finestra completa riuscita.

Il contatore heap riguarda l'intero processo, comprese allocazioni dei nuovi
thread; non si sommano contatori per worker. È memoria allocata cumulativa,
non heap vivo, RSS o riserva. GC automatici sono inclusi; full GC esplicito,
formattazione, costruzione dei record e checkpoint sono esclusi. L'ordine
dei due sensori produce un piccolo disallineamento ai bordi.

Nel seriale il main esegue il ciclo e il controllo finale di quiescenza.
Nel parallelo, compreso il caso a un worker, la finestra parte prima di
`make-thread` e include startup, ready/gate, cicli, join con deadline e
controllo di tutti i contesti coinvolti. Il main affida i contesti ai thread
soltanto dopo il warmup, li riacquisisce dopo join e non legge raw di thread
ancora vivi. Startup/join non vengono sottratti o stimati. I thread sono
nuovi a ogni finestra: questa misura non descrive un pool persistente.

Sono inclusi nei clock riempimento delle sentinelle, copia/verifica del
candidato, confronti degli enum, verifica integrale output, checksum,
osservazioni stato/EBR, cleanup del GET e contatori. Il controllo finale
del supporto verifica anche residui privati, sotto ownership del main dopo
join. Sono cicli completi con controlli di correttezza in finestra, non
stime del costo isolato della ricerca binaria.

Il sensore ha due finestre distinte: otto operazioni vuote e allocazione di
quattro array u8 da 1 MiB trattenuti. Ogni raw viene scritto prima del gate.
Il controllo positivo esige almeno 4.194.304 B osservati, completamento e
checksum corretti, array vivi della dimensione attesa e sentinelle ai bordi.
Il controllo vuoto registra il rumore e non esige heap zero. Nessun valore
del sensore viene sottratto dalle misure GET. I test diagnostici del driver
contengono REQ nel nome e rilevano `:completed` mancante, anche nel worker,
schema mancante, falso completamento parziale e rate NIL a zero tick.

## Deadline, errori e conservazione

Il run ha deadline assoluta di 600 s, comprende load, setup, sensori,
self-test e campagne. Ogni finestra ha un watchdog installato prima dei
sensori e usa la minore fra deadline run e 30 s locali. Ready, start e tutti
i join condividono questa stessa deadline; ogni attesa è bounded. Un
fallimento non cambia COUNT. Il cleanup termina solo thread propri e ha
un'unica deadline di 2 s complessivi per i quattro join; chiamate successive
non aggiungono tempo. Il cleanup di un gruppo fallito avviene dopo la
chiusura dei sensori e viene dichiarato fuori dalla finestra. I dati di
quel gruppo sono diagnostici, con rate NIL.

L'`unwind-protect` dei sensori conserva tick/heap anche su errore. Dopo
cleanup, il driver costruisce il record parziale, lo copia nel checkpoint
e lo persiste **prima della validazione**. Un worker vivo rende i suoi raw
non osservabili: completed/checksum NIL e stato FAILED esplicito; non viene
inventato un completamento. Un worker morto ha i contatori parziali reali,
anche se fallisce prima del primo ciclo. Non si chiude alcun FD sotto un
thread ancora vivo; in quel caso il run fallisce e la liberazione OS del
processo è l'ultimo confine. I record precedenti rimangono conservati.

Le condizioni del driver sono tipizzate (`bench-failure`, `bench-timeout`);
le diagnostiche sono limitate a 2.048 caratteri e riportano
`tools/get-directory-bench.lisp COD-61`. Gli errori del prodotto vengono
conservati nelle diagnostiche del worker/gruppo e causano exit 1. Non si
trasforma una location di segmento mancante in documento `:absent`.

Il run acquisisce una directory nuova 0700 con `mkdir` esclusivo; EEXIST
fallisce senza riuso. I prefix sono `get-directory-bench*` e
`get-directory-self-test*`, anche per la prova negativa. Le sole tre foglie
pubblicate sono `report.lisp`, `self-test-metrics.lisp`,
`self-test-sensor.lisp`; ciascuna è una plist plain UTF-8 minore di 1 MiB.
Ogni checkpoint usa un file temporaneo acquisito esclusivamente e rename
nella directory propria; rilegge una sola forma con READ-EVAL NIL e richiede
uguaglianza. Il limite live della directory di report, incluso lo staging
di una sola foglia, è 4 MiB. Non viene creato un file per replica.

Tutte le foglie dichiarano `:schema-version 1`, `:kind`, `:status`, `:source`
e `:limits`. Anche finestre, worker, metriche sensore, routing e riepiloghi
dichiarano schema 1/kind/status. Lo stato parte da RUNNING e termina OK o
FAILED. Self-test e sensore hanno checkpoint dedicati; il report mantiene
le campagne seriale/parallela distinte. `--negative-fixture` costruisce un
record **sintetico** con `:completed` deliberatamente assente, lo conserva
in `self-test-metrics.lisp`, poi richiede un rifiuto diagnosticato e exit 1.
Non carica il prodotto e non spaccia i suoi zero tick/heap per misure reali.

Le otto fixture di ciascuna campagna costruiscono in successione 210 file
per 52.710 B di immagini (`sum_N N * ((115+16)+(115+256))`). Il massimo
simultaneo è 64 file, 23.744 B, al profilo N=64/V=256; `--bench`, incluso
self-test, costruisce complessivamente 420 file per 105.420 B. I file sono
fuori dalla directory dei report, in root autonome del supporto, e vengono
rimossi dopo quiescenza di ciascun profilo. Payload directory massimo vivo
768 B e payload righe resolver massimo vivo 1.536 B sono distinti da
cache, FD, header Lisp, temporanei di costruzione e sensore trattenuto.
Il budget report esclude cache FASL e registrazione esterna del padre.

## Esecuzioni che il padre deve registrare

Il padre congela e registra argv, commit/base, working tree e blob sorgenti
prima e dopo ciascun comando. Il driver annota gli argv applicativi e la
responsabilità esterna del freeze; non certifica da solo la stabilità dei
sorgenti. Un'evidenza prestazionale accettabile richiede inoltre
`:source-consistency :stable` nel record esterno. I prefix e le tre foglie
devono essere inclusi dal collector. I seguenti comandi sono preregistrati
e **non sono stati eseguiti per questa consegna**:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-directory-bench.lisp --self-test spikes/out/get-directory-self-test-frozen/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-directory-bench.lisp --negative-fixture spikes/out/get-directory-self-test-negative-frozen/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-directory-bench.lisp --bench spikes/out/get-directory-bench-frozen/
```

La prova negativa deve conservare exit-code 1, stderr COD-61 e foglie FAILED;
un exit 0 sarebbe un difetto del rilevamento. `--bench` esegue prima sensore,
diagnostiche e tutte le celle piccole, poi la matrice di 320 finestre. Un
exit 0 richiede matrice completa, correttezza di ogni ciclo, quiescenza,
cleanup delle fixture e persistenza/rilettura riuscita del report finale.

La directory del prodotto supporta fino a 65.536 mappe, ricerca bounded a
17 passi, con al più due confronti numerici per pivot, e payload degli array
`12*N` B su SBCL64. Questi sono contratti
del prodotto, distinti dai profili prestazionali fino a N=64: il driver non
conta i passi o i confronti e non deduce il dominio massimo dai tempi. Pubblicazione,
reclaim EBR, ACTIVE, prepared, snapshot/storico, recovery, code e migrazione
fra pool sono fuori dal carico. CPU/frequenza, carico esterno, scheduler,
cache CPU e pressione di memoria non sono controllati. Non si ricavano P99,
durability, costi I/O sostenuti o throughput complessivo del database dal
rate di questi cicli validati.
