# Scrittura delle stringhe CBOR

`arcdocdb.cbor:scrivi-stringa-cbor-minima` scrive un item completo MT2/3,
riusando la testata minima e il validatore UTF-8. Realizza REQ-CBR-002;
contratto e verifiche sono nel [metodo preregistrato](cbor-stringhe-metodo.md).

```lisp
(scrivi-stringa-cbor-minima buffer start end major source source-start source-end
                          :max-bytes 16777216)
;; => NEXT, un solo valore
```

MAJOR2 copia byte arbitrari; MAJOR3 verifica prima UTF-8, poi copia gli
stessi byte. La lunghezza codificata conta byte, anche per caratteri
multibyte. Stringhe vuote, NUL, BOM e noncaratteri sono ammessi; non vi sono
conversione da stringhe Lisp, escaping o normalizzazione. La testata è
definite-length e minima. Questa primitiva non compone mappe/array/tag né
valida il profilo completo del documento.

I due span half-open devono stare in array simple u8. MAX-BYTES 0..16 MiB
include testata e payload, come il footprint scritto `[start,NEXT)`.
Il chiamante può impostare il budget residuo; la configurazione della
Serie e l'intero documento restano al livello superiore. Il suffisso
fisico oltre END non è capacità disponibile.

Il chiamante possiede la destinazione in esclusiva e mantiene stabili i
byte sorgente. Lo stesso array è ammesso se lo span sorgente è disgiunto
dal footprint scritto, testata inclusa; confini toccanti e sorgente vuota
sono ammessi. Dopo il successo il payload sorgente e ogni byte fuori
`[start,NEXT)` restano invariati, compreso il residuo della destinazione.

Il preflight verifica destinazione, major, sorgente, budget, capacità,
overlap e UTF-8, prima del primo write. Tipi/range/budget/alias invalidi
segnalano invalid-argument; budget o capacità insufficienti segnalano
resource-exhausted. I motivi e la precedenza sono nel metodo, con offset
NIL. Gli errori UTF-8 conservano corruption-detected, motivo e offset
assoluto nella sorgente. Ogni errore pubblico lascia entrambi gli array
intatti. Le guardie interne segnalano invariant-violation senza rollback:
il proprietario applica fail-stop.

La funzione non pubblica dati o rende durevoli modifiche. La copia ha
limite esplicito, usa cursori locali e non crea thread, attese, I/O o stato
condiviso tra Serie. Worker distinti possono leggere una sorgente stabile
condivisa e usare destinazioni private. La primitiva è un fondamento del
codec, senza qualifica implicita del motore.

Il [rapporto delle prove](cbor-stringhe-risultati.md) conserva corpus,
misure, mutazioni e copertura, con gate C1 ancora aperto.
