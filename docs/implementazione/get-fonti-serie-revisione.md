# Revisione statica C1 delle fonti GET della Serie

Revisore distinto dall'autore del prodotto, 2026-10-13, nel worktree
`get-controller/ArcDocDB`, base `4344d9e1f2ceb45e5fa3d5076b57d09505e69ac3`.
Scope di scrittura esclusivo: questo documento e
[get-fonti-serie.md](get-fonti-serie.md). Scope C1 letto:
`src/get-directory/sources-types.lisp`,
`src/get-directory/sources-read.lisp` e
`src/get-resolver/active-read.lisp`; contratti dipendenti letti in sola lettura.
Standard applicato: [standard-di-codifica.md](../affidabilita/standard-di-codifica.md).
La prima lettura ha seguito i contratti e il flusso dati; la seconda ha
ricontrollato guardie, cleanup, concorrenza e dodici punti C1 sul prodotto
dichiarato completo dall'autore, dopo la correzione GFS-REV-01 e il
ripristino della precedenza dell'owner legacy. È poi stata riletta soltanto
la delta GFS-REV-02, comprese le guardie di lease/salute del writer, e
aggiornata la checklist senza esecuzioni.
Queste sono due letture dello stesso revisore indipendente dall'autore,
non due revisori distinti.

Nessuna compilazione, test, benchmark, mutazione o comando di qualifica
eseguito da questo revisore. Le future esecuzioni dopo freeze spettano
all'integratore tramite `tools/record-command.lisp`; il loro piano è nel
[README preregistrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-fonti-serie/README.md).
Questo rapporto non rivendica qualifica C1, assenza di allocazioni misurata
o `make check` superato.

## Identità dei sorgenti riletti

Inventario Git blob finale identico in letture consecutive dopo l'ultima
delta dichiarata dall'autore, senza commit o scrittura dei sorgenti:

| File | Blob precedente della seconda lettura | Blob finale dopo delta GFS-REV-02 |
|---|---|---|
| `src/get-directory/sources-types.lisp` | `addb371196c98a7a165b9002c5b13e876683b60f` | `b9b9a00d607dcf36f3cac7db31fe4663eb0bcdb2` |
| `src/get-directory/sources-read.lisp` | `729e638230424b1a97465a40b3e2208034210646` | `ca171a29008377ec491dce07afd6cf24f12cd8fe` |
| `src/get-resolver/active-read.lisp` | `0a93acd78d9b8b341011531e23e5663ae1df4f72` | `0a93acd78d9b8b341011531e23e5663ae1df4f72` |

I riferimenti abbreviati `sources-types.lisp`, `sources-read.lisp` e
`active-read.lisp` sotto corrispondono a questi tre percorsi. Le righe
storiche di GFS-REV-01/02 indicano esplicitamente la versione intermedia;
gli altri riferimenti corrispondono ai blob finali.
La stabilità di questo inventario non è il freeze dell'intera campagna.

## Prima lettura: contratti e selezione

`avvia-get` entra in EBR prima di copiare il candidato del primary
(`src/get/lookup.lisp:46–58`). Il lookup conferma la root dell'indice prima
di copiare il payload (`src/index/primary-read.lisp:51–55`); questa conferma
non lega il candidato alla futura root delle fonti. La necessità del
superset è quindi parte del protocollo, anche quando il FD vecchio resta
aperto. La directory CLOSED dichiara pubblicazione prima delle location e
conservazione FD (`src/get-directory/types.lisp:15–20`).

Il nuovo contenitore ha due riferimenti readonly, senza copia del contenuto
opaco (`sources-types.lisp:7–27`). Registrazione: owner EQ e ricerca
duplicato precedono la delega (`sources-types.lisp:63–71`), quindi il wrapper
non adotta lotto/token su quei rifiuti. Il contenuto passa senza sostituzioni
alla radice costruita dall'ACTIVE (`src/get-resolver/active-build.lisp:94–110`).

