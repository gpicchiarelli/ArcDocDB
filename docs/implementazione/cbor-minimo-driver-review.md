# Testate CBOR minime — lettura dei driver C4

Lettura del coordinatore sui due strumenti, indipendente dal loro autore.
Il benchmark è congelato a otto fixture, cinque repliche di 4096 chiamate,
warmup 128; il mutatore a otto bersagli unici, prima delle campagne.

Nel benchmark, caricamento e warmup precedono clock e contatore heap.
I sei valori vengono confrontati con costanti indipendenti prima di
alimentare il sink; quest'ultimo usa tutti i valori e l'indice di chiamata.
Input e sentinelle sono preallocati e confrontati dopo la campagna.
Baseline nulla e allocazione deliberata con oggetto vivo verificano il
sensore. Un errore produce rapporto fallito ed exit nonzero. La misura
seriale non attesta heap di rifiuto, scaling o throughput del database.

Il mutatore copia ASDF, build, sorgenti e test in directory nuove e cache
private. La sostituzione ha un bersaglio unico nel file congelato.
La baseline richiede exit zero, marker smoke e completamento su righe
esatte; un mutante con exit zero senza completamento è INVALID.
Compilazione fallita, marker soltanto citati o errore prima dello smoke
sono INVALID. Un errore runtime dopo smoke conta DETECTED; un completamento
normale conta SURVIVED. I controlli negativi sono nel self-test.

Gli otto difetti interessano soglie 24/256/65536, parola alta u64,
massimo normale binary16, allineamento del subnormale binary16,
esponente speciale binary64 e minimo subnormale binary32. Non sono
mutazioni esaustive di tutte le condizioni composte: nessuna pretesa MC/DC.
Compilabilità e rilevamento effettivi vengono verificati nei log conservati,
senza contarli dal solo risultato della lettura statica.

Nessun rilievo statico aperto nei driver. Lo scope di copertura e l'utilità
di raccolta ricevono una [lettura distinta](cbor-minimo-strumenti-review.md).
