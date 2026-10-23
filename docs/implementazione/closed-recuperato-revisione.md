# Revisione statica del recovery CLOSED

2026-10-16; worktree condiviso `closed-verifica/ArcDocDB`.
Due letture distinte dello stesso revisore: P1 dal reader alle deleghe;
P2 dagli ingressi pubblici ai parser, con ricontrollo dei rilievi.
Primo lotto salvato prima del completamento; riferimenti alle posizioni lette.
Nessuna attestazione di snapshot congelato o di due revisori indipendenti.
Nessun test, compilazione, diagnostica, benchmark o scansione security eseguito;
nessun risultato runtime altrui usato. Nessuna qualifica C1.

Regole lette: CONTRIBUTING, guida al repository, principi di ingegneria,
standard di codifica e registro deviazioni. Checklist C1: standard, righe 89–108.
Contratti: `docs/implementazione/closed-recuperato.md` e `recovery-csn.md`;
ADR-0020/0040/0041. Letti tutti i nove file `src/recovery-closed/`, inclusi
`csn.lisp`/`csn-serie.lisp`, e deleghe in recovery-active, control, recovery/manifest,
foundation/batch, storage/header e compaction-scan, io/transfer e capacità.
Letti registrazione ASDF, requisiti/matrice e casi REQ-* disponibili nei sorgenti
`tests/recovery-closed/`; la lettura non ne dimostra l'esito.

## Rilievi e correzioni suggerite al coordinatore

**R1 — Correttezza contrattuale: conflitto OUTCOME/EDIT orfano non rilevato.**
Osservazione originale: `src/recovery-closed/resolve.lisp:18` itera soltanto i
TXID prepared; il confronto alla riga 21 non raggiunge gli OUTCOME orfani.
`src/recovery-active/frames.lisp:48` confronta soltanto OUTCOME duplicati;
`src/recovery-closed/build.lisp:18`–`:25` risolve, aggrega e costruisce il risultato.
Controesempio dedotto, non eseguito: OUTCOME(T, 7), SEAL CSN 8, EDIT(T, 9),
nessun prepared T, fonti integre e congelate. Il massimo restituito è 9,
senza confronto fra le due prove. Nessuna perdita di documenti dimostrata.
ADR-0041 impone la risoluzione dei prepared; l'obbligo ulteriore sugli orfani
qui deriva dal contratto `recovery-csn.md:48`/CSR-D04 (`:104`), confermato
esplicitamente dal coordinatore. Non è dedotto dalla sola autosufficienza.
Correzione concordata: confrontare tutti gli OUTCOME con l'eventuale EDIT
omonimo prima della classificazione prepared, senza nuovi contenitori;
conservare `:closed-recovery-outcome-conflict` e i conteggi dei soli prepared.
Il ciclo resta limitato dal budget OUTCOME, senza accesso a multiserie.log.
Stato: correzione annunciata dal coordinatore, ancora da rileggere staticamente.
Caso suggerito dopo freeze: `test-REQ-TXM-007-CLOSED-conflitto-orfano`,
con variante concorde, zero e bit alti, rifiuto prima del risultato/massimo.
Il caso letto in `tests/recovery-closed/semantics.lisp:50` contiene un prepared.

**R2 — Standard COD-24: una sola asserzione nel fold degli esiti EDIT.**
Posizione osservata: `src/recovery-closed/csn.lisp:8`–`:16`,
`massimo-csn-chiusura`: controlla solo la presenza della entry alla riga 13,
poi itera una hash table non tipizzata nei valori e restituisce gli scalari.
COD-24 richiede almeno due asserzioni significative nelle funzioni C1 non banali;
`docs/affidabilita/deviazioni.md:18` dichiara nessuna deroga approvata.
Proposta concreta, soli scalari: salvare la cardinalità attesa prima del fold;
per ogni esito verificare `(typep csn 'u64)` prima di `max`, incrementare
`used`, e verificare `used = expected` prima di restituire il risultato.
Il primo controllo rileva anche valori negativi che `max` potrebbe occultare;
il secondo rileva un attraversamento incompleto rispetto alla fonte attesa.
Segnalare `invariant-violation` con ragioni dedicate; conservare il controllo
CLOSED esistente. Non basta riaffermare che il massimo è maggiore di zero:
zero è valido. Nessun guasto runtime dimostrato; gestione FAULTED della Serie
al confine del controller da verificare separatamente.

