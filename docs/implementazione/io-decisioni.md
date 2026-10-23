# Decisioni del confine I/O

Inventario COD-54; test in [`tests/io/`](../../tests/io/), con REQ nel nome.
Non è attestazione MC/DC o qualifica C1.

| Predicato | Casi |
|---|---|
| `nome-file`: vuoto oppure NUL | entrambi rifiutati, nome valido: `REQ-STO-003-open-preflight-and-errors` |
| `nome-file`: directory e componente non root | directory normale, symlink con slash finale, file normale: `REQ-STO-003-native-no-follow-file-kinds-and-cloexec`; root non normalizzata |
| `nome-file`: append e suffisso `.tmp` valido | readonly senza suffisso, append valido, troppo corto e suffisso errato: test preflight |
| `apri`: max-transfer nell'intervallo e capienza positiva | 0, oltre massimo, capienza zero, valido: test preflight |
| `progresso`: intero e 1 ≤ n ≤ remaining | 1/short/completo, 0/negativo/eccessivo, nil/double/keyword: `REQ-AFF-008-invalid-progress-and-eof`, short append/pread |
| `chiudi`: stato non closed | close normale, errore EINTR/EIO, ritorno impossibile, close ripetuta: `REQ-AFF-001-close-once-even-eintr`, `REQ-AFF-001-invalid-close-result-and-closed-reader` |
| `fallisci`: operazione read | read non mutante, write/flush faulted: test errori read/write e frontiera flush |
| `native-open`: directory oppure file regolare | directory corretta, file corretto, directory usata come file, FIFO, file usato come directory: test tipi/symlink/CLOEXEC |

## Decisioni semplici e corrispondenze

- Progresso per puntatore/offset: `REQ-STO-003-short-pread-positional-no-state-write`.
- Capienza e transfer budget controllati prima della syscall; uguaglianza ammessa,
  zero byte senza syscall: `REQ-AFF-008-preflight-budget-and-zero-length`.
- Posizione scritta aggiornata soltanto dopo progresso positivo, durevole soltanto
  dopo flush riuscito: short append e `REQ-AFF-001-flush-error-preserves-durable-frontier`.
- Errore write/flush mai ritentato, incluse interruzioni: test errori EIO/ENOSPC/EINTR.
- Directory usa fsync e il file flush forte; fallimento della directory faulted:
  `REQ-AFF-001-directory-flush-dispatch-and-invalid-return`,
  `REQ-AFF-001-directory-failure-and-empty-file-flush`.
- Errno immediato e cleanup primario/secondario preservati:
  `REQ-AFF-004-native-errno-and-cleanup-provenance`.
- FD privato non inizializzato rifiutato prima della syscall:
  `REQ-AFF-004-invalid-private-descriptor-before-syscall`.

## Copertura da qualificare

Il ramo finale delle transfer loop non può ricevere byte esterni che lo rendano
vero: ogni iterazione avanza di almeno un byte verificato, il tetto è il numero
dei byte e la scansione termina quando il residuo è zero. Il controllo finale
della frontiera durevole è difensivo contro un difetto interno. Tipo mode e ABI
impossibili nell'ambiente corrente rimangono guardie attive.

I dati sb-cover comprendono definizioni/proclamazioni e copie inline dei wrapper
nativi. I rami nativi di altri OS, il guasto di fstat tra open/validazione e tutte
le eccezioni difensive richiedono ancora analisi e revisione per C1. La prova
diretta del cleanup e i callback di open non attestano tutti i guasti del kernel.
Nessuna esclusione automatica dal denominatore e nessuna certificazione completa.
