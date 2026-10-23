# Decisioni del collegamento worker–Serie

Inventario C1 preparato il 2026-10-11 dalla lettura dei tre sorgenti con
corpi di funzione del namespace `arcdocdb.execution.series`, inizialmente
su `2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11` e reintegrato senza modifiche
ai quattro sorgenti su `8101eb856cbe9d7540682babb53afb00fde30f70`.
I numeri di riga identificano
questa lettura, successiva alle correzioni WS-REV-01/02/03/04; il nome
della funzione e la forma restano il riferimento se cambia l'impaginazione.
Il quarto sorgente contiene soltanto la definizione del package. ASDF lo
carica, insieme ai tre corpi, dopo `series/retirement`, quando execution,
WAL e controller Serie sono già disponibili; nessun ciclo di caricamento.

| Sorgente letto | SHA-256 |
|---|---|
| [`worker-package.lisp`](../../src/series/worker-package.lisp) | `881a2958ddb8f5781954d4c59d7467e34c03c01fbb2fea43dc06e9e2050a1f37` |
| [`worker-types.lisp`](../../src/series/worker-types.lisp) | `a366799fd9b938bfaa48b0ffda228ff8369ab9acb5b5ead7f081dfc66ab2c81a` |
| [`worker-boundary.lisp`](../../src/series/worker-boundary.lisp) | `793d401d1b9acc7b67923d815560f277f3d390ca050740f735f07d88dbacfe73` |
| [`worker-run.lisp`](../../src/series/worker-run.lisp) | `f448442c5f9233f492bb8642206ec4913f7b2f5f3c9a1fdf05896a439f1d429f` |

REQ-CON-001/002/004/005 e REQ-AFF-001/004/008; INV-P1/P2/P5/P6, INV-A4
e INV-V4; [ADR-0005](../adr/0005-writer-logico-per-serie.md),
[ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) e
[ADR-0045](../adr/0045-modello-di-esecuzione.md).
Valgono gli [standard C1](../affidabilita/standard-di-codifica.md), in
particolare COD-10/13/21/24/40/45/46/53/54.

Questa è una lettura statica e una preregistrazione delle prove richieste.
Non attribuisce esiti ai test letti, ai benchmark o alla copertura; tali
esiti devono essere collegati ai rapporti grezzi sul congelamento effettivo.
Non attesta revisione umana, MC/DC o assenza universale di allocazioni.

## Identità, precondizioni e stati

Il collegamento conserva tre riferimenti immutabili: contesto worker,
writer programmabile e controller Serie. Il caller stabilisce all'avvio
la sola associazione valida fra quel writer logico e quella Serie e
prealloca i collegamenti necessari ai worker. La factory non verifica
membership o unicità globale e non crea un pool. Ogni collegamento
appartiene al thread creatore del proprio contesto, senza rientranza.
Le API raw di worker/Serie non si usano per cambiare le capacità di un
tratto attivo; i controlli delle lease catturate rilevano i bypass descritti
nelle fixture, senza trasformarli in un trasferimento autorizzato.

| Fase del link | Obbligo locale | Fase worker ammessa |
|---|---|---|
| `:idle` | Lease writer e Serie zero; generation conservata. | Begin richiede separatamente `:claimed` del writer associato. |
| `:active` | Generation positiva, lease writer catturata corrente, lease Serie corrente; il batch resta nel worker. | `:running` oppure `:batch`. |
| `:closing` | Generation e lease writer correnti; nessun nuovo acquire/pop/ack. La lease Serie può essere zero per rifiuto o release già conclusa. | `:running` oppure `:finishing`. |
| `:faulted` | Stato terminale e condizione del bridge conservata; nessuna riparazione, cessione o release implicita. | Worker terminale; una sua diagnosi terminale preesistente viene conservata. |

Il token identifica soltanto la coppia link/tratto. La lease del
controller identifica la coppia controller/generation e il thread;
il token batch identifica la coppia contesto worker/batch. Sono tre
capacità distinte, anche se i loro interi possono coincidere.

Begin acquisisce il writer prima della Serie e non estrae messaggi.
Serie busy o generation esaurita restituiscono token, `:closing` e la
ragione distinta; il caller deve completare il termine esplicito prima
del ricircolo. Termina rifiuta il debito batch prima di qualsiasi release,
fissa `:closing`, rilascia Serie, azzera la sua lease soltanto dopo il
successo, poi termina il worker. End busy conserva `:closing` e la lease
writer: il tentativo successivo completa soltanto end e non ripete release.

