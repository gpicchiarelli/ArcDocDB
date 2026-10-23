# Metodo di verifica delle code dei writer

Ambito registrato prima delle campagne: coda MPSC limitata, privata di una
Serie, e gettone del writer su worker riutilizzabili. Contratto da
[ADR-0045, punti 6 e 8](../adr/0045-modello-di-esecuzione.md),
[concorrenza](../10-concorrenza-e-scheduling.md) e
[architettura](../architettura.md#thread-pool).

## Contratto e oracoli

Ring preallocato; capacità e messaggi estraibili per tratto limitati.
Ogni operazione prova una sola volta la guardia locale tramite CAS: niente
spin, attesa, callback o I/O. Coda piena e contesa segnalano motivi distinti
di `resource-exhausted`, senza accettare il messaggio. FIFO significa ordine
di accettazione, non ordine di invocazione di produttori concorrenti.

Un solo worker detiene il gettone della Serie. Il gettone restituito include
una generazione fixnum monotona: estrazione e rilascio controllano anche il
thread corrente, e un gettone vecchio resta invalido dopo una nuova acquisizione
dello stesso thread. La generazione non si avvolge. L'estrazione riempie uno
span di un vettore del chiamante e addebita i messaggi realmente estratti alla
quota del tratto; chiamate successive non azzerano la quota. `NIL` è un
messaggio valido, distinto dal vuoto tramite il conteggio restituito.

Oracoli indipendenti: lista FIFO dichiarata, identità dei messaggi preallocati,
contatori per produttore e bitmap di accettazione/consegna. Capacità 1/2/3 e
cardinalità maggiori, giri del ring, span disallineati, vuoto, pieno e quota
esatta/esaurita; configurazione invalida, target invalido o alias del ring,
gettone passato al thread sbagliato, acquisizione ricorsiva, rilascio doppio e
gettone vecchio sullo stesso thread. Il contatore vicino al massimo viene
preparato in un oggetto privato senza worker, come stato legalmente raggiungibile,
per controllare il rifiuto dell'overflow senza miliardi di acquisizioni.

## Thread reali e limiti

Produttori e consumatori realmente sovrapposti su una coda piccola: tutti
i messaggi accettati devono essere consegnati una volta, mantenendo l'ordine
di ciascun produttore. I rifiuti non trasferiscono proprietà. Worker creati
una volta per campagna e riutilizzati su più messaggi, buffer privati e lavoro
di calcolo reale fuori dalla guardia. Una Serie deve avanzare mentre guardia
e gettone di un'altra sono occupati. Semafori rendono deterministiche le
prove avverse; retry e join del solo harness hanno tetti espliciti. Niente
successo dedotto da un ritardo o da una coda soltanto precompilata.

Build rigorosa, lint, tracciabilità, link e controllo integrato; due letture
C1 e tabella delle decisioni. Copertura strumentata separata, con self-test e
denominatore completo. Mutanti mirati in copie nuove: baseline invariata
obbligatoria, classificatore con smoke su riga esatta e compilazione fallita
sempre invalida. Si verificano FIFO, wrap, pieno, contesa, proprietario,
generazione, quota cumulativa e span del target; tutte le prove restano conservate.

Allocazioni sul percorso riuscito: cinque repliche di 4.096 cicli con code,
messaggi e target preallocati, warmup 128 e GC fuori dalla misura. Fixture con
capacità 1 e con batch di 32 messaggi; ogni ciclo acquisisce, accoda, estrae e
rilascia, e verifica un risultato osservabile atteso. Self-test del contatore
con baseline e controllo positivo 16 × 1 MiB. Zero heap misurato richiesto,
nessuna soglia di throughput o promessa di scalabilità del motore.

Questo blocco non implementa lista delle Serie pronte, risvegli, pool adattivo,
controller, pubblicazione, conferme o gestione FAULTED della Serie. Non chiude
il protocollo contro i risvegli persi né i requisiti del motore completo.
