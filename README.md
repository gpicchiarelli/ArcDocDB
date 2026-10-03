<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/img/arcdocdb-logo-dark.svg">
    <img src="assets/img/arcdocdb-logo.svg" alt="ArcDocDB" width="440">
  </picture>
</p>

<p align="center">
  <strong>A general-purpose document database that never overwrites — and never answers wrong in silence.</strong><br>
  Append-only storage, one writer per Serie, every read verified. Engineered as safety-critical software, in pure Common Lisp.
</p>

<p align="center">
  <a href="https://github.com/gpicchiarelli/ArcDocDB/actions/workflows/ci.yml"><img src="https://github.com/gpicchiarelli/ArcDocDB/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-BSD--2--Clause-3f7a80.svg" alt="License: BSD-2-Clause"></a>
  <a href="docs/adr/0001-common-lisp-sbcl.md"><img src="https://img.shields.io/badge/Common%20Lisp-100%25-3f7a80.svg" alt="100% Common Lisp"></a>
  <a href="https://www.sbcl.org/"><img src="https://img.shields.io/badge/SBCL-2.6%2B-1f3f43.svg" alt="SBCL 2.6+"></a>
  <a href="docs/adr/0027-dipendenze-e-test.md"><img src="https://img.shields.io/badge/dependencies-0-2e7d32.svg" alt="Zero dependencies"></a>
  <a href="docs/affidabilita/README.md"><img src="https://img.shields.io/badge/design-safety--critical-b71c1c.svg" alt="Safety-critical design"></a>
</p>

<p align="center">
  <a href="docs/roadmap.md"><img src="https://img.shields.io/badge/phase-0%20%C2%B7%20architecture-d4a017.svg" alt="Phase 0: architecture"></a>
  <a href="docs/adr/README.md"><img src="https://img.shields.io/badge/ADRs-35-5a9aa0.svg" alt="35 ADRs"></a>
  <a href="docs/invarianti.md"><img src="https://img.shields.io/badge/invariants-50-5a9aa0.svg" alt="50 invariants"></a>
  <a href="docs/tracciabilita/matrice.md"><img src="https://img.shields.io/badge/requirements-90%20traced-5a9aa0.svg" alt="90 requirements traced"></a>
  <a href="docs/questioni-aperte.md"><img src="https://img.shields.io/badge/open%20questions-0-2e7d32.svg" alt="0 open questions"></a>
  <a href="docs/valutazione/piano-spike.md"><img src="https://img.shields.io/badge/spikes-0%2F9-9e9e9e.svg" alt="Spikes 0/9"></a>
</p>

<p align="center">
  <a href="#why-arcdocdb">Why</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#design-at-a-glance">Design</a> ·
  <a href="#reliability">Reliability</a> ·
  <a href="#limits">Limits</a> ·
  <a href="#status">Status</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="docs/README.md">Documentation</a>
</p>

<br>

## Why ArcDocDB

