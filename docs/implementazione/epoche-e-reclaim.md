# Epoche e reclaim dei segmenti

[`src/epochs/`](../../src/epochs/) introduce il dominio EBR per Archivio previsto da
[ADR-0016](../adr/0016-epoch-based-reclamation.md), con l'ambito precisato da
[ADR-0043](../adr/0043-primary-index-a-frammenti.md) e
[ADR-0045](../adr/0045-modello-di-esecuzione.md). Protegge descrittori e file dei
segmenti rimossi; directory e frammenti Lisp restano responsabilità del collector.

## Risorse e proprietà

`crea-registro-epoche(W, K)` prealloca tutto il dominio:

- `1 <= W <= 4.096`: tetto comune dei worker di calcolo e di I/O che possono
  leggere questo Archivio. Gli ID sono distinti tra i due pool.
- `1 <= K <= 65.536`: ticket e riferimenti forti ai descrittori dei segmenti in
  manutenzione. Ogni prenotazione occupa un credito fino ad annullamento o reclaim.
- Un annuncio `u64` per worker: zero indica inattivo, un valore positivo indica
  l'epoca. Le parole usate distano **128 byte**, con padding iniziale e finale.
  Non si assume un allineamento della base dell'array a 128 byte; parole distanti
  128 byte non condividono una linea di cache da 64 o 128 byte.
- Generazioni ed epoche `u64`, stati `u8`, array di riferimenti e ticket canonici.
  I campi numerici dei ritiri occupano `17K` byte; gli annunci `128(W+1)` byte.
  Si aggiungono parole comuni, vettori di riferimenti, contesti, header e mutex.

`contesto-epoca(registry, worker-id)` restituisce sempre lo stesso contesto
preallocato. Il controller assegna l'ID a **un solo worker vivo**. Il riuso
richiede il termine dei compiti e il join del precedente worker; due thread
non possono usare lo stesso slot. Questo vincolo appartiene al controller
dei pool: il modulo non identifica thread tramite variabili globali.

Un worker scrive solo il proprio annuncio. Legge l'epoca `E` senza modificarla.
La manutenzione modifica `E`, ticket, contatori e soglia sotto un mutex per
Archivio, una volta per segmento o gruppo di ritiri. Nessun GET acquisisce quel
mutex sul percorso riuscito; nessuna richiesta incrementa un contatore condiviso.
Le parole `E` e soglia distano 128 byte dai contatori numerici aggiornati durante
la prenotazione.

## Ingresso e uscita del reader

`entra-epoca(reader)` ha **un solo tentativo**:

1. Verificare salute e slot inattivo.
2. Leggere `E = e` con barriera di lettura.
3. Pubblicare `e` nello slot esclusivo; barriera completa.
4. Rileggere `E` e salute prima di qualsiasi root, location o descrittore.
5. Se l'epoca è cambiata, liberare lo slot e restituire `NIL`.
6. Se è ancora `e`, restituire `T`: il compito può leggere.

Su `NIL` il controller riaccoda il compito secondo i budget di ammissione e la
deadline della richiesta. Il modulo non attende, non fa retry interno e non
mantiene una sezione aperta durante la riaccodatura. Una regressione di `E`
produce fail-stop; zero non è mai un'epoca corrente valida.

Il [contesto di lettura](compiti-lettura.md) installa il cleanup del compito
prima dell'ingresso, ammette il lookup solo dopo `T` e richiama `esci-epoca`
dopo l'ultimo accesso. `epoca-attiva-p`, usato dal solo proprietario, copre
anche l'interruzione fra conferma e ritorno di `entra-epoca`; non autorizza
una dereference. L'uscita esegue una barriera completa prima di pubblicare
zero. È consentita anche dopo `FAULTED`, per il cleanup del worker.
Ingresso annidato e uscita da slot inattivo sono `invalid-argument`.

```text
entra-epoca = T
  → verifica snapshot iniziale, se presente
  → root / indice / cache / segmento
  → verifica finale di indice e snapshot, anche sul miss
  → esci-epoca
  → invio della risposta
```

Il compito del pool di I/O può leggere dal disco dentro la propria epoca.
Una migrazione termina prima la sezione e riparte dall'inizio su un altro
worker: nessuna location, nessun descrittore e nessuna epoca attraversano la
coda. Rete, parcheggi e callback non si eseguono dentro una sezione.

## Ticket di ritiro

La manutenzione ottiene un ticket **prima di rimuovere i riferimenti**:

