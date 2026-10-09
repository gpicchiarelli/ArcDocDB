# Decisioni e obblighi del controller di Serie

Data: 2026-10-09. Perimetro: `arcdocdb.series`, controller limitato della
pubblicazione di una Serie e sole nuove preflight del ponte WAL. Base dichiarata:
`cf6091367853ec311fed7b05961a2812fd05a8f1`.

La matrice contrattuale è stata preparata prima della comparsa di `src/series/`.
L'inventario effettivo seguente deriva dalla lettura completa, aggiornata con
geometria del ring, fix P2 e ritiro I/O senza consegna (fase D, 42 funzioni). Identità dei file e
conteggi locali sono nella [revisione](controller-serie-revisione.md).
Non attesta esecuzioni, MC/DC, revisione umana o assenza di heap.

## Fonti e confini

- [ADR-0037](../adr/0037-lotto-sigillato.md): lotto come unità di pubblicazione,
  copertura distinta per livello, un compito I/O per log, buffer protetto fino al flush.
- [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md): token in registro
  limitato, risoluzione distinta dalla durability, nessun wrap del CSN.
- [ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md): guasto terminale,
  nessun retry I/O, responsabilità distinta fra Serie e Archivio.
- [Standard di codifica](../affidabilita/standard-di-codifica.md): C1,
  COD-10/13/21/24/40/43/45/46/54.
- [Ponte WAL–CSN](wal-csn.md): associazione al registro e al log originali,
  token conservato e precondizioni del resolver esistente.
- [Contratto del controller](controller-serie.md), scritto dal parent:
  ownership dell'effetto, progressi distinti e confini d'integrazione.

Indice hash, snapshot, scheduler, pool, protocollo di conferma al client e recovery
completo restano fuori dal perimetro di questa revisione. I relativi requisiti del
motore non diventano risultati dimostrati dal controller.

## Precondizioni da mantenere esplicite

| ID | Precondizione | Autorità e limite della verifica locale |
|---|---|---|
| P01 | La radice è opaca, immutabile e preparata dal writer fuori dal controller dopo la chiusura WAL. Anche `nil` è una radice valida. | Il controller verifica `eq` e ordine, non la struttura dell'indice o la sua immutabilità transitiva. |
| P02 | Un solo controller possiede registro/log della Serie; il log è un segmento esclusivo. | L'identità è quella degli oggetti sorgente, non una coppia file-id/versione. La factory non prova autonomamente l'unicità dei wrapper. |
| P03 | La chiusura usa `sigilla-lotto-con-csn`; l'adozione del lotto `:sealed` precede ogni dispatch I/O. | Full, busy e altri rifiuti lasciano il lotto/token al chiamante. Il solo SEAL preparato non è un commit durevole. |
| P04 | Il chiamante consegna un handoff sincronizzato attendibile della fine del compito I/O. | `:written` o un messaggio di avanzamento non prova la fine. `:durable`/`:faulted` sono accettabili per il ritiro solo insieme all'handoff conclusivo. |
| P05 | Il writer governa la lease e il proprio thread; un trasferimento richiede rilascio e nuova acquisizione. | Nessuna migrazione implicita di una lease numerica, né condivisione simultanea delle mutazioni. |
| P06 | Un'interruzione nonlocale nella finestra incerta root/stadio o registro/token richiede fail-stop dell'Archivio da parte del confine chiamante. | Non è sicuro annullare automaticamente o ritentare la pubblicazione in stato incerto. La lease trattenuta non dimostra da sola il fail-stop. |
| P07 | Il chiamante rilascia l'owner del gruppo con `riusa-gruppo` prima di `riusa-commit-serie`. | Riuso ammesso solo per lotto durevole, token risolto e consumatore ritirato. Nessun riuso dei buffer guasti. |
| P08 | Per `ritira-io-commit-serie`, il chiamante possiede la prova definitiva e sincronizzata che il compito con evento/generazione catturati sia stato ritirato oppure non sia mai stato accettato dallo scheduler. Prima annulla il gruppo mai scritto e ne rilascia l'owner. | Lotto sealed e owner nullo sono guardie locali necessarie; non provano da sole l'assenza di worker. Un rifiuto dello scheduler non autorizza ad abbandonare l'obbligo active. La API non revoca compiti. |

