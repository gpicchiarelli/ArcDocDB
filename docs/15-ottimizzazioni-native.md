# 15 — Ottimizzazioni native e SIMD

> **Fonte:** «SIMD e ottimizzazioni native» della [specifica](specifica/specifica-originale.md),
> emendata da [ADR-0001](adr/0001-common-lisp-sbcl.md).
> **Moduli:** M18 SIMD/Hot Path Optimization Layer.

## Vincolo corrente: solo Common Lisp

**Decisione del 2026-10-01:** per ora il progetto è **solo Common Lisp**. La specifica ammette,
per hot path estremi, il ricorso a C/C++ o Rust tramite funzioni foreign; questa possibilità è
**sospesa** finché non viene riaperta con un nuovo ADR. Tutto il codice del repository,
compresi spike e strumenti di benchmark, è Common Lisp su SBCL.

Restano utilizzabili le estensioni e i contrib di SBCL (thread, primitive atomiche, accesso
alle chiamate di sistema), perché sono Common Lisp sull'implementazione di riferimento.

## Progettare «SIMD-friendly»

Il database DEVE essere progettato per essere SIMD-friendly. In Common Lisp/SBCL questo
significa, nell'ordine:

1. usare strutture dati compatte;
2. usare typed arrays;
3. dichiarare i tipi;
4. minimizzare boxing e allocazioni;
5. favorire accessi sequenziali;
6. profilare;
7. introdurre SIMD **solo sui veri hot path** (INV-X1).

I primi cinque punti sono scelte di *layout dei dati*, e vanno fatte in fase di architettura:
non si recuperano dopo. Gli ultimi due sono attività guidate dalle misure.

SBCL può generare codice SIMD automaticamente in alcuni casi numerici opportunamente tipizzati.

## Scala di intervento

| Livello | Strumento | Stato |
|---|---|---|
| 1 | Common Lisp tipizzato: array specializzati, dichiarazioni, nessuna allocazione | sempre |
| 2 | Operazioni specifiche di SBCL | ammesso, sugli hot path misurati |
| 3 | Funzioni foreign, C/C++, Rust | **sospeso** (solo Common Lisp per ora) |

Si sale di livello solo quando il profiler mostra che il livello precedente non basta.

## Candidati SIMD

- bitmap AND/OR/XOR;
- Bloom filter;
- scansioni;
- confronti;
- filtri;
- parsing;
- hashing;
- compressione/decompressione.

Lo storage append-only con segmenti immutabili e scansioni sequenziali favorisce queste
ottimizzazioni: i dati sono contigui e non cambiano sotto il lettore.

## Questioni decise e rischi

- **QA-18** ([ADR-0024](adr/0024-memoria-e-gc.md)) — Garbage collector e memoria: quali strutture vivono nello heap Lisp e quali
  fuori (RSK-01). È il rischio tecnico principale della scelta di SBCL.
- **QA-19** ([ADR-0017](adr/0017-piattaforma-e-io.md)) — Architettura di riferimento. Il supporto SIMD esplicito di SBCL va verificato
  per architettura (x86-64 e ARM64): lo sviluppo avviene su macOS/ARM64, la piattaforma di
  riferimento è Linux x86-64 (RSK-11).
- Il vincolo «solo Common Lisp» riguarda anche le chiamate di sistema per l'I/O: va verificato
  nello spike sul WAL che `fsync` e le letture posizionali siano raggiungibili senza codice
  non-Lisp e senza allocazioni sul percorso critico (SPK-03, SPK-05).
