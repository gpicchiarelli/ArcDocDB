# Contratto GET per il benchmark

Suite autonoma di **19 test**, package `arcdocdb.get.performance.tests`, registro
`*get-performance-tests*`, entry point `run`. Il modulo ASDF `get-performance`
carica `support`, `paths`, `guards`, `threads` in questo ordine. Questa suite
non dipende da `tests/get` o dalle sue fixture.

I sorgenti sono consegnati **senza compilazione o esecuzione**. Il runner del
padre congela i sorgenti e registra tutte le prove. I casi e le asserzioni
descritti qui sono copertura predisposta, non risultati già ottenuti, né
copertura MC/DC. Nessuna asserzione di zero heap, latenza o throughput.

## Fixture e oracoli

- Chiave binaria di 16 byte, valori deterministici di 16, 256 e 4096 byte.
- Header segmento e PUT v1/v2 codificati con little endian e CRC32C bit per bit
  indipendenti dai writer e dal CRC del prodotto. I valori sono payload opachi
  dello storage; la suite non qualifica un codec CBOR.
- Segmento nativo readonly, ID 17, PUT a offset 64, frontiera `104 + V`.
  Undici byte sono fisicamente presenti oltre la frontiera: la lunghezza del
  file non costituisce prova del prefisso committed.
- Indice reale con seme `12345678:9abcdef0`, CSN 7 o `ffffffffffffffff`;
  payload atteso del candidato costruito indipendentemente dal lookup.
- Cache opzionale con classe 8192 e un insieme di otto posti; EBR e snapshot
  reali. Snapshot a tempo 10, GET a 11, conclusione a 12, deadline a 30.
- Ogni GET eseguito dal driver controlla stato candidato, cinque word,
  fonte/cache/inserimento, stato verified/copied, fine copia, tutti i byte
  della risposta, sentinelle, risultato/lunghezza e pin zero. Nessuna verifica
  limitata all'ultima iterazione o a una checksum accumulata.
- L'osservatore I/O intercetta tentativi di pread ma delega al backend POSIX
  nativo. I normali casi file richiedono una lettura PUT completa; cache hit e
  miss corrente richiedono zero letture dopo il setup dell'header.

## Casi e selezione dei mutanti

| Nome della funzione test | Contratto/oracolo principale |
|---|---|
| `test-REQ-AFF-002-performance-file-v1-value16` | v1, file, CSN 7, valore 16, tre operazioni verificate |
| `test-REQ-AFF-002-performance-file-v1-value256` | v1, file, valore 256 |
| `test-REQ-AFF-002-performance-file-v1-value4096` | v1, file, valore 4096 |
| `test-REQ-AFF-002-performance-file-v2-value16` | v2, file, valore 16 |
| `test-REQ-AFF-002-performance-file-v2-value256` | v2, file, valore 256 |
| `test-REQ-AFF-002-performance-file-v2-value4096` | v2, file, valore 4096 |
| `test-REQ-CCH-002-performance-cache-hit-v1` | tre dimensioni, hit da sonda e da leggi-record, zero pread |
| `test-REQ-CCH-002-performance-cache-hit-v2` | come sopra per v2 |
| `test-REQ-IDX-001-performance-absent` | miss corrente v1/v2, cache presente/assente, risposta intatta, pin zero |
| `test-REQ-MVC-005-performance-snapshot-boxed-late` | limite snapshot 7/max-u64, hit visibile; API numerica snapshot consultata dopo GET |
| `test-REQ-MVC-004-performance-snapshot-final-authorization` | futuro e miss richiedono storico; deadline dopo copia non autorizza risposta |
| `test-REQ-AFF-002-performance-output-copy` | **mutante copia**: tutti i byte, offset output 0/3/8, tre dimensioni, sentinelle |
| `test-REQ-AFF-002-performance-prefix-boundary` | **mutante frontiera**: fine esatta ammessa; fine meno un byte rifiutata anche con cache calda, zero I/O |
| `test-REQ-AFF-002-performance-max-u64-verification` | **mutante CSN**: max-u64 positivo; mismatch nei bit 0 e 63 con CRC valide rifiutato |
| `test-REQ-CCH-004-performance-cache-crc-fallback` | **mutante cache CRC/fallback**: bit del valore cache alterato, verify-failed, vera pread, risposta integra |
| `test-REQ-AFF-002-performance-persistent-crc-guard` | **mutante CRC persistente**: header/body corrotti, due GET rifiutati, risposta intatta, pin zero |
| `test-REQ-CMP-007-performance-cleanup` | **mutante cleanup**: error/throw in candidate/verified/copied, niente autorizzazione, pin zero e riuso sano |
| `test-REQ-CCH-004-performance-cache-repair-hit` | regressione: nuova copia raggiungibile dopo fallback anche con vecchio posto rifiutato/disabilitato |
| `test-REQ-CON-004-performance-shared-readers4` | quattro reader, 28 buffer distinti, file/cache, v1/v2, 16 GET verificati per worker, pin zero dopo tutti i join |

