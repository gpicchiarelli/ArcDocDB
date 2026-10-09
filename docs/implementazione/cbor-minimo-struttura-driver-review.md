# Lettura C4 dei driver dello scanner minimo

Lettura statica del coordinatore, prima di ogni esecuzione del prodotto e
delle campagne. Il benchmark congelato ha blob
`3cdd34a3dd5747f7fd0e513a1f2daeb7e2c2bbfb`; i test ciechi restano invariati.

Le otto fixture sono costruite dai byte preregistrati, con input e scratch
privati preparati fuori misura. Nodi, profondità, END e token sono costanti
indipendenti; il controllo freddo richiede esattamente tre valori. Il ciclo
misurato controlla i tre valori e li usa tutti nel sink. Warmup, GC e
allocazione del report sono esterni ai delta heap e clock. Baseline nulla,
allocazione deliberata viva, cinque repliche e immutabilità sono controllati.
La stabilità delle impronte è distinta dall'autenticità; nessuna soglia di
throughput, scaling o prova assoluta di nonallocazione è prevista.

La prima lettura ha rilevato che il solo MULTIPLE-VALUE-BIND non controllava
l'arità esatta. La correzione aggiunge un MULTIPLE-VALUE-LIST freddo, prima
del warmup. Originale bytewise `d0e85c152006e7949f9bdc80cbfebc1d15484650`
e dato finding/fix sono conservati nella raccolta; nessuna misura precede
la correzione.

Gli otto mutanti dello scanner sono fissati prima di leggere i nuovi test.
Copie private, baseline completa e frammenti unici impediscono sostituzioni
ambigue. Il catalogo e il dispatcher estendono il runner preesistente;
l'integrazione conserva le classificazioni upstream per segnali OS e
guasti successivi al completamento. Questi guasti sono WORKER-ERROR e gli
errori di compilazione INVALID, mai rilevamenti del mutante. I self-test
esercitano anche child reali e quattro sintassi valide/dodici invalide.
Compilabilità e rilevamento effettivi restano da acquisire nei rapporti.

La copertura ha una [lettura separata](cbor-minimo-struttura-strumenti-review.md).
Nessun rilievo statico aperto nel benchmark finale o nel catalogo; i risultati
runtime e la conservazione devono essere verificati sui dati originali.
