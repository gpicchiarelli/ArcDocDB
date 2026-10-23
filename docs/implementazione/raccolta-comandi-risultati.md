# Verifica della raccolta degli archivi di comandi

Il collector C4 usa un manifest esplicito, quattro worker e il checker
indipendente dell'inventario chiuso. Il [contratto](raccolta-comandi.md)
descrive ingressi, output e limiti; questa campagna verifica lo strumento,
senza qualificare il motore.

## Versioni e tentativi conservati

La prima esecuzione su `82100f5a` ha trovato un difetto nell'API:
i test passavano pathname validi, mentre l'ingresso richiedeva stringhe.
Self-test e controllo completo sono terminati FAILED, con exit 1 e 2.
Entrambi hanno conservato 59 casi, 984 controlli e 48 casi falliti;
le copie del collector non erano ancora iniziate.

La correzione su `6d47d2df` normalizza soltanto manifest, destinazione e
osservazioni all'ingresso dell'API. I campi del manifest restano stringhe.
Il corpus dei 59 casi è rimasto invariato. La ripetizione esplicita e quella
in `make check-core` hanno superato tutti i casi, con 2.807 controlli ciascuna.

| File | Blob Git |
|---|---|
| Collector iniziale | `48c4e1a23390a43767a3630d66514d9c03a79159` |
| Collector corretto | `d2eb1bd8a62b0fd98ec023243b2a768c19988dc7` |
| Self-test invariato | `49da390b7e170acc9ffdafa78285f215aec75f44` |

Le letture statiche hanno corretto la diagnosi della label vuota, il
collegamento dei payload accessori e il template della directory del
self-test. Le preparazioni sintattiche fallite sono conservate; le note
distinguono i diagnostici rimasti nella conversazione dai log fisici.

## Esiti dello strumento

Il caso principale conserva quattro processi storici distinti: OK,
FAILED con exit NIL, SOURCE-CHANGED e FAILED con exit 7. Il risultato
contiene nove file indicizzati e undici file effettivi, inclusi indice
e catalogo. Quattro thread distinti eseguono copie; i conteggi osservati
sono 3, 2, 2, 2. Il chiamante non esegue le copie.

Il secondo caso compresso mantiene il descriptor come accessorio, senza
inserirlo tra i processi: nove file, tre processi e conteggi 3, 2, 3, 1.
Sono stati confrontati integralmente i byte di diciotto copie dei due
casi, oltre alle due destinazioni ai limiti esatti di dimensione.
Le fixture verificano immutabilità degli ingressi, copie binarie e nomi
nascosti, metadati originali e assenza di inclusioni implicite.

I rifiuti comprendono manifest malformati, chiavi duplicate, percorsi
non relativi, nomi riservati, collisioni file/directory, record incompleti,
metadati incoerenti, symlink finali, destinazioni esistenti, output
sovrapposti, payload mancanti o spostati, hash errati e budget superati.
READ-EVAL resta NIL ed è richiesta una sola forma fino all'EOF.

L'alterazione di una copia viene rilevata come COPIED-BYTES e il cambio
della fonte come SOURCE-CHANGED. Un file nascosto aggiunto nella radice
provoca CLOSED-CHECK: il checker figlio rileva INVENTORY. Log e rapporto
fallito restano esterni, con copie parziali conservate.

## Integrazione e lettura indipendente

Su `6d47d2df`, `make check-core` ha superato 1.651 test nominati,
due smoke, quattro fixture del linter e i 59 casi del collector.
Sono distinti i test del prodotto dai controlli C4 del linter.

Lint: 237 file e zero violazioni. Tracciabilità: 122 requisiti, 65
invarianti, 13 scenari FI e 52 ADR, senza errori. Link: 476 file,
3.199 collegamenti e zero rotti. Le evidenze comprendono 123 cataloghi,
3.565 riferimenti e 42.702 file conservati. I dieci spike sono stati
eseguiti soltanto in modalità `--check`.

La lettura DATA indipendente ha superato 1.694 verifiche su 251 file
fisici, con hash e metadati prima/dopo stabili. Verifica i due wrapper
riusciti, i due falliti, le copie, i quattro worker, i metadati storici e
il checker finale. I wrapper hanno osservato 972 sorgenti stabili.
Il primo lettore non riconosceva i nomi dei test nel formato stampato;
il tentativo fallito e la variante corretta sono conservati.

## Conservazione

L'[archivio principale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-command-archive-collector/archive-index.lisp)
contiene 454 file elencati dal manifest e le due copie automatiche del
manifest e del collector: 456 file indicizzati, 458 effettivi, 2.189.674
byte indicizzati e sei processi, tre OK e tre FAILED. Il checker finale
ha verificato l'inventario chiuso dopo la scrittura dell'indice e del
catalogo.

Il [supplemento](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-command-archive-collector-final/archive-index.lisp)
conserva i record conclusi della preparazione e della raccolta principale,
compreso il risultato del checker: due processi, 53 file indicizzati e
55 effettivi. Anche il supplemento ha superato il checker finale.
Nessun append modifica i due archivi dopo la rispettiva verifica.

Il riepilogo del preparatore iniziale riportava 46 file perché SORT
riordinava la lista e il conteggio successivo partiva dal vecchio head.
Il manifest serializzato conteneva tutti i 454 file: il piano del collector
e l'inventario ne confermano la presenza. Il preparatore usato per il
supplemento ordina una copia della lista; sorgente e rapporto iniziali
rimangono conservati senza modifiche.

Le fixture complete, incluse quelle deliberatamente oltre budget, restano
nel backup locale delle prove. L'archivio pubblicato seleziona rapporti e
log dei casi: non contiene tutte le directory di input e gli archivi
parziali. Il manifest esplicita ogni file selezionato.

La riuscita della raccolta attesta copie e inventario, non promuove i
comandi falliti. Nessuna misura di throughput, speedup, atomicità durevole
o qualifica C1/MC/DC è derivata da questa campagna.