Il ponte acquisisce `leggi-radice-serie` una volta e deriva fonti/ACTIVE
dalla stessa variabile (`sources-read.lisp:14–16`). Il dispatch passa
`active` al resolver esplicito (`sources-read.lisp:48–52`), che cerca la
pagina soltanto dentro `root` (`active-read.lisp:18–25`). Nessuna lettura
di `planned-root`, secondo CAS, registro lifetime o chiusura FD compare
nel tratto. Il controller mantiene acquire e controllo salute
(`src/series/query.lisp:28–38`); la pubblicazione resta il CAS esistente
(`src/series/publication.lisp:29–45`).

La prima lettura ha rilevato **GFS-REV-01**, blocco della sonda cache:
chiamata con keyword non prevista dal nucleo GET. Segnalato subito
all'integratore prima di attendere esecuzioni.

## Findings e rischi registrati

| ID / priorità | Evidenza concreta | Effetto e azione |
|---|---|---|
| GFS-REV-01 / P1, **chiuso staticamente prima delle esecuzioni** | La versione intermedia `src/get-directory/sources-read.lisp:63–64` passava `:outcome-offset proof`; `src/get/target.lisp:68–71` dichiara e definisce `sonda-cache-get` con quattro argomenti, senza keyword. La versione finale riletta ha `declare (ignore proof)` a `sources-read.lisp:65` e chiamata a quattro argomenti a `:66`. | La versione intermedia avrebbe fatto fallire tutte le sonde per arità dopo la risoluzione, già completata a `sources-read.lisp:52` di quella versione, affidando il pin al cleanup esterno. La correzione dell'autore è coerente col nucleo: prepared è già `:proof-required` dai flag (`target.lisp:81–90`). Nessun esito runtime rivendicato. |
| GFS-REV-02 / P2, **chiuso staticamente prima delle esecuzioni: COD-24** | Nel blob precedente `addb371…`, `src/get-directory/sources-types.lisp:31–42` non aveva asserzioni di pre/postcondizione e terminava con NIL incondizionato. Il blob finale controlla cardinalità ID/mappe e massimo a `sources-types.lisp:37–38`, convergenza a `:45`; handler reader a `sources-read.lisp:29–31`, writer a `sources-types.lisp:65–70`, preceduti da lease/salute a `:61–62`. | Le due guardie significative sono sempre attive; geometria e mancata convergenza diventano invarianti con reason esplicita. Reader FAULTED con la stessa reason e cleanup EBR; writer con lease valida marca ambito Archivio e ripropaga la stessa condizione prima dell'adozione. Su directory canoniche restano 17 pivot. Correzione ritenuta coerente nella delta review; sensibilità dei test ed esiti runtime ancora da dimostrare. |
| GFS-RISK-01 / obbligo del writer | `sources-types.lisp:53–71` verifica lease/salute, owner/duplicato senza confrontare il contenuto con le vecchie fonti; `sources-read.lisp:46–52` cerca esclusivamente nella nuova root acquisita. | Una nuova directory che ometta una vecchia location ancora copiabile/osservabile causa FAULTED. Il protocollo richiede il superset delle location risolvibili per reader ammessi; nessuna implementazione di rotazione/reclaim è attestata. |
| GFS-RISK-02 / precondizione API | `src/get-resolver/active-read.lisp:10–12` attribuisce al caller la prova di pubblicazione; il corpo usa il valore `root` senza rileggere il controller. | Una root preparata ha lo stesso tipo di una pubblicata. L'adapter esplicito non può provarne l'autorità; il ponte la deriva dall'acquisizione effettiva. Non presentare il tipo come guardia contro root preparate. |
| GFS-RISK-03 / lifetime borrowed | `sources-types.lisp:7–27` conserva e restituisce `content` senza copia; `src/get-resolver/active-types.lisp:48–50` esclude attestazioni di lifetime esterno. | Mutazione del grafo opaco o chiusura anticipata dei FD violano precondizioni anche con slot readonly. GC, apertura corrente del FD e EBR non certificano da soli futura quiescenza. |
| GFS-RISK-04 / rifiuto dopo CSN | `sources-types.lisp:63–71` rifiuta owner/duplicato prima di `registra-lotto-get-attivo`; quest'API richiede SEALED/CSN (`src/get-resolver/active-build.lisp:95–98`). | Rifiuto senza adozione non annulla il CSN già assegnato. Lotto/token restano del caller e devono essere risolti dal protocollo WAL. |
| GFS-RISK-05 / misura e fault boundary | `src/get/lifecycle.lisp:8–12` marca il GET FAULTED e demanda l'isolamento al confine; i nuovi percorsi reader non marcano direttamente il controller. Il writer ora applica il marker locale a `sources-types.lisp:69`. | La campagna deve verificare cleanup e causa; il marker writer non prova l'arresto coordinato dell'Archivio. Isolamento Serie/Archivio e COD-30 non si deducono dalla sola lettura statica. |
| GFS-RISK-06 / limite di lifecycle, prossimo incremento | `src/get-resolver/active-build.lisp:42–45` richiede planned-root NIL/count eventi zero/offset header; `src/get-resolver/active-types.lisp:38` impone almeno una pagina; `src/get-resolver/active-build.lisp:91–94` e `sources-types.lisp:49–51` ammettono previous NIL/radice ACTIVE. Il controller iniziale conserva root anche come planned-root (`src/series/types.lisp:53–54`). | ACTIVE+CLOSED è disponibile dopo la prima pubblicazione ACTIVE. La forma CLOSED-only è leggibile ma non passa direttamente al builder ACTIVE. Il bootstrap ACTIVE vuoto con CLOSED recuperati prima del primo lotto resta distinto; nessun commit fittizio di avvio o nuovo CAS è introdotto. Non blocca le API del ponte nelle forme ammesse e non attesta avvio completo. |

