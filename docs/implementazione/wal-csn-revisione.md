# Revisione C1 statica del ponte WAL–CSN

**Stato corrente: R1 risolto staticamente nell'addendum finale.** Le osservazioni e le
impronte della lettura precedente sono conservate sotto per tracciabilità.
L'addendum sul preflight file documenta l'ultima revisione del ponte e la sua impronta.

Data: 2026-10-09. Seconda lettura indipendente svolta da Codex sul diff di prodotto.
Questa è una revisione automatica statica: **nessuna certificazione umana**, nessuna
esecuzione di test, benchmark, compilazione, lint, trace o `make check`. Nessuna modifica
al prodotto e nessun commit. I soli file scritti da questa revisione sono questo documento
e [wal-csn-decisioni.md](wal-csn-decisioni.md).

## Perimetro e versione letta

Diff rispetto a `HEAD=673987ad819dd48741a7c0a4ff259137a1ed0bef`:
`src/foundation/{record,package}.lisp`, `src/wal/{types,builder,package,csn,group}.lisp`,
`arcdocdb.asd`. `group.lisp` è stato incluso su richiesta esplicita del parent.
Il file nuovo `src/wal/csn.lisp` è stato letto come aggiunta rispetto a `/dev/null`.
Il contesto invariato dei diff è stato usato solo per capire le funzioni modificate.

Fonti normative lette: [ADR-0037](../adr/0037-lotto-sigillato.md),
[ADR-0038](../adr/0038-orizzonte-di-visibilita.md),
[ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md),
[standard di codifica](../affidabilita/standard-di-codifica.md) e relativa
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md).
Non sono stati letti test, benchmark, implementazione del registro CSN, executor,
controller, indice, scheduler o recovery. Le loro proprietà restano assunzioni esplicite.

Impronte Git dei contenuti letti, calcolate senza scrivere oggetti:

| File | Impronta |
|---|---|
| `src/foundation/record.lisp` | `251ba51cfb723f4944df669788b4532489bd07ad` |
| `src/foundation/package.lisp` | `12cdf3488cf5d389f50e1d97cdb44fa564c04207` |
| `src/wal/types.lisp` | `10c4b1949994d01cb9ed231f66a69cf81f1ea062` |
| `src/wal/builder.lisp` | `91f964cc5b0c2195a6962a004317ba78f3c5f18c` |
| `src/wal/package.lisp` | `07538705ebbec9058296c44b668c4d04194bb626` |
| `src/wal/csn.lisp` | `a592a370135b8b24b548c38588215ad7d26bf1b5` |
| `src/wal/group.lisp` | `8245bc10cedafbff8665489fbced6833f078a373` |
| `arcdocdb.asd` | `0c0a05d798f04ee5012d1c3a3a98930ae9fba2d5` |

La revisione incorpora la firma finale con token atteso:
`risolvi-lotto-pubblicato(lotto registry slot high low level)` e
`annulla-csn-lotto(lotto registry slot high low)`.
L'ultimo diff ASDF include anche `csn-threads` nel sistema di test; il file di test
non è stato letto né eseguito.
Una modifica successiva alle impronte richiede una rilettura della parte interessata.

## Rilievi azionabili

### R1 — P2: evidenza locale COD-24 mancante nel kernel di ristampa

In `src/wal/builder.lisp:41`, `ristampa-record-parole` è una funzione C1 non banale:
attraversa gli offset, modifica stamp e CRC e restituisce il checksum aggregato, ma non
contiene asserzioni esplicite di precondizione/postcondizione. COD-24 richiede almeno due
asserzioni significative per funzione C1 non banale. Il chiamante controlla count e spazio
SEAL in `verifica-chiusura-lotto` e la lunghezza finale in `sigilla-lotto-parole`, ma questo
non documenta due asserzioni del kernel né verifica la validità di ogni offset.

La lacuna era presente nel kernel precedente e resta nella funzione rinominata; non è
evidenza di una nuova corruzione introdotta dal diff. Azione: esplicitare le due verifiche
significative del kernel, oppure portare alla prima lettura l'evidenza del controllo
delegato e la deviazione formale necessaria. Non si attesta una deviazione registrata:
il registro delle deviazioni è fuori dal perimetro autorizzato.

### O1 — Obbligo del controller: validare l'evento prima della pubblicazione esterna

