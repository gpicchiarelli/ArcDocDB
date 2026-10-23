# Decisioni composte e condizioni del ponte WAL–CSN

**Aggiornamento corrente:** guardie locali e complessità dopo la chiusura statica di R1
sono nell'addendum finale; l'inventario composto precedente è preservato.
Il successivo addendum preflight aggiunge il contratto delegato E08 e i rifiuti pre-CSN.

Data: 2026-10-09. Inventario statico COD-54 della seconda lettura indipendente.
Versione, perimetro, conteggi di complessità e checklist delle due letture sono in
[wal-csn-revisione.md](wal-csn-revisione.md). Il ponte letto ha impronta
`a592a370135b8b24b548c38588215ad7d26bf1b5`; il gruppo ha impronta
`8245bc10cedafbff8665489fbced6833f078a373`.

Le tabelle descrivono condizioni effettive del codice e **obblighi di verifica futura**.
Non attestano test scritti/letti/eseguiti, copertura MC/DC, benchmark o allocazioni misurate.
Nessuna certificazione umana e nessun claim di assenza di heap.

## Inventario COD-54 delle funzioni modificate e nuove

Ogni lettera indica un predicato atomico. `AND` e `OR` sono valutati da sinistra a destra
con corto circuito. Per un AND di n predicati indipendenti, l'obbligo è il caso tutti veri
e ciascun falso a turno con i precedenti veri; per un OR, tutti falsi e ciascun vero da
solo. Si deve documentare l'eventuale impossibilità di una combinazione nello stato valido.
Un caso di corruzione interna deve essere distinto da un input API valido.

| ID | Funzione e decisione effettiva | Predicati atomici | Esito e obbligo per condizione |
|---|---|---|---|
| D01 | `aggiungi-record`: `A OR B` | A: count = lunghezza offset; B: byte record + SEAL > spazio residuo. | Ciascun limite da solo rifiuta `:lotto-capacity`; entrambi falsi consentono il passaggio. Il rifiuto precede la scrittura dei byte. |
| D02 | `ristampa-record-parole`: `(A OR B OR C) AND NOT P` | A: PUT; B: TOMBSTONE; C: EDIT; P: bit prepared impostato. | Ogni tipo ordinario con P falso viene ristampato; con P vero preserva TXID. OUTCOME/DECISION/altro tipo ammesso con A/B/C falsi preserva stamp. A/B/C sono mutuamente esclusivi, non combinabili a piacere. |
| D03 | `verifica-chiusura-lotto`: `A AND B` | A: durable ≤ file-start; B: file-start + used + SEAL ≤ most-positive-fixnum. | Ciascun falso rifiuta `:lotto-offset` prima della presa CSN. Caso al confine uguale incluso; numeri negativi fuori dal tipo dichiarato. |
| D04 | `verifica-chiusura-lotto`: `A AND B` | A: count ≤ lunghezza offset; B: used + SEAL ≤ lunghezza buffer. | Ciascun falso segnala `:lotto-seal-space`; nessun CSN preso. A falso rappresenta corruzione interna, non normale saturazione D01. |
| D05 | `verifica-log-csn`: `A AND B` | A: lotto di tipo segment; B: count > 0. | Controllo e lotto vuoto rifiutati separatamente con `:lotto-csn-content`; entrambi veri passano. |
| D06 | `verifica-log-csn`: `A AND B AND C` | A: log di tipo segment; B: file-id del lotto = quello del log; C: versioni uguali. | Ciascun disaccordo rifiuta `:lotto-csn-log` prima della presa. Qui l'identità del log viene fissata per la prima volta; l'appartenenza all'Archivio è precondizione esterna. |
| D07 | `esigi-csn-pendente`: `A AND B AND (C OR D)` | A: registry presente; B: log presente; C: high > 0; D: low > 0. | Con pending vero, ciascuna associazione mancante e high=low=0 segnala `:lotto-csn-token`. High=0/low>0 e high>0/low=0 sono entrambi token nonzero ammessi. Nessun accesso al registro nella guardia. |
| D08 | `esigi-identita-csn-lotto`: `A AND B AND C AND D` | A: `eq` tra registry locale e atteso; B: slot uguale; C: high uguale; D: low uguale. | Ognuno dei quattro falsi, con gli altri uguali, rifiuta `:lotto-csn-stale` prima della risoluzione. Per A usare due oggetti registry con numeri identici: uguaglianza numerica non basta. |
| D09 | `verifica-identita-lotto`: `A AND B AND C` | A: kind lotto/log uguale; B: file-id uguale; C: versione uguale. | Ogni differenza rifiuta `:group-identity-or-order` prima di acquisire ownership. |
| D10 | `verifica-identita-lotto`: `A AND NOT B` | A: csn-log presente; B: `eq csn-log (gruppo-log group)`. | A vero/B falso rifiuta `:lotto-csn-log` anche con D09 tutto vero. A vero/B vero passa. A falso segue il contratto legacy e B non viene valutato. |
| D11 | `verifica-identita-lotto`: `A OR B` | A: count gruppo zero; B: lotto-start = gruppo-start + gruppo-bytes. | Primo lotto passa senza usare la frontiera del gruppo vuoto; successivi passano solo contigui. Entrambi falsi rifiutano `:group-identity-or-order` prima del CAS. |
| D12 | `aggiungi-lotto`: `A OR B` | A: count = numero slot; B: lotto-used > max-bytes − bytes. | Ciascun limite da solo rifiuta `:group-capacity` prima di mutare owner o gruppo. Entrambi falsi non escludono duplicati/ownership errata: seguono le guardie semplici. |

