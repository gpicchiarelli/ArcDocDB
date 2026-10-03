# Invarianti

Regole che nessuna implementazione, ottimizzazione o decisione successiva può violare senza un
cambio esplicito di specifica (ADR). Derivano dai «Principi architetturali fondamentali», dagli
invarianti della sezione «Fault injection» e dalle regole normative delle singole sezioni della
[specifica](specifica/prompt-originale.md).

Ogni invariante ha un identificativo stabile. La colonna **Verifica** indica come se ne
controlla il rispetto: scenari di [fault injection](14-fault-injection.md) (`FI-…`), test,
revisione del progetto o benchmark.

## Storage

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-S1 | Lo storage è append-only: i record già scritti nei segmenti non vengono mai modificati in-place. | Storage append-only | test, revisione |
| INV-S2 | Per ogni Serie esiste esattamente un segmento `ACTIVE`. | Storage append-only | test, recovery |
| INV-S3 | Solo il segmento `ACTIVE` è scrivibile. | Segmenti | test |
| INV-S4 | I segmenti `CLOSED`, `OBSOLETE` e `RECLAIMABLE` sono sempre immutabili; un segmento non torna mai `ACTIVE` né viene riaperto in scrittura. | Storage append-only, Segmenti | test |
| INV-S5 | Le nuove scritture vanno sempre in un nuovo segmento `ACTIVE`; non si aggiungono mai record a un segmento prodotto dalla compaction. | Segmenti | test |
| INV-S6 | I segment metadata sono dati derivati: non sono l'unica fonte di verità e devono poter essere ricostruiti, verificati e corretti da WAL, dati e indice. | Segment metadata | FI-10, test |

## Compaction

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-C1 | CLEAN: 1 segmento sorgente → 1 nuovo segmento immutabile con i soli record live/necessari. | Clean | test |
| INV-C2 | MERGE: N segmenti → 1 nuovo segmento immutabile. | Merge | test |
| INV-C3 | CLEAN e MERGE sono copy-on-write: non modificano mai i segmenti sorgente. | Clean, Merge | FI-07, FI-08 |
| INV-C4 | I segmenti prodotti dalla compaction non hanno requisiti di dimensione; MERGE non è automatico dopo CLEAN; un segmento pulito può restare piccolo indefinitamente. | Segmenti, Merge | test della policy |
| INV-C5 | MERGE solo su segmenti stabili da almeno 50 secondi (dal timestamp di chiusura/stabilizzazione). | Condizioni obbligatorie per Merge | test della policy |
| INV-C6 | MERGE solo quando il carico del motore è basso; non deve competere con il traffico utente. | Low-load merge policy | test della policy, benchmark |
| INV-C7 | Un nuovo segmento non diventa visibile come definitivo prima che i suoi dati siano durevoli. | Recovery | FI-06 |
| INV-C8 | Un segmento sorgente resta recuperabile fino al completamento dello swap. | Fault injection (5) | FI-06, FI-07, FI-08 |
| INV-C9 | Una compaction interrotta è ripetibile o completabile durante il recovery. | Fault injection (6) | FI-07, FI-08 |
| INV-C10 | La compaction non blocca globalmente le letture; i reader già attivi terminano sui segmenti vecchi. | Readers durante compaction | test di concorrenza, benchmark |

## Reclaim

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-R1 | Un segmento viene eliminato solo quando nessun indice corrente, nessuno snapshot, nessuna transazione attiva e nessun reader lo referenzia o lo utilizza. | Index/Snapshot/Reclaim; Fault injection (3) | FI-09, FI-11 |

## WAL e log

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-W1 | Ogni Serie ha un WAL indipendente ed è fisicamente indipendente dalle altre; non esiste un global data WAL. | WAL, Layout fisico | revisione |
| INV-W2 | Esiste un unico `Registri/multiserie.log` per Archivio; non esiste un file per transazione. | Serie speciale Registri | revisione |

## Transazioni e durability

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-D1 | Nessun dato committed va perso. | Fault injection (1) | FI-01, FI-02, FI-05, FI-06, FI-09, FI-10 |
| INV-T1 | Una transazione single-Series usa solo il WAL della Serie e non scrive su `multiserie.log`. | Transazioni single-series | test |
| INV-T2 | Il controllo della versione attesa è atomico rispetto all'applicazione della modifica da parte del writer della Serie. | Transazioni single-series | test di concorrenza |
| INV-T3 | Una transazione multiserie è committed solo quando la decisione `COMMIT` è durevole in `multiserie.log`. | Transazioni multiserie | FI-04, FI-05 |
| INV-T4 | Nessuna transazione multiserie risulta parzialmente committed. | Fault injection (2) | FI-03, FI-04, FI-05, FI-12 |
| INV-T5 | Tutte le modifiche di una transazione multiserie condividono un unico TXID. | Transazioni multiserie | FI-12 |