In `src/wal/csn.lisp:80`, `risolvi-lotto-pubblicato` verifica identità attesa, salute e
copertura **dopo** la pubblicazione dell'indice richiesta dalla sua precondizione.
La funzione protegge il rilascio del credito; non può impedire una pubblicazione esterna
già eseguita con un evento vecchio o con un log guasto. Un controller che pubblicasse
prima di scartare quell'evento potrebbe alterare l'indice anche se il ponte lo rifiuta.
Il controller non è stato letto: questo è un obbligo d'integrazione, non un difetto
dimostrato nel suo codice.

Azione: al confine del writer, verificare token catturato nell'evento, incarnazione del
lotto, log sano, copertura e ordine prima di pubblicare; rendere indivisibile rispetto
agli altri eventi del writer la sequenza di verifica/pubblicazione/risoluzione.
Non ricostruire il token atteso leggendo il lotto corrente all'arrivo dell'evento.
Con `busy` dopo pubblicazione, conservarne l'esito e ritentare solo la risoluzione.

### O2 — Obbligo fail-stop: distinguere rifiuto sicuro e interruzione dopo mutazione

In `src/wal/csn.lisp:35`, il registro viene modificato da `prendi-csn` prima che tutti i
campi del token siano conservati nel lotto; in `src/wal/csn.lisp:72`, `risolvi-csn` libera
lo slot prima che `csn-pending` diventi `nil`. I due passaggi tra oggetti non sono una
singola scrittura atomica. La docstring richiede fail-stop per l'interruzione inattesa
durante risoluzione e per l'errore dopo assegnazione: questo requisito è coerente.

Azione: distinguere `resource-exhausted` prima della mutazione dal fallimento inatteso
dopo la mutazione. Portare Serie/log in stato guasto, ritirare i consumatori e vietare
il retry ordinario. Con token completo ancora pendente, l'annullamento usa lo stesso
registro e le stesse parole; con associazione incompleta o esito del registro incerto,
il controller deve avere una strategia esplicita di riconciliazione o arresto dell'Archivio.
Il solo arresto del writer senza risolvere quel credito può lasciare `H` fermo.
Non è stata verificata l'implementazione di questa gestione esterna.

## Riscontri statici positivi e confini

| Aspetto | Riscontro sul diff | Limite della conclusione |
|---|---|---|
| CSN alla chiusura | Le validazioni del lotto/log precedono `prendi-csn`; poi il token viene conservato e i byte sigillati. | Assegnazione/registrazione indivisibili e rifiuti senza mutazione dipendono dal registro non letto. |
| Identità sul disco | Stamp scritto low u32, poi high u32, sia nei record ordinari sia nel SEAL; CRC header aggiornati e checksum aggregato ricalcolato. | Codec binario e recovery non riesaminati. |
| Prepared/TXID | Il predicato di ristampa cambia PUT/TOMBSTONE/EDIT solo se il bit prepared è assente. | Il ponte accetta segmenti non vuoti; non prova che siano lotti di sole operazioni ordinarie. Il controller governa l'uso single-Serie. |
| Punto di atomicità | La sigillatura prepara il SEAL; `:async` richiede write, `:group`/`:strong` richiedono copertura durevole. | Nessuna sigillatura costituisce da sola I/O durevole o pubblicazione dell'indice. |
| Gruppo del log sbagliato | `verifica-identita-lotto`, `group.lisp:18`, rifiuta `csn-log` diverso tramite `eq` prima del CAS di ownership e della modifica del gruppo. | Numericamente uguali file-id/versione non sostituiscono l'identità dell'oggetto log. Lotti senza ponte seguono il contratto legacy. |
| Evento vecchio dopo riuso | `esigi-identita-csn-lotto`, `csn.lisp:43`, controlla `eq registry` e uguaglianza di slot/high/low prima della salute/copertura e della risoluzione. | Il token atteso deve appartenere all'evento originale; unicità senza wrap è responsabilità del registro. |
| Altro registro, stessi numeri | `eq` sul registro respinge l'altro Archivio anche se slot/high/low coincidono. | Il controllo non prova che il registro fornito alla sigillatura fosse quello dell'Archivio corretto; questa è una precondizione. |
| Risoluzione duplicata | La verifica di pending precede l'identità: un token già risolto dà `:lotto-csn-not-pending`; un evento obsoleto su un nuovo pendente dà `:lotto-csn-stale`. | `leggi-csn-lotto` conserva i numeri anche dopo risoluzione; non autorizza una seconda risoluzione. |
| Vecchio lotto coperto, log ora guasto | `risolvi-lotto-pubblicato` controlla salute del log originale anche se il lotto è ancora `:written`/`:durable`. | `coperto-p` osserva solo lo stato del lotto: da solo non è una prova di salute o pubblicazione. |
| Annullamento | Richiede token esatto e log originale `:faulted`, poi risolve; non riapre né elimina dati. | Serie FAULTED e assenza di consumatori sono precondizioni del controller, non verifiche del ponte. |
| Riuso | `riusa-lotto` richiede durevole, token non pendente e owner nullo, poi azzera l'associazione. | Owner nullo non prova l'assenza di eventi/reader esterni; il controller deve aver completato il loro ciclo. |
| Preallocazione | Token in slot tipizzati del lotto esistente; buffer, offset, SEAL e slot di gruppo preallocati. | Nessuna misura di allocazioni. **Nessun claim di assenza di heap**, boxing o GC. |
| Non blocking | Nel codice modificato non compaiono syscall, attese, lock bloccanti o cicli di retry; un tentativo di presa/risoluzione per chiamata. | Non sono state lette le funzioni del registro; try-lock, limite della sezione critica e parcheggio con tempo/byte limitati restano da provare. |
| Wiring | Package importa i nuovi simboli; ASDF carica il modulo CSN prima del WAL e il ponte dopo group/executor; `log-io` precede il suo uso nel tipo del lotto. | Nessuna attestazione di build senza warning o dei test registrati in ASDF. |

