# SPK-03 — Append e flush a lotti

> **Proposta** — Esperimento di Fase 0, limitato al costo di append e flush e alla
> verifica degli octet. Questo spike non è il WAL di produzione.

## Domanda

Quanto costa `write` seguito da flush, per lotti di 1, 32 o 128 record di 2 KiB
e per 1, 4 o 16 file indipendenti sullo stesso dispositivo? Quale differenza si
misura fra `fsync` e la primitiva richiesta da
[ADR-0017](../../docs/adr/0017-piattaforma-e-io.md) (`F_FULLFSYNC` su macOS,
`fdatasync` su Linux), con un solo append e flush alla volta per file
([ADR-0037](../../docs/adr/0037-lotto-sigillato.md))?

## Metodo

Il codice usa soltanto Common Lisp, SBCL e il contrib `sb-posix`, senza dipendenze.
Il package è `arcdocdb.spk03`, con le API `(check)` e `(benchmark &key ...)`.
Politica di compilazione: `safety 3`, nessun `warning` né `style-warning` ammesso.

Un worker possiede il suo file, descrittore, buffer specializzato di octet e
campioni. I file sono aperti con `O_CREAT | O_EXCL | O_APPEND`, permessi `0600`.
`write` passa per `SB-ALIEN`, con il buffer pinned per la durata della chiamata.
Il codice completa le scritture parziali, ripete soltanto `EINTR` e rifiuta errori,
ritorni nulli e progressioni incoerenti. Il numero di interruzioni consecutive
è limitato. I descrittori vengono chiusi anche in caso di errore. Nessun flush
fallito produce fallback o retry. Una primitiva assente o esplicitamente
rifiutata come non supportata produce `:unsupported`, con il motivo;
gli altri errori fanno fallire l'esecuzione.

Ogni record contiene il numero del file e il numero assoluto del record, ciascuno
su 64 bit, poi un motivo dipendente da questi due numeri e dalla posizione.
Prima della partenza comune ogni worker esegue un lotto di warmup con la stessa
primitiva sul proprio file; questo lotto resta nel file e viene verificato,
ma non entra nei campioni o nel throughput. Tutti i payload del caso sono
preparati prima del warmup. Il sink è la verifica integrale dopo la chiusura.
Dopo la chiusura del descrittore di scrittura, il file viene riaperto in lettura:
si controllano lunghezza esatta, numero di record e ogni octet. Preparazione dei
buffer e rilettura sono escluse dai tempi di `write` e flush; il throughput si
calcola sull'intervallo reale comune dei worker. I worker partono da una porta
comune, usata una volta per caso, poi non condividono contatori o lock per append
o flush. I casi della matrice si eseguono in successione; soltanto i file dello
stesso caso lavorano in parallelo. Append e flush di un file restano seriali,
secondo REQ-WAL-002; REQ-CON-003 e REQ-CON-005 guidano la proprietà indipendente;
REQ-AFF-001 guida gli errori espliciti.

Le misure restituiscono una plist con parametri, ambiente, conteggi effettivi,
octet verificati, tempi grezzi per worker, distribuzione minimo/mediana/P95/P99/
massimo e throughput. I percentili usano il rango superiore (`ceiling(p*n)`);
16 campioni non caratterizzano una coda P99. Il tasso di record sincronizzati
è indicato come throughput durevole soltanto per la primitiva richiesta da
ADR-0017, con i limiti dichiarati sotto.
`io-wall-seconds` è l'intervallo dal primo avvio I/O all'ultima conclusione;
`workers-wall-seconds` include avvio thread, apertura, warmup, porta e close;
`preparation-wall-seconds` e `verification-wall-seconds` sono separati;
`case-wall-seconds` include anche resoconto e pulizia, e
`matrix-wall-seconds` misura l'intera matrice, dopo il check.

Le directory nascono esclusivamente sotto `out/data/`, ignorato da Git, con
nome unico ottenuto da `mkdtemp`. Ogni file creato è registrato dal proprietario;
la pulizia elimina soltanto questi file e la loro directory esatta, senza
percorsi ricorsivi né rimozione di file preesistenti.

## Ambiente e primitiva macOS

Ambiente preparato: macOS 27.0.1 (26A434), ARM64, Mac16,3, 10 CPU logiche,
16 GiB RAM, SBCL 2.6.9. Il risultato riporta le informazioni esposte da SBCL;
il parent deve annotare supporto, filesystem e carico durante le misure.
La piattaforma di riferimento resta Linux x86-64 (ADR-0017).

