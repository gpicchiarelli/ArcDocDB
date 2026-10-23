# Ricostruzione dell'indice — lettura C1 indipendente

## Ambito e stato delle evidenze

Lettura statica del 2026-10-09 di `src/index/rebuild-scan.lisp`,
`rebuild-budget.lisp`, `rebuild-copy.lisp` e `rebuild.lisp`, con lettura delle
primitive slot v2, writer, arena e directory già esistenti. Il codice è in
scrittura concorrente: questo referto non dichiara un freeze. I test assegnati
sono esclusivamente in `tests/index/rebuild.lisp`, nel package del supporto
primario scritto da Noether. Nessun test, compilazione, benchmark, copertura
o mutazione è stato eseguito dal revisore. Il parent congela ed esegue i record.

Riferimenti: [ADR-0032](../adr/0032-seqlock-a-64-bit.md),
[ADR-0043](../adr/0043-primary-index-a-frammenti.md),
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md),
[ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md),
[standard](../affidabilita/standard-di-codifica.md).
REQ-IDX-001/003/005/006/007, REQ-LIM-001/003, REQ-AFF-004/008;
invarianti INV-I1, INV-I3, INV-A8, INV-P6. Nessuna qualifica C1 o deroga approvata.

## Contratto controllato

`ricostruisci-frammento-indice` riceve HIGH/LOW u32 per **slot originale**;
gli elementi relativi a EMPTY/DELETED non sono interpretati. Restituisce cinque
valori: piano verificato, C capacità del sorgente, byte delle chiavi vive copiati,
riferimenti della directory nuova e payload transitorio. C è una dimensione,
non il numero totale di visite: misura, copia e verifica compiono tre scansioni
complete di C slot. Si aggiungono probe di al più C slot per chiave viva nelle
tre fasi; con L entry vive il lavoro dei probe è limitato da 3×L×C. Copia e
confronto delle chiavi e costruzione di 2^G riferimenti restano costi distinti.

Il preflight verifica identità corrente, owner, stato published/writable,
used entro arena, forma digest, profondità, coerenza controlli/payload,
conteggio vivo, discoverability, budget e crediti prima dei candidati.
La copia non modifica arena, payload, controlli, contatori vivi o stato del
banco sorgente; incrementa la revisione dell'indice tramite il writer dei
candidati. Il sorgente rimane published/writable e la root conserva la sua
identità fino a `pubblica-directory-indice`. La pubblicazione congela e ritira
il sorgente, incrementa revisione/generazione e applica un solo CAS della root.

La memoria conteggiata è vecchia root e frammenti distinti + directory nuova
+ 41×C per candidato + arena di ciascun candidato, almeno un byte anche se
vuoto. Scratch fissi, digest forniti dal chiamante, altre root trattenute,
header, runtime e garbage sono prenotazioni del controller; payload non è RSS.
Il budget esatto è ammesso, un byte in meno è rifiutato prima di allocare
candidati, consumare revisione o congelare il sorgente.

L'hash non è ricalcolato: prefisso già usato, H2 e lookup originale sono
verificati, ma bit HIGH non discriminati dalla profondità corrente e bit LOW
che non alterano il probe restano un contratto del fornitore fidato. Il primo
split a profondità zero non può dimostrare autonomamente il bit HIGH successivo.

## Riscontri e azioni correttive

**IR-C1-01 — propagazione del guasto del banco durante il preflight (P2,
da chiudere).** `campiona-ricostruzione` chiama direttamente
`tenta-lettura-slot`. Una parola payload stabile malformata o una sequenza
oltre limite passa per `guasto-slot`, che rende il banco FAULTED e segnala
INVARIANT-VIOLATION. In questa uscita non viene chiamato `guasto-indice`:
il preflight può restituire la condizione con `indice-primario-health` ancora
`:open`. La successiva guardia del frammento propaga il guasto; non lo fa la
sola guardia dell'indice, né una chiamata relativa a un altro frammento sano.
Root e bytes sorgente non cambiano, ma non è un fail-stop immediato dell'intero
dominio dell'indice. Azione del parent: propagare il guasto del banco al dominio
prima dell'uscita, oppure documentare e provare il confine obbligatorio del
controller che impedisce altre operazioni nella Serie dopo tale condizione.
Nessuna correzione delle sorgenti da parte del revisore.

