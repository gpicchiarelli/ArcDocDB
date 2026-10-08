# Spike

[Progetto](../README.md) · [Documentazione](../docs/README.md) · [Piano degli spike](../docs/valutazione/piano-spike.md)

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

Dal 2026-10-08 sono disponibili esperimenti eseguibili per i cinque spike prioritari.
`make spikes-check` compila senza avvisi ed esegue la correttezza in processi isolati;
`make spikes-bench` esegue le misure **in serie** e registra ambiente, comandi e output
in `spikes/out/`. Gli esiti non promuovono automaticamente i requisiti del motore.

| Spike | Stato |
|---|---|
| [SPK-01 Primary index compatto](SPK-01-primary-index/README.md) | prototipo e verifica locale; scala 10⁷–10⁸ e piattaforma di riferimento da eseguire |
| [SPK-02 GC di SBCL sotto carico](SPK-02-gc/README.md) | campagna locale; heap da decine di GB e piattaforma di riferimento da eseguire |
| [SPK-03 WAL e group commit](SPK-03-group-commit/README.md) | append/flush reali e verifica locale; hardware di riferimento e power cut da eseguire |
| SPK-04 Writer logico su thread pool | da avviare |
| SPK-05 Percorso di lettura dei segmenti | da avviare |
| SPK-06 Interferenza della compaction e controllore | da avviare |
| [SPK-07 Modelli dei protocolli](SPK-07-protocols/README.md) | prima suite finita, controesempio corretto da ADR-0046; lacune residue esplicite |
| SPK-08 SIMD e codice generato | da avviare |
| [SPK-09 Costo dei controlli di affidabilità](SPK-09-integrity/README.md) | CRC/decoder verificati e benchmark locale; resolver del manifest e motore da implementare |
