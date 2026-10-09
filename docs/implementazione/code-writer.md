# Code locali e gettone dei writer

`arcdocdb.execution` fornisce la coda MPSC preallocata di una Serie e il gettone
del suo writer logico. Realizza le primitive di
[ADR-0045, punto 6](../adr/0045-modello-di-esecuzione.md): worker riutilizzabili,
un solo writer per Serie, tratti limitati. Ogni Serie riceve un oggetto distinto,
con ring e metadati propri; non esiste una guardia comune alle Serie.

## Interfaccia e proprietà

| Operazione | Risultato e condizioni |
|---|---|
| `crea-coda-writer :capacity :quantum` | Ring privato; default 1024 slot e 64 messaggi per tratto. Entrambi i limiti sono interi 1..65536, indipendenti. |
| `accoda-messaggio queue message` | Conteggio dopo l'accettazione. FIFO nell'ordine di accettazione; `NIL` è un payload valido. |
| `acquisisci-writer queue` | Generazione positiva del gettone, legata anche al thread corrente. |
| `preleva-messaggi queue lease target start end` | Conteggio e `:messages`, `:empty` o `:yield`; riempie lo span di un `simple-vector` privato del chiamante. |
| `rilascia-writer queue lease` | Rilascia il gettone, conserva la generazione e azzera la quota consumata del tratto. |

Il numero del gettone è locale alla coda: la sua identità completa è
`(queue, lease)`, con controllo del thread proprietario. Due code distinte
possono avere lo stesso numero di generazione.

L'accettazione trasferisce il riferimento dal produttore alla coda; il prelievo
lo trasferisce al consumatore. Il payload è un contesto interno già preparato:
la coda non copia, interpreta o valida un documento. Nessuno modifica il contesto
in volo. Il consumatore usa soltanto il numero di elementi restituito e mantiene
il gettone fino al termine dell'elaborazione dei messaggi estratti. Altri worker
possono produrre nuovi messaggi durante quel tratto.