## Errori, precondizioni e stati da conservare

| Fase | Condizione o fallimento | Stato previsto e gestione |
|---|---|---|
| Prima della presa CSN | Stato/associazione/contenuto/identità/frontiera errati: `invalid-argument`; log guasto: `io-fault`; budget interno incoerente: `invariant-violation`. | Nessun CSN preso dal ponte. Errori d'invariante richiedono il confine fail-stop C1; gli altri rifiuti non autorizzano mutazione o pubblicazione. |
| Presa CSN | Registro pieno/busy/64 bit esauriti: `resource-exhausted`, secondo contratto esterno. | Lotto aperto e senza associazione se il registro rifiuta prima della mutazione. Busy/pieno: riprogrammare con limiti; esaurimento 64 bit: nessun wrap né retry infinito. |
| Dopo presa riuscita | Fallimento della codifica o interruzione nel trasferimento del token. | Non richiedere un secondo CSN. Associazione completa conservata finché risolta; buffer aperto parziale o sealed non riusabile. Fail-stop secondo O2. |
| Risoluzione con evento errato | `:lotto-csn-stale` o `:lotto-csn-not-pending`. | Nessuna chiamata a `risolvi-csn`; nessuna modifica di pending/credito/H da parte del ponte. |
| Pubblicazione richiesta | Log guasto: `io-fault`; lotto non coperto: `invalid-argument`. | Token resta pendente. Non pubblicare/confermare usando il solo vecchio stato del lotto; eseguire la gestione della Serie guasta. |
| Risoluzione busy | `resource-exhausted`, solo se il registro garantisce nessuna modifica sul busy. | Pending e identità conservati; parcheggiare l'obbligo. Se indice già pubblicato, non pubblicarlo nuovamente. |
| Risoluzione con token interno errato/interruzione | `invariant-violation` o fallimento inatteso. | Fail-stop; non trattare come busy. Slot eventualmente già liberato e pending locale ancora vero richiedono O2. |
| Annullamento | Log sano: `:lotto-log-not-faulted`. | Credito conservato; non si usa l'annullamento per scartare un commit sano. |
| Riuso anticipato | Pending oppure owner presente: `invalid-argument`. | Nessun reset del token/buffer. Un lotto guasto non è automaticamente riapribile. |

Tipi Lisp errati, offset interni corrotti e interruzioni asincrone non sono provati come
condizioni della gerarchia ArcDocDB dal solo `safety 3`: il confine worker/controller deve
convertire o registrare il fallimento e compiere la transizione fail-stop. Non è stato letto.

## Complessità COD-13

Conteggio statico manuale per funzione: base 1; +1 per `if`/`when`/`unless`, ciclo e uscita
anticipata `thereis`; +`n-1` per ciascun `and`/`or` di `n` operandi, anche annidato.
`not`, confronti e chiamate non aggiungono decisioni; il costo delle funzioni chiamate
è conteggiato nella rispettiva funzione. Non equivale a copertura misurata.