D02 e D01 sono predicati già presenti nelle funzioni modificate; D09/D11 sono stati
estratti dal predicato precedente del gruppo. D10 e D08 sono le protezioni di identità
aggiunte. Non si confonde una decisione più corta con una copertura già ottenuta.

## Decisioni composte delegate o invariate nel contesto del diff

Non sono nuove decisioni del ponte, ma sono necessarie per le sue precondizioni.

| ID | Posizione nel contesto letto | Condizioni e obbligo |
|---|---|---|
| E01 | `encoding-size` | `eq buffer key OR eq buffer value`: ciascun alias da solo deve rifiutare prima della prima scrittura. |
| E02 | `encoding-size` | `key-length ≤ key-limit AND total ≤ record-limit`: ciascun limite falso produce `:format-limit`. |
| E03 | `encoding-size` | `kind = PUT AND value-length > document-limit`: budget documento applicato al PUT; gli altri tipi seguono le rispettive verifiche di formato. |
| E04 | `configurazione-log` | `kind = segment OR file-id = 0`: segment può avere file-id nonzero, controllo richiede zero. |
| E05 | `crea-lotto` | `SEAL ≤ capacity ≤ max-bytes AND 1 ≤ max-records ≤ max-records-limit`: ciascun budget invalido rifiutato prima dell'allocazione iniziale. |
| E06 | `crea-log-io` | `stato-file = open AND mode-file = append`: ciascuna proprietà falsa respinta. L'esclusività del wrapper è una precondizione. |
| E07 | `coperto-p` | `level = async AND kind ≠ segment`: async su controllo rifiutato; async segment richiede written/durable, group/strong richiedono durable. Questa funzione non verifica la salute del log. |

## Guardie semplici, ordine e rifiuto prima della mutazione

