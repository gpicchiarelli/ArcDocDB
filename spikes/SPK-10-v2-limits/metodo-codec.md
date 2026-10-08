# SPK-10 — Metodo del codec v1/v2

> **Proposta** — Esperimento isolato, registrato prima dell'esecuzione. Il metodo verifica il codec; non certifica il gate v2 né il motore.

## Domanda e riferimenti

La cornice di 24 byte e le entry hint di 24 byte conservano il layout distinto v1/v2, verificano i limiti ADR-0048 e rifiutano dati incoerenti prima di restituire un offset del valore?

Riferimenti: [CONTRIBUTING.md](../../CONTRIBUTING.md), ADR-0039, ADR-0047, ADR-0048, `docs/formati-su-disco.md`, standard di codifica. Tracciabilità: REQ-LIM-001/003, REQ-FOR-003/004, REQ-AFF-002/008. Le parti di tali requisiti relative a indice, CBOR, migrazione e durabilità appartengono agli altri moduli.

## Ambiente e perimetro

Common Lisp, SBCL 2.6.9, `safety 3`, nessuna libreria esterna. Il runner carica prima `arcdocdb.spk09`, da cui questo modulo usa soltanto il kernel esportato `crc32c-slicing8-safety3`. Package indipendente `arcdocdb.spk10.codec`; codice in `codec.lisp`. Nessun I/O persistente, lock o stato mutabile condiviso. La serialità è esclusivamente quella del singolo controllo locale; l'harness misura i moduli in serie.

Il chiamante fornisce la versione dal fileheader già verificato: solo interi 1 e 2, nessuna deduzione dai byte. I documenti sono vettori semplici di ottetti; la validazione CBOR è responsabilità del modulo CBOR prima del writer. I prepared sono rifiutati come record con `:prepared-not-supported`, senza restituire un valore. Gli hint prepared possono essere rappresentati come metadati e non costituiscono prova OUTCOME.

## API proposta

```lisp
(costruisci-record versione chiave valore csn
  &key (tipo :put) (flag 0)
       (massimo-chiave 65535) (massimo-valore 16777216)
       (massimo-record nil))
;; => vettore semplice di ottetti, record intero

(verifica-record versione buffer inizio fine chiave csn totale-atteso
  &key (tipo :put) (flag-entry 0)
       (massimo-chiave 65535) (massimo-valore 16777216)
       (massimo-record nil))
;; => values inizio-valore fine-valore csn-verificato
;; INIZIO/FINE delimitano esattamente un record, intervallo [inizio,fine).
;; FLAG-ENTRY è 0 oppure 1 (prepared); il contratto-versionato vive nel record.

(costruisci-hint-entry versione offset lunghezza csn key-off key-len
  &key (tipo :put) (flag 0)
       (massimo-chiave 65535) (massimo-valore 16777216)
       (massimo-record nil))
;; => vettore di 24 ottetti

(verifica-hint-entry versione buffer inizio fine
                     lunghezza-chiavi lunghezza-segmento
  &key (massimo-chiave 65535) (massimo-valore 16777216)
       (massimo-record nil))
;; => plist :offset :lunghezza :csn :key-off :key-len :tipo :flag :prepared
;; Il chiamante fornisce le dimensioni delle sezioni già verificate.

(check) ;; => plist :status :ok, conteggi e limiti effettivamente verificati
(benchmark &key (secondi 0.25d0)) ;; => plist, durata richiesta <= 3 secondi
```

Le condizioni esportate derivano da `codec-error`: `parameter-invalid`, `limit-exceeded`, `record-invalid`, `hint-invalid`, `check-failed`. `codec-error-reason` espone un keyword stabile. Anche versione sconosciuta, flag riservati e prepared hanno rifiuti espliciti. Per v1 il massimo effettivo della chiave è `min(massimo-chiave,255)` e del record `#xffffff`; per v2 è 65.535 e 16.842.775. Un massimo del record configurato non può superare quello del formato. Prima di allocare un record si controllano lunghezza del valore, chiave, totale e semantica. PUT richiede almeno un byte di documento; TOMBSTONE valore vuoto. Flag record ammessi: 0/4; 1/5 riconosciuti ma prepared rifiutato; compressione e gli altri bit rifiutati. Hint: flag 0/1, tipi PUT/TOMBSTONE.

Layout hint v1: offset 0, len 4, csn 8, key-off 16, key-len u8 a 20, tipo a 21, flag a 22, riservato zero a 23. Layout v2: stessi primi quattro campi, key-len u16 a 20, tipo a 22, flag a 23. Le entry non hanno CRC individuale: questa API non sostituisce la verifica delle sezioni del file hint.

## Verifiche bounded pianificate

- Chiavi 1/255/256/65.535 accettate in v2; 65.536 e zero rifiutate. V1 accetta 1/255 e rifiuta 256/65.535/65.536. Limiti configurati inferiori verificati sia in costruzione sia in lettura.
- Fixture massima: bytestring CBOR deterministica `5a 00 ff ff fb`, payload di 16.777.211 byte, totale CBOR 16.777.216. Costruzione e lettura con CRC integrale, chiave 65.535 e totale 16.842.775. Documento da 16 MiB + 1 rifiutato; la costruzione controlla il limite prima dell'allocazione del record. V1 conserva il proprio limite totale, incluso un caso esattamente `#xffffff`.
- Golden con campi e posizioni fissati indipendentemente dall'encoder per record e hint nelle due versioni. CRC del kernel confrontato con implementazione locale bit a bit e vettore noto `123456789`, su intervalli brevi con allineamenti diversi. Il riferimento bit a bit rimane bounded e non scansiona le fixture massime.
- Corruzioni di CRC header/body, riservato v1, tipo, flag, lunghezze, chiave e CSN; lunghezze alterate con header CRC ricalcolato per raggiungere i controlli semantici. Troncamenti ai confini header/campi/chiave/valore e sottovettori in buffer con prefisso/suffisso. Priorità osservabile: header CRC prima di lunghezze; nessun offset restituito prima di tutti i confronti.
- Hint v1/v2: packing fisso, riservato zero v1, tipo/flag, overflow e confini di offset/arena/segmento, lunghezze PUT/TOMBSTONE e limiti di configurazione.