## Seconda lettura e checklist C1

Seconda lettura **completata**, integrata dalla delta review GFS-REV-02
sui blob finali sopra. La chiamata della sonda è
compatibile con il suo `ftype`; `proof` ignorato è metadata già verificato,
non un esito d'errore (COD-06). La lettura del record conserva invece
`:outcome-offset proof` perché `leggi-record-get` dichiara quella keyword
(`src/get/segment.lisp:90–99`), e prepared legge OUTCOME prima della cache
(`src/get/segment.lisp:108–116`). I cinque risultati non vengono aggregati
o scartati dal wrapper (`sources-read.lisp:78–79`).

Guardie: `risolvi-candidato-serie-get` esige CANDIDATE prima
dell'acquisizione/cleanup (`sources-read.lisp:43–46`).
`acquisisci-fonti-serie-get` è interna e non esportata; il suo caller
installa il cleanup e controlla lo stato. Nel wrapper legacy l'owner
è nuovamente controllato prima della salute/root del controller
(`active-read.lisp:39–41`); l'adapter esplicito ripete il controllo di
owner (`active-read.lisp:18–20`). Una vista estranea non viene quindi
reinterpretata come un guasto del suo controller nel wrapper legacy.

Cleanup: `complete` diventa vero soltanto dopo la risoluzione restituita;
un errore della scelta ACTIVE/CLOSED lascia falso e chiama `abbandona-get`
(`sources-read.lisp:44–55`). L'adapter ACTIVE e il wrapper legacy hanno
lo stesso schema (`active-read.lisp:15–26`, `:36–47`). I cleanup annidati
sono compatibili con l'abbandono ripetibile del nucleo: riferimenti e
buffer vengono scartati e FAULTED resta terminale
(`src/get/lifecycle.lisp:28–42`). Nessuna catch generica o soppressione
della causa è introdotta. L'interruzione del cleanup stesso è il limite
fail-stop già dichiarato dal nucleo, da verificare centralmente.

Delta GFS-REV-02: la ricerca respinge array ID/mappe di lunghezza diversa
o cardinalità oltre 65.536 prima di accedere ai pivot; al termine del
budget richiede `left = right` prima del NIL. I rientri anticipati su
uguaglianza del pivot o intervallo vuoto restano coerenti. La nuova guardia
non aggiunge scansioni, allocazioni, I/O o attese.

Nel reader il handler cattura soltanto `invariant-violation` della ricerca
e passa `error-reason` a `guasto-get` (`sources-read.lisp:29–30`): conserva
la reason, crea la condizione terminale del GET e lascia al cleanup esterno
del resolver il rilascio del pin. L'accessor è importato dal package
(`src/get-directory/package.lisp:7`) e restituisce una keyword
(`src/foundation/conditions.lisp:6–8`). Non è conservata l'identità
dell'oggetto condizione nel reader; è conservata la causa reason.

