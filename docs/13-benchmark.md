# 13 — Benchmark

> **Fonte:** «Benchmark», «Target preliminari», «Confronto con Oracle, MySQL e MongoDB» della
> [specifica](specifica/specifica-originale.md).

## Principio

Le prestazioni si **misurano**; non si dichiarano. I numeri di questo documento sono target
architetturali, non risultati (INV-X2).

## Hardware di riferimento

| Risorsa | Valore |
|---|---|
| CPU | 16–32 core |
| RAM | 64–128 GB |
| Storage | NVMe PCIe 4/5 |
| Dataset | abbastanza grande da non essere interamente in cache quando si misura lo storage |
| Documenti | indicativamente 1–4 KB |

Nei confronti con altri sistemi l'hardware DEVE essere identico.

## Workload

| Categoria | Workload |
|---|---|
| Letture puntuali | GET `_id`; GET `_id` con cache hit; GET `_id` con accesso NVMe |
| Scritture | INSERT; UPDATE; DELETE/tombstone |
| Query | indexed query; sequential scan |
| Manutenzione | CLEAN; MERGE |
| Misti | mixed read/write; burst di sole letture; burst di scritture |
| Transazioni | single-Series; multiserie |

> **Deciso ([ADR-0036](adr/0036-leggi-di-progetto.md))** — Poiché il parallelismo è un
> principio fondante (INV-P6), ai workload della specifica se ne aggiungono due che lo
> verificano: **scalabilità** (lo stesso carico distribuito su 1, 2, 4, … Serie e su un numero
> crescente di core: il throughput aggregato deve crescere finché ci sono core e banda del
> dispositivo) e **isolamento** (un burst su una Serie, con latenza e throughput misurati
> sulle altre). Il risultato è una misura, non un target dichiarato in anticipo (INV-X2).

## Che cosa misurare sempre

Throughput; P50, P95, P99; CPU; RAM; cache hit rate; WAL bandwidth; fsync latency; NVMe
bandwidth; queue depth; compaction throughput; numero di worker; contention; GC di SBCL.

## Target preliminari

**Target architetturali indicativi, NON benchmark dimostrati.** Su hardware adeguato:

| Operazione | Target |
|---|---|
| GET `_id`, cache/index | ~1–4 M ops/s aggregati |
| GET `_id`, NVMe | ~150k–600k ops/s |
| INSERT, durability async | ~700k–2 M ops/s |
| INSERT, group commit | ~300k–1 M ops/s |
| UPDATE append-only | ~400k–1,2 M ops/s |
| DELETE/tombstone | ~500k–1,5 M ops/s |
| Query indicizzata semplice | ~500k–2 M ops/s |
| Sequential scan | ~1–5+ GB/s |
| CLEAN | ~0,5–3+ GB/s |
| MERGE | dipende da numero e dimensione dei segmenti, layout, I/O e carico disponibile |
| Transazioni multiserie | da decine a centinaia di migliaia di tx/s, secondo il numero di Serie coinvolte e il costo del commit durevole |

Questi numeri DEVONO essere verificati con benchmark reali. Una prima verifica di plausibilità
rispetto ai limiti fisici dell'hardware è in
[valutazione/stime-ordine-di-grandezza.md](valutazione/stime-ordine-di-grandezza.md).

> **Deciso (QA-26 → [ADR-0028](adr/0028-target-e-obiettivi-di-latenza.md))** — Solo il primo target è dichiarato «aggregato». Per gli altri va chiarito
> se si intendono per singola Serie o sommati su tutte le Serie: la differenza è sostanziale,
> perché ogni Serie ha un solo writer logico.

## Confronto con altri sistemi

NON usare benchmark eterogenei per dichiarare superiorità diretta. Oracle, MySQL/InnoDB e
MongoDB hanno architetture, semantiche, livelli di durability, workload e configurazioni
differenti.

L'**ipotesi architetturale** — da verificare sperimentalmente — è che ArcDocDB possa avere un
percorso particolarmente corto per operazioni document/KV semplici, grazie a: Serie
indipendenti, un writer logico per Serie, primary index in RAM, storage append-only, WAL per
Serie, group commit, segmenti immutabili, cache, parallelismo orizzontale tra Serie.

Un confronto è corretto solo a parità di:

- hardware;
- dataset e dimensione dei documenti;
- indici;
- livello di durability;
- concorrenza;
- workload (equivalente);
- semantica della transazione.

## Riproducibilità

> **Proposta** — Ogni risultato pubblicato nei documenti va accompagnato da: revisione del
> codice, versione di SBCL e parametri di avvio (dimensione heap, GC), hardware e sistema
> operativo, configurazione della Serie (durability, dimensione segmento, indici), generatore
> del dataset con seme, comando esatto. Senza questi dati un numero non entra nella
> documentazione.

## Relazione con la fase di valutazione

I benchmark completi richiedono il sistema implementato. Nella fase di definizione
architetturale si eseguono solo **spike** mirati, che misurano singole ipotesi (indice, GC,
group commit…): vedi il [piano degli spike](valutazione/piano-spike.md).
