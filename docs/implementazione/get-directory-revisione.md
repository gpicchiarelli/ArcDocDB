# Revisione indipendente statica della directory GET CLOSED

Base: `6eeb501d2eace49fad8e2ec333ed0c6c1386dd6c`. Worktree:
`/Users/gpicchiarelli/.codex/worktrees/get-directory/ArcDocDB`.
Data: 11 ottobre 2026. Unico file scritto dal revisore: questo rapporto.
Nessuna esecuzione di prodotto o strumenti, compilazione, test, benchmark,
commit o creazione di agenti. Le letture e gli identificatori blob sono
osservazioni statiche del contenuto; non attestano risultati dinamici.

## Esito e sequenza delle letture

La prima lettura completa del prodotto e delle dipendenze GET/resolver/IO/EBR
non ha individuato rilievi P0/P1/P2 nei percorsi del costruttore canonico.
La seconda lettura è stata completata subito alla notifica del padre
«prodotto canonico pronto», rileggendo i quattro sorgenti. I blob del
prodotto erano identici nelle due letture. Il successivo caso FI di entry
privata NIL, richiesto dal padre, introduce il rilievo GDR-R02 qui sotto.

I due rilievi P2 iniziali, sulla raccolta C4 di raw incompleti e sulla
classificazione della corruzione di una entry privata, sono chiusi dalla
lettura statica delle correzioni notificate dal padre. Nessun P0 o P1
identificato sul contenuto letto. Questi esiti non costituiscono qualifica C1,
dimostrazione di assenza di difetti o misura di prestazioni/allocazioni.

## Rilievi concreti

### GDR-R01 — P2 — Raw di campagne non terminali raccolti senza controllo di chiusura

Stato: **chiuso staticamente** sul blob corretto
`086da7ca0d664169bd433a60db943c221f3bb365`.
`publication-raw-roots` seleziona soltanto le specifiche `:raw-roots` del
manifesto. Prima di raccogliere ciascuna radice, `raw-root-metadata` richiede
schema 1, kind command-verification, stato terminale OK/FAILED/SOURCE-CHANGED
e timestamp di fine intero. RUNNING o timestamp assente interrompono publish.
Ogni raw della radice e ogni sorgente mutata riceve produttore, stato,
source-consistency e limiti espliciti su raw parziali dei produttori falliti,
senza promozione del risultato. Lettura delle righe 129–201.
I quattro controlli aggiunti al self-test (righe 235–245) accettano OK/FAILED
terminali e rifiutano RUNNING/fine assente; `:checks 25` è un dato del
sorgente, non un esito eseguito. La correttezza dell'associazione
raw-root/produttore nel manifesto resta da leggere quando sarà disponibile.

Descrizione del rilievo sul contenuto precedente:

File: [`tools/get-directory-evidence.lisp`](../../tools/get-directory-evidence.lisp),
righe 144 e 151–166. Blob letto:
`09c68723c15f286641d9b24844bfe2f282394db9`.

`publish` esclude un record `:running` dalla lista `:entries`, ma raccoglie
ricorsivamente i raw di tutte le directory con prefisso coverage/mutations
senza richiedere un report terminale. La raccolta delle sorgenti mutate
controlla soltanto l'esistenza del report e del file. Il controllo finale
richiede almeno una entry conclusa, non la chiusura delle radici dei raw.

Scenario concreto: un processo mutation interrotto lascia report `:running`
e alcuni raw; un'altra esecuzione ha un record concluso. `publish` può
concludere con `:status :ok` e archiviare quei raw parziali senza un attributo
di incompletezza o un legame obbligatorio al report terminale. Digest e copia
integra attestano i byte conservati, non la completezza della campagna.
Il rischio riguarda la lettura del catalogo come raccolta conclusa; non è
un difetto del GET né un risultato dinamico osservato.

Proposta: richiedere un report terminale per ogni radice raw da pubblicare,
oppure registrare esplicitamente radice e raw incompleti e impedirne l'uso
come evidenza conclusa. Conservare i report terminali falliti con il loro
stato. Il manifesto esplicito delle radici resta necessario; da solo non
verifica lo stato dei report. Il self-test dovrebbe distinguere una radice
conclusa da una `:running` con raw presenti.

Limite: la logica è ereditata dal collector get-performance; non si afferma
che la copia di bytes parziali sia di per sé illecita, né che un artefatto
parziale esista già in questa campagna. È il percorso statico di pubblicazione
senza classificazione della completezza a essere segnalato.

### GDR-R02 — P2 — Entry privata NIL produce TYPE-ERROR e contesto IDLE