## Passaggio 1 — checklist C1, dal reader alle deleghe

«Aperto» significa evidenza non acquisita, non esito positivo.

| # | Punto C1 | Evidenza statica / limite |
|---|---|---|
| 1 | REQ e ADR | REQ annotati; ADR-0040/0041 per P e autosufficienza; R1 sul contratto CSN aggiuntivo. |
| 2 | Invarianti e test | INV-S7/A2/A9/P6 pertinenti; letti casi REQ-TXM-007, REQ-MVC-005, REQ-AFF-008; efficacia aperta. |
| 3 | Errori | Rifiuti tipizzati, propagazione senza handler nel modulo; R1 manca un rifiuto contrattuale. |
| 4 | Cicli e attese | Chunk/lotti/record/prepared/OUTCOME/EDIT/insieme limitati; nessuna ricorsione o attesa introdotta. |
| 5 | Allocazioni | Workspace/hash table all'apertura; heap zero, RSS e costi u64/GC non misurati. |
| 6 | Dati verificati | Costruzione dopo CRC/SEAL e semantica locale; R1 limita la coerenza delle prove orfane. |
| 7 | Decisioni | CDR-D01…07 e CSR-D01…10 elencate; MC/DC aperta. |
| 8 | Ownership | OWNER/SHARED dichiarati; scratch privato, capacità e fonti conservate dal controller. |
| 9 | Tracciabilità/check | REQ, ASDF e matrice letti; rigenerazione e `make check` non attestati. |
| 10 | Standard/deviazioni | Safety 3, ftype, slot tipizzati/readonly; R2 COD-24, nessuna deroga registrata. |
| 11 | Parallelismo | Nessun nuovo lock, globale mutabile o scrittura tra Serie; I/O nel compito dedicato. |
| 12 | Durabilità | Reader readonly; rinomina CONTROL/fsync parent delegati al publisher canonico. |

## Passaggio 2 — checklist C1, dagli ingressi ai parser

| # | Punto C1 | Evidenza statica / limite |
|---|---|---|
| 1 | REQ e ADR | Rilette risoluzione e fonti CSN; massimo osservato distinto da H e dalla base completa di Archivio. |
| 2 | Invarianti e test | Partizione prepared ricontrollata; R1 richiede caso orfano dedicato. Nessuna prova eseguita. |
| 3 | Errori | Budget produce rifiuto, mai abort/assenza; errori short read/EOF propagati. FI/gestione controller aperte. |
| 4 | Cicli e attese | Budget insieme prima di seen; limite esatto lotti accettato; parser su batches+records, compaction su count. |
| 5 | Allocazioni | Risultato senza scratch/workspace; seen resta allocazione di apertura, nessuna misura. |
| 6 | Dati verificati | EQ CONTROL, ID u64, P, unicità e presenza/zero ricontrollati; R1 confermato sui sorgenti letti. |
| 7 | Decisioni | Ricontrollate composte in read/verify/resolve/publication e CSR-D06; copertura per condizione non attestata. |
| 8 | Ownership | Congelamento, autorità del catalogo e stabilità dei FD sono precondizioni esplicite del controller. |
| 9 | Tracciabilità/check | Nomi REQ-* letti; nessuna evidenza build/trace/lint/copertura/check prodotta qui. |
| 10 | Standard/deviazioni | R2 confermato nel fold EDIT; safety e controlli delegati non danno approvazione complessiva. |
| 11 | Parallelismo | Aggregazione locale readonly; nessuna assegnazione CSN o nuova serializzazione tra Serie. |
| 12 | Durabilità | Gate CLOSED prima del claim; stesso CAS/rename/stati del publisher; inventario e ammissione esterni. |

## Controlli effettivi e precondizioni

- **Fine P / EOF.** `read.lisp:33` prende P dal manifest, `:70` limita il corpo;
  `verify.lisp:19` verifica lotti interi senza scanner TAIL. P a metà lotto è
  errore; byte successivi non letti. File corto: `src/io/transfer.lisp:34`
  segnala EOF/mancato progresso. P non misura EOF. Header più
  `ceiling((P-64)/chunk)` sono letture logiche esatte: short read possono
  richiedere più syscall, con progresso positivo e tetto per byte.
