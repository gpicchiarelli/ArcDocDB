# Lotti WAL e group commit

Implementazione del percorso comune di [ADR-0037](../adr/0037-lotto-sigillato.md):
formazione in memoria, SEAL, write di più lotti, un flush. Solo Common Lisp/SBCL,
safety 3. [Metodo](wal-metodo.md), [decisioni](wal-decisioni.md),
[evidenze](../../spikes/results/2026-10-08-wal/catalogo.lisp).

## Preparazione senza I/O

`crea-lotto` prealloca buffer, offset u32 e scratch SEAL. `aggiungi-record` copia
con il codec e riserva sempre spazio per SEAL; non assegna il CSN del lotto.
`sigilla-lotto` riceve il CSN appena preso dal chiamante, la posizione pianificata
e la frontiera durevole osservata tramite l'evento del precedente flush.
Il [registro CSN dell'Archivio](csn.md) e le [code del writer](code-writer.md)
sono componenti distinti; il controller che li collega al lotto resta da integrare.

La chiusura ristampa PUT/tombstone ordinari e EDIT, preserva TXID prepared,
OUTCOME e DECISION, ricalcola CRC header e CRC aggregato, scrive SEAL. Il buffer
privato non è esportato ed è immutabile da sealed fino al riuso. Il file-id nel
SEAL è codificato una volta all'inizializzazione: anche u64 massimi non causano
boxing sul percorso misurato. I valori CBOR, i contratti e la semantica degli
EDIT/DECISION sono validati dal chiamante; questo modulo costruisce la cornice.

> **Proposta** — Budget iniziali: 256 KiB/1024 record per lotto, tetti configurabili
> 64 MiB/65536 record; 64 lotti/64 MiB per gruppo, massimo 1024 lotti. Sono limiti
> delle risorse preallocate, non nuovi limiti del formato o soglie dello scheduler.

## Compito I/O

`crea-log-io` lega una capacità append già aperta a un log/versione/file-id.
La capacità è posseduta esclusivamente da quel log: non può avere un secondo
wrapper né ricevere append/flush dirette durante la vita del wrapper.
`aggiungi-lotto` verifica identità, contiguità e budget; un CAS sulla proprietà
del lotto impedisce di accodarlo in due gruppi. `chiudi-gruppo` prepara uno
snapshot non vuoto per il pool I/O.

| Operazione | Effetto |
|---|---|
| `scrivi-gruppo` | CAS del log, preflight di tutti i budget/frontiere, N append, stato written |
| `sincronizza-gruppo` | CAS written → flushing, un flush, N stati durable, rilascio del log |
| `esegui-gruppo` | entrambe le fasi nello stesso compito I/O |
| `coperto-p` | verifica la copertura dei byte: written per async, durable per group/strong |
| `annulla-gruppo` | rilascia i lotti di un gruppo building/ready ritirato dallo scheduler |
| `riusa-gruppo`, `riusa-lotto` | riuso solo dopo completamento durevole e fine dei consumatori |

Un secondo gruppo sullo stesso log riceve `resource-exhausted` senza syscall,
attesa o spin. CAS e stati sono locali al log; Serie indipendenti non condividono
scritture o lock. Write e flush appartengono al **pool I/O**, mai al writer nel
pool di calcolo. Lo scheduler dovrà conservare proprietà e durata dei messaggi;
non è implementato da queste primitive.

Il preflight controlla capienza dell'intero gruppo, massimo trasferimento,
offset scritto iniziale e frontiera storica di ogni SEAL. Un rifiuto libera la
proprietà I/O senza scrivere. Un guasto write/flush marca log, gruppo e lotti
coinvolti faulted; conserva la proprietà per impedire nuovi gruppi, non ritenta
e non avanza la frontiera durevole. L'evento verso la Serie/Archivio rimane da
integrare al confine worker.

`coperto-p` **non pubblica né conferma**: la pubblicazione ordinata nell'indice,
la salute della Serie, gli esiti 2PC e la conferma al client sono controlli del
controller. Un lotto precedente già durable conserva quella copertura anche
se un gruppo successivo fallisce; ciò non autorizza conferme dopo il guasto.
Async è rifiutato per control/multiserie; gli obblighi PREPARE/COMMIT richiedono
comunque i controlli del Transaction Manager.

## Durata, riuso e guasti

Non si può riusare un lotto ancora posseduto da un gruppo. Dopo il flush,
il controller attende la fine dei consumatori, riusa il gruppo e poi i lotti.
Annullare un gruppo richiede che sia ritirato dallo scheduler: non annulla un
compito già in volo. I riferimenti esterni e la pubblicazione degli eventi
devono rispettare un protocollo di durata; gli stati non sostituiscono quel protocollo.

Il punto di atomicità è SEAL; la formazione lo prepara, write/flush completano
la sua persistenza. Nessuna rinomina, eliminazione, riapertura o troncamento.
Header e offset iniziale sono responsabilità del Segment Manager; la prova
nativa usa header v1/v2 reali e parte da offset 64. Per i log di controllo
si applica anche la decisione sul loro header prima della pubblicazione del file.

## Prove e limiti

19 test WAL, 330 prefissi di crash v1/v2, file reali con F_FULLFSYNC e directory
fsync, oracle dei codec/recovery, errori EIO/ENOSPC/EINTR, concorrenza di gruppi,
flush concorrenti resi deterministici con semafori, budget e riuso. Le 12 mutazioni
mirate sono rilevate; un errore di compilazione non conta come mutazione rilevata.
Tentativi falliti, log delle copie mutate e copertura grezza restano nel catalogo.

Le misure locali comprendono formazione di otto record da 2 KiB, SEAL, group I/O
**simulato** e riuso: circa 37 mila gruppi/s, con zero byte heap nei cinque campioni,
anche con CSN e file-id u64 massimi. Non sono throughput del database, flush su
NVMe o latenza delle richieste. Hardware, carico e hash sono nel record della campagna.

Requisiti: REQ-WAL-002/003/005/006, REQ-AFF-001/008/009, REQ-FOR-003, REQ-VAL-001.
Due letture: formato/CRC/TXID/frontiere, poi proprietà/CAS/risorse/riuso. Restano
revisione indipendente, copertura C1 completa/MC/DC, Linux nativo, controller,
CSN, code/pool, pubblicazione/ack e fault injection del motore integrato.
Nessun requisito del motore viene promosso automaticamente da queste prove locali.
