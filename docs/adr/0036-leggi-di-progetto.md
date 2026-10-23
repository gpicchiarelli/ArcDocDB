# ADR-0036 — Leggi di progetto: il parallelismo è fondante; un punto di atomicità per operazione; prepara, decidi, completa; nulla si distrugge per assenza

- **Stato:** Accettata (il parallelismo come principio fondante è una decisione dell'autore,
  2026-10-03)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; rende normative, in forma generale, regole che
  la specifica enuncia come obiettivo («forte parallelismo tra Serie indipendenti»,
  «Parallelismo») o applica caso per caso («Workflow Clean/Merge», «Recovery», «Catalogo»)
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md#le-leggi),
  [architettura](../architettura.md#leggi), INV-P6, INV-A9, INV-A10, INV-A11

## Contesto

Gli ADR 0013–0035 definiscono un meccanismo per ogni problema. L'[analisi progettuale](../analisi-progettuale.md)
ha mostrato che i difetti trovati nascono tutti dove un meccanismo aveva una regola *propria*
invece di applicarne una generale: la compaction decideva con un record, il catalogo con una
macchina a stati, il recovery con la troncatura, la pulizia con «ciò che non è menzionato».
Un sistema critico si verifica meglio se i casi particolari discendono da poche leggi.

Il parallelismo, che la specifica pone nell'obiettivo del progetto, era presente come insieme
di invarianti (INV-P1…P4, INV-W1) ma non come **criterio**: nessuna regola diceva che un
meccanismo nuovo va giudicato da ciò che rende seriale. Un contatore di Archivio toccato a
ogni operazione (AP-13) è potuto entrare nel progetto senza che nulla lo segnalasse.

## Decisione

Le dieci leggi dell'[analisi](../analisi-progettuale.md#le-leggi) sono **normative**: un
meccanismo che non discende da una di esse richiede un ADR che lo giustifichi. Quattro non
erano finora invarianti e lo diventano.

### 1. Il parallelismo è fondante (INV-P6)

Il parallelismo non è un'ottimizzazione che si aggiunge: è **la forma in cui lo stato è
diviso**. È la prima legge perché decide la struttura prima di ogni altra scelta.

- **Unità.** Ogni lavoro appartiene a un'unità di parallelismo e procede senza attendere le
  altre unità dello stesso livello: Archivi; Serie di un Archivio; reader di una Serie, tra
  loro e rispetto al writer; lotti di log diversi; segmenti, per compaction, recovery e
  query; frammenti dell'indice. La gerarchia è in
  [architettura](../architettura.md#parallelismo).
- **Elenco chiuso di ciò che è condiviso.** Tra Serie non esiste alcun lock e alcuna
  scrittura condivisa sul percorso di una singola operazione. Gli elementi condivisi sono
  soltanto quelli elencati in [architettura](../architettura.md#archivio-coordinamento-minimo),
  ciascuno con un costo **limitato** e pagato al più una volta **per lotto, per transazione
  multiserie o per snapshot** — mai per operazione. Aggiungere una voce all'elenco richiede un
  ADR.
- **Criterio di progetto.** Ogni meccanismo dichiara che cosa rende seriale e a quale livello.
  A parità di garanzie vince la soluzione che serializza meno e più in basso nella gerarchia.
- **Rapporto con le priorità.** La legge non modifica la gerarchia di
  [ADR-0031](0031-software-critico-criteri-e-priorita.md): l'integrità resta sopra tutto. Ma
  parallelismo e correttezza qui non sono in concorrenza, perché hanno la stessa origine:
  l'unità di parallelismo coincide con l'unità di proprietà dello stato (un solo scrittore per
  Serie). Dove una garanzia superiore richiede un punto condiviso — l'orizzonte di visibilità
  per INV-M1 — quel punto va dichiarato, limitato, collocato dove pesa meno e approvato con un
  ADR ([ADR-0038](0038-orizzonte-di-visibilita.md) ne è l'esempio: l'attesa è alla nascita
  dello snapshot, non alla conferma delle scritture).

### 2. Un punto di atomicità per operazione (INV-A11)

Ogni operazione che cambia lo stato durevole è decisa da **un solo record durevole** nella
fonte di verità del suo livello:

| Livello | Fonte di verità | Record |
|---|---|---|
| dati della Serie | segmento `ACTIVE` | SEAL del lotto ([ADR-0037](0037-lotto-sigillato.md)) |
| struttura della Serie | `wal/control.log` | EDIT ([ADR-0040](0040-manifest-a-record-unico.md)) |
| transazione multiserie | `Registri/multiserie.log` | DECISION ([ADR-0041](0041-multiserie-segmenti-autosufficienti.md)) |
| Serie dell'Archivio | catalogo (Serie Registri) | documento della Serie |

Tutto ciò che precede il record è **preparazione**: non ha effetti visibili e si può scartare.
Tutto ciò che lo segue è **completamento**: è determinato dal record, è idempotente, e il
recovery lo ripete. Non esiste un'operazione con due punti di atomicità.

### 3. Prepara, decidi, completa

- Ciò che si prepara su disco nasce con suffisso **`.tmp`** (file o directory), è reso
  durevole, e resta `.tmp` fino alla decisione.
- La **decisione** è il record della sezione 2.
- Il **completamento** allinea il file system (rinomina da `.tmp`, eliminazione dei rimossi) e
  le strutture in memoria.

Al riavvio: un `.tmp` che la fonte di verità non nomina si elimina; un `.tmp` che la fonte di
verità nomina si rinomina; un oggetto rimosso dalla fonte di verità e ancora presente si
elimina.

### 4. Nulla si distrugge per assenza (INV-A10)

Un file o una directory si elimina **solo** se:

- ha suffisso `.tmp` e la fonte di verità non lo nomina (non è mai stato deciso), oppure
- la fonte di verità ne **registra la rimozione** (elenco dei rimossi di un EDIT, stato
  `dropping` nel catalogo).

Un oggetto con nome definitivo che la fonte di verità non conosce è un'**anomalia**: non si
tocca, si registra l'evento, il verificatore offline lo riporta. Un oggetto che la fonte di
verità nomina e che manca è un guasto (FM-16): quarantena o `FAULTED`.

### 5. Il recovery non distrugge (INV-A9)

Il recovery non modifica e non tronca alcun file di dati esistente. I suoi soli effetti
durevoli sono record nelle fonti di verità (sezione 2) e completamenti (sezione 3). Un
`ACTIVE` trovato al riavvio viene chiuso con la sua lunghezza valida e sostituito da uno nuovo
([ADR-0037](0037-lotto-sigillato.md)).

Pattern: stato partizionato con un solo scrittore per partizione e nessuna condivisione sul
percorso delle operazioni (architetture *shared-nothing*; Seastar/ScyllaDB; partizioni di
Kafka); commit point unico e redo idempotente (ARIES, per il principio); MANIFEST come unica
fonte dell'insieme dei file (LevelDB/RocksDB); file attivo nuovo a ogni apertura (Bitcask).

## Conseguenze

- Ogni ADR futuro compila, oltre al punto di atomicità, la riga «che cosa rende seriale».
- La scalabilità con il numero di Serie e di core diventa una proprietà verificabile: l'elenco
  di ciò che è condiviso è chiuso e ogni voce ha un costo misurabile.
- Il recovery non ha logica propria: per ogni fonte di verità scarta ciò che precede l'ultimo
  record valido e completa ciò che lo segue; procede in parallelo per Serie e per segmento.
  L'idempotenza (INV-A7) è una conseguenza, non una proprietà da dimostrare caso per caso.
- Un difetto nel calcolo dell'insieme dei segmenti o del catalogo non può più distruggere
  dati: al peggio lascia un oggetto sconosciuto, che viene segnalato.
- Ogni nuova operazione durevole si progetta compilando una riga della
  [tabella dei punti di atomicità](../analisi-progettuale.md#punti-di-atomicità).

## Limite dichiarato

Tre cose restano condivise da tutto il processo e non sono eliminabili dal progetto: il
**dispositivo**, i **worker** e il **garbage collector** di SBCL, che ferma ogni thread a ogni
collezione (RSK-01). Il progetto le governa — priorità di I/O, pool dimensionati, nessuna
allocazione sui percorsi caldi — ma non le rende parallele.

## Alternative considerate

- *Parallelismo come obiettivo di prestazione, da ottenere con ottimizzazioni:* in fondo alla
  gerarchia delle priorità verrebbe sacrificato a ogni scelta comoda; e un punto seriale
  introdotto nella struttura non si toglie dopo con una misura.
- *Regole per meccanismo, come finora:* ogni regola va verificata da sola; i difetti AP-03,
  AP-05 e AP-14 sono nati così.
- *Eliminare gli orfani «non menzionati»:* più semplice, ma trasforma un difetto del manifest in
  una perdita di dati.

## Valutazione

- Rischi: riduce RSK-18 e RSK-20 (un errore è rilevato invece di propagarsi); RSK-04 e RSK-12
  (ciò che è condiviso è enumerato).
- Verifica: revisione dell'elenco chiuso a ogni ADR; benchmark di scalabilità con il numero di
  Serie e di core e benchmark di isolamento (burst su una Serie, [13](../13-benchmark.md));
  SPK-04; modello del recovery in SPK-07 con un crash prima e dopo ogni punto di atomicità;
  test del verificatore su oggetti sconosciuti e mancanti.
