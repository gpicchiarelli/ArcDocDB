# Decision log recuperato — revisione statica C1

Data: 2026-10-15. Revisore: Codex, incarico di lettura indipendente.
Worktree condiviso: `/Users/gpicchiarelli/.codex/worktrees/decisioni-verifica/ArcDocDB`.
Revisione Git osservata: `c6a21d810dabdc1218efbbeaa1f7dab560da8893`;
le osservazioni riguardano i file di lavoro letti, senza attestare un freeze globale.

**Esito:** due letture statiche concluse, entrambe dello **stesso revisore**.
Un rilievo concreto di conformità a COD-25, descritto sotto. Nelle letture
non sono emersi ulteriori difetti funzionali dimostrabili sotto le precondizioni
del contratto. Questo esito non attesta assenza di difetti né qualifica C1.

## Perimetro e metodo

Letti integralmente i sei file di `src/recovery-archive/`: `package.lisp`,
`types.lisp`, `read.lisp`, `build.lisp`, `query.lisp`, `active.lisp`.
Confronto con [contratto API](decisioni-recuperate.md), ADR-0041, ADR-0052,
[standard di codifica](../affidabilita/standard-di-codifica.md), registro delle
deviazioni, guida del repository, requisiti e matrice di tracciabilità.

Seguite staticamente le deleghe rilevanti: header e costanti storage;
`io/types.lisp`, `io/transfer.lisp` e lifecycle; scanner recovery;
`decisions-types/build/query/sort.lisp`; ingresso, preflight, risoluzione e
risultato del recovery ACTIVE; identità di `ambito-get` e vista della Serie.
Questo approfondimento delle deleghe non costituisce revisione completa di
quei moduli o del Recovery Manager.

| Lettura | Metodo concreto | Esito |
|---|---|---|
| L1, stesso revisore Codex | Dal contratto al flusso: bootstrap, preflight, header, corpo, replay, query, collegamento ACTIVE; seguite le deleghe per controllarne i contratti. | Rilevato R1; precondizioni di EOF, catalogo e ownership distinte dai controlli locali. |
| L2, stesso revisore Codex | Rilettura integrale in ordine inverso dei file; controllo dei rifiuti prima dell'I/O, estremi dei range, assenza/zero, coda/duplicati, FD e corrispondenza dei budget. | Confermato R1; nessun ulteriore difetto funzionale dimostrato nel perimetro. |

Le due letture sono due passaggi dello stesso revisore, non due revisori
indipendenti. Nessun test, compilazione, lint, benchmark, strumento di copertura,
mutazione o scansione security è stato eseguito. Nessuna skill utilizzata.

## R1 — I/O dentro il predicato delle asserzioni di invariante

**Priorità media; non conformità statica a COD-25.** Rilevata in L1 e
confermata in L2; nessun guasto runtime osservato o dedotto come inevitabile.

- Posizioni: [`src/recovery-archive/read.lisp`](../../src/recovery-archive/read.lisp),
  righe **39–40** (`leggi-header-decisioni`) e **58–59** (`leggi-corpo-decisioni`).
- I due controlli `unless … (error 'invariant-violation …)` eseguono
  `leggi-esatto` direttamente nel predicato dell'asserzione. Questa chiamata
  effettua I/O e modifica lo scratch: la condizione non è priva di effetti.
  La delega che rende concreto l'effetto è `src/io/transfer.lisp`, righe 55–77,
  in particolare il trasferimento nel buffer alle righe 67–73.
- I rami segnalano rispettivamente `:archive-recovery-header-read` e
  `:archive-recovery-read`; quest'ultimo conserva `:offset start`.
- COD-25 impone che nessuna asserzione abbia effetti collaterali. Questi sono
  controlli espliciti di invariante anche se scritti con `unless`, anziché
  con la macro `assert`. Il registro delle deviazioni letto non contiene
  deroghe approvate.
- Conseguenza concreta: l'operazione di lettura e la verifica del suo esito
  sono accoppiate nel predicato; rimuovere o riformulare quel controllo può
  rimuovere anche l'operazione. Nel codice attuale il controllo resta attivo:
  non si sostiene che la lettura venga saltata o che vengano restituiti dati
  corrotti.
- Correzione proposta, non applicata: assegnare il risultato di `leggi-esatto`
  a una variabile locale e verificare poi l'uguaglianza con un predicato puro,
  mantenendo ordine, chiamata unica, condizione e offset originali.

## Confronto concreto tra contratto e implementazione

