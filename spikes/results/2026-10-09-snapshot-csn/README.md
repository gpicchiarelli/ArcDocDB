# Collegamento snapshot/CSN — 2026-10-09

[Contratto e metodo](../../../docs/implementazione/snapshot-csn.md) registrati
prima dei controlli locali. Il [catalogo](catalogo.lisp) conserva comandi,
ambiente, blob prima/dopo e output originali, anche dei tentativi falliti.

Si compila solo `arcdocdb`, senza caricare `arcdocdb/tests`. Il disassemblato
ispeziona il collegamento e le guardie senza eseguire le funzioni del prodotto;
il suo script viene conservato come testo in un record dati.

Lint, tracciabilità, link e cataloghi sono controlli statici. Nessuna nuova
prova funzionale, concorrente, fault injection, modello, benchmark o
auto-verifica degli strumenti viene aggiunta o eseguita localmente.
Non si estende la qualifica del registro CSN a questo collegamento.
