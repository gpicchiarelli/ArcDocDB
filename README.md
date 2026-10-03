<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/img/arcdocdb-logo-dark.svg">
    <img src="assets/img/arcdocdb-logo.svg" alt="ArcDocDB" width="440">
  </picture>
</p>

<p align="center">
  <strong>A general-purpose document database that never overwrites.</strong><br>
  Append-only storage, one writer per Serie, copy-on-write compaction — in pure Common Lisp.
</p>

<p align="center">
  <a href="https://github.com/gpicchiarelli/ArcDocDB/actions/workflows/ci.yml"><img src="https://github.com/gpicchiarelli/ArcDocDB/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-BSD--2--Clause-3f7a80.svg" alt="License: BSD-2-Clause"></a>
  <a href="docs/adr/0001-common-lisp-sbcl.md"><img src="https://img.shields.io/badge/Common%20Lisp-100%25-3f7a80.svg" alt="100% Common Lisp"></a>
  <a href="https://www.sbcl.org/"><img src="https://img.shields.io/badge/SBCL-2.6%2B-1f3f43.svg" alt="SBCL 2.6+"></a>
  <a href="docs/roadmap.md"><img src="https://img.shields.io/badge/phase-0%20%C2%B7%20architecture-d4a017.svg" alt="Phase 0: architecture"></a>
  <a href="docs/adr/README.md"><img src="https://img.shields.io/badge/ADRs-30-5a9aa0.svg" alt="30 ADRs"></a>
  <a href="docs/invarianti.md"><img src="https://img.shields.io/badge/invariants-42-5a9aa0.svg" alt="42 invariants"></a>
  <a href="docs/questioni-aperte.md"><img src="https://img.shields.io/badge/open%20questions-0-2e7d32.svg" alt="0 open questions"></a>
  <a href="docs/valutazione/piano-spike.md"><img src="https://img.shields.io/badge/spikes-0%2F8-9e9e9e.svg" alt="Spikes 0/8"></a>
  <img src="https://img.shields.io/badge/dependencies-0-2e7d32.svg" alt="Zero dependencies">
  <a href="https://github.com/gpicchiarelli/ArcDocDB/commits/main"><img src="https://img.shields.io/github/last-commit/gpicchiarelli/ArcDocDB.svg?color=3f7a80" alt="Last commit"></a>
  <a href="https://github.com/gpicchiarelli/ArcDocDB/commits/main"><img src="https://img.shields.io/github/commit-activity/m/gpicchiarelli/ArcDocDB.svg?color=3f7a80" alt="Commit activity"></a>
  <a href="CONTRIBUTING.md"><img src="https://img.shields.io/badge/PRs-welcome-3f7a80.svg" alt="PRs welcome"></a>
</p>

<p align="center">
  <a href="#why-arcdocdb">Why</a> ·
  <a href="#how-it-works">How it works</a> ·
  <a href="#design-at-a-glance">Design</a> ·
  <a href="#limits">Limits</a> ·
  <a href="#status">Status</a> ·
  <a href="#quick-start">Quick start</a> ·
  <a href="docs/README.md">Documentation</a>
</p>

<br>

## Why ArcDocDB