Nel writer `controller` deriva da `source`, quindi `%check-owner` e
`%require-healthy` precedono owner/ricerca e il handler con effetti
(`sources-types.lisp:58–65`). Il controllo di lease respinge generation,
tipo o thread estranei prima del controllo ring
(`src/series/ownership.lisp:73–80`). Il handler marca quel controller
`:archive-faulted` e ripropaga il medesimo oggetto condizione
(`sources-types.lisp:68–70`; `src/series/ownership.lisp:8–18`). Il duplicato
ordinario resta `invalid-argument` e non viene catturato come invariante.
La delega ricontrolla lease/salute e avviene dopo le guardie (`:71`).
Nei rami di fault non avvengono adozione o annullamento del token;
nessun CAS nuovo è introdotto dalla delta.

| Punto della lista C1 | Prima lettura | Seconda lettura ed esito statico |
|---|---|---|
| 1. Requisiti e ADR coerenti | REQ-IDX-001/WAL-006/CMP-007/AFF e contratti GET, WAL, controller acquisiti prima del protocollo. | Intestazioni REQ e docstring presenti; CAS/SEAL e modello dei compiti coerenti con ADR-0033/0035/0036/0037/0045. Nessuna promozione dei requisiti. |
| 2. Invarianti e test sensibili | Owner, frontiera, superset, pin, immutabilità e risposta privata inventariati nel protocollo. | `series-read.lisp` contiene scenari owner/root/candidato mancante/cattura singola; l'esecuzione e la sensibilità restano da dimostrare. Ritiro e chiusura delle risorse restano fuori dall'incremento. |
| 3. Errori, gestione e test | Invalid-argument di input, invariant-violation di grafo e io-fault del controller distinti; GFS-REV-01 trovato. | GFS-REV-01/02 chiusi staticamente prima delle esecuzioni. Wrong-state precede il possesso; reader conserva reason/FAULTED e cleanup, writer verifica lease prima del marker e ripropaga la stessa condizione. Test/fault injection non eseguiti. |
| 4. Cicli, attese, ricorsione limitati | Unico ciclo nuovo: ricerca duplicato con 17 pivot. | Per N ≤ 65.536 l'intervallo dimezza a ogni pivot; il minimo può richiedere tutti i 17. La delta controlla cardinalità e convergenza; nessuna attesa o nuova ricorsione. Pagine/riga restano ai limiti 17/33 esistenti. |
| 5. Allocazione calda misurata | Contenitore costruito fuori dal lookup, con due riferimenti propri; nessuna allocazione esplicita nel lookup. | Staticamente non si misura heap/boxing né il costo dei valori multipli. COD-30 aperto alle misure centralizzate. |
| 6. Dati verificati prima dell'uscita | Resolver e GET conservano controllo CSN, size, flag, FD, prova, CRC e chiave. | Il ponte restituisce capacità/metadata provvisori, mai un valore autorizzato; copia e `concludi-get` con tempo fresco restano obbligatorie. Prepared conserva OUTCOME. |
| 7. Decisioni composte | Inventariate GFS-D01…D03. | Aggiunta GFS-D04 per la guardia geometria/cardinalità della delta; tutte le nuove `and` del tratto sono elencate sotto. Nessuna condition coverage o MC/DC rivendicata. |
| 8. Proprietari dello stato condiviso | OWNER/SHARED espliciti; writer prepara, worker legge sotto EBR. | Due slot typed readonly; grafo opaco borrowed documentato. Nessun defvar/registro mutabile, nessuna copia/chiusura di FD. |
| 9. Tracciabilità e `make check` | Package/ASDF e matrice consultati in sola lettura. | Import/export collegano adapter e wrapper; ASDF ordina i due nuovi file dopo directory read. Matrice globale, build e `make check` da controllare dall'integratore dopo freeze. |
| 10. Standard e deviazioni | Safety3, ftype, docstring e REQ presenti; rilevata arità errata. | Le funzioni nuove/modificate hanno meno di 60 righe; nessun costrutto vietato aggiunto. Le guardie significative di geometria/convergenza e i handler dei caller chiudono il rilievo COD-24 della ricerca duplicato. Complessità/copertura restano nel piano delle verifiche centralizzate; nessuna deviazione richiesta dalla delta. |
| 11. Parallelismo INV-P6 | Accessi limitati alla singola Serie e al contesto proprietario. | Nessun nuovo lock, attesa o scrittura comune per GET. CAS/ring del writer e ingresso EBR esistono già; nessuna scalabilità misurata qui. |
| 12. Atomicità durevole e scarto | Wrapper prepara/adotta; punto WAL SEAL, CAS in memoria. | Non scrive un nuovo record durevole, non elimina file e non chiude FD. Rifiuti SEALED/CSN conservano gli obblighi del caller, senza rollback implicito. |

