# Scrittura dei valori semplici CBOR

`arcdocdb.cbor:scrivi-semplice-cbor-minimo` scrive un codice wire MT7
in una destinazione esclusiva. Realizza REQ-CBR-003; dominio, precedenza
degli errori e prove sono nel [metodo preregistrato](cbor-semplici-metodo.md).

```lisp
(scrivi-semplice-cbor-minimo buffer start end value)
;; => NEXT, esattamente un valore
```

VALUE è un intero 0..23 oppure 32..255. I codici 20/21/22/23 rappresentano
false/true/null/undefined, senza conversione dei valori Common Lisp;
i codici non assegnati non ricevono semantica applicativa. I codici
riservati 24..31 sono rifiutati. La rappresentazione minima usa un byte
per 0..23 e due per 32..255.

BUFFER deve essere un array simple u8 posseduto in esclusiva; START/END
delimitano uno span half-open, anche vuoto. Il preflight controlla range,
codice e capacità in quest'ordine. Un argomento invalido segnala
invalid-argument; uno span insufficiente resource-exhausted. Offset NIL
e intero array intatto su ogni errore pubblico. Lo spazio fisico dopo
END non è disponibile per la scrittura.

Dopo il successo NEXT=START+dimensione e cambiano soltanto i byte
`[START,NEXT)`. Prefisso, residuo dello span e coda fisica restano
intatti. Le guardie interne segnalano invariant-violation senza rollback;
il proprietario applica fail-stop. La primitiva non pubblica né rende
durevoli dati.

Il lavoro è limitato a due byte e variabili locali. Worker distinti
possono chiamarla su destinazioni private, senza coordinamento tra Serie,
attese, I/O o AST. Budget complessivo, profilo applicativo, float e
composizione di documenti rimangono al livello superiore.

Il [rapporto delle prove](cbor-semplici-risultati.md) conserva corpus,
misure, mutazioni e copertura grezza; la qualifica C1 del motore rimane aperta.
