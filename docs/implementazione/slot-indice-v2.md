# Slot compatti dell'indice, formato v2

## Ambito — 2026-10-09

`arcdocdb.index.slots` realizza il banco di parole di un frammento e il suo
protocollo single-writer/multi-reader: cinque parole u64 per slot primario,
sei per le versioni trattenute, secondo
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md).
Con il controllo Swiss separato il costo previsto è 41/49 byte per slot,
escluse chiavi, header degli array e runtime.

Il componente implementa payload e seqlock, secondo
[ADR-0032](../adr/0032-seqlock-a-64-bit.md),
[ADR-0043](../adr/0043-primary-index-a-frammenti.md) e
[ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md).
Mancano sondaggio, controllo Swiss, arena, directory e versioni trattenute
ricercabili. Non è ancora la tabella dell'indice o un GET completo.

Classe C1: REQ-IDX-001, REQ-IDX-003, REQ-IDX-004, REQ-IDX-005,
REQ-IDX-006, REQ-IDX-007, REQ-LIM-001, REQ-LIM-003, REQ-CON-004,
REQ-AFF-004 e REQ-AFF-008. Invarianti: INV-I1, INV-I3, INV-V3, INV-A8,
INV-P6. I requisiti restano progettati; le decisioni architetturali invariate.

## Proprietà, memoria e layout

Un banco appartiene a un frammento della Serie. Il controller lo alloca
prima della pubblicazione; il writer con gettone esclusivo è l'unico a
pubblicare, rimuovere, rilocare o congelare. Nessun thread permanente,
mutex, coda, callback o I/O; nessun contatore comune tra Serie.

Capacità 1..65.536 slot, default 8.192: è un limite del banco, non della
Serie. Il budget controlla `capacità × parole × 8` prima dell'allocazione.
Riguarda il solo payload, non RSS, directory o memoria transitoria.
Il futuro gestore del frammento aggiunge i costi degli altri array.
Nessun array cresce in questo componente.

| Word | Layout v2 |
|---|---|
| 0 | CSN u64 |
| 1 | segment-id nei 32 bit alti, offset nei 32 bit bassi |
| 2 | key-off(32), key-len(16), flag(8), riservato(8), dal bit basso |
| 3 | seqlock u64 |
| 4 | record-len(32), riservato(32) |
| 5, solo trattenuto | CSN di fine validità esclusivo |

Flag vivo 1; slot vuoto con tutti i campi zero, salvo il seqlock. Non sono
il controllo Swiss, il flag PREPARED o un tombstone dello storage.
Controllati: riservati, chiavi 1..65.535, rappresentabilità dell'intervallo
chiave, lunghezza record/documento, fine record entro i 4 GiB − 1 del
segmento. Nel primario la fine è zero; nel trattenuto è maggiore del CSN.
Arena, segmento, manifest, decisione di commit e integrità dei byte sono
verificati dal livello superiore.

Il buffer privato preallocato del worker ha **cinque u64** in ordine
`[CSN, location, key-meta, record-len, end-CSN]`. Non contiene seqlock,
riferimenti o descrittori. Nessun altro worker modifica input/output
durante la chiamata. Nessun u64 del payload è restituito come valore Lisp
dal percorso di lettura; l'assenza di allocazioni richiede ancora misure.

## API e protocollo

| API | Contratto |
|---|---|
| `crea-banco-slot` | Preallocazione con capacità, tipo primario/trattenuto e budget. |
| `leggi-slot-v2(bank, slot, buffer)` | `:live` copia dati coerenti; `:empty`/`:retry-limit` lasciano il buffer intatto. Non autorizza da sola un GET. |
| `credito-scrittura-slot(bank, slot)` | Preflight: incrementi doppi ancora ammessi; non li prenota. |
| `pubblica-slot-v2(bank, slot, source)` | Pubblica un payload vivo; conflitti, retention, chiave/arena e budget già risolti dal writer. |
| `rimuovi-slot-v2(bank, slot)` | Azzera sotto seqlock; rimozione già conclusa idempotente; controllo Swiss DELETED dopo. |
| `riloca-slot-v2(bank, slot, expected, replacement)` | Cambia solo la location se tutti i campi correnti coincidono con quelli originali; altrimenti `NIL`, senza modifiche. |
| `congela-banco-slot(bank)` | Non scrivibile permanentemente, leggibile; non pubblica una directory. |
| `invalida-banco-slot(bank)` | Salute terminale `FAULTED`, ripetibile senza mutex; il confine della Serie deve isolare il dominio. |

Writer: contenuto originale e credito verificati, sequenza dispari,
barriera di scrittura, campi, barriera di scrittura, sequenza pari.
Il ritorno attesta la pubblicazione in memoria, senza durability o commit.
Reader: prima sequenza, rifiuto se dispari, barriera di lettura, campi,
barriera di lettura, seconda sequenza. Si verifica e copia solo un campione
stabile. Incoerenza stabile porta a `FAULTED` e `invariant-violation`;
campi transitori non vengono interpretati come corruzione. Salute acquisita
prima/dopo la lettura e dopo la copia. Su errore o uscita non locale il
chiamante scarta il risultato privato.

