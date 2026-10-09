# Testate CBOR minime

Il lettore `arcdocdb.cbor:leggi-header-cbor-minimo` completa la lettura
sintattica con il controllo delle larghezze minime: interi, lunghezze,
tag e floating point. È un componente locale per il successivo profilo
documentale di ADR-0014.

```lisp
(arcdocdb.cbor:leggi-header-cbor-minimo buffer start end)
;; => major, AI, high-u32, low-u32, next, :argument
```

Il buffer rimane immutabile. Il controllo lavora su bit e parole u32,
anche per float64 e NaN, senza creare un numero floating point o un intero
u64. Zeri di entrambi i segni, infiniti e payload NaN sono preservati.
Una rappresentazione NaN più corta è richiesta solo quando il padding
del suo significando riproduce il payload originale, secondo
[RFC 8949 §4.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.1).

Il controllo sintattico precede quello di minimalità: conserva condizioni
e offset del lettore di base. Una testata completa con argomento o float
accorciabile, una lunghezza indefinita o un break segnala
`corruption-detected :cbor-nonminimal` all'offset iniziale.

Ogni chiamata usa soltanto variabili locali; worker e Serie possono
leggere buffer indipendenti senza lock, stato condiviso o scratch.
Il lavoro ha un limite fisso di nove byte. Non attraversa il corpo,
non verifica UTF-8, ordinamento/duplicati delle mappe o semantica dei
tag. Un risultato positivo non attesta il determinismo dell'intero item.
Lo scanner strutturale generico conserva la sua API e il suo ambito.

[Contratto e campagne](cbor-minimo-metodo.md),
[risultati e dati originali](cbor-minimo-risultati.md).