| Aspetto | Evidenza statica e conclusione | Limite |
|---|---|---|
| Requisiti e ADR | I marcatori REQ delle definizioni coprono REQ-REC-001, REQ-TXM-001/005/007, REQ-FOR-001/002/003 e REQ-AFF-002/008/009 secondo la funzione. ADR-0052 governa header/identità, ADR-0041 decisioni e risoluzione. | Realizzazione parziale dei requisiti del Recovery Manager; non chiude l'intero requisito REQ-REC-001 o la durabilità degli esiti dei partecipanti. |
| Preflight | `read.lisp:14–28`: capacità aperta `:input`, alias UUID, chunk, size/header, budget byte, scratch, capacità del trasferimento, budget replay e scanner, prima di `leggi-header-decisioni`. | La validità dei tipi degli argomenti è una precondizione delle firme; non tutti i rifiuti di tipo sono `invalid-argument`. |
| Header e versione | `read.lisp:38–45` legge 64 byte; `storage/log-header.lisp:39–59` verifica range, CRC, magic multiserie, versione supportata, tutti i riservati e tutti i 16 byte UUID. `build.lisp:28` passa al replay la versione letta. | Nessuna prova bytewise v1/v2 eseguita. Il `2` nel preflight scanner non è la versione usata per decodificare il corpo. |
| Ownership | `types.lisp:20–22` verifica 16 byte e usa `copy-seq`; slot readonly alle righe 11–12 e 31–37. `decisions-build.lisp:89–95` copia i partecipanti; il risultato conserva tabella posseduta, archivio e capacità, senza scratch. `package.lisp:14–17` non esporta accessor degli array. | L'immutabilità è quella del protocollo e delle API pubbliche; non una protezione da accessi agli internals Lisp o da mutazioni esterne al protocollo. |
| Wrong scope | `active.lisp:15–19` confronta con `eq` l'ambito canonico dell'Archivio e quello della vista CONTROL, poi controlla alias e capacità. `active.lisp:37` precede la delega che effettua l'I/O ACTIVE. | UUID uguali non rendono equivalenti due ambiti distinti. Associazione iniziale UUID/ambito e unicità del bootstrap restano responsabilità del controller, come documentato. |
| Lifetime FD | `read.lisp:14,60`, `build.lisp:36`, `active.lisp:19,43` richiedono capacità aperta readonly; `io/types.lisp:83–91` verifica modo, stato e descrittore. `io/transfer.lisp:65–73` ricontrolla la capacità attorno ai trasferimenti. | Il riferimento trattenuto non è una lease che impedisce close. Il controllo finale ACTIVE osserva il decision log al ritorno; non ne garantisce da solo la vita continua. Freeze di FD/file/namespace e close dopo i reader restano precondizioni. |
| EOF e frontiere | `build.lisp:28–35` usa `file-size = size`, offset file zero e verifica `64 <= P <= size`, COMPLETE con `P = size`, TAIL con `P < size`. Lo scratch rappresenta il file dall'offset zero: P è quindi assoluto. | Nessuna misura EOF/fstat: un size non completo viola la precondizione. Readonly non impedisce una scrittura esterna. |
| Coda e testimoni | `decisions-build.lisp:178–190` esegue prima lo scanner; `scan.lisp:181–184` cerca testimoni prima di restituire TAIL. `scan.lisp:144–158` visita ogni posizione candidata entro budget e segnala ricerca incompleta o corruzione durevole. | La coda esclude l'intero lotto fallito. Non attesta che il supporto o il file restino sani dopo il ritorno. |
| Duplicati e assenza | `decisions-build.lisp:120–153` coalesce TXID uguali solo dopo confronto di CSN e insieme canonico dei partecipanti; conflitto con `:decision-conflict`. `decisions-sort.lisp:54–66` rifiuta partecipanti ripetuti. `decisions-query.lisp:35–43,69–78` distingue presenza/CSN zero e verifica ID16 anche per TXID assente. | Semantica delegata al replay canonico; questa lettura non riesegue le sue campagne pregresse. |
| Risoluzione ACTIVE | `active.lisp:38–42` passa la tabella verificata al lettore canonico. `recovery-active/resolve.lisp:13–23` controlla partecipante e concordanza OUTCOME/DECISION prima della classificazione. | Nessun fallback da NIL o da un errore del lettore. Il risultato ACTIVE non conserva la tabella (`recovery-active/types.lisp:10–27`); pubblicazione e dimenticanza delle decisioni sono fuori perimetro. |

