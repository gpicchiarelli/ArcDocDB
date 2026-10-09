# Registro snapshot — compilazione e ispezione statica

Il [catalogo](catalogo.lisp) conserva i record originali di compilazione del
solo prodotto, controlli statici e disassemblato ARM64, con ambiente,
comando e identità dei sorgenti prima/dopo. La compilazione usa SBCL 2.6.9
e tratta gli avvisi come errori.

Il primo rifiuto del linter è conservato: considerava il keyword `:read`
della barriera una chiamata al reader Lisp. La correzione distingue i
keyword dai nomi di funzione, senza rimuovere il divieto delle chiamate a `READ`.

Il sorgente dello script di disassemblaggio è conservato come testo in un
record di dati. Lo script carica il prodotto e stampa il codice generato;
non chiama le funzioni ispezionate. Nei comandi locali non sono stati aggiunti o eseguiti test
funzionali, auto-test, fault injection, prove concorrenti o benchmark del modulo.

La qualifica C1 e le prestazioni restano aperte. Il registro non implementa
indice, versioni trattenute, EBR o scheduler. Contratti e responsabilità sono
nella [documentazione](../../../docs/implementazione/registro-snapshot.md).
