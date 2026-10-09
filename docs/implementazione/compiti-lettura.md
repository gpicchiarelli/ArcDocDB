# Compiti di lettura: epoche, snapshot e cleanup

## Ambito

`arcdocdb.read` collega il [registro snapshot](registro-snapshot.md) al
[dominio EBR](epoche-e-reclaim.md) per la durata di un compito. Realizza il
confine previsto da [ADR-0045](../adr/0045-modello-di-esecuzione.md), senza
cambiare il protocollo degli snapshot o dei segmenti.

Il modulo è incluso nel sistema di prodotto. Non consulta ancora un primary
index, una cache o un segmento; non è un GET completo. La verifica dei byte
rimane responsabilità di `arcdocdb.record:verifica-put`, inclusa la prova
OUTCOME dei prepared secondo [ADR-0047](../adr/0047-verifica-csn-dei-record-prepared.md).
Un contesto di lettura protegge l'accesso, non attesta il contenuto del record.

Classe C1. Requisiti interessati: REQ-CON-004, REQ-CMP-005, REQ-CMP-007,
REQ-MVC-004, REQ-MVC-005, REQ-AFF-004 e REQ-AFF-008. Restano `:progettato`.
Invarianti: INV-P5, INV-A8, INV-C10, INV-R1, INV-M1 e INV-M4.

## Proprietà e memoria

Il controller crea **un solo contesto per slot worker dell'Archivio**, prima
dell'avvio dei pool, passando il reader EBR canonico e il registro snapshot
dello stesso Archivio. I due registri hanno identità indipendenti: il loro
abbinamento è responsabilità del controller, non dedotto dai dati in lettura.
Gli ID dei worker di calcolo e I/O devono essere distinti nel dominio EBR.

Il contesto contiene legami immutabili, un riferimento temporaneo allo
snapshot e quattro word u64 private: generazione attesa, CSN iniziale,
tempo iniziale e CSN ricontrollato. Le word vengono azzerate al cleanup.
Non conserva root, location, descrittori, buffer di dati o risultati.

La capacità è quella dei worker del dominio, senza strutture per documento
o richiesta. La sola scrittura condivisa è l'annuncio EBR del worker; le
verifiche dello snapshot leggono il registro. Nessuna coda globale, mutex,
timer, callback, creazione di thread o chiamata di sistema sul percorso
riuscito. Il cleanup visita esattamente quattro word; l'ingresso EBR è un
solo tentativo. I percorsi di errore dei registri possono prendere un mutex.

I buffer e le funzioni di controllo del CSN sono specializzati e inline per
evitare un ritorno u64 boxed sul percorso previsto. Questo è un vincolo di
implementazione: l'assenza di allocazioni e il costo reale richiedono misure.

## API

| Funzione | Contratto |
|---|---|
| `crea-contesto-lettura(reader, snapshots)` | Preallocazione nel controller; reader già attivo rifiutato. |
| `avvia-lettura(ctx, snapshot, generazione, now)` | `T`: epoca confermata e snapshot eventualmente verificato. `NIL`: epoca cambiata, nessun accesso ammesso; riaccodare con budget/deadline della richiesta. |
| `copia-limite-lettura(ctx, buffer, indice)` | `T`: CSN snapshot copiato. `NIL`: GET corrente, buffer intatto. Il lookup deve controllare il booleano e scegliere la versione appropriata. |
| `concludi-lettura(ctx, now)` | Dopo il lookup, **anche su miss**: ricontrolla snapshot e tempo, poi libera EBR. Solo il ritorno normale consente di consegnare il risultato privato. |
| `abbandona-lettura(ctx)` | Cleanup senza autorizzare risultati; idempotente quando inattivo. Prima di migrare, scartare tutte le location. |
| `stato-contesto-lettura(ctx)` | Diagnostica locale del proprietario; non sincronizza un controller con un worker vivo. |

GET corrente: `snapshot=NIL`, `generazione=0`. Con snapshot: identità
originale positiva e registro identico a quello del contesto. Uno snapshot
di un altro Archivio è rifiutato prima dell'annuncio EBR. Generazione, stato,
CSN e deadline vengono poi verificati dal registro, dentro l'epoca.

`now` è fresco, monotono e nelle stesse unità dei registri snapshot.
Il controllo finale rifiuta un valore inferiore a quello iniziale; non può
rilevare che il chiamante abbia riutilizzato un timestamp vecchio. La fonte
di tempo rimane iniettabile e responsabilità del chiamante.

## Confine del compito

Il worker installa `unwind-protect` **prima di chiamare `avvia-lettura`** e
chiama sempre `abbandona-lettura` nel cleanup. Questo copre anche l'uscita
non locale dopo l'ammissione e prima del ritorno della funzione. Non basta
installare la protezione soltanto dopo aver ricevuto `T`.

