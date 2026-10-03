# Architettura di ArcDocDB

> Documento consolidato del progetto, risultato della Fase 0. Riunisce le decisioni della
> [specifica](specifica/prompt-originale.md) e degli [ADR](adr/README.md) in un'unica
> descrizione coerente, dopo l'[analisi progettuale](analisi-progettuale.md) del 2026-10-03
> (ADR 0036–0045). In caso di dubbio prevalgono specifica e ADR; questo documento li cita. I
> formati persistenti sono in [formati-su-disco.md](formati-su-disco.md).

## In una pagina

ArcDocDB è un database documentale **log-structured** e **parallelo per costruzione**: le
Serie sono unità indipendenti che non si attendono mai; ogni Serie scrive i record una sola
volta, in **lotti sigillati**, nel suo segmento `ACTIVE`; un **indice primario compatto in
memoria** mappa `_id` alla posizione della versione corrente; i segmenti chiusi sono
**immutabili** e si interpretano da soli; la **compaction** copia ciò che serve in segmenti
nuovi e non tocca mai i vecchi. La concorrenza è **un writer per Serie, reader senza lock**;
la visibilità è governata da un **numero di sequenza di commit (CSN)** per Archivio, che è
anche la versione di ogni documento; le transazioni multiserie usano un **2PC** con decision
log unico. Ogni cambiamento durevole ha **un solo punto di atomicità**. Tutto è Common Lisp su
SBCL, senza allocazioni sui percorsi caldi.

```
                 Motore (libreria) dentro il Server (processo SBCL)
 ┌─────────────────────────────────────────────────────────────────────┐
 │ Protocollo (TCP, frame CBOR)    Scheduler · pool di calcolo · pool I/O│
 │                                                                      │
 │  Archivio ─ CSN ─ orizzonte ─ coordinatore ─ Registri/multiserie.log │
 │   │                                                                  │
 │   ├── Serie A ── coda ─▶ writer A ─▶ ACTIVE A ──▶ CLOSED… (immutabili)│
 │   │                │        │  (lotti sigillati)     │               │
 │   │                │   indice A (RAM, a frammenti)  hint/idx per seg.│
 │   │              reader ◀── cache A ◀─────── pread ◀┘                │
 │   ├── Serie B …                                                      │
 │   └── Registri (catalogo = Serie)                                    │
 │                                                                      │
 │  Compaction Scheduler ─ worker CLEAN/MERGE ─ EBR ─ reclaim           │
 └─────────────────────────────────────────────────────────────────────┘
```

## Leggi

