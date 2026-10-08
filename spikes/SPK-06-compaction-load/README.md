# SPK-06 — Compaction e carico

> **Proposta** — Esperimento di valutazione: macchina a stati finita e copie
> di file concorrenti a letture. Non è una compaction del motore e non cambia
> i default di [ADR-0023](../../docs/adr/0023-politiche-di-compaction.md).

## Domande e criteri prima dell'esecuzione

Come reagisce il controllore a segnali e timer ai confini? Quanto cambiano
latenza delle letture e banda di copia quando si introduce una copia concorrente
con diversi limiti di banda? Le prove sono accettate solo se i casi del modello
producono gli esiti dichiarati, tutte le letture verificano CRC/chiave/stamp,
l'output copiato coincide con la sorgente e la sorgente resta immutabile.
Un caso senza sovrapposizione effettiva viene dichiarato; non vale come misura
di interferenza. Nessuna soglia P99 o banda di prodotto è assunta verificata.

## Modello del controllore

Tempo monotono iniettato, nessun thread o sleep. Tracce proprie di al più
256 campioni, tempi da 0 a 1.000.000 ms, rapporti dei segnali da 0 a 2000
millimi dell'obiettivo. Campionamento regolare ogni 500 ms dopo il primo
campione. EWMA esatta con `alpha=1/2`; la lunghezza finita limita la crescita
dei numeratori razionali.

> **Proposta** — Il passo di 500 ms e il peso `1/2` sono parametri
> sperimentali dichiarati; ADR-0023 indica una finestra circa un secondo.
> Non sono una taratura del controllore del motore.

Le soglie seguono ADR-0023: alto se un segnale supera strettamente 80%,
basso dopo entrambi strettamente sotto 40% per almeno 10 s, normale altrimenti.
MERGE in corso rallenta in normale, si sospende in alto e viene abbandonato
dopo 30 s continui di alto. L'uscita da alto resetta il timer. Non parte un
nuovo MERGE in normale/alto; CLEAN urgente in alto richiede almeno 80% di
spazio morto e ha un solo worker.

L'ammissibilità MERGE verifica separatamente CLOSED, immutabilità, non ACTIVE,
assenza di snapshot, gruppo sufficiente, basso carico e stabilità di almeno
50 s. Dopo un riavvio la stabilizzazione parte dalla fine recovery
([ADR-0040](../../docs/adr/0040-manifest-a-record-unico.md)). Il token bucket
del modello ha credito finito, consumo esatto e rifiuto senza credito negativo.
Tempo regressivo, tracce e parametri invalidi producono errori espliciti prima
della mutazione del campione. Starvation e priorità restano proprietà distinte.

## Interferenza reale

Solo Common Lisp/SBCL, `safety 3`, zero warning/style-warning. Si riusano
le API pubbliche I/O e record di [SPK-05](../SPK-05-segment-read/README.md),
senza dipendere dal suo controller. Un file immutabile di 8192 record da
2048 byte (16 MiB) viene generato e verificato prima della matrice. Il body
è sintetico, senza CBOR; non si attestano commit, snapshot o durability.

Matrice: 1/2 lettori, 32.768 letture casuali aggregate per caso, stessa
sequenza deterministica per i confronti, tre repliche con ordine alternato.
Condizioni: nessuna copia, copia libera, copia a 16 MiB/s, copia a 64 MiB/s:
**24 casi**. La copia attraversa una volta tutto il file in blocchi di 64 KiB,
controlla i record e scrive un output `.tmp` esclusivo; dopo i join, l'output
viene riaperto e confrontato integralmente con la sorgente. Non usa fsync:
misura copia buffered, non persistenza del supporto.

Il limite di banda è un token bucket per il solo worker di copia, con credito
massimo di un blocco e un blocco iniziale disponibile. La quota precede la
lettura, verifica e scrittura del blocco. Il clock reale e le attese di pacing
sono nel worker I/O; tentativi e lavoro hanno limiti diagnostici. Il modello
del controllore usa un clock distinto, iniettato: non si trasforma la latenza
osservata in un segnale sintetico di utilizzo reale del dispositivo.

Buffer, fd, piani e campioni sono esclusivi per worker e pronti prima del ciclo.
Una porta comune viene usata ai confini del caso; non ci sono lock o scritture
condivise per record. I tempi distinguono avvio/join, letture, copia, pacing,
verifica finale e pulizia. Si conservano timestamp e campioni grezzi, P99 totale
e P99 delle sole letture il cui intervallo è interamente dentro la reale
sovrapposizione lettori/copia, insieme al numero di tali letture. Una porta
comune non prova da sola la sovrapposizione. I percentili usano rango superiore.
La finestra di copia comprende le attese del token bucket: una lettura coperta
non dimostra che la syscall di copia sia attiva nello stesso istante. Nei dati,
la fine di ogni operazione si ricostruisce sommando inizio e latenza, nell'ordine
dei worker dichiarato da `:worker-operation-counts`.

Attese e join hanno timeout di 10 s. Una syscall bloccata può superare il budget;
un worker vivo impedisce close e rimozione della fixture fino all'uscita del
processo. Directory e file esclusivi nascono sotto `out/data/`; si eliminano
solo oggetti creati dalla prova. Il file di origine non viene scritto.

## Riproduzione e ambiente

```sh
sbcl --script tools/run-spikes.lisp --check SPK-06
sbcl --script tools/run-spikes.lisp --bench SPK-06
```

Check e misure girano in processi isolati; il runner compila in directory
distinta per PID, con avvisi fatali, e produce una sola plist di esito.
Hardware, OS, SBCL, comando, heap configurato e blob dei sorgenti prima/dopo
sono nel registro strutturato. `--check` usa fixture piccole e non è una misura
prestazionale. Le campagne sono eseguite in serie con gli altri spike.

## Risultati e limiti

La [prima campagna](../../docs/valutazione/risultati-SPK-06-2026-10-08.md)
supera i controlli del modello e dei worker; 24 casi completano 786.432 letture
verificate e 18 copie riaperte e confrontate integralmente. Check, misure,
confronto derivato e primo errore di compilazione sono conservati nel catalogo.
Le sorgenti dei run finali risultano stabili prima/dopo.

Il dataset è piccolo, appena
scritto, con page cache non controllata e carico esterno non controllato.
Non si misurano Linux x86-64, NVMe a cache fredda, dataset oltre RAM, traffico
WAL, selezione dei record necessari, rilocazioni, reclaim, CLEAN/MERGE durevoli
o il feedback completo del controllore. RSK-08 (starvation accettata) e RSK-12
(stabilità su carichi reali) restano aperti nell'ambito dichiarato.