## Quattro progressi distinti

| Progresso | Transizione | Punto osservabile | Non implica |
|---|---|---|---|
| Pubblicazione root | `:preparato` → `:pubblicato` | CAS `expected-root` → `new-root` dopo tutte le preflight. | Token risolto, flush concluso o buffer libero. |
| Risoluzione token | `:pubblicato` → `:risolto` | Resolver WAL con registro e slot/high/low catturati nell'evento. | Ritiro del consumatore I/O o riuso del lotto. |
| Ritiro I/O | `:idle` → `:active` → `:retired` | Registrazione prima del dispatch; completamento dopo handoff di fine. | Pubblicazione, risoluzione token o owner del gruppo nullo. |
| FIFO | Cursore unresolved distinto dalla testa di ritiro | Risoluzione/annullamento del primo unresolved; riuso della testa del ring. | La testa occupata impedisca risoluzioni async successive. |

Il busy del registro dopo il CAS conserva `:pubblicato`, evento e token. Il ritorno
`:pendente, 0, 0` non è una misura di H. Il successivo tentativo esegue soltanto la
risoluzione. H viene restituito come due parole solo al successo del resolver.

## Autorità, identità e generazioni

| Oggetto | Identità richiesta | Rifiuto da dimostrare |
|---|---|---|
| Lease | Controller corrente + thread proprietario + generazione positiva corrente. | Lease vecchia, lease di altro thread, controller busy; rifiuto prima di mutare. |
| Evento | Stesso oggetto preallocato appartenente al ring del controller + generazione catturata alla registrazione. | Evento di altro controller anche con stessi numeri; vecchia generazione dopo riuso dello stesso oggetto. |
| Token | Registry originale `eq`, log originale `eq`, slot/high/low catturati. | Valori numerici uguali provenienti da registry/log distinti non trasferiscono autorità. |
| Radice | `expected-root eq planned-root` all'adozione; `expected-root eq published-root` al CAS. | Una catena pianificata diversa è rifiutata prima di adozione; mismatch interno al CAS richiede ambito Archivio. |
| Sorgenti della review | File, revisione base e impronta del contenuto letto. | Una lettura durante integrazione non certifica la revisione successiva o una campagna eseguita su sorgenti diversi. |

Le generazioni di lease/evento sono fixnum e non fanno wrap. L'evento libero conserva
la generazione corrente: non la si azzera al rilascio. Il numero deve essere
conservato dal chiamante insieme al riferimento all'evento; rileggere soltanto la
generazione corrente dopo il riuso eliminerebbe la protezione contro ABA.

## Matrice del contratto da confrontare con il prodotto

