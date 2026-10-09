# Metodo di verifica della tabella delle decisioni

Ambito registrato prima delle campagne: ricostruire in memoria la tabella
TXID → CSN e insieme dei partecipanti dal prefisso verificato di
`multiserie.log`, secondo [ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md).
Il modulo non applica record, non modifica log e non decide lo stato del catalogo.

## Contratti da verificare

- Il verificatore dei lotti e la ricerca di corruzione terminano prima di
  restituire qualsiasi tabella. Solo una tabella costruita con successo
  permette di interpretare un TXID assente come presumed abort.
- Il prefisso contiene solo lotti completi; una coda incompleta non aggiunge
  decisioni. Un payload DECISION malformato nel prefisso che ha superato la
  verifica delle cornici e dei SEAL è corruzione semantica, non una nuova
  coda da ignorare. Una cornice sotto la lunghezza minima è invece un errore
  dello scanner: coda senza testimone successivo, corruzione con un SEAL
  successivo la cui frontiera durevole copre l'inizio del lotto invalido.
- Ogni decisione contiene almeno due partecipanti distinti. Ripetere uno
  stesso TXID con CSN e insieme dei partecipanti identici è idempotente;
  cambiamenti di CSN o insieme sono un conflitto dichiarato. L'ordine dei
  partecipanti non cambia il significato della decisione.
- TXID e CSN sono u64 opachi: non si impongono ordine del log, positività
  o unicità del CSN fra TXID diversi. Gli identificativi di Serie sono
  confrontati su tutti i 16 byte.
- La tabella possiede i dati copiati. Modificare il buffer sorgente dopo
  la costruzione non cambia le consultazioni; nessun vettore interno è
  restituito al chiamante.
- I budget contano i record e i partecipanti letti prima di coalescere i
  duplicati. Limiti esatti accettati; superamenti o input invalidi producono
  errori tipizzati e nessun risultato parziale, anche per un log vuoto.
- Le query verificano il range e la lunghezza dell'ID di Serie anche quando
  il TXID cercato non esiste. Gli esiti includono una presenza esplicita,
  così CSN zero e decisione assente rimangono distinguibili.

## Prove e oracoli

Fixture di cornici, payload e SEAL con packing bytewise e CRC bitwise
indipendenti dai codec del prodotto. Storie dichiarate come dati alimentano
un oracolo a liste e insiemi; confronto con le consultazioni della tabella
per entrambe le versioni del formato, ordine arbitrario e offset non nulli.
Il seme delle storie generate è fisso e riportato nel test.

Troncamento a ogni byte dei lotti, corruzione prima di un SEAL testimone,
budget di ricerca insufficiente, payload semanticamente invalido con CRC
e SEAL corretti, duplicati permutati e discordanti, identificativi con bit
alti o differenze nell'ultimo byte, valori u64 estremi, budget zero/esatti
e superati, immutabilità del sorgente e ownership del risultato.

Compilazione senza avvisi, lint, tracciabilità e `make check`. Campagne di
copertura e mutazione separate dai test ordinari; self-test degli strumenti.
I record conservano comandi, ambiente, hash prima/dopo, output e tentativi
falliti. Due letture C1 controllano i contratti e la tabella delle decisioni.

La campagna mirata deve rilevare ogni mutante compilabile selezionato:
limiti di record/partecipanti, uguaglianza del CSN e dell'intero ID16,
partecipanti duplicati e presenza esplicita nella query. Un errore prima
dell'avvio dei test non conta come rilevamento; mutanti non compilabili
vengono corretti conservando il tentativo iniziale.

## Limiti

Percorso di apertura/recovery: copie, ordinamento e condizioni possono
allocare. Nessuna promessa di zero heap o prestazioni del database;
nessun benchmark di I/O viene dedotto da queste prove in memoria.
Il chiamante verifica l'intestazione e la dimensione fisica stabile del log.
Catalogo, manifest, risoluzione/applicazione dei prepared, compattazione,
flush e punto di atomicità del recovery restano moduli separati.
Le prove locali non chiudono un gate di qualifica del motore o MC/DC.
