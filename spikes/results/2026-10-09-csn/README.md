# Registro CSN — compilazione e controlli statici

Il [catalogo](catalogo.lisp) conserva due compilazioni del solo prodotto e i
controlli statici iniziali/finali. I record contengono comando, ambiente,
identità dei sorgenti prima/dopo, esito e output originale. I file sono copie
integrali dei record prodotti da `tools/record-command.lisp`.

La compilazione finale usa SBCL 2.6.9 e tratta gli avvisi come errori.
Sono riusciti anche linter, tracciabilità, collegamenti e controllo strutturale
dei cataloghi. Quest'ultimo verifica presenza e leggibilità degli artefatti,
senza qualificare il risultato descritto al loro interno.

Non sono stati aggiunti o eseguiti test funzionali, prove concorrenti,
fault injection, copertura, mutazione o benchmark di questo modulo. Non si
attribuiscono al registro prestazioni misurate o una qualifica C1. Contratti,
precondizioni e lavoro residuo sono nella
[documentazione del modulo](../../../docs/implementazione/orizzonte-csn.md).
