# Fondazioni binarie

Cornice dei record, CRC32C e verifica dei lotti. Codice Common Lisp, vettori specializzati,
nessuna dipendenza esterna. Riferimenti: [formati su disco](../formati-su-disco.md),
[ADR-0039](../adr/0039-cornice-unica-dei-record.md),
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md),
[standard di codifica](../affidabilita/standard-di-codifica.md).

## Ambito

Sono implementate primitive in memoria. Il modulo prepara e verifica byte; il proprietario
del segmento governa I/O, commit, visibilità e transizione a `FAULTED`. Nessuna scrittura su
file, sincronizzazione, cancellazione, attesa o modifica dell'indice viene eseguita qui.

Le strutture `EDIT` e `DECISION` sono verificate soltanto nella cornice e nella lunghezza
minima. Il loro contenuto, il CBOR e la profondità del documento spettano ai decoder
dedicati. Un record integro può essere non committed; un SEAL integro non attesta da solo
che sia avvenuto un `fsync`.

## Contratti

Tutti i buffer sono `simple-array (unsigned-byte 8)`. Gli intervalli sono `[start,end)`;
versione e origine del buffer sono esplicite. I tipi Lisp dichiarati sono precondizioni;
con `safety 3` una violazione dei tipi è rilevata dal runtime. Gli errori di cornice e budget
appartengono alla gerarchia `arcdocdb-error`.

| Operazione | Garantisce | Restituisce |
|---|---|---|
| `crc32c` | CRC32C incrementale, senza copie | checksum finalizzato |
| `scrivi-record` | controlli prima della prima mutazione; CRC header/body; cornice v1/v2 | fine del record |
| `verifica-record` | header CRC prima delle lunghezze; limiti, tipo, flag e body CRC | fine, tipo, flag, stamp, range di chiave e valore |
| `verifica-put` | verifiche della cornice e corrispondenza con chiave, CSN e flag dell'indice | range del valore |
| `verifica-lotto` | record ammessi dal tipo di log, stamp applicabile, SEAL, file, offset, count, CRC del lotto e budget | fine, stamp del SEAL, frontiera dichiarata, count |

`scrivi-record` richiede un buffer esclusivo e input che non siano alias del buffer di
destinazione. Un rifiuto di validazione lascia la destinazione invariata. I reader richiedono
buffer stabili per tutta la chiamata **e per l'utilizzo dei range restituiti**: il proprietario
mantiene il pin o il riferimento fino al termine della lettura.

Per un PUT prepared, il resolver deve fornire un OUTCOME **nello stesso segmento e in un
lotto committed**. Il codec verifica byte, TXID e CSN della prova; la provenienza e il commit
restano precondizioni del resolver. Un numero passato come prova non è accettato.

Nel lotto, PUT e TOMBSTONE ordinari ed EDIT devono avere lo stamp del SEAL. PUT/TOMBSTONE
prepared, OUTCOME e DECISION portano un TXID: non viene confrontato con il CSN del SEAL.
Questa distinzione segue i campi dei [formati](../formati-su-disco.md).

## Memoria e parallelismo

Le tabelle CRC32C sono private: costruzione all'avvio, sole letture dopo la pubblicazione.
Gli altri dati appartengono al chiamante. Tra Serie non esistono lock, code, contatori o
scritture condivise per operazione. Il modulo rende seriale soltanto l'accesso al buffer
esclusivo affidato alla singola chiamata.

Il codec usa range sul buffer e valori multipli; non crea copie del documento né oggetti
per entry. Tutte le scansioni sono limitate dalle dimensioni verificate. La verifica dei
lotti ha budget separati di byte e record e controlla la dimensione prima di scandire il
body successivo. Il superamento del budget è distinto dalla corruzione.

> **Proposta** — Il percorso GET confronta gli interi a 64 bit come due word a 32 bit,
> dopo la verifica della cornice. Evita di materializzare un bignum, mantenendo il confronto
> completo. L'API ispettiva `verifica-record` e la lettura di interi tramite `leggi-u64`
> possono invece allocare per valori oltre il fixnum. Non sono dichiarate prive di allocazioni.

## Verifica riproducibile

```sh
make test lint
sbcl --noinform --no-userinit --script tools/foundation-bench.lisp --self-test
sbcl --noinform --no-userinit --script tools/foundation-bench.lisp --bench
sbcl --noinform --no-userinit --script tools/foundation-coverage.lisp --self-test /tmp/foundation-cover-probe/
sbcl --noinform --no-userinit --script tools/foundation-coverage.lisp --report /tmp/foundation-cover/
sbcl --noinform --no-userinit --script tools/foundation-mutation.lisp --self-test
sbcl --noinform --no-userinit --script tools/foundation-mutation.lisp --run /tmp/foundation-mutants-new/
```

