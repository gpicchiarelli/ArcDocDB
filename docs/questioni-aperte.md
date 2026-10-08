# Questioni aperte

Punti che la [specifica](specifica/specifica-originale.md) non decide. Chiuderli è il lavoro
principale della [Fase 0](roadmap.md). Ogni questione si chiude con un ADR; la voce resta qui,
marcata «Risolta da ADR-nnnn».

**Stato al 2026-10-03: tutte le questioni sono chiuse da un ADR** (vedi colonna *Stato*).
L'[analisi progettuale](analisi-progettuale.md) ha poi rivisto alcune risposte con gli ADR
0036–0045: la colonna *Stato* indica la decisione originaria e quella che la rivede.
ADR-0028 e ADR-0030 sono stati confermati dall'autore il 2026-10-08. La valutazione
sperimentale ha corretto il registro dell'orizzonte con ADR-0046. Le sezioni di dettaglio sotto conservano le opzioni valutate e la
motivazione della scelta è nell'ADR.

**Priorità**

- **A** — architetturale: va decisa in Fase 0, perché condiziona formati su disco o più moduli.
- **B** — va decisa prima di implementare il modulo interessato.
- **C** — differibile.

## Quadro

| ID | Questione | Priorità | Stato | Spike | Rischi |
|---|---|---|---|---|---|
| [QA-01](#qa-01) | Formato di documento e record | A | Risolta da [ADR-0014](adr/0014-formato-record-documento-id.md); record rivisto da [ADR-0039](adr/0039-cornice-unica-dei-record.md) | — | — |
| [QA-02](#qa-02) | Rapporto WAL ↔ segmenti | A | Risolta da [ADR-0013](adr/0013-log-structured-segmento-active-come-log.md) (emenda la specifica) | SPK-03 | RSK-03 |
| [QA-03](#qa-03) | Persistenza del primary index | A | Risolta da [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md); hint rivisto da [ADR-0039](adr/0039-cornice-unica-dei-record.md) | SPK-01 | RSK-07 |
| [QA-04](#qa-04) | Manifest dei segmenti e atomic swap | A | Risolta da [ADR-0018](adr/0018-control-log-manifest-swap.md); rivista da [ADR-0040](adr/0040-manifest-a-record-unico.md) | SPK-07 | RSK-02 |
| [QA-05](#qa-05) | Livelli di durability | A | Risolta da [ADR-0019](adr/0019-durability-e-group-commit-pipelined.md); meccanica rivista da [ADR-0037](adr/0037-lotto-sigillato.md) | SPK-03 | — |
| [QA-06](#qa-06) | TXID, ordine di commit di Archivio, snapshot multiserie | A | Risolta da [ADR-0020](adr/0020-csn-snapshot-isolamento.md); rivista da [ADR-0038](adr/0038-orizzonte-di-visibilita.md) | SPK-07 | RSK-05 |
| [QA-07](#qa-07) | Stato PREPARED: visibilità e blocco | A | Risolta da [ADR-0021](adr/0021-2pc-intenti-outcome.md); rivista da [ADR-0041](adr/0041-multiserie-segmenti-autosufficienti.md) | SPK-07 | RSK-05 |
| [QA-08](#qa-08) | Troncamento di `multiserie.log` | B | Risolta da [ADR-0021](adr/0021-2pc-intenti-outcome.md) | — | RSK-06 |
| [QA-09](#qa-09) | Livelli di isolamento | A | Risolta da [ADR-0020](adr/0020-csn-snapshot-isolamento.md) | SPK-07 | — |
| [QA-10](#qa-10) | Natura fisica di Registri e del catalogo | B | Risolta da [ADR-0022](adr/0022-registri-come-serie-catalogo.md); DDL rivisto da [ADR-0040](adr/0040-manifest-a-record-unico.md) | — | RSK-15 |
| [QA-11](#qa-11) | Soglie di CLEAN e MERGE | C | Risolta da [ADR-0023](adr/0023-politiche-di-compaction.md) | SPK-06 | — |
| [QA-12](#qa-12) | Definizione di basso carico; preemption e starvation del MERGE | B | Risolta da [ADR-0023](adr/0023-politiche-di-compaction.md) | SPK-06 | RSK-08, RSK-12 |
| [QA-13](#qa-13) | Timestamp di stabilizzazione | B | Risolta da [ADR-0018](adr/0018-control-log-manifest-swap.md) | — | — |
| [QA-14](#qa-14) | Snapshot longevi | B | Risolta da [ADR-0020](adr/0020-csn-snapshot-isolamento.md) | — | RSK-09 |
| [QA-15](#qa-15) | Vita dei tombstone | B | Risolta da [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) (sostituisce la regola di ADR-0023) | — | — |
| [QA-16](#qa-16) | Tracciamento dei reader per il reclaim | B | Risolta da [ADR-0016](adr/0016-epoch-based-reclamation.md) | SPK-01 | — |
| [QA-17](#qa-17) | Granularità e chiave della cache | B | Risolta da [ADR-0025](adr/0025-cache-per-location.md); rivista da [ADR-0044](adr/0044-cache-acceleratore-puro.md) | SPK-05 | RSK-10 |
| [QA-18](#qa-18) | GC di SBCL e memoria fuori heap | A | Risolta da [ADR-0024](adr/0024-memoria-e-gc.md) (ipotesi verificata da SPK-02) | SPK-02 | RSK-01 |
| [QA-19](#qa-19) | Piattaforma di riferimento e primitive di I/O | A | Risolta da [ADR-0017](adr/0017-piattaforma-e-io.md); precisata da [ADR-0045](adr/0045-modello-di-esecuzione.md) | SPK-03, SPK-05 | RSK-11 |
| [QA-20](#qa-20) | Protocollo di rete e linguaggio di query | C | Risolta da [ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md) | — | — |
| [QA-21](#qa-21) | Schema/contratto della Serie | C | Risolta da [ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md) | — | — |
| [QA-22](#qa-22) | Dipendenze e framework di test | B | Risolta da [ADR-0027](adr/0027-dipendenze-e-test.md) | — | — |
| [QA-23](#qa-23) | Funzioni fuori dallo scope v1 | C | Risolta da [ADR-0030](adr/0030-scope-v1.md), confermata il 2026-10-08 | — | RSK-14 |
| [QA-24](#qa-24) | Primary index: MVCC, concorrenza, rilocazione | A | Risolta da [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md); struttura rivista da [ADR-0043](adr/0043-primary-index-a-frammenti.md) | SPK-01, SPK-07 | RSK-02 |
| [QA-25](#qa-25) | Indici secondari: sincronia, snapshot, persistenza | B | Risolta da [ADR-0026](adr/0026-indici-secondari-segmentati.md) | — | RSK-13 |
| [QA-26](#qa-26) | Target: per Serie o aggregati; obiettivi numerici di latenza | A | Risolta da [ADR-0028](adr/0028-target-e-obiettivi-di-latenza.md), confermata il 2026-10-08 | — | RSK-04 |

---

## Dati e formati

### QA-01

**Formato di documento e record.** La specifica non definisce il formato del documento, il
tipo di `_id` né la codifica dei record nei segmenti e nel WAL.

- *Da decidere:* rappresentazione del documento (testo tipo JSON, binario proprio, bytes
  opachi + schema); `_id` a lunghezza fissa o arbitraria; intestazione del record (lunghezza,
  checksum, versione, TXID, flag tombstone).
- *Orientamento:* record binario con lunghezza e checksum in testa, leggibile in sequenza
  senza indice (serve a scansioni, CLEAN e recovery). `_id` a lunghezza fissa semplifica molto
  il primary index compatto (QA-24).
- *Condiziona:* M02, M03, M05, M12, M15.

### QA-02

**Rapporto WAL ↔ segmenti.** La specifica prescrive sia un WAL sia i segmenti per ogni Serie,
ma non dice come un record passa dall'uno agli altri né quando il WAL si può troncare.

| Opzione | Descrizione | Pro | Contro |
|---|---|---|---|
| a | Record completo nel WAL e poi nel segmento ACTIVE; WAL troncato a checkpoint | recovery semplice | ogni byte scritto due volte |
| b | Come (a), ma il segmento viene alimentato in differita dal WAL, fuori dal percorso di commit | latenza di commit minima | stessa amplificazione; letture recenti dal WAL |
| c | Dato scritto una sola volta nel segmento ACTIVE; il WAL contiene solo record piccoli (riferimento, checksum, marker transazionali) | una sola scrittura dei dati | due file da sincronizzare a ogni commit |
| d | WAL e segmento ACTIVE coincidono | minima amplificazione | contraddice la separazione prescritta: richiede un ADR che emendi la specifica |

- *Criteri:* amplificazione di scrittura rispetto alla banda NVMe
  ([stime](valutazione/stime-ordine-di-grandezza.md#banda-di-scrittura)), numero di flush per
  commit, complessità del recovery.

### QA-03

**Persistenza del primary index.** L'indice è in RAM; non è detto se e come viene persistito.

| Opzione | Riavvio | Note |
|---|---|---|
| a. Solo RAM, ricostruzione leggendo i segmenti | proporzionale ai dati totali | il più semplice |
| b. File di *hint* per ogni segmento chiuso (elenco compatto `_id`/offset/versione) | proporzionale al numero di documenti | si sposa con i segmenti immutabili: l'hint si scrive una volta |
| c. Checkpoint periodico dell'intera tabella + replay del WAL | proporzionale alle scritture dal checkpoint | checkpoint costoso su tabelle grandi |

- *Orientamento:* (b), eventualmente con (c) in seguito. In ogni caso l'indice resta un dato
  derivato, ricostruibile dai segmenti.

### QA-04

**Manifest dei segmenti e meccanismo dell'atomic swap.** Serve una registrazione autorevole e
atomica di quali segmenti compongono una Serie, per rendere riconoscibile in recovery uno swap
incompleto.

| Opzione | Descrizione |
|---|---|
| a | File manifest per Serie, riscritto per intero in modo atomico (file temporaneo, flush, rename) |
| b | Log di manifest append-only (sequenza di «aggiungi S042, rimuovi S017») |
| c | Record di swap nel WAL della Serie, emessi dal writer logico |

- *Orientamento:* (c) mette lo swap nello stesso ordine totale delle scritture della Serie e
  non introduce un secondo meccanismo di durability; va valutato insieme a QA-24.

---

## Durability e transazioni

### QA-05

**Livelli di durability.** Vanno definiti nomi, semantica, default e granularità.

- *Orientamento:* tre livelli — `async` (conferma prima del flush), `group` (conferma dopo un
  flush condiviso; default), `strong` (flush dedicato). Default per Serie, con possibilità di
  richiesta più forte per singola operazione.
- *Da decidere:* che cosa vuol dire «committed» per INV-D1 con `async`; quale livello vale per
  una transazione multiserie con partecipanti configurati diversamente.

### QA-06

**TXID, ordine di commit di Archivio, snapshot multiserie.** Uno snapshot coerente a livello di
Archivio richiede un riferimento comune tra Serie che per il resto sono indipendenti.

| Opzione | Descrizione | Nota |
|---|---|---|
| a | Numero di sequenza di commit dell'Archivio (contatore atomico), registrato da ogni Serie; snapshot = un numero | un punto condiviso tra Serie, ma è un incremento in memoria, non I/O |
| b | Snapshot = vettore delle posizioni correnti di ogni Serie | nessun contatore condiviso; serve una barriera contro le multiserie a metà applicazione |
| c | Sequenza di Archivio solo per le multiserie, ordine locale per le single-Series | minimizza la condivisione; snapshot più complesso |

- *Requisito comune:* una transazione multiserie deve apparire a uno snapshot **tutta o per
  niente**, anche se i partecipanti la applicano in momenti diversi.

### QA-07

**Stato PREPARED.** Tra PREPARE e decisione un documento ha una modifica pendente.

- *Da decidere:* un GET vede la versione precedente? Una scrittura concorrente sullo stesso
  documento abortisce subito o attende? Uno snapshot creato in quell'intervallo come si
  comporta?
- *Vincolo:* il writer della Serie non può fermarsi ad aspettare la decisione (INV-P3); le
  modifiche pendenti vanno tenute in una struttura a parte finché la decisione non arriva.

### QA-08

**Troncamento di `multiserie.log`.** Il file è unico e persistente, quindi cresce.

- *Orientamento:* una decisione è dimenticabile quando tutti i partecipanti hanno reso
  durevole l'esito nel proprio WAL. Va definito come si compatta un file che deve restare
  unico (riscrittura atomica a checkpoint).

### QA-09

**Livelli di isolamento.** La specifica definisce il conflitto scrittura-scrittura sullo stesso
documento, non il livello di isolamento.

- *Orientamento:* GET semplice = read committed; transazioni = snapshot isolation; eventuale
  serializzabilità come opzione, validando anche le versioni dei documenti letti.

### QA-10

**Natura fisica di Registri.** «Serie speciale» ma con layout proprio (`catalog/`,
`multiserie.log`).

| Opzione | Pro | Contro |
|---|---|---|
| a. Registri è una Serie normale (WAL, segmenti, indice) con configurazione incorporata nel codice; le voci di catalogo sono documenti | catalogo transazionale e crash-safe senza meccanismi nuovi | dipendenza circolare da sciogliere al bootstrap |
| b. Catalogo in formato dedicato, con riscrittura atomica | bootstrap banale | un secondo meccanismo di durability da verificare |

- *Da decidere anche:* se creare una Serie e scrivervi può essere un'unica transazione.

---

## Compaction

### QA-11

**Soglie.** Parametri per Serie da introdurre: quota di spazio morto che attiva il CLEAN;
dimensione sotto cui un segmento è «piccolo»; numero minimo di segmenti piccoli per un MERGE;
dimensione massima dell'output di un MERGE. I valori si determinano con le misure.

### QA-12

**Basso carico, preemption, starvation.**

- *Orientamento:* uno stato di carico discreto (basso / normale / alto) calcolato dallo
  scheduler su segnali smussati, con isteresi; MERGE ammesso solo dopo una permanenza minima
  nello stato basso. Per un MERGE in corso: prima rallentare, poi sospendere, infine
  abbandonare (l'output parziale si scarta senza conseguenze).
- *Da decidere:* se il carico non scende mai, il MERGE non parte mai. È accettato così (con
  metrica e allarme), oppure serve una soglia di emergenza? La seconda ipotesi emenda la
  specifica.

### QA-13

**Timestamp di stabilizzazione.** Per i segmenti del writer è il close time. Per i segmenti
prodotti dalla compaction: orientamento = completamento dello swap. Dopo un riavvio, se i
metadata sono stati ricostruiti: orientamento = far ripartire i 50 s dalla fine del recovery.
Serve un orologio monotono.

### QA-14

**Snapshot longevi.** Trattengono versioni (spazio) e sospendono il MERGE dei segmenti
coinvolti. Opzioni: solo metrica e allarme; durata massima con terminazione forzata dello
snapshot; limite configurabile per Serie.

### QA-15

**Vita dei tombstone.** Un tombstone può essere scartato solo se nessuna versione precedente
dello stesso `_id` esiste ancora in un segmento su disco e nessuno snapshot lo richiede:
altrimenti una ricostruzione dell'indice dai segmenti farebbe «risorgere» il documento.
Dipende da QA-03.

---

## Runtime

### QA-16

**Tracciamento dei reader.** Per il reclaim occorre sapere quando nessun reader usa più un
segmento, senza appesantire le letture. Opzioni: epoch per worker (il reader pubblica l'epoch
in cui è entrato); contatore di riferimenti per segmento (semplice, ma è una scrittura
condivisa a ogni lettura).

### QA-17

**Cache.** Granularità (documento o blocco), chiave (orientamento: location, vedi
[09](09-cache.md)), ripartizione del budget tra Serie, rapporto con la page cache del sistema
operativo, definizione misurabile di scan pollution.

### QA-18

**GC di SBCL e memoria.** Quali strutture vivono nello heap gestito e quali fuori.

- *Da valutare:* costo per il GC di array specializzati molto grandi; memoria esterna allo
  heap per indice e cache; allocazione per richiesta sul hot path (obiettivo: zero);
  parametri e varianti del collector disponibili in SBCL.
- *Vincolo:* solo Common Lisp (INV-X3) — l'accesso a memoria esterna deve passare dalle
  facility di SBCL.

### QA-19

**Piattaforma di riferimento e I/O.** La specifica indica l'hardware, non sistema operativo né
architettura. Lo sviluppo avviene su macOS/ARM64.

- *Da decidere:* piattaforma di riferimento per i benchmark; primitive di flush per piattaforma
  (su macOS `fsync` non garantisce la persistenza su supporto: serve `F_FULLFSYNC`); I/O
  bloccante su worker contro I/O asincrono; lettura dei segmenti con letture posizionali o
  mappatura in memoria.

---

## Interfacce

### QA-20

**Protocollo di rete e linguaggio di query.** Non specificati. Differibili finché il motore non
esiste; l'interfaccia interna del Query Engine va però pensata per non dipendere dal
protocollo.

### QA-21

**Schema/contratto della Serie.** Linguaggio di definizione, validazione, evoluzione dello
schema su dati append-only già scritti.

---

## Progetto

### QA-22

**Dipendenze e test.** Con il vincolo «solo Common Lisp»: sono ammesse librerie Common Lisp di
terze parti, o solo SBCL e i suoi contrib? Quale framework di test? Meno dipendenze significa
più controllo sul hot path e più codice da scrivere.

### QA-23

**Fuori scope v1.** Replica, alta disponibilità, backup/restore, autenticazione e
autorizzazione, cifratura non sono menzionati dalla specifica. Vanno dichiarati esplicitamente
fuori scope oppure aggiunti; alcune (backup, replica) sono favorite dai segmenti immutabili e
conviene non precluderle nei formati.

### QA-24

**Primary index: MVCC, concorrenza, rilocazione.** È la questione architetturale più densa:
tre requisiti insistono sulla stessa struttura.

1. *Scritture continue.* Il writer aggiorna l'indice a ogni commit; una nuova versione
   completa a ogni modifica (INV-I1 letto alla lettera) non è praticabile.
2. *Snapshot.* Uno snapshot deve trovare la location di versioni non più correnti.
3. *Compaction.* Lo swap riloca in blocco molte entry mentre il writer continua a lavorare.

| Opzione | Descrizione | Pro | Contro |
|---|---|---|---|
| a | Tabella compatta mutabile (un writer, reader senza lock) + tabella laterale delle **versioni trattenute**, popolata solo quando il writer sovrascrive un documento mentre esistono snapshot attivi | costo nullo senza snapshot; resta compatta | protocollo di lettura concorrente da verificare |
| b | Indice persistente con condivisione strutturale (ogni commit produce una nuova radice) | snapshot in O(1); INV-I1 alla lettera | molti oggetti con puntatori: contrario al requisito di compattezza e pesante per il GC |
| c | Catena di versioni su disco (ogni record punta al precedente) | nessuna memoria aggiuntiva | letture di versioni vecchie con più I/O; i puntatori si invalidano con la rilocazione |

- *Osservazione sulla rilocazione:* la copia fatta dalla compaction ha contenuto identico
  all'originale, e l'originale resta leggibile finché è `OBSOLETE`. Quindi un reader è corretto
  sia con la vecchia sia con la nuova location: ciò che deve essere atomico e durevole è il
  cambio dell'insieme dei segmenti (QA-04), mentre l'aggiornamento delle entry può essere una
  serie di sostituzioni condizionali («se punta ancora alla vecchia location») eseguite dal
  writer logico.
- *Orientamento:* (a), con INV-I1 interpretato come «un reader non osserva mai uno stato
  intermedio», da confermare con ADR.

### QA-25

**Indici secondari.** Aggiornamento sincrono con il commit o differito? Che cosa vede uno
snapshot attraverso un indice secondario? Persistenza o ricostruzione al riavvio? Costo sul
writer logico della Serie.

### QA-26

**Target.** Solo il target dei GET è dichiarato «aggregato». Va chiarito per ciascun target se
è per singola Serie o sommato, e vanno fissati obiettivi **numerici** di latenza P95/P99: la
specifica chiede «bassa latenza» senza un valore, e senza un valore non si possono valutare né
il GC né la low-load policy.