### Bounds e inoltro dei budget

Ponendo `H = 64`, `N = size`, `C = chunk`, il preflight impone `N >= H`,
`C > 0`, `N <= max-bytes` e scratch lungo almeno N. Il ciclo di
`read.lisp:56–59` ha `ceiling((N-H)/C)` iterazioni. Per ogni iterazione
eseguita, `H <= start < end <= N`, con `end = min(N, start+C)`.
Per N = H non legge il corpo; l'ultimo chunk può essere corto.
Il controllo di capacità copre `max(H, min(N-H,C))`. L'aritmetica intera
Lisp non introduce un wrap degli offset prima del `min`.

Il limite riguarda le chiamate logiche a `leggi-esatto`: gli short read
possono richiedere più chiamate al backend. La primitiva I/O ha un ciclo
limitato dal conteggio dei byte e richiede progresso positivo
(`io/transfer.lisp:31–38,64–76`). Non si deducono tempi massimi di syscall.

In `build.lisp:28–32` sono inoltrati al replay `max-bytes`, `max-batches`,
`max-batch-records`, `max-batch-bytes`, `max-decisions`, `max-participants`
e `max-participants-per-decision`; `max-search-bytes` riceve `max-bytes`.
`chunk-bytes` limita la lettura locale, non lo scanner. Il budget byte del
wrapper include l'header; il budget scanner limita il corpo, dopo il più
restrittivo controllo `size <= max-bytes` del wrapper.

I conteggi fisici e cumulativi precedono la coalescenza: controllo DECISION
in `decisions-build.lisp:183–184`, controllo dei partecipanti alle righe
62–66, copie alle righe 89–95. I duplicati consumano budget prima di essere
coalescenti; un errore non diventa presumed abort. Zero è ammesso per i
conteggi DECISION/partecipanti nel caso vuoto, non per chunk o numero
massimo di lotti della configurazione scanner (`scan.lisp:68–74`).

Nel wrapper ACTIVE gli otto budget esposti sono inoltrati senza sostituzioni
(`active.lisp:28–31,40–42`, confrontati con `recovery-active/build.lisp:32–35`):

| Keyword | Valore trasmesso |
|---|---|
| `:chunk-bytes` | `chunk-bytes` |
| `:max-bytes` | `max-bytes` |
| `:max-batches` | `max-batches` |
| `:max-batch-records` | `max-batch-records` |
| `:max-batch-bytes` | `max-batch-bytes` |
| `:max-records` | `max-records` |
| `:max-prepared` | `max-prepared` |
| `:max-outcomes` | `max-outcomes` |

### Errori tipizzati e gestione

| Origine | Condizione / `reason` osservabile nel codice |
|---|---|
| UUID non lungo 16 byte | `invalid-argument / :archive-recovery-identity`, `types.lisp:20–21`. |
| Alias, chunk o configurazione iniziale errata | `invalid-argument / :archive-recovery-alias` oppure `:archive-recovery-arguments`, `read.lisp:15–18`; scanner/replay propagano i propri motivi. |
| Header fisicamente attestato troppo corto | `corruption-detected / :archive-recovery-header-truncated`, `read.lisp:19–20`. |
| Budget totale file | `resource-exhausted / :archive-recovery-byte-budget`, `read.lisp:21`; capacità I/O: `:io-byte-budget`. |
| Range scratch o ID16 | `invalid-argument / :buffer-range` o `:serie-id-length`, tramite le deleghe. |
| Header integro ma incompatibile | `corruption-detected / :log-header-crc`, `:log-magic`, `:log-reserved`, `:log-identity`; versione ignota: `unsupported-format / :file-version`. |
| Capacità errata o chiusa | `invalid-argument / :io-mode`, `io-fault / :io-unavailable`; lettura senza progresso: `:io-eof` o `:io-invalid-progress`; syscall: `:io-syscall`, tramite `io`. |
| Ambito differente | `invalid-argument / :active-recovery-archive`, `active.lisp:15–16`, prima dell'I/O ACTIVE. |
| Replay non valido | Propagati `log-corruption / :log-durable-corruption`, budget scanner/replay, `:decision-conflict`, `:decision-duplicate-participant` e condizioni dei codec. |
| Risultati interni incoerenti | `invariant-violation / :archive-recovery-preflight`, `:archive-recovery-header-read`, `:archive-recovery-header`, `:archive-recovery-read`, `:archive-recovery-prefix`. |