Dieci leggi da cui discende ogni meccanismo ([ADR-0036](adr/0036-leggi-di-progetto.md),
[analisi](analisi-progettuale.md#le-leggi)):

1. **Il parallelismo è fondante**: unità che non si attendono; ciò che è condiviso è un
   elenco chiuso, mai pagato per operazione.
2. **Si scrive una volta.** Nessun byte scritto si modifica; il recovery non tronca.
3. **Un solo scrittore** per ogni stato; gli altri propongono.
4. **Un punto di atomicità per operazione**: un record durevole decide.
5. **Prepara, decidi, completa**: `.tmp`, poi il record, poi il file system.
6. **Nulla si distrugge per assenza.**
7. **In sospeso → durevole → pubblicata → confermata.**
8. **Il CSN è l'unico ordine e l'unico nome di una versione.**
9. **Verifica prima di fidarti, e dichiara.**
10. **Tutto è limitato; chi governa non decide.**

| Operazione | Punto di atomicità |
|---|---|
| scrittura single-Series | SEAL del lotto, durevole |
| transazione multiserie | DECISION in `multiserie.log`, durevole |
| rotazione, CLEAN, MERGE | EDIT nel control log, durevole |
| recovery di una Serie | rinomina del control log compattato |
| creazione / eliminazione di una Serie | documento nel catalogo (`active` / `dropping`) |

## Parallelismo

Il parallelismo è il **principio fondante** dell'architettura (legge 1, INV-P6): non si
aggiunge a un sistema seriale, è il modo in cui lo stato è diviso. L'unità di parallelismo
coincide con l'unità di proprietà dello stato, quindi la stessa divisione dà la correttezza
(un solo scrittore) e il parallelismo.

| Livello | Unità | Procede in parallelo | Resta seriale |
|---|---|---|---|
| Server | Archivio | ogni Archivio ha CSN, orizzonte, coordinatore e log propri | nulla |
| Archivio | Serie | scritture, letture, flush, compaction, recovery | l'[elenco chiuso](#archivio-coordinamento-minimo) |
| Serie | reader, writer | i reader tra loro e rispetto al writer, senza lock | le mutazioni: un writer |
| Scrittura | richiesta | parsing, validazione, codifica, CRC del corpo | versione, copia, sigillo: nel writer |
| Log | lotto | i flush di log diversi; i lotti si formano durante il flush | un compito di I/O per log |
| Compaction | segmento | CLEAN e MERGE su segmenti e Serie diversi | EDIT e rilocazioni: nel writer |
| Recovery | Serie, segmento | le Serie; gli hint in qualsiasi ordine | nulla |
| Query | segmento | gli indici dei segmenti | nulla |
| Indice | frammento | la divisione non ferma reader né altri frammenti | la divisione: nel writer |

Regole che ne discendono:

- tra Serie **nessun lock e nessuna scrittura condivisa per operazione**; ciò che è condiviso
  è nell'elenco chiuso di [Archivio: coordinamento minimo](#archivio-coordinamento-minimo);
- ogni meccanismo dichiara che cosa rende seriale e a quale livello; a parità di garanzie
  vince chi serializza meno e più in basso;
- la distribuzione del lavoro non è un punto seriale: una lettura è eseguita dal worker che
  la riceve, senza coda comune; una scrittura entra nella coda della **propria** Serie; la
  lista delle Serie con lavoro pronto è toccata una volta per tratto del writer, non per
  operazione ([ADR-0045](adr/0045-modello-di-esecuzione.md)).

## Modello logico

`Server → Archivio → Serie → Documento` ([02](02-modello-logico.md)). La Serie è l'unità di
storage, parallelismo e isolamento. L'Archivio è l'ambito di CSN, snapshot, transazioni
multiserie e catalogo.

### Archivio e Registri

- **Registri è una Serie** con configurazione incorporata; ogni Serie dell'Archivio è un
  documento del catalogo, identificato da un id stabile a 16 byte che dà il nome alla sua
  directory ([ADR-0022](adr/0022-registri-come-serie-catalogo.md)). Creazione ed eliminazione
  seguono «prepara, decidi, completa» ([ADR-0040](adr/0040-manifest-a-record-unico.md) §5).
- L'Archivio possiede: il contatore **CSN** e l'**orizzonte di visibilità**, il registro degli
  **snapshot attivi**, il **coordinatore** e `multiserie.log`, l'**epoca** per il reclaim.

### Layout fisico

```
Archivio/
├── LOCK
├── Registri/
│   ├── catalog/                 ← storage della Serie Registri
│   │   ├── wal/control.log
│   │   ├── segments/<id>.seg|.hint|.<idx>.idx
│   │   └── index/               ← riservato (indici riassuntivi futuri)
│   └── multiserie.log
├── 0f3a…c2/                     ← Serie (id interno; il nome è nel catalogo)
│   ├── wal/control.log
│   ├── segments/
│   └── index/
└── …
```

## Memoria

Tutte le strutture grandi sono array specializzati senza puntatori; i percorsi caldi non
allocano ([ADR-0024](adr/0024-memoria-e-gc.md)). L'indice cresce un frammento alla volta
([ADR-0043](adr/0043-primary-index-a-frammenti.md)).

| Struttura | Per | Contenuto | Crescita |
|---|---|---|---|
| Primary index | Serie | directory + frammenti (byte di controllo, 4 parole/slot, chiavi locali) | divisione di un frammento |
| Versioni trattenute | Serie | stessa tabella, slot a 5 parole: versioni ancora visibili a uno snapshot | solo con snapshot attivi |
| Versioni in sospeso | Serie | stessa tabella, solo del writer: lotti non pubblicati e intenti | limitata |
| Delta indici secondari | Serie | entry dell'`ACTIVE` per ogni indice, array in aggiunta | svuotato alla chiusura |
| Cache | Serie (partizione) | insiemi associativi per classe di dimensione + arena di byte | budget dallo scheduler |
| Buffer dei lotti | Serie | lotto aperto + lotti chiusi non ancora durevoli | limitato in byte |
| Metriche | worker/Serie | contatori padded + istogrammi log-lineari | fisso |
| Epoche | worker | una parola per worker, padded | fisso |
| Orizzonte, registro snapshot | Archivio | anello di parole, array di CSN attivi | fisso |

## Concorrenza

### Modello di esecuzione

**Compiti a completamento** ([ADR-0045](adr/0045-modello-di-esecuzione.md)): ogni unità di
lavoro gira dall'inizio alla fine senza sospendersi. Un'attesa è un **parcheggio** del
contesto della richiesta in una lista limitata (client di un lotto, snapshot in attesa
dell'orizzonte, coordinatori); l'evento atteso accoda un nuovo compito.

### Thread pool

Due pool dinamici ([ADR-0011](adr/0011-thread-pool-dinamico.md),
[ADR-0017](adr/0017-piattaforma-e-io.md)):

- **Pool di calcolo**: richieste, tratti dei writer logici, compaction (parte di calcolo),
  query. Non esegue chiamate bloccanti (INV-P5). Dimensionato dallo scheduler
  (EWMA/AIMD/isteresi) tra `min` e `2 × core`.
- **Pool di I/O**: scritture nei log, flush, letture dai segmenti, rinomine, eliminazioni. Ha
  un tetto, che è anche il limite di concorrenza sul dispositivo.

Il **writer logico** di una Serie è un esecutore seriale: una coda MPSC limitata; il worker
che acquisisce il gettone della Serie elabora un tratto limitato di operazioni e messaggi;
nessun thread dedicato, nessun lock globale ([ADR-0005](adr/0005-writer-logico-per-serie.md)).

### Reclaim

Epoch-based reclamation per le **risorse esterne**: descrittori e file dei segmenti rimossi
([ADR-0016](adr/0016-epoch-based-reclamation.md)). Directory e frammenti dell'indice
sostituiti sono oggetti dello heap: li recupera il collector quando nessun reader li
referenzia. Una sezione di lettura coincide con un compito: può contenere una lettura da
disco, mai rete né attese.

## Percorso di scrittura

```
worker richiesta                  writer logico (tratto)                    pool di I/O
───────────────                   ──────────────────────                    ───────────
parse CBOR, valida contratto,  ─▶ per op: indice + versioni in sospeso,
hash chiave, codifica record,     check expected-version (= CSN) e intenti,
body-crc                          copia nel buffer del lotto aperto,
                                  voce in sospeso, delta indici secondari
                                  ── chiusura del lotto ──
                                  csn ← incf; stamp, header-crc, SEAL   ─▶  write dei lotti chiusi
                                  (passa al lotto successivo)               flush durevole
                                  ◀── «durevole fino a X» in coda ─────────┘
                                  per ogni lotto coperto, in ordine:
                                  trattieni se soglia < csn, pubblica
                                  nell'indice (seqlock), CSN fuori
                                  dall'orizzonte, conferma i client
```

- Il record è scritto **una volta**, nel segmento `ACTIVE` ([ADR-0013](adr/0013-log-structured-segmento-active-come-log.md)).
- Il **lotto sigillato** è atomico; un compito di I/O alla volta per log; conferma dopo la
  pubblicazione ([ADR-0037](adr/0037-lotto-sigillato.md)). Livelli `:async` / `:group` /
  `:strong`: cambia solo il momento di pubblicazione e conferma
  ([ADR-0019](adr/0019-durability-e-group-commit-pipelined.md)).
- Nel writer non c'è lavoro proporzionale ai byte oltre alla copia: il CRC del corpo è
  calcolato dal worker della richiesta ([ADR-0039](adr/0039-cornice-unica-dei-record.md)).
- **Rotazione**: a `target` byte, quando ogni lotto è durevole e pubblicato e la Serie non ha
  intenti pendenti: nuovo segmento `.tmp`, EDIT `{chiude, apre}`, rinomina. Hint e indici del
  segmento chiuso li produce poi un worker ([ADR-0040](adr/0040-manifest-a-record-unico.md)).

## Percorso di lettura

```
GET(serie, _id [, snapshot s])                       compito nel pool di calcolo
  entra epoca
  hash → directory → frammento → gruppo → slot (seqlock) → chiave
  se s dato e csn(entry) > s → versioni trattenute
  location (seg, off, len)
  cache[(seg, off)] → hit: copia, verifica, risposta
                    → miss: la richiesta migra al pool di I/O e riparte dall'inizio:
                            indice → cache → pread → verifica → inserimento → risposta
  esci epoca
```

Nessuna allocazione; nessun lock. La cache è per location, non si invalida mai e non
partecipa ad alcun protocollo ([ADR-0025](adr/0025-cache-per-location.md),
[ADR-0044](adr/0044-cache-acceleratore-puro.md)). Ogni record è verificato prima di uscire,
da disco o da cache (INV-A2).

## Primary index

Directory a hashing estendibile di **frammenti**; ogni frammento è una tabella Swiss di
capacità fissa con le proprie chiavi; un writer, reader senza lock con seqlock per slot
([ADR-0043](adr/0043-primary-index-a-frammenti.md), [ADR-0032](adr/0032-seqlock-a-64-bit.md)).
Contiene **solo documenti vivi** ([ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md)).

Slot (4 parole + 1 byte di controllo = 33 B):

| Parola | Contenuto |
|---|---|
| 0 | CSN = versione |
| 1 | segment-id (32) · offset (32) |
| 2 | key-off (24) · key-len (8) · lunghezza del record (24) · flag (8) |
| 3 | contatore seqlock (64) |

Persistenza: l'indice è un dato derivato; si ricostruisce dagli hint dei segmenti chiusi, in
qualsiasi ordine, scegliendo per ogni chiave il CSN massimo. I limiti che discendono dal
layout sono in [limiti.md](limiti.md).

## Indici secondari

Un file immutabile a formato fisso per segmento e per indice, con filtro di esistenza sui
valori; delta in memoria (array in aggiunta) per l'`ACTIVE`; query per segmento in parallelo
con filtro di visibilità sul primary index: una riga è un risultato se il suo CSN è quello che
il lettore vede ([ADR-0026](adr/0026-indici-secondari-segmentati.md)).

## Snapshot e MVCC

- **CSN** per Archivio, preso alla chiusura del lotto o della decisione; per ogni documento
  l'ordine dei CSN è l'ordine delle versioni (INV-M5).
- **Orizzonte di visibilità** `H`: il più grande CSN sotto il quale tutto è pubblicato. Uno
  snapshot è un numero `s` e nasce quando `H ≥ s` (INV-M4): la sua vista non può cambiare.
- **Versioni trattenute** per i documenti sovrascritti mentre uno snapshot ne ha bisogno,
  decise con la `soglia` del registro degli snapshot.
- `snapshot-too-old` oltre la durata massima; livelli: read committed per GET, snapshot
  isolation per le transazioni, `:serializable` opzionale con validazione del read-set.

([ADR-0038](adr/0038-orizzonte-di-visibilita.md), [ADR-0020](adr/0020-csn-snapshot-isolamento.md))

## Transazioni

### Single-Series

Operazioni con expected-version (un CSN) eseguite dal writer nel lotto; conflitto →
`conflict`; il lotto è atomico; un CSN per lotto ([ADR-0005](adr/0005-writer-logico-per-serie.md),
[ADR-0037](adr/0037-lotto-sigillato.md)).

### Transazioni multiserie

```
coordinatore            writer A                 writer B              multiserie.log
    │ PREPARE ─────────▶ check, record prepared
    │                    nel lotto, intenti, flush
    │ PREPARE ─────────────────────────────────▶ (idem)
    │ ◀ prepared ─────── │                        │
    │ ◀ prepared ─────────────────────────────────┘
    │ DECISION(T) ──────────────────────────────────────────────────▶ lotto: csn ← incf; flush
    │ ◀ durevole ───────────────────────────────────────────────────┘      (T è committed)
    │ OUTCOME(T, csn) ─▶ pubblica, toglie intenti,
    │                    record OUTCOME nel lotto
    │ OUTCOME(T, csn) ─────────────────────────▶ (idem)
    │ ◀ applicato ────── │ ◀ applicato ──────────┘
    │ csn fuori dall'orizzonte; conferma al client
    │ ◀ esito durevole (tutti) → T dimenticabile
```

Writer mai bloccato; intenti senza attesa; *presumed abort* (un abort non scrive nulla);
segmenti autosufficienti: la rotazione attende gli intenti pendenti, quindi l'esito di ogni
record prepared sta nel suo stesso segmento ([ADR-0021](adr/0021-2pc-intenti-outcome.md),
[ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md)).

## Compaction

- Selezione per spazio morto (CLEAN) o numero di segmenti piccoli stabili da ≥ 50 s (MERGE),
  con stato di carico `{basso, normale, alto}` e limitatore di banda per worker
  ([ADR-0023](adr/0023-politiche-di-compaction.md)).
- Workflow copy-on-write: lettura sequenziale dei sorgenti → copia dei record **necessari**
  (puntati dall'indice, puntati dalle versioni trattenute, tombstone non scartabili), con i
  record prepared riscritti come record ordinari → `<id>.seg.tmp` con hint e indici, durevole
  → **EDIT** `{chiude: output, rimuove: sorgenti}` → rinomina → rilocazioni condizionali
  tramite il writer → sorgenti `OBSOLETE` → epoca superata → `RECLAIMABLE` → eliminazione
  ([ADR-0040](adr/0040-manifest-a-record-unico.md)).
- Un **tombstone** si scarta solo se è superato da una versione più recente o se nessun altro
  segmento può contenere un record più vecchio della stessa chiave (filtro di esistenza negli
  hint) ([ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md)).
- Parallela per segmento e per Serie; i reader non si fermano mai.

## Archivio: coordinamento minimo

Ciò che le Serie condividono, e il suo costo. L'elenco è **chiuso** (INV-P6): nessuna voce è
pagata per singola operazione con una scrittura condivisa, e aggiungerne una richiede un ADR.

| Elemento condiviso | Quando si paga | Costo |
|---|---|---|
| CSN | per lotto (single-Series) o per decisione (multiserie) | un incremento atomico |
| Orizzonte | per lotto pubblicato | un passaggio sotto mutex; nessun costo per i reader |
| Nascita di uno snapshot | per snapshot | attesa che l'orizzonte raggiunga lo snapshot: al più i flush in corso nell'Archivio, con tempo massimo. È l'unico punto in cui una Serie può ritardarne un'altra, a tutela di INV-M1 |
| Registro snapshot | per snapshot; per lotto pubblicato | creazione/chiusura sotto mutex; una lettura di `soglia` per lotto |
| Epoca | per compito di lettura | una lettura condivisa e una scrittura **locale** al worker |
| `multiserie.log` | per transazione multiserie | group commit |
| Catalogo (Registri) | per creazione, modifica, eliminazione di una Serie | una scrittura in Registri |
| Lista delle Serie pronte | per tratto del writer | un'operazione sulla lista |
| Scheduler, metriche | fuori dal percorso delle richieste | contatori per worker e per Serie, aggregati in lettura |

Condivisi dall'intero processo e non eliminabili, quindi **governati**: il dispositivo
(priorità INV-P4, limitatore di banda, tetto del pool di I/O), i worker (pool dinamici) e il
garbage collector, che ferma ogni thread (nessuna allocazione sui percorsi caldi, RSK-01).

## Recovery

Sola lettura sui segmenti; idempotente perché ogni effetto è un punto di atomicità o un
completamento ([11](11-recovery.md), [ADR-0036](adr/0036-leggi-di-progetto.md)):

1. Lock esclusivo sull'Archivio. Registri: come ogni Serie (passo 3), per prima.
2. `multiserie.log` → tabella delle decisioni; coda secondo la regola della frontiera.
3. Per ogni Serie del catalogo, in parallelo:
   - ripiegamento del control log; riconciliazione con la directory (`.tmp` non nominati
     eliminati, nominati rinominati, rimossi eliminati, sconosciuti segnalati, mancanti in
     quarantena);
   - validazione dell'`ACTIVE` lotto per lotto; coda o corruzione con la frontiera durevole
     ([ADR-0037](adr/0037-lotto-sigillato.md) §3);
   - indice dagli hint dei `CLOSED` e dai lotti validi dell'`ACTIVE`: per ogni chiave vince
     il CSN massimo; record prepared risolti con OUTCOME, manifest o tabella delle decisioni;
   - **punto di atomicità**: control log compattato che chiude il vecchio `ACTIVE` alla
     lunghezza valida, con gli esiti, e apre il nuovo; rinomina.
4. CSN = massimo osservato + 1; orizzonte = CSN − 1; stabilizzazione dei segmenti = fine
   recovery; `multiserie.log` riscritto con le sole decisioni di Serie non aperte.
5. Apertura al traffico. Hint e indici mancanti si rigenerano in background.

## Affidabilità

Il progetto è software critico ([ADR-0031](adr/0031-software-critico-criteri-e-priorita.md)); le
prestazioni sono subordinate. Ciò che questo significa nell'architettura:

| Aspetto | Meccanismo | Riferimento |
|---|---|---|
| Stati di salute | Serie `HEALTHY`/`DEGRADED`/`FAULTED`; Archivio `HEALTHY`/`MULTI-DISABLED`/`FAULTED` | [ADR-0033](adr/0033-fail-stop-e-integrita-end-to-end.md) |
| Errori di I/O | fail-stop, mai retry; riserva di spazio contro `ENOSPC` | ADR-0033 §2 |
| Verifica | due CRC32C e confronto con l'indice a ogni lettura, da disco e da cache | ADR-0033 §3, [ADR-0039](adr/0039-cornice-unica-dei-record.md) §4 |
| Coda o corruzione | frontiera durevole nei SEAL: decidibile dal contenuto | [ADR-0037](adr/0037-lotto-sigillato.md) §3 |
| Recovery | non distruttivo, idempotente, un punto di atomicità | [ADR-0036](adr/0036-leggi-di-progetto.md) |
| Distruzione | solo `.tmp` o rimozioni registrate; mai per assenza | ADR-0036 §3 |
| Rilevamento latente | scrubbing entro 7 giorni; verificatore offline | ADR-0033 §6–7 |
| Codice | `safety` ≥ 2, nessun avviso, divieti, linter | [ADR-0034](adr/0034-policy-di-compilazione-e-standard-di-codifica.md) |
| Concorrenza | seqlock a 64 bit con tentativi limitati e ripiego sul writer; una sola tabella concorrente | [ADR-0032](adr/0032-seqlock-a-64-bit.md), [ADR-0043](adr/0043-primary-index-a-frammenti.md) |
| Verifica del sistema | modelli, simulatore, fault injection, differenziale, fuzzing, mutazione | [ADR-0035](adr/0035-strategia-di-verifica-e-tracciabilita.md) |
| Tracciabilità | requisiti, matrice generata, `make trace` | [tracciabilità](tracciabilita/README.md) |

Analisi completa dei guasti e delle risposte: [affidabilita/analisi-dei-guasti.md](affidabilita/analisi-dei-guasti.md).

## Scheduler e osservabilità

Metriche per worker e per Serie, istogrammi log-lineari, senza allocazione; lo scheduler
legge valori EWMA per: numero di worker di calcolo e di I/O, budget della cache per Serie,
stato di carico, banda e concorrenza della compaction ([12](12-osservabilita.md)). Lo
scheduler sceglie numeri dentro intervalli verificati: non può cambiare un dato (classe C3).

## Interfacce

Il motore è una **libreria** con interfaccia «richiesta più continuazione»; il server è un
guscio che la espone con un protocollo a frame CBOR su TCP con multiplexing; query come dati;
contratto della Serie nel catalogo con evoluzione additiva
([ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md),
[ADR-0045](adr/0045-modello-di-esecuzione.md)).

## Contratti

Regole di interfaccia tra moduli ([16](16-moduli.md)), derivate dagli ADR:

1. **Nessuna allocazione** nelle API dei percorsi caldi: ingressi come `(array start end)`,
   uscite in buffer del chiamante; i codici di esito sono valori immediati.
2. **Chi muta una Serie è il suo writer**: ogni modifica a indice, versioni in sospeso e
   trattenute, delta, contatori e control log passa dalla coda del writer. Compaction e
   coordinatore *propongono* (rilocazioni, OUTCOME); il writer *applica*.
3. **Chi legge sta in un'epoca** per la durata del suo compito, senza rete né attese.
4. **Tutto l'I/O passa dal modulo `io`**, sostituibile in test, ed è eseguito dal pool di I/O.
5. **Ogni file persistente** ha magic, versione e CRC32C; ogni log è una sequenza di lotti
   sigillati con la stessa cornice di record (INV-F1, INV-F2).
6. **Ogni dato derivato dichiara la propria fonte** e ha una procedura di ricostruzione.
7. **Tempo, casualità, schedulazione e I/O passano da interfacce iniettabili**
   ([ADR-0035](adr/0035-strategia-di-verifica-e-tracciabilita.md)): in test il sistema intero
   gira in un simulatore deterministico riproducibile da seme.
8. **Un dato non verificato non lascia il motore** (INV-A2): ogni record letto è controllato
   (CRC dell'intestazione e del corpo, chiave, CSN) prima di essere restituito.
9. **Un errore di scrittura o di flush è fatale per la Serie** (INV-A1) e non è mai ritentato.
10. **Nessun ciclo e nessuna attesa illimitati** (INV-A8); ogni risorsa ha un limite
    controllato.
11. **Nessun compito si sospende** (INV-P5): un'attesa è un parcheggio in una lista limitata;
    le interfacce sono «richiesta più continuazione».
12. **Ogni operazione durevole dichiara il suo punto di atomicità**, la sua preparazione e il
    suo completamento (INV-A11); nulla si elimina senza un record che lo dica (INV-A10).
13. **Ogni modulo dichiara che cosa condivide tra Serie**: nulla, oppure una voce
    dell'elenco chiuso; mai una scrittura condivisa per operazione (INV-P6).

## Moduli

Corrispondenza con i 18 moduli della specifica in [16-moduli.md](16-moduli.md); gli ADR
indicano per ciascuno il meccanismo. Package: `arcdocdb.<modulo>`; moduli di supporto `io` e
`metrics`.

## Che cosa resta da misurare

Le decisioni sono prese; cinque ipotesi quantitative restano da verificare con gli spike prima
della Fase 1 ([valutazione](valutazione/README.md#rivalutazione-2026-10-03)):

1. pause del GC con heap grande, allocazione nulla e numero di thread crescente (SPK-02,
   criterio ≤ 5 ms);
2. throughput, memoria per documento e correttezza del primary index a frammenti (SPK-01);
3. latenza e scalabilità di un flush alla volta per Serie, con molte Serie (SPK-03), e
   scalabilità dell'insieme con il numero di Serie e di core (SPK-04);
4. costo dei controlli di affidabilità, CRC in lettura e `safety` ≥ 2 (SPK-09);
5. modello dei protocolli — lotto e frontiera, orizzonte, 2PC, swap, recovery — senza
   violazioni (SPK-07).