A database has one job before all others: give back exactly what was committed, or say
clearly that it cannot. ArcDocDB is engineered like **safety-critical software**: reliability
outranks speed, every requirement is traced to its verification by a tool, and a datum that
cannot be verified is never returned — see [Reliability](#reliability).

Performance follows from the layout rather than from shortcuts: every write is one sequential
append, every read is a lock-free probe in memory, and background work is strictly subordinate
to user traffic.

It is a **document** engine, not a CMS backend: it stores opaque, versioned documents under
a unique `_id`, with schemas, secondary indexes, snapshots and transactions on top.

<table>
  <tr>
    <td width="33%" valign="top">
      <strong>Never overwrites</strong><br>
      Records are appended once. Closed segments are immutable. Crash-safety becomes a
      property of the layout, not of discipline.
    </td>
    <td width="33%" valign="top">
      <strong>One writer per Serie</strong><br>
      The Serie is the unit of storage, parallelism and isolation. Independent Serie write
      in parallel; a burst on one never blocks another.
    </td>
    <td width="33%" valign="top">
      <strong>Readers never wait</strong><br>
      Lock-free index probes, epoch-based reclamation, snapshots that cost nothing until
      someone overwrites what they see.
    </td>
  </tr>
  <tr>
    <td valign="top">
      <strong>Opportunistic maintenance</strong><br>
      CLEAN reclaims space. MERGE only runs on segments stable for 50 s, under low load.
      User traffic always wins.
    </td>
    <td valign="top">
      <strong>Transactions that scale out</strong><br>
      Single-Serie commits touch one log. Multi-Serie commits use a 2PC with one decision
      log and a writer that never blocks.
    </td>
    <td valign="top">
      <strong>Designed to be measured</strong><br>
      Targets are hypotheses. Nine spikes, a protocol model and thirteen crash scenarios
      decide what survives.
    </td>
  </tr>
</table>

## How it works

```
Server
└── Archivio                      CSN · snapshots · multi-Serie coordinator
    ├── Registri                  the catalog is itself a Serie · multiserie.log
    └── Serie                     one writer · own log, segments, indexes
        └── Documento             opaque CBOR under a unique _id
```

```
 write ─▶ queue ─▶ writer ─▶ ACTIVE segment ──rotate──▶ CLOSED (immutable) ──▶ CLEAN / MERGE
                       │                                     │
                       ▼                                     ▼
                  primary index (RAM)                 per-segment hint, indexes, Bloom
                       ▲
 read  ─▶ lock-free probe ─▶ cache by location ─▶ pread ─▶ segment
```

The full design is a single document: **[docs/architettura.md](docs/architettura.md)**.

## Design at a glance

| Area | Decision | ADR |
|---|---|---|
| **Storage** | Log-structured: the `ACTIVE` segment *is* the data log — each record written once, CRC32C-protected | [0013](docs/adr/0013-log-structured-segmento-active-come-log.md) |
| **Primary index** | Swiss-table, single-writer / multi-reader, 64-bit per-slot seqlock with bounded retries, flat arrays — no Lisp object per entry | [0015](docs/adr/0015-primary-index-swiss-table-swmr.md) · [0032](docs/adr/0032-seqlock-a-64-bit.md) |
| **Secondary indexes** | One immutable, fixed-format file per segment (ordered / string / category / bitmap) + in-memory delta for `ACTIVE` | [0026](docs/adr/0026-indici-secondari-segmentati.md) |
| **Durability** | `:async` · `:group` (default) · `:strong`; pipelined group commit — the writer never waits for a flush | [0019](docs/adr/0019-durability-e-group-commit-pipelined.md) |
| **MVCC** | Per-Archivio commit sequence number; snapshot isolation; optional `:serializable` | [0020](docs/adr/0020-csn-snapshot-isolamento.md) |
| **Multi-Serie transactions** | 2PC, presumed abort, no-wait intents, one `multiserie.log` | [0021](docs/adr/0021-2pc-intenti-outcome.md) |
| **Compaction** | CLEAN and MERGE, copy-on-write, swap is a *single log record*, banded by load state | [0018](docs/adr/0018-control-log-manifest-swap.md) · [0023](docs/adr/0023-politiche-di-compaction.md) |
| **Reclamation** | Epoch-based — no per-read shared writes | [0016](docs/adr/0016-epoch-based-reclamation.md) |
| **Cache** | Keyed by immutable location: never stale, never invalidated | [0025](docs/adr/0025-cache-per-location.md) |
| **Memory / GC** | Long-lived specialized arrays, zero allocation on hot paths | [0024](docs/adr/0024-memoria-e-gc.md) |
| **Integrity** | End-to-end CRC32C on every read (disk *and* cache), fail-stop on any write/flush error, scrubbing, offline verifier | [0033](docs/adr/0033-fail-stop-e-integrita-end-to-end.md) |
| **Code policy** | `safety` ≥ 2 always, zero compiler warnings, banned constructs checked by a linter | [0034](docs/adr/0034-policy-di-compilazione-e-standard-di-codifica.md) |
| **Verification** | Deterministic simulation, exhaustively explored protocol models, fault injection, differential testing, fuzzing, mutation testing | [0035](docs/adr/0035-strategia-di-verifica-e-tracciabilita.md) |
| **Dependencies** | None. SBCL and its contribs only; own CBOR, CRC32C, hash, test harness | [0027](docs/adr/0027-dipendenze-e-test.md) |

Every pattern is admitted by one rule: *the best known solution for the problem, decided once,
before the code* — see [principi di ingegneria](docs/principi-di-ingegneria.md).

## Reliability

Priorities, in order ([ADR-0031](docs/adr/0031-software-critico-criteri-e-priorita.md)):
**committed data integrity → functional correctness → defined behaviour under faults →
verifiability → availability → performance.** A lower priority never weakens a higher one.

| What the design guarantees | How it is checked |
|---|---|
| No committed datum is lost or corrupted **without being detected and declared** | fault injection FI-01…FI-13, model of the protocols, offline verifier |
| No silent wrong answer: unverified data never leaves the engine | verify-on-read, corruption testing, fuzzing |
| Every fault in the [fault model](docs/affidabilita/analisi-dei-guasti.md) has a defined, tested response | 24-entry FMEA, each traced to a test |
| Every requirement traces to a verification | [matrix](docs/tracciabilita/matrice.md), generated and checked by `make trace` |

**What it cannot promise**, stated up front: survival of the loss of every copy of the data
(hence backup in v1), a kernel or firmware that lies about a flush, defects in the compiler or
runtime (made *detectable*, not impossible), and protection from an adversary. See the
[assurance case](docs/affidabilita/README.md).

## Limits

| | |
|---|---|
| `_id` | 1–255 bytes |
| Document | up to 16 MiB (default per-Serie cap 4 MiB) |
| Segment | up to 4 GiB (default target 256 MiB) |
| Versions per document | 2⁴⁰ |
| Documents per server | ~750 million per 64 GB of RAM, ~1.5 billion per 128 GB (primary index lives in memory, ~56 B/entry + key) |
| Serie per Archivio | thousands out of the box |

Full table, with the origin of each limit: **[docs/limiti.md](docs/limiti.md)**.

## Status

**Phase 0 — architecture and evaluation.** There is no production code yet, by design.

| | |
|---|---|
| ✅ Specification, consolidated architecture, on-disk formats | [specifica](docs/specifica/prompt-originale.md) · [architettura](docs/architettura.md) · [formati](docs/formati-su-disco.md) |
| ✅ 26 open questions closed; safety-critical criteria adopted — 35 ADRs | [ADR](docs/adr/README.md) |
| ✅ Fault model (FMEA), coding standard, verification plan, 90 traced requirements | [affidabilità](docs/affidabilita/README.md) · [tracciabilità](docs/tracciabilita/README.md) |
| ✅ Critical evaluation, estimates, risk register | [valutazione](docs/valutazione/README.md) |
| ⏳ Spikes: GC pauses, primary index, concurrent flush, protocol model, cost of the integrity checks | [piano](docs/valutazione/piano-spike.md) |
| ⏳ Author sign-off on targets and v1 scope | [ADR-0028](docs/adr/0028-target-e-obiettivi-di-latenza.md) · [ADR-0030](docs/adr/0030-scope-v1.md) |

Performance numbers in the documents are **targets or estimates**, never results
([INV-X2](docs/invarianti.md)). The [roadmap](docs/roadmap.md) lists the exit criteria for
Phase 0 and the ten phases that follow.

## Quick start

The documentation is written in Italian; this page and the code are in English and Lisp.

Requires SBCL and ASDF (bundled with SBCL). Nothing else.

```bash
git clone https://github.com/gpicchiarelli/ArcDocDB.git
cd ArcDocDB
make check      # strict build + tests, linter (+ self-test), traceability, doc links
```

## Repository map

| Path | Contents |
|---|---|
| [`docs/`](docs/README.md) | specification, design, evaluation, ADRs, invariants, glossary |
| [`src/`](src) · [`tests/`](tests) | ASDF system (minimal in Phase 0) |
| [`spikes/`](spikes/README.md) | disposable experiments, one folder per spike |
| [`tools/`](tools) | strict build, linter, traceability and link checkers — all Common Lisp |
| [`assets/`](assets/README.md) | logo, palette, hero image brief |

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) first: decisions go through ADRs, code is written once
in its final form, and everything is Common Lisp.

## License

[BSD 2-Clause](LICENSE) © Giacomo Picchiarelli
