# Piano degli spike

Uno **spike** è un esperimento piccolo e mirato che risponde a una domanda di valutazione. Non
è codice di produzione: vive in [`spikes/`](../../spikes/README.md), si può buttare, e il suo
prodotto è una **misura con una raccomandazione**.

## Regole

- Solo Common Lisp su SBCL ([ADR-0001](../adr/0001-common-lisp-sbcl.md)).
- Ogni spike dichiara *prima* di essere eseguito: domanda, metodo, criterio di esito.
- Ogni risultato riporta hardware, sistema operativo, versione e parametri di SBCL, comando
  esatto ([riproducibilità](../13-benchmark.md#riproducibilità)).
- Le misure sulla macchina di sviluppo sono indicative; quelle che dipendono da I/O e numero
  di core vanno ripetute sulla piattaforma di riferimento (QA-19).
- Al termine si aggiornano [registro dei rischi](registro-rischi.md),
  [stime](stime-ordine-di-grandezza.md) e la questione aperta collegata.

## Quadro

| ID | Spike | Risponde a | Rischi | Ordine |
|---|---|---|---|---|
| [SPK-01](#spk-01) | Primary index compatto | QA-24, QA-03, QA-16 | RSK-02, RSK-07 | 1 |
| [SPK-02](#spk-02) | GC di SBCL sotto carico | QA-18 | RSK-01 | 1 |
| [SPK-03](#spk-03) | WAL e group commit | QA-02, QA-05, QA-19 | RSK-03, RSK-06, RSK-11 | 2 |
| [SPK-04](#spk-04) | Writer logico su thread pool | QA-26 | RSK-04 | 4 |
| [SPK-05](#spk-05) | Percorso di lettura dei segmenti | QA-17, QA-19 | RSK-10, RSK-16 | 4 |
| [SPK-06](#spk-06) | Interferenza della compaction e controllore di carico | QA-11, QA-12 | RSK-08, RSK-12 | 5 |
| [SPK-07](#spk-07) | Modelli dei protocolli | QA-04, QA-06, QA-07, QA-09, QA-24 | RSK-02, RSK-05 | 3 |
| [SPK-08](#spk-08) | SIMD e codice generato | QA-19 | RSK-11, RSK-16 | 5 |
| [SPK-09](#spk-09) | Costo dei controlli di affidabilità | ADR-0033, ADR-0034 | RSK-19 | 1 |

---

### SPK-01

**Primary index compatto.**

- *Domanda:* una tabella hash compatta, in array specializzati, con un writer e molti reader
  senza lock, è realizzabile in solo Common Lisp con prestazioni dell'ordine richiesto?
- *Metodo:* prototipo della tabella a frammenti di
  [ADR-0043](../adr/0043-primary-index-a-frammenti.md) (directory estendibile, frammenti Swiss
  a capacità fissa, slot a 4 parole, chiavi locali) su array specializzati; carico con
  10⁷–10⁸ entry; un thread scrive, N leggono; divisioni continue sotto carico; inserimenti ed
  eliminazioni ripetuti a popolazione costante; variante a 5 parole per le versioni
  trattenute. Verifica sul codice generato che ogni parola sia letta e scritta con una sola
  istruzione sulle due piattaforme.
- *Misure:* lookup/s per core e aggregati; inserimenti/s; **byte per documento** (media e
  intervallo); durata di una divisione; memoria a popolazione costante con ricambio di chiavi
  (deve restare limitata); effetto sulle pause del GC; correttezza delle letture concorrenti;
  frequenza del ripiego del seqlock.
- *Esito:* ordine di grandezza dei lookup compatibile con il target dei GET; memoria per entry
  entro la [stima](stime-ordine-di-grandezza.md#memoria-del-primary-index); nessuna lettura
  incoerente.

### SPK-02

**GC di SBCL sotto carico.**

- *Domanda:* quali pause produce il collector con heap delle dimensioni previste, e quanto
  dipendono da dove vivono indice e cache?
- *Metodo:* processo con (a) decine di GB in array specializzati nello heap, (b) la stessa
  memoria fuori dallo heap gestito; carico sintetico multi-thread con tasso di allocazione
  variabile per richiesta (zero, basso, alto); confronto tra configurazioni del collector.
  In più ([ADR-0043](../adr/0043-primary-index-a-frammenti.md), [ADR-0045](../adr/0045-modello-di-esecuzione.md)):
  la stessa memoria in decine di migliaia di frammenti da ~256 KiB anziché in pochi array
  enormi, con sostituzione continua di frammenti; numero di thread crescente (16, 64, 256),
  con thread fermi in chiamate di sistema.
- *Misure:* distribuzione delle pause (P50, P99, massimo); frequenza; tempo totale in GC;
  latenza delle richieste sintetiche; **pausa in funzione del numero di thread** (fissa il
  tetto del pool di I/O).
- *Esito:* pause entro l'obiettivo numerico di P99 (da fissare con QA-26) nella configurazione
  migliore. In caso contrario: quantificare lo scarto e rivalutare ADR-0001.

### SPK-03

**WAL e group commit.**

- *Domanda:* quanto costa un flush, come scala il group commit, e che cosa succede con molti
  WAL che eseguono flush in parallelo sullo stesso dispositivo?
- *Metodo:* append + flush a lotti su un file; variare dimensione del gruppo e del record;
  ripetere con 1, 4, 16, 64 file concorrenti; confrontare le primitive di flush disponibili;
  confrontare singola e doppia scrittura del record (opzioni di QA-02). Disciplina di
  [ADR-0037](../adr/0037-lotto-sigillato.md): un compito di I/O alla volta per file (scrive i
  lotti chiusi, poi flush), con i lotti che si formano durante il flush.
- *Misure:* durata del flush (distribuzione); operazioni/s durevoli; banda; scalabilità con
  il numero di file.
- *Esito:* dati per decidere QA-02 e QA-05 e per confermare o rivedere il target «INSERT group
  commit». Verifica che flush e scritture siano raggiungibili da Common Lisp senza allocazione.
- *Attenzione:* su macOS il flush ordinario non garantisce la persistenza; le misure di
  durability vanno fatte con la primitiva corretta e ripetute sulla piattaforma di riferimento.

### SPK-04

**Writer logico su thread pool.**

- *Domanda:* qual è il tetto di throughput di un esecutore seriale per Serie su un pool
  condiviso, e come scala con il numero di Serie?
- *Metodo:* code per Serie svuotate a lotti da worker del pool; lavoro seriale sintetico di
  durata controllata; 1…N Serie; carico uniforme e sbilanciato. Secondo
  [ADR-0045](../adr/0045-modello-di-esecuzione.md): tratti del writer a lunghezza limitata,
  lista delle Serie pronte toccata una volta per tratto, letture eseguite dal worker che le
  riceve, parcheggio e ripresa dei client di un lotto; e, per il parallelismo come principio
  fondante ([ADR-0036](../adr/0036-leggi-di-progetto.md), INV-P6), gli elementi dell'elenco
  chiuso (CSN, orizzonte, soglia, epoca) esercitati alla frequenza prevista.
- *Misure:* operazioni/s per Serie e aggregate; costo del passaggio di consegna; latenza in
  coda; equità tra Serie; **throughput aggregato in funzione del numero di Serie e di core**;
  tempo speso su ciascun elemento condiviso; effetto di un burst su una Serie sulle altre.
- *Esito:* conferma che il costo del meccanismo è piccolo rispetto al
  [budget](stime-ordine-di-grandezza.md#budget-del-writer-logico); scalabilità quasi lineare
  con le Serie finché ci sono core; nessun elemento dell'elenco chiuso diventa il collo di
  bottiglia. In caso contrario il risultato indica quale voce rivedere.

### SPK-05

**Percorso di lettura dei segmenti.**

- *Domanda:* come si legge un record da un segmento immutabile senza copiare né allocare, e
  con quale concorrenza di I/O?
- *Metodo:* confronto tra letture posizionali in buffer riutilizzati e mappatura in memoria;
  letture casuali con concorrenza crescente; scansione sequenziale.
- *Misure:* letture/s; latenza; GB/s in scansione; allocazione per lettura; comportamento con
  dataset più grande della RAM.
- *Esito:* scelta della modalità di lettura (QA-19) e della granularità della cache (QA-17);
  conferma o revisione dei target «GET NVMe» e «sequential scan».

### SPK-06

**Interferenza della compaction e controllore di carico.**

- *Domanda:* quanto peggiora la latenza delle richieste mentre un CLEAN o un MERGE è in corso,
  e un controllore semplice basta a contenerla?
- *Metodo:* carico di lettura/scrittura sintetico più copia sequenziale di segmenti a banda
  limitata variabile; simulazione del controllore (stati di carico con isteresi) su tracce.
- *Misure:* P99 con e senza compaction; banda di compaction ottenuta; stabilità del
  controllore.
- *Esito:* valori iniziali per le soglie (QA-11, QA-12); evidenza che il MERGE opportunistico
  non altera il P99.

### SPK-07

**Modelli dei protocolli.**

- *Domanda:* i protocolli rispettano gli invarianti in ogni interleaving e con un crash in
  ogni punto?
- *Metodo:* descrivere come macchine a stati, ed esplorare esaustivamente su configurazioni
  piccole: (1) 2PC con writer non bloccante, `multiserie.log`, recovery; (2) CLEAN/MERGE con
  writer concorrente, swap, reader, snapshot, reclaim. L'esploratore è un programma Common
  Lisp: nessun linguaggio di specifica o strumento di verifica esterno (decisione dell'autore,
  2026-10-03; [ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md)).
- *Modelli aggiuntivi (ADR-0032, ADR-0033):* (3) il protocollo del seqlock a 64 bit con 1
  writer, 2 reader, 2 slot, ogni interleaving e ogni sospensione, compreso il ripiego sul
  writer; (4) l'**idempotenza del recovery**: interruzione del recovery in ogni passo e
  riesecuzione.
- *Modelli dell'analisi progettuale (ADR 0036–0043):* (5) **lotto e frontiera durevole**: più
  lotti chiusi e non sincronizzati, ogni sottoinsieme perso o parziale, e in alternativa un
  danno sotto la frontiera — il recovery conclude «coda» nel primo caso e «corruzione» nel
  secondo, senza mai scrivere nei segmenti; (6) **orizzonte di visibilità**: due Serie, un
  lotto in volo, una multiserie, uno snapshot creato in ogni punto, registrazione dello
  snapshot in gara con una pubblicazione, una Serie che va in `FAULTED` con un CSN in volo;
  (7) **segmenti autosufficienti**: rotazione, CLEAN e rigenerazione dell'hint in ogni punto
  di una multiserie; (8) **tombstone**: eliminazioni, ricreazioni, CLEAN, MERGE di segmenti
  non adiacenti, snapshot, riavvio in ogni punto; (9) divisione di un frammento con reader
  concorrenti; (10) un crash prima e dopo **ogni punto di atomicità** della
  [tabella](../analisi-progettuale.md#punti-di-atomicità).
- *Verifica:* INV-D1, INV-T3, INV-T4, INV-M1, INV-M2, INV-R1, INV-C7, INV-C8, INV-C9, INV-I1,
  INV-A7 negli scenari FI-01…FI-13; in più INV-F2, INV-F3, INV-V5, INV-M4, INV-M5, INV-S7,
  INV-C11, INV-A9, INV-A10, INV-A11.
- *Esito:* nessuna violazione; in caso contrario il controesempio guida la decisione su QA-04,
  QA-06, QA-07, QA-24. I modelli restano come riferimento per i test di fault injection.

> **Deciso (SPK-07 → ADR-0046)** — La prima suite finita è eseguibile in
> [SPK-07-protocols](../../spikes/SPK-07-protocols/README.md). Ha trovato il blocco
> dell'anello dell'orizzonte e verifica il registro limitato che lo sostituisce. Le lacune
> residue sono dichiarate nell'output; SPK-07 non è ancora completo ai fini del gate.

### SPK-08

**SIMD e codice generato.**

- *Domanda:* che cosa produce SBCL per i cicli tipici (operazioni su bitmap, confronto di
  impronte, checksum) sulle architetture di interesse, e quali strumenti SIMD espliciti sono
  disponibili su ciascuna?
- *Metodo:* microbenchmark dei cicli candidati; ispezione del codice generato; verifica del
  supporto SIMD esplicito su x86-64 e ARM64.
- *Esito:* elenco dei cicli dove il codice tipizzato basta e di quelli dove servirebbe un
  intervento; nessuna ottimizzazione viene introdotta in questa fase (INV-X1).

### SPK-09

**Costo dei controlli di affidabilità.**

- *Domanda:* quanto costano, in Common Lisp tipizzato, i controlli che il progetto rende
  obbligatori — CRC32C a ogni lettura, `safety` 2/3, scrubbing — e i minimi di prestazione di
  [ADR-0028](../adr/0028-target-e-obiettivi-di-latenza.md) restano raggiungibili?
- *Metodo:* (a) CRC32C in Lisp: bit a bit, a tabella (byte), *slicing-by-8*, con e senza
  `(safety 3)`, separatamente per l'intestazione (20 byte) e per il corpo; (b) ciclo di
  lettura di un record da 2 KB con verifica dei due CRC, della chiave e del CSN, contro la
  stessa lettura senza verifica; (c) lo stesso ciclo compilato con `safety` 3,
  `safety` 2 con `speed` 3 e (solo come riferimento, mai adottabile) `safety` 0, per
  quantificare il prezzo dei controlli.
- *Misure:* byte/s del CRC per core; ns per record; overhead percentuale per verifica e per
  `safety`; allocazione per operazione (obiettivo: 0).
- *Esito:* i minimi di throughput sono raggiungibili con **tutti** i controlli attivi e
  `safety` ≥ 2. Se non lo sono: si cambia algoritmo (ad esempio slicing-by-8, verifica a
  blocchi) e si registra in un ADR; **non** si rimuove un controllo (ADR-0031 §5).
