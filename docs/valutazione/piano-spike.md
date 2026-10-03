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
- *Metodo:* prototipo di tabella a indirizzamento aperto su array specializzati; carico con
  10⁷–10⁸ entry; un thread scrive, N leggono; ridimensionamento sotto carico; variante con
  tabella laterale delle versioni trattenute (opzione a di QA-24).
- *Misure:* lookup/s per core e aggregati; inserimenti/s; byte per entry; effetto sulle pause
  del GC; correttezza delle letture concorrenti.
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
- *Misure:* distribuzione delle pause (P50, P99, massimo); frequenza; tempo totale in GC;
  latenza delle richieste sintetiche.
- *Esito:* pause entro l'obiettivo numerico di P99 (da fissare con QA-26) nella configurazione
  migliore. In caso contrario: quantificare lo scarto e rivalutare ADR-0001.

### SPK-03

**WAL e group commit.**

- *Domanda:* quanto costa un flush, come scala il group commit, e che cosa succede con molti
  WAL che eseguono flush in parallelo sullo stesso dispositivo?
- *Metodo:* append + flush a lotti su un file; variare dimensione del gruppo e del record;
  ripetere con 1, 4, 16, 64 file concorrenti; confrontare le primitive di flush disponibili;
  confrontare singola e doppia scrittura del record (opzioni di QA-02).
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
  durata controllata; 1…N Serie; carico uniforme e sbilanciato.
- *Misure:* operazioni/s per Serie e aggregate; costo del passaggio di consegna; latenza in
  coda; equità tra Serie.
- *Esito:* conferma che il costo del meccanismo è piccolo rispetto al
  [budget](stime-ordine-di-grandezza.md#budget-del-writer-logico); scalabilità quasi lineare
  con le Serie finché ci sono core.

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
  Lisp.
- *Modelli aggiuntivi (ADR-0032, ADR-0033):* (3) il protocollo del seqlock a 64 bit con 1
  writer, 2 reader, 2 slot, ogni interleaving e ogni sospensione, compreso il ripiego sul
  writer; (4) l'**idempotenza del recovery**: interruzione del recovery in ogni passo e
  riesecuzione.
- *Verifica:* INV-D1, INV-T3, INV-T4, INV-M1, INV-M2, INV-R1, INV-C7, INV-C8, INV-C9, INV-I1,
  INV-A7 negli scenari FI-01…FI-13.
- *Esito:* nessuna violazione; in caso contrario il controesempio guida la decisione su QA-04,
  QA-06, QA-07, QA-24. I modelli restano come riferimento per i test di fault injection.

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
  `(safety 3)`; (b) ciclo di lettura di un record da 2 KB con verifica di CRC, chiave, versione
  e CSN, contro la stessa lettura senza verifica; (c) lo stesso ciclo compilato con `safety` 3,
  `safety` 2 con `speed` 3 e (solo come riferimento, mai adottabile) `safety` 0, per
  quantificare il prezzo dei controlli.
- *Misure:* byte/s del CRC per core; ns per record; overhead percentuale per verifica e per
  `safety`; allocazione per operazione (obiettivo: 0).
- *Esito:* i minimi di throughput sono raggiungibili con **tutti** i controlli attivi e
  `safety` ≥ 2. Se non lo sono: si cambia algoritmo (ad esempio slicing-by-8, verifica a
  blocchi) e si registra in un ADR; **non** si rimuove un controllo (ADR-0031 §5).

