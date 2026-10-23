# Verifica del piano CSN dell'Archivio

## Metodo prima delle esecuzioni

La suite `tests/recovery-archive-csn/` attraversa i contratti di
[insieme, provenienza e base](csn-archivio-recovery.md), con v1/v2 e
oracoli indipendenti CT/RT per packing e CRC. Nessun formato o nuovo
limite del database. Serie, Registri, scope e completezza iniziale del
catalogo sono fatti dichiarati della fixture, non deduzioni del piano.

Il supporto possiede al massimo quattro Serie, quattro CLOSED per Serie,
32 capacità readonly, 4096 byte per file e 65536 eventi. Genera CONTROL,
ACTIVE, CLOSED writer/compaction e l'intero decision log; li recupera
con le API pubbliche. Token, marker e risultati positivi non sono forgiati.
Le query del piano devono lasciare vuoto il registro eventi: nessun I/O,
mutazione delle sorgenti o avanzamento del registro CSN di bootstrap.
Chiusure intenzionali del caller sono separate dai controlli d'integrità.

La matrice segue ACR-D01…12: count e budget `8*N` prima della copia,
Registri presente per EQ, scope e UUID unici, copia posseduta del vettore,
cardinalità ACTIVE/CLOSED e somma globale comprendente gli ACTIVE. Per
ogni Serie la vista e il marker del replay devono coincidere: rileggere
gli stessi byte non produce la stessa autorità. Si controlla il gate dei
CLOSED con risultati reali; le impossibilità interne possono essere
forzate soltanto da FI dichiarate e ripristinate prima del caso seguente.

Il massimo comprende DECISION anche senza prepared locale, oltre ai CSN
delle Serie. Nessun CSN e CSN zero presente restano distinti; TXID e code
non sigillate sono esclusi. Ordini, parità, bit alti e massimo u64 non
dipendono da un massimo atteso estratto dalle query del prodotto.

La catena nativa riusa namespace 0700, registri FD/nomi limitati e deadline
delle fixture CONTROL. La base in due parole passa al costruttore esistente
del registro soltanto nel test: primo CSN M+1, riporto fra parole u32,
esaurimento senza wrap. Eventuali worker reali hanno deadline, join e
un proprietario per cella dei risultati; cleanup solo dopo tutti i join.
Il test non crea un controller di prodotto né autorizza l'ammissione.

## Coordinamento, copertura e conservazione

Gli agenti scrivono file disgiunti senza eseguire test o compilazioni.
Prima dei run si chiudono gli scrittori, si congela la revisione e si
salva il lavoro. Ogni esecuzione usa il recorder esistente, anche nei
fallimenti; ogni correzione produce una revisione e un run distinti.

Lo scope `recovery-archive-csn` seleziona nove file esatti: i cinque file
non-package del modulo, `recovery/decisions-types`, `recovery/decisions-query`,
`recovery-active/types` e `recovery-active/build`. Questi ultimi rendono visibile il contesto del
marker e del suo trasferimento al risultato; non sono l'intero recovery
ACTIVE o DECISION. Il fold DECISION ora ricontrolla forma delle entry e
consumo/normalizzazione del risultato, dopo il rilievo COD-24 del revisore;
la correzione aggiunge soli controlli scalari alla scansione esistente.
I contatori sono azzerati dopo il caricamento, prima
della sola suite Archivio CSN. Il self-test controlla inclusioni/esclusioni
e rilevamento di un ramo mancante. Forme e rami SBCL non sono MC/DC;
residui, codice generato e controlli delle dipendenze restano distinti.

La [revisione indipendente](archivio-csn-revisione.md) conserva due letture
dello stesso revisore, separate dalla rilettura del coordinatore e dai
run. Nessuna qualifica C1 deriva dal solo successo della suite. Restano
catalogo persistente, inventario, pubblicazione, indici e registro unico
nel controller, oltre alle verifiche complessive prima del traffico.

La raccolta usa il [collector comune](raccolta-comandi.md), manifest
esplicito, quattro worker, hash e inventario chiuso verificato da un
processo indipendente. Il produttore rimane in una raccolta separata;
nessuna append nell'archivio chiuso. Cache FASL e stato globale ricostruibile
di sb-cover sono esclusi; HTML, helper, fallimenti e raw citati sono conservati.

Nessun nuovo benchmark previsto. Tempi del recorder includono compilazione
e fixture, sotto carico esterno incontrollato: non sono throughput DB,
scalabilità, RSS o heap zero. La scansione del piano resta lavoro di
bootstrap; il costo e la completezza del catalogo sono obblighi distinti.

## Esiti conservati

La [campagna 2026-10-16](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-archivio-csn-verifica/report.md)
conserva 54 test superati, la diagnostica fallita e la correzione delle
fixture, copertura e controllo completo sulla revisione integrata.
Solo modulo: 267/301 forme e 34/36 rami; nove file grezzi di modulo e
contesto: 589/736 forme e 57/74 rami. Nessun residuo è escluso dal totale;
assenza di MC/DC o qualifica C1 mantenuta esplicita nel report.
