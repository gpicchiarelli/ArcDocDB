# Scrittura delle testate CBOR — contratto e metodo

Incremento C1 registrato il 2026-10-11 prima della compilazione e delle
campagne. REQ-CBR-001 deriva dalla codifica CBOR decisa in ADR-0014;
REQ-AFF-004/008 governano errori, confini e proprietari.

## Contratto congelato

`arcdocdb.cbor:scrivi-header-cbor-minimo(buffer,start,end,major,high,low)`
restituisce esattamente NEXT. La destinazione è un array simple u8 esclusivo
della chiamata attiva, nell'intervallo half-open `[start,end)`. MAJOR è un
intero 0..6; HIGH e LOW sono parole unsigned u32 dell'argomento wire. Per
MT1 il chiamante fornisce l'argomento non negativo `-1-n`, non il numero
negativo applicativo. Nessun argomento u64 viene ricomposto.

HIGH diverso da zero richiede nove byte (AI27). Con HIGH zero, LOW sotto
24 occupa il solo lead; sotto 256, 65536 e 2^32 richiede rispettivamente
due, tre e cinque byte (AI24/25/26). Le parole sono scritte big-endian.
Queste regole seguono [RFC 8949 §3 e §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-3).
La funzione scrive solo la testata; payload, conteggi dei contenitori,
testo, ordine/equivalenza delle chiavi, semantica dei tag e profilo completo
restano al livello documentale. MT7, float, simple e forme indefinite
restano fuori dal dominio dell'API.

Preflight in ordine: range (`invalid-argument :cbor-range`), MAJOR
(`:cbor-write-major`), HIGH (`:cbor-write-high`), LOW (`:cbor-write-low`),
capacità (`resource-exhausted :cbor-write-capacity`). Ogni errore pubblico
ha offset NIL e lascia l'intera destinazione invariata, anche quando un
suffisso fisico fuori dallo span sarebbe sufficiente. Uno span valido vuoto
arriva al controllo della capacità. Nessun limite implicito di 16 MiB è
applicato all'argomento locale.

Un successo modifica esattamente `[start,NEXT)`, lasciando invariati
prefisso, resto dello span e suffisso fisico. Non è una pubblicazione
atomica: il buffer deve restare esclusivo fino al ritorno. Nessuna attesa,
I/O, stato globale mutabile o scrittura condivisa tra Serie; al massimo
nove byte scritti. Guardie interne attive segnalano `invariant-violation`;
il proprietario applica fail-stop, senza promessa di rollback interno.

## Verifiche preregistrate

Test ciechi da modello aritmetico indipendente, congelati prima di leggere
il prodotto: tutti i sette major, soglie 0/23/24/255/256/65535/65536/u32max,
HIGH1, massimo u64 e parole asimmetriche; LOW0..65535 ×7 e fuzz4096 con
seme fissato nel test. Il round-trip con il lettore minimo è supplementare:
gli expected byte non dipendono dal prodotto. Arity esatta, sentinelle,
capacità 0..size-1, buffer non simple, priorità concorrenti e riuso.
Due worker reali con destinazioni private, attese/join/cleanup limitati e
sink verificati: concorrenza funzionale, senza attestazione di scaling.

Due letture C1 e inventario di tutte le decisioni composte. Copertura
grezza del solo nuovo file di prodotto, report completo e HTML conservati,
nessuna guardia rimossa dal denominatore e nessuna attestazione MC/DC.
Driver di misura con fixture fredde indipendenti per tutte le larghezze,
cinque repliche ×4096 chiamate, warmup128, buffer preallocato; NEXT e byte
alimentano un sink verificato. Baseline nulla e controllo positivo16×1MiB.
Criterio locale: zero heap osservato; nessuna soglia di velocità.

Otto mutazioni compilabili, bersagli e sostituzioni congelati prima della
campagna in `tools/cbor-write-mutation.lisp`: soglie23/255/65535 anticipate,
endianness invertita, HIGH sostituito con LOW, major spostato di quattro
bit, capacità calcolata sul suffisso fisico e NEXT decrementato.
Copie/cache private, baseline completa, marker esatti smoke e
fine; compilazione fallita INVALID, segnale/guasto worker WORKER-ERROR,
mai rilevamento. Ogni tentativo e log viene conservato. Build senza avvisi,
lint, tracciabilità e controlli completi prima del push. Strumenti e audit
in Common Lisp (INV-X3); sorgenti stabili durante ogni processo registrato.
