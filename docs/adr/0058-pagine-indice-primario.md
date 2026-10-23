# ADR-0058 — Pagine derivate dell'indice primario

- **Stato:** Accettata nell'implementazione incrementale autorizzata dall'autore
- **Data:** 2026-10-22
- **Rapporto con la specifica:** concretizza il formato di pagina di ADR-0049 e
  l'incremento I2 di ADR-0057; non sostituisce il primario residente, i log o il commit
- **Riferimenti:** REQ-IDX-009, INV-I8, INV-A2, INV-A8, INV-P6;
  [formato e verifica](../implementazione/pagine-indice.md)

## Decisione

Il formato ARCIPG01, versione 1, usa pagine little-endian di 4096, 16384 o
65536 byte. La dimensione sara' uniforme in un'immagine dell'indice e non
cambiera' in-place. L'header di 96 byte contiene identita' della Serie,
immagine, offset fisico, generazione, geometria e due CRC32C distinti.
Il codec opera soltanto su buffer posseduti; non scrive file o root.

Tre tipi: bucket flat con controlli a sette bit e gruppi da 16, directory
radix con PageRef da 16 byte, frammento di chiave. Il bucket conserva digest,
CSN, location e lunghezza v2; nessun albero ordinato sostituisce la ricerca
flat. Non si serializzano seqlock o oggetti Lisp. Un bucket immutabile usa
solo EMPTY e fingerprint vivi, senza tombstone; DELETE e history restano
responsabilita' del futuro backend e dei protocolli MVCC esistenti.

PageRef = (offset, generazione), nel dominio (Serie, immagine, dimensione).
Zero/zero e' assenza. Gli offset positivi sono allineati, sotto 2^60 e mai
riutilizzati nella stessa immagine. Ogni riferimento punta a offset minore
del genitore e generazione non maggiore: si costruiscono figli prima dei
genitori, inclusi overflow e frammenti di chiave dal fondo. I grafi locali
non possono formare cicli; raggiungibilita', copertura e durabilita' complete
sono ancora obblighi dell'integrazione. Nessun wrap o riciclo di identita'.

Le chiavi inline sono impacchettate in ordine fisico degli slot, senza
sovrapposizioni o buchi. Le chiavi esterne, fino a 65535 byte, usano frammenti
con totale e posizione verificabili. Catene e hash identici non si considerano
risolti dal digest: il futuro lookup confronta i byte completi con budget
esplicito. Il codec controlla forma e sondaggio locale, non ricalcola l'hash
senza il seme autorevole e non certifica unicita' o visibilita' committed.

## Fondamento e alternative

- [Swiss tables](https://abseil.io/about/design/swisstables): controlli compatti
  e fingerprint; coerenti con ADR-0015/0043 e il codice residente.
- [PostgreSQL hash](https://www.postgresql.org/docs/13/hash-implementation.html):
  bucket e pagine di overflow sono un pattern persistente consolidato.
- [SQLite](https://www.sqlite.org/fileformat.html#cell_payload_overflow_pages):
  pagine dedicate ai payload lunghi evitano un limite implicito pari alla pagina.
- [CouchDB](https://docs.couchdb.org/en/stable/intro/overview.html): strutture
  derivate append-only; la topologia con figli precedenti e' una scelta specifica
  verificabile di ArcDocDB, non una garanzia ereditata da CouchDB.

Un B-tree cambierebbe algoritmo e carico senza evidenza necessaria. Una sola
directory residente riprodurrebbe il limite RAM. mmap non rende esplicito
il budget dei frame. Si supportano tutte e tre le taglie; una preferenza
prestazionale richiede benchmark e non si deduce dal codec.

## Atomicita', rollback e limiti

Serializzare e verificare una pagina prepara soltanto un derivato in RAM.
Il formato non contiene un nuovo commit marker; SEAL/EDIT/DECISION mantengono
autorita'. File container, assegnazione delle identita', pubblicazione delle
root, flush, snapshot, cache, reclamation e recovery oltre RAM saranno integrati
separatamente prima dell'uso nel motore. Un'immagine incompleta non e' pronta.
Il rollback corrente rimuove il codec non collegato, senza migrare dati utente.

I2 qualifica la rappresentazione locale, non il grafo completo, lo storage
oltre RAM, il progresso lock-free o le prestazioni. Le verifiche includono
fixture indipendenti per tre taglie/tipi, chiavi massime, collisioni, overflow,
pagina piena, directory da split, troncamenti, CRC, identita' e alterazioni con
CRC ricalcolati. Nessuna modifica agli ADR gia' accettati e agli archivi chiusi.
