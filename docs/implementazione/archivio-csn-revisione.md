# Revisione statica del piano CSN di Archivio

2026-10-16; worktree `archivio-csn-verifica/ArcDocDB`.
Due letture dello stesso revisore, distinto dall'autore dell'incremento:
P1 dalle strutture alle fonti; P2 dagli output ai prerequisiti e ai marker.
Non sono due revisori indipendenti. Primo lotto significativo salvato prima
che fossero completate le deleghe; posizioni riferite ai sorgenti letti.
Nessun test, compilazione, diagnostica, benchmark o scansione security eseguito;
nessun risultato runtime altrui usato. Nessuna qualifica C1 inferita.

Regole lette: CONTRIBUTING, guida al repository, principi di ingegneria,
standard di codifica e registro deviazioni. Checklist C1: standard, righe 89–108.
Perimetro: tutti i sei file di `src/recovery-archive-csn/`; marker in
`src/recovery/decisions-types.lisp`, `src/recovery-active/types.lisp`/`build.lisp`;
query fonte DECISION/ACTIVE/CLOSED, gate CLOSED, risoluzione e replay rilevanti.
Contratti `docs/implementazione/csn-archivio-recovery.md`, `recovery-csn.md`;
ADR-0020/0038/0041/0046. Letti requisiti e registrazione ASDF di prodotto;
nomi e casi REQ-* dei test in lavorazione sono materiale statico, senza esito attestato.

Copertura prevista dal coordinatore, non misurata: nove file, cioè i cinque
`types/series/preflight/build/query` del modulo, `recovery/decisions-types.lisp`,
`recovery-active/types.lisp`, `recovery-active/build.lisp` e, dopo la patch R1,
`recovery/decisions-query.lisp` come nono esplicito. `package.lisp` è stato letto
per import/export; gli altri delegati letti non estendono questo denominatore.

## Rilievo per il coordinatore

**R1 — COD-24 nella query fonte DECISION, delegata preesistente.**
Osservazione originale prima della patch; l'addendum aggiorna lo stato.
`src/recovery/decisions-query.lisp:14`–`:22`, `massimo-csn-decisioni`,
attraversa tutte le entry e calcola il massimo senza asserzioni esplicite
su forma/consumo e senza chiamare verificatori. Il piano vi arriva attraverso
`src/recovery-archive/query.lisp:13`–`:14` e il proprio `build.lisp:19`.
Il replay canonico e i tipi sostengono la precondizione sui dati; non costituiscono
le due asserzioni significative richieste da COD-24 per una funzione C1 non banale.
`docs/affidabilita/deviazioni.md:18` non riporta deroghe approvate.

> **Proposta** — durante il fold chiamare `check-entry-shape` sulle entry
> (`src/recovery/decisions-types.lisp:36`, controlli count/partecipanti),
> salvare la cardinalità iniziale e verificare il numero visitato prima del ritorno.
> Soli contatori scalari, nessun contenitore; `invariant-violation` per consumo incoerente.

R1 è uno scostamento di standard nel delegato: nessun massimo errato dimostrato
per input canonici. Nei sei nuovi file e nel collegamento del marker non è stato
individuato un controesempio di correttezza sotto le precondizioni dichiarate.
Questa conclusione non attesta gestione FAULTED, test, copertura o qualifica.

## Passaggio 1 — checklist C1, strutture e fonti

«Aperto» indica evidenza non acquisita, non esito positivo.

| # | Punto C1 | Evidenza statica / limite |
|---|---|---|
| 1 | REQ e ADR | REQ-REC-001/002, MVC-006, TXM-005/007, AFF-008 annotati; base e recovery coerenti con ADR-0020/0038/0041/0046. |
| 2 | Invarianti/test | INV-M5/T2/S7/A8/P6 pertinenti; nomi REQ-* visibili nei test; efficacia e completezza aperte. |
| 3 | Errori | Condizioni tipizzate e propagazione senza handler; nessun piano parziale consegnato. Gestione al controller aperta. |
| 4 | Cicli/attese | Cicli su viste, segmenti e DECISION budgetati; nessuna ricorsione o attesa introdotta. |
| 5 | Allocazioni | Copia del vettore e hash table UUID all'apertura; boxing/GC/RSS non misurati. |
| 6 | Dati verificati | Scope/UUID/Registri, EQ Archivio/vista/marker, gate CLOSED; fonti canoniche come prerequisito. |
| 7 | Decisioni | ACR-D01…11 elencate nel contratto; MC/DC non dimostrata. |
| 8 | Ownership | OWNER/SHARED dichiarati; vettore copiato, viste e fonti immutabili per protocollo. |
| 9 | Tracciabilità/check | REQ e ordine ASDF letti; rigenerazione matrice e `make check` non eseguiti. |
| 10 | Standard/deviazioni | Safety 3, ftype e slot tipizzati/readonly; R1 sul fold fonte preesistente, nessuna deroga registrata. |
| 11 | Parallelismo | Aggregazione locale al bootstrap; nessun nuovo lock o aggiornamento CSN fra Serie. |
| 12 | Durabilità | Nessun cambiamento durevole, rename, cancellazione o nuova atomicità nel piano. |