Il modulo non intercetta queste condizioni e non restituisce risultati
parziali in loro sostituzione. La transizione FAULTED e la registrazione
sono demandate al controller; non sono certificate in questo incarico.
Le violazioni dei tipi precontrattuali possono segnalare `type-error`, come
dichiarato nelle docstring: non vengono tradotte localmente in
`arcdocdb-error`. La gestione al confine C1 di queste condizioni e dei
fallimenti di allocazione resta da verificare; non si attesta conformità
incondizionata a COD-22 o chiusura di COD-24 con la sola propagazione.

## Checklist C1 — i dodici punti dello standard

«Coerente staticamente» indica soltanto una conclusione di lettura.
«Aperto» richiede evidenza ulteriore, che il coordinatore raccoglie altrove.

| N. | Punto dello standard | L1 — stesso revisore | L2 — stesso revisore |
|---|---|---|---|
| 1 | Requisito REQ e ADR indicati e coerenti | Marcatori letti in tutte le definizioni; coerenti con ADR-0041/0052 per il sottocompito. | Confermata la distinzione tra lettura decisioni e completamento del Recovery Manager. |
| 2 | Invarianti elencati e test che fallirebbe alla violazione | Interessati INV-F1/F2/F3, INV-A2/A4/A7/A8/A9, INV-T4/T5, INV-S7, INV-P5/P6 e INV-X3; INV-A10/A11 come vincoli di assenza di effetti durevoli. | Legami statici descritti sopra. Prove di violazione non eseguite né dichiarate coperte: aperto. |
| 3 | Ogni errore ha tipo, gestione e test | Condizioni e reason censiti sopra; nessun gestore generico locale che nasconda il fallimento. | Propagazione confermata; gestione controller, TYPE-ERROR, allocazioni e prove dedicate restano aperti. |
| 4 | Cicli/attese limitati, ricorsione limitata | Ciclo corpo con limite esplicito; scanner con budget e query binarie limitate. | Bounds riesaminati, nessuna ricorsione o attesa su lock introdotta. Blocco I/O ammesso solo nel compito I/O previsto dalla precondizione. |
| 5 | Assenza di allocazioni sul percorso caldo, misurata | Lettura/replay sono apertura con allocazioni esplicitamente ammesse; copia UUID e tabella posseduta. | Nessuna misura heap, RSS o query: punto misurato aperto, nessuna promessa heap zero. |
| 6 | Nessun dato non verificato lascia il modulo | Header prima del corpo, scanner prima dei payload/copie, risultato dopo frontiere e controllo capacità. | Query solo scalari; span e lunghezza ID16 verificati anche in assenza. Coerente staticamente sotto EOF/stabilità autorevoli. |
| 7 | Decisioni composte nella tabella | DAR-D01 = `read.lisp:17`; DAR-D02 = `read.lisp:53`; DAR-D03 = `build.lisp:33–34`. | Censimento delle tre forme `and` confermato, inclusi i rami COMPLETE/TAIL di DAR-D03. Copertura condizione per condizione non attestata. |
| 8 | Proprietario dello stato condiviso dichiarato e rispettato | OWNER/SHARED nei sei file; scratch esclusivo, copie private, risultato readonly. | Nessuna mutazione della tabella dal wrapper; freeze e lifetime affidati al controller. Coerente staticamente. |
| 9 | Matrice aggiornata e `make check` superato | REQ e collegamenti della matrice letti; modulo registrato in ASDF. | Nessuna rigenerazione della matrice o esecuzione di `make check`; esito richiesto dallo standard aperto. |
| 10 | Nessuna regola violata senza deviazione | R1 su COD-25; nessuna deviazione approvata nel registro letto. FTYPE, slot readonly e safety 3 presenti. | R1 confermato. Build senza avvisi, lint e conformità completa non attestati; gestione errori/invarianti limitata come sopra. |
| 11 | Nessun nuovo lock/attesa/scrittura condivisa per operazione tra Serie | Solo letture delle decisioni e scratch privati; nessun nuovo lock, CSN o registro globale. | Confermato nel modulo; apertura dell'Archivio precede il recovery delle Serie. Nessuna misura di parallelismo eseguita. |
| 12 | Punto di atomicità, preparazione/idempotenza, rimozione autorizzata | Nessun cambiamento durevole: solo lettura e costruzione in memoria; nessun punto atomico nuovo. | Nessun truncate/delete/rename/flush o pubblicazione introdotto. Gli effetti durevoli successivi e la loro idempotenza sono fuori perimetro. |

