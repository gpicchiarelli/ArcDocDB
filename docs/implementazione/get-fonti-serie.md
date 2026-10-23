# Fonti GET nella radice del controller Serie

Questo incremento collega la directory CLOSED e il resolver ACTIVE alla
radice già pubblicata dal controller della Serie. Il protocollo usa il CAS
esistente e il medesimo compito EBR del candidato. La revisione è in
[get-fonti-serie-revisione.md](get-fonti-serie-revisione.md); il piano delle
esecuzioni centralizzate è nel
[README della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-fonti-serie/README.md).

Compaction, rotazione, rilocazione completa del primary e reclaim non sono
implementati da questo ponte. Non vengono introdotti un CAS aggiuntivo,
un registro di lifetime, la chiusura di FD o la rimozione di file. Il
contenitore non certifica la coerenza dell'indice concreto né la qualifica C1.

## Grafo e proprietà

`fonti-get-serie` contiene esattamente due riferimenti readonly:
`directory`, una `directory-get-serie` CLOSED già verificata, e `content`,
il contenuto opaco del caller. `crea-fonti-get-serie(directory, :content C)`
crea il solo contenitore; `contenuto-fonti-get-serie` restituisce C.
Non copia directory, mappe, FD o C. Il grafo di C è preso in prestito:
il proprietario lo mantiene immutabile e valido fino all'ultimo lettore.
`read-only` impedisce la sostituzione degli slot, senza rendere immutabile
un oggetto esterno mutabile.

La radice pubblicata ammette due forme:

| Forma della radice | Fonti CLOSED | Fonte ACTIVE | Contenuto del caller |
|---|---|---|---|
| `fonti-get-serie` | `directory` del contenitore | Nessuna | `contenuto-fonti-get-serie(root)` |
| `radice-get-attiva` | `directory` del contenitore in `content` della radice ACTIVE | Directory di pagine della stessa radice ACTIVE | `contenuto-fonti-get-serie(contenuto-radice-get-attiva(root))` |

Il worker accetta soltanto le forme pubblicate. Directory e segmento
ACTIVE devono appartenere per identità EQ alla vista canonica della
richiesta. La sorgente ACTIVE deve indicare lo stesso controller da cui
la radice è stata acquisita; il suo ID storage ha parola alta zero e
parola bassa positiva u32. Quell'ID deve essere assente dalla directory
CLOSED. Il reader verifica anche un duplicato impossibile già pubblicato,
che è un guasto interno e non una scelta arbitraria fra due fonti.

## Preparazione, adozione e pubblicazione

Il writer costruisce la directory CLOSED con le API esistenti, poi prepara
il contenitore immutabile. Una Serie di sola lettura CLOSED può ricevere
il contenitore come radice iniziale del controller, con l'associazione
log/vista/Archivio verificata dal caller prima dell'ammissione dei worker.
Questo incremento non aggiunge una transizione di rotazione verso quella
forma.

Per un nuovo ACTIVE il controller parte secondo il protocollo ACTIVE
esistente, con radice pianificata NIL e offset iniziale dell'header.
La preflight `verifica-capienza-get-attiva` precede l'assegnazione CSN;
sigillatura e preparazione del contenuto seguono il protocollo WAL.
`registra-lotto-fonti-get-attivo(source, lease, batch, previous, sources, level)`:

1. verifica lease corrente e salute del controller prima delle guardie
   sulle fonti e di qualsiasi effetto di fault;
2. verifica che la directory di `sources` appartenga alla vista del
   segmento ACTIVE;
3. cerca l'ID ACTIVE nella directory CLOSED con al più diciassette pivot
   e rifiuta un duplicato;
4. delega a `registra-lotto-get-attivo` con `sources` come contenuto della
   nuova radice ACTIVE; conserva lease, token, FIFO, budget e verifiche WAL;
5. restituisce evento, generazione e radice pianificata. Il caller conserva
   l'ultima radice pianificata per l'adozione successiva.

Owner e duplicato sono rifiutati con `invalid-argument` prima dell'adozione,
senza mutare il ring o consumare l'evento. Poiché il lotto è già SEALED/CSN,
il caller deve conservare lotto e token e gestire il rifiuto con il
protocollo WAL esistente; non può scartarli come se il CSN non esistesse.
Il wrapper non verifica automaticamente che le nuove fonti coprano quelle
necessarie ai reader: è un obbligo del writer.

