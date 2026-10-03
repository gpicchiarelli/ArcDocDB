# 08 — Indici

> **Fonte:** «Index», «Secondary index», «Secondary index delta», «Index snapshot» della
> [specifica](specifica/prompt-originale.md).
> **Moduli:** M05 Primary Index Manager, M06 Secondary Index Manager.
> **Decisioni:** [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md) (primary index Swiss
> SWMR, hint per segmento), [ADR-0026](adr/0026-indici-secondari-segmentati.md) (indici
> secondari **per segmento**, a formato fisso, con delta in memoria per l'ACTIVE). Formati in
> [formati-su-disco.md](formati-su-disco.md#file-indice).

## Primary index

```
_id → location
```

La `location` contiene almeno:

| Campo | Significato |
|---|---|
| `segment-id` | segmento che contiene il record |
| `offset` | posizione nel segmento |
| `length` | lunghezza del record |
| `version` | versione del documento (usata dall'optimistic version checking, [05](05-transazioni.md)) |

Requisiti:

- lookup **O(1) medio**, altamente ottimizzato;
- valutare una struttura tipo **Swiss Table**;
- evitare milioni di oggetti Lisp separati (uno per entry);
- preferire packed arrays, vectors, strutture compatte, metadata binari, memoria contigua.

La specifica colloca il primary index **in RAM** (sezione sul confronto con altri sistemi).
Il vincolo sugli oggetti Lisp non è solo una questione di velocità: milioni di oggetti con
puntatori sono lavoro per il garbage collector, mentre array specializzati non contengono
puntatori da tracciare ([15](15-ottimizzazioni-native.md)).

> **Deciso (QA-03 → [ADR-0015](adr/0015-primary-index-swiss-table-swmr.md))** — Persistenza dell'indice: la directory `index/` della Serie esiste nel
> layout, ma la specifica non dice se contiene un checkpoint del primary index o solo indici
> secondari. La scelta determina il tempo di riavvio.

> **Deciso (QA-01 → [ADR-0014](adr/0014-formato-record-documento-id.md))** — Tipo e lunghezza di `_id` condizionano il formato della tabella (chiavi
> a lunghezza fissa inline oppure hash + verifica).

## Indici secondari

Strutture diverse per tipo di query:

| Tipo di dato / query | Struttura |
|---|---|
| Stringhe, prefix | ART (Adaptive Radix Tree) |
| Numeri, date, range | B+ tree o struttura ordinata equivalente |
| Categorie | posting lists |
| Boolean, bassa cardinalità | bitmap |

**Bloom filter per segmento.** Serve solo a stabilire che un valore è *sicuramente assente*
oppure *potenzialmente presente*. NON DEVE essere usato come struttura di localizzazione
definitiva (INV-I2).

### Modello a delta

Per gli indici secondari soggetti a modifiche frequenti, un modello LSM-like:

```
base index + immutable delta(s)  →  merge asincrono  →  nuova base index
```

Un aggiornamento che sposta il documento 42 da `category="tech"` a `category="sport"` produce:

```
category="tech"  → REMOVE 42
category="sport" → ADD 42
```

La nuova base viene costruita **senza bloccare globalmente i reader**.

## Index snapshot

Gli indici DEVONO essere immutabili per i reader (INV-I1):

```
Reader → Index v17

Writer: costruisce Index v18, atomic swap

nuovi reader      → Index v18
reader precedenti → completano su v17
```

## Questioni decise e rischi

- **QA-24** ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)) — Il modello «versione immutabile + swap» è naturale per gli indici secondari
  (base + delta) e per la rilocazione in blocco fatta dalla compaction. Per il **primary
  index**, che riceve una modifica per ogni scrittura, costruire una nuova versione completa a
  ogni commit non è praticabile: va definito come si concilia l'immutabilità per i reader con
  aggiornamenti continui del writer (RSK-02).
  Risolto con il seqlock per slot e lo scambio atomico della tabella
  ([ADR-0032](adr/0032-seqlock-a-64-bit.md)).
- **QA-25** ([ADR-0026](adr/0026-indici-secondari-segmentati.md)) — Indici secondari: aggiornati in modo sincrono con il commit o in ritardo? Che
  cosa vede uno snapshot? Sono persistiti o ricostruiti al riavvio?
- **QA-03** ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)) — Persistenza e tempo di ricostruzione del primary index (RSK-07).

## Metriche

Hit rate, latenza di lookup, tempo di rebuild ([12 Osservabilità](12-osservabilita.md)).