## Passaggio 2 — checklist C1, output e prerequisiti

| # | Punto C1 | Evidenza statica / limite |
|---|---|---|
| 1 | REQ e ADR | Base M, prima assegnazione M+1 esterna; ADR-0046 mantiene rifiuto dell'esaurimento senza wrap. |
| 2 | Invarianti/test | Rilette provenienza, duplicati e fonti del massimo; nessuna prova di violazione/test efficace eseguita. |
| 3 | Errori | Budget è rifiuto esplicito; wrong owner/view/marker precedono il gate della rispettiva Serie; lifetime delegato. |
| 4 | Cicli/attese | N+SUM(CLOSED) preflight prima dei gate; consumo ricontrollato; tetti esatti inclusivi, zero CLOSED ammesso. |
| 5 | Allocazioni | Piano: Archivio e quattro scalari; marker senza entry/FD; nessuna fonte pesante trattenuta dal piano. Nessuna misura. |
| 6 | Dati verificati | Marker dalla tabella realmente risolutiva anche su ACTIVE vuoto; completo set CLOSED per lo stesso CONTROL. |
| 7 | Decisioni | Rilette AND di count, OR di budget e consumo AND (presenza OR zero); corrispondenza ACR-D01/02/04/05/10. |
| 8 | Ownership | FD/vettori/file/namespace stabili per l'intero piano sono precondizioni, non una fotografia atomica prodotta dai gate. |
| 9 | Tracciabilità/check | Nomi test REQ-* letti, sorgenti ancora in lavorazione; nessuna evidenza build/lint/trace/copertura/check prodotta. |
| 10 | Standard/deviazioni | R1 confermato: la query con fold non ha asserzioni; tipi/replay non sostituiscono COD-24. |
| 11 | Parallelismo | Nessun thread, callback, timer o I/O nuovo; registri runtime e GET non aggiornati. |
| 12 | Durabilità | Esiti scalari derivati; obblighi di pubblicazione/recovery e ammissione restano al coordinatore. |

## Evidenze e limiti dei controlli

- **Elenco Serie.** `series.lisp:40`–`:44` rifiuta vuoto e budget prima di
  copia/hash table; `:13` ricontrolla count/range, `:18` scope EQ, `:22` UUID
  distinti per contenuto, `:25`/`:26` presenza EQ di Registri, `:27` cardinalità.
  La copia conserva ordine e isola il vettore del caller; le viste non sono copiate.
  Completezza del catalogo e ruolo reale di Registri sono attestazioni del controller
  (`csn-archivio-recovery.md:21`): una Serie omessa inizialmente non è rilevabile qui.
- **Origine.** `src/recovery/decisions-types.lisp:8` definisce un marker senza
  slot; `:32` ne crea uno per nuova tabella. `src/recovery-active/build.lisp:55`
  risolve usando `decisions`, poi `:63` conserva proprio `%table-origin` di quella
  tabella nello slot readonly di `types.lisp:31`, anche senza prepared.
  `preflight.lisp:13` richiede Archivio EQ; `:38` vista EQ; `:41` marker EQ.
  Replay distinti di byte uguali restano distinti. Il marker non attesta il catalogo
  e non protegge da accessi Lisp agli interni privati: nessuna garanzia ulteriore assunta.
