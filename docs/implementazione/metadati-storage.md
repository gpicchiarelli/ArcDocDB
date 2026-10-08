# Metadati storage

Encoder e verificatori in memoria per header dei segmenti e contenuto di EDIT/DECISION.
Solo Common Lisp, SBCL, vettori specializzati, `safety 3`. Riferimenti:
[formati su disco](../formati-su-disco.md),
[ADR-0039](../adr/0039-cornice-unica-dei-record.md),
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md),
[standard di codifica](../affidabilita/standard-di-codifica.md).

## Ambito e responsabilità

Il modulo prepara e verifica byte. Non apre file, non applica EDIT a un manifest,
non decide transazioni e non modifica indici. La visibilità di un EDIT richiede il
lotto SEAL applicabile; la durability di DECISION richiede il protocollo e I/O del
proprietario del log. Una DECISION strutturalmente valida non prova quel protocollo.

Gli ID, CSN e TXID nei payload sono interi opachi: unicità, esistenza nel catalogo,
ordine applicabile, disponibilità dei file e appartenenza dei partecipanti restano
controlli dello stato. Nessun nuovo punto di atomicità o coordinamento tra Serie.

## Contratti pubblici

Buffer `simple-array (unsigned-byte 8)`, intervalli `[start,end)`. I tipi dichiarati
sono precondizioni rilevate dal runtime con safety 3. Gli errori di formato o budget
sono condizioni della gerarchia `arcdocdb-error`.

| API | Verifica/prepara | Valori restituiti |
|---|---|---|
| `scrivi-header-segmento` | header 64 byte, versione 1/2, origine writer/compaction, identità, CRC | fine header |
| `verifica-header-segmento` | CRC, magic, versione effettiva, origine, riservati, Serie e segment-id attesi | fine header, versione, origine, offset created-at |
| `scrivi-valore-edit` | sezioni chiusi/esiti/rimossi complete, conteggi, next-id, budget; copia dopo preflight | fine payload |
| `valida-valore-edit` | flag, next-id ordinario zero, valid-bytes, conteggi cumulativi, sezioni complete, consumo esatto | inizio chiusi, count, inizio rimossi, count, totale esiti |
| `scrivi-valore-decision` | almeno 2 ID16, count u16, budget e capacità | fine payload |
| `valida-valore-decision` | CSN presente, count, lista ID16 completa, consumo esatto | offset CSN, inizio/fine lista, count |
| `verifica-record-edit` | budget prima del CRC, cornice, tipo, consumo esatto, payload EDIT | range payload, chiusi/count, rimossi/count, totale esiti, flag |
| `verifica-record-decision` | budget prima del CRC, cornice, tipo, consumo esatto, payload DECISION | offset CSN, inizio/fine lista, count |

Gli adattatori di record richiedono `:version` ottenuta dall'header del file.
L'omissione usa zero e segnala `unsupported-format`; non interpreta il record
per tentativi. Il lettore dell'header restituisce la versione realmente presente.

Le API `valida-valore-*` presuppongono la verifica della cornice e dei CRC: servono
anche alla composizione interna del decoder, non sono il confine per byte esterni
privi di integrità verificata. Su byte di file si usano `verifica-record-*`.

Il chiamante mantiene stabili e referenziati i buffer fino al termine dell'uso degli
intervalli restituiti. Gli encoder richiedono una destinazione esclusiva e input
senza alias con essa. Tutti i rifiuti di preflight precedono la prima mutazione.
La data di creazione è fornita dal chiamante: il codec non legge l'orologio.

## Limiti di lavoro e memoria

I conteggi sono confrontati con budget e byte disponibili **prima** di moltiplicare
o avviare un ciclo. Gli esiti hanno un budget cumulativo per tutto EDIT. Sono distinti
`resource-exhausted` (budget operativo), `corruption-detected` (struttura impossibile)
e `invalid-argument` (input/configurazione del chiamante).

> **Proposta** — Budget iniziale EDIT: 65.536 chiusure, rimozioni ed esiti totali;
> ciascuno è un parametro distinto modificabile per chiamata, fino al campo u32.
> Il budget byte del payload è configurabile fino a 16 MiB, coerente con il tetto
> della cornice v2 per valore. Non è un nuovo limite sul numero di segmenti di una
> Serie: chiusure ordinarie possono essere distribuite tra più EDIT; il proprietario
> deve gestire esplicitamente l'esaurimento di un EDIT completo, senza troncarlo.

> **Proposta** — I byte riservati dell'header sono scritti e richiesti zero,
> inclusi i quattro finali fuori dal CRC. La specifica li chiama riservati;
> questa è la politica conservativa del codec per i formati attuali, non
> un'interpretazione di future estensioni del formato.

Gli u64 di identità sono confrontati come due u32; CSN, TXID e created-at possono
restare nel buffer come offset. Non si materializzano bignum durante la verifica.
Gli interi sono conservati integralmente; nessuna approssimazione probabilistica.

