# SPK-10 — limiti, formati e migrazione v2

> **Proposta** — Esperimento di Fase 0 registrato prima dell'esecuzione.
> Solo Common Lisp/SBCL, nessun codice del motore. Valuta i limiti aggiornati
> di [ADR-0048](../../docs/adr/0048-limiti-documentali-e-formato-v2.md).

## Domanda

Il formato v2 rappresenta e controlla documenti CBOR da 16 MiB effettivi,
100 livelli di contenitori e chiavi binarie da 1–65.535 byte? Le arene e
la conversione rispettano budget espliciti senza perdere i sorgenti o
pubblicare risultati non verificati?

## Metodo e ambiti

Quattro moduli indipendenti, compilati senza warning/style-warning, `safety 3`:

| Modulo | Domanda | Metodo dichiarato prima delle prove |
|---|---|---|
| Codec | lunghezze, versioni, CRC e hint | [metodo-codec.md](metodo-codec.md) |
| Indice | slot v2, chiavi estese e arene limitate | [metodo-indice.md](metodo-indice.md) |
| CBOR | profondità, byte, nodi e parsing senza ricorsione | [metodo-cbor.md](metodo-cbor.md) |
| Migrazione | versione del file, EDIT, conservazione e ripetibilità | [metodo-migrazione.md](metodo-migrazione.md) |

Il codec usa il kernel CRC32C già verificato da SPK-09; i suoi risultati
restano distinti dai risultati v1. Gli altri moduli dichiarano le proprie
dipendenze e le parti non implementate. La migrazione è un **modello finito**,
non un convertitore su filesystem. I controlli indipendenti non sostituiscono
una fetta completa con storage, manifest, snapshot e fault injection reali.

Confini obbligatori: documenti 16 MiB/16 MiB+1, profondità 100/101,
chiavi 1/255/256/65.535/65.536, versioni v1/v2/sconosciuta, troncamenti,
lunghezze alterate e saturazione dei budget. I metodi precisano copertura,
subset del CBOR, fixture, quantità e oracle. Nessun numero prestazionale
è anticipato e nessun requisito del motore è promosso automaticamente.

## Esecuzione

### Metodo dell'integrazione, registrato prima dell'esecuzione

`core.lisp` collega i moduli con fixture in memoria: fileheader verificato →
parser selezionato per versione → record ordinario e due CRC → documento CBOR →
hint → inserimento e lookup nell'indice. Sedici combinazioni positive:
mappe da 4 byte/profondità 2 e da 102 byte/profondità 100, chiavi 1/255 byte
per v1 e 1/255/256/65.535 per v2; mappa di **16 MiB codificati effettivi**
con le quattro chiavi v2. Il massimo documentale non è rappresentabile nel
record v1 u24, che comprende header e chiave. CSN u64 alto e offset non nullo.

Oracle indipendenti confrontano versione, callback, intervalli, CSN, profondità,
metadati hint e campi letti dallo slot. Una fixture negativa ha entrambi i CRC
validi ma CBOR non minimo: il codec la verifica e il validatore deve rifiutarla.
Il risultato espone casi, asserzioni e dimensione massima del record.

Il validatore accetta un vettore intero: l'integrazione copia esplicitamente
l'intervallo del valore nel solo harness. La fixture massima usa meno di 128 MiB
di payload simultaneo degli array del singolo caso, senza contare garbage,
header Lisp e runtime. Nessun throughput viene derivato da questi controlli.
CRC delle sezioni hint, prepared, storage e commit durevole restano esclusi.

`run.lisp` risolve tutti i file rispetto al proprio percorso, carica il
kernel SPK-09 e compila i quattro moduli in `out/`. Controlli e misure
rimangono separati. Il runner è integrato nell'harness seriale:

```sh
sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit \
  --script spikes/SPK-10-v2-limits/run.lisp --check
sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit \
  --script tools/run-spikes.lisp --bench SPK-10
```

Per gli esperimenti si dichiarano memoria viva, allocazioni transitorie e
budget cooperativi; un budget temporale non interrompe una syscall e non
garantisce una latenza. Errori espliciti, stdout con una sola plist,
output grezzo e sorgenti identificati nell'harness.

## Risultato e limiti

La prima [suite integrata e campagna locale](../../docs/valutazione/risultati-2026-10-08.md#spk-10--limiti-v2-e-integrazione)
è completata: 416 casi del codec, 614 CBOR, otto gruppi dell'indice,
208 crash e 4.160 interruzioni recovery sul modello, 16 combinazioni positive
e una negativa tra moduli. Il record massimo di 16.842.775 byte è costruito,
verificato e rappresentato nello slot. Report distinti per controlli e misure,
con sorgenti identificati prima/dopo. Il gate completo resta aperto.
La variante CBOR con pila creata su richiesta supera 629 casi (614 precedenti
e 15 nuovi) e ha due benchmark separati, mantenendo anche la misura più lenta.
Il percorso oltre RAM di ADR-0049 resta una proposta distinta: questo
esperimento non lo implementa. Prima del motore occorrono anche memoria
debole, modelli mancanti, I/O e conversione reale interrotta, decoder
completo e campagna sulla piattaforma Linux di riferimento.

Requisiti collegati: REQ-LIM-001, REQ-LIM-002, REQ-LIM-003,
REQ-IDX-007, REQ-FOR-002, REQ-AFF-007, REQ-AFF-008, REQ-AFF-019,
REQ-VAL-001. Identificativi e fonti non sono cambiati dai moduli sperimentali.