- **Copertura e budget.** `preflight.lisp:17` confronta entrambi i count con N;
  `:19` include N ACTIVE, `:23` controlla ogni CLOSED rispetto a tetto Serie e residuo
  globale prima dell'addizione. Budget riferimenti `8*N` esclude hash/oggetti/GC.
  `build.lisp:24` verifica origine prima del gate della Serie; `:26` usa
  `massimo-csn-serie-recuperata`, che in `src/recovery-closed/csn-serie.lisp:17`
  verifica CLOSED completi: stesso CONTROL EQ, ID unici, stato CLOSED e P esatto.
  Il limite per Serie riguarda i CLOSED; quello globale include gli ACTIVE.
- **Lifetime.** La query `src/recovery-archive/query.lisp:13` verifica il FD
  decisioni; `build.lisp:31` lo ricontrolla dopo l'aggregazione. La query Serie
  verifica ACTIVE prima/dopo e CONTROL; il gate verifica i FD CLOSED.
  Sono osservazioni locali, senza pin atomico di tutti i FD: apertura e stabilità
  di file, manifest, vettori e namespace per tutta la chiamata spettano al coordinatore.
  I getter del piano descrivono il calcolo concluso e funzionano senza rileggere fonti.
- **Massimo e output.** `build.lisp:19` include tutte le DECISION, anche senza
  prepared locali; `:26`–`:29` unisce tutte le Serie e controlla consumo/assenza-zero.
  I delegati includono stamp ordinari, SEAL writer, payload OUTCOME ed EDIT;
  stamp prepared/TXID, frontiere e code escluse non contribuiscono.
  Presenza è distinta dal valore zero; `query.lisp:33`–`:34` separa high/low u32
  senza incremento o perdita dei bit alti, incluso massimo u64.
  `types.lisp:21`–`:25` conserva Archivio e quattro scalari, senza set, ACTIVE,
  CLOSED, tabella decisioni, scratch o FD; nessun risultato prima di tutti i gate.
- **Bootstrap e ammissione.** Il piano non aggiorna l'ambito GET di bootstrap;
  catalogo, indici/radici, pubblicazioni e multiserie pendenti restano da completare.
  La creazione del registro riceve M (`src/csn/registry.lisp:76`–`:88`);
  esaurimento verificato prima dell'incremento (`:117`). Due piani non autorizzano
  due allocatori. Il massimo osservato non è l'orizzonte H né prova traffico ammissibile.

## Sintassi e consegna

Riletti manualmente package/import/export, firme ftype, costruttori e nuovo
argomento `decision-origin`: l'unico punto di costruzione ACTIVE trovato nel
prodotto passa il marker; l'ordine ASDF carica decisioni prima di ACTIVE e il piano
dopo CLOSED. Nessun errore sintattico individuato mediante lettura; compilabilità
non attestata. Non si riusano istanze con il layout precedente, come da contratto.

R1 originale e proposta conservati; correzione del coordinatore riletta sotto.
Nessuna correzione di prodotto applicata dal revisore. Origine distinta, FD chiusi,
budget esatto, zero/bit alti/massimo u64 e base M restano da verificare dopo freeze.
FAULTED al confine, MC/DC, regressione e misure rimangono senza attestazione.

## Addendum — seconda lettura della patch R1, 2026-10-16

Riletto `src/recovery/decisions-query.lisp:14`–`:27` dopo la modifica.
`:22` chiama `check-entry-shape` prima del massimo: vengono controllati count
partecipanti >=2 e lunghezza ID16 esatta, con le ragioni preesistenti
`:decision-entry-count` / `:decision-entry-size`. `:24` incrementa `used`.
`:25`–`:27` verifica `(= used count) AND ((plusp count) OR (zerop maximum))`,
segnala `:decision-csn-result` e restituisce presenza ricavata da count.
Il consumo esatto lega la presenza all'attraversamento; sul vuoto il massimo
deve essere zero, mentre CSN zero in una tabella non vuota resta presente.
Sono controlli di forma e postcondizione significativi per COD-24. Nessun nuovo
contenitore/I/O o secondo attraversamento; rimane O(N), senza misura di allocazioni.
R1 affrontato rispetto al rilievo di standard; nessun bug numerico riprodotto
o dimostrato su input canonici, nessun nuovo problema individuato nella patch.
Per COD-54, registrare la decisione composta della query separatamente dal
controllo del piano ACR-D10. FI specifiche in `guards.lisp` restano al coordinatore;
nessun relativo esito assunto qui. Precondizione di fonti congelate conservata.
Seconda lettura conclusa per il freeze; nessuna esecuzione, commit o qualifica C1.
