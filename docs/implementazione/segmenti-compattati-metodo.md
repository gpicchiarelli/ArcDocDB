# Metodo di verifica dei segmenti compattati

Ambito registrato prima delle campagne: verifica in memoria del prefisso CLOSED
di un segmento origine compaction, secondo [formati su disco](../formati-su-disco.md)
e [ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md).
Nessuna applicazione, I/O, manifest, ricostruzione di indici o resolver.

## Contratto e oracoli

Buffer stabile che inizia all'offset zero del file e contiene almeno
`valid-bytes` byte. Serie, segment-id e lunghezza valida provengono dalla fonte
autorevole. Si verificano header, versione e origine compaction; dall'offset
64 al limite valido, solo PUT/TOMBSTONE ordinari con cornice e CRC completi.
Il limite logico CLOSED non viene presentato come EOF fisico allo scanner
dei lotti. Nessuna classificazione TAIL: un record incompleto nel prefisso
autorevole è corruzione; i byte dopo il limite valido non sono interpretati.

Fixture manuali: magic ASCII, packing bytewise, CRC32C bitwise indipendente.
Storie di record dichiarate alimentano i conteggi attesi senza il decoder
del prodotto. Entrambe le versioni, chiavi e body diversi, record disallineati,
CSN u64 estremi e flag contratto-versionato dei PUT ordinari.

Prove negative: identità diversa in ogni byte e in entrambe le metà del
segment-id; header alterato e versione ignota con CRC valido; origine writer;
prepared PUT/TOMBSTONE e record OUTCOME/SEAL/EDIT/DECISION integri; tutti i
punti di troncamento del contenuto, con successo soltanto sui confini noti;
alterazione di ogni bit di una fixture piccola; lunghezze incoerenti riparando
il CRC; input e budget invalidi/esatti/esauriti; buffer invariati, compresa
la coda fisica ignorata. I risultati vengono restituiti soltanto al termine.

## Campagne e criteri

Build senza warning/style-warning, lint, collegamenti, tracciabilità e check
integrato. Due letture C1 su formato/errori e poi limiti/ownership/decisioni.
Copertura strumentata separata con self-test del ramo mancante, conservando
il denominatore completo. Mutazioni in copie isolate, baseline invariata
obbligatoria e self-test del classificatore: origine, tipi ammessi, prepared,
limite valido, budget byte/record, versione dal file e conteggi. Una compilazione
fallita non conta come difetto rilevato. Tutti i tentativi rimangono conservati.

Misura seriale del percorso riuscito: fixture preallocate da 64 byte e da
256 record (PUT/TOMBSTONE alternati), entrambe le versioni; cinque repliche di
4.096 chiamate, warmup 128 e GC completo prima di ogni replica. Tempo monotono,
delta heap SBCL e risultato osservabile. Self-test con baseline nulla e
controllo positivo 16 × 1 MiB. Criterio zero heap misurato; nessuna soglia di
throughput promessa e nessuna assenza assoluta di allocazioni dedotta dal
contatore. Un worker, safety 3, carico esterno non controllato, niente I/O.

Le prove riguardano il verificatore in memoria. Non promuovono requisiti del
motore né chiudono recovery, transazioni, compaction o gate di rilascio.