| ID | API/decisione attesa | Condizioni atomiche o ordine | Obbligo statico e futura verifica strutturata |
|---|---|---|---|
| C01 | Factory | capacity fra 1 e 1024, default 64; log segmento; offset valido; salute log. | Ogni configurazione invalida rifiuta prima della costruzione; root `nil` passa. |
| C02 | Acquisizione lease | Singolo CAS; thread e nuova generazione; budget prima dell'incremento. | Busy senza retry; generazione al massimo rifiutata senza wrap e senza trattenere una nuova lease. |
| C03 | Verifica lease | Thread corretto AND generazione corrente AND ownership acquisita. | Ciascun falso separatamente; nessuna mutazione del controller/evento. |
| C04 | Verifica evento | Oggetto del ring corrente AND generazione uguale. | Cross-controller e generazione stale distinti; stessi numeri non bastano. |
| C05 | Adozione | Controller sano; lotto sealed; token/log/registry; next-offset; CSN crescente; root pianificata; capacità; budget generazione. | Tutte le guardie prima di riferimenti/cursori/count; nessuna presa di un nuovo CSN. |
| C06 | CSN crescente | high precedente < high nuovo OR (high uguali AND low precedente < low nuovo). | High diverso, confronto low, uguaglianza e regressione; mai ricostruzione u64. |
| C07 | Dispatch | Sano; evento valido; consumer idle; budget active-io. | Doppio dispatch rifiutato; marcatura active e incremento prima della consegna al worker. |
| C08 | Fine I/O | Consumer active; lotto durable OR faulted; handoff conclusivo come precondizione. | Solo written respinto prima di decrementare; drenaggio ammesso dopo fault. |
| C09 | Pre-CAS | FIFO unresolved; stato `:preparato`; salute log; token sorgente; copertura al livello. | Invalidi/carenza copertura respinti senza CAS; guasto I/O noto Serie, incoerenza interna Archivio. |
| C10 | CAS radice | Radice osservata `eq expected-root`. | CAS una sola volta per lotto; root `nil` lecita; mismatch → faulted Archivio. |
| C11 | Risoluzione | Stato pubblicato; token catturato; resolver esistente. | Solo `resource-exhausted` con reason `:csn-busy` diventa pendente; altri errori non vengono normalizzati a busy. |
| C12 | FIFO unresolved | Evento = cursore di pubblicazione, non necessariamente testa di ritiro. | A async risolto ancora attivo non impedisce la risoluzione di B coperto; B non salta A unresolved. |
| C13 | Riuso | FIFO ritiro; risolto; consumer retired; WAL durable/pending falso/owner nullo. | Errore prematuro prima di azzerare riferimenti o count; generazione preservata. |
| C14 | Fault | Scope Serie OR Archivio; transizione terminale; upgrade senza downgrade. | Ingressi/dispatch/pubblicazioni bloccati; completamenti restano possibili; nessuna mutazione file. |
| C15 | Annullamento | Faulted Serie; active-io zero per tutta la Serie; primo unresolved; log faulted. | Quiescenza verificata prima di marca-log e resolver; ambito Archivio rifiuta l'annullamento automatico. |
| C16 | Letture | Barriera della root; salute sana; evento/generazione validi; CSN non libero. | Root letta parallela; CSN libero rifiutato; conteggi solo con lease corrente. |
| C17 | Preflight token WAL | Token pendente + registry `eq` + log `eq` + slot/high/low uguali. | Guardia senza I/O/mutazione; log distinto con stessi file-id/versione rifiutato. |
| C18 | Preflight pubblicazione WAL | C17, log open, copertura async/group/strong. | Tutto prima del CAS root; il resolver preserva il ricontrollo dopo il CAS. |
| C19 | Ritiro I/O senza esecuzione, addendum D | Faulted; evento preparato/active; token catturato; lotto sealed/owner nullo; count active positivo; prova esterna P08. | Consente drenaggio del dispatch ritirato/mai accettato senza write/flush; token resta pendente, decremento unico; non revoca né annulla autonomamente. |

La tabella è un piano del contratto,
non una dichiarazione di copertura del prodotto. Le condizioni composte effettive
devono ricevere identificatori separati una volta disponibili i sorgenti.

## Metodo C1 per l'inventario effettivo

Per ciascuna funzione nuova si registra il nome, il file e la complessità
McCabe statica: base 1, selezioni, cicli, alternative dei dispatch/handler e ogni
continuazione di corto circuito (`and`/`or` con n operandi aggiunge n−1).
L'obbligo COD-13 è **massimo 10 per funzione**, compresi i corto circuiti.
Helper e macro delegate vengono identificati; un'estrazione non sostituisce la
copertura delle guardie. Un'incertezza nel conteggio si esplicita invece di dichiarare
automaticamente la conformità.

