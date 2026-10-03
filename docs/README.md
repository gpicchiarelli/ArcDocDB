<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="../assets/img/mark-dark.svg">
    <img src="../assets/img/mark-light.svg" alt="" width="48" height="48">
  </picture>
</p>

# Documentazione di ArcDocDB

Questa cartella trasforma la [specifica originale](specifica/prompt-originale.md) in documenti
tematici navigabili, con tracciabilità verso il testo di partenza, e la sottopone a una
[valutazione architetturale](valutazione/README.md).

**Fase corrente:** definizione architetturale e valutazione ([roadmap](roadmap.md)). La
definizione è completa: il progetto consolidato è in [architettura.md](architettura.md), i
formati persistenti in [formati-su-disco.md](formati-su-disco.md), le decisioni negli
[ADR](adr/README.md). Restano gli [spike](valutazione/piano-spike.md) di verifica.

## Come leggere

Ordine consigliato per chi arriva per la prima volta:

1. [Visione e obiettivi](01-visione-e-obiettivi.md) — che cosa si costruisce e perché.
2. [Modello logico](02-modello-logico.md) — Server, Archivio, Serie, Documento, Registri.
3. [Invarianti](invarianti.md) — le regole che nessuna implementazione può violare.
4. I documenti di sottosistema (tabella sotto), nell'ordine che serve.
   Per l'approccio da software critico: [affidabilità](affidabilita/README.md).
5. [Valutazione architetturale](valutazione/README.md) — che cosa regge, che cosa è
   rischioso, come lo si verifica.
6. [Questioni aperte](questioni-aperte.md) — ciò che la specifica non decide ancora.
7. [Roadmap](roadmap.md) — fase corrente e fasi successive.

## Mappa dei documenti

| Documento | Contenuto | Sezioni della specifica coperte |
|---|---|---|
| [01 Visione e obiettivi](01-visione-e-obiettivi.md) | Scopo, obiettivi, non-obiettivi | Introduzione, Obiettivo finale |
| [02 Modello logico](02-modello-logico.md) | Gerarchia, Registri, catalogo, layout fisico | Architettura logica, Serie speciale Registri, Catalogo, Layout fisico |
| [03 Storage](03-storage.md) | Append-only, segmenti, stati, metadata, versioni | Storage append-only, Segmenti, Segment metadata, Versioni dei record |
| [04 WAL e durability](04-wal-e-durability.md) | WAL per Serie, group commit | WAL |
| [05 Transazioni](05-transazioni.md) | Single-Series (OCC), multiserie (2PC), `multiserie.log` | Transazioni single-series, Transazioni multiserie |
| [06 MVCC e snapshot](06-mvcc-e-snapshot.md) | Snapshot logici, visibilità, reclaim | Snapshot/MVCC, Index/Snapshot/Reclaim, Cache e snapshot |
| [07 Compaction](07-compaction.md) | CLEAN, MERGE, regola 50 s + basso carico, workflow | Clean, Merge, Condizioni obbligatorie per Merge, Low-load merge policy, Politica generale, Compaction parallela, Workflow, Readers durante compaction, Compaction scheduler dinamico |
| [08 Indici](08-indici.md) | Primary index, indici secondari, delta, index snapshot | Index, Secondary index, Secondary index delta, Index snapshot |
| [09 Cache](09-cache.md) | CLOCK, partizionamento, read path | Cache, Cache e snapshot |
| [10 Concorrenza e scheduling](10-concorrenza-e-scheduling.md) | Writer logico, thread pool dinamico, priorità | Concorrenza, Thread pool dinamico, Parallelismo |
| [11 Recovery](11-recovery.md) | Procedura di ripartenza, crash-safety | Recovery |
| [12 Osservabilità](12-osservabilita.md) | Metriche | Osservabilità |
| [13 Benchmark](13-benchmark.md) | Metodologia, workload, target, confronti | Benchmark, Target preliminari, Confronto con Oracle/MySQL/MongoDB |
| [14 Fault injection](14-fault-injection.md) | Scenari di crash e invarianti verificati | Fault injection |
| [15 Ottimizzazioni native](15-ottimizzazioni-native.md) | SBCL, SIMD, FFI | SIMD e ottimizzazioni native |
| [16 Moduli](16-moduli.md) | I 18 moduli, package, dipendenze, mappa del codice | Moduli software |

Progetto consolidato:

