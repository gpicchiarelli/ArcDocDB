# Toolchain CI

> **Proposta** — Toolchain candidata per queste verifiche: SBCL 2.6.9.
> La versione è controllata su ogni runner; non è una qualifica generale del
> compilatore o del database.

La [CI](../../workflows/ci.yml) usa questa [azione locale](action.yml) per tutti
i job. Linux x86-64 installa il binario della [distribuzione ufficiale
SBCL](https://www.sbcl.org/platform-table.html), controllando il digest SHA256
fissato nell'azione prima dell'estrazione. macOS aggiorna l'indice Homebrew,
installa il pacchetto e
rifiuta una versione differente: un aggiornamento della formula richiede
aggiornare deliberatamente questa configurazione e ripetere le prove.

La precedente CI Linux installava SBCL 2.2.9: SPK-02 non compilava perché
`SB-EXT:*GC-REAL-TIME*` era assente. Il [record originale del
fallimento](../../../spikes/results/2026-10-08-wal/ci-linux-precedente.lisp)
resta conservato. Il contatore, le prove dello spike e i controlli del motore
mantengono i propri contratti; non si sostituisce il tempo reale con il tempo CPU.

La versione e il checksum sono parametri espliciti e coordinati. Un digest,
una versione o un'architettura Linux discordanti fanno fallire il setup.
L'esecuzione completa dei job resta la prova dell'installazione sui runner.