| Guardia | Ordine effettivo nel diff | Obbligo osservabile |
|---|---|---|
| Lotto aperto e non già associato | `verifica-chiusura-lotto`, poi guardia registry di `verifica-log-csn`. | Seconda sigillatura non prende un altro CSN. Dopo errore post-presa con lotto ancora open, anche `aggiungi-record` e sigillatura legacy rifiutano l'associazione esistente. |
| Salute alla chiusura | Dopo D05/D06, prima della frontiera storica e di `prendi-csn`. | Log già faulted dà `io-fault`; non si consuma credito. |
| Frontiera storica | durable ≤ posizione-durevole del file associato, oltre D03. | Una frontiera futura è rifiutata anche se inferiore a file-start. Non si richiede l'uguaglianza con la frontiera attuale: il dato può essere storico. |
| Pending prima dell'identità attesa | `esigi-csn-pendente` precede D08. | Libero/già risolto dà `:lotto-csn-not-pending`; token obsoleto su nuovo pendente dà `:lotto-csn-stale`. |
| Salute alla pubblicazione | D08 precede salute originale, poi `coperto-p`, poi `risolvi-csn`. | Un vecchio lotto durable con log faulted non libera il token come pubblicato. Non basta il risultato vero di `coperto-p`. |
| Salute all'annullamento | D08, poi log originale faulted, poi `risolvi-csn`. | Log sano rifiuta `:lotto-log-not-faulted`; evento vecchio rifiuta prima, anche se il nuovo log fosse faulted. |
| Duplicato/owner del gruppo | Dopo identità/budget, ricerca limitata dei duplicati e CAS nil→group. | Oggetto lotto già presente dà `:group-duplicate`; owner di altro gruppo dà `:lotto-owned`; nessun incremento del count in entrambi i rifiuti. |
| Riuso | Stato durable, pending falso, owner nullo, poi reset. | Risoluzione sola non abilita il riuso. Group release solo non libera il credito CSN. |

## Identità dell'evento e scenari concreti da verificare successivamente

L'evento conserva in campi preallocati il riferimento al **registry originale** e i numeri
**slot/high/low originali**. Alla sigillatura sono noti registry e high/low restituiti;
`leggi-csn-lotto`, chiamata dal writer prima del passaggio dell'evento, fornisce slot/high/low.
La lettura del lotto corrente quando arriva un evento vecchio sostituirebbe il token atteso
e annullerebbe la protezione contro il riuso. Questa disciplina è del controller.

| ID | Stato/azione | Risultato staticamente atteso e osservazioni da verificare |
|---|---|---|
| S01 | Sigillare A, conservare token T, completare write e pubblicazione async, chiamare risoluzione con T. | Token esatto/log sano/written: una sola risoluzione; pending falso. Conferma esterna dopo pubblicazione. Nessuna prova dinamica svolta. |
| S02 | Come S01 con group/strong e lotto solamente written. | `:lotto-not-covered`, token ancora pendente e nessuno slot liberato; ripetere dopo durable può riuscire con lo stesso T. |
| S03 | Risolvere T, chiamare nuovamente con T prima del riuso. | `:lotto-csn-not-pending`; nessuna seconda chiamata mutante al registro. |
| S04 | Risolvere T, rendere durable, rilasciare owner, riusare A, sigillare ancora ottenendo T2, consegnare evento vecchio T. | Se T ≠ T2, `:lotto-csn-stale`; T2 resta pendente, byte/owner/registro non mutati dal ponte. Caso slot riutilizzato ma parole diverse incluso. |
| S05 | A pendente con registry R; fornire registry R2 distinto con slot/high/low numericamente uguali. | `:lotto-csn-stale` per `eq` falso; nessuna risoluzione in R o R2. |
| S06 | A pendente; alterare separatamente slot, high oppure low atteso, lasciando gli altri uguali. | Tre rifiuti separati `:lotto-csn-stale`; nessun rilascio del token reale. |
| S07 | Dopo riuso A è libero, evento vecchio T arriva prima di una nuova sigillatura. | `:lotto-csn-not-pending`; non `:lotto-csn-stale`, perché pending viene controllato per primo. |
| S08 | A bound a log L; gruppo G di L2 distinto, con stesso kind/file-id/versione e offset compatibili. | D09 passa, D10 rifiuta `:lotto-csn-log` prima del CAS; owner/count/bytes/slot del gruppo invariati. Poi A può essere aggiunto al gruppo di L. |
| S09 | A written/durable e T pendente; un guasto successivo porta L a faulted. | Pubblicazione tramite ponte con T dà `io-fault` anche se `coperto-p` sarebbe vero. Dopo Serie FAULTED e consumatori ritirati, annullamento con T può risolvere. |
| S10 | L faulted, ma evento di annullamento contiene T vecchio mentre A conserva T2. | D08 rifiuta `:lotto-csn-stale` prima di liberare il credito di T2. |
| S11 | Registro pieno/busy/esaurito alla chiusura. | Secondo contratto registro: A rimane open senza token, bytes/count invariati. Esaurimento u64 non produce wrap; busy/pieno richiedono parcheggio limitato, non spin. |
| S12 | Pubblicazione esterna completata, risoluzione con T rifiutata busy. | Conservare T e fatto-pubblicato in stato preallocato; retry della sola risoluzione. Non ripetere le modifiche all'indice. |
| S13 | Fallimento di codifica dopo presa riuscita e associazione completa. | T pendente conservato; aggiunta record, nuova sigillatura e riuso rifiutati. Fail-stop, quiescenza I/O e annullamento con T. |
| S14 | Interruzione tra presa e memorizzazione completa, oppure tra rilascio slot e reset pending. | Esito incerto tra registro e lotto; vietato retry ordinario. Riconciliazione esplicita o arresto Archivio; non attestare recuperabilità locale. |
| S15 | CSN con low=0 e high>0; oppure high=0 e low>0; stamp ordinario e prepared in codifica. | D07 non rifiuta i token nonzero; ordine LE low/high coerente, stamp e CRC ordinari aggiornati, TXID prepared preservato. Nessuna ricostruzione u64 esplicita nel ponte. |