Ogni decisione composta effettiva elenca i predicati atomici e il corto circuito.
Per AND: tutti veri e ogni falso con i precedenti veri. Per OR: tutti falsi e ogni
vero con i precedenti falsi. Si documentano le combinazioni irraggiungibili nel
protocollo valido e si distinguono input API da corruzione interna. Questi casi
sono obblighi per l'agente incaricato delle prove; qui non si producono test o driver.

## Rischi da chiudere o conservare come precondizioni

| ID | Rischio | Gravità se implementato in modo errato | Controllo richiesto |
|---|---|---|---|
| R01 | CAS della root seguito da errore/interruzione prima di conservare `:pubblicato`. | P1: effetto visibile con token/stato incerti, doppia pubblicazione o annullamento indebito. | Guardie prima del CAS, conservazione stadio, fail-stop Archivio per stato incerto; precondizione P06. |
| R02 | Evento obsoleto autorizzato dai soli numeri. | P1: mutazione o risoluzione del nuovo lotto. | Oggetto ring del controller + generazione catturata; token catturato, non ricostruito dal lotto corrente. |
| R03 | `:written` interpretato come fine I/O. | P1: riuso durante flush o annullamento con worker attivo. | Stato consumer distinto, handoff conclusivo, durable/faulted prima del ritiro. |
| R04 | Una testa unica per risoluzione e rilascio. | P2: async blocca altri commit fino al flush, o libera buffer ancora usato. | Cursore unresolved separato dalla FIFO ritiro. |
| R05 | Annullamento verifica solo l'evento corrente. | P1: altri consumatori della Serie possono ancora usare log/token. | active-io globale al controller pari a zero; marca-log-faulted solo dopo quiescenza. |
| R06 | Normalizzazione indiscriminata di resource-exhausted. | P1/P2 secondo la finestra: maschera budget/invarianti come pending riprogrammabile. | Confronto esatto di reason `:csn-busy`; obbligo conservato sugli altri errori. |
| R07 | Mutazione dell'evento prima di un rifiuto normale. | P1/P2: perdita dell'obbligo o slot parziale su full/stale/riuso prematuro. | Preflight complete prima di count/cursori/refs e prima del reset. |
| R08 | Claim esteso al motore o alle allocazioni. | P2 documentale: risultato non sostenuto dall'evidenza. | Ambito/sorgenti espliciti; runtime e heap non misurati da questa review. |
| R09 | Active conservato dopo dispatch rifiutato, seguito da fault, senza possibilità di fine durable/faulted. | P2 di integrazione: obbligo I/O non drenabile se abbandonato. | Nuovo `ritira-io-commit-serie`, solo dopo prova P08; token pendente conservato, decremento unico, annullamento separato e quiescente. |

## Inventario composto effettivo — aggiornato alla lettura D

Versione correlata ai blob e alle impronte della review D. Gli otto file Series, le
preflight WAL, gli export e l'ASDF sono stati letti. I predicati composti
apparsi nella fase A sono invariati; il resto del modulo non aggiunge `and/or`
composti nel testo sorgente. I casi sotto sono obblighi di prova, non risultati
di esecuzione. Le chiamate relazionali a più argomenti restano predicati atomici
del sorgente, senza espandere implementazioni del runtime.

