# 07 — Compaction

> **Fonte:** «Clean», «Merge», «Condizioni obbligatorie per Merge», «Low-load merge policy»,
> «Politica generale di compaction», «Compaction parallela», «Workflow Clean/Merge», «Readers
> durante compaction», «Compaction scheduler dinamico» della
> [specifica](specifica/specifica-originale.md).
> **Moduli:** M11 Compaction Manager (con M13 Scheduler).
> **Decisioni:** [ADR-0018](adr/0018-control-log-manifest-swap.md) e
> [ADR-0040](adr/0040-manifest-a-record-unico.md) (swap = un record EDIT, deciso prima della
> rinomina; stabilizzazione), [ADR-0023](adr/0023-politiche-di-compaction.md) (soglie, stati
> di carico), [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) (tombstone),
> [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) (rilocazione condizionale),
> [ADR-0016](adr/0016-epoch-based-reclamation.md) (reclaim).

## Due operazioni, due scopi

| | CLEAN | MERGE |
|---|---|---|
| Scopo | recuperare spazio morto, rimuovere versioni inutili | ridurre frammentazione e numero di segmenti, migliorare la località di lettura |
| Ingresso → uscita | 1 segmento → 1 nuovo segmento immutabile | N segmenti piccoli → 1 nuovo segmento immutabile |
| Quando | quando un segmento ha spazio morto significativo | solo se esistono troppi segmenti piccoli **e** valgono tutte le condizioni sotto |
| Vincolo di stabilità | nessuno | segmenti fermi da ≥ 50 s |
| Vincolo di carico | modulato dallo scheduler | solo a basso carico |
| Natura | necessario | opportunistico |

Entrambe sono **copy-on-write**: non modificano mai i segmenti sorgente (INV-C3) e producono
sempre un nuovo segmento immutabile (INV-C1, INV-C2).

## Politica generale

| Condizione del segmento | Azione |
|---|---|
| `live = 0` | eliminazione diretta, se nessuno snapshot/riferimento lo utilizza |
| `0 < live < total` | CLEAN → nuovo segmento con i soli record live/necessari |
| `live ≈ total` | nessuna compaction |
| troppi segmenti piccoli | MERGE, **solo se** i candidati hanno ≥ 50 s di stabilità **e** il carico è basso |

> **Deciso (QA-11 → [ADR-0023](adr/0023-politiche-di-compaction.md))** — Le soglie numeriche non sono specificate: quanto spazio morto fa
> scattare un CLEAN, che cosa conta come «piccolo», quanti segmenti piccoli fanno un gruppo,
> dimensione massima dell'output di un MERGE.

## CLEAN

```
S017: 256 MB totali, 20 MB live, 236 MB dead
CLEAN: S017 → S042 (20 MB, immutabile)
```

Il segmento sorgente:

- non viene modificato;
- diventa `OBSOLETE` dopo lo swap;
- resta leggibile finché necessario;
- viene eliminato solo quando nessun reader/snapshot lo utilizza.