**IR-C1-02 — COD-26, rivalutato sul main aggiornato.** Il main non contiene
più `unwind-protect`. Non acquisisce risorse esterne né un contesto condiviso:
scratch e candidati sono locali e scartabili dal GC. Le primitive writer
rilasciano il contesto busy e governano il fail-stop delle proprie mutazioni;
la verifica di una copia diversa chiama esplicitamente `guasto-indice`.
L'abbandono in una fase fredda non rende terminale l'indice solo perché il
lavoro è incompleto. La revisione già avanzata può invalidare conservativamente
un piano precedente. Non emerge una nuova violazione COD-26 nel main letto.
La sostituzione temporanea C4 di `symbol-function` nei test usa cleanup per
rilasciare/ripristinare quella risorsa del harness, preservando la condizione.

## Inventario delle decisioni — COD-54

Le coppie indicate sono obiettivi delle fixture, non esiti di copertura o MC/DC.
Le guardie delegate preesistenti sono inventariate in
[indice primario](indice-primario.md) e [slot v2](slot-indice-v2.md).

| ID | Nuova decisione composta | Condizioni da isolare |
|---|---|---|
| IR-D01 | `esigi-ricostruzione`: `and` configurazione | length HIGH=C; length LOW=C; 1≤budget≤most-positive-fixnum. Separare HIGH corto, LOW corto, budget zero/oltre massimo e configurazione valida. |
| IR-D02 | `esigi-ricostruzione`: `and` profondità split | split richiesto; depth sorgente≥max-depth. Con depth al limite, rebuild ammesso e split rifiutato; split sotto il limite ammesso. |
| IR-D03 | `verifica-digest-ricostruzione`: `and` lookup originale | trovato; found-slot=slot originale. LOW che cambia gruppo con EMPTY dà miss; duplicato fisico della chiave dà hit su un altro slot. |
| IR-D04 | `misura-ricostruzione`: `and` destinazione | split; parità dispari del prefisso alla nuova profondità. HIGH sui due lati e rebuild con HIGH alto. |
| IR-D05 | `budget-ricostruzione`: `or`/`and` frammenti | primo payload oltre budget; split; secondo payload oltre budget. Entrambi entro soglia, primo oltre, secondo oltre solo nello split; secondo irrilevante nel rebuild. |
| IR-D06 | `copia-ricostruzione-uguale-p`: `and` cinque confronti | CSN; location; key-meta senza offset basso; record-length; end-CSN. Cambiare un solo campo per volta; offset arena diverso ammesso. Predicato usato in IR-D07. |
| IR-D07 | `verifica-ricostruzione`: `and` copia | trovato; found-slot≥0; cinque confronti IR-D06. Miss e payload diverso devono rendere l'indice FAULTED. Un hit con slot negativo è escluso dal contratto di sonda-writer: eventuale FI C4 esplicita, nessuna esclusione di copertura approvata. |

Altre decisioni semplici da coprire: controllo valido/vivo/libero, stato retry
del writer, intervallo chiave entro used, used entro arena, conteggio vivo,
fingerprint, soglie directory/transitorio, generazione e credito revisione,
split con figlio vuoto, selezione figlio, assenza del secondo candidato.

## Checklist C1