| ID | Funzione | Predicato effettivo e atomici | Obbligo per condizione |
|---|---|---|---|
| D01 | `crea-controllore-serie` | A AND B AND C: capacity di tipo index; 1 ≤ capacity ≤ 1024; next-offset di tipo index. | Ciascun falso separato rifiuta `:serie-budget` prima dell'allocazione. Per A falso, B non viene valutato. Root nil non entra nel predicato. |
| D02 | `%check-ring` | A AND B AND C AND D: capacità valida; head < capacity; tail < capacity; publish-head < capacity. | Ciascun falso segnala invariante `:serie-ring` e fault Archivio prima dell'indicizzazione. I range nonnegativi vengono dai tipi degli slot. |
| D03 | `%check-ring` | A AND B AND C: count ≤ capacity; unresolved ≤ count; active-io ≤ count. | Ciascun falso separato porta fault Archivio `:serie-count`. Non prova da solo la cardinalità precisa degli eventi. |
| D04 | `%check-owner` | A AND B AND C AND D: lease index; lease positiva; lease = lease-generation; owner eq current-thread. | Tipo invalido, zero, generation stale e thread estraneo rifiutano separatamente `:serie-lease` prima di `%check-ring` o mutazioni. |
| D05 | `%check-event` | A AND B AND C AND D: event.controller eq controller; generation index; positiva; uguale a event.generation. | Stesso numero su altro controller rifiutato per A; stale dello stesso oggetto per D. Seguono range position e identità dell'oggetto nel ring. |
| D06 | `%csn-after-p` | A OR (B AND C): high > previous-high; high uguali; low > previous-low. | High maggiore passa senza C; high minore rifiuta; high uguale seleziona il confronto low; uguaglianza totale rifiuta. B e A non possono essere entrambi veri. |

Le nuove preflight WAL non introducono decisioni composte proprie: delegano
l'identità a `esigi-identita-csn-lotto` e la copertura a `coperto-p`. Le decisioni
composte di questi helper preesistenti sono D07/D08/E07 dell'inventario
[WAL–CSN](wal-csn-decisioni.md); la nuova guardia log usa `eq` sull'oggetto.

## Selezioni, guardie e rifiuti effettivi — C con addendum D

