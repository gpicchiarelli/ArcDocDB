# CONTROL: metodo del benchmark nativo C4

> **Deciso (richiesta dell'autore, 2026-10-14)** — sidecar nel checkout
> condiviso `control-verifica`; scrittura limitata a questo metodo e a
> `tools/control-checkpoint-bench.lisp`. Compilazione, esecuzione, test, copertura
> e commit spettano al runtime centrale dopo il freeze dei sorgenti.

## Domanda e campione

Quanto costano insieme `prepara-checkpoint-control` e
`pubblica-control-recuperato` su file nativi locali, con uno, due o quattro
worker e Serie indipendenti? Il percorso misurato comprende il preflight e
la rilettura interna della preparazione, la rinomina verificata sul nome
`control.log` e gli fsync previsti dalle due API. ACTIVE e piano CONTROL
provengono dalle factory reali, costruiti prima del clock.

Il campione è fisso: versioni 1 e 2, worker 1/2/4, cinque repliche per
combinazione, trenta finestre. Ogni worker pubblica otto checkpoint distinti
per finestra: `2 × 5 × (1 + 2 + 4) × 8 = 560` pubblicazioni richieste.
Non ci sono warmup, adattamento del conteggio o soglie prestazionali.
L'ordine è versione, numero di worker, replica; le finestre sono seriali.

## Fixture e separazione

Ogni finestra crea una directory nuova; ogni worker ha una root privata
0700, con otto directory di caso 0700. Ogni caso possiede file, FD, scratch,
registri, vista GET, indice, ACTIVE, piano e risultato di preparazione propri.
L'identità Serie è diversa tra worker e finestre; gli otto casi dello stesso
worker sono istanze isolate della stessa storia logica iniziale, senza
condivisione di oggetti mutabili. Nessuna replica riusa fixture o gettoni.

Il setup usa `prepara-segmento-attivo`, `scrivi-valore-edit` e
`crea-checkpoint-control`, senza caricare `arcdocdb/tests` o `tests/control`.
Il vecchio ACTIVE 1 ha un header canonico durevole. Il precedente CONTROL
contiene un EDIT completo, ACTIVE 1, next-id 2 e SEAL valido: scritto in un
temporaneo esclusivo, sincronizzato, installato su `control.log`, parent
sincronizzato, riletto e ricostruito. Rimane aperto un FD readonly del vecchio
CONTROL durante lo swap.

Il nuovo ACTIVE 2 è header-only e durevole. Il nuovo EDIT completo dichiara
ACTIVE 2, next-id 3 e CLOSED 1 con valid-bytes 64 e zero esiti di chiusura;
non dichiara REMOVED. Il vecchio ACTIVE header-only viene quindi chiuso nel
manifest, con il suo intero prefisso durevole di 64 byte conservato. Questo
carico non esegue il reclaim.
`control.log.tmp` parte vuoto con FD append e readonly distinti della stessa
identità fisica. Il nuovo piano ha header CONTROL, EDIT completo e SEAL
costruiti e validati dal prodotto. `previous-control.bytes` e
`planned-control.bytes` conservano gli input canonici fuori clock.

Il benchmark usa `pubblica-control-recuperato`, l'ingresso generico presente
nel checkout. Il caller attesta l'autorità della fixture e la transizione
coerente con ADR-0040: ACTIVE 1 precedente, header e frontiera 64, CLOSED 1/64
senza esiti, nuovo ACTIVE 2, next-id 3 e nessuna rimozione. La chiamata generica
non viene presentata come prova autonoma di questa autorità. La futura API
`pubblica-control-validato` verrà integrata dal coordinatore dopo la consegna;
il sidecar non ne dipende e non modifica ASDF.

La CLI accetta soltanto `spikes/out/control-checkpoint-bench-X/`, con X di
1..64 caratteri ASCII alfanumerici, trattino o underscore. Nessun percorso
equivalente con `..`, slash aggiuntivi o prefissi diversi è accettato.
LSTAT controlla gli antenati dalla radice, senza seguire symlink; mkdir della
root è esclusiva, EEXIST fallisce. Le verifiche stat distinguono directory,
ACTIVE nuovo/vecchio e CONTROL nuovo/vecchio, senza alias di inode tra casi.
LSTAT non protegge da un soggetto esterno che cambia gli antenati tra
controllo e uso: il namespace deve restare riservato durante la campagna.

## Clock, heap e deadline

Sono esclusi caricamento/compilazione del prodotto, costruzione delle
fixture, preparazione ACTIVE, codifica del piano, scritture dei byte di
setup/evidenza, GC esplicito e oracoli finali. Un unico `sb-ext:gc :full t`
precede ogni finestra, nella stessa posizione per tutte le varianti.
Le scritture CONTROL eseguite da `prepara-checkpoint-control` sono incluse.

Il clock wall usa `get-internal-real-time`. Il caso a un worker esegue
direttamente le otto coppie di chiamate; nei casi paralleli il clock include
avvio dei thread, ready gate, start gate e join. Contatori e controlli
cooperativi sono inclusi. Non si tratta della misura isolata di una syscall.

`sb-ext:get-bytes-consed` misura i byte allocati dall'intero processo nella
finestra, compresi coordinamento e worker. Non misura heap vivo, RSS o la
memoria di un singolo worker. Nessun criterio zero heap, nessuna deduzione
di throughput DB, percentile o assenza universale di allocazioni.

Ogni finestra ha una deadline cooperativa di 60 secondi; la campagna ha
600 secondi, inclusi setup, caricamento, hash, oracoli e persistenza. Gate e
join hanno attese limitate dalla stessa deadline della finestra. Una syscall
bloccata non viene interrotta: il recorder centrale deve imporre un limite
esterno alla vita del processo. Non ci sono terminate-thread, timeout
asincroni, retry o rollback.

I timeout sono condizioni C4 `bench-deadline`, classificati `:incomplete`;
gli errori e gli oracoli falliti sono `:failed`. Si conservano attempted,
prepared e pubblicazioni effettivamente restituite, anche per prefissi
parziali. Le capacità si chiudono soltanto dopo quiescenza globale. Se un
worker resta vivo, nessun FD di fixture viene chiuso e nessun nuovo
checkpoint del report viene aperto: le risorse restano fino all'uscita OS.
Tutti i file rimangono nel namespace come evidenza, anche su fallimento.

## Oracoli fuori clock

Per ogni pubblicazione restituita, dopo quiescenza:

- `control.log` è un file regolare senza hardlink, con EOF e byte identici
  al piano; LSTAT prima e dopo la lettura attesta la stessa identità;
- header CONTROL verificato e recovery manifest ricostruito sui byte letti
  dal file installato: prefisso completo, versione attesa, ACTIVE 2,
  next-id 3, CLOSED 1 con valid-bytes 64 e zero esiti, nessun REMOVED;
- il nome installato punta all'inode del nuovo CONTROL, diverso da quello
  precedente; `control.log.tmp` è assente;
- il vecchio FD resta leggibile, byte uguali al precedente CONTROL e recovery
  ancora valido per ACTIVE 1;
- nuovo e precedente ACTIVE mantengono header, byte, versione, origine,
  identità e dimensione 64; directory identica e 0700;
- capacità aperte, modi, FD, inode, offset e frontiere confrontati con la
  baseline; solo il nuovo CONTROL avanza fino alla lunghezza esatta del piano;
- stato `:published` con rinomina osservata, risultato collegato allo stesso
  ACTIVE e log canonico aperto dello stesso writer.

Le verifiche sono native con stat/fstat indipendenti dalle API di identità
del prodotto. Il readback controlla anche l'identità e il modo 0700 della
root del worker; le root hanno inode indipendenti. La dimensione del parent
non viene trattata come una frontiera del log: la rinomina cambia le entry
della directory. Il vecchio inode CONTROL deve avere link count zero,
restando leggibile dai FD mantenuti aperti. Nessuna funzione globale viene sostituita per costruire un
oracolo o un guasto. La prova attesta le condizioni finali osservate; non
osserva tutti gli stati intermedi né dimostra resistenza a power loss.

## Report ed evidenza canonica

`report.lisp` è una plist di dati schema 1, leggibile con `*read-eval* nil`.
La radice conserva versioni, readers, repliche, count, seconds, heap-bytes,
windows, workers, results, limits e readback. Ogni finestra ha gli stessi
campi: versione/readers/replica, conteggi, durata, heap, record dei worker,
diagnostica, limiti e stato degli oracoli. Il record del worker conserva
prefisso attempted/prepared/count, terminazione, error-kind, results e
readback. Zero conteggi alla radice prima del carico significano progresso
ancora nullo; non sono una misura zero heap del prodotto.

Il report è scritto in temporaneo, rinominato e riletto come dati prima di
essere accettato. `report.sha256` identifica i byte del report canonico;
ogni risultato riuscito include SHA-256 del CONTROL installato. Gli hash
usano il lettore comune `tools/evidence-storage.lisp`, fuori clock. Gli
input sorgente hanno snapshot SHA-256 prima/dopo, con inventario conservativo
di tutto `src/*.lisp` ricorsivo, ASD, driver, metodo e helper dell'evidenza.
Il confronto non sorveglia continuamente le aperture dei sorgenti. Il
recorder esterno deve conservare revisione, stato Git, argv, ambiente,
stdout/stderr originali e actual exit del processo.
Il descriptor SHA viene rigenerato anche quando uno stato tardivo richiede
una nuova persistenza; il suo readback controlla i byte. Prima del
caricamento dell'helper SHA, un fallimento può lasciare soltanto il report e
l'output del recorder, senza hash finale. Un guasto di persistenza è
esplicito: stdout e actual exit restano necessari per leggere l'ultimo esito.

Il caricamento usa una cache FASL privata dentro il run e ASDF `:force t`;
nessun test-op. Warning e style-warning sono fatali; soltanto
`SB-KERNEL:REDEFINITION-WARNING` è catturato, registrato e muffled come
eccezione di caricamento. Dopo persistenza e stdout viene ricontrollata la
deadline: l'actual exit nonzero prevale su un testo emesso appena prima
dell'esaurimento del budget. Non si dichiara durability del report tramite
fsync; il readback attesta il contenuto disponibile nel filesystem locale.

## Comandi previsti dopo freeze

Dal checkout congelato, in processi distinti registrati dal runtime centrale:

```sh
sbcl --no-userinit --no-sysinit --script tools/control-checkpoint-bench.lisp --self-test
sbcl --no-userinit --no-sysinit --script tools/control-checkpoint-bench.lisp --bench spikes/out/control-checkpoint-bench-X/
```

Il self-test è un classificatore puro: esempi completi e parziali, cella
duplicata, worker duplicato, prefisso valido, conteggi oltre limite, timeout
tipizzati, errori worker, readback fallito, finestra e uscita tardive,
precedenza degli errori sui timeout, namespace letterale, alias inode e
serializzazione. Produce un solo record su stdout, senza prodotto, processi
figli, thread o fixture native. Non certifica compilazione o syscall del
prodotto e non viene eseguito nel processo benchmark.

## Dati aperti, limiti e consegna

Non sono state eseguite compilazione, prove, benchmark, copertura o commit
durante questa stesura. Non ci sono rate misurate o risultati prestazionali
da pubblicare. Restano da osservare warning del caricamento forzato, arità e
tipi delle factory nel checkout congelato, disponibilità del tool SHA e
durate effettive su macOS/Linux. L'integrazione ASDF/copertura del modulo
nuovo resta al coordinatore.
Il carico a quattro worker conserva fino a 288 FD di fixture simultanei,
oltre a quelli del runtime e del recorder: il limite del processo deve
permetterlo. Anche l'hash comune avvia processi figli fuori clock; il loro
eventuale blocco ricade nel limite esterno del recorder. Dopo una deadline
già dichiarata fallita, la finalizzazione può completare hash e persistenza
con controlli finali dell'actual exit; i 600 secondi non sono un limite duro.

I dati sono aperti: nessuna soglia inventata, nessuna imputazione per
finestre mancanti, nessuna promozione dei prefissi parziali a campagna
completa. I file nativi, le evidenze canoniche, la cache privata e i report
restano consultabili nel namespace esclusivo. Il filesystem locale e la
cache OS sono caldi; il carico esterno non è controllato. Otto casi per
worker non rappresentano una distribuzione di latenze o una storia di
rotazioni del motore. Catalogo, inventario CLOSED, decisioni multiserie,
adozione nel server, ammissione dei client e reclaim restano fuori dal carico.