| Punto | Riscontro e limite |
|---|---|
| 1. Requisiti/ADR | Annotazioni REQ e contratti coerenti con slot v2 e ADR-0050; nessun formato persistente nuovo. |
| 2. Invarianti | Fixture per root/sorgente immutati, arena compatta, payload fedele, freeze solo alla pubblicazione, revisione/generazione senza wrap. Esiti runtime demandati al parent. |
| 3. Errori | INVALID-ARGUMENT per input/digest/stale; RESOURCE-EXHAUSTED per budget/profondità/credito; INVARIANT-VIOLATION per corruzione/copia diversa. IR-C1-01 aperto. |
| 4. Limiti | Tre scansioni di C≤65536; probe≤C; chiave≤65535; directory≤2^max-depth con max-depth≤30 e budget prima dell'allocazione. Nessuna attesa o ricorsione. |
| 5. Allocazioni | Percorso di manutenzione writer, candidati/scratch allocati esplicitamente; il lookup reader non cambia. Nessuna misura heap/GC/P99 eseguita. |
| 6. Risultati verificati | Lookup sorgente prima copia, verifica byte/per-payload dopo copia e piano dopo verifica; fiducia residua nell'hash dichiarata sopra. |
| 7. Decisioni | IR-D01…07 include confronti payload dipendenti; condizioni escluse dal contratto da distinguere dalla prova runtime. |
| 8. Proprietà | Un writer mantiene il gettone lungo l'intera chiamata; digest/scratch privati; root immutabile e CAS locale. C4 symbol-function solo runner seriale isolato. |
| 9. Tracciabilità | Test con REQ nel nome; nessun `make check` eseguito. Caricamento ASDF e record spettano al parent. |
| 10. Standard | Safety 3, ftype e tipi specializzati; COD-26 sul main rivalutato. COD-24 pre/post dei piccoli helper va valutato insieme alle guardie delegate; nessuna deroga inventata. |
| 11. Serie | Nessun mutex, attesa, stato o contatore comune tra Serie; costruzione seriale solo nel writer proprietario. |
| 12. Durability | Nessun I/O, eliminazione o commit; punto atomico in memoria rimane il CAS di pubblica-directory-indice. |

## Test consegnati e mutanti

Inventario finale dei casi e nomi dei quattro bersagli runtime da completare
insieme al file di test. Tutti i casi sono seriali, deterministici e bounded;
nessun esito positivo è attribuito prima dell'esecuzione registrata dal parent.

## Chiusura del parent dopo il freeze

La sezione IR-C1-01 sopra conserva il riscontro iniziale del revisore. Il
parent lo ha chiuso con guardie specifiche su INVARIANT-VIOLATION sia in
`campiona-ricostruzione` sia in `sonda-ricostruzione`: indice FAULTED prima
della propagazione della stessa condizione del banco. I test del banco
corrotto nella scansione e del candidato corrotto incontrato dal probe
prima del proprio turno di scansione sono nella suite finale.

La lettura dell'indice di Noether ha segnalato un'ambiguità nel conteggio
slot/cambi-root. Il contratto è precisato come otto crediti di campionamento
e riavvio: una conferma finale fallita a credito zero termina senza un
nuovo probe e senza output. Il test dedicato inietta il cambio root dopo
l'ottavo campione e controlla esattamente un probe. Nessun cambiamento del
protocollo o del limite di riavvio; la conferma resta obbligatoria anche sul miss.

Il parent ha riletto tipi, budget, prefix routing, fedeltà della copia,
cleanup e complessità dei nuovi helper, separando i crediti in una funzione
per contenere i percorsi. Restano i limiti delle primitive preesistenti:
FI deterministica su sequenza cambiata durante il campione, interruzioni
interne della mutazione, fault durante la copia, x86-64 e qualifica del
motore completo. Nessuna copertura MC/DC completa dichiarata.

## Seconda lettura indipendente — Averroes

HEAD esaminato: `6796eb3931af81d4f82479c416cd9deae4b2f261`, hash riletti
stabili dal revisore. Nessun difetto funzionale bloccante rilevato; IR-C1-01
chiuso staticamente. Sono stati controllati requisiti/ADR, limiti, ownership,
preflight, fedeltà del digest/payload, crediti, integrazione e CAS.
Il revisore non ha eseguito prove e non attesta gli esiti runtime del parent.

Riscontro P2 su IR-D06: la fixture isolava soltanto location. Il parent ha
aggiunto variazioni indipendenti di CSN, key-meta alto e record-length, oltre
alla fine validità, mantenendo tutti gli altri campi identici. Offset arena
locale diverso resta ammesso. La variazione di end-CSN è FI del predicato:
nel percorso primario valido entrambi i valori sono zero, e la validazione
del banco rifiuta una fine non zero. Non qualifica retention o snapshot;
nessuna esclusione MC/DC o deroga normativa viene dichiarata approvata.
