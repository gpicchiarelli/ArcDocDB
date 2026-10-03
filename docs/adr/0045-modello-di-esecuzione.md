# ADR-0045 — Modello di esecuzione: compiti a completamento, migrazione senza stato, attese come parcheggi

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; realizza «Concorrenza» e «Thread pool
  dinamico» (nessun thread per richiesta né per Serie). **Precisa**
  [ADR-0017](0017-piattaforma-e-io.md) punto 5 (che cosa passa dal pool di I/O),
  [ADR-0016](0016-epoch-based-reclamation.md) (estensione di una sezione di lettura) e
  [ADR-0035](0035-strategia-di-verifica-e-tracciabilita.md) §2 (come si realizza il
  simulatore).
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-10;
  [architettura](../architettura.md#concorrenza); INV-P2, INV-P5, INV-P6, INV-A8

## Contesto

Il progetto ha due pool di worker e zero allocazioni sui percorsi caldi, ma non diceva che
cosa succede quando un'operazione deve aspettare: una lettura che manca la cache, un client
che attende il flush, uno snapshot che attende l'orizzonte, un coordinatore che attende i
partecipanti. In Common Lisp non ci sono continuazioni: un'operazione che si sospende a metà
occupa un thread. E un simulatore deterministico a flusso unico (ADR-0035) è realizzabile
solo se nessuna operazione si sospende a metà.

## Decisione

1. **Compiti a completamento.** Ogni unità di lavoro — lettura, tratto del writer di una
   Serie, compito di I/O di un log, passo di compaction, passo del coordinatore — è un
   **compito** che un worker esegue dall'inizio alla fine senza sospendersi e senza attendere
   un altro compito.
2. **Un'attesa è un parcheggio.** Un compito che ha bisogno di un evento futuro registra il
   **contesto della richiesta** (preallocato, a dimensione fissa) nella lista di chi produrrà
   l'evento, e termina. L'evento accoda un nuovo compito che riprende da quel contesto. Le
   liste di parcheggio sono tre: i client di un lotto (attendono la pubblicazione), gli
   snapshot (attendono l'orizzonte), i coordinatori (attendono i partecipanti). Ciascuna ha
   una **lunghezza massima** e un **tempo massimo**; il superamento è `resource-exhausted`
   (INV-A8).
3. **Il pool di calcolo non si blocca** (INV-P5). Nessun worker di calcolo esegue chiamate di
   sistema bloccanti. Scritture nei log, flush, letture dai segmenti, rinomine ed eliminazioni
   sono compiti del **pool di I/O**. Il pool di I/O ha un tetto di worker: è anche il limite
   della concorrenza sul dispositivo.
4. **Migrazione senza stato delle letture.** Una lettura parte nel pool di calcolo: indice,
   cache; se trova il record, risponde. Se manca la cache, **migra**: accoda la stessa
   richiesta al pool di I/O e termina. Il worker di I/O **riesegue la lettura dall'inizio**
   (indice, cache, lettura dal segmento, verifica, risposta). Nessuna location, nessun
   descrittore, nessuna epoca attraversano il passaggio: la lettura è idempotente, quindi
   ripeterla è sempre corretto.
5. **Sezione di lettura = compito.** Un compito che consulta indice o segmenti resta dentro
   un'epoca ([ADR-0016](0016-epoch-based-reclamation.md)) per tutta la sua durata. Una
   sezione può contenere una lettura da disco (nel pool di I/O), mai rete, mai un parcheggio:
   parcheggiare termina il compito, quindi la sezione.
6. **Tratto del writer.** Il writer logico di una Serie è un compito che acquisisce il gettone
   della Serie, elabora al più un numero limitato di operazioni e messaggi (esiti dei flush,
   PREPARE, OUTCOME, rilocazioni), rilascia il gettone e, se la coda non è vuota, si
   riaccoda. Il limite garantisce l'equità tra Serie.
7. **Il motore è una libreria.** L'interfaccia del motore è: richiesta più continuazione. Il
   server (connessioni, frame, [ADR-0029](0029-interfacce-protocollo-query-contratto.md)) è un
   guscio che la chiama; il simulatore e i test chiamano la stessa interfaccia.
8. **La distribuzione del lavoro non è un punto seriale** (legge 1,
   [ADR-0036](0036-leggi-di-progetto.md)). Una lettura è eseguita dal worker che la riceve,
   senza passare da una coda comune. Una scrittura entra nella coda della propria Serie.
   La lista delle Serie con lavoro pronto, da cui i worker prendono i tratti dei writer, è
   toccata una volta per tratto, non per operazione. Non esiste una coda globale attraversata
   da ogni richiesta.
9. **Simulatore.** Poiché nessun compito si sospende, il simulatore deterministico è un ciclo
   che sceglie dal seme il prossimo compito pronto e lo esegue, con tempo e I/O simulati. Un
   crash è l'abbandono dello stato in memoria tra due compiti o in un punto di iniezione
   nominato. Non servono thread né continuazioni. Gli interleaving **interni** alle strutture
   senza lock (seqlock dell'indice e della cache) non sono compiti: li coprono il modello
   esaustivo (SPK-07) e le prove di stress con thread reali.

Pattern: esecuzione a compiti brevi senza sospensione con code per partizione (SEDA; modello
*thread-per-core* con passaggio di messaggi di Seastar/ScyllaDB, qui senza affinità ai core);
simulazione deterministica a flusso unico (FoundationDB, TigerBeetle).

## Conseguenze

- Il numero di thread non dipende dal numero di richieste in attesa: dipende dai core e dal
  tetto del pool di I/O.
- Ogni attesa del sistema è una lista limitata, osservabile con una metrica.
- Una lettura che manca la cache costa un passaggio di coda e una seconda ricerca
  nell'indice: nanosecondi contro i ~0,1 ms di una lettura dal dispositivo.
- Le interfacce tra moduli sono «richiesta più continuazione», non chiamate che ritornano
  dopo un'attesa: va tenuto presente dalla Fase 1.

## Limite da misurare

Il collector di SBCL ferma **ogni** thread a ogni collezione: la pausa cresce con il numero
di thread, compresi i worker di I/O fermi in una chiamata di sistema. Il tetto del pool di
I/O è quindi anche un parametro della pausa: SPK-02 misura la pausa in funzione del numero di
thread, e il tetto si fissa di conseguenza.

## Alternative considerate

- *Bloccare il worker che serve la richiesta:* semplice, ma un dispositivo lento occupa tutti
  i worker e ferma anche le letture servite dalla memoria.
- *Passare la location al pool di I/O:* evita la seconda ricerca, ma richiede di tenere
  un'epoca tra due thread o di rivalidare la location; ripartire dall'inizio non ha casi.
- *Simulatore con thread reali a staffetta:* esplora anche le sospensioni a metà compito, ma
  quelle sospensioni non esistono nel modello.

## Valutazione

- Rischi: RSK-01 (numero di thread e pause), RSK-12.
- Verifica: SPK-04 (costo dei passaggi di coda, equità tra Serie); SPK-02 (pausa per numero
  di thread); test di saturazione di ogni lista di parcheggio.
