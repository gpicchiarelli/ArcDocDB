# Primo incremento dell'indice automatico — Risultati

Data: 2026-10-22. Contratto e limiti in [indice automatico](indice-automatico.md).
SBCL 2.6.9 su macOS ARM64. Il carico esterno non e' controllato; nessun
benchmark di prestazione del motore viene eseguito o dedotto da questi dati.

L'[archivio chiuso](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-index-auto-targeted/catalogo.lisp)
conserva le sorgenti dell'incremento, il driver della suite e i record dei
due processi, entrambi con stato OK, uscita 0 e sorgenti stabili prima/dopo.
La base Git e l'intero inventario degli hash sono nei record originali.

## Selettore C1

Compilazione rigorosa del sistema e delle definizioni dei test, seguita dalla
sola nuova suite: 8 test superati. Verificati avvio residente alla quota esatta,
crescita che richiede il paginato, transitorio capiente/insufficiente, rientro
con isteresi, variazione delle quote, indipendenza delle Serie, domini e
arrotondamento al limite intero. La finestra seriale di 10.000 decisioni
osserva zero byte Lisp allocati con sink atteso 3994.

Questo risultato non dimostra la capienza delle stime future del runtime:
il selettore riceve campioni fidati, non misura RSS o GC. Backend persistente
e migrazione non sono presenti; il requisito complessivo rimane progettato.

## Lifetime C4

Il [metodo preregistrato](../../spikes/SPK-07-protocols/metodo-page-lifetime.md)
e il modello sono conservati nell'archivio con i controesempi completi.

| Reader | Riusi | Stati visitati | Archi | Violazioni |
|---:|---:|---:|---:|---:|
| 1 | 1 | 65 | 95 | 0 |
| 1 | 2 | 153 | 233 | 0 |
| 2 | 1 | 745 | 1574 | 0 |
| 2 | 2 | 2316 | 4984 | 0 |

Totale calcolato: 3279 stati e 6886 archi nelle quattro configurazioni corrette.
Ogni configurazione raggiunge successo, copia durante RETIRING, riuso fermato
da protezione e annuncio tardivo. Il limite duro di 200.000 stati non viene raggiunto.

| Controllo negativo | Esito atteso e osservato |
|---|---|
| Senza riconferma READY/token | Copia di un'incarnazione diversa; controesempio conservato. |
| Rilascio fra le due copie | Secondo campo riusato; controesempio conservato. |
| Reclaimer ignora hazard | Frame sovrascritto durante la protezione; controesempio conservato. |
| Token riciclato dopo due riusi | ABA accettato dal confronto, rifiutato dall'oracolo delle incarnazioni. |

Sono enumerazioni finite sotto SC e primitive astratte terminanti. La safety
del modello e il limite di sei passi propri per tentativo non sono una prova
di lock-freedom del lookup completo o del GET. CPU reale, atomiche SBCL,
directory, snapshot, cache finita e miss I/O restano gate aperti.

## Revisione e integrazione

La lettura del contratto e la lettura degli interleaving verificano perimetro,
budget, validazione e ABA; sono revisioni dello stesso autore, non una revisione
indipendente C1. La suite e il modello sono registrati rispettivamente nel
catalogo CI e in SPK-07. I controlli globali del repository restano una verifica
distinta dalle due esecuzioni iniziali conservate qui.