| Funzione modificata/nuova | Base | Selezioni e cicli | Corto circuito | Totale |
|---|---:|---:|---:|---:|
| `scrivi-record` | 1 | 0 | 0 | 1 |
| `scrivi-record-parole` | 1 | 0 | 0 | 1 |
| `aggiungi-record` | 1 | 4 | 1 | 6 |
| `ristampa-record-parole` | 1 | 2 | 3 | 6 |
| `verifica-chiusura-lotto` | 1 | 2 | 2 | 5 |
| `sigilla-lotto-parole` | 1 | 1 | 0 | 2 |
| `sigilla-lotto` | 1 | 1 | 0 | 2 |
| `riusa-lotto` | 1 | 2 | 0 | 3 |
| `verifica-identita-lotto` | 1 | 3 | 4 | 8 |
| `aggiungi-lotto` | 1 | 7 | 1 | 9 |
| `verifica-log-csn` | 1 | 5 | 3 | 9 |
| `sigilla-lotto-con-csn` | 1 | 0 | 0 | 1 |
| `esigi-identita-csn-lotto` | 1 | 1 | 3 | 5 |
| `esigi-csn-pendente` | 1 | 2 | 3 | 6 |
| `risolvi-token-lotto` | 1 | 0 | 0 | 1 |
| `risolvi-lotto-pubblicato` | 1 | 2 | 0 | 3 |
| `annulla-csn-lotto` | 1 | 1 | 0 | 2 |
| `stato-csn-lotto` | 1 | 2 | 0 | 3 |
| `leggi-csn-lotto` | 1 | 1 | 0 | 2 |

Massimo 9, quindi nessuna funzione modificata supera 10 con questo conteggio.
Il ciclo di ristampa è limitato da count ≤ offset preallocati; la ricerca duplicati da
count del gruppo ≤ slot preallocati. I limiti costruttivi visibili nel contesto del diff
sono 65.536 record, 64 MiB per lotto e 1.024 lotti per gruppo; la correttezza di uno stato
interno corrotto non discende dal solo limite. Nessuna ricorsione aggiunta.

## Checklist delle due letture, nell'ordine richiesto

**Lettura 1: parent.** Responsabilità assegnata al parent; evidenza puntuale delle sue
12 risposte e riferimenti di revisione non fornita in questa sessione. Le comunicazioni
sulle modifiche non attestano da sole una checklist completa. La colonna resta da
compilare dal parent, senza firma o certificazione umana implicita.

**Lettura 2: questa revisione indipendente.** Completata sul perimetro e sulle impronte
sopra; riletto il nuovo controllo `eq` del gruppo e la firma con token atteso dopo gli
aggiornamenti del parent. Non si attesta che la prima lettura completa abbia preceduto
questa: la sequenza formale resta da documentare dal parent.

| # | Voce dello standard | Lettura 1 — parent | Lettura 2 — evidenza statica |
|---|---|---|---|
| 1 | REQ e ADR coerenti | Da attestare | REQ-FOR/LIM/WAL/MVC/AFF presenti; chiusura e token coerenti con ADR-0037/0038/0046. Semantica interna del registro fuori perimetro. |
| 2 | Invarianti e test capaci di fallire | Da attestare | INV-F2/F3/V5/M4/M5/A8/A11/P6 analizzati; scenari concreti nel documento decisioni. Nessun test letto o eseguito. |
| 3 | Tipo, gestione e test di ogni errore | Da attestare | Tabella errori sopra; gestione esterna O1/O2 non verificata, test non attestati. |
| 4 | Cicli e attese limitati | Da attestare | Cicli sullo stato preallocato e complessità ≤10; non blocking del registro/parcheggio condizionale. |
| 5 | Nessuna allocazione, misurata | Da attestare | **Non attestato: misure assenti.** Due u32 e preallocazione sono evidenza strutturale, non una misura heap. |
| 6 | Nessun dato non verificato esce dal modulo | Da attestare | Validazione prima di scrittura; token e high/low restituiti con precondizioni di ownership. Idoneità alla pubblicazione esterna resta O1. |
| 7 | Nuove decisioni composte elencate | Da attestare | Inventario COD-54 in `wal-csn-decisioni.md`, inclusa identità registry/slot/high/low. Copertura per condizione non eseguita. |
| 8 | Proprietario dello stato condiviso | Da attestare | OWNER/SHARED dichiarano writer, I/O e registro per lotto; handoff e mutua esclusione esterni non verificati. |
| 9 | Trace aggiornata e `make check` | Da attestare | ASDF aggiornato; matrice, trace e `make check` non letti/eseguiti. |
| 10 | Nessuna violazione senza deviazione | Da attestare | R1 aperto su COD-24. Nessuna attestazione del registro deviazioni; COD-01/30 richiedono prove successive. |
| 11 | Nessuna serializzazione per operazione tra Serie | Da attestare | Il diff tocca il registro solo a chiusura/risoluzione; costo e progress del registro da misurare/verificare. |
| 12 | Atomicità, scartabilità, idempotenza, eliminazione | Da attestare | SEAL preparato esplicitamente; nessuna eliminazione. Duplicati/stale respinti; retry solo dopo rifiuto senza mutazione, O2 per interruzioni. |

