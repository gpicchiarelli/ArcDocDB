# ADR-0027 — Nessuna dipendenza esterna; harness di test proprio

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-22; applica [ADR-0001](0001-common-lisp-sbcl.md)
- **Riferimenti:** [principi di ingegneria](../principi-di-ingegneria.md)

## Decisione

1. Il sistema `arcdocdb` dipende solo da SBCL e dai suoi contrib (`sb-thread`, `sb-posix`,
   `sb-unix`, `sb-concurrency` dove utile, `sb-simd` su x86-64 quando [ADR-0012](0012-simd-guidato-dai-benchmark.md)
   lo richiederà). Nessuna libreria di terze parti, nemmeno per CBOR, CRC, hash o CLI.
2. I test usano un **harness proprio** (`arcdocdb/tests`): registrazione di test per modulo,
   asserzioni, esecuzione in parallelo dove possibile, e il **runner di fault injection**
   (crash in punti nominati, I/O simulato, oracolo). Un framework esterno non offrirebbe
   quest'ultimo, che è la parte che conta.
3. Gli spike seguono la stessa regola.
4. Strumenti di sviluppo (CI, controllo dei link) sono script Common Lisp eseguiti con
   `sbcl --script`.

## Conseguenze

- Controllo totale sul codice che sta sui percorsi caldi e nel recovery.
- Più codice da scrivere (CBOR, CRC32C, hash, istogrammi): tutto piccolo e tabellare.
- Nessun gestore di pacchetti richiesto per compilare: `sbcl` e ASDF bastano.

## Alternative considerate

- *Quicklisp con poche librerie consolidate:* comodo, ma introduce codice non tipizzato per i
  nostri scopi sui percorsi caldi e un confine di qualità non controllato.