## Esecuzione e risultato

I byte CRC dei golden fissi sono stati precalcolati con uno script Common Lisp bit a bit indipendente: record breve header `(151 17 18 68)`, corpo `(114 157 69 8)`; record v2 con chiave 256 header `(245 56 11 210)`, corpo `(245 240 17 235)`. Lo script non esegue il controllo del modulo né un benchmark.

Pianificato un solo processo SBCL per lo strict check: compilazione rigorosa del supporto SPK-09 e di `codec.lisp`, caricamento FASL, una chiamata a `(check)`. Warning e style-warning sono fatali; tutti i valori di `compile-file` sono controllati. FASL e runner temporaneo fuori dal repository; il testo del runner è incluso nel registro per riprodurre il comando. Nessun benchmark durante questa esecuzione. Il risultato locale è riportato nella sezione seguente.

Prima dell'esecuzione si predispone la registrazione strutturata in `out/codec-check.lisp` (artefatto ignorato): plist con `:schema 1`, `:command`, `:environment`, `:source-blobs` (Git blob dei sorgenti, senza inserirli nell'object database), `:compile-status`, `:result`, `:limits`, `:time`, `:stdout`, `:stderr`, `:failures`. Il comando e il testo del runner sono conservati; avvisi, fallimenti o condizioni vengono registrati prima di uscire con codice non nullo. La plist viene riletta con `*read-eval* nil`. Il registro integrato è versionato separatamente dal report locale.

### Risultato locale del 2026-10-08

> **Proposta** — Evidenza sperimentale locale: non dichiara completato il gate v2.

Un solo strict check eseguito. SBCL 2.6.9, compilazione SPK-09 e codec senza warning/style-warning (conteggi entrambi zero), caricamento FASL riuscito. `(check)` restituisce `:status :ok` e **416 casi**:

| Gruppo | Casi |
|---|---:|
| CRC differenziale e vettore noto | 122 |
| Golden record v1/v2 | 9 |
| Chiavi e TOMBSTONE | 21 |
| Documenti massimi, cap e troncamenti grandi | 27 |
| Campi malformati e CRC | 51 |
| Intervalli e entry attesa | 43 |
| Golden hint v1/v2 | 6 |
| Hint, limiti e troncamenti | 101 |
| Versioni sconosciute e parametri | 36 |

Accettati e verificati con CRC dell'intero corpo: documento CBOR da **16.777.216 byte** con chiave da **65.535 byte**, record v2 da **16.842.775 byte**; record v1 da **16.777.215 byte**. La fixture CBOR massima contiene i cinque byte `5a 00 ff ff fb` seguiti da 16.777.211 byte di payload. Rifiutati documento da 16 MiB + 1, lunghezza dichiarata da 16 MiB + 1, chiave 65.536, cap inferiori e prepared.

Il rifiuto del documento eccedente è prima della `make-array` del record; il controllo dedicato impone anche un budget di allocazione del rifiuto inferiore a 1 MiB. Il contatore SBCL ha riportato `:rejection-bytes-consed 0` in questa esecuzione: tale contatore non dimostra assenza di ogni piccola allocazione.

Registro conservato: [v2-codec-check.lisp](../results/2026-10-08/v2-codec-check.lisp), copia invariata del report locale `out/codec-check.lisp`, schema 1, riletto fedelmente con `*read-eval* nil`, nessun fallimento. Tempo del processo registrato **0,846542 s**, comprensivo di raccolta metadati, compilazione e check: non è un benchmark. Comando: `sbcl --noinform --script /private/tmp/arcdocdb-spk10-codec.DFuRp6/strict-check.lisp`; testo completo del runner, ambiente e hash Git dei due sorgenti conservati nell'artefatto. Nessun benchmark eseguito.

## Limiti residui

Il CRC rende rilevabili le alterazioni esercitate e non garantisce l'assenza di collisioni. Non si verifica durabilità, fileheader, SEAL, OUTCOME, semantica CBOR, concurrent writer o pubblicazione della migrazione. Le versioni sono selezionate esclusivamente dal chiamante; un record v1 con byte riservato zero può avere gli stessi byte di un v2 con chiave corta. La provenienza della versione è quindi indispensabile e non può essere ricavata dalla sola cornice.

Per l'integrazione restano espliciti: prepared non supportato dal codec; CRC delle sezioni hint e fileheader verificati dal chiamante; validazione CBOR nel modulo dedicato; la lettura di TOMBSTONE usa `:tipo :tombstone`, quella ordinaria `:put`. Il benchmark opzionale ha default 0,25 s, massimo richiesto 3 s e tetto di 1.000.000 iterazioni; il tempo effettivo può includere l'ultima operazione e il runtime. Non esprime garanzie temporali o capacità del motore.
