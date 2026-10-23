# Verifica del decision log autorevole dell'Archivio

## Metodo registrato prima delle esecuzioni

La suite `tests/recovery-archive/` esercita le API pubbliche del modulo
`src/recovery-archive/`, nei formati v1 e v2, riusando gli oracoli bytewise e
CRC bitwise indipendenti dei test DECISION, CONTROL e ACTIVE. Non modifica
il formato o i limiti del database.

La revisione statica ha rilevato R1 su COD-25: due letture nel predicato
di asserzioni. La correzione conserva il risultato della lettura in una
variabile locale prima del confronto puro, senza cambiare sequenza I/O,
condizioni o offset. Le prove osservano esattamente richieste e byte,
inclusi trasferimenti corti e fallimenti; la rilettura del patch resta
nel documento di revisione.

Il backend iniettato conserva un solo FD readonly per fixture; registra al
più 32768 eventi e file di al più 4096 byte. Header di 64 byte e corpo sono
osservati separatamente. Le prove verificano preflight senza I/O, identità
completa, budget, trasferimenti corti, errori originali, prefisso sigillato,
proprietà delle copie e query scalari. Le sostituzioni di funzioni, se
necessarie per guardie irraggiungibili con dipendenze corrette, sono seriali,
delimitate e ripristinate prima del ritorno. `guards.lisp` inietta risultati
incoerenti da preflight, trasferimento, decoder header e replay: ogni rifiuto
precede la consegna e viene seguito da una lettura valida con dipendenze
ripristinate. Le coppie del predicato corpo e i limiti/coerenza di P sono
espliciti. Anche i costruttori privati sono invocati dinamicamente con tipi
invalidi, senza sopprimere warning o indebolire i tipi del prodotto.

Il bridge usa un Archivio con UUID distinto dalla Serie, associato al suo
stesso ambito GET canonico. Sono separati identità dei byte, identità
dell'ambito e lifetime dei FD. I budget passano al lettore ACTIVE canonico;
le decisioni derivano dall'header e dall'intero log letto dalle nuove API.

La catena nativa usa la fixture CONTROL privata 0700 esistente: temporaneo
esclusivo, flush e rename nel solo setup; successivamente Archivio readonly,
recovery ACTIVE, builder checkpoint e pubblicazione CONTROL reali. I casi
completo/coda, v1/v2, controllano byte, namespace, FD, offset e numero esatto
di letture. La decisione contraddittoria nella coda non sigillata resta
esclusa; CSN zero e alto restano interi. Limiti della fixture: 128 FD,
64 nomi, 4096 byte per file, deadline seriale di 30 secondi. Nessun nuovo
worker nativo o test di power loss.

## Esecuzione e copertura

Prima delle prove si chiudono gli agenti scrittori e si congelano i sorgenti.
Ogni comando, anche fallito, passa dal recorder strutturato esistente;
revisione, snapshot prima/dopo, argv, ambiente, output e codice di uscita
restano conservati. Una correzione genera una nuova revisione e un nuovo run.

`tools/foundation-coverage.lisp --report directory/ recovery-archive` seleziona
esattamente `types`, `read`, `build`, `query`, `active`, escludendo package e
fixture. I contatori sono azzerati dopo il caricamento e prima della suite.
Il self-test comprende selezioni positive, falsi suffissi e file esterni,
oltre alla fixture che rileva un ramo mancante. Forme e rami SBCL non sono
MC/DC; i denominatori non vengono ridotti con eccezioni implicite.

Il [registro della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-decisioni-verifica/report.md)
conserva separatamente esiti, tentativi e revisioni effettive.

Non è previsto un nuovo benchmark in questo incremento. Le prove parallele,
se presenti, dimostrano soltanto gli esiti della matrice dichiarata; non
misurano scalabilità, throughput DB o assenza universale di allocazioni.
I tempi del recorder includono bootstrap e fixture; il carico esterno non
è controllato. I risultati sono pubblicati separatamente nel registro
delle evidenze, compattando senza perdita gli output grandi.

## Limiti

La fixture attesta EOF e congela file e namespace; l'API di prodotto non
certifica il catalogo né impedisce scritture esterne. La qualifica locale
non conclude C1, riconciliazione CLOSED, indici, orizzonte CSN, ammissione
del traffico o il Recovery Manager completo. La revisione indipendente
resta distinta dagli esiti runtime.

## Integrazione con le altre suite

La [campagna di integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-decisioni-integrazione/report.md)
registra separatamente il grafo che comprende anche le suite indipendenti
del checkpoint ACTIVE e della catena pool/Serie arrivate durante la chiusura.
Le evidenze della prima campagna restano immutate e attribuite alle loro revisioni.