1. Avviare senza avere letto indice, root, location o descrittore.
2. Se `NIL`, terminare il compito e riaccodare la richiesta originale entro
   il suo budget. Nessun retry interno al contesto.
3. Se `T`, scegliere il CSN, consultare indice e versioni trattenute,
   ricontrollare root/generazione anche su miss (ADR-0050), verificare i
   byte e copiare l'eventuale risposta in memoria privata della richiesta.
4. Chiamare `concludi-lettura` con tempo fresco. Se fallisce, scartare anche
   il risultato negativo; nessuna risposta è ammessa.
5. Dopo il ritorno normale, terminare il compito e consegnare la risposta
   privata al livello di rete fuori dall'epoca.

Su cache miss nel pool di calcolo, abbandonare la sezione e scartare la
location **prima** di accodare la richiesta al pool di I/O. Il contesto
rimane nel worker; il nuovo compito entra nel proprio reader e riparte dal
lookup. Nel pool di I/O è consentito `pread` nella sezione; non sono
consentiti rete, parcheggi o attese di altri compiti.

Il contesto non fornisce un adattatore del pool o una continuazione e non
può impedire a un chiamante di consegnare un risultato troppo presto. Il
futuro confine eseguibile del motore deve rispettare questa sequenza.

## Stati, errori e interruzioni

| Stato | Transizione |
|---|---|
| `:idle` | Input validato senza toccare EBR; ingresso → `:entering`. |
| `:entering` | Conferma EBR e snapshot riuscite → `:active`; cambio epoca o errore recuperabile → cleanup e `:idle`. |
| `:active` | Conclusione o abbandono → cleanup e `:idle`; errore di invariante → `:faulted`. |
| `:faulted` | Cleanup consentito; il contesto resta inutilizzabile. Nessun reset automatico. |

Il cleanup imposta prima `:faulted`, verifica l'annuncio del solo reader
proprio, lo libera e azzera i dati. Ripristina `:idle` soltanto quando tutto
è terminato e il contesto non era già guasto. Un'interruzione nel mezzo
conserva `:faulted`; il controller può completare il cleanup solo dopo la
fine del compito o il join del worker, mai cancellare un reader vivo.

`epoca-attiva-p` serve al proprietario per il cleanup: osservare un annuncio
non autorizza a dereferenziare una risorsa. Consente di liberare anche la
finestra in cui `entra-epoca` ha confermato il pin ma non ha ancora restituito
il booleano al contesto. L'ingresso rifiuta un reader già attivo prima di
installare questo cleanup, evitando di liberare una sezione preesistente.

Le condizioni del registro (`snapshot-too-old`, `resource-exhausted`,
`invalid-argument`, `invariant-violation`) restano tipizzate e non sono
catturate o nascoste. L'annidamento e l'uso fuori dallo stato ammesso sono
rifiutati. Un'incoerenza interna rende il contesto `:faulted`; il futuro
confine worker deve isolare la Serie o l'Archivio interessato e registrare
il guasto. Tale propagazione non è ancora integrata.

La scadenza logica dello snapshot non libera il pin EBR di un compito vivo.
Il controllo finale rifiuta il risultato scaduto; il pin protegge l'accesso
fisico fino all'ultimo uso. Terminare una lettura non termina lo snapshot,
che può essere condiviso da più richieste dell'Archivio.

## Decisioni da coprire — COD-54

| ID | Decisione | Condizioni da distinguere |
|---|---|---|
| READ-D01 | Inattivo senza residui | Riferimento snapshot nullo e ciascuna delle quattro word zero. |
| READ-D02 | Identità snapshot di input | Generazione positiva; registro uguale. |
| READ-D03 | Associazione snapshot attiva | Generazione positiva; registro uguale. |
| READ-D04 | Modalità corrente attiva | Generazione zero; CSN iniziale zero. |

Le altre decisioni semplici da esercitare comprendono annidamento,
annuncio già attivo, cambio di epoca, snapshot in attesa/terminato/scaduto,
indice del buffer invalido, regressione del tempo, CSN finale discordante,
interruzione in ingresso/conclusione/cleanup e migrazione tra worker.
Per le decisioni dei registri valgono anche le loro tabelle dedicate.

## Evidenze e lavoro restante

La campagna [2026-10-09](../../spikes/results/2026-10-09-read-task/README.md)
conserva compilazione del solo prodotto, controlli statici, tracciabilità,
link, cataloghi e disassemblato ARM64. Nessuna funzione di lettura viene
eseguita dalla campagna; non sono state aggiunte o eseguite prove funzionali,
concorrenti, fault injection, benchmark o auto-verifiche degli strumenti.

Restano da integrare primary index, versioni trattenute, cache, lettura dei
record e confine dei pool. La qualifica richiede esercitare le decisioni,
interruzioni e gare con scadenza/reclaim, verificare la migrazione su worker
reali e misurare allocazioni/latency su ARM64 e x86-64. Compilazione e CI
dei test già presenti non chiudono questi criteri.
