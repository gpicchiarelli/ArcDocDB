# Checkpoint completo dal recovery ACTIVE

`arcdocdb.recovery.checkpoint:crea-checkpoint-da-active(recovered, active, stamp, …)`
collega [ACTIVE recuperato](active-recuperato.md) e
[nuovo ACTIVE preparato](inizializzazione-active.md) al
[piano CONTROL](checkpoint-control.md). Applica
[ADR-0040§3](../adr/0040-manifest-a-record-unico.md#3-riconciliazione-al-riavvio)
e [ADR-0041§4](../adr/0041-multiserie-segmenti-autosufficienti.md#4-recovery),
senza cambiare formati o decisioni architetturali.

## Contratto e composizione

Restituisce un `checkpoint-control` esistente: si consulta con le sue query,
si prepara con `prepara-checkpoint-control` e si pubblica con
`pubblica-control-da-active(prepared, recovered)`. Il payload EDIT completo
viene derivato dalle fonti, senza ricostruzione manuale del chiamante.
Nessun I/O, prenotazione ID, nuovo CSN o secondo gettone di pubblicazione.
Lo stamp u64 è l'ordinale fornito dal controller.

Il recovery è esclusivo. Il controller mantiene CONTROL, vecchio ACTIVE,
nuovo ACTIVE e namespace autorevoli, congelati e aperti fino alla
pubblicazione. Il nuovo ACTIVE deve appartenere alla **stessa identica vista**
del CONTROL e restare al solo header durevole. Controlli ripetuti al ritorno.
L'autorità delle decisioni resta nel contratto del lettore ACTIVE usato;
è disponibile il [lettore legato all'Archivio](decisioni-recuperate.md).

L'ID nuovo proviene dal suo header verificato: deve essere almeno il
high-water precedente e `next-id = id + 1` deve essere u64. Nessun wrap,
riuso o nuovo sentinel su disco. Il controller riserva e prepara l'ID.

Lo stato conserva ogni CLOSED con lunghezza ed esiti, ogni REMOVED, il
vecchio ACTIVE chiuso a **P esatto** con tutti e soli gli esiti derivati,
il nuovo ACTIVE preparato e il high-water successivo. CLOSED/REMOVED sono
ordinati per ID unsigned u64, gli esiti per TXID. Zero presente e bit alti
restano significativi; le tabelle sorgenti restano immutabili.

Le sezioni private riusano serializer ACTIVE e `scrivi-valore-edit`.
Il builder CONTROL canonico aggiunge header/EDIT/SEAL e ricostruisce il
manifest. Una verifica finale confronta transizione, P, count e ogni esito
derivato. Nessun piano parziale. L'atomicità resta la rinomina del control
log; conferma dopo fsync del parent del publisher esistente. La sola
costruzione o preparazione non rende il piano autorevole.

## Budget e costi

| Configurazione | Default |
|---|---:|
| `max-payload` | 16 MiB, entro tetto metadata e capienza record v1/v2 |
| `max-segmenti` | 65.536 menzioni, incluso il nuovo ACTIVE |
| `max-esiti` | 65.536 coppie totali nei CLOSED, nuova chiusura inclusa |
| `budget-workspace` | 64 MiB di payload degli array propri del builder |

Con C = CLOSED finali, R = REMOVED, E = esiti dei vecchi CLOSED e D = esiti
derivati: `Bc = 20C + 16(E+D)`, `Br = 8R`, `Pedit = 24 + Bc + Br` byte.
Gli array propri creano cumulativamente
`Pedit + Bc + Br + 8(C+R+E)` byte, comprese le chiavi temporanee di ogni
CLOSED, senza supporre un recupero immediato del GC. Sono esclusi
oggetti/header Lisp, boxing, lavoro interno di `SORT`, builder CONTROL,
manifest ricostruito e GC: **non è un tetto RSS**. Il controller contabilizza
anche questi costi e i costruttori simultanei. Sezioni e payload temporanei
non restano nel piano restituito.

Dimensioni, `1 + C + R` menzioni, esiti, capienza v1/v2 e workspace sono
controllati prima degli array. Nessun metadato scartato per rientrare nei
budget. Zero per esiti è valido se non ve ne sono; servono comunque nuovo
CLOSED e nuovo ACTIVE. Sono budget del compito, non nuovi limiti del database.
Cicli su cardinalità note e array finiti; `SORT` su copie locali del percorso
di apertura. Nessun nuovo lock o scrittura condivisa fra Serie. Nessuna
misura di heap, latenza, RSS o throughput dichiarata.

## Decisioni ed errori

`invalid-argument` per vista diversa, ID riusato o configurazione payload
invalida; `resource-exhausted` per ID esauriti, next-id non rappresentabile
o budget insufficienti; `invariant-violation` per incoerenze interne.
Condizioni originali di capacità, codec, replay e transizione propagate;
nessun handler generico, retry, close, rollback, eliminazione o troncatura.

| ID | Decisione composta / confine | Casi richiesti, aperti |
|---|---|---|
| CRB-D01 | payload oltre budget caller oppure capienza versione | ciascuna vera, entrambe false; confini v1/v2 |
| CRB-D02 | EXTRA presente e già nella tabella | NIL, zero, ID nuovo, duplicato |
| CRB-D03 | spazio per chiave e tipo u64 | ciascuna falsa, entrambe vere; cardinalità mutata |
| CRB-D04 | esito presente e CSN u64 | assente, tipo errato, zero e high bits validi |
| CRB-D05 | chiusura CLOSED, P e count esatti | ogni campo discordante separato, tutti esatti |
| CRB-D06 | esito derivato presente e CSN uguale | assenza, discordanza, zero presente |
| CRB-G01 | fonti canoniche e lifetime | vista diversa, FD chiusi, nuovo ACTIVE avanzato/faulted |
| CRB-G02 | next-id e budget prima degli array | ID esaurito/sotto/al/sopra high-water; ogni budget esatto/insufficiente |
| CRB-G03 | conservazione e ordine | zero/u64 alto; nessun/molti CLOSED e REMOVED; esiti coalescenti; ACTIVE a inizio/mezzo/fine |
| CRB-G04 | consumo e postcondizioni | ritorni codec discordanti, fonte mutata, piano intero e nessun I/O |

Le [evidenze locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-recovery-checkpoint/README.md)
riguardano compilazione e controlli statici. Qualifica C1, revisione
indipendente, casi funzionali/FI e misure dedicate restano aperti.
Riconciliazione fisica, indici/orizzonte CSN, dimenticanza
delle decisioni e gate del Recovery Manager restano da integrare.

Il [lettore CLOSED e il controllo dell'insieme](closed-recuperato.md) sono
ora disponibili con qualifica dedicata aperta. L'ingresso aggiuntivo
`pubblica-control-con-closed` verifica i vecchi CLOSED prima di delegare al
publisher ACTIVE; questo builder e il formato del piano restano invariati.