Questi scenari richiedono in seguito osservazioni su credito, `H`, byte, pending, ownership
e indice. In questa revisione non sono stati letti o creati file di test/benchmark: la
responsabilità assegnata riguarda esclusivamente i due documenti.

## Stati preallocati e obblighi non blocking/fail-stop

| Stato | Campi e transizione | Obbligo esterno |
|---|---|---|
| Libero | registry/log nil, pending nil; slot/high/low inizialmente zero. | Writer unico; nessun evento corrente autorizzato alla risoluzione. |
| Pendente aperto parziale | Presa riuscita e associazione completa, sigillatura fallita prima di sealed. | Non continuare il lotto e non prendere un altro CSN. Serie/log faulted prima dell'annullamento; consumatori completati/ritirati. |
| Pendente sealed/written/durable | registry/log/token conservati, pending vero; bytes immutabili dopo sealed. | I/O possiede il gruppo in volo; writer osserva gli esiti dopo handoff. Evento conserva identità originale. |
| Pubblicato, risoluzione parcheggiata | Il ponte vede ancora pending; il controller conserva separatamente fatto-pubblicato e token. | Retry solo su rifiuto busy senza mutazione; lista di obblighi, byte e tempo limitati. |
| Risolto | pending nil, registry/log/token conservati fino al riuso. | Duplicati respinti; attendere durable e rilascio di tutti i riferimenti prima del riuso. |
| Nuova incarnazione dopo riuso | Reset dei campi CSN; nuova presa può riutilizzare slot ma non CSN nello stesso registry. | Un evento vecchio usa ancora i numeri catturati; mai sostituirli con quelli della nuova incarnazione. |
| Incoerenza dopo interruzione | Token locale incompleto o pending vero con slot già liberato. | Stato da fail-stop e riconciliazione, non un normale pendente ritentabile. |

Il ponte non conserva un bit fatto-pubblicato, non possiede stato della Serie né l'indice,
e non parcheggia richieste. L'annullamento controlla solo log faulted, oltre al token:
Serie FAULTED e quiescenza dei consumatori devono essere già veri al momento della chiamata.