Stato: **chiuso staticamente** sul blob corretto
`b0e40d9ff3f504130aaf1e083a633dee9b146d29`.
`read:23–26` legge la entry, controlla TYPEP prima del ritorno e chiama
`guasto-get :directory-shape` per un tipo impossibile. Il contesto passa a
FAULTED prima della condizione; l'unwind-protect del wrapper libera EBR e
`abbandona-get` conserva FAULTED. La guardia aggiunge solo l'invariante del
selettore e non modifica la ricerca, l'ownership o la delega al resolver.
Riletti il percorso completo e il cleanup; nessuna esecuzione.

Descrizione del rilievo sul contenuto precedente:

File: [`src/get-directory/read.lisp`](../../src/get-directory/read.lisp),
righe 23–24 e 35–46. Blob letto:
`a6e13ce6f1b3f5aa23f479de2efbcdab78cf5f0f`.
Dipendenza cleanup: [`src/get/lifecycle.lisp`](../../src/get/lifecycle.lisp),
blob `23f16c3039b71be0bd46d6bf92f05791e444683e`.

Se FI sostituisce con NIL la entry privata associata all'ID trovato,
`(the mappa-segmento-get (svref maps middle))` segnala TYPE-ERROR con safety 3.
Il controllo di geometria ha già accettato lunghezze uguali. Il contesto è
ancora CANDIDATE: `abbandona-get` libera EBR e, in assenza di FAULTED
preesistente, lo riporta a IDLE. La corruzione interna non passa quindi dal
ramo di guasto terminale già previsto per geometria o ID mancanti.

Proposta: leggere la entry, controllare `typep` per `mappa-segmento-get` e
chiamare `guasto-get context :directory-shape` prima del ritorno se il tipo
è impossibile. Il cleanup allora conserva FAULTED. È un controllo locale
dell'invariante del selettore, senza duplicare CSN, size, FD o prove.

Limite: NIL non è producibile tramite il costruttore canonico con input
stabile. La copia attuale impedisce che il riuso dell'input alteri la entry
privata. Un mutante che rimuova la copia può invece esporre questo percorso.
La guardia migliora la classificazione sotto FI/regressione di alias; non
sostituisce la copia né controlla l'identità di una mappa del tipo corretto.
Nessun valore è autorizzato dal percorso TYPE-ERROR esistente.

## Checklist C1 — due letture statiche

«Letto» indica controllo del sorgente e ragionamento sui rami, non un test
passato o copertura misurata. Riferimenti e numeri di riga sono quelli dei
blob elencati nel rapporto.

La checklist conserva le due letture iniziali sui blob precedenti. La
rilettura successiva alla correzione R02 conferma anche il nuovo invariante
di tipo della entry; gli altri tre sorgenti del prodotto hanno blob identici.

