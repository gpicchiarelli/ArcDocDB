# SPK-01 — indice primario a frammenti

> **Proposta** — Esperimento di Fase 0, autorizzato dall'autore; non è codice di
> produzione. Domanda, metodo e limiti sono registrati prima dell'esecuzione.

**Ambito: layout v1 di ADR-0043.** Questo spike non implementa e non verifica
il formato v2 adottato da [ADR-0048](../../docs/adr/0048-limiti-documentali-e-formato-v2.md).
La variante a cinque parole qui aggiunge un CSN finale: non è lo slot primario
v2 a cinque parole, che ha un'altra distribuzione dei campi. Chiavi da 16 byte
e length a 24 bit non verificano i limiti documentali v2. `check` e `benchmark`
dichiarano `:layout :adr-0043-v1 :verifies-format-v2 nil`.

## Domanda e criterio

La directory estendibile di ADR-0043, con frammenti a capacità fissa, ctrl byte,
slot da quattro parole u64 e chiavi locali da 16 byte, permette lookup concorrenti
coerenti e recupera spazio durante split e ricambio di chiavi? Si misurano memoria,
insert/get, allocazione, durata degli split e retry; i target ADR-0028 confermati
dall'autore restano da valutare su hardware di riferimento. La verifica locale
richiede confronti differenziali e nessuna incoerenza negli scenari eseguiti.

Riferimenti: ADR-0001, 0028, 0030, 0031, 0032, 0036, 0043, 0050; REQ-IDX-001,
REQ-IDX-003, REQ-IDX-005, REQ-IDX-007, REQ-BEN-001. Lo spike non modifica
i requisiti o i documenti condivisi.

## Metodo

- Package `arcdocdb.spk01`; API `(check)` e `(benchmark &key ...)`, entrambe
  restituiscono plist. Solo Common Lisp/SBCL, `safety 3`, nessuna dipendenza.
- Directory e generazione immutabili, pubblicate con CAS; i bit alti dell'hash
  scelgono il frammento. Sondaggio scalare per gruppi di otto ctrl byte, nessun
  SIMD. Quattro parole: CSN, segment/offset, key-off/key-len/length/flag, seqlock.
  La variante a cinque parole aggiunge un CSN finale, con lo stesso seqlock.
- Un writer per indice. Ogni manutenzione legge al massimo C slot di un solo
  frammento; gli split creano due frammenti, i rebuild uno. La copia della
  directory costa separatamente O(2^G), anche per rebuild e split senza
  raddoppio: ogni pubblicazione copia l'intero vettore immutabile. Il report
  conta i riferimenti copiati e distingue tempo di directory, copia del
  frammento e manutenzione totale. `payload-indice` è O(1), usando contatori
  del writer; `indice-statistiche` scandisce la directory fuori dalle fasi
  misurate. Il costo totale della manutenzione non è limitato da C. La profondità è
  configurata e controllata; saturazione e collisioni estreme danno errore.
- Arena locale fissa C×16 byte in questo prototipo: append-only fino al limite,
  poi rebuild delle sole chiavi vive. Non è implementata la crescita separata
  dell'arena prevista da ADR-0043. Ctrl: vuoto → occupato → eliminato → occupato;
  nessun ritorno a vuoto sullo stesso frammento. Nessun merge di frammenti.
- Reader: otto tentativi al massimo, barriere e seqlock. `leggi` restituisce
  `:retry-limit` senza bloccare. Il solo harness usa un mutex per serializzare
  writer e ripiego; nessun mutex nel reader fast path. Non simula la coda del
  writer logico di produzione. Contatori retry locali a ciascun reader.
- Chiavi e golden hash deterministici, maschere a 64 bit esplicite. Il mixing
  moltiplicativo viene compilato inline con intermedi u64; la funzione autonoma
  e il trasporto dei risultati u64 tra funzioni possono richiedere boxing.
  Nessuna promessa di allocazione zero. Le
  misure separano allocazione di processo e payload strutturale dell'indice.
- Verifica: golden hash/output, collisioni, split, deletion/reinsertion, reclaim,
  limiti, sequenze seeded contro `hash-table`, ricontrollo della root con
  interleaving iniettato, aggiornamento durante seqlock e reader concorrenti con
  writer. Errori dei worker restituiti e risollevati dal coordinatore dopo join;
  cleanup dei thread anche in caso di errore.

> **Deciso (2026-10-08 → ADR-0050)** — Il solo stato
> congelato del frammento ritirato non giustifica il punto di linearizzazione
> dichiarato all'istante di lettura del riferimento. Il prototipo rilegge root/generazione dopo il
> sondaggio (anche su miss), scarta il risultato se sono cambiate e riprova.
> Questa verifica sperimentale non sostituisce il modello SPK-07 né una prova
> del modello di memoria sulle due architetture.

