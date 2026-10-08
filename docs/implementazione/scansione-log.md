# Scansione dei log

Scansione in memoria dei lotti sigillati di segmento writer, control log e
`multiserie.log`, secondo [ADR-0037](../adr/0037-lotto-sigillato.md).
Il modulo [`src/recovery/`](../../src/recovery/) verifica il prefisso utilizzabile
e distingue una coda incompleta da una corruzione testimoniata da un SEAL successivo.

## Contratto e responsabilità

`arcdocdb.recovery.scan:scansiona-log` riceve un vettore di byte stabile,
un intervallo `[start,end)`, l'identificativo del file e la versione già verificata
dall'intestazione. `start` identifica il primo lotto dopo l'header o un confine
autorevole già verificato; `file-offset` è la posizione nel file di `buffer[0]`.
Per control log e multiserie, il file-id è zero.

Il chiamante fornisce `file-size` da una fonte autorevole e garantisce che il
buffer arrivi all'EOF fisico stabile: `file-offset + end = file-size`.
Una finestra parziale non autorizza una classificazione finale della coda.
Una lunghezza dichiarata nei dati non sostituisce la dimensione fisica del file.
Questa prima API non è una scansione streaming.

| Esito | Risultato |
|---|---|
| Tutti i lotti verificano cornice e SEAL | fine del prefisso, `:complete`, conteggi di lotti e record |
| Primo lotto invalido senza testimone durevole successivo | inizio di quel lotto, `:tail`, soli conteggi del prefisso |
| SEAL successivo con frontiera durevole oltre l'inizio del lotto invalido | condizione `log-corruption`, senza prefisso applicato |
| Input, formato o budget invalidi/esauriti | errore tipizzato; nessuna classificazione della coda |

Il confine restituito è un offset nel **buffer**. La condizione di corruzione
riporta anche gli offset assoluti del primo lotto invalido e del SEAL testimone,
la sua frontiera e il motivo del primo errore. Il modulo non applica record,
non pubblica dati, non apre file e non modifica il buffer.
La transizione a `FAULTED`, la registrazione dell'evento e l'eventuale chiusura
del vecchio ACTIVE restano al proprietario del log. Nessuna troncatura.

## Prefisso e risincronizzazione

Il prefisso contiguo usa il verificatore di lotto delle
[fondazioni binarie](fondazioni-binarie.md). Un lotto è utilizzabile solo per
intero: il punto `P` è il suo **inizio**, anche se l'errore riguarda un record
interno. Il semplice ritrovamento di un record valido non basta a dichiarare
corruzione.

Il prefisso verifica cornici, tipi ammessi, CRC, stamp e SEAL. La verifica
completa dei payload EDIT/DECISION e la loro applicazione appartengono ai
livelli successivi: `:complete` non certifica la semantica di quei metadati.

Da `P` la ricerca avanza di un byte, senza salti basati su lunghezze corrotte.
Ogni candidato SEAL ha dimensione fissa di 56 byte; il codec verifica CRC di
header e corpo, tipo, flag, chiave e lunghezza. Si controllano inoltre file-id,
inizio del lotto nell'area dei record e non oltre la posizione del SEAL,
e frontiera durevole non oltre l'inizio dichiarato del lotto.
Un testimone con `D > P` segnala corruzione; con `D = P` si continua.
Anche dopo un candidato integro si avanza di un solo byte.

> **Proposta** — Dopo un danno non sempre è ricostruibile l'effettivo confine
> del lotto dichiarato da un SEAL. La risincronizzazione usa quindi una
> testimonianza conservativa di CRC, identità e posizioni plausibili. Non
> richiede che il lotto del testimone sia integro: il suo corpo potrebbe
> essere danneggiato insieme al primo lotto. Un falso SEAL può rifiutare
> l'apertura, come previsto da ADR-0037; non autorizza mai il replay dei record
> oltre `P` o una loro eliminazione.

## Budget e parallelismo

> **Proposta** — I default sono 64 MiB per intervallo e per lotto, 65.536
> lotti, 65.536 record per lotto e 64 MiB di posizioni di risincronizzazione.
> Sono budget operativi configurabili, distinti dai limiti persistenti dei file.

L'esaurimento della ricerca non viene convertito in coda. Il budget di ricerca
conta le possibili posizioni iniziali dei candidati; una coda più corta di
56 byte non contiene un SEAL completo. Le somme degli offset sono verificate
nel dominio u64 prima di iniziare. Il lavoro è limitato dall'intervallo,
dai budget dei lotti e dalle posizioni effettivamente esaminate.

La scansione appartiene all'apertura/recovery, non al percorso GET.
Non promette assenza di allocazioni: gli errori creano condizioni e la lettura
ispettiva di interi u64 può materializzare bignum. Non introduce stato mutabile,
lock, attese o contatori condivisi fra Serie. Ogni scansione legge il proprio
buffer; il chiamante ne mantiene la stabilità.

## Verifica e limiti

Le prove in [`tests/recovery/`](../../tests/recovery/) esercitano entrambe le
versioni e i tre tipi di log, troncamenti, corruzioni, frontiere prima/uguali/dopo
`P`, identità e offset, budget, input incompleti e immutabilità del buffer.
La [tabella delle decisioni](scansione-log-decisioni.md) collega i controlli
ai casi di regressione.

Due prove aggiuntive alterano un bit alla volta in ogni byte di tre lotti,
per i tre tipi di log e le due versioni: 13.504 casi prima di un testimone
successivo e 6.752 nel lotto finale, 20.256 complessivi. Le fixture usano
packing bytewise e CRC bitwise indipendenti dal prodotto; controllano
classificazione, confine, conteggi e immutabilità del buffer.
Un ulteriore caso costruisce due SEAL integri sovrapposti: un candidato
non conclusivo non deve far saltare quello successivo. Le prove recovery
sono complessivamente 19.

Requisiti: REQ-FOR-001/003, REQ-AFF-008/009/017. Invarianti interessati:
INV-F1/F2/F3, INV-A4/A8/A9, INV-P6 e INV-X3. Nessun requisito del motore è
promosso a verificato sulla sola evidenza di questa scansione.

Resta il limite dichiarato in ADR-0037: un danno nell'ultimo flush, senza un
SEAL successivo che lo testimoni, può essere indistinguibile dalla coda.
CRC32C ha collisioni e non autentica i dati. Le prove in memoria non verificano
I/O, recovery completo, semantica dei payload, manifest, decisioni multiserie
o transizioni di salute. Nessun gate di rilascio viene chiuso qui.