La guardia protegge ring e indici anche quando un worker possiede il gettone.
Il gettone protegge invece l'esclusività del writer: i due CAS sono distinti.
Ogni acquisizione prova una sola volta, senza attesa o spin. Le proprietà di
ordinamento sono quelle del
[CAS e delle barriere SBCL](https://www.sbcl.org/manual/#Barriers).
Non si tratta di una promessa di progresso senza blocchi: un worker che non
rilascia una proprietà impedisce gli accessi che la richiedono alla sua Serie.

| Rifiuto | Condizione e proprietà preservata |
|---|---|
| Configurazione invalida | `invalid-argument`, `:writer-configuration`; nessuna coda pubblicata. |
| Guardia del ring occupata | `resource-exhausted`, `:writer-queue-busy`; nessun messaggio accettato o estratto. |
| Ring pieno | `resource-exhausted`, `:writer-queue-full`; messaggio ancora del produttore. |
| Writer già occupato | `resource-exhausted`, `:writer-busy`; nessuna seconda proprietà acquisita. |
| Generazione esaurita | `resource-exhausted`, `:writer-generation`; niente wrap, gettone acquisito temporaneamente rilasciato. |
| Gettone vecchio, errato o di altro thread | `invalid-argument`, `:writer-lease`; proprietà e quota correnti conservate. |
| Target o span invalido, alias del ring | `invalid-argument`, `:writer-target`; nessun prelievo o modifica del target. |
| Incoerenza interna | `invariant-violation`; il futuro controller deve applicare il fail-stop della Serie. |

Il prelievo è limitato da messaggi disponibili, span del target e quota rimasta
nel tratto. La quota viene addebitata cumulativamente al gettone: più chiamate
non consentono di aggirarla. Dopo l'esaurimento restituisce `0, :yield`; il vuoto
con quota disponibile restituisce `0, :empty`. Gli elementi del target fuori
dallo span effettivamente riempito non vengono toccati. Gli slot consumati nel
ring vengono svuotati, evitando riferimenti trattenuti dalla coda.

> **Proposta** — I limiti iniziali sono budget operativi configurabili, non
> parametri persistenti o soglie dello scheduler. La generazione usa l'intervallo
> fixnum positivo e rifiuta l'esaurimento senza riciclo.

## Integrazione e verifica

Il modulo non crea thread, esegue callback o chiama I/O. Un pool potrà usare le
stesse primitive per assegnare tratti a worker diversi. Lista delle Serie pronte,
risvegli, retry, deadline, crescita adattiva dei pool, pubblicazione e conferme
restano responsabilità dei componenti successivi. Un'accettazione non notifica
automaticamente un worker: queste primitive non chiudono il protocollo contro
i risvegli persi e non attestano fairness o latenza del database.

Il [metodo registrato prima delle campagne](code-writer-metodo.md) comprende
oracoli indipendenti, produttori e consumatori sovrapposti su thread reali,
isolamento tra due Serie, due letture C1, copertura con denominatore intero,
mutazioni e misure delle allocazioni. La
[tabella delle decisioni](code-writer-decisioni.md) distingue gli input
rifiutati dai controlli difensivi del protocollo.

La campagna locale del 9 ottobre 2026 ha superato 17 test nominali, inclusi
9 × 1200 azioni confrontate con liste FIFO indipendenti, tre ondate di 144
messaggi su tre producer e due consumer riutilizzati, e calcolo CRC sui buffer
di due Serie con intervalli sovrapposti. Il primo run ha osservato 34.065 tick
di sovrapposizione, con timer da 1.000.000 tick/s, fuori dai semafori; non è una
misura di scalabilità o dell'applicazione dei messaggi nel motore.

La copertura SBCL raw conta 321/391 espressioni e 58/76 esiti di ramo:
package 0/1 e 0/0, queue 131/172 e 22/32, writer 190/218 e 36/44.
Il denominatore comprende dichiarazioni, default e guardie difensive non
marcati. Non si dichiara MC/DC completa e non si approva una deroga C1.
L'inventario dei non marcati conserva 1 forma del package; nella coda,
21 forme di definizione/default e 20 forme nei cinque errori difensivi,
con due esiti del tipo `or` del DEFSTRUCT e otto esiti difensivi; nel writer,
otto forme di definizione e 20 forme nei cinque errori difensivi, con otto
esiti difensivi. I default della factory sono esercitati dall'API ma restano
non marcati nel report. Nessun ramo di input o operativo strumentato risulta
scoperto; le condizioni difensive non sono tutte provate al falso.
Le mutazioni hanno una baseline compilata e riuscita; tutti gli otto mutanti
compilano e vengono rilevati dopo lo smoke, con log integrali conservati.

Le due fixture di allocazione (capacità e quantum 1 oppure 32) hanno cinque
repliche ciascuna di 4096 cicli completi: zero byte di heap osservati in tutti
i dieci campioni e sink esatti. Il self-test del contatore registra baseline
zero e controllo positivo di 16.777.472 byte. Le misure sono seriali, su input
preallocati, con carico esterno non controllato; non costituiscono una prova
assoluta di assenza di allocazioni o di prestazioni del pool.

Le letture locali non trovano difetti residui nel contratto delle primitive.
Il cleanup del solo harness, dopo un errore, usa terminate e join con limite
di un secondo senza attestare una postcondizione thread-dead. Nei run riusciti
tutti i worker restituiscono `:ok` tramite join; il limite del percorso di
errore resta dichiarato. Nessuno stato di requisito viene promosso.

La [verifica integrata isolata](../../spikes/results/2026-10-09-writer-queue/verifica-integrata.lisp)
ha superato 168 test dei moduli e i dieci spike con sorgenti stabili.
Il [catalogo degli artefatti](../../spikes/results/2026-10-09-writer-queue/catalogo.lisp)
conserva anche il primo controllo integrato: comandi riusciti, ma record
`SOURCE-CHANGED` per modifiche concorrenti dell'ordinamento radix, estranee
al modulo execution. La copia isolata contiene la base `10576a0` più i file
di questo componente; la verifica del catalogo e dei link segue la conservazione.

Requisiti: REQ-CON-001/002/004/005, REQ-AFF-008. Invarianti: INV-P1/P2/P5/P6,
INV-A8, INV-V4. Questa è una parte del runtime, distinta dal pool adattivo
REQ-THR-001 e dalle prestazioni integrate di REQ-CON-003.
