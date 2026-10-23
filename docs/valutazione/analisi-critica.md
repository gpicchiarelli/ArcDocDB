# Analisi critica

> Valutazione preliminare. Vedi le [avvertenze](README.md).

## Punti di forza

| # | Scelta | Perché regge |
|---|---|---|
| F1 | Segmenti immutabili + compaction copy-on-write | La crash-safety della compaction è strutturale: fino allo swap il sistema non dipende dall'output, e i sorgenti non vengono mai toccati. Gli stati intermedi sono pochi e riconoscibili. |
| F2 | Serie fisicamente indipendenti | Isolamento del carico, recovery parallelo per Serie, nessun log condiviso sul percorso delle scritture ordinarie. |
| F3 | Un writer logico per Serie | Elimina i lock per documento: il controllo di versione e l'applicazione sono atomici per costruzione (INV-T2). La Serie ha un ordine totale delle modifiche. |
| F4 | CLEAN e MERGE separati | Il recupero di spazio (necessario) non è accoppiato alla deframmentazione (facoltativa). Si evita la compaction a cascata tipica dei sistemi a livelli. |
| F5 | MERGE opportunistico | La manutenzione strutturale non compete con il traffico: favorisce la prevedibilità del P99, che è un obiettivo dichiarato. |
| F6 | Metadata derivati | Contatori errati non possono causare perdita di dati; un solo insieme di fonti di verità (WAL, dati, indice). |
| F7 | Decision log separato dai dati | Le transazioni single-Series non pagano nulla per l'esistenza delle multiserie. |
| F8 | Disciplina sui numeri | Target dichiarati come ipotesi, confronti solo a parità di condizioni, SIMD solo su misura: riduce il rischio di ottimizzare la cosa sbagliata. |
| F9 | Fault injection come requisito | I protocolli nascono per essere interrotti in ogni punto. |

## Tensioni interne alla specifica

Punti in cui due requisiti, presi alla lettera, tirano in direzioni diverse. Non sono errori:
sono i luoghi dove serve una decisione esplicita.

### T1 — Indice immutabile per i reader contro scritture continue

La sezione «Index snapshot» chiede indici immutabili con atomic swap (v17 → v18). Il primary
index riceve una modifica a ogni scrittura, con target fino a milioni di operazioni al
secondo, e deve essere una struttura compatta e contigua. Costruire una nuova versione a ogni
commit è impraticabile; una struttura persistente con condivisione strutturale contraddice il
requisito di compattezza e pesa sul GC.

*Lettura proposta:* il modello «versione + swap» si applica alla lettera agli indici secondari
(base + delta) e alle sostituzioni in blocco; per il primary index il requisito diventa «un
reader non osserva mai uno stato intermedio». → QA-24, RSK-02.

### T2 — WAL e segmenti: due scritture per ogni record?

