# 09 — Cache

> **Fonte:** «Cache», «Cache e snapshot» della [specifica](specifica/prompt-originale.md).
> **Moduli:** M07 Cache Manager.
> **Decisioni:** [ADR-0025](adr/0025-cache-per-location.md) (chiave per location, arena a
> slot, CLOCK per partizione, ri-etichettatura alla rilocazione).

## Politica

- La cache iniziale usa **CLOCK**.
- Se i benchmark mostrano *scan pollution* significativa, valutare **2Q**. Il passaggio è
  quindi subordinato a una misura, non anticipato.
- La cache PUÒ essere **partizionata per Serie**, per impedire che un burst su una singola
  Serie monopolizzi tutta la cache.

## Read path

```
request → Serie → snapshot/index → cache → segment
```

L'indice viene consultato **prima** della cache: la cache è interrogata conoscendo già quale
versione serve.

## Cache e snapshot

La cache DEVE essere consapevole della versione/epoch del dato; un reader non deve ottenere
una versione incompatibile con il proprio snapshot (INV-M3).

> **Deciso ([ADR-0025](adr/0025-cache-per-location.md))** — Indicizzare la cache per **location** (`segment-id`, `offset`) invece che per
> `_id`. Poiché i segmenti chiusi sono immutabili, il contenuto di una location non cambia mai:
> una entry non può diventare «vecchia», non serve invalidazione sugli update e la
> compatibilità con gli snapshot è garantita per costruzione, perché ogni reader arriva alla
> cache con la location della versione che il suo snapshot deve vedere. La rilocazione fatta da
> CLEAN/MERGE cambia le location: le entry in cache vengono ri-etichettate con la nuova
> location, senza perdere calore (RSK-10).

## Questioni decise e rischi

- **QA-17** ([ADR-0025](adr/0025-cache-per-location.md)) — Granularità (documento o blocco), chiave, budget per Serie e criteri di
  ripartizione tra Serie.
- **RSK-10** — Doppia cache con la page cache del sistema operativo, se i segmenti sono letti
  con I/O bufferizzato o `mmap`; perdita di calore dopo la compaction.
- La memoria della cache è soggetta alle stesse considerazioni sul GC degli indici: i payload
  non devono vivere come oggetti gestiti dal collector (QA-18).

## Metriche

Hit/miss, eviction, occupazione per Serie, scan pollution
([12 Osservabilità](12-osservabilita.md)). La metrica di scan pollution è quella che decide
l'eventuale passaggio a 2Q: va definita prima dei benchmark.
