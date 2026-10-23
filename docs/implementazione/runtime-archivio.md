# Bootstrap del runtime dell'Archivio

`arcdocdb.runtime` collega il [piano CSN completo](csn-archivio-recovery.md)
ai registri esistenti di CSN, snapshot ed epoche. Realizza ADR-0046 e le
voci condivise dell'[Archivio](../architettura.md#archivio-coordinamento-minimo).
Non introduce formati o nuove sezioni critiche per operazione.

## Famiglia unica e pubblicazione

Il controller mantiene un solo oggetto canonico `archivio-recovery` per
Archivio fisico, con catalogo e fonti congelati attraverso il bootstrap.
`crea-runtime-archivio` riceve un piano completo di quell'oggetto e
costruisce in privato CSN con ultimo=H=M, snapshot legato per EQ a quel
CSN, EBR e un nuovo ambito GET. Verifica legami e frontiere prima del CAS.

Un solo CAS passa il binding privato dell'Archivio da NIL alla capsula.
La barriera write precede il CAS; il getter carica una volta e acquisisce
prima di interpretare il riferimento. Due tentativi, anche con piani
distinti dello stesso Archivio, restituiscono al massimo una capsula
pubblicata. Il perdente segnala `:archive-runtime-bound`; la sua candidata
locale diventa recuperabile dal GC. Il controllo iniziale evita allocazioni
quando il binding è già visibile; il CAS decide la concorrenza.

Dopo il CAS riuscito segue solo il ritorno. Non esiste reset, rollback o
seconda pubblicazione. `trova-runtime-archivio` ritrova la stessa capsula
se il caller perde il ritorno per interruzione. Gli errori prima del CAS
non pubblicano stati intermedi. È una pubblicazione in memoria, senza
atomicità durevole. La capsula contiene solo CSN e nuovo ambito; nessun
piano, vecchio ambito, risultato recovery, tabella o FD trattenuto.

L'unicità vale **per oggetto Archivio canonico**. Canonicalità rispetto
al catalogo, esclusione di altri processi e validità temporale del piano
sono obblighi del controller. Due oggetti con lo stesso UUID non creano
un'esclusione fisica. Gli accessi Lisp agli interni privati sono fuori
dal contratto pubblico. Il nuovo slot privato cambia il layout: occorre
ricompilare senza riutilizzare vecchie istanze.

## API e limiti

| API | Contratto |
|---|---|
| `crea-runtime-archivio(plan, lifetime-ticks, wait-ticks, :csn-capacity 256, :snapshot-capacity 256, :worker-capacity 64, :retirement-capacity 256)` | Costruzione e binding unico, senza assegnare CSN |
| `trova-runtime-archivio(archive)` | NIL oppure capsula pubblicata per identità |
| `csn-runtime-archivio(runtime)` | Registro da passare a writer e decisioni |
| `ambito-runtime-archivio(runtime)` | Ambito per nuove viste e contesti GET |
| `snapshot-runtime-archivio(runtime)` | Snapshot dello stesso CSN e ambito |
| `epoche-runtime-archivio(runtime)` | EBR dello stesso ambito, reader preallocati |

Le capacità sono rispettivamente 1..65536, 1..65536, 1..4096 e 1..65536:
i limiti esistenti dei registri. Tutti i tipi e limiti, incluso
`1 <= wait-ticks <= lifetime-ticks <= max-u64`, sono verificati prima di
allocare registri o fare binding. Le durate sono obbligatorie nella stessa
unità monotona di NOW fornita poi alle API snapshot. Nessun clock, worker,
timer o compito I/O avviato.

Il costo è quello delle capacità preallocate; oggetti Lisp e GC non sono
un budget RSS. Candidate concorrenti possono moltiplicare temporaneamente
il costo; il controller mantiene il bootstrap esclusivo. Il CAS difende
dal doppio binding, non autorizza recovery concorrenti. Il binding non è
toccato da assegnazione, risoluzione, snapshot o GET.

## Collegamento delle Serie e ammissione

La prima assegnazione restituisce M+1. Riporto u32 ed esaurimento u64
restano quelli del registro canonico: la base massima è rappresentabile,
un'assegnazione ulteriore fallisce senza wrap.