## Inventario completo delle decisioni

`types:N`, `boundary:N` e `run:N` indicano i rispettivi sorgenti sopra.
Ogni riga distingue il ramo vero da quello falso; le funzioni delegate
non sono appiattite in decisioni locali. Il punto T01 censisce il controllo
owner delegato; gli altri 32 punti censiscono le forme di controllo
esplicite dei tre nuovi sorgenti. Le unioni `or` nei tipi non sono
decisioni COD-54.

| ID / posizione | Funzione e forma | Rami, condizione ed effetto |
|---|---|---|
| T01 / types:22,25 | `%check-owner-worker-serie` → `execution::%check-owner-worker` | Thread `eq` owner: prosegue; estraneo: `invalid-argument :worker-owner`, prima del handler e senza scritture. Non vi è un nuovo predicato locale. |
| T02 / types:33 | `%check-writer-worker-serie`, `unless (plusp generation)` | Vero: generation valida; falso: `invariant-violation :worker-serie-generation`, mai semplice rifiuto di token. WS-REV-02. |
| T03 / types:35 | Stesso helper, `unless (eq worker-writer bound-writer)` | Identità esatta: prosegue; altro/NIL: invariante binding. |
| T04 / types:37 | Stesso helper, `unless (plusp writer-lease)` | Token positivo: prosegue; zero: invariante lease. |
| T05 / types:39 | Stesso helper, `unless (= context-lease captured-lease)` | Lease identica: verifica completa worker delegata; diversa: invariante lease prima di pop/end. |
| T06 / types:51 | `%check-worker-serie`, `unless (null fault)` | Nessuna diagnosi in fase operativa: prosegue; diagnosi non NIL: invariante stato. |
| T07 / types:53 | Stesso helper, `case state` | Tre clausole operative `:idle`, `:active`, `:closing`; `otherwise` segnala invariante. `:faulted` entra soltanto nei getter o nel gate terminale della macro. |
| T08 / types:55 | Clausola idle, `unless (zerop writer-lease)` | Zero: prosegue; positivo: invariante lease, senza cancellare il campo. |
| T09 / types:57 | Clausola idle, `unless (zerop series-lease)` | Zero: prosegue; positivo: invariante lease, senza release correttiva. |
| T10 / types:61 | Clausola active, `unless (member worker-state '(:running :batch))` | Entrambe le fasi ammesse; ogni altra fase è invariante prima della verifica Serie. Segue `series::%check-owner` della lease catturata. |
| T11 / types:67 | Clausola closing, `unless (member worker-state '(:running :finishing))` | Entrambe ammesse; ogni altra fase è invariante. Nessuna lettura del controller, anche dopo la sua migrazione. |
| T12 / types:78 | `%require-worker-serie`, `unless (member link-state states)` | Stato nella lista letterale: controlli della forma/capacità; fuori lista: `resource-exhausted :worker-serie-state`, prima di leggere la Serie. |
| T13 / types:87 | `%check-token-worker-serie`, `unless (typep token 'index)` | Index: prosegue; tipo/range errato: `invalid-argument :worker-serie-token`. |
| T14 / types:88 | Stesso helper, `unless (plusp token)` | Positivo: prosegue; zero: stesso rifiuto ordinario, nessuna mutazione. |
| T15 / types:89 | Stesso helper, `unless (= token generation)` | Corrente: prosegue; stale/diverso: stesso rifiuto ordinario prima di mutare. |
| B01 / boundary:15–17 | `%fault-serie-posseduta`, `when (and A B C)` | Unica nuova decisione composta: marca `:archive` soltanto se tutte e tre le condizioni sono vere; altrimenti nessuna scrittura del controller. Coppie in tabella separata. |
| B10 / boundary:27 | `%fault-worker-serie`, primo `unless (eq worker-state :faulted)` | Worker operativo: può esaminare le allowlist B02–B05; worker già terminale: le salta tutte e rende terminale anche il bridge. Un fault già classificato dal sottopasso non torna benigno per coincidenza di ragione nel passo esterno. WS-REV-04. |
| B02 / boundary:28 | Stesso helper, `when (typep condition 'resource-exhausted)` | Classe resource: controlla B03; altra classe: passa a B04. La sola ragione non autorizza recupero. |
| B03 / boundary:29 | Stesso helper, `when (member reason resources)` | Ragione prevista per quel passo: ritorna NIL senza mutare; inattesa: prosegue verso il fault. |
| B04 / boundary:30 | Stesso helper, `when (typep condition 'invalid-argument)` | Classe invalid: controlla B05; altra classe: fault, salvo ritorno già avvenuto da B03. |
| B05 / boundary:31 | Stesso helper, `when (member reason arguments)` | Ragione invalid prevista: ritorna senza mutare; inattesa: fault. Nessun recupero di invarianti o errori runtime con la stessa ragione. |
| B06 / boundary:35 | Stesso helper, secondo `unless (eq worker-state :faulted)` | Worker ancora operativo: classifier con liste vuote lo rende terminale; già terminale: non sovrascrive la sua prima diagnosi. WS-REV-01. |
| B07 / boundary:38 | Stesso helper, `unless (eq saved-fault condition)` | Identità della condizione conservata: prosegue; errore di registrazione: invariante stato. |
| B08 / boundary:40 | Stesso helper, `unless (eq link-state :faulted)` | Terminale: ritorna; altrimenti invariante stato. |
| B09 / boundary:52 | `%passo-worker-serie`, `when (eq link-state :faulted)` nell'espansione | Terminale: `resource-exhausted :worker-serie-state` prima di installare il handler; operativo: esegue il corpo sotto il confine. La prima diagnosi non viene sostituita dal gate. |
| R01 / run:15 | `%acquire-worker-serie`, `unless (eq state :closing)` | Closing: prosegue; altra fase: invariante stato prima dell'acquisizione. |
| R02 / run:17 | Stesso helper, `unless (zerop series-lease)` | Zero: può acquisire; positiva: invariante lease, nessun acquire duplicato. |
| R03 / run:20,25 | Stesso helper, `handler-case` con la sola clausola `resource-exhausted`, interno a `%passo-worker-serie (link () ())` in run:14 | Successo: conserva lease Serie e passa active; resource: R04; altre condizioni: prima il confine locale senza ragioni recuperabili, poi quello esterno di begin. |
| R04 / run:26 | Clausola resource, `unless (member reason '(:serie-busy :serie-lease-generation))` | Due ragioni esatte: ritorna la ragione in closing; ogni altra resource viene risollevata EQ dentro il boundary nil/nil, diventando terminale anche se la ragione fosse ordinaria in un diverso sottopasso di begin. WS-REV-03. |
| R05 / run:46 | `inizia-worker-serie`, `unless (eq claimed-writer bound-writer)` | Identità: prosegue; altra: `invalid-argument :worker-serie-binding` prima di begin writer. |
| R06 / run:48 | Stessa API, `when (= generation most-positive-fixnum)` | Al limite: `resource-exhausted :worker-serie-generation` prima di begin; sotto il limite: nuova lease writer, closing e incremento monotono. |
| R07 / run:103 | `termina-worker-serie`, `unless (member worker-state '(:running :finishing))` | Running/finishing: può chiudere; batch o altro: `resource-exhausted :worker-state` prima di release Serie. Il controllo della forma può rilevare prima un'invariante. |
| R08 / run:106 | Stessa API, `when (plusp series-lease)` | Positiva: una release protetta dal boundary nil/nil in run:107 e poi azzeramento; zero: nessuna release e nessuna lettura Serie. End worker segue entrambi i rami. Nessuna ragione inattesa della release è recuperabile tramite la allowlist esterna di end. WS-REV-04. |