| Controllo | Prima lettura | Seconda lettura | Evidenza statica e limite |
|---|---|---|---|
| Identità della vista | Letto | Letto | `build:30–31`, `read:39–40`: EQ della vista canonica; stessi byte di identità non rendono intercambiabili due viste. |
| ID intero u32, alto zero e basso positivo | Letto | Letto | `build:23–38`, slot u32 di segmento: zero e high nonzero rifiutati; `#xffffffff` rappresentabile senza troncamento. GDR-D02. |
| Location del candidato u64 e FTYPE del selettore | Letto | Letto | `read:7–8,41–43`; GET content è un array u64. `ldb (byte 32 32)` estrae tutti i bit dell'ID, senza restringere la location a u32. |
| Ordine strettamente crescente e duplicati | Letto | Letto | `build:37,49–56`: previous u32, ID iniziale zero; duplicati e inversioni rifiutati. Nessun ordinamento implicito. |
| Copie e ownership degli array | Letto | Letto | `build:51–56`: nuovo array u32 e copia simple-vector; le mappe immutabili sono condivise per riferimento. Nessun accessor di array esportato. |
| Budget prima degli array | Letto | Letto | `build:12–20,48–52`: forma, M in 1…65.536 e B index, count e 12N prima delle copie; poi verifica completa delle mappe. GDR-D01. |
| Zero, massimo e payload | Letto | Letto | N=0 ammesso con M positivo e B=0; N=65.536 richiede 786.432 byte di payload logico SBCL64. Non include input, mappe, header, GC o vecchie radici. |
| Ricerca massimo 17 sonde | Letto | Letto | `read:13–25`: intervallo semichiuso, massimo 65.536; primo/ultimo/missing/ID estremo considerati. GDR-D04. Argomento dettagliato sotto. |
| Nessun falso ABSENT | Letto | Letto | Vuoto, geometria impossibile e ID mancante chiamano `guasto-get`; nessuna traduzione in documento assente. Entry di tipo impossibile: rilievo GDR-R02. |
| Precondizione e cleanup in EBR | Letto | Letto | `read:35` precede unwind-protect; dopo l'accettazione, errori di vista e lookup abbandonano GET. Un ordine API errato non prende il cleanup di un compito altrui. Il cleanup esterno resta necessario prima di AVVIA-GET. |
| Selezione mappa e delega dei controlli | Letto | Letto | `trova-mappa` restituisce una mappa; i tre wrapper chiamano resolver/GET, che ricontrollano offset, size, CSN, flag, frontiera, FD e, quando richiesto, CRC/chiave/OUTCOME. La selezione non autorizza una risposta. |
| FD readonly/open e lifetime | Letto | Letto | `build:34–36`, resolver read: stato corrente ricontrollato; GDR-D03. La capacità Lisp non autorizza close/reclaim e non dimostra identità fisica o quiescenza. |
| Fonte e frontiera CLOSED | Letto | Letto | Resolver build: manifest CLOSED, frontiera valid-bytes; header/body dallo stesso FD. Directory non ricava un limite da EOF, cache, H o hint. |
| Heap e I/O | Letto | Letto | Il selettore non contiene allocazioni di array o I/O espliciti; sonda delegata senza I/O, leggi delegata nel pool I/O. FTYPE u64 non dimostra assenza di boxing o heap effettivo. |
| Migrazione e risposta privata | Letto | Letto | Nuovo AVVIA-GET e nuova acquisizione dopo migrazione; copia privata e conclusione con tempo fresco restano obbligatorie. Nessun pin o location conservato in coda. |
| ASD e scope coverage integrati | Letto sullo stato integrato | Letto | Modulo dopo get-resolver; scope dei tre file types/build/read. La presenza dello scope non attesta copertura o successo dei test. |

### Argomento statico del limite di ricerca

Per un intervallo di ampiezza N, `middle = left + floor(N/2)` è interno
quando N>0. Dopo una sonda non risolutiva la metà sinistra ha al massimo
`floor(N/2)` elementi e quella destra `N-floor(N/2)-1`.

Con N=65.536 la ricerca del primo elemento visita gli indici
32.768, 16.384, 8.192, …, 2, 1, 0: diciassette sonde, con ritorno consentito
anche nell'ultima iterazione. L'ultimo elemento richiede sedici sonde.
Un ID sotto il minimo segue il primo percorso e termina in guasto; sopra
il massimo esaurisce l'intervallo prima di una nuova lettura. I missing
interni si esauriscono entro lo stesso limite; un array vuoto fallisce
prima di AREF. L'ID positivo massimo `#xffffffff` è confrontato come u32
esatto e segue il percorso della sua posizione, senza wrap o alias.
Il limite riguarda le sonde di un pivot; il COND usa le relazioni `<` e `>`.
Non è una misura di istruzioni, latenza o allocazioni.

## C4 disponibile e lavoro non ancora leggibile

Letti contratto, preregistrazione e collector C4. Il confronto statico con
get-performance-evidence mostra adattamenti di nomi, prefissi, scope,
campagna e nome temporaneo; non si assume trasferita una qualifica dinamica.
Il collector verifica copie/digest e gzip senza perdita; conserva stati dei
record conclusi e controlla i link HTML. Il self-test contiene controlli
positivi e negativi di copie, digest, compressione, selector e link.
La raccolta raw ha il limite GDR-R01. Il manifesto `publication-roots.lisp`
è richiesto prima di publish; la sua futura presenza non è attestata qui.

Alla chiusura di questa lettura non sono disponibili benchmark/metodo/mutation
get-directory completi da valutare. Restano pertanto non valutati clock e
regressione temporale, raw delle finestre interrotte, heap globale e relativo
oracolo, conteggi fissi/non adattivi, controlli positivi/negativi dei sensori
e timeout/join dei thread. Non si attribuisce loro né un difetto né un esito
positivo in assenza del codice. L'eventuale aggiornamento è subordinato a
nuovi messaggi prima del freeze; dopo freeze e durante le verifiche il
revisore non scrive e non esegue strumenti.

## Identificatori del contenuto letto