Esito: revisione del sorgente C1 e delta review completate, con GFS-REV-01
e GFS-REV-02 chiusi staticamente prima delle esecuzioni. Gli obblighi GFS-RISK-01…06 restano
documentati come limiti di integrazione/prova. Nessun altro blocco di
correttezza è emerso nei tre sorgenti sotto le precondizioni dichiarate.

Il prossimo incremento di lifecycle deve definire l'avvio con ACTIVE
vuoto e CLOSED recuperati prima del primo lotto, mantenendo autorità,
pubblicazione e superset. GFS-RISK-06 registra il limite del builder
esistente; non è una riapertura dei findings del ponte né una qualifica
di startup, rotazione o reclaim.

La revisione C4 di `tools/get-series-bench.lisp` non è conclusa: il gate
è ancora in aggiornamento da un altro agente secondo la comunicazione
dell'integratore. Nessun esito di quel tool, del collector o dei suoi
self-test è assunto per chiudere questa lettura C1.

## Decisioni da coprire dopo freeze

| ID | Sede | Condizioni e casi richiesti |
|---|---|---|
| GFS-D01 | `src/get-directory/sources-read.lisp:27` | Parola alta zero/non zero; parola bassa positiva/zero, separatamente |
| GFS-D02 | `src/get-directory/sources-read.lisp:48–50` | `active` NIL; ACTIVE presente con ID uguale; ACTIVE presente con ID diverso; il secondo operando non è valutato con NIL |
| GFS-D03 | `src/get-resolver/active-read.lisp:42` | Root del tipo corretto e sorgente EQ; tipo errato e root di sorgente diversa separati |
| GFS-D04 | `src/get-directory/sources-types.lisp:37` | Lunghezze ID/mappe uguali/diverse; cardinalità ≤ 65.536/oltre, separatamente; directory vuota valida |
| GFS-S01 | Root/fonti e owner | CLOSED-only, ACTIVE.content=fonti, forma/contenuto impossibili, controller/view estranei, owner ACTIVE diverso |
| GFS-S02 | Ricerca duplicato bounded | Directory vuota; ID presenti minimo/medio/massimo; ID assenti prima/fra/dopo; 65.536 entry; massimo u32; duplicato prima adozione e pubblicato; geometria/cardinalità impossibili e budget forzato senza convergenza |
| GFS-S03 | Cleanup e precedenza | Wrong-state senza lettura controller e senza sottrarre il pin; wrong-owner legacy prima della salute; guasto dopo ingresso libera EBR preservando FAULTED/cause |
| GFS-S04 | Root catturata e pubblicazione | Evento preparato non acquisibile dal ponte; pubblicazione B dopo cattura A mantiene risoluzione in A; candidate copiato prima di cambio root resta risolvibile |
| GFS-S05 | GET comune e migrazione | CLOSED ordinario/prepared, ACTIVE ordinario, cinque valori conservati, proof-required senza I/O, nuovo avvio nel pool I/O; risposta privata fino a copia/conclusione |
| GFS-S06 | Fault delta e ownership writer | Reader conserva reason e GET FAULTED e libera pin; writer con lease valida marca ambito Archivio e stessa condizione; lease stale/estranea rifiutata prima di esaminare una directory corrotta, senza marcare il controller |

GFS-D01…D04 sono le nuove decisioni composte COD-54 nel tratto in scope;
GFS-S01…S06 sono scenari ulteriori di guardia/protocollo. Presenza di un
test sorgente non dimostra condition coverage, MC/DC o superamento.