Factory e due getter non contengono altre decisioni: delegano T01;
la factory delega inoltre T06–T09 prima di restituire il link. Le API
lease/pop/ack aggiungono soltanto il confine B09, T12 e T13–T15, poi
delegano al controller o al worker. La restituzione di stato e ragione
da begin non aggiunge un `case`: è verificata dalle postcondizioni di
`%acquire-worker-serie`. Il valore `:idle/:schedule` di end viene dal
worker, che distingue tali esiti e conserva l'obbligo di ricircolo.

## Decisione composta e coppie indipendenti

In `%fault-serie-posseduta`:

- A = `(plusp captured-series-lease)`;
- B = `(eq controller-owner sb-thread:*current-thread*)`;
- C = `(= controller-lease-generation captured-series-lease)`.

Il test scritto `TEST-REQ-AFF-004-WORKER-SERIE-OWNED-FAULT-THREE-INDEPENDENT-TRUTH-PAIRS`,
in [`worker-bridge.lisp`](../../tests/series/worker-bridge.lisp), dichiara
quattro scenari indipendenti. La tabella è la lettura manuale delle
assegnazioni e del risultato richiesto, non un risultato strumentale.

| Scenario della fixture | A | B | C | Decisione richiesta | Contrasto |
|---|---|---|---|---|---|
| `:all-true` | V | V | V | Marca Archivio; solo health può cambiare. | Base comune. |
| `:lease-zero` | F | V | V | Nessuna scrittura del controller. | Con base cambia soltanto A. |
| `:owner-other` | V | F | V | Nessuna scrittura del controller. | Con base cambia soltanto B. |
| `:generation-stale` | V | V | F | Nessuna scrittura del controller. | Con base cambia soltanto C. |

