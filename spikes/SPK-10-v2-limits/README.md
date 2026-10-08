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

`run.lisp` risolve tutti i file rispetto al proprio percorso, carica il
kernel SPK-09 e compila i quattro moduli in `out/`. Controlli e misure
rimangono separati. Il parent integra il runner nell'harness seriale:

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

In sviluppo. I limiti v2 non sono ancora verificati dalla suite integrata.
Il percorso oltre RAM di ADR-0049 resta una proposta distinta: questo
esperimento non lo implementa. Prima del motore occorrono anche memoria
debole, modelli mancanti, I/O e conversione reale interrotta, decoder
completo e campagna sulla piattaforma Linux di riferimento.

Requisiti collegati: REQ-LIM-001, REQ-LIM-002, REQ-LIM-003,
REQ-IDX-007, REQ-FOR-002, REQ-AFF-007, REQ-AFF-008, REQ-AFF-019,
REQ-VAL-001. Identificativi e fonti non sono cambiati dai moduli sperimentali.