| File | Blob |
|---|---|
| `src/get-directory/package.lisp` | `951e5efdd1977c18a5bd90a1e4b3199d60e92d38` |
| `src/get-directory/types.lisp` | `ec99839d234468298b553e331873a320c8ece53f` |
| `src/get-directory/build.lisp` | `f1a1a37ccd59a81e7ff91fcb36009d5953d7edd5` |
| `src/get-directory/read.lisp` | `a6e13ce6f1b3f5aa23f479de2efbcdab78cf5f0f` |
| `src/get/types.lisp` | `032ad088b19ec3498a7c80a5e4b96d7777257dad` |
| `src/get/build.lisp` | `cb426426eac6e923224bc57c1dd602405f4bc040` |
| `src/get/lifecycle.lisp` | `23f16c3039b71be0bd46d6bf92f05791e444683e` |
| `src/get/lookup.lisp` | `5a105a141b43f5585f8e79c2965d59e96cd35ac6` |
| `src/get/target.lisp` | `c9b8488d0a1aa7643a6ab1570765ec870aa7c9e4` |
| `src/get/segment.lisp` | `cf168c44bfe5aedd2e34180ce4f766a6a89500a7` |
| `src/get-resolver/types.lisp` | `b6a50c95567f302f84000471197ca4f9bc7e5be8` |
| `src/get-resolver/build.lisp` | `4c0deb7ca308c4fd617a585ac174f8d3d344b670` |
| `src/get-resolver/read.lisp` | `e12dfbef734622173bb2a44a317c527f0827461d` |
| `src/read/core.lisp` | `132e44c138e209d3f8840b098cca0424853d09c3` |
| `src/read/task.lisp` | `b3601060197a27c6e8a2aaee22b5576c6b0c6e5a` |
| `src/epochs/read.lisp` | `a3dfde4a4780554b88e6e037ab4f70731f9c884a` |
| `src/epochs/reclaim.lisp` | `57235763cf556ecd7633a0052f265ce3eb2b0462` |
| `src/io/types.lisp` | `b496c1df87108127da568a1fb7b0fd32856afcc5` |
| `src/io/lifecycle.lisp` | `0b93448ffe9c6dd4f3a0a2f3f35d5cd656700bd7` |
| `src/io/transfer.lisp` | `93acbd608b1af475aa505a6a7dedceb3b15e8d4b` |
| `arcdocdb.asd` | `c4d066a48bf840d841bad9f1e92e534dcded7985` |
| `tools/foundation-coverage.lisp` | `6e6eccefd5fad1786d555fa2060d4660f8c4e725` |
| `tools/get-directory-evidence.lisp` | `09c68723c15f286641d9b24844bfe2f282394db9` |
| `docs/implementazione/get-directory.md` | `cf00b52a7dd8be53fd49ebafb320000978faa7e8` |
| `spikes/results/2026-10-11-get-directory/README.md` | `2768e28d64c35853d0cbeac5d57f9d39a0a609ed` |

La pubblicazione delle radici, la raggiungibilità delle fonti dei reader già
ammessi e la conservazione dei FD fino al reclaim sono precondizioni del
controller, esplicite nel contratto CLOSED. Questa directory non aggiunge
una cella di pubblicazione. Le integrazioni ACTIVE/controller sviluppate
altrove non sono duplicate o modificate da questa revisione.

## Chiusura dell'autore prima del congelamento

Questa sezione è scritta dall'autore, non dal revisore indipendente.
Il revisore è stato chiuso prima delle esecuzioni dopo le due letture C1 e
la rilettura statica delle correzioni R01/R02 già conservate sopra.
La richiesta successiva di ampliare la lettura C4 non ha prodotto un handoff
conclusivo: benchmark e mutazioni non ricevono una revisione indipendente
completa da questo rapporto. Il loro metodo è stato letto dall'autore;
i controlli dinamici e i sensori restano da eseguire e registrare.

L'integrazione include `main` fino a `7568456`, GET funzionale, resolver ACTIVE
ordinario e routing dei worker. I conflitti ASDF e coverage preservano i due
percorsi e i rispettivi scope. Il prodotto directory mantiene i quattro file
elencati sopra, con la guardia R02. Le fixture benchmark sono sequenziali,
con al massimo 64 FD readonly vivi; i conteggi rimangono fissati a 80/240
finestre seriali/parallele. Il mutante di location conserva il guasto nel
caso vuoto e altera soltanto la directory non vuota.

La correzione in `get-resolver/build.lisp` confronta il ritorno di
`leggi-esatto` con END, secondo il contratto di `io/transfer.lisp`, anziché
con END−64. La nuova regressione su file reale verifica ritorno, regione,
sentinelle e osservazione I/O. Non è stata eseguita prima del congelamento.
I risultati successivi qualificano soltanto il contenuto effettivamente
registrato nei rispettivi comandi; non si attribuisce una qualifica C1
complessiva a questo incremento.