### Witness deterministico per ADR-0043 §3

`check` restituisce il witness in `:retired-root`; la fixture usa il callback
`leggi :after-fragment` senza dipendere dallo scheduler:

1. Writer: chiave K presente con CSN 1; reader: acquisisce root R e frammento F.
2. Writer: aggiorna K a CSN 2 nello stesso F ancora attivo.
3. Writer: split di F, copia CSN 2 nei figli e pubblica R′ con CAS. F è ritirato.
4. Writer: aggiorna K a CSN 3 nel figlio corrente.
5. Reader: sonda F ritirato e legge un hit coerente con CSN 2. Senza ricontrollo
   restituirebbe 2; il controllo di R/generazione scarta il tentativo, rilegge
   R′ e restituisce 3 con un retry. La fixture legge anche F direttamente e
   verifica che il risultato senza ricontrollo sia proprio 2.

L'hit 2 è errato rispetto al **punto dichiarato** di acquisizione di R, dove K
valeva 1. Questo witness falsifica quel punto di linearizzazione; non dimostra
un errore generale di linearizzabilità, poiché 2 è esistito durante l'operazione.
L'output rende esplicito `:general-linearizability-counterexample nil`.
Una seconda sequenza verifica che anche un miss su F ritirato venga scartato
dopo swap e inserimento nel frammento corrente. Il punto di linearizzazione
e il costo O(2^G) sono qualificati in
[ADR-0050](../../docs/adr/0050-pubblicazione-e-costi-della-directory.md),
REQ-IDX-007; resta da modellare swap/reader in SPK-07. La sola coerenza del
frammento congelato non fissa il punto prima dichiarato da ADR-0043.

## Comandi

Da qualsiasi directory, `run.lisp` risolve `core.lisp` rispetto a
`*load-truename*`, compila in `out/core.fasl` e promuove warning e style-warning a
errori. Stampa una sola s-expression plist; fallimento con exit code non nullo.

```sh
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --check
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --documents 1000 --seconds 1 --capacity 64 --readers 2
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --words 5
```

Il default usa 100.000 documenti, capacità 8.192, quattro parole, due reader,
budget di 12 secondi per le fasi misurate: obiettivo circa 15 secondi complessivi,
non garanzia temporale. Il tempo viene controllato a blocchi; quantità effettive,
fase incompleta e durata reale sono sempre riportate. Budget strutturale di
512 MiB (default); il limite di heap del runtime si imposta separatamente.
Per la campagna seriale:

```sh
sbcl --dynamic-space-size 1024 --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --documents 1000000 --seconds 12
```

La scala 10^7 è opzionale, richiede budget e heap espliciti più grandi e tempo
sufficiente: `--documents 10000000 --seconds 120 --memory-mib 2048`, con
`--dynamic-space-size 4096` prima di `--script`. La campagna si esegue in serie.
Il controllo della memoria riguarda strutture correnti e
allocazioni transitorie previste, non RSS, garbage non ancora raccolto o oggetti
trattenuti da reader sospesi. Non si afferma un limite assoluto di RSS.

## Ambiente, misure e limiti

L'output registra implementazione/versione, macchina, sistema operativo,
parametri, seed, unità e conteggi effettivi. `byte/doc` è il payload esatto
degli array vivi più riferimenti della directory, senza header, strutture Lisp,
heap del runtime o frammenti ritirati. L'allocazione è quella rilevata da
`sb-ext:get-bytes-consed`, cumulativa di processo, inclusi bignum e harness;
non è una misura di RSS. Throughput include hash e generazione della chiave in
buffer riutilizzato. Durata split include copia di directory e allocazione;
durata rebuild è distinta. Un campione temporale di risoluzione insufficiente
produce `nil` per i rapporti non calcolabili.