| Interfaccia | Contratto |
|---|---|
| `prenota-ritiro(registry, resource)` | Conserva il descrittore canonico e restituisce ticket e generazione originale. Riserva slot e un avanzamento di `E`. |
| `annulla-ritiro(ticket, generation)` | Solo prima di qualsiasi rimozione di riferimenti; rilascia i crediti. Idempotente per la stessa identità annullata. |
| `pubblica-ritiro(ticket, generation)` | Dopo la rilocazione completata e la rimozione dei riferimenti da indice e versioni trattenute, registra `r = E` e avanza `E`. |
| `aggiorna-soglia-reclaim(registry)` | Una scansione di `W` annunci aggiorna la frontiera acquisita per più ticket. |
| `acquisisci-reclaim(ticket, generation)` | Restituisce `T` solo per `r < soglia`; assegna un unico proprietario del reclaim. Altrimenti `NIL`. |
| `leggi-risorsa-ritiro(ticket, generation)` | Restituisce il riferimento forte ancora conservato; non concede il diritto di chiudere il descrittore. |
| `completa-reclaim(ticket, generation)` | Solo dopo la chiusura/rimozione riuscita secondo la prova del manifest; rilascia riferimento e credito. Idempotente per la stessa identità completata. |
| `leggi-ritiro`, `leggi-registro-epoche` | Stato, epoca, soglia e occupazione per osservabilità, sotto mutex. |

La macchina a stati del ticket è:

```text
RESERVED → RETIRED → CLAIMED → COMPLETED
    └─────────────────────→ CANCELLED (solo prima dello swap)
```

`leggi-ritiro` espone gli stati come keyword. Il ticket è un oggetto canonico
con slot fisso; la **generazione**, crescente senza wrap, identifica il singolo
ritiro. Ogni evento conserva quella ricevuta da `prenota-ritiro`. Un evento di
una vecchia generazione non modifica il ticket riusato. Un secondo claim viene
rifiutato: due compiti non acquisiscono contemporaneamente la stessa risorsa.
Il registro rifiuta un descrittore canonico già presente; il Segment Manager
deve garantire una sola identità di descrittore per ciascun file.

Un errore I/O dopo il claim lascia ticket e risorsa in `CLAIMED`: lo stesso
proprietario può ripetere il completamento I/O idempotente. Il credito non viene
restituito da un timer o da un timeout. Le generazioni distinguono riuso ed
eventi tardivi, ma non sostituiscono la proprietà del compito assegnata dallo scheduler.

## Frontiera e barriere

`E` parte da uno ed è monotona. Pubblicare un ritiro richiede:

```text
rimozione dei riferimenti → barriera completa → r = E; E = E + 1 → barriera completa
```

La scansione dei reader, serializzata rispetto ai ritiri, usa `E` come limite
superiore e calcola `m = min(E, epoche non zero osservate)`. Barriere complete
precedono la scansione e la pubblicazione della soglia. Un ticket è reclamabile
solo con il confronto **stretto** `r < soglia`.

La soglia conserva `max(soglia precedente, m)`: un worker può aver campionato
una vecchia `E` e annunciarla dopo una scansione, ma la conferma lo rifiuterà
prima di accedere alla risorsa. Quell'annuncio transitorio non annulla una
frontiera già acquisita. Un reader ammesso della vecchia epoca deve invece
essere osservato prima che la frontiera lo superi. Non si scade o azzera mai
lo slot di un worker ancora vivo per forzare il reclaim.

La lettura di una nuova `E` viene dopo la pubblicazione della rimozione dei
riferimenti; il reader consulta la root soltanto dopo la conferma. È questa
sequenza che collega ammissione e ritiro. La sola scansione di slot senza
le barriere di ingresso e di ritiro sarebbe insufficiente.