Esito: seconda lettura statica completata, con R1 e obblighi esterni O1/O2 aperti.
Non costituisce approvazione C1 completa, prova di copertura, misura heap o certificazione umana.

## Addendum finale — R1 risolto, 2026-10-09

Riletto il diff finale di `builder.lisp`, comprese le sole rifiniture di formattazione.
**R1 è risolto staticamente**: `ristampa-record-parole` richiede ora `esigi-lotto :open`,
asserisce count ≤ lunghezza offset prima dell'iterazione (`:lotto-record-count`) e,
per ogni record, pos + header-bytes ≤ used prima della lettura dell'header
(`:lotto-record-offset`). Entrambe le nuove asserzioni esplicite segnalano
`invariant-violation`; la docstring ne descrive le condizioni. Con pos u32 non negativo
e used ≤ buffer già verificato, l'header del record corrente è entro i byte utilizzati.

| Osservazione preservata | Impronta |
|---|---|
| Builder alla lettura originaria, prima della correzione R1 | `91f964cc5b0c2195a6962a004317ba78f3c5f18c` |
| Builder dopo le guardie, prima della rifinitura di formato | `63db635f031d5f74d954b9cdcc9d2ad01680561c` |
| **Builder finale riletto** | **`5b4be8856be1e25f35f7a6e68f45ae727c18b168`** |
| ASDF osservato inizialmente, prima dell'aggiunta test `csn-threads` | `09ac3f6db87d5f45709bd9eee453131cae5de580` |
| ASDF dopo la sola aggiunta test `csn-threads`, già riletto nel diff | `0c0a05d798f04ee5012d1c3a3a98930ae9fba2d5` |

Calcolate nuovamente le impronte degli otto file del perimetro finale: tutte le altre
coincidono con la tabella della lettura precedente. Nessuna impronta storica è sostituita
da questo addendum; l'impronta builder finale identifica la versione della chiusura R1.

Il conteggio corrente di `ristampa-record-parole` è **1 base + 4 selezioni/cicli + 3
corti circuiti = 8** (prima: 6). `esigi-lotto` resta conteggiata nella propria funzione.
Massimo complessivo invariato: **9 ≤ 10**. Le due guardie nuove sono semplici, senza
nuovi `and`/`or`: l'inventario composto D01…D12 ed E01…E07 non cambia.

Il controllo offset precede l'accesso al relativo header, non tutte le modifiche al
lotto: record precedenti possono già essere ristampati. Nel ponte la ristampa avviene
dopo la presa e memorizzazione del CSN; un offset corrotto conserva quindi l'obbligo
pendente e richiede il fail-stop O2, senza rollback o retry ordinario. Per count corrotto,
la verifica esterna può già rifiutare `:lotto-seal-space` prima della presa; la nuova
guardia locale tutela anche il kernel con `:lotto-record-count`.

La voce 10 della seconda checklist è aggiornata a **R1 chiuso staticamente**; le voci
2/3 includono ora gli scenari di conteggio/offset tipizzati dell'addendum decisioni.
O1/O2 sono obblighi esterni concordati dal parent, con implementazione ancora fuori
perimetro. Il parent ha comunicato l'aggiunta del test FI offset in `csn-threads` e
attesterà la propria prima lettura dopo questo aggiornamento: nessuna delle due
evidenze è certificata qui. Non sono stati letti o eseguiti test, né eseguite misure.
Nessuna modifica al prodotto o commit; nessuna certificazione umana o garanzia heap.

## Addendum — preflight file prima della presa CSN, 2026-10-09

Riletto il diff del ponte dopo l'introduzione di `verifica-file-csn` (`csn.lisp:9`).
Impronta precedente preservata: `a592a370135b8b24b548c38588215ad7d26bf1b5`;
**impronta corrente: `9e1bcfc2dcc92908600dfced771869677b2e90b5`**.
Ricalcolate le impronte degli otto file autorizzati: tutte le altre restano quelle
documentate nell'addendum precedente, incluso builder `5b4be8856be1e25f35f7a6e68f45ae727c18b168`.

