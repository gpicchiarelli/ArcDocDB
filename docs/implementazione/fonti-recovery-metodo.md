# Acquisizione posseduta dei segmenti per il recovery

Metodo preregistrato il 2026-10-17, prima del codice e delle prove.
Incremento C1 su ADR-0040 e COD-37; nessun nuovo formato persistente.

`apri-fonti-recovery(manifest, directory, …)` raccoglie una sola volta il
namespace completo con il planner directory e acquisisce in sola lettura
**tutti e soli ACTIVE/CLOSED**, in ordine crescente u64. Richiede piano
`:ready`: DEGRADED/FAULTED sono rifiutati prima della prima apertura. Il
risultato possiede i child; parent, manifest e namespace restano del controller.
Il namespace deve restare esclusivo e stabile dall'inventario al termine
dell'acquisizione; niente cancellazione asincrona nella finestra di ownership.
Le forme temporanee vive sono lette con il loro nome `.seg.tmp`, senza rinomina.
Le anomalie, REMOVED e temporanei orfani restano soltanto nel piano restituito.

Le query restituiscono ID, stato ACTIVE/CLOSED, forma, capacità readonly
prestata e dimensione osservata dal suo stesso FD. Il chiamante non chiude i
child separatamente e termina tutti i reader prima di `chiudi-fonti-recovery`.
La chiusura è idempotente, invalida prima il set e tenta ogni child una sola
volta anche dopo guasto. Un errore aggregato conserva la condizione primaria
originale (oppure NIL), la prima condizione di close e il numero di close
fallite. Nessun errore restituisce un set parziale; cleanup riuscito propaga
la condizione primaria per EQ. Uscite estranee al contratto tentano cleanup,
senza sostituire la causa originale. Nessun retry dopo EINTR.

Cinque budget dell'inventario mantengono default e semantica; `max-transfer`
e `max-file-bytes` mantengono quelli I/O. `max-total-file-bytes` (default
4 GiB−1, intero `index`, zero ammesso) limita la somma degli EOF vivi:
uguaglianza valida, sottrazione prima dell'addizione, nessun wrap. Ogni
configurazione e callback necessaria è verificata prima dell'enumerazione.
Il child che supera il totale entra prima nel set privato per essere chiuso.
Header, CRC, prefisso valido, radici/CSN, riconciliazione fisica e ammissione
restano responsabilità successive. Nessuna scrittura, eliminazione, flush,
prenotazione ID, lock fra Serie o creazione di worker. Percorso freddo con
allocazioni; O(N) aperture sequenziali limitate dal numero di segmenti vivi.

## Decisioni e prove previste

| ID | Decisione / casi di indipendenza |
|---|---|
| FRS-D01 | `:ready` oppure rifiuto DEGRADED/FAULTED prima di open |
| FRS-D02 | Stato ACTIVE/CLOSED ammesso; REMOVED/UNKNOWN mai aperto |
| FRS-D03 | Forma FINAL/TEMPORARY coerente con USE/RENAME; FI di ogni incoerenza |
| FRS-D04 | Totale EOF <= budget, esatto/uno sotto/zero, high bits e niente wrap |
| FRS-D05 | Child presente durante cleanup; primo errore conservato, tutti tentati |
| FRS-D06 | Primaria presente o assente e close fallita o riuscita; quattro combinazioni |
| FRS-D07 | Set aperto/chiuso; query indice 0/ultimo/fuori range |

Suite dedicata: fixture EDIT v1/v2, oracolo dichiarato dei soli file vivi,
ID zero/bit63/max-u64, ordine fisico permutato, input riusati e alias vietati;
contatori esatti di enumerazione/aperture/close. Saturazione di tutti gli
otto budget, callback mancanti e EOF incompleto. Guasto in ogni posizione
di open/metadata/identità, close singola/multipla e parent invalidato;
condizioni originali e cleanup verificati. File nativi byte per byte,
parent rinominato e sostituito, symlink rifiutato e descrittori riutilizzabili.
Quattro thread con backend privati, gate e join limitati, nessun override globale.
Copertura nativa grezza e mutanti compilabili delle decisioni/budget/cleanup;
nessuna esclusione approvata o attribuzione ai moduli dipendenti.

Due letture dell'autore con lista C1, registrate separatamente dai test;
non sostituiscono il secondo revisore indipendente. Sorgenti congelati e
committed prima dei run registrati, compilazione rigorosa e `make check`.
Ogni fallimento e variante resta nelle evidenze originali; conservazione
con collector comune e inventario chiuso. Qualifica C1/MC/DC complessiva,
recovery completo e prestazioni restano aperti.

REQ-REC-001/002/004, REQ-AFF-001/004/008/017/018, REQ-VAL-001.
INV-A7/A8/A9/A10/A11, INV-P6.
