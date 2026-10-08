# Confine I/O

Primitive POSIX in Common Lisp/SBCL: creazione esclusiva, lettura posizionale,
append, flush durevole e chiusura. Realizzano il confine richiesto da
[ADR-0017](../adr/0017-piattaforma-e-io.md), con errori secondo
[ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md). Il proprietario le
esegue nei compiti del pool I/O ([ADR-0045](../adr/0045-modello-di-esecuzione.md)).
Il pool e il motore delle transazioni restano moduli da integrare.

## Contratti

| API | Risultato |
|---|---|
| `apri-lettura` | capacità di file regolare readonly, pread concorrenti su buffer distinti |
| `crea-temporaneo` | nuovo `.tmp` con O_EXCL, O_APPEND e permessi 0600; nessuna riapertura in scrittura |
| `apri-directory` | capacità di directory per fsync |
| `leggi-esatto` | riempie `[start,end)` da offset esplicito; restituisce end, senza modificare il cursore |
| `append-esatto` | completa il range e restituisce posizione scritta; non attesta commit/durability |
| `durable-flush` | file: fdatasync Linux, F_FULLFSYNC macOS; directory: fsync; avanza frontiera dopo successo |
| `chiudi` | invalida la capacità prima di una sola close; chiamate successive sono no-op |
| `stato-file` | open, faulted o closed |
| `mode-file` | modo immutabile input, append o directory; nessun descrittore esposto |
| `verifica-capienza-append` | verifica totale del gruppo e massimo chunk prima della prima write |
| `posizione-scritta`, `posizione-durevole` | frontiere del nuovo file, osservate dal proprietario |

`file-io` è una capacità con descrittore privato. Il chiamante possiede il
namespace, impedisce modifiche esterne e mantiene vivo il descrittore fino al
termine di tutti i reader. Append e flush dello stesso file hanno un solo compito
proprietario. Non c'è un lock globale, un thread per Serie o stato mutabile tra
file/Serie. Un reader riuscito o fallito non scrive nello stato della capacità.
La chiusura richiede che i reader siano terminati: il protocollo dei riferimenti
e la quarantena del segmento spettano al proprietario.

Le letture restituiscono byte al codec, che deve verificarne CRC e identità prima
di una risposta al client. Queste API non pubblicano indici e non confermano lotti.
La prova su due lotti SEAL dimostra il collegamento tra I/O e codec, non il commit
integrato del motore. Nessuna rinomina, cancellazione o troncamento è offerta qui.

## Guasti e frontiere

Ogni syscall con progresso positivo avanza esattamente di quel numero di byte.
Un ciclo ha al massimo una iterazione per byte richiesto. Completare short I/O è
distinto dal ritentare un errore: **nessun errore viene ritentato**, neppure EINTR.
Zero write, EOF e ritorni impossibili sono guasti espliciti.

Write/flush falliti marcano il file faulted prima di segnalare `io-fault`.
Ogni append/flush futuro è rifiutato senza syscall; la frontiera durevole resta
quella dell'ultimo flush riuscito. Il controller deve propagare l'evento allo
stato e alle metriche della Serie/Archivio: quel collegamento resta da integrare.
Non si ignora la condizione e non si conferma un lotto dopo l'errore.

La condizione espone operazione, errno e progresso noto. La chiusura non viene
ritentata perché il numero del FD potrebbe essere già riutilizzato. Un fallimento
di fstat durante l'apertura chiude una sola volta il descrittore non pubblicato;
sono conservati sia l'errore primario sia un eventuale errno di cleanup.

## Confini e risorse

I buffer sono octets specializzati. Sono esclusivi in lettura e stabili durante
append. Range, budget e offset vengono controllati prima della prima syscall.
Un rifiuto di configurazione/capienza non mette il file in guasto. Tutti i
puntatori e i pin rimangono dentro `src/io/` e non sono esportati dalle API.

> **Proposta** — Budget massimo per trasferimento 256 MiB, abbassabile per capacità;
> capienza iniziale dei nuovi file 4 GiB−1, configurabile. Posizioni/capienze sono
> fixnum non negativi, fino a `most-positive-fixnum`, e restano entro off_t a 64 bit.
> È un limite dell'interfaccia in memoria, non una modifica dei formati persistenti.
> Evita boxing/bignum nell'aritmetica del percorso caldo. I segmenti restano soggetti
> al limite v2 di ADR-0048; la capienza del singolo log deve essere configurata dal
> suo controller. Nessun rollover viene deciso da questo modulo.

