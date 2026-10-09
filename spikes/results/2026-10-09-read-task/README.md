# Compiti di lettura — 2026-10-09

Campagna di compilazione e ispezione statica del collegamento fra EBR e
snapshot, secondo il [contratto](../../../docs/implementazione/compiti-lettura.md).
Gli output originali e i blob dei sorgenti prima/dopo sono nel
[catalogo](catalogo.lisp). Ogni tentativo eseguito è conservato.

La compilazione carica solo `arcdocdb`, senza `arcdocdb/tests`. Il
disassemblato stampa il codice generato ARM64 delle funzioni di ingresso,
limite, conclusione e cleanup, senza chiamarle. Lo script temporaneo è
conservato come testo in un record dati.

Lint, tracciabilità, collegamenti e cataloghi sono controlli statici;
nessuna auto-verifica degli strumenti viene eseguita. Non sono stati
aggiunti o eseguiti test funzionali, stress, fault injection o benchmark.
Non si dimostrano linearizzabilità, assenza di allocazioni, prestazioni o
qualifica C1. Le prove richieste dal contratto rimangono aperte.