## MVCC e snapshot

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-M1 | Nessuno snapshot osserva una versione non coerente: la vista resta quella del suo punto di creazione fino alla conclusione. | Snapshot/MVCC; Fault injection (4) | FI-11, test di concorrenza |
| INV-M2 | Uno snapshot impedisce alla compaction di eliminare le versioni di cui ha bisogno. | Snapshot/MVCC | FI-11 |
| INV-M3 | La cache è consapevole della versione/epoch: non restituisce a un reader una versione incompatibile con il suo snapshot. | Cache e snapshot | test di concorrenza |

## Indici

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-I1 | Gli indici sono immutabili per i reader; gli aggiornamenti diventano visibili tramite atomic swap e i reader precedenti completano sulla versione vecchia. | Index snapshot | test di concorrenza, FI-06 |
| INV-I2 | Il Bloom filter per segmento indica solo «sicuramente assente / potenzialmente presente»; non è mai la struttura di localizzazione definitiva. | Secondary index | revisione, test |

## Concorrenza e priorità

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-P1 | Un solo writer logico per Serie; molti reader concorrenti. | Concorrenza | revisione, test |
| INV-P2 | Nessun global writer lock, nessun thread permanente per Serie, nessun thread per richiesta. | Concorrenza | revisione |
| INV-P3 | Le Serie sono isolate nel carico: il traffico su una Serie non impedisce scritture, query o compaction controllata sulle altre. | Parallelismo | benchmark (burst) |
| INV-P4 | Priorità: traffico utente > WAL/durability > CLEAN necessario > MERGE opportunistico. | Compaction scheduler dinamico | benchmark, test della policy |

## Metodo

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-X1 | SIMD e ottimizzazioni native si introducono solo sugli hot path dove i benchmark ne dimostrano l'utilità. | SIMD e ottimizzazioni native | revisione |
| INV-X2 | I target di prestazione sono ipotesi finché non verificati da benchmark riproducibili; nessuna dichiarazione di superiorità da benchmark eterogenei. | Target preliminari, Confronto | revisione |
| INV-X3 | Il codice del progetto è solo Common Lisp, finché un ADR non riapre l'uso di codice foreign. | [ADR-0001](adr/0001-common-lisp-sbcl.md) (decisione del 2026-10-01) | revisione |

## Derivati dalle decisioni di progetto (ADR 0013–0030)

| ID | Invariante | Fonte | Verifica |
|---|---|---|---|
| INV-F1 | Ogni record e ogni file persistente porta lunghezza e CRC32C; ciò che non si verifica è trattato come inesistente (coda troncata) o rigenerato (dato derivato). | [ADR-0013](adr/0013-log-structured-segmento-active-come-log.md), [ADR-0014](adr/0014-formato-record-documento-id.md) | FI-01, FI-02, FI-10 |
| INV-V1 | Con durability `:group` o `:strong`, nessun reader vede una versione prima che sia durevole. | [ADR-0019](adr/0019-durability-e-group-commit-pipelined.md) | FI-01, FI-02 |
| INV-V2 | Uno snapshot vede una transazione multiserie per intero o per niente: il suo CSN è pubblicato solo dopo la decisione durevole, e la creazione dello snapshot attende le multiserie in applicazione con CSN inferiore. | [ADR-0020](adr/0020-csn-snapshot-isolamento.md), [ADR-0021](adr/0021-2pc-intenti-outcome.md) | FI-12, modello SPK-07 |
| INV-V3 | Una rilocazione da compaction aggiorna una entry dell'indice solo se punta ancora alla location sorgente; non sovrascrive mai una versione più nuova. | [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) | FI-06, test di concorrenza |
| INV-V4 | Ogni modifica allo stato di una Serie (indice, intenti, versioni trattenute, delta, contatori, control log) è applicata dal writer logico della Serie. | [architettura](architettura.md#contratti) | revisione |

## Corrispondenza con i principi della specifica

Tutti i 33 punti dei «Principi architetturali fondamentali» sono coperti: i principi che sono
vincoli verificabili sono invarianti qui sopra; quelli che sono indirizzi di progetto (group
commit, scheduler dinamico, primary index altamente ottimizzato, secondary index specializzati,
cache anti-scan-pollution, thread pool dinamico, recovery crash-safe, fault injection, benchmark
riproducibili) sono requisiti dei rispettivi documenti tematici e ADR.
