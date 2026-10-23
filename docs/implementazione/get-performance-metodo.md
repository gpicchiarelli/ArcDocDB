# Metodo preregistrato del benchmark GET corrente

Implementazione complementare alla suite funzionale GET, con package autonomo
`arcdocdb.get-performance.bench` e fixture costruita soltanto dalle API del
sistema `arcdocdb`. Non carica `arcdocdb/tests` e non dipende dalla suite
`tests/get-performance`. Tool: [get-performance-bench.lisp](../../tools/get-performance-bench.lisp).
Questo documento e il tool sono consegnati al padre senza eseguire test,
compilazione o benchmark. Ogni risultato richiede esecuzione registrata dopo
freeze; qui non sono riportate prestazioni osservate.

## Preregistrazione, prima delle misure

| Parametro | Valore fisso |
|---|---|
| COUNT | 20.000 GET per worker per finestra |
| Warmup | 1.000 GET per worker, prima di ogni finestra |
| Repliche | 5, identificate da 0 a 4 |
| Chiavi | 16 byte; 8 presenti e 8 assenti |
| Valori | 16, 256, 4096 byte |
| CSN | 7 e `#xffffffffffffffff`, in tutti i casi |
| Seriale | main, 1 contesto, senza creazione di thread |
| Parallelo | thread distinti, 1/2/4 worker |
| Seme XXH64 | high `#x01234567`, low `#x89abcdef` |
| Segmento | v2, ID 17, origine compaction, PUT non prepared, flag 0 |
| Indice | capacità 16, arena 128 B, profondità 0 |
| Cache | 1 insieme, 8 posti; classe 1024 B oppure 8192 B |

Nessun argomento CLI cambia COUNT. Non ci sono calibrazione automatica,
conteggi maggiorati dopo il timing, retry del GET o selezione delle repliche.
Il CSN massimo attraversa il percorso corrente tramite lo slot specializzato
u64 e il verificatore che riceve high/low u32: il driver non legge il CSN in
un oggetto generico dentro il ciclo. Le sue allocazioni cold non appartengono
alle finestre. Le osservazioni dello heap restano globali, senza attribuire
eventuali byte al boxing o a una specifica componente.

La matrice contiene 18 celle (3 dimensioni × 2 CSN × 3 casi), 90 finestre
seriali e 270 finestre con thread. Sono 14.400.000 GET misurati e 720.000 GET
di warmup, con carico per worker identico tra seriale e parallelo. Il report
unico mantiene `:serial` e `:parallel` distinti e verifica la matrice esatta,
compresi conteggi, configurazioni mancanti e duplicati. Le 72 finestre bounded
del self-test usano 8 GET per worker e 8 di warmup: sono autoverifica del tool,
non risultati prestazionali né un COUNT alternativo. Ogni finestra self-test
viene persistita prima della validazione: anche un fallimento conserva le
metriche parziali e una diagnostica con stato `:failed`.

## Percorsi inclusi

1. **Cache hit**: `avvia-get` corrente, ingresso EBR, XXH64 della chiave,
   lookup indice, resolver sintetico, `sonda-cache-get`, copia cache nello
   scratch con seqlock e verifica CRC32C/chiave/CSN/flag,
   `copia-valore-get` verso output privato, `concludi-get` con tempo fresco,
   rilascio EBR e cleanup esterno. Ogni sonda deve essere `:hit`: un miss
   invalida la finestra e non diventa una lettura dal segmento.
2. **Segmento, cache disattivata**: stessi avvio/EBR/XXH64/indice;
   `sonda-cache-get` deve essere `:disabled`, poi `leggi-record-get` deve
   restituire fonte `:segment`, cache `:disabled`, inserimento
   `:not-attempted`, nessuna espulsione/scan. Include `pread` nativo esatto,
   verifica completa del PUT, copia privata e conclusione.
3. **Absent corrente**: avvio, EBR, XXH64, lookup assente confermato e
   conclusione `:absent` con zero byte. Non esegue sonda cache, CRC o I/O;
   tutti i byte dell'output devono conservare la sentinella.

Sono chiamate reali al modulo GET corrente. Il resolver della fixture associa
un segmento già verificato e una frontiera immutabile calcolata in costruzione;
non misura ricerca nel manifest, code, inoltro al writer, migrazione tra pool,
rete o serializzazione della risposta. Non esegue snapshot, storico, prepared
o recovery. La frontiera non viene dedotta da stat/file size. Le viste cache
e segmento condividono indice, ambito e FD; ciascuna capacità segmento è
associata alla sua vista, come richiede il contratto GET.

## Fixture, ownership e verifica nel ciclo