## Limiti e consegna

Il freeze delle esecuzioni richiesto dal coordinamento è rispettato. Questa
lettura non importa come propri risultati le precedenti evidenze locali e
non aggiunge prove, campagna o risultati runtime. Restano aperti test dei
nuovi ingressi, FI, mutazioni, copertura/MC/DC, compilazione e verifica
completa, allocazioni/prestazioni e integrazione del controller/fail-stop.

Il worktree è condiviso: durante la lettura sono comparse modifiche altrui
in `arcdocdb.asd`, `tools/foundation-coverage.lisp` e `tests/recovery-archive/`.
Non sono state modificate o ripristinate da questo incarico; le conclusioni
non attestano la versione finale di tali lavori o del worktree intero.

**Unico file scritto da questo incarico:**
`docs/implementazione/decisioni-recuperate-revisione.md`.
Nessun sorgente prodotto modificato; nessun commit. Le due letture e questa
checklist costituiscono la consegna statica, con R1 aperto e senza pretesa
di qualifica completa.

## Addendum — seconda revisione statica della patch R1

Data: 2026-10-15. Revisore: lo stesso Codex delle letture L1 e L2.
Seconda revisione successiva alla correzione applicata dall'autore, limitata
al diff di `src/recovery-archive/read.lisp`; non costituisce un secondo
revisore indipendente né una nuova revisione completa del modulo.

L'osservazione originaria, la checklist e i riferimenti di riga precedenti
restano conservati e descrivono il sorgente osservato alla revisione
`c6a21d810dabdc1218efbbeaa1f7dab560da8893`. L'HEAD osservato è ancora quello;
la patch esaminata è nel worktree. Il diff prodotto letto riporta due soli
hunk, con identificativi abbreviati dei blob `a07e6357..b46823a3`.
Le righe indicate qui sotto si riferiscono al file corretto, non aggiornano
retroattivamente quelle dell'osservazione originaria.

| Controllo della patch | Evidenza statica | Esito |
|---|---|---|
| Header: operazione separata dall'asserzione | `read.lisp:39–41`: `let` assegna a `next` il risultato di `leggi-esatto`; il predicato di `unless` confronta soltanto `next` con `+log-header-bytes+`. | Il predicato non effettua I/O né scrive nello scratch. |
| Corpo: operazione separata dall'asserzione | `read.lisp:59–61`: a ogni iterazione `let` assegna a `next` il risultato della stessa lettura; `unless` confronta soltanto `next` con `end`. | Il predicato non effettua I/O né scrive nello scratch. |
| Numero, argomenti e ordine delle letture | Resta una chiamata header con `input scratch 0 +log-header-bytes+ 0`, dopo `check-range` e prima della verifica dell'header; resta una chiamata corpo con `input scratch start end start` per iterazione. | Nessuna duplicazione, omissione o variazione d'ordine introdotta nei due hunk. |
| Condizioni e propagazione | Restano `invariant-violation / :archive-recovery-header-read` e `invariant-violation / :archive-recovery-read`, con `:offset start` nel corpo. Nessun gestore, retry o cleanup aggiunto; le condizioni di `leggi-esatto` continuano a propagarsi prima del confronto. | Stessi controlli ed errori nel flusso esaminato. |
| Ambito e limiti | I nuovi `next` sono lessicali; quello dell'header termina prima del successivo `multiple-value-bind`. Conteggio del ciclo, `start/end`, controllo finale della capacità, firme e budget non cambiano nei due hunk. | Nessuna interferenza lessicale o variazione dei bounds individuata nella patch. |

**Stato aggiornato: R1 chiuso esclusivamente sul piano statico per la patch
esaminata.** L'I/O è ora eseguito prima del controllo e i due predicati di
invariante sono privi dell'effetto collaterale contestato da COD-25.
Non sono emersi nuovi rilievi nei due hunk. La voce R1 aperta e il punto 10
della checklist precedente restano testimonianza della prima versione;
questo addendum registra la successiva risoluzione statica.

Nessuna esecuzione runtime, prova, compilazione, lint o benchmark svolto.
La chiusura non attesta equivalenza misurata, assenza di regressioni runtime,
conformità completa del modulo o qualifica C1; tutti gli altri limiti della
revisione originaria restano validi. In questo seguito è stato soltanto
aggiunto il presente addendum a `docs/implementazione/decisioni-recuperate-revisione.md`;
nessun altro file modificato e nessun commit eseguito. Incarico concluso per
il freeze coordinato.
