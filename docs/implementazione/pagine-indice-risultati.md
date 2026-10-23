# Pagine dell'indice — Verifiche iniziali I2

Campagna avviata il 2026-10-22, aggiornamenti del 2026-10-23; SBCL 2.6.9,
macOS ARM64. Metodo preregistrato nel
[contratto del codec](pagine-indice.md#metodo-preregistrato-e-decisioni-c1).
Le prove funzionali non misurano prestazioni, RSS o capacita' oltre RAM.

L'[archivio dei comandi](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-index-pages-targeted/catalogo.lisp)
conserva output integrali, sorgenti correnti e versioni dei test precedenti
alle correzioni. I record conservano lo stato originale, mai reinterpretato.

| Run | Esito | Interpretazione |
|---|---|---|
| targeted-01 | FAILED, sorgenti stabili | Conflitto del nome helper IDENTITY con COMMON-LISP; rinominato nel package di test. |
| targeted-02 | FAILED, sorgenti stabili | Fixture con home group non conforme alla maschera allineata del primario; corretta la costruzione manuale dei digest. |
| targeted-03 | OK, exit 0, sorgenti stabili | Compilazione rigorosa e 18 test completati. |
| targeted-04 | OK, exit 0, sorgenti stabili | Stessi test dopo aggiunta delle asserzioni sui contratti privati e sulla scrittura dell'header. |
| lint-01 | OK, exit 0, sorgenti stabili | Controlli statici prima delle asserzioni finali; il controllo globale e' distinto. |
| collection-01 | FAILED, sorgenti stabili | Preflight del collettore: percorso assoluto inserito nel path relativo di destinazione. Manifest corretto, originale e rifiuto conservati. |
| full-check-01 | FAILED, sorgenti stabili | Build/test, lint, tracciabilita', link e controlli full text passati. Due casi preesistenti di cleanup delle sessioni nello strumento delle evidenze impediscono la chiusura del controllo globale; nessun test del codec fallito. |
| session-replay-01 | OK, exit 0, sorgenti stabili | Due casi originali ripetuti senza modificare lo strumento; entrambi passati, con condizioni originarie registrate. Nessuna causa definitiva attribuita al fallimento precedente. |
| full-check-02 | FAILED, sorgenti stabili | Build/test, lint e tracciabilita' passati; i link delle copie di conservazione Markdown in out erano interpretati rispetto alla directory delle copie. Estensione rinominata in .md.txt, senza modificare i byte. |

Le fixture indipendenti verificano header e corpo byte per byte con CRC bit
per bit, tre taglie e tre tipi. I test coprono saturazione 7/8 e byte successivo,
collisioni identiche, record v2 ai limiti, identita' estranee e copiate, chiavi
inline con arena esatta, chiavi esterne e frammentazione di 65535 byte in
17/5/2 pagine. Guardie, sorgenti e buffer rifiutati restano invariati.

Una prova altera singolarmente tutti i 4096 byte di una pagina senza aggiornare
i CRC e richiede rifiuto. Casi separati ricalcolano CRC corretti per campi,
PageRef, controlli, packing, padding e geometrie incoerenti. Si distinguono
quindi verifica dei checksum e validazione della struttura locale.

La rappresentazione di una directory da split verifica soltanto pagine e
riferimenti: non attua split del writer o pubblicazione. Nella revisione
successiva ai run mirati i due digest sintetici sono stati collocati anche
nei prefissi 0/1 corrispondenti ai figli; la versione aggiornata ha superato
la fase build/test del primo controllo globale. Non e' ancora un test
differenziale dello split del motore. La diagnosi e la ripetizione del
controllo globale restano registrate separatamente dal primo archivio mirato.

Due letture dello stesso autore: contratto/layout e flusso degli errori con
assenza di effetti prima del preflight. Restano aperti review indipendente,
MC/DC completa, container su file, prove di grafo, cache, snapshot, commit,
recovery e cambi automatici nel runtime. Nessuna proprieta' lock-free o
allocazione zero viene attribuita al codec da queste esecuzioni.

## Chiusura della verifica integrata — 2026-10-23

`full-check-03` ha concluso `make check` con stato OK, exit 0 e sorgenti
stabili: compilazione senza avvisi, suite complete (18 test del codec),
lint, trace, link, controlli full text, strumenti delle evidenze, 307 cataloghi,
11 spike e autoverifica CI. I due casi C4 di sessione sono passati anche nella
suite completa: 48 casi e 756 controlli del relativo strumento.

L'[archivio finale verificato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-index-pages-final/catalogo.lisp)
conserva il comando riuscito, entrambi i run globali falliti, la replica
diagnostica, le fixture interessate e le versioni dei documenti precedenti
agli aggiornamenti. Nessun esito storico e' stato promosso o sovrascritto.
Questa annotazione e' successiva al run globale: codice invariato, soli
metadati finali sottoposti separatamente ai controlli link e trace.