Non ci sono stato mutabile condiviso, contatori globali, lock o attese tra Serie.
L'unica serializzazione è il possesso esclusivo del buffer di output di una chiamata.

## Verifica ed evidenze

[Metodo](metadati-storage-metodo.md), [decisioni composte](metadati-storage-decisioni.md)
e [catalogo delle prove](../../spikes/results/2026-10-08-storage/catalogo.lisp).
I requisiti collegati restano nello stato assegnato al motore: nessuna promozione
automatica per il solo successo di un codec.

```sh
make test lint
sbcl --noinform --no-userinit --script tools/storage-bench.lisp --self-test
sbcl --noinform --no-userinit --script tools/storage-bench.lisp --bench
sbcl --noinform --no-userinit --script tools/foundation-coverage.lisp --report /tmp/storage-cover/ storage
sbcl --noinform --no-userinit --script tools/foundation-mutation.lisp --run /tmp/storage-mutants-new/ storage
make check
```

18 nuove prove: packing indipendente e CRC bitwise, versioni 1/2, origini 1/2,
troncamenti, alterazioni dei byte, campi invalidi con CRC corretti, identità diversa,
interi alti, valid-bytes 64 e 4 GiB−1, budget cumulativi/esatti, conteggi enormi,
65.535 partecipanti e rifiuto di 65.536, nessuna scrittura parziale dell'encoder.
Build senza warning/style warning e lint senza violazioni.

[10 mutazioni mirate](../../spikes/results/2026-10-08-storage/mutazioni-finali.lisp)
rilevate su CRC, magic, identità, riservati, budget, limiti e consumo esatto.
Le [9 mutazioni delle fondazioni](../../spikes/results/2026-10-08-storage/mutazioni-fondazioni.lisp)
rimangono rilevate dopo l'integrazione del modulo. Una prima campagna comprendeva
un confronto equivalente all'originale per le precondizioni del decoder: il suo
[esito fallito](../../spikes/results/2026-10-08-storage/mutazioni-iniziali-fallite.lisp)
è conservato e il mutante finale introduce invece un difetto osservabile.

## Prestazioni osservate

[Campagna finale](../../spikes/results/2026-10-08-storage/benchmark-finale.lisp),
Apple M4 ARM64, SBCL 2.6.9, un worker, safety 3, cinque campioni, mediana:

| Campagna | Operazioni/s | Byte heap per ciascun campione |
|---|---:|---:|
| Verifica header, u64 alti | 4.617.244 | 0 |
| Encoding header, u64 alti | 5.005.709 | 0 |
| Verifica record EDIT, 2 chiusure/2 esiti | 2.301.366 | 0 |
| Encoding payload EDIT, 2 chiusure/2 esiti | 3.924.899 | 0 |
| Verifica record EDIT, 1.024 chiusure/esiti | 10.771 | 0 |
| Encoding payload EDIT, 1.024 chiusure/esiti | 23.846 | 0 |
| Verifica record DECISION, 2 partecipanti | 4.474.058 | 0 |
| Encoding payload DECISION, 2 partecipanti | 17.055.563 | 0 |
| Verifica record DECISION, 65.535 partecipanti | 675 | 0 |
| Encoding payload DECISION, 65.535 partecipanti | 40.764 | 0 |

EDIT piccoli: payload 96 byte, record 120; EDIT grandi: 36.888/36.912 byte.
DECISION piccole: 42/66 byte; grandi: 1.048.570/1.048.594 byte. La verifica include
CRC sull'intero record, l'encoding del payload non include la cornice. Sono misure
seriali in memoria con buffer preallocati e carico esterno non controllato, senza
I/O, commit, P95/P99 o concorrenza. Zero heap vale per gli input riusciti misurati;
le condizioni di errore possono allocare.

## Letture e criteri aperti

Due letture: formato/confini/errori; poi proprietà dei buffer, budget prima delle
scansioni, parallelismo e interi alti. Le evidenze non equivalgono a una revisione
indipendente o a qualifica C1. Tracciabilità: REQ-FOR-001/002/003, REQ-LIM-001,
REQ-TXM-001, REQ-AFF-002/008, REQ-VAL-001; invarianti INV-F1, INV-A2/A3/A4/A8,
INV-P6 e INV-X3.

La [copertura grezza](../../spikes/results/2026-10-08-storage/copertura-dati.lisp)
conserva il denominatore completo: definizioni e proclamazioni non eseguite, e
il ramo difensivo `closed-range` che non è raggiungibile da dati esterni dopo i
controlli dei passi. Le eccezioni richiedono ancora registrazione/revisione per C1.
CRC32C non autentica i dati e ha collisioni; restano da verificare l'integrazione
con I/O, resolver, manifest e `FAULTED`, l'unicità e validità semantica degli ID,
i protocolli di commit e i guasti del motore. Nessun gate di rilascio è chiuso qui.