Le primitive sono quelle del [manuale SBCL](https://www.sbcl.org/manual/#Barriers)
sulle piattaforme a 64 bit di [ADR-0017](../adr/0017-piattaforma-e-io.md).
L'ispezione del [protocollo Crossbeam](https://github.com/crossbeam-rs/crossbeam/blob/master/crossbeam-epoch/src/internal.rs)
ha informato la revisione delle barriere di annuncio e scansione; non si importa
codice Rust né si assume equivalenza tra le implementazioni.

## Esaurimento, guasti e persistenza

Ogni prenotazione riserva anche un incremento dell'epoca: l'invariante è
`E + reserved <= MAX-U64`. Il budget viene controllato **prima dello swap**,
così `pubblica-ritiro` non scopre un overflow dopo la rimozione dei riferimenti.
Annullamento restituisce quel budget; pubblicazione lo consuma. Generazioni
esaurite o capacità piena producono `resource-exhausted` senza wrap.

Le transizioni composte usano cleanup fail-stop. Un'uscita non locale durante
la mutazione marca il dominio `FAULTED`; contatori, identità e metadati restano
controllati. Il proprietario isola l'Archivio. Nessun reclaim continua nel
dominio guasto; l'uscita dei reader già ammessi resta possibile.

EBR e ticket sono **volatili**. Dopo crash si ricostruiscono da manifest e
segmenti, senza ripristinare vecchie epoche o contesti. `pubblica-ritiro` non
è un punto di atomicità durevole. L'ammissione al reclaim prova solo l'assenza
dei reader: l'I/O di eliminazione richiede anche la prova della rimozione dal
manifest ([REQ-AFF-018](../tracciabilita/matrice.md)) e un compito del pool di I/O.
Il registro non chiude descrittori e non elimina file.

La perdita di un worker può lasciare un pin conservativo. Il contesto di
lettura dispone ora del cleanup fra ammissione e consegna al chiamante;
il confine del worker deve installarlo prima dell'ingresso e terminare il
compito. Non si può dichiarare inattivo un thread che potrebbe ancora
leggere. Monitoraggio, join e gestione di questi guasti sono da integrare.

## Tracciabilità e qualifica

### Decisioni composte da coprire

Questa tabella identifica le decisioni introdotte; non dichiara copertura.
Ogni condizione richiede un caso indipendente oltre al percorso riuscito.

| ID | Funzione | Condizioni |
|---|---|---|
| EBR-D01 | `crea-registro-epoche` | `W` nel range e `K` nel range, prima di allocare. |
| EBR-D02 | `verifica-contatori-epoche` | `reserved <= count <= K`, cursore nel range, `1 <= soglia <= E`, crediti di avanzamento senza overflow. |
| EBR-D03 | `esigi-identita-ritiro` | Slot nel range, generazione positiva, uguaglianza con la generazione del ticket. |
| EBR-D04 | `verifica-slot-ritiro` | Generazione assegnata; stato RESERVED con epoca zero e risorsa; RETIRED/CLAIMED con `0 < r < E` e risorsa; CANCELLED con epoca zero senza risorsa; COMPLETED con `0 < r < E` senza risorsa. |
| EBR-D05 | `prenota-ritiro` | Esaurimento della generazione oppure di `MAX-U64 - E - reserved`. Capacità e duplicato hanno rifiuti distinti. |
| EBR-D06 | `pubblica-ritiro` | Credito riservato positivo e `E < MAX-U64`, dopo stato e identità verificati. |
| EBR-D07 | `trova-slot-ritiro` | Stato occupato fra RESERVED e CLAIMED; identità `EQ` della risorsa; scelta di un libero o errore di contabilità. |
| EBR-D08 | `leggi-risorsa-ritiro` | Stato fra RESERVED e CLAIMED e riferimento forte presente. |

I confini del protocollo richiedono inoltre: reader sospeso prima e dopo
l'annuncio, cambio di `E` prima della conferma, uscita prima/dopo la scansione,
annuncio vecchio arrivato dopo l'avanzamento della soglia, claim duplicato,
evento tardivo sullo slot riusato, errore I/O e interruzione del worker. Sono
obblighi di verifica aperti, non scenari eseguiti da questa modifica.

| Requisito | Parte introdotta | Integrazione/verifica restante |
|---|---|---|
| REQ-CMP-005 | Reader indipendenti dal mutex di manutenzione, ingresso a tentativo singolo. | Letture reali durante CLEAN/MERGE e costo delle barriere. |
| REQ-CMP-007 | Epoche, riferimenti forti e claim esclusivo dopo la frontiera. | Segment Manager, indice/versioni trattenute, FI-09/FI-11. |
| REQ-AFF-008 | Slot e ticket fissi, scansioni limitate, crediti u64 prima dello swap. | Saturazione, confini u64, worker arrestati e integrazione dei pool. |
| REQ-AFF-004 | Errori tipizzati e fail-stop delle mutazioni interrotte. | Interruzioni in ogni transizione e gestione del guasto dell'Archivio. |

I requisiti restano **progettati**. Compilazione del solo prodotto, controlli
statici e disassemblato non qualificano il protocollo concorrente. Non sono
stati aggiunti o eseguiti localmente test funzionali, stress, fault injection
o benchmark del modulo. Restano memoria debole x86-64/ARM64, allocazioni e
prestazioni misurate e l'integrazione del reclaim durevole.
I [record originali](../../spikes/results/2026-10-09-ebr/catalogo.lisp)
conservano sorgenti, comandi e output, compreso il testo dello script che
stampa il disassemblato senza eseguire le funzioni ispezionate.
