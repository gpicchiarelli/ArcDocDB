# Rapporti CI nei processi isolati

Metodo preregistrato il 2026-10-17, prima della correzione.
Il run GitHub 39028943515 ha verifiche ordinarie riuscite, ma coverage fallita
leggendo `verify-linux/result.lisp`: nel processo fresco mancano keyword
prodotte da altri moduli. Il vocabolario trusted deve includere SKIPPED,
METRICS-STATUS ed EXECUTION senza dipendere dai moduli già caricati.

La correzione estende soltanto l'elenco finito di keyword del wire C4.
Il parser conserva FIND-SYMBOL, i limiti e il rifiuto dei token non noti;
nessun INTERN su ingresso o caricamento del prodotto come rimedio.

Regressioni: un nuovo SBCL carica solo DATA e legge/riscrive il rapporto
canonico rappresentativo byte per byte; un altro rifiuta una keyword
sconosciuta costruita senza INTERN. Entrambi conservano argv, exit code,
stdout/stderr e file d'ingresso, con timeout e cleanup limitati. Prima
la regressione positiva deve fallire; dopo la correzione devono riuscire
anche replay dell'originale Linux, self-test CI e verifica Linux reale.

Il job seal del run originale ha conservato la raccolta chiusa, incompleta
e fallita: il suo exit non zero è coerente con coverage assente. Questa
semantica resta invariata; nessuna riclassificazione dei run storici.

REQ-VAL-001, REQ-AFF-012. Percorso C4, nessun codice di prodotto modificato.

## Budget del riepilogo di copertura

Secondo controllo preregistrato prima della correzione del producer. Il
riepilogo storico misura 26.473 byte. La prima fixture con le 349 righe
EXPECTED-FILES originali occupa 68.380 caratteri, includendo metadati del
publisher che non appartengono a seal. Il ricalcolo del 2026-10-22 elimina
questi metadati e rappresenta gli esiti positivi: la fixture sealed con
le sole righe attese occupa 68.009 byte, oltre i 65.536 ammessi. Entrambe
le fixture sono conservate; non sono misure di copertura e non modificano
il run storico fallito.

Il riepilogo compatto deve contenere il conteggio dei file attesi; il piano
e il rapporto raw conservano tutte le righe originali. La regressione usa
600 file, impacchetta un risultato sealed entro il limite e rilegge il raw
compresso confrontandolo con l'originale. Verifica separatamente che una
prova ordinaria mancante resti incompleta dopo la compattazione. Prima
il caso di impacchettamento deve fallire; dopo entrambi devono passare.
Nessun aumento dei budget e nessun cambiamento degli esiti seal.

## Risultati locali e conservazione

Prove del 2026-10-17 su SBCL 2.6.9, macOS ARM64, con carico esterno non
controllato. Nessuna inferenza sulle prestazioni del motore.

| Revisione | Prova | Esito |
|---|---|---|
| `a8226c10` | Self-test prima del vocabolario completo | 328/329; fallisce solo la lettura nel processo fresco |
| `fb81a7e7` | Self-test dopo il vocabolario completo | 329/329 |
| `fb81a7e7` | Rapporto Linux originale, processo senza prodotto | 6/6 prove ordinarie riconosciute |
| `fb81a7e7` | `make check` | OK, sorgenti STABLE |
| `edd4000b` | Self-test prima della compattazione | 330/331; fallisce soltanto il budget del riepilogo |
| `8ecfadc4` | Self-test dopo la compattazione | 331/331 |
| `8ecfadc4` | `make check` completo | OK, sorgenti STABLE |

La fixture di 600 file conserva 118.298 byte di rapporto originale e
produce un risultato compatto di 304 byte. Il pacchetto e il raw compresso
sono riletti e confrontati con l'ingresso. Una prova ordinaria incompleta
rimane incompleta.

La [raccolta chiusa](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-ci-wire-processi/catalogo.lisp)
conserva record, output originali, fallimenti, fixture e varianti dei
sorgenti. La raccolta è del 2026-10-22; le date dei processi originali
restano nei rispettivi record. Il replay identifica il rapporto Linux
originale tramite percorso e SHA-256, senza presentarlo come una nuova
campagna Linux. La copertura reale Linux resta da verificare nel workflow
della stessa revisione; nessuna promozione C1/MC/DC.

### Disponibilità del conteggio

Controllo aggiuntivo preregistrato il 2026-10-22: il risultato compatto
ricava il conteggio da TOTALS, già prodotto dall'adattatore di copertura.
Se il figlio si interrompe prima del rapporto, il conteggio deve restare
NIL; un inventario misurato vuoto deve invece restare zero. Due casi
separati distinguono assenza e misura, senza trasformare NIL in zero
tramite LENGTH. La raccolta precedente resta chiusa e immutata.

Su `097ad02a` il self-test passa 332/333 casi: fallisce soltanto il
conteggio erroneamente zero quando manca il rapporto. Su `18d761b2`
passano 333/333 casi e `make check` completo; tutti i record hanno
sorgenti STABLE. La [raccolta aggiuntiva](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-ci-count-availability/catalogo.lisp)
conserva prima/dopo, sorgenti e verifica completa. Il conteggio non
richiede una nuova scansione dell'elenco: riusa il valore già misurato.
