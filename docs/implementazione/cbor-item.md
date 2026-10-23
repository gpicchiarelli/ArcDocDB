# Lettura del primo item CBOR minimo

`arcdocdb.cbor:leggi-item-cbor-minimo` verifica il primo item nella
finestra autorizzata e restituisce tre valori: numero di nodi,
picco dei livelli array/map e frontiera assoluta NEXT.
Il [metodo preregistrato](cbor-item-metodo.md) fissa precedenze e prove;
le [verifiche](cbor-item-risultati.md) conservano risultati e limiti.

```lisp
(leggi-item-cbor-minimo buffer start end space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => NODES, PEAK, NEXT
```

Per i byte `C0 81 00 FF`, START=0 ed END=4, il risultato è
3, 1, 3. Il tag conta come nodo e non aggiunge profondità.
Il byte FF della coda non viene letto né verificato. Per verificare
l'intero span resta disponibile
`verifica-struttura-cbor-minima`, che rifiuta la coda con
`:cbor-trailing`.

MAX-BYTES limita **l'intera finestra END-START**, compresa la coda,
prima del reset o della lettura. Non è un budget dei soli byte consumati.
I massimi restano 16 MiB, 16 Mi nodi e 100 livelli array/map.
Il chiamante sceglie END in base alla finestra che autorizza.
Ogni successo ha START<NEXT<=END; la chiamata successiva può usare
NEXT come START per ricavare le frontiere degli item concatenati.

BUFFER simple u8 resta immutabile ed è condivisibile in lettura.
Ogni worker usa uno SPACE esclusivo preallocato, riusabile anche
dopo un errore di parsing. Il preflight rifiutato conserva lo scratch;
dopo successo i conteggi descrivono soltanto il primo item.

Sono richiesti header minimi e UTF-8 valido per il testo, con offset
assoluti nei rifiuti. La primitiva non costruisce AST, non interpreta
tag applicativi e non impone ordine/unicità delle chiavi. Nessuna
attesa, I/O o gestione dei thread nel prodotto. Profilo documentale
deterministico e qualifica C1/MC/DC restano aperti.

