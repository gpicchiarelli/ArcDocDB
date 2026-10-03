# Spike

Esperimenti della fase di valutazione. Il piano, con domande, metodi e criteri di esito, è in
[docs/valutazione/piano-spike.md](../docs/valutazione/piano-spike.md).

## Regole

- Codice **solo Common Lisp** su SBCL ([ADR-0001](../docs/adr/0001-common-lisp-sbcl.md)).
- Uno spike è codice usa-e-getta: non viene promosso a codice di produzione; al più ne ispira
  il progetto.
- Una cartella per spike: `spikes/SPK-nn-nome/`, con:
  - `README.md` — domanda, metodo, ambiente (hardware, sistema operativo, versione e parametri
    di SBCL), comando esatto, risultati, raccomandazione;
  - il codice e un modo per eseguirlo da riga di comando;
  - dati e output generati in `data/` e `out/` (ignorati da git).
- Al termine si aggiornano [registro dei rischi](../docs/valutazione/registro-rischi.md),
  [stime](../docs/valutazione/stime-ordine-di-grandezza.md) e la questione aperta collegata.

## Stato

| Spike | Stato |
|---|---|
| SPK-01 Primary index compatto | da avviare |
| SPK-02 GC di SBCL sotto carico | da avviare |
| SPK-03 WAL e group commit | da avviare |
| SPK-04 Writer logico su thread pool | da avviare |
| SPK-05 Percorso di lettura dei segmenti | da avviare |
| SPK-06 Interferenza della compaction e controllore | da avviare |
| SPK-07 Modelli dei protocolli | da avviare |
| SPK-08 SIMD e codice generato | da avviare |
| SPK-09 Costo dei controlli di affidabilità | da avviare |