O_NOFOLLOW rifiuta i symlink del componente finale e CLOEXEC impedisce l'eredità
del descrittore. Per le directory si rimuove il separatore finale prima di open,
così non aggira O_NOFOLLOW. Gli antenati del percorso devono essere controllati
dal controller: non si introduce qui un protocollo openat per namespace ostili.
Directory/FIFO non possono diventare segmenti readonly; O_NONBLOCK evita di
bloccarsi su un FIFO prima che fstat lo rifiuti.

Il backend iniettabile è una tabella immutabile di sei funzioni: open, reader,
writer, flush file, flush directory, close. Riceve vettori/intervalli, mai SAP.
I callback sono codice fidato, segnalano syscall-error per errno e rispettano
durata e proprietà dei buffer. `nil` seleziona il percorso nativo, con le due
chiamate alien inline; nessun C/C++/Rust o libreria del progetto fuori da Lisp.

## Prove

[Metodo](io-metodo.md), [decisioni](io-decisioni.md) e
[catalogo](../../spikes/results/2026-10-08-io/catalogo.lisp).

18 nuove prove comprendono short I/O, un byte per passo, EOF parziale, EIO,
ENOSPC, EINTR, frontiere, budget, chiusura ambigua, errno del cleanup, tipi di file,
symlink con separatore finale, CLOEXEC, pread concorrenti e due lotti SEAL v1/v2
scritti con un solo flush. Le 10 mutazioni mirate sono rilevate; nessun warning
o style warning nella compilazione del prodotto, lint senza violazioni.

```sh
make test lint
sbcl --noinform --no-userinit --script tools/io-bench.lisp --self-test
sbcl --noinform --no-userinit --script tools/io-bench.lisp --bench
sbcl --noinform --no-userinit --script tools/foundation-coverage.lisp --report /tmp/io-cover/ io
sbcl --noinform --no-userinit --script tools/foundation-mutation.lisp --run /tmp/io-mutants-new/ io
make check
```

Requisiti: REQ-STO-003, REQ-AFF-001/002/004/008, REQ-FOR-003 e REQ-VAL-001.
Invarianti: INV-A1/A2/A3/A4/A8/A9, INV-P6, INV-X3. Il loro stato sul motore
rimane distinto da queste prove locali; nessuna promozione automatica.

## Prestazioni e limiti delle evidenze

La [prima misura](../../spikes/results/2026-10-08-io/benchmark-iniziale.lisp)
ha rilevato heap sulle chiamate native. Le chiamate alien inline e l'aritmetica
fixnum hanno eliminato quelle allocazioni senza ridurre safety o controlli.
La [campagna senza allocazioni](../../spikes/results/2026-10-08-io/benchmark-zero-heap.lisp)
riporta zero byte heap in tutti i cinque campioni di ogni percorso scelto.
I campioni originali restano conservati; `io-bench` stampa i risultati e fallisce
se una campagna riuscita rileva heap.

Misure locali Apple M4/ARM64, SBCL 2.6.9, safety 3, un worker, mediana di cinque
campioni: pread 2 KiB con cache OS calda circa **1,34 M/s**; append 2 KiB senza
flush per operazione circa **206 k/s**; append 64 KiB + flush forte circa **269
gruppi/s**. Non sono prestazioni del database, I/O NVMe sostenuto o latenza delle
richieste. Il costo di flush dipende da filesystem/dispositivo/carico locale;
non si deduce P99 da questa campagna. Zero heap vale per i percorsi riusciti
misurati, non per errori, apertura o inizializzazione.

Due letture hanno controllato ABI/formato/errno e poi durata dei buffer/FD,
frontiere, bounded loops e assenza di stato tra Serie. Restano revisione
indipendente, qualifica C1, prova nativa su Linux x86-64, fault injection del
motore integrato e guasti reali del supporto. La copertura conserva definizioni,
copie inline e guardie difensive nel denominatore; non equivale a MC/DC.
Un flush riuscito richiede comunque che OS, filesystem e supporto rispettino
la garanzia dichiarata: non è una prova contro un dispositivo che mente.

Costanti native confrontate con gli header installati e con le fonti primarie:
[Apple XNU fcntl.h](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/sys/fcntl.h),
[Linux UAPI fcntl.h](https://github.com/torvalds/linux/blob/master/include/uapi/asm-generic/fcntl.h).