Sei fixture (dimensione × CSN) sono costruite e mantenute vive prima delle
finestre. La costruzione scrive header e otto PUT in file `.tmp` esclusivi,
pubblica gli otto slot e popola tutti gli otto posti cache, verificando i
ritorni. Il file viene chiuso in append e riaperto readonly; l'header viene
letto e verificato sullo stesso FD usato dai GET. Non viene chiamato un flush:
la fixture rappresenta dati committed per contratto locale e non dimostra
pubblicazione o durata di un commit reale.

Entrambe le aperture usano `max-transfer = max(64, record-size)`: il record
del valore da 16 B occupa 56 B, ma append e lettura dell'header richiedono
64 B. Il limite del file resta la frontiera calcolata `64 + 8 × record-size`;
la correzione non aggiunge byte alle fixture o alle finestre GET.

Ogni fixture ha una sola scope canonica, un registro EBR da quattro worker e
un registro snapshot vuoto. I quattro contesti GET, con worker-id 0/1/2/3,
hanno scratch, output e annuncio EBR distinti. Indice, chiavi, valori attesi,
frontiera e capacità readonly sono stabili; gli hit scrivono soltanto i byte
di calore/rilettura consentiti dalla cache. Non ci sono writer concorrenti,
inserimenti nella finestra, cambi epoca/root o eviction. I worker partono da
ordini diversi e ciclando visitano tutte le otto chiavi, sullo stesso insieme
cache. I contesti vengono riusati solo dopo join e quiescenza.

Il warmup viene eseguito dal main, con ownership esclusiva di ciascun contesto,
prima che venga affidato al thread. Scalda lo stesso percorso e la pagecache,
ma non scalda il runtime del nuovo thread. Non si svuota la pagecache: il caso
segmento misura letture di un piccolo insieme già letto, senza attestare che
ogni syscall eviti I/O fisico in presenza di pressione esterna della memoria.

Ogni iterazione riempie l'output con sentinelle, esige gli esiti e le dimensioni
corretti, copia solo per un hit, conclude con un nuovo tempo e controlla stato
IDLE, annuncio EBR libero e due guardie dell'output. Verifica tutti i byte,
non soltanto l'ultimo risultato della replica. Un `unwind-protect` abbandona
il GET anche su errore. Completamento e checksum vengono incrementati soltanto
dopo questi controlli e il cleanup. Per un found il contributo è `1 + somma
dei byte`; per absent è `2 + 215 × dimensione`. L'oracolo è calcolato dai
valori generati cold; COUNT e warmup sono divisibili per otto, quindi ogni
worker deve ottenere lo stesso checksum previsto. La verifica byte per byte
impedisce che una collisione della somma accetti un valore sbagliato.

Tempo e heap includono anche sentinelle, oracolo byte per byte, checksum,
clock fresco per ciascun GET, osservazioni EBR/stato, cleanup e contatori del
driver. Queste misure descrivono quel ciclo completo, con il suo costo di
controllo; non sono il costo isolato delle primitive.

## Finestre, contatori e ambiente

Il tempo usa `get-internal-real-time`, base monotona SBCL nelle unità registrate
nel report, e non il calendario. Il tool registra tick originali, secondi,
qualità del tempo e operazioni completate al secondo. Zero tick resta
`:below-resolution`, secondi zero e rate NIL; non inventa un rate. Il calendario
è usato soltanto per metadata e nomi dei run.

`sb-ext:get-bytes-consed` viene letto una volta prima e una volta dopo la
finestra sul main. È un contatore dell'intero processo, comprese allocazioni
dei worker e attività del runtime; non rappresenta heap vivo, RSS o memoria
riservata. Non vengono lette o sommate misure heap dei singoli thread. Timer
e contatore heap hanno un piccolo disallineamento dovuto all'ordine delle
letture: tick-start, heap-start, heap-end, tick-end. La costruzione dei record,
formattazione, persistenza e GC esplicito sono fuori dalle finestre. Il GC
automatico durante una finestra è incluso.

Il main esegue un GC completo prima di ciascuna finestra; fixture, closure,
nomi thread, raw, semafori e output sono già allocati. Nel **seriale** il main
esegue soltanto il ciclo e il confine diagnostico. Nel **parallelo**, incluso
il caso a un worker, tempo e heap iniziano prima di `make-thread`: includono
creazione/inizializzazione dei thread, ready, apertura del gate, attesa start,
cicli, join e controllo di quiescenza. La stessa finestra globale copre tutti
i worker; il rate è aggregato su COUNT × worker. Non è il throughput di un
pool persistente con startup escluso. L'ordine delle campagne è fisso:
seriale intero, parallelo intero; valori crescenti, CSN 7 poi massimo,
cache/segmento/absent, repliche 0..4, worker 1/2/4.

Il report registra implementazione/versione Lisp, macchina, OS/versione,
directory, policy del driver e unità del timer. Il padre conserva argv,
ambiente host completo, commit, working tree e blob sorgenti prima/dopo
attraverso `record-command.lisp`. CPU/frequenza, carico esterno, cache CPU,
scheduler e pressione di memoria non sono controllati. Non si afferma P99,
latenza client, I/O sostenuto, NVMe, durability o throughput complessivo DB.