Warmup separato (256 insert e 1.024 get), escluso dai tempi delle fasi. Ogni
fase porta un sink restituito nel report e verifica il pattern dei dati letti.
I secondi sono wall (`get-internal-real-time`), non CPU. L'allocazione della
fase concorrente include sia reader sia writer del harness: il rapporto per
lookup descrive il costo dell'intero carico, non una sola funzione reader.
Riferimento runtime: [manuale SBCL, barriere e CAS](https://www.sbcl.org/manual/#Memory-Barriers).

La variante a cinque parole verifica layout e trasporto del CSN finale, non
implementa versioni multiple per chiave o selezione snapshot. Non sono coperti
WAL, persistenza, MVCC, compaction, queue del writer, pause GC, né verifica del
codice macchina per accessi atomici agli slot su entrambe le architetture.
Il disassemblato del solo kernel hash ARM64 è descritto sotto. Stress concorrente e test seeded sono evidenza degli scenari
eseguiti, non dimostrazione universale di linearizzabilità.

## Risultato

Verifica `--check` riuscita su SBCL 2.6.9, ARM64 Apple M4, Darwin 27.0.0:
golden output, 3.000 operazioni seeded per larghezza 4/5, collisioni con rifiuto
esplicito al limite, reclaim, witness root, seqlock e fallback forzato, limiti,
propagazione errori dei worker e cleanup; due reader × 1.200 operazioni con
writer × 600 iterazioni, per entrambe le larghezze. Compilazione senza warning
o style-warning tramite il launcher. I conteggi retry dello stress variano
con lo scheduler, mentre gli assert e il witness sono deterministici.

Diagnostica breve, eseguita dalla cwd `/tmp` il 2026-10-08:

```sh
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --documents 1000 --seconds 1 --capacity 64 --readers 2 --words 5
```

Report locale in `out/diagnostic-5.sexp` (ignorato da Git). Nel campione:
1.000 documenti effettivi; payload 106.048 byte prima e 116.992 byte dopo il
churn; 31 split e 35 rebuild dopo churn. GET: 1.179.552 byte allocati su 8.000
operazioni, cioè 147,444 byte/operazione del carico misurato. Il risultato
esclude qualunque dichiarazione di allocazione zero; l'attribuzione a bignum,
boxing e altre fonti richiede profiling. Questi dati diagnostici non chiudono
i target o il gate 10^7–10^8: i throughput del report non sono una campagna
rappresentativa. Nessun benchmark lungo eseguito in questa diagnostica;
le misure complete si eseguono in serie. La crescita della directory e l'assenza
di merge richiedono misure di churn più lunghe; il limite esplicito di memoria non implica un costo
di manutenzione indipendente dalla dimensione della Serie.

### Esperimento successivo: kernel hash senza boxing evitabile

> **Proposta** — Registrato prima dell'esecuzione: mantenere identici SplitMix64,
> chiavi, golden e seed; aggiungere INLINE a `mix64`, `parola-chiave` e
> `hash-chiave`, con tipi espliciti su argomenti e intermedi u64, `safety 3`.
> Ipotesi da misurare: diminuire il boxing alle chiamate interne del kernel
> hash, senza VOP interni o cambio di algoritmo. Nessuna promessa di allocazione
> zero: payload u64 restituiti dall'API possono ancora richiedere boxing.

Il baseline locale è stato misurato a 100.000 documenti (report in
`spikes/out/4000472823-bench/`): GET 2,915 M/s e 151,95 byte/op;
INSERT 1,657 M/s e 551,75 byte/op. Confronto diagnostico singolo dopo warmup,
stessa scala e parametri predefiniti salvo budget breve `--seconds 1`:

```sh
sbcl --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --documents 100000 --seconds 1
```

Si confrontano soprattutto byte/op; durata, conteggi effettivi e sink restano
nel report. Il budget diverso limita la comparabilità dei throughput. Prima
e dopo: golden/seed e check; ispezione del disassemblato di wrapper compilati
che leggono/scrivono array u64 per distinguere il kernel dal boxing di ritorno
di una funzione Lisp. La verifica delle location e dei CSN alti copre anche
u64 superiori a `most-positive-fixnum`.

**Esito diagnostico misurato** — singola esecuzione, 100.000 insert e 800.000
get completati, `out/inline-hash-100k.sexp`; nessun warning/style-warning.

| Misura | Baseline locale | INLINE, diagnostica singola |
|---|---:|---:|
| GET byte allocati/op | 151,94986 | 71,94406 |
| INSERT byte allocati/op | 551,74592 | 219,95536 |
| GET operazioni/s | 2.915.048 | 3.328.355 |
| INSERT operazioni/s | 1.657.275 | 1.714.296 |
| Wall massimo split, ms | 1,613 | 17,171 |

L'allocazione osservata diminuisce; i throughput sono indicativi di questo
campione. La durata massima dello split è aumentata nel campione: la causa
non è profilata, e resta evidenza da conservare nelle repliche.
Il baseline è stato lanciato con heap 4.096 MiB, mentre la diagnostica usa il
default del runtime e un budget temporale diverso; questo limita il confronto
di GC e latenze. Non si conclude un miglioramento del costo massimo.
Payload vivo prima e dopo il churn: 6.422.656 byte, 64,22656 byte/doc esclusi
header; 15 split, 16 rebuild, 426 riferimenti di directory copiati complessivi.

Golden hash fissati dal FASL precedente all'ottimizzazione per ID 0, 1,
424.242 e 2^64−1; stessi valori dopo INLINE. `check` verifica inoltre CSN,
location e CSN finale pari a 2^64−1, length a 2^24−1 e la variante 5 parole.

Disassemblato locale: `out/hash-kernel-disassembly.txt`, generato da
`out/disassemble-kernel.lisp` e `out/kernel-probe.lisp`. I wrapper con
`safety 3` leggono/scrivono array u64 e restituiscono NIL, così il kernel non
include boxing del ritorno Lisp. Nelle due funzioni osservate: `LDR`/`STR`
a 64 bit, `ADD`, `MUL`, `LSR`, `EOR`; nessuna chiamata ad aritmetica generica
o allocazione sul percorso normale del codice mostrato, controlli dei limiti
degli array presenti. Questa ispezione è limitata a SBCL 2.6.9 ARM64; non
dimostra allocazione zero del GET o atomicità dell'intero protocollo.
Wrapper riproducibili, da compilare dopo aver caricato `out/core.fasl`:

```lisp
(in-package #:arcdocdb.spk01)
(declaim (optimize (safety 3) (speed 2) (debug 1)))
(defun probe-mix64 (input output)
  (declare (type parole input output))
  (setf (aref output 0) (mix64 (aref input 0)))
  nil)
(defun probe-hash (chiave output)
  (declare (type ottetti chiave) (type parole output))
  (setf (aref output 0) (hash-chiave chiave 0))
  nil)
```

Confronto e repliche si eseguono in serie. Restano aperti il gate
10^7–10^8, il costo O(2^G) della pubblicazione e il profiling dell'allocazione
residua nell'API; nessun cambiamento a trie o al formato dell'indice.

### Microfix successivo: trasporto degli helper

> **Proposta** — Registrato prima della verifica: INLINE di `scegli-frammento`,
> `sonda-reader`, `leggi-slot`, `posizione-sonda`, `impronta` e `scrivi-chiave`,
> con tipi espliciti degli argomenti e dei locali u64; `alto` della generazione
> chiave dichiarato u64. Ipotesi: eliminare ulteriore boxing del trasporto hash
> e della chiave. API `leggi` autonoma, stesso layout v1 e `safety 3`.

Verifica prevista: `--check` e disassemblato ARM64; nessun ulteriore benchmark
in questa diagnostica. I numeri di `inline-hash-100k.sexp` descrivono il kernel
hash precedente a questo microfix. Le repliche si eseguono con heap 4 GiB
a 100.000 e 10^7 documenti, riportando allocazione residua effettiva.

**Esito della verifica** — `--check` passato con compilazione senza warning
o style-warning, incluse larghezze 4/5, golden del FASL precedente, CSN/location
u64 alti, root hit/miss, fallback forzato e thread con cleanup. Disassemblato
in `out/reader-after-microfix-disassembly.txt`: `leggi` resta autonoma; kernel
hash e helper elencati sono incorporati, senza chiamate alle funzioni ponte.
Aritmetica e accessi u64 sono visibili; restano tre rami di boxing da 32 byte
per CSN/location/CSN finale quando non rappresentabili come fixnum, al confine
dei valori restituiti. Le barriere ARM64 e i controlli degli array restano nel
codice. Nessuna misura di allocazione dopo questo microfix è stata eseguita
in questa diagnostica.

Il disassemblato precedente di `scrivi-chiave`, conservato in
`out/key-before-microfix-disassembly.txt`, già mostrava XOR e scrittura byte
senza allocazione sul percorso valido; non si attribuisce quindi un risparmio
di 32 byte/op alla sola dichiarazione di `alto`. L'effetto degli INLINE sulle
allocazioni del reader va misurato nelle repliche.

## Ambito del formato

### Repliche con heap 4 GiB

> **Proposta (profilazione successiva)** — isolare generazione della chiave,
> hash con risultato in array u64 e API `leggi` su chiave fissa. Dopo warmup,
> un milione di chiamate per caso, processo dedicato: clock e byte allocati
> del processo. Confrontare `speed 2` e `speed 3` nel reader mantenendo
> `safety 3`; nessun cambio del formato o dei controlli. Questa diagnostica
> serve ad attribuire il residuo, non misura il database.

La [campagna pubblicata](../../docs/valutazione/risultati-2026-10-08.md) conserva
anche i risultati dopo il microfix completo: GET 3,557 M/s e 47,99 B/op a
100.000 documenti; 2,098 M/s e 48,00 B/op a 10 milioni, con 75.400.960 GET
effettivi. Alla scala maggiore: 82,21 B/doc di payload e massimo split
98,827 ms, causa non profilata. Nessuna garanzia di allocazione nulla o pausa
indipendente dalla dimensione. I dati grezzi identificano sorgenti e comandi.

Questo esperimento esercita il layout v1. Il layout v2 a 5 parole e le chiavi estese di ADR-0048 richiedono una campagna distinta: i risultati qui non lo verificano.
