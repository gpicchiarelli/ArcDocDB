# ArcDocDB

Database server **documentale general-purpose**, append-only, scritto in **Common Lisp** (SBCL
come implementazione di riferimento).

Gerarchia: `Server → Archivio → Serie → Documento`. La **Serie** è l'unità di storage e di
parallelismo: WAL, segmenti e indici propri, un writer logico e molti reader. Le transazioni
locali usano il WAL della Serie; quelle multiserie un protocollo 2PC-like con un unico
`Registri/multiserie.log` per Archivio. La compaction è copy-on-write (CLEAN per lo spazio,
MERGE opportunistico per la frammentazione) e non blocca le letture.

## Stato del progetto

**Fase 0 — definizione architetturale e valutazione.** Non esiste ancora codice di
produzione. Il repository contiene:

- la [specifica](docs/specifica/prompt-originale.md), fonte di verità;
- la [documentazione](docs/README.md) derivata: modello logico, storage, WAL, transazioni,
  MVCC, compaction, indici, cache, scheduling, recovery, osservabilità, benchmark, fault
  injection, moduli;
- gli [invarianti](docs/invarianti.md) e le [questioni aperte](docs/questioni-aperte.md);
- la [valutazione architetturale](docs/valutazione/README.md): analisi critica, stime,
  registro dei rischi, piano degli spike;
- gli [ADR](docs/adr/README.md);
- la [roadmap](docs/roadmap.md);
- il sistema ASDF minimo e la cartella [`spikes/`](spikes/README.md) per gli esperimenti.

Il progetto è **solo Common Lisp** ([ADR-0001](docs/adr/0001-common-lisp-sbcl.md)).

## Da dove cominciare

1. [docs/README.md](docs/README.md) — indice e convenzioni.
2. [Visione e obiettivi](docs/01-visione-e-obiettivi.md).
3. [Valutazione architetturale](docs/valutazione/README.md) — sintesi, rischi, prossimi passi.

## Caricare il sistema

Richiede SBCL e ASDF (incluso in SBCL).

```bash
sbcl --non-interactive --eval '(asdf:load-asd (merge-pathnames "arcdocdb.asd" (uiop:getcwd)))' --eval '(asdf:test-system "arcdocdb")'
```

## Licenza

BSD 2-Clause. Vedi [LICENSE](LICENSE).