- **Identità/insieme.** `read.lisp:31` confronta backend, anche NIL; `:55`
  delega CRC/UUID/ID completo/versione/origine/riservati dell'header.
  `publication.lisp:16` controlla budget prima di seen; `:17`–`:30` verificano
  cardinalità, EQ del token CONTROL, appartenenza, P e ID EQL unici.
  Sotto stabilità questo prova tutti e soli i vecchi CLOSED, inclusi ID zero/u64 alto.
  Nomi/inode, catalogo e riconciliazione fisica restano precondizioni.
- **Lifetime.** Reader: CONTROL/input prima e dopo. Gate: ciascun input,
  CONTROL ricontrollato alla fine. `csn-serie.lisp:16`/`:22`: ACTIVE prima/dopo.
  Nessuna presa atomica su tutti i FD: controller mantiene apertura e congela
  file, namespace, manifest e vettore per tutta l'operazione. Le query scalari
  singole descrivono la lettura conclusa, senza ricontrollare apertura.
- **Budget.** `read.lisp:30`–`:40` verifica configurazione/P/esiti/range/capacità
  prima di I/O; `verify.lisp:23` limita record prima del workspace. Il parser
  ACTIVE limita prepared distinti e OUTCOME fisici, inclusi duplicati.
  EDIT canonici limitati dal count; max-segmenti esclude ACTIVE. Nessun tetto RSS attestato.
- **TXID/CSN e scope.** `src/recovery-active/frames.lisp:73` esclude stamp
  prepared; `:78` prende CSN dal payload OUTCOME, `:82` dal SEAL writer.
  `csn.lisp:14` include tutti gli EDIT, anche orfani; `:35` ammette soltanto
  stamp ordinari compaction. Massimi u64, NIL/0 distinto da T/0, nessun incremento.
  L'insieme completo riguarda questa Serie: occorrono ancora tutte le Serie e
  il decision log completo per inizializzare il registro unico dell'Archivio.
  Gli esiti orfani non producono documenti/commit; il massimo non autorizza traffico.
- **Token/durabilità.** `publication.lisp:44` precede ogni claim; deleghe ACTIVE
  e CONTROL verificano chiusura, vista e transizione conservativa.
  `src/control/publication.lisp:49` usa CAS canonico; `:52` rinomina, `:56`
  sincronizza parent, `:62` marca FAULTED l'uscita incompleta del proprietario.
  Nessun nuovo gettone; il controllo CLOSED non certifica il Recovery Manager.

Consegna: R1 conservato come osservazione originale, correzione annunciata;
R2 corredato da proposta concreta. Patch successive da rileggere prima del freeze.
Verifiche eseguibili e altri gate C1 senza attestazione.

## Addendum — rilettura statica delle patch R1/R2, 2026-10-16

Questo addendum aggiorna lo stato dei rilievi; osservazioni e posizioni precedenti
restano riferite ai sorgenti anteriori alle correzioni del coordinatore.

- **R1:** `src/recovery-closed/resolve.lisp:18`–`:21` attraversa tutti gli
  OUTCOME prima della classificazione prepared (`:22`–`:25`). EDIT presente e
  CSN diverso causano `:closed-recovery-outcome-conflict`, anche senza prepared.
  Presenza separata dal CSN preserva zero e bit alti; conteggi dei soli prepared
  invariati. Nessun nuovo contenitore; lavoro limitato dalle mappe già budgetate.
- **R2:** `src/recovery-closed/csn.lisp:14`–`:22` salva cardinalità, verifica
  u64 prima di `max` e confronta `used` con `expected` prima del ritorno.
  Ragioni dedicate: `:closed-recovery-csn-value` e `:closed-recovery-csn-outcomes`.
  Controlli informativi su valori/consumo; il conteggio non prova stabilità
  concorrente, che resta precondizione. Soli contatori aggiunti, CSN zero ammesso.

R1/R2 risultano affrontati rispetto ai rilievi statici; nessun nuovo problema
di prodotto individuato nelle due patch. Per CDR-D06, il confronto composto ora
è EDIT presente AND CSN diverso; presenza OUTCOME implicita nel ciclo, orfano da coprire.
Rilettura conclusa per il freeze; nessuna esecuzione, commit o qualifica runtime.