L'ordine effettivo è verifica chiusura → associazione/contenuto/identità log → salute log
→ preflight file → `prendi-csn` → memorizzazione token → codifica. Il nuovo helper:

1. Legge written del file appartenente al log e calcola size = used + SEAL.
2. Rifiuta written > file-start con `invalid-argument :lotto-written-offset`.
3. Chiama `verifica-capienza-append(file, (file-start − written) + size, size)`.
4. Rifiuta durable > posizione-durevole del file con `:lotto-future-durable`.

L'identità aritmetica written + budget-pianificato = file-start + size include anche
i byte pianificati prima del lotto corrente. Il terzo argomento è la sola size del
lotto sigillato: il budget cumulativo non viene usato come singolo trasferimento.
L'uguaglianza written = file-start è ammessa e produce un budget pari a size;
written < file-start è ammesso per lotti già pianificati. Questo controllo non prova
da solo che la sequenza pianificata sia contigua: l'ordine resta del writer/gruppo.

Disponibilità del file, modalità append, limite di trasferimento e budget finale sono
delegati alla funzione I/O esistente. Il suo corpo resta fuori perimetro: questi sono
obblighi del contratto, non una rilettura dei suoi predicati o una prova della sua purezza.
I rifiuti avvengono nel ponte prima della presa e prima di qualunque sua mutazione;
l'assenza di modifiche anche nel validatore I/O resta condizionata al suo contratto.
La preflight valida uno stato osservato dopo handoff, non riserva spazio né garantisce
che il file resti disponibile fino al successivo compito I/O.

| Funzione | Base | Selezioni/cicli | Corto circuito | Totale corrente |
|---|---:|---:|---:|---:|
| `verifica-file-csn` | 1 | 2 | 0 | **3** |
| `verifica-log-csn` | 1 | 4 | 3 | **8**, prima 9 |

Nessun nuovo `and`/`or`, ciclo o retry nel helper. Massimo complessivo ancora **9 ≤ 10**;
il costo del validatore delegato non è sommato alla complessità locale né riesaminato.
La docstring e il REQ del nuovo helper dichiarano frontiere, budget, condizioni e nessuna
syscall. Il controllo durable è stato spostato, senza cambiarne il predicato.

Le voci 2/3/6/7 della seconda checklist incorporano i rifiuti pre-CSN e il contratto
delegato E08 nel documento decisioni. Il parent comunica copertura di sei casi di
budget/disponibilità e immagine invariata: **evidenza riferita, non verificata qui**.
R1 resta chiuso staticamente; O1/O2 restano obblighi esterni concordati. Nessun nuovo
rilievo sul diff locale. Prima lettura del parent da attestare; nessun test o benchmark
letto/eseguito, modifica al prodotto, commit, certificazione umana o garanzia heap.

## Prima lettura del parent — 2026-10-09, prima delle campagne

L’autore ha riletto il prodotto e i test integrati: codec a parole e wrapper,
chiusura con preflight di log/file/budget, conservazione di registro e token,
identità dell’evento e del log, copertura distinta da pubblicazione, annullamento
solo dopo FAULTED e riuso solo dopo risoluzione/durability/quiescenza.
Ha corretto R1 e aggiunto controlli di disponibilità e budget pianificato.

Le voci 1, 4, 6, 7, 8, 11 e 12 della prima checklist sono argomentate dal
contratto e dal prodotto riletto. Le voci 2 e 3 hanno test dedicati ai rifiuti,
carry/max, eventi vecchi e registry distinto, guasti append/flush, conteggio e
offset interni corrotti; un test con quattro Serie e K=3 forza saturazione e
verifica 2000 cicli, unicità e convergenza. Questi test sono ancora da eseguire.
Per 5, 9 e 10 restano da raccogliere misure heap, build senza avvisi e gate.
Nessun requisito dell’intero motore viene promosso a verificato.

O1 e O2 sono accettati come obblighi dell’integrazione futura: evento atteso
validato prima della pubblicazione, esito già pubblicato conservato sul busy;
fail-stop dell’Archivio per interruzioni dopo mutazione o stato incerto.
Indice, lifecycle di Serie e scheduler non sono implementati dal ponte.
Questa prima lettura e quella indipendente sono automatizzate, senza
certificazione umana. Le prove saranno riportate nei risultati della campagna.