Per la conformità complessiva restano da dimostrare: rifiuti del registro prima della
mutazione; identità interna slot/CSN; assegnazione e registrazione indivisibili; `H` monotono
secondo ADR-0046; try-lock senza attesa bloccante; limite K delle scansioni; confini fail-stop
e ordinamento reale dell'handoff. Il diff autorizzato contiene solo le chiamate al registro.

L'uso di due u32 evita la ricostruzione esplicita del CSN u64 nel ponte; non dimostra
assenza di heap/boxing/GC nelle chiamate delegate, nei ritorni multipli, nei confronti u64
o nella gestione degli errori. COD-30 resta **non attestato fino alle misurazioni**.

## Addendum finale — guardie di ristampa dopo R1

Riletto il builder finale `5b4be8856be1e25f35f7a6e68f45ae727c18b168`; le impronte della
lettura precedente e del passaggio intermedio restano nel documento revisione.
R1 risolto staticamente. **Nessuna nuova decisione composta**: restano 12 decisioni
D01…D12 nelle funzioni modificate e 7 E01…E07 delegate/invariate. D02 preserva esattamente
il predicato tipo/prepared; le nuove selezioni sono due `unless` semplici.

| Guardia aggiunta nel kernel | Condizione effettiva e ordine | Esito staticamente atteso |
|---|---|---|
| Stato/limite buffer delegati | `esigi-lotto lotto :open` prima della ristampa. | Stato errato: `:lotto-state`; used oltre buffer: `:lotto-length`. Nessun header letto dal kernel. |
| G-R1-count | count ≤ lunghezza offset, prima del ciclo e del primo accesso all'array. | Falso: `invariant-violation :lotto-record-count`; zero e uguaglianza al limite ammessi. La verifica esterna del ponte può anticipare il rifiuto con `:lotto-seal-space`. |
| G-R1-offset | pos + header-bytes ≤ used, per ogni record prima di leggerne tipo/flag. | Falso: `invariant-violation :lotto-record-offset`; uguaglianza ammessa. La guardia non richiede che il body sia nuovamente verificato: il buffer proviene dal codec e resta esclusivo. |

| Scenario aggiuntivo, da verificare successivamente | Risultato richiesto |
|---|---|
| S16 — count oltre l'array offset al confine del kernel; poi count uguale al limite. | Oltre limite: errore tipizzato prima dell'accesso; al limite: il ciclo resta limitato e visita i soli offset presenti. Nessuna esecuzione svolta. |
| S17 — count valido e pos + header = used; poi pos + header = used + 1, anche con pos ancora entro la capacità del buffer. | Uguaglianza passa; oltre used rifiuta prima della lettura del relativo header, senza affidarsi al solo limite fisico del buffer. |
| S18 — primo offset valido e secondo corrotto, sigillatura attraverso il ponte. | Il primo record può essere già ristampato; il secondo dà `:lotto-record-offset`. CSN già assegnato conservato pendente, nessun nuovo CSN/riuso/retry ordinario; gestione fail-stop O2. |

Complessità corrente del kernel: **1 + 4 selezioni/cicli + 3 corto circuito = 8**;
incremento di 2 rispetto al 6 originario. Massimo di tutte le funzioni modificate
invariato a **9**, entro COD-13. Le guardie non aggiungono cicli, attese o strutture
allocate; questo riscontro non costituisce una misura heap.

Il parent ha comunicato il test FI offset separato in `csn-threads`; non è stato letto
né eseguito da questa revisione. O1/O2 concordati restano condizioni del controller,
con implementazione non esaminata. Prima lettura del parent ancora da attestare;
nessuna certificazione umana, copertura misurata o garanzia di assenza di heap.

## Addendum — preflight file e contratto delegato E08

Ponte riletto: `9e1bcfc2dcc92908600dfced771869677b2e90b5`; l'impronta precedente
`a592a370135b8b24b548c38588215ad7d26bf1b5` resta storica. In `verifica-log-csn`,
la guardia durable originaria è ora dentro `verifica-file-csn`; identità/salute del log
precedono il helper, e tutto il helper precede `prendi-csn`.