| ID | Funzioni e decisione effettiva | Esiti e obblighi da verificare |
|---|---|---|
| S01 | Factory, `verifica-log-segmento` | Prima dell'allocazione: kind diverso da segment → `invalid-argument :log-segment-kind`; log non open → `io-fault :log-faulted`. Default capacity 64, massimo 1024 e root nil. |
| S02 | `%position-after`, `%check-geometry` | Dopo i limiti D02/D03: `tail = (head+count) mod capacity` e `tail = (publish-head+unresolved) mod capacity`, verificati separatamente. Ciascun disaccordo → fault Archivio `:serie-ring-geometry`. Somma ≤ 2047; capacity 1 e ring pieno/vuoto inclusi. |
| S03 | Acquisizione/rilascio owner | CAS nil→current-thread una volta; busy → `:serie-busy`; generation al massimo → `:serie-lease-generation`, owner rilasciato. Rilascio controlla owner prima e risultato CAS dopo; errore → invariante `:serie-owner`. |
| S04 | `%check-admission`, `%check-new-slot` | Full → `:serie-full`; generation al massimo → `:serie-event-generation`; livello → `:serie-level`; root pianificata → `:serie-root-order`; sealed → `:serie-lotto-state`; contiguità/somma → `:serie-offset`; CSN non crescente → `:serie-csn-order`. Tutto prima di `%begin-effect` e prima delle mutazioni di evento/count/cursor. |
| S05 | `%check-event`, `%live-event` | Dopo D05: position nel range e oggetto eq slot; incoerenza → `:serie-event-slot` Archivio. Libero → `invalid-argument :serie-event-state`; riferimento lotto perso → `:serie-event-lotto` Archivio. |
| S06 | `%check-publish-head` | Evento eq slot publish-head; fase preparato/pubblicato; unresolved positivo. Fuori FIFO → `:serie-publish-order`, fase conclusa → `:serie-event-state`; contatore incoerente → `:serie-count` Archivio. |
| S07 | `inizia-io-commit-serie` | Healthy; preparato; io idle; token catturato esatto. Phase errata → `:serie-event-state`; doppio ingresso → `:serie-io-state`. Dopo successo active/count conservati anche se lo scheduler rifiuta il compito: il caller riprogramma la stessa obbligazione senza un nuovo ingresso. |
| S08 | `completa-io-commit-serie` | Io active; lotto durable o faulted; active-io positivo. Semplice written/sealed → `:serie-io-in-flight` senza decremento; doppia fine → `:serie-io-state`. Log faulted noto marca scope Serie, preservando precedente Archivio; retirement e decremento una sola volta. |
| S09 | `%check-publication` | Token esatto; io active/retired; preflight WAL; root attuale eq expected-root se preparato, eq nuova root se pubblicato. Io idle → `:serie-io-not-started`; copertura insufficiente → `:lotto-not-covered` prima CAS; salute → fault Serie; token/root/invariante → Archivio. |
| S10 | `%publish-root` | `case`: preparato marca pubblicando, esegue CAS, marca pubblicato; pubblicato non ripete CAS; otherwise → `:serie-event-state` Archivio. Post fase e radice verificate; CAS mismatch → `:serie-root-cas` Archivio. Interruzione nella fase intermedia resta incerta. |
| S11 | `%resolve-publication` | Fase pubblicato; successo resolver → risolto e advance. Solo handler resource-exhausted con reason eq csn-busy → pendente/0/0 e cursor invariato. Altri resource-exhausted propagati; cleanup incompleto marca Archivio. |
| S12 | `%advance-publication` | Unresolved positivo e fase risolto/annullato prima del decremento; cursor passa al successore, head del ritiro non cambia. Incoerenze → `:serie-count`/`:serie-event-state` Archivio. |
| S13 | `riusa-commit-serie` | Healthy; head FIFO; risolto; io retired; count positivo; preflight WAL prima dell'effetto tramite `%check-lotto-release :riuso`. Fuori FIFO → `:serie-retire-order`; io non ritirato → `:serie-io-in-flight`; WAL prematuro → lotto-state/csn-pending/owned. Invariante della preflight marca Archivio: CS-REV-01 chiuso alla lettura D. |
| S14 | `%mark-fault`, getter salute/ambito | Scope Archivio assegna archive-faulted; scope Serie CAS healthy→faulted, preservando i due stati faulted. Getter ambito case healthy/faulted/archive-faulted → none/Serie/Archivio; otherwise invariante. Due chiamate separate ai getter non costituiscono uno snapshot a coppia. |
| S15 | `%require-quiescent`, `annulla-commit-serie` | Scope eq Serie; FIFO unresolved; active-io zero, poi ogni slot non active, poi token esatto. Scope healthy/Archivio → `:serie-fault-scope`; active-io nonzero → `:serie-io-active`; slot active a contatore zero → `:serie-io-count` Archivio. Solo dopo: marca log faulted, annulla token catturato. Busy conserva stadio/token/count e restituisce 0/0 non misurati. |
| S16 | `%begin-effect`, `%end-effect`, rilascio lease | Effect-active vero all'ingresso o al rilascio della lease → `:serie-effect` Archivio. Cleanup complete vero libera la proprietà; complete falso marca Archivio e libera la proprietà mantenendo causa/riferimenti. COD-26 motivata nella review; nessuna deviazione o approvazione umana inventata. |
| S17 | `leggi-radice-serie`, query evento/CSN/count | Root con barriera lettura e rifiuto salute/log guasti; evento/generazione verificati; token libero respinto; count con lease. Stato evento case sui cinque valori contrattuali; pubblicando/altro → `invariant-violation :serie-event-uncertain` e Archivio. CS-REV-02 chiuso alla lettura D. |
| S18 | `%capture-token`, adozione | Legge token dal lotto sealed e verifica registry/log/slot/parole prima dell'adozione. Handler della sola invariant-violation → fault Archivio e propagazione della stessa condizione. Invalid-argument resta rifiuto pre-mutazione; nessuna risoluzione o nuova presa CSN. |
| S19 | `%check-lotto-release` | Case `:riuso` → preflight durable/token risolto/owner nullo; `:ritiro` → preflight sealed/owner nullo; otherwise → `:serie-release-kind` Archivio. Handler invariant-violation marca Archivio e ripropaga; rifiuti ordinari restano pre-mutazione. Nessun nuovo and/or composto. |
| S20 | `ritira-io-commit-serie` | Lease ed evento validi; salute faulted Serie o Archivio; phase preparato; io active; token catturato; preflight ritiro; active-io positivo. Healthy → `:serie-not-faulted`; phase/io errate → `:serie-event-state`/`:serie-io-state`; lotto non sealed/owner non nullo → `:lotto-state`/`:lotto-owned`. Solo dopo tutte le guardie: retired e decremento esatto, post-guardie e cleanup effetto. Slot/token/root/cursor/count/unresolved restano conservati; non esegue I/O né annulla CSN. |