## Diagnostiche, sensore e limiti

`--self-test` carica soltanto il sistema prodotto; avvisi di compilazione sono
fallimenti `COD-01`, esclusi i normali redefinition-warning SBCL. Le diagnostiche
del driver includono file e regola; gli errori GET interrompono il ciclo e
sono conservati con completamento parziale/checksum. Non vengono ritentati.
Le finestre fallite restano nel report e il processo esce con codice 1.

L'autoverifica del sensore esegue 20.000 cicli vuoti con checksum/completamento
corretti ed heap zero. Alloca poi quattro array u8 da 1 MiB, li trattiene e
pretende almeno 4 MiB osservati dal contatore globale. Salva e rilegge
`self-test-sensor.lisp`. Il controllo vuoto non è sottratto dai GET e non è
applicato come gate heap-zero alle prestazioni GET.

L'autoverifica diagnostica rifiuta campi mancanti, contatori negativi, esiti,
completamento o checksum dei worker errati, tempi/rate incoerenti; controlla
zero tick, copia delle metriche tramite alias e conversione di un errore in
stato failed/exit 1. Un report positivo può avere heap maggiore di zero.
`self-test-metrics.lisp` conserva i 72 casi autonomi e le diagnostiche.
`--negative-fixture` omette deliberatamente `:completed` in una metrica:
il padre deve osservare report failed e exit-code 1, senza caricare il prodotto.
`--negative-self-test` rimuove invece `:completed` dalla prima finestra reale
del self-test: richiede exit 1 e `self-test-metrics.lisp` con stato failed,
una finestra parziale e la diagnostica del campo mancante. Questa prova
verifica la conservazione del fallimento del self-test prima della campagna.

Budget preregistrati: 600 s per load/fixture/autoverifica/campagne, 30 s per
finestra; ready/start/join condividono la deadline assoluta della finestra.
Il watchdog è installato prima delle letture dei contatori. Il cleanup termina
solo i thread propri e attende al massimo 2 s per thread, fino a quattro;
un worker non quiescente impedisce di consumare i raw e chiudere il FD. Il
processo fallisce senza ridurre COUNT o dichiarare una campagna parziale
riuscita. Le deadline non sono soglie prestazionali.

I sei file della fixture occupano complessivamente 72.192 B e sono rimossi
dopo quiescenza, anche al fallimento. Si pubblicano solo tre file plain:
`report.lisp`, `self-test-metrics.lisp`, `self-test-sensor.lisp`, ciascuno
strettamente minore di 1 MiB UTF-8. Il massimo live della directory propria
resta sotto 4 MiB. Il sensore trattiene 4 MiB di payload soltanto in memoria;
la cache ha payload locale limitato a 70.000 B per fixture. Il budget non
include cache FASL del sistema o record-command esterno, gestiti dal padre.
Checkpoint del report avvengono dopo ogni fixture/campagna, fuori dai clock;
non viene creato un file per replica. Persistenza e rilettura richiedono
uguaglianza dei dati, usando evidence-storage con READ-EVAL NIL.

## Esecuzione registrata e conservazione

Il padre congela il write set, registra i blob e usa directory nuove con
prefix `get-performance-bench*` oppure `get-performance-self-test*`. Il
collector deve includere entrambi i prefix e le tre foglie sopra. Un esito
positivo richiede anche `:source-consistency :stable` nel record esterno;
il benchmark non scrive sorgenti e non certifica da solo il freeze.

Comandi fissati, da eseguire soltanto dal padre dopo il freeze nel checkout:

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-performance-bench.lisp --self-test spikes/out/get-performance-self-test-frozen/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-performance-bench.lisp --negative-fixture spikes/out/get-performance-self-test-negative-frozen/
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/get-performance-bench.lisp --bench spikes/out/get-performance-bench-frozen/
```

Un quarto comando preregistrato usa `--negative-self-test` con directory nuova
`spikes/out/get-performance-self-test-partial-frozen/`, tramite il medesimo
registro esterno. Entrambi i comandi negativi devono fallire: è una prova del rilevamento, da conservare
con stdout/stderr e codice reale. `--bench` include la stessa autoverifica
prima delle campagne. Il processo esce con 0 solo dopo una matrice completa
e un report persistito/riletto; nessuna affermazione quantitativa precede
questa evidenza.

Tutte le foglie pubblicate, inclusi i due self-test, dichiarano
`:schema-version 1`, `:kind` e `:status`. La scrittura esige questa intestazione
prima di persistere; anche il validatore del report controlla la versione.
Il self-test diagnostico rifiuta esplicitamente versione mancante o diversa
da 1 per entrambi i tipi di foglia self-test; la rilettura ricontrolla lo schema.
