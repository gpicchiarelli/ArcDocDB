# Scrittura delle testate CBOR minime

La fondazione codec espone `arcdocdb.cbor:scrivi-header-cbor-minimo` per
scrivere una testata ad argomento MT0..6 in una destinazione preallocata.
Realizza REQ-CBR-001, derivato da ADR-0014; il [metodo](cbor-scrittura-metodo.md)
congela contratto e verifiche.

```lisp
(scrivi-header-cbor-minimo buffer start end major high low)
;; => NEXT, un solo valore
```

Lo span è `[start,end)` dentro un array simple u8. MAJOR è 0..6, HIGH e LOW
sono u32 dell'argomento wire. Per il major negativo MT1, `n` è rappresentato
con argomento `-1-n`: ad esempio `major=1, high=0, low=24` scrive `38 18`
(byte esadecimali), che rappresenta -25. Le stringhe, mappe, array e i tag
ricevono soltanto la propria testata, senza payload o figli.

La larghezza è sempre minima: 1/2/3/5/9 byte secondo l'argomento.
Le parole sono scritte big-endian senza costruire un u64 o un documento.
Un successo modifica `[start,NEXT)`; il resto del buffer rimane invariato.
Una testata di lunghezza o tag può avere qualunque argomento wire u64;
i budget del documento completo restano al livello superiore.

Il preflight verifica range, major, high, low e capacità, in quest'ordine.
Gli argomenti invalidi segnalano `invalid-argument` con motivo
`:cbor-range`, `:cbor-write-major`, `:cbor-write-high` o `:cbor-write-low`.
Lo spazio insufficiente segnala `resource-exhausted :cbor-write-capacity`.
Tutti hanno offset NIL e lasciano la destinazione intatta. Le guardie interne
segnalano `invariant-violation`, senza rollback; il proprietario applica
fail-stop secondo il contratto generale del progetto.

Il chiamante possiede in esclusiva la destinazione fino al ritorno.
La funzione non crea thread o attese, non effettua I/O e non pubblica dati:
worker distinti operano su buffer privati. Il codice non mantiene stato
globale mutabile e non introduce una scrittura condivisa tra Serie.

Questa primitiva completa il [lettore minimo](cbor-minimo.md) per le sole
testate MT0..6. Float/simple MT7, payload, UTF-8, struttura e profilo
deterministico del documento appartengono ad altri componenti.
I [risultati conservati](cbor-scrittura-risultati.md) documentano test,
concorrenza, heap, mutazioni e limiti della copertura.