Per A falso la fixture pone sia la lease catturata sia la generation
controller a zero, mantenendo owner uguale al thread: C rimane vero.
Questo stato è FI privata quiescente; non è una lease produttiva e
nessuna API owner viene invocata prima di ripristinare i campi FI.
Per B falso owner diventa NIL con lease/generation intatte; per C falso
la generation diventa lease+1 con owner e lease intatti. Ogni scenario
usa un controller sano distinto e confronta l'immagine prima/dopo,
eccetto la health nel caso tutto vero. Il cleanup FI non resetta health.

`and` cortocircuita: con A falso B/C non sono valutati, con B falso C
non è valutato. I valori della tabella sono quelli delle assegnazioni;
non si deduce la loro valutazione dinamica da sb-cover. Le coppie
manuali e il rapporto dei rami non attestano MC/DC del modulo.

## Allowlist per passo e classe di errore

Il confine non intercetta condizioni non `error`. Intercetta `error`
soltanto per registrare la transizione del worker, con handler locale
`dynamic-extent`: non sopprime né risolleva la condizione originaria.
Le liste sono letterali e finite; la ragione è ammessa soltanto nella
classe dichiarata e nel passo che segue.
Le allowlist vengono esaminate soltanto se il worker non è già terminale,
come stabilito da B10; un fault del sottopasso impedisce ogni conversione
successiva in rifiuto ordinario.

| API | Resource recuperabili | Invalid recuperabili | Fasi ammesse |
|---|---|---|---|
| `inizia-worker-serie` | `:worker-serie-state`, `:worker-state`, `:worker-serie-generation`, `:writer-queue-busy` | `:worker-serie-binding` | Link idle; worker claimed. |
| `%acquire-worker-serie`, boundary interno | Nessuna | Nessuna | Closing; writer acquisito. R03/R04, interno anche a questo boundary, converte soltanto le due resource Serie dichiarate. |
| `lease-worker-serie` | `:worker-serie-state` | `:worker-serie-token` | Active; worker running/batch. |
| `preleva-worker-serie` | `:worker-serie-state`, `:worker-state`, `:worker-generation`, `:writer-queue-busy` | `:worker-serie-token`, `:writer-target` | Active; il pop worker richiede running. |
| `conferma-worker-serie` | `:worker-serie-state`, `:worker-state` | `:worker-serie-token`, `:worker-batch` | Active; ack worker richiede batch. |
| `termina-worker-serie` | `:worker-serie-state`, `:worker-state`, `:writer-queue-busy` | `:worker-serie-token` | Active o closing; worker running/finishing. |
| Release Serie, boundary interno di termina | Nessuna | Nessuna | Closing; lease Serie positiva, prima del suo azzeramento. |

Le resource `:serie-busy` e `:serie-lease-generation` sono convertite
in `:closing` dal solo handler R03/R04, dopo begin writer, con la ragione
come terzo valore. Non sono nella allowlist esterna. Esaurimento locale
e esaurimento controller non sono retry ciechi: il primo conserva idle
senza lease nuova, il secondo impone chiusura della lease writer acquisita.

In begin vi sono due istanze dinamiche del confine: il primo boundary
ammette i rifiuti delle precondizioni e del writer, il secondo racchiude
soltanto `%acquire-worker-serie` con entrambe le liste vuote. Il
`handler-case` della Serie è ancora più interno e consuma i due rifiuti
attesi prima dei boundary. Se risolleva una resource sconosciuta oppure
si propaga un altro errore, il boundary interno rende terminali i contesti
prima che quello esterno possa riconoscere una ragione valida soltanto
per un passo diverso. Il boundary esterno non resetta il fault già
registrato: B10 salta le sue allowlist perché il worker è già terminale,
la stessa condizione continua a propagarsi e lo stato resta terminale.
Questa separazione
del sottopasso è WS-REV-03; non richiede un retry o un cleanup.

