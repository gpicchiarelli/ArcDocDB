# Riserve full text — metodo e decisioni

Incremento del 17 ottobre 2026 per ADR-0054, REQ-SEC-003/006/010 e REQ-CON-002.
Prima dell'esecuzione: fixture documentale NNTP manuale di 25 byte, due configurazioni,
73 byte di payload e U=145 per ciascuna. Modello indipendente su 128 operazioni;
confronti dei run copiati e ricerche subject/body. Bordi cumulativi, ultima configurazione
rifiutata, rotazione, cancellazione durante tutte le unita della piccola copia,
generation/lease stale, sedici generazioni e quattro writer indipendenti.

Heap: 100 warm-up, GC completa, 1000 prenotazioni/copie/query/cancellazioni; ID 1 e
UINT64_MAX. Nessuna asserzione di latenza, RSS o durata realtime. Misura separata
dalla copertura diagnostica, che esclude i test di allocazione. Conservare output
originali e fallimenti; `make check` verifica anche integrazione, strumenti e spike.

| Decisione composta | Condizioni da verificare |
|---|---|
| Costruzione | coda, 1..16 configurazioni, ordine ID/generazione, otto indici e due generazioni, capacita e costi prima delle allocazioni |
| Lease | pool canonico, thread e generation della coda, stato sano, nessun effetto pendente |
| Slot | oggetto canonico del pool, generation catturata positiva e senza wrap |
| Sorgenti | tutti DONE, configurazioni canoniche attuali, nessun borrower, stessa row, run SEALED e costo coerente |
| Ammissione | tutte le capacita fisiche, delta/staging cumulativi, tutti i bound file, row non gia trattenuta |
| File | costo fisso una volta; richiesta maggiore del file vuoto distinta da rotazione prima dell'append |
| Copia | prestito ancora posseduto; un byte/parola o transizione per passo; risultato solo dopo tutti gli indici |
| Cancellazione | solo prima del trasferimento, rilascio esatto e idempotente fino al riuso; stale/trasferiti rifiutati |
| Trasferimento | solo READY, staging restituito, delta/file/slot conservati senza reclaim per assenza |
| Interruzione | effetto incompleto o fonte persa => pool FAULTED, riferimenti conservati, fail-stop della Serie al confine del caller |

La qualifica C1 completa e MC/DC restano aperte. Le due letture finali devono distinguere
questa riserva locale dalla validazione generale del documento e dal binding agli esatti
byte del PUT. Il pool non esegue append, SEAL, PREPARE, DECISION, H/ACK o query MVCC.
Non e l'allocatore del catalogo o l'inventario durevole di un ACTIVE esistente.

## Due letture del 17 ottobre 2026

Lettura 1, dati e budget: riletti tutti i preflight prima dell'effetto, il costo fisso
una volta per file, le somme di tutte le generazioni e la distinzione richiesta troppo
grande/rotazione. Aggiunta una prova con prima configurazione ammessa e seconda rifiutata
per token o bound. Le larghezze della copia usano le costanti del run esistente.

Lettura 2, ownership e guasti: riletti i borrower, il rilascio del singolo task a copia
conclusa, generation e lease catturate, cancellazione prima del trasferimento e costi
permanenti dopo. Le uscite incomplete conservano gli effetti parziali e impongono fail-stop.
Non sono revisione indipendente: binding PUT, pipeline WAL, prepared, pubblicazione e
quiescenza restano da collegare. La factory richiede un pool autorevole e un ACTIVE nuovo;
non dimostra canonicalita ne fa sparire i costi di altri pool o delle viste congelate.