La API tenta al massimo otto volte. Il futuro sondaggio usa il tentativo
interno nello **stesso budget complessivo**, senza moltiplicarlo per slot
o cambi root. Al limite scarta la location e passa la richiesta originale
al writer della Serie. Anche un miss richiede il ricontrollo finale di
root/generazione di ADR-0050; seqlock valido non lo sostituisce.

## Crediti, rilocazione e interruzioni

La sequenza non raggiunge 2^62 e non fa wrap. Prima del commit il writer
confronta il credito con **tutte** le mutazioni già prenotate dai lotti
pendenti per lo slot, oppure prepara un rebuild. La contabilità dei lotti
resta esterna; il numero restituito non è una prenotazione. La mutazione
ricontrolla il credito prima del primo store. Verifiche, rimozioni già
concluse e rilocazioni non applicabili non richiedono credito aggiuntivo.

Rilocazione: CSN, key-meta, lunghezza e fine rimangono identici; confronto
e applicazione serializzati dal writer. Versione più nuova o location già
sostituita non vengono sovrascritte. Il messaggio di compaction si ricerca
per chiave nella root corrente: non conserva slot o offset arena oltre
split/rebuild. `expected` si associa a quel lookup corrente prima della
primitiva. Copia durevole, manifest, retention e reclaim sono esterni.

Uscita non locale nella mutazione => `FAULTED`, anche dopo la sequenza pari.
Nessun rollback, reset o riapertura del banco congelato. Il futuro gestore
pubblica root, controllo Swiss e arena con controlli e cleanup propri.

## Decisioni da coprire — COD-54

| ID | Decisione composta | Condizioni indipendenti |
|---|---|---|
| SLOT-D01 | Configurazione | Capacità nel range; budget positivo; payload entro budget. |
| SLOT-D02 | Payload vivo | CSN positivo; flag 1; riservato key zero; key-len positiva; intervallo chiave rappresentabile. |
| SLOT-D03 | Record/location | Riservato length zero; minimo header+key; massimo record; limite documento; fine record entro segmento. |
| SLOT-D04 | Intervallo MVCC | Primario con fine zero; trattenuto con fine maggiore del CSN. |
| SLOT-D05 | Sequenza writer | Dispari; oltre soglia; credito disponibile separato dalla verifica. |
| SLOT-D06 | Identità attesa | Uguaglianza separata di CSN, location, key-meta, lunghezza e fine. |
| SLOT-D07 | Copia da rilocare | CSN, key-meta, lunghezza e fine invariati; location distinta o uguale. |

Altre transizioni da esercitare: otto sequenze dispari/cambiate; incoerenza
solo transitoria; vuoto e riuso; CSN oltre fixnum/fino a u64 massimo; chiavi
massime; credito zero; guasto concorrente; interruzione prima/durante/dopo
pubblicazione; congelamento e ritiro. Nessuna copertura dichiarata.

## Metodo delle evidenze e qualifica

Metodo stabilito prima dei controlli: compilazione del solo `arcdocdb` con
avvisi come errori; lint, tracciabilità, link e cataloghi. Record originali
e disassemblato ARM64 della lettura/pubblicazione conservati per ispezione
statica, senza chiamare le funzioni del nuovo modulo. Rifiuti conservati.

Le due letture locali hanno controllato separatamente payload e protocollo:
validazione solo dopo un campione stabile, rifiuto dei riservati, credito
seqlock distinto dalle verifiche/rilocazioni senza effetto, proprietà dei
buffer, congelamento e salute terminali. I predicati chiave e record sono
separati e inline per contenere la complessità senza aggiungere ritorni u64.
Il disassemblato ARM64 conserva i load/store delle parole native e le
barriere `DMB ISHLD`/`DMB ISHST`; questa ispezione non è una prova concorrente.

Il primo controllo dei cataloghi ha rifiutato riferimenti a sottocartelle.
Catalogo iniziale e rifiuto sono conservati; i report e i metadati originali
sono stati spostati senza ricodificarli in file nella directory della
campagna, come richiede il verificatore esistente. La sorgente del collector
iniziale e quella della correzione sono conservate come dati.

La [campagna dedicata](../../spikes/results/2026-10-09-index-slots/README.md)
ha questo ambito. Nessun test funzionale, concorrente, fault injection,
modello, benchmark o auto-verifica degli strumenti aggiunto/eseguito
localmente. Il codice e le misure v1 di SPK-01 non qualificano il layout v2.

Restano qualifica C1, interleaving e disassemblato x86-64, allocazione/P99,
sondaggio/arena/directory con budget condiviso, retention, recovery e
writer integrati. Gate del motore completo aperto. Le due letture locali
del codice non sono revisioni indipendenti.