Solo il normale `pubblica-commit-serie`, dopo la copertura prevista da
`:async`, `:group` o `:strong`, espone la radice tramite il CAS esistente.
Il SEAL conserva il punto di atomicità WAL; il CAS pubblica memoria.
Un evento preparato e il valore restituito dalla registrazione non sono
una prova di pubblicazione. Le location del primary diventano osservabili
soltanto dopo che le fonti corrispondenti sono pubblicate.

## Bootstrap con ACTIVE vuoto

L'[inizializzazione della radice vuota](get-active-vuoto.md) rende i CLOSED
recuperati consultabili prima del primo lotto. Dopo preparazione dell'header
e decisione EDIT, il writer crea il controller con root NIL e offset 64,
crea la sorgente ACTIVE e chiama
`inizializza-fonti-get-attive(source, lease, sources)` prima dell'ammissione.
La radice restituita ha zero pagine, PUT e nodi, directory NIL e fine 64.
Il primo lotto la usa come `previous`; i successivi usano l'ultima radice
pianificata. Nessun lotto fittizio, evento o CSN viene assegnato all'avvio.

L'avvio usa il medesimo slot atomico della Serie; ogni lotto continua a
pubblicare con il CAS e la copertura WAL ordinari. Il percorso legacy con
controller iniziale NIL e primo lotto senza bootstrap rimane disponibile.
Una radice CLOSED-only iniziale è leggibile ma non è una radice ACTIVE:
non la si può passare al builder né trasformare in-place. Il caller sceglie
la forma ACTIVE vuota durante la costruzione del controller.

Restano aperti l'esecutore di apertura con EDIT, la rotazione e il reclaim
completi. Le singole factory non provano unicità del controller, lifetime
dei FD o completamento della decisione del catalogo.

## Copertura delle location e reader già ammessi

Sia `R` la radice acquisita dopo il lookup, `S(R)` l'insieme delle location
risolvibili dalle sue mappe CLOSED e pagine ACTIVE e `L` l'insieme delle
location che i reader già ammessi possono ancora osservare o avere copiato
dal primary. L'obbligo è **`L ⊆ S(R)`** per ogni acquisizione ammessa.
La presenza del solo ID di un segmento non basta: devono restare disponibili
la riga dell'offset, CSN, size, frontiera e prova del candidato.

Esempio: un reader entra in EBR e `avvia-get` copia la location del segmento
7. Il writer pubblica una nuova directory per il segmento 8 e aggiorna il
primary. Quando il reader acquisisce la nuova radice, questa deve ancora
risolvere la location del segmento 7. Conservare soltanto la vecchia radice
in memoria o lasciare aperto il vecchio FD non basta: il ponte cerca nelle
fonti della radice che ha appena acquisito. Una mappa mancante provoca un
guasto del candidato già pubblicato, mai `:absent`.

L'ordine «fonti prima delle location» risolve l'introduzione di nuove fonti;
il superset risolve la conservazione delle fonti che possono ancora servire.
EBR protegge il lifetime delle capacità acquisite nel compito; non aggiunge
una fonte rimossa dalla directory e non rende le fonti una vista snapshot
del primary. Una futura rotazione/reclaim deve dimostrare entrambi gli
obblighi prima di ridurre quel superset o chiudere una risorsa.

Il [metodo della verifica integrata del lifetime](get-lifetime.md) esercita
questi obblighi con FD reali, pubblicazioni ordinarie e ritiro EBR.
La prova mantiene distinti il FD catturato dal reader e le fonti che un
nuovo lookup può acquisire; il catalogo durabile resta una precondizione.

## Lettura nel compito GET

Il caller installa il cleanup esterno prima di `avvia-get`. Se l'esito è
`:candidate`, usa una delle API della Serie nel medesimo compito:

| API | Esito e responsabilità |
|---|---|
| `risolvi-candidato-serie-get(context, controller)` | Una sola acquisizione della radice; capacità readonly, fine autorevole, flag storage e prova OUTCOME/NIL |
| `sonda-cache-serie-get(context, controller)` | Sonda senza I/O; `:hit`, `:miss`, `:verify-failed`, `:disabled`, `:proof-required` o `:buffer-required` |
| `leggi-record-serie-get(context, controller)` | Nel worker I/O, cinque esiti del nucleo GET; prepared conserva la rilettura OUTCOME autorevole |

