# ADR-0017 — Piattaforma di riferimento e primitive di I/O

- **Stato:** Accettata; **punto 5 precisato da [ADR-0045](0045-modello-di-esecuzione.md)**: ogni chiamata bloccante (scritture nei log comprese) è un compito del pool di I/O; una lettura che manca la cache migra ripartendo dall'inizio.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-19
- **Riferimenti:** [architettura](../architettura.md#thread-pool), RSK-11, RSK-16

## Contesto

La specifica fissa l'hardware ma non il sistema operativo; lo sviluppo avviene su macOS/ARM64;
il vincolo «solo Common Lisp» esclude librerie C per l'I/O.

## Decisione

1. **Piattaforma di riferimento:** Linux x86-64. I benchmark e i criteri di uscita si misurano
   lì. macOS/ARM64 è piattaforma di sviluppo supportata; le misure di I/O su macOS sono
   indicative.
2. **Chiamate di sistema** tramite i contrib di SBCL (`sb-posix`, `sb-unix`) e `sb-alien` verso
   la libc del sistema: è Common Lisp che invoca il sistema operativo, non codice foreign del
   progetto. Nessuna libreria C esterna.
3. **Flush durevole:** `fdatasync` su Linux; `fcntl(F_FULLFSYNC)` su macOS. Un'unica funzione
   `durable-flush` nel modulo `io` nasconde la differenza; le directory si sincronizzano con
   `fsync` dopo creazione/rinomina di file.
4. **Letture:** `pread` posizionali in buffer riutilizzati dell'arena di cache; nessuna
   mappatura in memoria (evita il doppio conteggio imprevedibile e le page fault nei reader).
5. **Modello di I/O:** bloccante, eseguito da un **pool di I/O** separato dal pool di calcolo
   ([ADR-0011](0011-thread-pool-dinamico.md)): i worker di I/O possono essere molti più dei
   core, perché passano il tempo in attesa. I/O asincrono (io_uring) non è adottato: con il
   vincolo di solo Common Lisp costerebbe un'interfaccia complessa senza che la fascia alta
   dei target lo richieda ([stime](../valutazione/stime-ordine-di-grandezza.md#letture-puntuali)).
6. **Fault injection:** tutte le scritture, letture e flush passano dal modulo `io`, che in
   test è sostituibile con un'implementazione che simula crash e scritture parziali.

Pattern: thread pool di I/O bloccante con pread/fdatasync (RocksDB, PostgreSQL).

## Conseguenze

- Un solo modulo conosce il sistema operativo.
- La correttezza della durability su macOS dipende da `F_FULLFSYNC`: i test la usano.
- Il numero di worker di I/O è un parametro del controllore, non del codice.

## Alternative considerate

- *mmap dei segmenti:* letture senza copia, ma page fault dentro sezioni di lettura (trattengono
  l'epoca), doppio conteggio della memoria e comportamento diverso per piattaforma.
- *io_uring:* massima concorrenza di I/O; rinviato finché una misura non lo richieda; un
  eventuale ADR futuro lo aggiungerebbe dentro il modulo `io` senza toccare il resto.

## Valutazione

- Verifica: SPK-03 (flush), SPK-05 (pread concorrenti, GB/s in scansione).
- Rivedere se: il target «GET NVMe» di fascia alta non è raggiungibile con il pool di I/O.