Ogni Serie ha un WAL *e* segmenti append-only. Se il record completo va in entrambi, ogni byte
è scritto due volte, e la fascia alta dei target di INSERT supera la banda di un dispositivo
([stime](stime-ordine-di-grandezza.md#banda-di-scrittura)). Se va in uno solo, cambia il ruolo
dell'altro. → QA-02, RSK-03.

### T3 — «Atomic index swap» mentre il writer lavora

Durante un CLEAN il writer della Serie continua a ricevere scritture. Un documento già copiato
nel nuovo segmento può essere aggiornato prima dello swap: la copia è nata `LIVE` ed è
diventata `DEAD`. Lo swap non può quindi essere una sostituzione cieca dell'indice.

*Osservazione:* la copia è identica all'originale e l'originale resta leggibile finché
`OBSOLETE`; per un reader le due location sono equivalenti. L'atomicità serve davvero in un
punto solo — il cambio dell'insieme dei segmenti validi — mentre le entry dell'indice si
possono aggiornare con sostituzioni condizionali. Questo semplifica molto il problema, ma va
verificato su modello. → QA-04, QA-24.

### T4 — Writer che non si ferma contro 2PC che aspetta

Nel 2PC un partecipante, dopo il PREPARE, attende la decisione. Ma il writer logico è l'unico
flusso di scrittura della Serie: se attendesse, tutte le scritture della Serie si fermerebbero
per la durata di un flush di `multiserie.log`, e una Serie coinvolta in molte multiserie
diventerebbe un collo di bottiglia per le altre (contro INV-P3). Il writer deve proseguire,
tenendo da parte le modifiche pendenti; questo introduce uno stato in più per documento. → QA-07.

### T5 — Serie indipendenti contro snapshot coerente di Archivio

L'indipendenza delle Serie significa nessun ordine comune tra i loro commit. Uno snapshot
multiserie coerente ne richiede uno, almeno per le transazioni multiserie, che devono apparire
tutte o per niente. Qualsiasi soluzione introduce un elemento condiviso a livello di Archivio;
la domanda è quanto leggero. Va inoltre deciso che cosa garantiscono due GET semplici
successivi su Serie diverse durante l'applicazione di una multiserie. → QA-06, QA-09.

### T6 — MERGE vietato su segmenti necessari a uno snapshot

Il MERGE è copy-on-write e i sorgenti restano leggibili fino al reclaim: dal punto di vista
della correttezza potrebbe procedere anche con snapshot attivi (come fa il CLEAN, che copia le
versioni `SNAPSHOT-LIVE`). La specifica invece lo vieta. È una scelta prudente e coerente con
la natura opportunistica del MERGE, ma ha una conseguenza: uno snapshot longevo sospende la
deframmentazione oltre a trattenere spazio. → QA-14, RSK-09.

### T7 — MERGE solo a basso carico contro carico sostenuto

Se il motore non scende mai sotto la soglia di basso carico, il MERGE non parte mai e i
segmenti piccoli si accumulano. La specifica lo accetta («può rimanere piccolo
indefinitamente»), ma il costo di molti segmenti piccoli (file aperti, metadata, località)
cresce senza un limite dichiarato. → QA-12, RSK-08.

### T8 — Metadata derivati contro regola dei 50 secondi

Il close time è il riferimento per i 50 s, ma i metadata sono dati derivati e ricostruibili.
Dopo una ricostruzione il close time originale può non essere noto. → QA-13.

### T9 — Registri è una Serie, ma descrive le Serie

Se il catalogo vive in una Serie normale, aprirla richiede il catalogo. La circolarità si
scioglie con una configurazione incorporata, ma va decisa. → QA-10, RSK-15.

## Lacune di progetto

Aspetti che la specifica non tratta e senza i quali l'architettura non è completa.

| Lacuna | Questione |
|---|---|
| Formato di record, documento e `_id` | QA-01 |
| Persistenza dell'indice e tempo di riavvio | QA-03 |
| Semantica dei livelli di durability | QA-05 |
| Livello di isolamento | QA-09 |
| Crescita di `multiserie.log` | QA-08 |
| Vita dei tombstone | QA-15 |
| Tracciamento dei reader | QA-16 |
| Consistenza degli indici secondari | QA-25 |
| Obiettivi numerici di latenza; target per Serie o aggregati | QA-26 |
| Piattaforma di riferimento | QA-19 |
| Protocollo, query, schema | QA-20, QA-21 |
| Replica, backup, sicurezza | QA-23 |

## Confronto con architetture note

Utile per sapere quali problemi sono già stati incontrati da altri, non per stabilire
classifiche.

| Aspetto | ArcDocDB (specifica) | Modello di riferimento | Che cosa se ne ricava |
|---|---|---|---|
| Log append-only + indice delle chiavi in RAM | sì | Bitcask | Limiti noti: l'indice deve stare in memoria; il riavvio richiede file di hint. → QA-03, RSK-07 |
| Separazione tra log e valori | da decidere (QA-02) | WiscKey | Scrivere i valori una sola volta riduce l'amplificazione; costa in gestione dello spazio |
| Insieme dei file come log di modifiche | da decidere (QA-04) | manifest degli LSM-tree | Meccanismo collaudato per rendere atomici i cambi di insieme dei file |
| Compaction | CLEAN per segmento + MERGE opportunistico, senza ordinamento | LSM-tree a livelli | Qui non servono run ordinati (l'indice è in RAM): la compaction è molto più semplice e meno invasiva |
| Commit atomico multi-partizione | 2PC con decision log unico | 2PC classico con coordinatore | Il blocco dei partecipanti in stato PREPARED è il problema noto. → QA-07 |
| Un writer per partizione | sì | architetture a partizioni single-writer | Niente lock, ma il tetto per partizione è quello di un core. → RSK-04 |

## Che cosa cambierebbe il giudizio

L'architettura andrebbe rivista, e non solo rifinita, se:

- le pause del GC di SBCL risultassero incompatibili con l'obiettivo di P99 anche tenendo
  indici e cache fuori dallo heap gestito (SPK-02);
- un primary index compatto con reader concorrenti non fosse realizzabile in solo Common Lisp
  con prestazioni dell'ordine richiesto (SPK-01);
- il modello dei protocolli mostrasse che visibilità atomica delle multiserie e writer non
  bloccante sono incompatibili senza un coordinamento globale pesante (SPK-07).
