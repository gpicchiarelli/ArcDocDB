# SPK-01 — indice primario a frammenti

> **Proposta** — Esperimento di Fase 0, autorizzato dall'autore; non è codice di
> produzione. Domanda, metodo e limiti sono registrati prima dell'esecuzione.

## Domanda e criterio

La directory estendibile di ADR-0043, con frammenti a capacità fissa, ctrl byte,
slot da quattro parole u64 e chiavi locali da 16 byte, permette lookup concorrenti
coerenti e recupera spazio durante split e ricambio di chiavi? Si misurano memoria,
insert/get, allocazione, durata degli split e retry; i target ADR-0028 confermati
dall'autore restano da valutare su hardware di riferimento. La verifica locale
richiede confronti differenziali e nessuna incoerenza negli scenari eseguiti.

Riferimenti: ADR-0001, 0028, 0030, 0031, 0032, 0036, 0043; REQ-IDX-001,
REQ-IDX-003, REQ-IDX-005, REQ-BEN-001. Nessuna modifica di requisiti o documenti
condivisi rientra nel write set di questo agente.

## Metodo

- Package `arcdocdb.spk01`; API `(check)` e `(benchmark &key ...)`, entrambe
  restituiscono plist. Solo Common Lisp/SBCL, `safety 3`, nessuna dipendenza.
- Directory e generazione immutabili, pubblicate con CAS; i bit alti dell'hash
  scelgono il frammento. Sondaggio scalare per gruppi di otto ctrl byte, nessun
  SIMD. Quattro parole: CSN, segment/offset, key-off/key-len/length/flag, seqlock.
  La variante a cinque parole aggiunge un CSN finale, con lo stesso seqlock.
- Un writer per indice. Ogni manutenzione legge al massimo C slot di un solo
  frammento; gli split creano due frammenti, i rebuild uno. La copia della
  directory costa separatamente O(2^G): non è limitata da C. La profondità è
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
  moltiplicativo può allocare bignum; nessuna promessa di allocazione zero. Le
  misure separano allocazione di processo e payload strutturale dell'indice.
- Verifica: golden hash/output, collisioni, split, deletion/reinsertion, reclaim,
  limiti, sequenze seeded contro `hash-table`, ricontrollo della root con
  interleaving iniettato, aggiornamento durante seqlock e reader concorrenti con
  writer. Errori dei worker restituiti e risollevati dal coordinatore dopo join;
  cleanup dei thread anche in caso di errore.

> **Proposta** — Correzione da riportare al parent per ADR-0043 §3: il solo stato
> congelato del frammento ritirato non giustifica la linearizzazione all'istante
> di lettura del riferimento. Il prototipo rilegge root/generazione dopo il
> sondaggio (anche su miss), scarta il risultato se sono cambiate e riprova.
> Questa verifica sperimentale non sostituisce il modello SPK-07 né una prova
> del modello di memoria sulle due architetture.

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
Per la campagna seriale del parent:

```sh
sbcl --dynamic-space-size 1024 --script /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-01-primary-index/run.lisp --bench --documents 1000000 --seconds 12
```

La scala 10^7 è opzionale, richiede budget e heap espliciti più grandi e tempo
sufficiente: `--documents 10000000 --seconds 120 --memory-mib 2048`, con
`--dynamic-space-size 4096` prima di `--script`. Non viene eseguita durante il
lavoro parallelo. Il controllo della memoria riguarda strutture correnti e
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

La variante a cinque parole verifica layout e trasporto del CSN finale, non
implementa versioni multiple per chiave o selezione snapshot. Non sono coperti
WAL, persistenza, MVCC, compaction, queue del writer, pause GC, né disassemblato
su x86-64 e ARM64. Stress concorrente e test seeded sono evidenza degli scenari
eseguiti, non dimostrazione universale di linearizzabilità.

## Risultato

Non ancora eseguito. L'agente eseguirà solo `--check` e diagnostiche brevi;
le misure complete spettano al parent in serie. Nessun numero prestazionale
è anticipato.
