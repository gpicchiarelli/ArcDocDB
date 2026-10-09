# Item CBOR con testate minime

Il codec verifica un item completo, applicando il controllo delle
[testate minime](cbor-minimo.md) durante lo stesso attraversamento che
controlla struttura, UTF-8 e budget. Ogni worker usa uno scratch privato.

```lisp
(let ((spazio (arcdocdb.cbor:crea-spazio-cbor))) ; preparazione fuori percorso caldo
  (arcdocdb.cbor:verifica-struttura-cbor-minima
   buffer start end spazio
   :max-bytes 16777216 :max-nodes 16777216 :max-depth 100))
;; => nodi, picco di profondità degli array/map, end
```

Il buffer resta immutabile. Lo scratch preallocato di 102 celle è
riusabile, anche dopo errore, e appartiene a una sola chiamata attiva.
Radice, figli, chiavi, valori e tag passano dal lettore minimo; i payload
binari restano opachi. Il controllo non costruisce AST, float o interi
u64, non copia il documento e non introduce lock, attese o I/O.

Gli errori di sintassi delle testate precedono quelli di minimalità.
Una testata completa accorciabile, indefinita o break segnala
`corruption-detected :cbor-nonminimal` sul lead, prima di nodi,
profondità e payload. La coda dopo una radice completa resta
`:cbor-trailing`; un figlio incompleto resta `:cbor-truncated` a END.
Range, alias e limiti configurati sono controllati prima del reset.

Lo scanner generico conserva firma e comportamento. Ordine/equivalenza
delle chiavi e semantica dei tag richiedono il successivo profilo
documentale: il risultato di questa API attesta struttura, UTF-8,
budget e preferenza locale delle testate.

[Contratto e metodo](cbor-minimo-struttura-metodo.md),
[prima lettura](cbor-minimo-struttura-lettura.md) e
[inventario delle decisioni](cbor-minimo-struttura-decisioni.md).

[Risultati, copertura e archivi originali](cbor-minimo-struttura-risultati.md).
