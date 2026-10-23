# Metodo: lotti WAL e compito I/O

Registrato prima dell'implementazione. Ambito: buffer preallocato del lotto,
CSN assegnato dal chiamante alla chiusura, SEAL, gruppi limitati, singolo compito
I/O per log e frontiere dopo write/flush. Nessun catalogo, indice, conferma al
client, scheduler, rollover o transazione completa.

## Contratti

- Il buffer privato è mutabile solo nel lotto aperto. Alla chiusura si assegna il
  CSN ai record ordinari, preservando i TXID prepared/OUTCOME/DECISION. CRC delle
  intestazioni e CRC aggregato sono ricalcolati; SEAL contiene posizione, file,
  numero di record e frontiera durevole nota, con budget verificati prima.
- Tutti i buffer e vettori sono allocati all'inizializzazione. I gruppi hanno
  capienza finita e contengono lotti contigui dello stesso file/versione/log.
- La preparazione non effettua I/O. Write e flush appartengono al compito del
  pool I/O. Un CAS locale al log impedisce un secondo gruppo in volo, senza attesa
  o scrittura condivisa tra Serie. Una sola transizione autorizza il flush.
- Write completata e flush completato sono distinti. Un guasto impedisce nuove
  operazioni e coperture; non si pubblica né si conferma dopo un guasto.
- La copertura async vale solo per i dati; group/strong richiedono durability.
  La copertura dei byte non prova la pubblicazione dell'indice o l'esito 2PC.
- Il riuso di lotti/gruppi preallocati richiede completamento durevole e assenza
  di riferimenti/consumatori; il chiamante possiede questo protocollo di durata.

## Prove e misure

Confronto con codec/verifica-lotto e scansione recovery v1/v2: lotti vuoti e
non vuoti, PUT/tombstone/prepared/OUTCOME, EDIT/DECISION, stamp u64 al limite,
offset fisico non zero, frontiera storica e scritture in gruppo. Backend iniettato
per EIO/ENOSPC/EINTR, short write, crash a ogni prefisso, flush fallito,
operazioni ripetute, riuso prematuro e concorrenza di gruppi sul medesimo log.

Misure separate dai test: buffer preallocati, warmup, GC completo, cinque campioni,
safety 3, heap e tempo. Misurare formazione/sigillatura e I/O simulato senza
generalizzare a latenza o throughput del database. Conservare comando, ambiente,
hash, output e fallimenti con `tools/record-command.lisp`; pubblicare catalogo,
copertura grezza e mutazioni. C1 e integrazione del motore restano gate separati.
