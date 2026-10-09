# Epoche e reclaim — compilazione e ispezione statica

Il [catalogo](catalogo.lisp) conserva i record originali del solo prodotto,
dei controlli statici e del disassemblato ARM64. I record includono comando,
ambiente, output e identità dei sorgenti prima/dopo; SBCL 2.6.9 compila con
avvisi trattati come errori. Nessun record viene ripulito o sostituito.

Lo script di disassemblaggio è conservato come testo nel record
`disassemblato-sorgente.lisp`: carica il prodotto e stampa il codice macchina
di ingresso/uscita del reader, senza chiamare le funzioni ispezionate.
Il codice generato contiene accessi u64 e barriere `DMB ISH`/`DMB ISHLD`;
questo dato statico non misura allocazioni, costo delle barriere o throughput.

Non sono stati aggiunti o eseguiti localmente test funzionali, stress,
fault injection, modelli o benchmark del nuovo modulo. La qualifica C1
resta aperta; i test preesistenti della CI non la sostituiscono.

Contratti, stati, decisioni da coprire e integrazioni necessarie sono nella
[documentazione](../../../docs/implementazione/epoche-e-reclaim.md).
