# Scrittura dei float CBOR

La primitiva `arcdocdb.cbor:scrivi-float-cbor-minimo` riceve
`BUFFER START END AI HIGH LOW` e restituisce un solo NEXT.
Le parole contengono i bit IEEE, con AI25/26/27 per binary16/32/64;
HIGH è zero nelle prime due larghezze e LOW è u16 per binary16.
La destinazione simple u8 appartiene esclusivamente al chiamante.

La riduzione sceglie una forma esatta più corta, senza arrotondare
o materializzare un float Lisp. Conserva segno, zero, infinito e payload
NaN, incluso il bit signaling/quiet, secondo la preferenza locale del
[lettore minimo](cbor-minimo-metodo.md). Codifiche applicative equivalenti
e normalizzazione dei NaN richiedono un profilo superiore.

L'output contiene F9/FA/FB e parole big-endian, per 3/5/9 byte.
NEXT=START+dimensione; il resto dell'array fisico è invariato.
Prima di scrivere vengono verificati range, AI, HIGH, LOW, coerenza
delle parole e capacità della forma scelta, in quest'ordine. Gli errori
pubblici hanno offset NIL e lasciano tutti i byte intatti:

| Controllo | Condizione | Motivo |
|---|---|---|
| Destinazione/range | invalid-argument | :cbor-range |
| AI25/26/27 | invalid-argument | :cbor-float-ai |
| HIGH u32 | invalid-argument | :cbor-float-high |
| LOW u32 | invalid-argument | :cbor-float-low |
| Coerenza delle parole | invalid-argument | :cbor-float-words |
| Capacità fino a END | resource-exhausted | :cbor-float-capacity |

Le guardie interne richiedono fail-stop senza rollback. Non sono
pubblicazione atomica o durevole; la composizione e il budget del
documento rimangono superiori. Non vi sono attese, I/O o scritture
condivise per operazione; chiamate su buffer privati possono essere
eseguite in parallelo.

Il [metodo preregistrato](cbor-float-scrittura-metodo.md) fissa corpus,
misure, difetti e conservazione. La qualifica C1 e il gate del motore
restano aperti fino alle evidenze richieste da ADR-0035.

I [risultati delle verifiche](cbor-float-scrittura-risultati.md) riportano
prove parallele, mutazioni, misure e limiti della copertura osservata.