| Documento | Contenuto |
|---|---|
| [Architettura](architettura.md) | Il progetto completo in un documento: strutture, percorsi di lettura e scrittura, transazioni, compaction, recovery, contratti tra moduli |
| [Formati su disco](formati-su-disco.md) | Segmento, record, hint, indici, Bloom, control log, `multiserie.log`, catalogo |
| [Limiti dimensionali](limiti.md) | Limiti hard dai formati e limiti pratici dall'hardware |
| [Principi di ingegneria](principi-di-ingegneria.md) | Criterio di ammissione dei pattern; si scrive una volta sola |
| [Affidabilità](affidabilita/README.md) | Software critico: caso di affidabilità, analisi dei guasti (FMEA), standard di codifica, piano di verifica, deviazioni |
| [Tracciabilità](tracciabilita/README.md) | Requisiti `REQ-…`, matrice generata e controllata da `make trace` |

Documenti trasversali:

| Documento | Contenuto |
|---|---|
| [Invarianti](invarianti.md) | Elenco numerato (`INV-…`) delle regole inviolabili, con fonte e test che le verificano |
| [Glossario](glossario.md) | Termini di dominio e convenzione linguistica |
| [Questioni aperte](questioni-aperte.md) | Elenco numerato (`QA-…`) dei punti non decisi dalla specifica |
| [Roadmap](roadmap.md) | Fase 0 (definizione e valutazione) con criteri di uscita; fasi successive |
| [ADR](adr/README.md) | Registro delle decisioni architetturali |

Valutazione architetturale ([valutazione/](valutazione/README.md)):

| Documento | Contenuto |
|---|---|
| [Analisi critica](valutazione/analisi-critica.md) | Punti di forza, tensioni interne alla specifica, lacune, confronto con architetture note |
| [Stime di ordine di grandezza](valutazione/stime-ordine-di-grandezza.md) | Plausibilità dei target rispetto ai limiti dell'hardware |
| [Registro dei rischi](valutazione/registro-rischi.md) | Rischi `RSK-…` con mitigazioni e verifiche |
| [Piano degli spike](valutazione/piano-spike.md) | Esperimenti `SPK-…` della Fase 0 |

## Convenzioni

**Livelli di autorità.** In caso di conflitto prevale, nell'ordine:

1. la [specifica originale](specifica/prompt-originale.md);
2. gli [ADR](adr/README.md) accettati (che possono emendare la specifica, dichiarandolo);
3. gli [invarianti](invarianti.md);
4. i documenti tematici.

**Che cosa è specifica e che cosa no.** Nei documenti tematici il testo corrente riporta ciò che
la specifica prescrive. Tutto il resto è marcato esplicitamente:

> **Proposta** — interpretazione o scelta di progetto non presente nella specifica. Va
> confermata; finché non lo è, non vincola l'implementazione.

> **Deciso (QA-nn → ADR-nnnn)** — punto che la specifica non decideva, chiuso dall'ADR
> indicato. Il testo che segue descrive la questione; la decisione è nell'ADR.

> **Aperto (QA-nn)** — punto non ancora deciso; rimanda a
> [questioni-aperte.md](questioni-aperte.md). Oggi non ce ne sono.

**Parole normative.** DEVE / NON DEVE indicano requisiti; DOVREBBE una forte preferenza; PUÒ
una facoltà.

**Identificativi.** `INV-…` invarianti, `QA-…` questioni aperte, `FI-…` scenari di fault
injection, `M01…M18` moduli, `ADR-…` decisioni, `RSK-…` rischi, `SPK-…` spike. Gli
identificativi sono stabili: non si rinumerano, si ritirano. Aggiunti da ADR-0031: `REQ-…`
requisiti ([tracciabilità](tracciabilita/README.md)), `FM-…` modi di guasto, `COD-…` regole di
codifica, `DEV-…` deviazioni, `COV-…` eccezioni di copertura.

**Lingua.** Documentazione in italiano. I termini di dominio (Archivio, Serie, Documento,
Registri, `multiserie.log`) restano in italiano anche nel codice; i termini tecnici consolidati
(WAL, segment, snapshot, commit…) restano in inglese. Dettagli nel [glossario](glossario.md).

## Come si mantiene

- Un cambio di requisito parte dalla specifica (o da un ADR che la emenda), poi si propaga a
  invarianti e documenti tematici nello stesso commit.
- Una questione aperta si chiude con un ADR; la voce in `questioni-aperte.md` viene marcata
  «Risolta da ADR-nnnn» e non cancellata.
- I numeri di prestazione entrano nei documenti solo se prodotti da benchmark riproducibili
  (vedi [13 Benchmark](13-benchmark.md)); altrimenti sono dichiarati come target.