Ogni invocazione di risoluzione acquisisce la radice una sola volta, dopo
il controllo CANDIDATE/EBR. La funzione interna `acquisisci-fonti-serie-get`
deriva fonti e ACTIVE dalla stessa lettura acquire del controller.
Il segmento della location sceglie ACTIVE solo se coincide con il suo ID;
gli altri candidati vanno al resolver CLOSED. I controlli di riga, entrambe
le word CSN, size, flag, FD e frontiera sono delegati al resolver comune.
GET verifica ancora record/cache, CRC, chiave e prova prima della risposta.

Il ramo ACTIVE chiama `risolvi-candidato-radice-attiva-get(context, root)`
con la radice appena catturata. Quest'API non rilegge il controller. La sua
precondizione richiede una radice già pubblicata, acquisita dopo il pin
nello stesso EBR; il tipo `radice-get-attiva` non distingue una radice
preparata. L'adapter esplicito affida questa prova al caller. Il ponte della
Serie la soddisfa leggendo soltanto `leggi-radice-serie`. Il wrapper legacy
`risolvi-candidato-attivo-get(context, source)` conserva l'acquisizione
singola e delega allo stesso adapter.

Il valore resta privato fino a `copia-valore-get` e `concludi-get` con tempo
fresco. Per miss di cache, buffer insufficiente o prepared, il passaggio
al pool I/O trasferisce la richiesta originale: il nuovo worker esegue
nuovo `avvia-get`, nuova epoca e nuova acquisizione. Pin, radice, location
e FD non attraversano la coda.

## Errori, invarianti e limiti della prova

Wrong-state è respinto prima di assumere il cleanup. Owner estraneo è
`invalid-argument`. Forma della radice/contenuto impossibile, associazione
ACTIVE/controller incoerente, ID ACTIVE invalido o duplicato pubblicato
producono `guasto-get` e `invariant-violation`. Fonti/riga mancanti non
sono assenza logica. Gli errori dopo l'ammissione rilasciano EBR; il confine
del worker deve isolare Serie/Archivio secondo la causa. Il solo stato
FAULTED del contesto non prova che il controller sia già stato isolato.

La ricerca del duplicato verifica prima l'uguaglianza delle cardinalità
di ID/mappe e il massimo di 65.536 entry. Dopo i diciassette pivot esige
la convergenza `left = right` prima di restituire assenza. Geometria o
convergenza impossibili segnalano `invariant-violation` con reason
`:directory-shape` o `:directory-search-bound`. Nel reader il handler
conserva la reason tramite `guasto-get`, rende il GET FAULTED e il cleanup
del resolver libera EBR. Nel writer, dopo il controllo di lease/salute,
il handler marca il controller `:archive-faulted` e ripropaga la stessa
condizione; non adotta il lotto e non risolve implicitamente il token.

Gli invarianti interessati sono INV-A2, INV-A3, INV-A4, INV-A8, INV-R1,
INV-M1, INV-M4, INV-P1, INV-P5, INV-P6 e INV-V4. La tracciabilità locale
usa REQ-IDX-001, REQ-WAL-006, REQ-CMP-007, REQ-CCH-002, REQ-FOR-004,
REQ-CON-004, REQ-AFF-002 e REQ-AFF-008. Riferimenti:
[standard](../affidabilita/standard-di-codifica.md),
[ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md),
[ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md),
[ADR-0036](../adr/0036-leggi-di-progetto.md),
[ADR-0037](../adr/0037-lotto-sigillato.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md),
[directory CLOSED](get-directory.md) e [resolver ACTIVE](get-active.md).

Il contenitore proprio ha due riferimenti; oggetti/header Lisp, grafo opaco,
directory, mappe, FD, radici trattenute ed EBR sono costi distinti.
La ricerca di un duplicato usa i limiti della directory canonica
(0–65.536 segmenti; diciassette pivot). Il nuovo lookup non contiene
allocazioni esplicite, lock, attese o I/O; COD-30, latenza, boxing e RSS
richiedono misure centralizzate. Le due letture statiche non attestano
compilazione, esiti di test, copertura o qualifica C1.