Termina contiene analogamente due boundary dinamici mentre deve ancora
rilasciare Serie: quello interno, con liste vuote, protegge soltanto la
release; quello esterno ammette i rifiuti di fase/token e busy del termine
writer. Una ragione `:writer-queue-busy` o `:worker-serie-token` iniettata
nella release non autorizza recupero: il boundary interno marca il fault
prima di quello esterno. Se la release fallisce, il suo token non viene
azzerato e il writer non viene terminato. Dopo release riuscita, retry di
end con token Serie zero non reinstalla il boundary della release.

Ragione corretta nella classe sbagliata, resource/invalid inattese,
`invariant-violation`, `io-fault` e altri errori runtime richiedono
fault terminale. La condizione del bridge resta lo stesso oggetto EQ;
se il worker era già terminale, conserva la sua prima condizione,
anche quando è diversa da quella del bridge. Wrong-thread e gate
faulted stanno prima del handler. Factory e getter non installano handler.

## Controlli delegati e coupling privato

| Delegato letto | Obbligo e confine |
|---|---|
| `execution::%check-owner-worker` | Owner del contesto; non legge Serie o writer sotto guard. |
| `execution::contesto-worker-writer-lease` | Confronto scalare con lease writer catturata; non ricostruisce un token da un ruolo migrato. |
| `execution::%check-worker` | Forma del worker, riferimenti/lease/debito/quote, cursori e ready; le sue decisioni restano nell'[inventario worker](writer-worker-decisioni.md). |
| `execution::%richiedi-worker` | Claimed verificato prima di begin; nessuna adozione o cessione implicita. |
| `execution::%classifica-guasto-worker` | Solo sul worker non ancora terminale, liste vuote: errore originale registrato senza reset di riferimenti o debito. |
| `series::%check-owner` | Thread, lease positiva, generation e ring corrente prima di utilizzare la Serie. Invarianti ring marcano Archivio; lease stale resta condizione propagata. |
| `series::controllore-serie-owner` e `...-lease-generation` | Solo letture scalari nel gate di fault B01; nessun check-ring che possa sostituire l'errore originale. |
| `series::%mark-fault :archive` | Una parola terminale, senza lease ricostruita, callback o verifica del ring; invocata soltanto per A/B/C veri. Non coordina altre Serie. |
| API pubbliche worker e Serie | Le loro pre/postcondizioni restano attive; pop/ack/end e ordine del controller non sono reimplementati dal bridge. |

Questo coupling è intenzionale fra le due fondazioni dello stesso
sistema ASDF: ogni modifica a owner/generation/lease/check/classifier
richiede revisione dell'integrazione. Il bridge non legge la Serie in
closing dopo release, anche se un altro worker l'ha già acquisita.
Un fault dopo release può rendere terminale soltanto bridge e worker;
il caller deve fermare l'Archivio quando l'esito lo richiede. Non è
sicuro marcare il controller di un tratto successivo usando una lease stale.

## Limiti, asserzioni e macro

Non vi sono cicli, ricorsione, attese, thread, callback, lookup globale,
I/O o retry nei tre sorgenti. Le liste `member` hanno lunghezza massima
quattro per resource, due per invalid e due per fasi: scansioni bounded.
Ogni passo è O(1), oltre alla copia batch bounded esistente; begin non
tocca ready, end restituisce al worker l'obbligo che il caller ricircola.
La factory alloca soltanto in fase di preallocazione. L'assenza di heap
sul percorso normale richiede la misura registrata separatamente.

Conteggi sintattici locali della lettura: si conta una base più ogni
`when`/`unless`, due ingressi booleani ulteriori per l'`and` a tre
condizioni, tre clausole non default del `case`, e la clausola del
`handler-case`; le decisioni delegate restano nelle proprie funzioni.
Il gate B09 introdotto dall'espansione è contato separatamente per ogni
istanza, senza appiattire il classifier nel chiamante. Il massimo è 9:
`%check-worker-serie` e `%fault-worker-serie`; `%fault-serie-posseduta`
è 4, `%check-writer-worker-serie` è 5. `%acquire-worker-serie` è 6 incluso
il gate macro, begin è 4, lease/pop/ack sono 2, termina è 5 inclusi i suoi
due gate macro. Le altre funzioni sono al più 4. Nessun corpo supera
60 righe. Questi conteggi non sono misure di copertura o numero di
interleaving concorrenti.