Most databases are built to be fast on launch day and unpredictable at the tail. ArcDocDB is
designed backwards from **predictable P99**: a data layout where every write is one sequential
append, every read is a lock-free probe in memory, and background work is strictly
subordinate to user traffic.

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
      Targets are hypotheses. Eight spikes, a protocol model and thirteen crash scenarios
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
| **Primary index** | Swiss-table, single-writer / multi-reader, per-slot seqlock, flat arrays — no Lisp object per entry | [0015](docs/adr/0015-primary-index-swiss-table-swmr.md) |
| **Secondary indexes** | One immutable, fixed-format file per segment (ordered / string / category / bitmap) + in-memory delta for `ACTIVE` | [0026](docs/adr/0026-indici-secondari-segmentati.md) |
| **Durability** | `:async` · `:group` (default) · `:strong`; pipelined group commit — the writer never waits for a flush | [0019](docs/adr/0019-durability-e-group-commit-pipelined.md) |
| **MVCC** | Per-Archivio commit sequence number; snapshot isolation; optional `:serializable` | [0020](docs/adr/0020-csn-snapshot-isolamento.md) |
| **Multi-Serie transactions** | 2PC, presumed abort, no-wait intents, one `multiserie.log` | [0021](docs/adr/0021-2pc-intenti-outcome.md) |
| **Compaction** | CLEAN and MERGE, copy-on-write, swap is a *single log record*, banded by load state | [0018](docs/adr/0018-control-log-manifest-swap.md) · [0023](docs/adr/0023-politiche-di-compaction.md) |
| **Reclamation** | Epoch-based — no per-read shared writes | [0016](docs/adr/0016-epoch-based-reclamation.md) |
| **Cache** | Keyed by immutable location: never stale, never invalidated | [0025](docs/adr/0025-cache-per-location.md) |
| **Memory / GC** | Long-lived specialized arrays, zero allocation on hot paths | [0024](docs/adr/0024-memoria-e-gc.md) |
| **Dependencies** | None. SBCL and its contribs only; own CBOR, CRC32C, hash, test harness | [0027](docs/adr/0027-dipendenze-e-test.md) |

Every pattern is admitted by one rule: *the best known solution for the problem, decided once,
before the code* — see [principi di ingegneria](docs/principi-di-ingegneria.md).

## Limits

| | |
|---|---|
| `_id` | 1–255 bytes |
| Document | up to 16 MiB (default per-Serie cap 4 MiB) |
| Segment | up to 4 GiB (default target 256 MiB) |
| Versions per document | 2⁴⁰ |
| Documents per server | ~1 billion per 64 GB of RAM (primary index lives in memory, ~48 B/entry) |
| Serie per Archivio | thousands out of the box |

Full table, with the origin of each limit: **[docs/limiti.md](docs/limiti.md)**.

## Status

**Phase 0 — architecture and evaluation.** There is no production code yet, by design.

| | |
|---|---|
| ✅ Specification, consolidated architecture, on-disk formats | [specifica](docs/specifica/prompt-originale.md) · [architettura](docs/architettura.md) · [formati](docs/formati-su-disco.md) |
| ✅ 26 open questions closed by 30 ADRs | [ADR](docs/adr/README.md) |
| ✅ Critical evaluation, estimates, risk register | [valutazione](docs/valutazione/README.md) |
| ⏳ Spikes: GC pauses, primary index, concurrent flush, protocol model | [piano](docs/valutazione/piano-spike.md) |
| ⏳ Author sign-off on targets and v1 scope | [ADR-0028](docs/adr/0028-target-e-obiettivi-di-latenza.md) · [ADR-0030](docs/adr/0030-scope-v1.md) |

Performance numbers in the documents are **targets or estimates**, never results
([INV-X2](docs/invarianti.md)). The [roadmap](docs/roadmap.md) lists the exit criteria for
Phase 0 and the ten phases that follow.

## Quick start

Requires SBCL and ASDF (bundled with SBCL). Nothing else.

```bash
git clone https://github.com/gpicchiarelli/ArcDocDB.git
cd ArcDocDB
make check      # smoke tests + documentation link/anchor check
```

## Repository map

| Path | Contents |
|---|---|
| [`docs/`](docs/README.md) | specification, design, evaluation, ADRs, invariants, glossary |
| [`src/`](src) · [`tests/`](tests) | ASDF system (minimal in Phase 0) |
| [`spikes/`](spikes/README.md) | disposable experiments, one folder per spike |
| [`tools/`](tools) | repository tooling, in Common Lisp |

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md) first: decisions go through ADRs, code is written once
in its final form, and everything is Common Lisp.

## License

[BSD 2-Clause](LICENSE) © Giacomo Picchiarelli
