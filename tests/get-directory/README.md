# Test della directory GET CLOSED

Package `arcdocdb.get.directory.tests`, ingresso `run`, registro `*get-directory-tests*`.
Ordine dei sorgenti: `support`, `construction`, `read`, `threads`. L'integrazione ASDF,
la compilazione e tutte le esecuzioni sono responsabilità del padre dopo il congelamento.
In questa consegna non sono stati caricati sorgenti Lisp né eseguiti test, benchmark,
mutanti o check. I casi descritti sono codice predisposto, senza esiti di esecuzione.

## Contratto condiviso della fixture

`support.lisp` contiene soltanto definizioni di package, condizioni, fixture ed encoding;
non contiene `deftest`, registrazioni di casi, chiamate al runner o setup automatici.
Può essere caricato dal benchmark dopo `arcdocdb/tests`, fuori dalle finestre misurate.

```lisp
(make-directory-fixture :count 1 :value-bytes 16 :workers 4 :version 2
                        :csn #xffffffffffffffff :cache-p t)
(close-directory-fixture fixture)
```

La firma e gli accessor pubblici sono definiti in `support.lisp`. `view`, `directory`,
`maps`, `keys`, `values`, `contexts`, `outputs`, `epochs`, `index`, `files`, `paths`,
`ids`, `ends`, `images`, `manifest`, `scope`, `cache`, `snapshots`, `snapshot` e
`generation` si leggono con il prefisso `directory-fixture-`.

- `keys` e `values`: simple-vector di N elementi; ogni chiave è un u8 semplice di 16 byte.
- `maps`: simple-vector di N mappe native costruite dall'API pubblica del resolver.
- `contexts`: simple-vector di `workers` contesti, da 1 a 4; scratch esclusivi.
- `outputs`: **sempre** simple-vector di quattro u8 distinti di `value-bytes+6`,
  inizializzati a `#xcc`; copia da offset 3, tre sentinelle per lato.
- ID crescenti non contigui: `17+2*i`, con ultimo ID `#xffffffff`, anche per N=1.
- Primary con seme fisso `#x12345678/#x9abcdef0`; digest e pubblicazione tramite API pubbliche.
  Arena chiavi `16*(N+4)` byte: quattro richieste FI aggiuntive senza cambiare i profili.
- Cache: una classe, minima 1024, prima potenza di due che contiene `40+value-bytes`,
  **256 set e otto posti per set**, una stripe. Payload autorizzato
  `256*8*(class-size+29)+256+16`: 2.156.816 byte per classe 1024.
  Il routing usa segmento u32 e offset 64; il caso cache64 confronta un oracolo indipendente,
  verifica occupazione al massimo otto, scalda tutte le 64 chiavi e richiede HIT a ogni lettura.
- Snapshot creato ma non registrato; `directory-register-snapshot` registra a tempo 10,
  ingresso a 11, conclusione ordinaria a 12, deadline 30.

La fixture supporta count 0..32768; i profili benchmark usano solo N<=64. Il limite della
fixture deriva dal primary singolo con capacità massima 65536 e carico al più metà.
Le risorse native dipendono dal limite FD del processo: il caso geometrico 65536 non
richiede altrettanti FD. Ogni chiamata usa un namespace acquisito con mkdir esclusiva,
con tentativi limitati a 1000; pulisce soltanto file propri. Chiudere in `unwind-protect`,
**dopo tutti i join**. La chiusura è idempotente e non termina implicitamente worker.

Keyword aggiuntive per setup/FI: `prepared-p`, `record-csn`, `record-bytes`, `observe-io-p`
e `image-mutator(image, ordinal)`. L'osservazione I/O è disattivata per default,
così il benchmark può usare il backend nativo senza lista eventi o mutex aggiuntivo.
Con osservazione attiva, `directory-read-events` restituisce triple `(id offset count)`;
setup e lettura header sono esclusi dai contatori delle operazioni. `directory-checked-read`
è un driver di correttezza e alloca liste: non costituisce il corpo da cronometrare.

## File e oracoli indipendenti

Ogni mappa nativa nasce da un file realmente scritto, sincronizzato, chiuso e riaperto
readonly. Header `ARCDSEG1`, PUT, EDIT completo e SEAL sono codificati byte per byte;
CRC32C bitwise indipendente dalle primitive del prodotto. Il manifest è ricostruito
dall'API pubblica su EDIT+SEAL validi e contiene frontiere CLOSED autorevoli.
L'ACTIVE u64 richiesto dal formato del manifest è distinto dai CLOSED e resta fuori
dalla directory: nessuna capacità ACTIVE è costruita o esercitata.

L'origine ordinaria è compaction, con PUT senza PREPARED. Il caso writer prepared
produce PUT con TXID, OUTCOME con lo stesso TXID e CSN, e SEAL del lotto: nessun esito
EDIT aggiuntivo. Il resolver valida il prefisso e ricava l'offset della prova; anche
la lettura da cache prepared deve rileggere OUTCOME dal medesimo FD.
Undici byte invalidi oltre la frontiera CLOSED distinguono il prefisso autorevole da EOF.
Il buffer del resolver copre soltanto END; `max-batch-bytes` è almeno 56 ed entro
`max-bytes`; la lettura dell'header usa esattamente 64 byte.

## Casi predisposti e limiti

| Sorgente | Casi e metodo |
| --- | --- |
| construction | Vuota; payload 12*N; budget esatto e uno corto; massimo 65536 e rifiuto 65537; copia dell'array input; forma simple-vector; duplicati/ordine; proprietario canonico EQ; ID zero/highbits; FD chiuso o append. |
| read | File v1/v2 e valori 16/256/4096; ID massimo; enum e cinque valori del nucleo; cache64 senza eviction; cache corrotta con VERIFY-FAILED e rilettura nativa; prepared+OUTCOME+SEAL; candidata pubblicata senza segmento => FAULTED, mai ABSENT; CSN basso/alto, dimensione e word riservata; chiave del file discordante; shape FI di lunghezze, massimo ed entry privata NIL su tutti i quattro ingressi, zero I/O e pin; FD scaduto; reentrancy/ordine; throw durante pread; snapshot finale; vera assenza primary; buffer piccolo e riavvio su nuovo worker. |
| threads | Quattro reader su vista/directory/FD condivisi, 28 buffer distinti, risposta completa e sentinelle, pin zero dopo tutti i join; file e cache v1/v2; gate e join con timeout, condizioni trasportate al controller. |

Ogni test ha `REQ` nel nome. Le condizioni del prodotto sono verificate per tipo e reason;
i timeout della fixture sono condizioni dedicate. Ogni ciclo ha cardinalità o budget
esplicito; le attese delle gate precedono EBR. I test osservano il cleanup del prodotto
prima di chiamare il cleanup esterno di sicurezza.

**Il caso 65536 è esclusivamente geometria e selezione sintetica.** Le capacità FI
condividono il solo FD reale della fixture: non certificano CLOSED per 65.536 file.
Il primo elemento richiede i 17 passi della ricerca binaria su 2^16 elementi; il caso
seleziona primo/ultimo e non invoca resolver, cache o lettura su mappe sintetiche.
Le FI di shape, capacità e scratch sono seriali e locali; non modificano sorgenti prodotto.
Pubblicazione/reclaim del controller, prestazioni, zero heap, ACTIVE e trasferimenti
reali fra pool restano fuori da questa suite. Il riavvio sul secondo worker conserva
soltanto la richiesta e riesegue lookup e acquisizione della directory sotto una nuova epoca.