La destinazione delle mutazioni deve essere nuova. Ogni mutante compila ed esegue i test
in una copia separata; un fallimento precedente all'avvio dei test non vale come rilevamento.
La copertura usa una cache ASDF distinta. I benchmark si eseguono dopo i controlli, in un
processo senza strumentazione di copertura, senza altre campagne di misura concorrenti.

Le **26 prove** comprendono vettori CRC noti, oracolo CRC bitwise, confronto di oltre 2.000
intervalli/allineamenti, packing indipendente, v1/v2, valori u64 estremi, documento da 16 MiB,
chiave da 65.535 byte, ogni troncamento di fixture, bit flip in ogni byte, campi malformati con
CRC validi, mismatch dell'indice, prova OUTCOME e budget del lotto. Le fixture non verificano
la semantica del CBOR o dei protocolli durevoli.

Le [nove mutazioni mirate](risultati/2026-10-08-mutazioni.lisp) verificano polinomio, confronti CRC, soglia della chiave, `and`/`or`
dell'identità, flag prepared, checksum del SEAL, stamp e budget. Il risultato è relativo a
questa famiglia dichiarata: **9/9 rilevate**, non una misura di tutti i mutanti possibili.

## Prestazioni

Le [misure grezze](risultati/2026-10-08-benchmark.lisp) registrano ambiente, impronte dei
sorgenti, iterazioni, durata e byte heap per ciascuno dei cinque campioni. Sono microbenchmark
seriali in memoria su Apple M4, ARM64, SBCL 2.6.9, `safety 3`, con buffer già allocati e cache
calda. Non misurano NVMe, latenza di rete, `fsync`, concorrenza, P95/P99 delle richieste o
throughput del database. Le impronte MD5 identificano i sorgenti; non ne attestano l'autenticità.

Le campagne includono CSN ordinario e massimo u64, encoding con massimo u64 e verifica
prepared con TXID e CSN alti. Il self-test del contatore verifica sia assenza di allocazioni
nella fixture di controllo sia rilevamento di allocazioni deliberate. Zero byte rilevati
vale per gli input e il percorso riuscito misurati; gli errori possono allocare condizioni.

Mediana dei cinque campioni, 2026-10-08:

| Campagna | Operazioni/s | MiB/s | Byte heap rilevati in ciascun campione |
|---|---:|---:|---:|
| CRC32C, 2 KiB | 342.139 | 668,2 | 0 |
| CRC32C, 16 MiB | 41,4 | 662,9 | 0 |
| Verifica PUT, valore 2 KiB | 310.462 | 618,2 | 0 |
| Encoding PUT, valore 2 KiB | 308.547 | 614,4 | 0 |
| Verifica PUT, massimo u64 | 310.247 | 617,8 | 0 |
| Encoding PUT, massimo u64 | 306.183 | 609,7 | 0 |
| Verifica prepared, TXID/CSN alti | 290.175 | 586,7 | 0 |

Per CRC32C il conteggio dei byte è quello del buffer; per i record include chiave e header;
per prepared include anche OUTCOME. Il documento da 2 KiB ha chiave da 16 byte.

## Decisioni e revisione

La [tabella delle decisioni](fondazioni-decisioni.md) collega i predicati alle prove. Due
letture hanno controllato formato e confini, poi proprietà dei buffer, budget, stamp e
allocazioni. Build senza `warning` o `style-warning`; linter senza violazioni.

Requisiti collegati: REQ-FOR-002, REQ-FOR-003, REQ-FOR-004, REQ-LIM-001, REQ-LIM-003,
REQ-AFF-002, REQ-AFF-004, REQ-VAL-001. Invarianti interessate: INV-A2, INV-A3, INV-A4,
INV-A8, INV-P6 e INV-X3. Lo stato dei requisiti completi resta distinto dalle evidenze di
queste primitive: nessun requisito del motore è promosso a verificato automaticamente.

### Criteri ancora da chiudere

I [dati grezzi di `sb-cover`](risultati/2026-10-08-copertura.lisp) non equivalgono a MC/DC.
La copertura include forme di definizione e
corpi delle funzioni inline; i dati grezzi vanno esaminati senza togliere dal denominatore
forme non eseguite. La qualifica C1 richiede la chiusura della copertura e delle eccezioni
secondo il [piano di verifica](../affidabilita/piano-di-verifica.md), revisione indipendente
e successiva verifica del collegamento a I/O, resolver e transizioni `FAULTED`.

I limiti residui includono collisioni CRC32C, mutazione concorrente del buffer se il
proprietario viola il contratto, incompletezza dei decoder dei payload di controllo e
assenza di prove di crash sul motore integrato. CRC32C non è autenticazione. Questo modulo
non chiude i criteri di rilascio del database.