## Addendum D — obblighi discriminanti per i fix e il ritiro I/O

| ID | Stato e azione | Esito atteso da verificare nella campagna del parent |
|---|---|---|
| D-S01 | Lotto sealed con token interno incompleto all'adozione. | Invariante originale WAL propagata; controller Archivio faulted; nessun evento adottato e nessun token liberato. |
| D-S02 | Stessa adozione con token di registry/log estraneo o non pendente. | Rifiuto ordinario senza adozione/mutazione, distinto dall'invariante interna. |
| D-S03 | Riuso di evento risolto/retired con errore d'invariante della preflight WAL. | Archivio faulted prima di riaprire il lotto o liberare lo slot; errore prematuro ordinario non resetta l'evento. |
| D-S04 | Phase pubblicando dopo uscita nonlocale, evento/generazione validi. | Getter segnala serie-event-uncertain e Archivio; nessuno stato pubblico incerto o root reinterpretata. |
| D-S05 | Dispatch mai accettato, active conservato, Serie poi faulted, gruppo annullato e prova P08. | Ritiro active→retired e decremento una volta; token e phase preparato conservati. Solo dopo quiescenza dell'intera Serie il caller può chiedere annullamento. |
| D-S06 | Richiesta di ritiro ancora healthy, io idle/retired, evento stale/estraneo, lotto written/durable/faulted o owner di gruppo presente. | Ogni guardia rifiuta prima del decremento; nessuna perdita dell'obbligo. Nuova chiamata dopo successo rifiuta io retired. |
| D-S07 | Ritiro valido mentre ambito già Archivio. | Drenaggio locale ammesso senza downgrade; successivo annullamento automatico rimane rifiutato per scope Archivio. |
| D-S08 | Lotto sealed senza owner ma prova esterna del ritiro assente. | Fuori dalle precondizioni della API: non attribuire alla sola riuscita della guardia una prova di quiescenza dello scheduler. |

Questi sono obblighi di test e interpretazione, non test scritti/eseguiti dal
revisore. Il ritiro I/O è locale all'evento e non richiede FIFO: può drenare
compiti fuori ordine; la successiva risoluzione/annullamento conserva la FIFO
unresolved e il riuso normale conserva la FIFO head. Il ritiro non abilita riuso
di buffer guasti. Il nuovo cleanup dell'effetto rientra nella motivazione COD-26
già esposta nella review, con sette percorsi che rilasciano tale proprietà.

Le preflight e la risoluzione ordinaria non provano l'immutabilità della radice,
la fine reale del worker o il fail-stop globale dell'Archivio. Restano P01/P04/P06.
La guardia preflight di pubblicazione delega `verifica-log-segmento(log)`; quella
del resolver esistente su `lotto-csn-log` rimane invariata e presente una volta:
l'anchor del precedente mutatore WAL non viene duplicata. Nessun mutatore eseguito.

L'esito della lettura e le osservazioni P1/P2 sono nel
[documento di revisione](controller-serie-revisione.md).