`F_FULLFSYNC = 51` è stato verificato prima dell'esecuzione nel header Apple del SDK:
`/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/fcntl.h`,
riga 260, commento « fsync + ask the drive to flush to the media ».
Il contrib non esporta `ENOTSUP` su questo SBCL: la classificazione usa anche
il valore Darwin 45 verificato nel medesimo SDK, `sys/errno.h`, riga 144;
`EOPNOTSUPP` può avere valore diverso con UNIX03. Non si presume che i due
simboli siano sinonimi su macOS.
Il codice usa `sb-posix:fcntl` soltanto su Darwin. FFI e pinning seguono il
[manuale ufficiale SBCL](https://www.sbcl.org/manual/#Foreign-Function-Interface).

## Comandi

Dalla radice del repository, soltanto verifica rapida:

```sh
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-03-group-commit/run.lisp --check
```

Il runner trova `core.lisp` relativamente a `*load-truename*`, compila in
`out/core.fasl`, converte i warning in errori ed emette una sola s-expression
plist leggibile. Un errore produce uno stato esplicito e un exit code non nullo.
Le opzioni numeriche vengono analizzate senza il reader Lisp.

Misure da eseguire **dal parent, in serie con gli altri spike**:

```sh
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-03-group-commit/run.lisp --bench
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-03-group-commit/run.lisp --bench --files 1,4,16 --batches 1,32,128 --samples 32 --seconds 15
```

Default: `--files 1,4`, `--batches 1,32,128`, `--samples 16`,
`--record-bytes 2048`, `--seconds 15`. `--bench` è il default e include `check`.
`--flush fsync,fullfsync` su macOS o `--flush fsync,fdatasync` su Linux seleziona
le primitive. La memoria esplicita di buffer e campioni è limitata; parametri
oltre 256 MiB di memoria esplicita per caso sono rifiutati. Nessuna proprietà
di zero allocazioni viene dichiarata o misurata da questo esperimento.
Il budget temporale viene controllato fra operazioni e casi:
una syscall bloccata non viene interrotta e verifica/pulizia
possono superare il budget. È un budget di lavoro previsto, non una garanzia
di tempo reale.

## Limiti e risultato

**Verifiche eseguite il 2026-10-08:** `--check` completato con exit 0 e
`:status :ok`, compilazione senza warning/style-warning. Verificati short write
e offset, `EINTR` e suo limite, write nullo/sovradimensionato, errore EIO,
flush fallito senza fallback, stato `:unsupported`, close dopo errori write e
flush, open esclusiva fallita senza eliminare il file preesistente, rilevamento
di lunghezza e payload alterati (identificativo del file e del record inclusi).
La prova reale frammentata verifica 3 record, 6144 byte; la prova con
`F_FULLFSYNC` verifica altri 18432 byte, incluso un lotto di warmup.
Il comando assoluto funziona anche da `/tmp`, sempre con dati sotto questo spike.

È stata eseguita soltanto questa diagnostica breve della matrice, con un budget
di un secondo e due campioni per file, senza usare il benchmark predefinito:

```sh
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-03-group-commit/run.lisp --bench --files 4 --batches 1 --samples 2 --seconds 1 --flush fsync,fullfsync
```

Entrambi i casi restituiscono `:ok`: 8 flush misurati, 4 warmup e 24576 byte
verificati per caso. Il risultato è conservato localmente in
`out/diagnostica.lisp`, ignorato da Git. Una verifica del risultato ha confermato
una sola plist leggibile, conteggi coerenti, campioni della lunghezza attesa e
intervalli wall coerenti. `out/data/` è vuoto dopo il termine. Questi pochi
campioni servono a verificare il meccanismo, non a valutare i target di prodotto.
Le misure complete e i percentili rappresentativi restano da eseguire dal parent.

La rilettura passa per filesystem/page cache; non prova la persistenza dopo
perdita di alimentazione. Non sono modellati powercut, crash del sistema,
recovery, formato SEAL/CRC, indice, CSN, rotazione, sincronizzazione delle
directory, doppia scrittura, formazione dei lotti durante il flush e latenza
client. Lo spike copre la primitiva I/O e la sua disciplina. Le misure non
stabiliscono i minimi di ADR-0028; vanno ripetute sulla piattaforma di riferimento
con carico controllato. I check con iniezioni limitate coprono soltanto i rami
esercitati, non tutti gli errori di sistema o tutti gli interleaving.
Il solo completamento della syscall non verifica il comportamento del supporto
(FM-03). Il costo di flush e la coda sul dispositivo condiviso restano limiti
architetturali da misurare; questo spike non introduce serializzazione fra
Serie oltre la preparazione/partenza/aggregazione del singolo caso sperimentale.
Non emerge da queste prove un nuovo difetto architetturale dimostrato.