| ID/guardia | Predicato o contratto effettivamente osservato | Esito/limite |
|---|---|---|
| G-file-written | written ≤ file-start, prima della chiamata al validatore I/O. | Falso: `invalid-argument :lotto-written-offset`; nessun credito preso. Uguale ammesso, maggiore distanza positiva ammessa. |
| E08 — contratto delegato | `verifica-capienza-append(file, planned, size)`, con size = used + SEAL e planned = file-start − written + size. Requisiti congiunti riferiti: file disponibile/aperto, modalità append, trasferimento size ammesso, estensione pianificata ammessa. | Non è un nuovo `and` sorgente del ponte: è il predicato logico delegato del contratto I/O. Corpo e ordine interno dei controlli non letti; condizioni tipizzate/purezza dipendono da quel modulo. |
| G-file-durable | durable ≤ posizione-durevole(file), dopo E08. | Falso: `invalid-argument :lotto-future-durable`; nessun credito preso. Un rifiuto E08 può precedere questo errore. |

Restano **12 decisioni composte sorgente D01…D12** e **7 predicati sorgente delegati/invariati
E01…E07** della lettura precedente; si aggiunge **1 contratto delegato E08**, senza
attribuirgli una struttura `and`/`or` o una complessità interna non letta.
`verifica-file-csn`: **1 + 2 selezioni + 0 corto circuito = 3**.
`verifica-log-csn`: **1 + 4 selezioni + 3 corto circuito = 8**, prima 9.
Massimo complessivo **9 ≤ 10**; nessun ciclo o attesa aggiunto localmente.

Se written=100, file-start=150 e size=40, gli argomenti pianificato/trasferimento sono
90/40 e la fine pianificata è 190: questo distingue limite file e singolo trasferimento.
La preflight non riserva la distanza né dimostra la contiguità dei lotti: il writer
mantiene il piano e il gruppo verifica l'ordine. Lo stato file deve essere osservato
tramite handoff sincronizzato; la sua disponibilità può cambiare prima dell'I/O.

| Scenario aggiuntivo da verificare successivamente | Obbligo osservabile prima della presa CSN |
|---|---|
| S19 — written maggiore di file-start; poi uguale e minore. | Maggiore: `:lotto-written-offset`; uguale/minore: valutare E08 con la distanza esatta. Nessuna modifica locale su rifiuto. |
| S20 — file indisponibile/non aperto, log wrapper ancora open. | E08 deve rifiutare secondo contratto I/O, anche se la salute del wrapper da sola passa. Nessun token assegnato. |
| S21 — file aperto con modalità incompatibile con append. | E08 deve rifiutare prima del token; tipo/reason esatti dipendono dal modulo I/O non letto. |
| S22 — size del lotto sigillato oltre il limite di trasferimento. | E08 deve rifiutare usando il terzo argomento size, anche se il budget totale del file ammetterebbe il lotto. |
| S23 — singolo lotto entro il trasferimento ma fine pianificata oltre il budget file. | E08 deve rifiutare includendo file-start − written; al confine consentito il lotto è ammissibile. |
| S24 — E08 valido e durable oltre la frontiera reale; poi uguale e inferiore. | Oltre: `:lotto-future-durable`; uguale/inferiore ammessi. Il valore storico non deve essere confuso con file-start. |

Per ogni rifiuto: lotto open senza nuova associazione CSN, buffer/count/used invariati
da parte del ponte, nessuna pubblicazione/conferma. L'immagine completa, inclusi registro
e stato del file, richiede la prova che E08 sia solo una validazione. Questi sei assi
descrivono gli obblighi del contratto; non attestano i dettagli dei sei test del parent.
Il parent riferisce copertura di budget/disponibilità e immagine invariata; test non
letti né eseguiti qui. R1 chiuso staticamente e O1/O2 concordati; nessuna certificazione
umana, misura heap o attestazione della prima lettura del parent.
