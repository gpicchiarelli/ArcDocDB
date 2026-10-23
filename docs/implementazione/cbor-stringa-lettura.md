# Lettura diretta delle stringhe CBOR

`arcdocdb.cbor:leggi-stringa-cbor-minima` restituisce il tipo MT2/3 e
l'intervallo del payload nel buffer originale. Il chiamante può così
usare byte o testo UTF-8 verificato senza una copia intermedia.

```lisp
(leggi-stringa-cbor-minima buffer start end :max-bytes 16777216)
;; => MAJOR, PAYLOAD-START, NEXT
```

La stringa deve avere lunghezza definita e testata minima. Il testo MT3
deve essere UTF-8 valido; i byte MT2 sono opachi. La funzione restituisce
esattamente tre fixnum, anche per un payload vuoto. Per `61 61 FF`, con
START0 ed END3, il risultato è `3,1,2`: il byte FF resta nella coda.

MAX-BYTES limita tutta la finestra autorizzata END-START, inclusa la
coda. Il limite massimo è 16MiB. Il buffer simple u8 deve restare stabile
durante la chiamata e durante l'uso dell'intervallo restituito. Più
worker possono leggerlo insieme; la funzione non possiede scratch.

Il [metodo preregistrato](cbor-stringa-lettura-metodo.md) specifica errori,
precedenze e limiti; i [risultati conservati](cbor-stringa-lettura-risultati.md)
riportano corpus, parallelismo, misure e copertura.
Il lettore minimo esistente verifica la testata;
prima dell'UTF-8 si verifica che l'intero payload sia presente. Non ci
sono conversione in stringa Common Lisp, normalizzazione o scelte sul
profilo documentale. REQ-CBR-009 è un requisito locale del codec; qualifica
C1/MC/DC e limiti documentali complessivi restano aperti.