«Record necessari» comprende sia le versioni `LIVE` sia le `SNAPSHOT-LIVE`
([03 Storage](03-storage.md#classificazione-delle-versioni)).

Il segmento prodotto può essere molto più piccolo di 256 MB e **può restare piccolo
indefinitamente** (INV-C4): non si esegue automaticamente un MERGE dopo un CLEAN, e non vi si
aggiungono nuove scritture (INV-S5).

## MERGE

### Condizioni obbligatorie

Un segmento è candidato a MERGE **solamente se** tutte le condizioni sono vere:

1. è `CLOSED`;
2. è immutabile;
3. non è `ACTIVE`;
4. è fermo da almeno **50 secondi** (INV-C5);
5. non è necessario a uno snapshot attivo;
6. appartiene a un gruppo che supera le soglie di segmentazione/numero di piccoli segmenti;
7. il motore è in condizione di **basso carico** (INV-C6).

### Regola di stabilità

```
segment age >= 50 secondi
```

Il timestamp di riferimento è quello di **chiusura/stabilizzazione** del segmento. Lo scopo è
non compattare immediatamente segmenti appena chiusi. La regola si applica al solo MERGE, non
al CLEAN.

> **Deciso (QA-13 → [ADR-0018](adr/0018-control-log-manifest-swap.md))** — Per un segmento prodotto da CLEAN o MERGE il timestamp di
> «stabilizzazione» va definito (proposta: l'istante in cui lo swap è completato). Va inoltre
> deciso che cosa succede dopo un riavvio, dato che il close time vive nei metadata, che sono
> dati derivati: l'opzione conservativa è far ripartire il conteggio dal termine del recovery.
> Serve un orologio monotono.

> **Deciso (QA-14 → [ADR-0020](adr/0020-csn-snapshot-isolamento.md))** — La condizione 5 implica che uno snapshot longevo sospende il MERGE dei
> segmenti che gli servono, anche se il MERGE è copy-on-write e i sorgenti resterebbero
> comunque leggibili fino al reclaim.

### Low-load policy

Prima di avviare un MERGE, il Compaction Scheduler DEVE verificare il carico del motore,
considerando almeno:

| Area | Segnali |
|---|---|
| CPU | utilizzo CPU, numero di worker attivi |
| Richieste | latenza P95 e P99, profondità delle code, throughput |
| WAL | throughput, latenza WAL/fsync |
| I/O | utilizzo NVMe, I/O queue depth |
| Compaction | backlog di compaction |

Se il carico è alto:

- non avviare nuovi MERGE;
- ridurre la concorrenza dei MERGE;
- dare priorità a richieste utente e WAL.

Se il carico aumenta significativamente **durante** un MERGE:

- non avviare nuovi MERGE;
- ridurre la concorrenza futura;
- eventualmente mettere in pausa o rallentare il lavoro non critico.

Il MERGE NON DEVE monopolizzare CPU, NVMe, memoria, cache, memory bandwidth, e NON DEVE
competere con il traffico utente.

> **Deciso (QA-12 → [ADR-0023](adr/0023-politiche-di-compaction.md))** — «Basso carico» va reso operativo: soglie, finestre di osservazione,
> isteresi per evitare oscillazioni. Va deciso se un MERGE in corso si può sospendere e
> riprendere o solo abbandonare (l'output parziale è scartabile senza danni, perché i sorgenti
> sono intatti). Va infine deciso che cosa accade se il carico non scende mai: il MERGE non
> parte e il numero di segmenti cresce (RSK-08).

## Workflow

Comune a CLEAN e MERGE:

| # | Passo | Stato su disco / visibilità |
|---|---|---|
| 1 | selezionare il segmento candidato | — |
| 2 | verificare lo stato | sorgente `CLOSED` |
| 3 | verificare snapshot/riferimenti | determina i record necessari |
| 4 | leggere sequenzialmente il segmento | sorgente invariato |
| 5 | copiare solo i record necessari | nuovo file in costruzione, non visibile |
| 6 | creare il nuovo segmento | non visibile |
| 7 | `fsync` del nuovo segmento | dati durevoli, ancora non visibile |
| 8 | preparare i metadata | — |
| 9 | **atomic index swap** | i nuovi reader usano il nuovo segmento |
| 10 | segnare il sorgente `OBSOLETE` | sorgente ancora leggibile |
| 11 | attendere che nessun reader/snapshot lo utilizzi | — |
| 12 | segnare `RECLAIMABLE` | — |
| 13 | eliminare | `DELETED` |

Per MERGE: si leggono più segmenti, si produce un solo nuovo segmento, stesso meccanismo
copy-on-write, sorgenti immutabili fino al reclaim.

> **Deciso ([ADR-0040](adr/0040-manifest-a-record-unico.md), [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md))** —
> Corrispondenza con i passi: l'output è scritto come `.tmp` (5–7); il passo 9 è **un record
> EDIT** nel control log che chiude l'output e rimuove i sorgenti, seguito dalla rinomina e
> dalle rilocazioni dell'indice; i passi 10–13 sono stati in memoria del segmento rimosso,
> fino all'eliminazione del file. «Record necessari» sono quelli puntati dall'indice, quelli
> puntati dalle versioni trattenute e i tombstone non ancora scartabili; i record prepared
> committed sono riscritti come record ordinari.

Proprietà di crash-safety (dettagli in [11 Recovery](11-recovery.md)):

- prima del passo 9 un crash non lascia effetti: il file parziale si scarta e l'operazione si
  ripete (INV-C9);
- il nuovo segmento non diventa visibile prima che i suoi dati siano durevoli: il passo 7
  precede sempre il 9 (INV-C7);
- il sorgente resta recuperabile fino al completamento dello swap (INV-C8);
- un passo 9 interrotto DEVE essere riconoscibile in recovery.

> **Deciso (QA-04, QA-24 → [ADR-0018](adr/0018-control-log-manifest-swap.md), [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md))** — Lo «atomic index swap» è il punto più delicato del workflow. Il
> writer della Serie continua a lavorare durante la copia: un documento copiato può essere
> stato aggiornato nel frattempo, e in quel caso l'indice non va toccato per quel documento.
> Il meccanismo di swap e il suo rapporto con il writer logico sono da definire.

## Reader durante la compaction

- I reader continuano a leggere i segmenti vecchi mentre la compaction produce i nuovi.
- La compaction NON DEVE bloccare globalmente le letture (INV-C10).
- Dopo lo swap: i nuovi reader usano il nuovo indice/segmento; i reader già attivi terminano
  sul vecchio.

## Parallelismo e scheduling

La compaction è parallelizzabile **per segmento** e **per Serie**; non esiste un singolo
compaction worker globale, e lo scheduler distribuisce il lavoro dinamicamente.

```
Compaction Scheduler
├── Worker 1 → S017 → S101
├── Worker 2 → S018 → S102
├── Worker 3 → S019 → S103
└── Worker 4 → S020 → S104
```

Il Compaction Scheduler ha **limiti indipendenti** dal request scheduler e DEVE poter:

- aumentare i worker CLEAN quando il sistema è scarico, ridurli quando il traffico aumenta;
- impedire il MERGE durante carico elevato;
- preferire un CLEAN urgente a un MERGE;
- evitare la starvation delle richieste utente.

Priorità (INV-P4):

```
traffico utente  >  WAL/durability  >  CLEAN necessario  >  MERGE opportunistico
```

## Metriche

Segment count e size, live/dead ratio, bytes reclaimed, throughput di CLEAN e MERGE,
compaction concurrency, backlog ([12 Osservabilità](12-osservabilita.md)).