Il controller passa il CSN della capsula ai controller Serie e costruisce
viste, contesti GET e capacità dei segmenti nel nuovo ambito. Le vecchie
viste vengono respinte per identità dello scope: non vanno riusati neppure
i `segmento-get` che le trattengono. Il vecchio ambiente resta riservato al
bootstrap, non viene revocato. Nessun pin o ritiro EBR viene importato.

L'[adozione verificata dell'ACTIVE](adozione-controller-runtime.md) costruisce
ora il controller reale con CSN runtime, ambito esatto e binding unico sul
log canonico; decisione del catalogo e ammissione restano del coordinatore.

L'[adozione dei CLOSED](adozione-closed-runtime.md) collega inoltre le mappe
GET verificate al nuovo ambito, riusando righe immutabili e gli stessi FD.
Non pubblica il primary o le fonti e non trasferisce la proprietà dei file.

**H=M non certifica la pubblicazione degli effetti recuperati.** Prima
dell'uso operativo rimangono catalogo/inventari autorevoli, riconciliazione
fisica, indici/radici coerenti, chiusura/pubblicazione del vecchio ACTIVE e
obblighi multiserie. Recovery Manager e gate del traffico restano da
implementare; queste API non qualificano l'intero motore.

## Decisioni e metodo preregistrato

| ID | Decisione e prova prevista |
|---|---|
| RTA-D01 | Quattro capacità valide; ogni tipo e limite inferiore/superiore |
| RTA-D02 | Lifetime valido AND wait valido AND wait <= lifetime; ogni condizione |
| RTA-D03 | Serie positive AND segmenti >= Serie; presenza OR massimo zero |
| RTA-D04 | Binding NIL oppure capsula; slot estraneo mediante FI |
| RTA-D05 | Ambito diverso AND snapshot legato per EQ al CSN candidato |
| RTA-D06 | Frontiere high e low uguali alla base; FI separate |
| RTA-D07 | Binding già presente prima della costruzione; due piani, stessa autorità |
| RTA-D08 | CAS riuscito/perdente; worker reali con deadline e join |

La suite `tests/runtime/` usa risultati pubblici delle fixture Archivio:
v1/v2, zero assente/presente, DECISION/CLOSED, riporto/esaurimento, nessun
I/O aggiuntivo e vecchio scope invariato. Le FI costruiscono stati interni
deliberatamente incoerenti, separati dai positivi; binding estranei sempre
ripristinati. Worker con limiti finiti, cleanup dopo join, celle possedute.
Nessuna callback di prova introdotta nel prodotto.

Gli agenti scrivono file disgiunti; prima dei run vengono chiusi e la
revisione è congelata e committed. Diagnostiche e fallimenti usano il
recorder. Copertura con cache separata, contatori azzerati dopo il load e
sola suite runtime: quattro file non-package del modulo più
`recovery-archive/types.lisp` per il nuovo slot. Self-test dei confini dello
scope e del rilevamento di un ramo mancante. Forme/rami SBCL non sono MC/DC;
nessun residuo viene escluso dal denominatore.

Due letture statiche C1 sono distinte dai test. Conservazione con
[collector comune](raccolta-comandi.md), manifest, quattro worker, hash e
controllo indipendente dell'inventario. Nessun benchmark nuovo: tempi dei
comandi includono compilazione/fixture e non sono throughput DB.
C1/MC/DC, piattaforma di riferimento e ammissione rimangono aperti.

## Esiti conservati

La [campagna dedicata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-runtime-bootstrap/report.md)
conserva 27 test composti superati, inclusi due concorrenti e tre nativi,
controllo completo locale e copertura: modulo 178/201 forme e 34/34 rami;
con contesto Archivio 190/230 forme e 35/40 rami. Nessun residuo escluso.
Il CAS perdente è osservato nel run, senza garanzia dello scheduling futuro.
La [revisione statica](runtime-archivio-revisione.md) resta distinta da
MC/DC, qualifica C1 e prova dinamica dell'interruzione dopo il CAS.
