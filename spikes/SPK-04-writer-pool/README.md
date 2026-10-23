# SPK-04 — writer logico su thread pool

> **Proposta** — Esperimento di Fase 0, solo Common Lisp/SBCL. Il metodo
> seguente è registrato prima delle prove. Studia ADR-0045 e INV-P5/INV-P6;
> non implementa il motore e non chiude i requisiti di produzione.

## Domanda

Un pool di worker può eseguire tratti limitati del writer di più Serie,
con ordine FIFO, un solo writer per Serie, code limitate e passaggi di
consegna pagati per tratto? Un client può attendere un evento in un contesto
limitato, senza occupare un worker né ricevere due completamenti?

## Metodo

Tre ambiti separati:

- `pool.lisp`: code per Serie e lista delle Serie pronte preallocate;
  worker riutilizzati e limite di operazioni per tratto. La lista comune
  serve solo al passaggio fra tratti; nessun contatore globale viene
  aggiornato da ogni operazione. Il lavoro sintetico controlla ordine,
  contabilità e unicità tramite bitmap; il checksum è un risultato osservato.
- `parcheggi.lisp`: modello deterministico delle liste dei client di un
  lotto, snapshot e coordinatori. Clock logico, capacità e scadenza
  esplicite; generazioni dei contesti distinguono le notifiche obsolete
  dopo il riuso di uno slot. Evento e scadenza producono un solo esito.
- `core.lisp`: integrazione e modello di una lettura che manca la cache.
  Il compito di I/O riparte dalla richiesta e rilegge l'indice; location
  ed epoca del primo compito non attraversano il passaggio.

### Serialità e limiti

Il corpo di un tratto modifica soltanto i dati della propria Serie.
La lista delle Serie pronte è la voce già ammessa nell'elenco chiuso di
[architettura](../../docs/architettura.md#archivio-coordinamento-minimo):
serializza la sola amministrazione dei passaggi tra tratti. Il prototipo
non dimostra latenza costante, equità del runtime, attese nulle o assenza
di contesa. Un limite di tentativi non è una garanzia di completamento.

I carichi sono accodati prima di avviare i worker: non misurano produttori
concorrenti, rete, parsing, WAL, CRC o durability. Il caso con una sola
operazione per tratto rende il costo della lista comune un costo per
operazione: è una diagnostica, non una configurazione raccomandata.

I parcheggi e la migrazione delle letture sono modelli in memoria;
non usano filesystem né simulano memoria debole. Il numero dei worker
è fissato per ciascun caso: EWMA, AIMD e isteresi restano fuori dallo spike.

## Controlli e misure

Prima dei benchmark: compilazione senza warning/style-warning con `safety 3`,
ordine FIFO e risultato esatto per Serie, esclusività del writer, passaggi
fra worker, burst, saturazione delle code, propagazione degli errori,
scadenze e notifiche obsolete dei parcheggi, ripartenza delle letture.
L'equità deterministica è espressa in tratti, non in millisecondi.

La campagna di benchmark confronta carichi uniformi e sbilanciati, numero
di Serie e worker e ampiezza dei tratti. Ogni caso espone operazioni,
tempo wall, throughput, allocazioni e contatori di passaggio. I tempi
includono l'esecuzione sintetica e il coordinamento dichiarati nel record.
Comprendono la creazione sequenziale dei thread e i join; non misurano un
pool già avviato. Il clock viene letto anche durante l'elaborazione delle
richieste, quindi le misure comprendono la strumentazione dell'harness.
Il default comprende 54 casi: worker 1/2/4, Serie 1/4/16, tratti di
1/8/64 operazioni, carico uniforme o sbilanciato, 4.096 richieste totali
per caso e 32 passi di lavoro sintetico per richiesta. Una campagna
non misura risorse condivise del catalogo, CSN, orizzonte o soglia.
Il carico esterno è non controllato; i dati locali non verificano i target
del motore né la scalabilità sulla piattaforma Linux di riferimento.

## Esecuzione e registrazione

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-04
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-04
```

Il runner compila i moduli in una directory locale distinta per processo.
L'harness conserva ambiente, comando, output, errori e blob di tutti i
sorgenti prima e dopo la prova, anche quando la campagna fallisce.
Gli artefatti citati saranno conservati in `spikes/results/2026-10-08/`.

## Stato

La [prima campagna locale](../../docs/valutazione/risultati-SPK-04-2026-10-08.md)
supera cinque gruppi di controlli del pool, 15 fixture dei parcheggi e
nove scenari di ripartenza delle letture. Sono conservati 54 benchmark,
221.184 operazioni sintetiche e i due tentativi falliti precedenti.
RSK-04 e RSK-12 restano aperti alla verifica; i requisiti del motore
restano progettati. Le brevi finestre misurate non dimostrano scalabilità.

Requisiti studiati: REQ-CON-001, REQ-CON-002, REQ-CON-003, REQ-CON-004,
REQ-CON-005, REQ-AFF-008, REQ-VAL-001, REQ-BEN-001, REQ-BEN-002.
