# SPK-01 — metodo preregistrato del confronto lettura buffer

> **Proposta** — confronto sperimentale Fase0; REQ-VAL-001, REQ-BEN-001.

Registrato prima di qualsiasi compilazione il 2026-10-08. Fase0, Common
Lisp/SBCL, safety 3. Proprietà esclusiva: questo metodo,
`bench-lettura-buffer.lisp` e nuovi file sotto
`out/bench-lettura-buffer-agent/`. Il checkout è esclusivamente
`/Users/gpicchiarelli/.codex/worktrees/indice-lettura/ArcDocDB`.
Core, runner, tools, documenti condivisi e sorgenti degli altri agenti non
sono modificati. Nessun commit/push. L'agente compila soltanto; **non esegue
BENCH, warmup, CHECK o kernel di altri agenti**. Profilazione, integrazione e
tutte le misure seriali sono del parent.

## Ipotesi e matrice fissa

Confrontare la baseline `ARCDOCDB.SPK01:LEGGI`, che restituisce quattro campi,
stato e retry, con `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, che restituisce stato
e retry e pubblica quattro u64 nel buffer privato dopo seqlock e root validati.
Una sola istanza immutabile dell'indice per cella serve entrambi i metodi.
Nessun writer durante warmup/misure. Barriere, ricontrollo root e writer
restano responsabilità dei moduli esistenti; il benchmark non li reimplementa.

| Layout v1 | Profilo | Workload | Coppie | Campioni |
| --- | --- | --- | ---: | ---: |
| words4 | fields-fixnum | hit-only | 5 | 10 |
| words4 | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words4 | u64-massimi | hit-only | 5 | 10 |
| words4 | u64-massimi | mixed-hit-miss | 5 | 10 |
| words5-extra-end | fields-fixnum | hit-only | 5 | 10 |
| words5-extra-end | fields-fixnum | mixed-hit-miss | 5 | 10 |
| words5-extra-end | u64-massimi | hit-only | 5 | 10 |
| words5-extra-end | u64-massimi | mixed-hit-miss | 5 | 10 |

Totale obbligatorio: 8 celle, 40 coppie, 80 campioni. A = baseline, B = buffer.
Per cella e replica si alterna AB/BA secondo la parità di cella + replica:
20 coppie AB e 20 BA nell'intera matrice. Cinque repliche esatte; nessun filtro
di celle o interruzione con successo parziale. Le comparazioni paired
conservano numeri di campione, ordine, delta e rapporti, senza proclamare
superiorità statistica da cinque coppie.

## Dati e consumatore comune

Default: 4096 documenti, C8192, 128000 lookup effettivi per campione
(qui 128k significa 128000), 4096 lookup di warmup per metodo/cella.
Si preparano fuori misura chiavi univoche di 16 byte per documenti e miss
nuovi, due query array di lunghezza 2*documents, quattro campi indipendenti
per documento/cella, oracle u64 e status byte preallocati per cella.
Hit-only percorre due permutazioni della popolazione; mixed alterna hit e
miss (50% su ogni periodo completo), cominciando da un hit. Il miss usa
un ID distinto da ogni documento. Ordine deterministico con moltiplicatore
104729, senza RNG o generazione chiavi nel ciclo.

Le tuple sono generate prima dell'inserimento e l'oracle è costruito dalle
tuple, mai leggendo l'indice. CSN, location, length ed end-CSN hanno formule
distinte. Nel profilo estremo CSN/location/end includono 2^64-1 e valori
vicini; length include 2^24-1, il limite v1. words4 ha sempre end-CSN zero.
La location viene scomposta in segmento/offset u32 solo per inserire.
Non si usa il pattern correlato del core né il layout v2.

Due cicli compilati, generati da una macro comune, chiamano direttamente le
API tipizzate: nessun FUNCALL di lookup. Il consumatore e il controllo
dell'oracle sono la stessa espansione nei due cicli. Su hit si confrontano
esattamente quattro u64. Su miss la baseline mantiene i quattro valori del
precedente hit; la variante legge il buffer che deve mantenere quel payload.
L'oracle del miss è il payload del precedente hit. Non si copia la baseline
nel buffer per simulare l'altra API. I quattro valori restituiti dalla
baseline su miss sono ignorati: non costituiscono un payload valido.
Un retry-limit, uno stato inatteso, un retry in questo fixture immutabile,
un campo diverso o un numero di operazioni insufficiente sono errori.

Il checksum resta un fixnum non negativo di 60 bit: per ogni u64 si uniscono
parte bassa di 60 bit e parte alta di 4 bit dopo rotazione del checksum.
Nessuna estrazione del sink u64 per stamparlo durante il ciclo. Il checksum
non sostituisce il confronto integrale dei quattro campi. Sono inclusi anche
stato e retry; entrambi i metodi devono avere checksum, hit, miss e retry
uguali per ogni coppia. Nessun hash-table, cons esplicito, report, lista,
generazione di chiave o costruzione di oracle nel ciclo. Le allocazioni delle
API, compreso il boxing della baseline, sono precisamente ciò che si misura.

## Finestra, GC e contatore positivo

Preparazione, inizializzazione del buffer, warmup, full GC e report sono
fuori dalla finestra. Full GC precede ogni campione. La finestra comprende
lookup, accessi alle query/oracle, verifica, checksum, conteggi e guardie
cooperative ogni 256 operazioni. Il GC provocato dentro il ciclo è incluso.
Wall ticks da GET-INTERNAL-REAL-TIME, ns/op esatto derivato da ticks e unità
del timer, delta GET-BYTES-CONSED; tick zero o delta negativo sono errori.
Il contatore consed è di processo: nessun altro benchmark o worker deve
operare contemporaneamente. La destinazione è un simple-array u64 di
lunghezza esatta 4, privata alla cella/chiamante; questo modulo non crea thread.

Prima della preparazione/misura si esegue, fuori misura, un controllo positivo
del contatore: full GC, before, allocazione di un vector u8 di 262144 byte
pubblicato in un globale del modulo, after. Il globale resta vivo almeno fino
al delta; solo dopo after si leggono il contenuto e
SB-EXT:PRIMITIVE-OBJECT-SIZE dell'oggetto effettivo. Si riportano before,
after, delta, elementi, payload, valore letto e dimensione reale. Un delta
non positivo o più piccolo del payload è errore. Nessuna inferenza sul payload
heap di array non escaped. La dimensione reale è diagnostica fuori misura;
il tetto payload esclude header, mentre quello heap include l'uso dinamico
osservato dal runtime.

## API e budget

Package `ARCDOCDB.SPK01.BENCH-LETTURA-BUFFER`, unico export `BENCH`.

| Keyword | Default | Vincolo |
| --- | ---: | --- |
| documents | 4096 | 1..max-documents; <=7*C/8 |
| capacity | 8192 | potenza di due, 8..32768 |
| operations | 128000 | 1..max-operations |
| replicas | 5 | esattamente 5 |
| warmup | 4096 | 1..min(max-warmup,operations) |
| time-limit-seconds | 120 | reale positivo <=max-time-limit-seconds |
| memory-mib | 256 | heap dinamico, 1..1024 MiB |
| attempts | 8 | 1..8 |
| max-documents | 16384 | 1..28672 |
| max-operations | 1000000 | 1..10000000 |
| max-warmup | 65536 | 1..1000000 |
| max-payload-bytes | 33554432 | 1..268435456 |
| max-copy-bytes | 16777216 | 1..67108864 |
| max-consed-bytes | 1073741824 | 1..4294967296 |
| max-time-limit-seconds | 300 | reale positivo <=300 |

Tutti i parametri, il carico senza split e le stime di payload/copie sono
validati **prima di qualunque campione**. Payload preventivo conservativo:
otto frammenti/directory v1, chiavi e query condivise, otto oracle/status/buffer,
una tabella temporanea di tuple e vector del controllo positivo. Le copie
contate sono le chiavi inserite (8*documents*16) e i campi copiati nell'oracle
(8*2*documents*32). Nessuna manutenzione è ammessa; i contatori del core
devono restare a zero per split/rebuild/copie di manutenzione.

Scadenza unica cooperativa per l'intera BENCH, default <=120 s, hard cap 300 s,
controllata in preparazione, tra GC, warmup, campioni, report e ogni blocco
di lookup. Controlli del tetto heap tramite SB-KERNEL:DYNAMIC-USAGE e del
consed cumulativo dell'intera BENCH alle stesse guardie. Consed cumulativo
include preparazione, controllo positivo, warmup e report; il delta del
campione comprende solo la finestra dichiarata. GC/allocazioni/chiamate non
sono interrotti asincronamente: l'overshoot cooperativo può essere osservato,
ma dopo scadenza si segnala errore. Nessun budget esaurito restituisce :ok.

BENCH restituisce dati plain readable: liste di keyword/stringhe/numeri;
tipi e nomi di funzioni come stringhe, niente simboli dei package dello spike,
array, pathname o strutture nel risultato. :ok è costruito soltanto dopo
80 campioni completi, 40 confronti paired e ultima guardia. Il parent registra
anche gli errori nel proprio envelope schema1, senza promuovere prefissi
di campioni a risultati completi.

## CLI pianificato e compilazione locale

CLI parent pianificato, non eseguito da questo agente:

```sh
sbcl --noinform --disable-debugger --script spikes/SPK-01-primary-index/run.lisp --bench --variant buffer --documents 4096 --capacity 8192 --operations 128000 --replicas 5 --warmup 4096 --time-limit-seconds 120 --memory-mib 256
# harness integrato: --bench SPK-01 -- --variant buffer [stesse opzioni]
```

Prima di ogni tentativo compile si aggiunge qui il piano e si crea un nuovo
direttorio esclusivo `out/bench-lettura-buffer-agent/attempt-NNN/`. Il driver
Common Lisp registra schema1 con argv e stdin esatti, ambiente, source-before
e source-after (hash MD5 SBCL e contenuti integrali di core, modulo, metodo
e driver), stdout/stderr originali, warning/style-warning come stringhe,
tutti i valori compile-file normalizzati a keyword/stringhe e risultato.
Il compilatore/core vengono caricati con warning e style-warning fatali.
Per compilare il consumer senza eseguire codice dell'altro agente è sufficiente
un package/proclamazione dell'API buffer; non si definisce alcun kernel stub.
Si compilano e caricano core e benchmark; nessuna chiamata a BENCH o warmup.
Se il reader reale è disponibile, si compila/carica anche quel file come
dipendenza immutata, senza invocarne funzioni. La proclamazione dei valori
del reader include `&optional`, identica al kernel, per evitare incompatibilità.

Un recorder separato lancia il driver con stdin conservato, cattura i due
stream originali e il codice di uscita. Un **terzo processo SBCL senza alcun
package dello spike** rilegge dati/envelope con *read-eval*=nil, controlla che
ogni foglia sia keyword/stringa/numero, e salva la decodifica leggibile.
Anche i fallimenti restano registrati; mai sovrascrivere un tentativo.

### Piano attempt-001

Compilare strict core, reader reale ora disponibile e consumer; caricare
tutti e tre senza invocazioni. Il reader resta immutato e viene incluso nei
source-before/after. Nessun kernel stub. La proclamazione ftype coincide
con quella del reader, incluso `(values keyword fixnum &optional)`.
CLI locale previsto: `sbcl --noinform --disable-debugger --script
spikes/SPK-01-primary-index/out/bench-lettura-buffer-agent/recorder.lisp 001`.
Accettazione: zero warning/style-warning, warnings-p/failure-p :no,
FASL non nulli; dati rilette nel processo neutro. Non prova la correttezza
del kernel, la riuscita del warmup o alcuna prestazione.

Il parent ha comunicato un precedente profilo lookup-fixed-key di
47.96064 B/op e key/hash 0 B osservati: contesto esterno, non risultato di
questa matrice e non prova di allocazione zero generale.

### Esito attempt-001 e piano attempt-002

001: core e reader compilati/caricati senza warning; consumer non compilato
per EOF nella forma BENCH (binding list di deadline non chiusa). warnings-p
e failure-p del consumer :yes, output :none; zero warning/style-warning
segnalati, un errore del reader Lisp. Driver uscita 1, decoder neutro uscita 0.
Record e decodifica conservati in `out/bench-lettura-buffer-agent/attempt-001/`.
Nessuna invocazione di BENCH/warmup/CHECK/lookup.

002 preregistrato prima dell'esecuzione: chiudere la binding list della
deadline, stesso strict compile/load di core, reader reale e consumer.
Il writer dell'evidenza usa stringhe letterali comuni evitando la notazione
SBCL #A per base-string; ogni foglia resta validata e i dati sono riletti con
*read-eval*=nil nel decoder neutro. CLI identico con argomento `002`.
Accettazione invariata, senza alcuna esecuzione di benchmark o warmup.

### Esito attempt-002 e piano attempt-003

002: compilazione dei tre file senza warning/style-warning e tutti i valori
compile-file :no/:no. Il load del consumer segnala un solo style-warning
REDEFINITION-WITH-DEFMACRO: COMPILE-FILE lascia definito il generatore
globale %DEFINE-CONSUMER e il FASL lo ridefinisce. Il driver carica ciascun
FASL una sola volta. L'avviso è fatale, non soppresso. Uscita driver 1,
decoder neutro 0; stdout/stderr, condizioni e source-before/after conservati.

003 preregistrato: generatore locale MACROLET con le due espansioni nel suo
corpo comune; nessuna definizione di macro persistente nel FASL o nel package.
Strict compile/load di core, reader e consumer nel medesimo processo, stesso
driver, CLI con argomento `003`. Zero warning/style-warning anche al load,
rilettura neutra e zero invocazioni BENCH/warmup/CHECK/lookup richiesti.