I sei nomi in grassetto indicano i test consigliati al runner per 4–6 mutanti.
La capacità di uccidere uno specifico mutante deve essere registrata dal runner;
qui non è rivendicata senza esecuzione.

Il test parallelo sincronizza soltanto la partenza prima di EBR. Non introduce
attese sotto pin e non rivendica una particolare sovrapposizione di syscall o
la verifica di tutte le finestre interne di concorrenza. La lock dell'osservatore
è della sola fixture; viene disabilitata nel caso parallelo.

## API riusabile, facoltativa

`make-get-performance-fixture` accetta keyword:

- `:version` 1/2; `:value-bytes` 16/256/4096; `:csn` (default 7).
- `:cache-p` booleano; `:workers` 1..4; `:record-bytes` (default `40 + V`).
- `:snapshot-p`; `:snapshot-csn` (default CSN del candidato).
- `:observe-io-p` (default T). Usare NIL nelle misure: niente eventi o lock
  dell'osservatore nel percorso da cronometrare.
- `:record-csn` e `:image-mutator` sono FI di setup per i test negativi.

`close-get-performance-fixture` è idempotente e richiede che tutti i reader
siano già joined. `with-get-performance-fixture` installa tale cleanup.

Gli accessor esportati `get-performance-fixture-{key,missing-key,value,view,
segment,valid-bytes,contexts,outputs,epochs,snapshot,generation,cache,version,csn}`
espongono le risorse di setup. Ogni worker usa soltanto `contexts[i]` e
`outputs[i]`; il controller osserva contesti e annunci dopo join. Chiave,
valore atteso e vista rimangono stabili. Nessun thread viene avviato dalla
creazione e nessuna cache viene scaldata implicitamente.

`performance-checked-get` è un driver di correttezza che alloca oracoli e
asserzioni; **non è il corpo da cronometrare**. Keyword `:worker` (default 0),
`:path` (`:file`, `:cache-hit`, `:cache-record`, `:absent`), `:expected-cache`,
`:expected-insertion`, `:finish-now` (default 12). Per il primo GET con cache
vuota passare `:expected-cache :miss :expected-insertion :inserted`. Per un
GET caldo usare `:cache-hit` oppure `:cache-record`.

`performance-read-events` restituisce una copia degli eventi `(offset count)`;
`performance-clear-read-events` li azzera senza reader in volo. I contatori
iniziali escludono la lettura dell'header. Queste API non sono necessarie per
un benchmark che possiede già fixture autonome.

## Limiti

Suite focalizzata sulle operazioni del benchmark; prepared/OUTCOME, resolver
storico, matrice completa di alias/owner/ordine e fault injection del controller
appartengono alla suite funzionale separata. La variante “boxed late” controlla
la semantica e la consultazione finale della API numerica: non dimostra dove
SBCL alloca bignum. Il driver di correttezza materializza anche il candidato
e non deve essere usato come prova di allocazione del kernel GET.

## Riparazione e concorrenza

Il precedente rilievo sul tag rifiutato che nascondeva la copia reinserita
è già corretto: `cerca-record-cache` salta i posti rifiutati o disabilitati
prima del confronto del tag. Il test
`test-REQ-CCH-004-performance-cache-repair-hit` richiede un HIT dopo il
fallback e verifica anche il vecchio posto disabilitato.

Le letture concorrenti di questa fixture partono da una cache già popolata.
La [suite della cache](../cache/README.md) aggiunge contesa, inserimenti e
sostituzioni concorrenti; i due ambiti restano distinti.