Pre/postcondizioni sono composte attraverso helper e verificatori:
inizio controlla idle/claimed/identità/limite prima delle acquisizioni e
verifica la fase dopo acquire; pop/ack controllano fase, token e capacità
prima delle verifiche worker, che effettuano anche i postcheck; termine
verifica entrambe le capacità e il debito prima di release, e dopo end
controlla soltanto il link idle con lease azzerate. Il fault verifica
separatamente identità della diagnosi e stato terminale. I getter hanno
soltanto la precondizione owner perché servono anche alla diagnosi.

`%passo-worker-serie` valuta link una sola volta con un binding lessicale,
verifica owner e stato terminale fuori dal handler, poi restituisce
senza trasformazione tutti i valori del corpo. Il test scritto
`TEST-REQ-AFF-008-WORKER-SERIE-BOUNDARY-ONCE-VALUES-AND-EXACT-CONDITION`
legge l'espansione, conta l'unico riferimento di input e verifica
valutazione singola, tre valori, condition EQ e immagini di rifiuto.
Il test non autorizza a dedurre heap nullo dalla sola espansione.
La stessa macro ha sette siti nel prodotto: cinque API pubbliche,
il sottopasso acquire Serie e il sottopasso release Serie. I due
handler simultanei di begin e, quando serve release, di termina sono
locali `dynamic-extent`; la loro assenza di heap richiede comunque
misura sul sorgente successivo a WS-REV-03/04.

Un'uscita nonlocale che non segnala `error` non viene intercettata:
non vi è cleanup automatico che rilasci, annulli o riusi capacità.
L'integrazione non consente abbandono nonlocale di un tratto e richiede
un confine del coordinatore per gli esiti incerti. Il bridge non applica
payload, non conferma client, non prova FINE I/O da `:written`, non
riusa buffer e non realizza shutdown o fairness del pool.

## Obblighi delle prove e rapporto grezzo

Le fixture scritte censiscono doppia lease e FIFO, quote e generazioni,
prima e seconda contesa, end busy dopo release Serie, debito batch,
token stale/tipo/zero, target/span/alias, identità binding, entrambi gli
esaurimenti, owner estraneo nelle quattro fasi, release fault e errore
fra le release, owner/generation Serie stale, coppie B01, macro e FINE
I/O dopo fault. Due fixture con thread reali distinguono esclusione sullo
stesso controller da due controller attivi prima di qualsiasi release.
Questa lettura non attribuisce throughput, P99, scalabilità o correttezza
universale al loro interleaving finito.

La regressione WS-REV-01 deve preservare la condition EQ del worker già
faulted quando begin del link provoca un nuovo errore. WS-REV-02 deve
rendere terminale la generation link zero in active e closing, senza
trattarla come token caller errato. I rami delle asserzioni, i motivi
non previsti e le classi di errore errate devono restare nell'inventario
anche se una campagna finita non li raggiunge.
La regressione WS-REV-03 deve iniettare nell'acquisizione Serie ragioni
ordinarie soltanto altrove (`:writer-queue-busy`, `:worker-serie-binding`)
e un errore runtime, mantenendo la condition EQ, writer/token trattenuti
e controller non modificato se non ne è stata acquisita la lease.
WS-REV-04 richiede altre due regressioni: tre classi di errore nella
release Serie con ragioni ammesse soltanto dal passo esterno; errore
nel pop raw già classificato come terminale dal worker ma con ragione
ammessa dal bridge (`:worker-serie-token`). Devono conservare la
condition EQ, i token e il fault terminale, senza end o pop duplicati.

Il rapporto di copertura `series` deve conservare tutti i dodici file
`src/series/` (otto controller più quattro bridge), con denominatori
grezzi, rami mancanti e nessuna esclusione dei package/helper/delegati
interni alla directory. Le decisioni execution transitive hanno il
proprio inventario e rapporto: uno scope Series non le misura. Rapporti
grezzi e decisioni manuali non provano MC/DC, tutti i percorsi di
interruzione o tutta la gerarchia di errori del motore.
