# Scrittura delle stringhe CBOR — revisione dei dati

Lettura del 2026-10-11, congelata in spikes/out durante le campagne
registrate; nessun file tracciabile o test congelato è modificato dalla lettura.
La lettura non avvia build, test, benchmark, coverage o mutazioni.
Revisione definitiva sui record elencati; draft ed eventuali helper di
questa lettura sono congelati prima della raccolta. I link riportano
ancora i percorsi originali come metadati storici. I byte sono conservati
nell'[archivio originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write/archive-index.lisp),
che mappa ogni percorso sorgente alla copia pubblicata.

## Record preliminare

Record letto integralmente come dati tramite
`arcdocdb.evidence:read-evidence` di `tools/evidence-storage.lisp`:
`spikes/out/4000708581-command-2575-0/report.lisp`.
Il reader restituisce schema1, kind COMMAND-VERIFICATION, comando
`make test lint trace`, STATUS OK, EXIT-CODE0, SOURCE-CONSISTENCY STABLE
e WALL-SECONDS13.692469d0. I 606 elementi SOURCE-BLOBS-BEFORE e AFTER
sono uguali, compreso il prodotto e il corpus congelati.

Ambiente dichiarato: SBCL2.6.9, Darwin27.0.0 ARM64, AppleM4, dieci CPU
logiche, 16GiB RAM; carico esterno UNCONTROLLED. Base Git
`2a0011f9d2bef104b22f7ad1eb86d7e5d60d5e11`, working tree registrato.
Il tempo comprende l'intero comando e non misura una singola operazione.

I blob nel record coincidono con il freeze:

| Artefatto | Blob Git |
|---|---|
| Prodotto | `a2c5c77dd51bff760bff4508e998d94370921eda` |
| Supporto cieco | `e45437a508fc7893c4df06f3129ab064d3a4dbdd` |
| Test seriali ciechi | `ed0f6a67c46498bdc9c721480cb76bc727fc5b4f` |
| Test worker ciechi | `33c7e6a9a0d6bbd551d4171ece6681b66bf87657` |
| Seconda lettura statica | `6602c0c81fe57865cd417c0a1e8eea275742c876` |
| ASDF | `e3a98df96d9e7be83e41bfef21a2bf08a59017e8` |

## Test, compilazione e controlli

Il record contiene 122.711 caratteri STDOUT e 220.252 STDERR, esaminati
integralmente mediante il reader. Le righe `ok    ` sono 683, tutte uniche:
681 test nominali e due smoke (`package ARCDOCDB presente` e
`ARCDOCDB:*VERSION* è una stringa`). La somma dei diciotto conteggi di
suite è 681:

| Suite | Nominali |
|---|---:|
| Fondazioni | 28 |
| UTF-8 | 17 |
| Header CBOR | 17 |
| Header CBOR minimi | 15 |
| Struttura CBOR | 24 |
| Struttura CBOR minima | 22 |
| Scrittura header CBOR | 17 |
| Scrittura stringhe CBOR | 21 |
| Registro CSN | 20 |
| Snapshot/CSN | 43 |
| Code writer/worker | 89 |
| Metadati storage | 44 |
| I/O | 18 |
| Recovery | 95 |
| WAL | 48 |
| Controller Serie | 44 |
| Slot indice v2 | 64 |
| Indice primario | 55 |

Tutti i ventuno nomi REQ-CBR-002 del corpus congelato compaiono una volta,
incluso il test parallelo. Il log registra 8.194 confronti di lunghezza
e fuzz2048, seed53574342, con 1.546 accettati e 502 rifiuti UTF-8:
la somma coincide con il piano. Le altre quantità del corpus sono
dedotte dagli assert e dalle fixture congelate, senza un nuovo contatore
indipendente nel log.

La compilazione forzata e la policy di tools/build.lisp trattano warning
e style-warning come errori. Nel contenuto completo non compare alcun
warning/style-warning o Unhandled; compare il marker finale
`build e test: nessun avviso, tutti i controlli superati`.
STDERR conserva note di compilazione: 158 per il prodotto e 198 per i
test, senza avvisi osservati. Lint registra 125 file, zero violazioni;
trace registra 116 requisiti, 65 invarianti, 13 scenari FI, 52 ADR e zero
errori. EXIT-CODE0 e STATUS OK sono coerenti con questi marker.

## Dati dei worker

Due worker reali, ciascuno con destinazione privata, vengono riusati in
due ondate. Ogni worker esegue 8.192 item per ondata, su sorgente condivisa
immutabile da 1.024 byte. Il corpus verifica a ogni chiamata un solo NEXT
fixnum e l'intera destinazione; dopo il join verifica sorgente e buffer
interi. Le attese, il join e il cleanup hanno limiti e controllano la
terminazione. Il test nominale passa nel record preliminare.

Ricalcolo freddo del sink: payload1024 richiede testata3; START3 implica
NEXT1030. I byte di testata iniziali sono MT2=#x59=89 e MT3=#x79=121;
l'ultimo byte payload è #x42=66. Token per item: 1030+89+66=1185 e
1030+121+66=1217. Moltiplicando per8192 si ottengono esattamente
9707520/9969664, entrambi i sink osservati in entrambe le ondate.

| Ondata | Item complessivi | Sink MT2/MT3 | Overlap a 1.000.000 tick/s |
|---|---:|---|---:|
| 0 | 16.384 | 9.707.520 / 9.969.664 | 47.821 tick = 47,821 ms |
| 1 | 16.384 | 9.707.520 / 9.969.664 | 47.752 tick = 47,752 ms |

Totale32.768 item e 33.554.432 byte payload copiati. Gli intervalli reali
si sovrappongono e i sink dipendono da valori/byte osservati. Il record
supporta concorrenza funzionale su sorgente condivisa e destinazioni
private; non stabilisce simultaneità sui core o scaling. Gli overhead
delle verifiche fredde restano nel tempo del comando e del test.

## Benchmark seriale e sensori

Record `spikes/out/4000708804-command-7496-0/report.lisp`, letto come dati
tramite evidence-storage: wrapper OK/exit0/STABLE, 83.243866 secondi,
606 blob before/after uguali. Report interno CBOR-STRING-WRITE-BENCHMARK
OK, sorgenti STABLE con 127 fingerprint uguali, un worker, safety3,
clock1.000.000 tick/s. STDERR vuoto.

Nove fixture hanno cinque campioni ciascuna, 4.096 chiamate misurate e
warmup128 per campione: 45 campioni, 184.320 chiamate misurate. Ogni
campione osserva heap0. Un ricalcolo separato, senza caricare prodotto o
driver, ricostruisce header aritmetico, payload e intero buffer con due
sentinelle iniziali e quattro finali. Tutti gli expected-full-buffer,
NEXT, token e cold-values coincidono; ciascuna cold arity è uno.
Tutti i campioni coincidono con il sink indipendente
4096×token+(4096×4095)/2, con warmup/iterations e conversione ticks/secondi.
Le osservazioni source-unchanged, private-preallocated-buffer-and-source
e complete-output-checked-per-call sono vere per tutte le fixture.

| Fixture | NEXT | Token freddo | Byte buffer completo | Min–max secondi per 4.096 chiamate |
|---|---:|---:|---:|---|
| MT2, 23 byte | 26 | 107.567 | 30 | 0,003207–0,003285 |
| MT2, 24 byte | 28 | 121.993 | 32 | 0,003421–0,003479 |
| MT2, 256 byte | 261 | 8.889.817 | 265 | 0,025691–0,025793 |
| MT2, 65.536 byte | 65.543 | 547.776.994.183 | 65.547 | 6,279073–7,036515 |
| MT3 ASCII, 23 byte | 26 | 53.153 | 30 | 0,004466–0,004555 |
| MT3 ASCII, 24 byte | 28 | 59.521 | 32 | 0,004665–0,004754 |
| MT3 ASCII, 256 byte | 261 | 3.490.105 | 265 | 0,037904–0,038055 |
| MT3 ASCII, 65.536 byte | 65.543 | 208.396.917.735 | 65.547 | 9,293614–9,424335 |
| MT3 Unicode, 16 byte | 19 | 49.192 | 23 | 0,002944–0,002979 |

I controlli registrati nello stesso benchmark osservano baselineheap0,
sink8.386.560 per4096 chiamate nulle e positivoheap16.777.472 byte per
16 array deliberati da1MiB, sink16.777.336. Il controllo dell'output
riporta token3529, NEXT alterato rifiutato e tre alterazioni di
prefisso/payload/suffisso rifiutate; quello dell'arità accetta il singolo
valore e rifiuta quattro fixture di arità/NEXT.

Il driver congelato `c4bd98e145d13deb47b7eedb0f4581a241f1d0e1` esegue
checked-token sull'intero buffer a ogni chiamata misurata e confronta
la sorgente alla fine. I tempi comprendono tali controlli. Il contatore
misura delta del heap gestito osservato sul successo, con GC e warmup
fuori dalla misura; non è una prova assoluta di nonallocazione e non
copre percorsi di errore, pool, I/O o scaling. Carico esterno non controllato.

Il self-test dell'auditor dei dati è conservato nel record
`spikes/out/4000708787-command-7053-0/report.lisp`: OK/exit0/STABLE,
1,812891 secondi, quattro fixture positive e 54 negative, 37.424 check.
Si tratta di dati sintetici, senza esecuzione del prodotto. Il precedente
tentativo `spikes/out/4000708581-command-2576-0/report.lisp` resta
FAILED/exit1/STABLE, 1,41555 secondi, 9.432 check: setter SETF FIRST-SAMPLE
indefinito nella fixture dell'auditor. La correzione è nel blob auditor
`ae591bf0f2b37d0ed2ae08f16d0270568268a048`; il vecchio file rimane nel
freeze originale. Nessuno dei due tentativi è omesso.

L'audit sui dati reali è letto nel record
`spikes/out/4000708897-command-8700-0/report.lisp`: OK/exit0/STABLE,
1,895363 secondi, STDERR vuoto, 19.170 check. Prima/dopo il benchmark
wrapper conserva 654.034 byte e SHA256
`9fb205681abf9b324bf392eb56348c4484941a849035b18d827994f7c60dde59`.
L'audit conferma nove celle, 45 campioni, heap0, coldarity1, 127 fingerprint,
baseline0 e positivo16.777.472 byte. La somma dei tempi dei campioni è
79,272522 secondi, entro gli83,243866 del comando completo. L'auditor
conserva i limiti di consistenza dei dati, inventario dichiarato, osservazioni
prima/dopo e assenza di prova di autenticità o esecuzione.

## Copertura grezza e forma OTHER

Record `spikes/out/4000708897-command-8699-0/report.lisp`:
OK/exit0/STABLE, 11,407834 secondi, STDERR vuoto. Il comando coverage
usa scope `cbor-string-write`, cache privata e tutti i21 test della suite.
Gli stessi numeri di fuzz e sink compaiono nel record strumentato; overlap
worker56.188/55.237 tick. I tempi strumentati restano diagnostici.

Raw conservati in `spikes/out/cbor-string-write-coverage-20261011/`:
coverage-state.lisp, cover-index.html e l'unico source HTML
`de5dd74a96006e359337b0ce64959b64.html`. Il raw state salva204 file,
mentre lo scope HTML contiene soltanto il nuovo prodotto. La lettura
indipendente dei vettori raw mediante call-with-evidence-bytes e READ
con READ-EVAL NIL conferma256/308 espressioni e39/52 esiti di ramo;
le due tabelle HTML concordano, rispettivamente83,1% e75,0%.

Audit della copertura: record
`spikes/out/4000708950-command-9144-0/report.lisp`, OK/exit0/STABLE,
2,236314 secondi, 74 check; risultato taskroot/audit-coverage.lisp.
Cinque osservazioni di file prima/dopo coincidono. Le52 espressioni
scoperte sono associate sintatticamente a7 dichiarazioni,44 forme degli
errori interni e una OTHER; i13 esiti di ramo scoperti sono associati
alle guardie interne, con zero OTHER nei rami. Sono mantenuti tutti i
denominatori e le forme degli errori interni.

La singola OTHER ha raw-path `(8 2 11)` e forward-path `(11 2 8)`:
è `(max-bytes +cbor-scan-max-bytes+)`, argomento keyword con default
nella lambda-list della funzione pubblica, riga99. Il percorso è stato
risolto direttamente nelle forme del sorgente letto come dati; il source
HTML marca esattamente quella forma con state-2. Rimane OTHER e nel
denominatore. La presenza di chiamate senza keyword nel corpus non
autorizza a correggere il dato strumentato o a dichiarare quella forma
irraggiungibile. L'associazione dei restanti gap è sintattica, senza
prova di irraggiungibilità, esclusioni, MC/DC o chiusura del gate C1.

## Mutazioni e lettura dei log

Record `spikes/out/4000708897-command-8701-0/report.lisp`, directory
`spikes/out/cbor-string-write-mutations-20261011/`:
OK/exit0/STABLE, 85,832531 secondi, STDERR vuoto. Report interno OK,
fingerprint stabili, baseline OK/exit0/signalNIL e otto mutanti rilevati,
zero sopravvissuti, invalidi o worker-error. Il preambolo esatto identifica
il self-test worker, con report conservato
`spikes/out/4000708899-cbor-string-write-worker-self-test-8780/report.lisp`.
I dati self-test registrano dispatcher2validi/6negativi, sostituzione unica,
marker smoke esatto, compilazione invalida, segnale e guasto dopo
completamento distinti dai rilevamenti, otto bersagli applicabili.

Lettura dei nove log completi tramite evidence-storage: la baseline ha
683 righe ok, smoke alla riga2, build-end alla743 e nessun Unhandled.
Ciascun mutante ha exit1, signalNIL, smoke prima del primo Unhandled,
nessun build-end e un percorso riconoscibile della nuova suite. Le due
guardie COPY-PROGRESS sono errori runtime del prodotto mutato. Le altre
sei alterazioni sono intercettate dagli assert ciechi; alcuni rifiuti
mostrano anche il successivo assert di array immutabile durante cleanup,
senza costituire un rilevamento supplementare.

| Copia | Bersaglio | Esito runtime osservato |
|---|---|---|
| 0 | major MT2/3 scambiato | Intera destinazione diversa nel test dei vettori letterali |
| 1 | lunghezza scalari al posto dei byte | Intera destinazione diversa nel test Unicode/no normalizzazione |
| 2 | ultimo byte payload omesso | INVARIANT-VIOLATION COPY-PROGRESS nel test letterale |
| 3 | origine sorgente zero | INVARIANT-VIOLATION COPY-PROGRESS, anche su span vuoto con offset sorgente |
| 4 | budget senza testata | Ritorno normale inatteso e buffer mutato nel test budget/item vuoto |
| 5 | capacità fisica al posto di END | Ritorno normale inatteso e buffer mutato nel test capacità/suffisso fisico |
| 6 | overlap che ignora il byte iniziale | Ritorno normale inatteso nel test overlap che include testata |
| 7 | verifica testo non vuoto saltata | Ritorno normale inatteso e buffer mutato nel test UTF-8 malformato/offset |

Audit mutazioni: record
`spikes/out/4000709011-command-9525-0/report.lisp`, OK/exit0/STABLE,
9,133384 secondi, STDERR vuoto, 11.828 check; taskroot/audit-mutations.lisp.
Le36 osservazioni di file prima/dopo coincidono. Sono confrontate nove
copie per210 file dell'inventario dichiarato: baseline identica; ogni
mutante cambia soltanto il prodotto previsto, con sostituzione unica
coincidente con il catalogo. Runner e cache privati sono presenti.

Il confronto chiude l'inventario dichiarato, senza attestare l'intero
albero delle copie o autenticità del record. Il classifier runtime usa
marker/exit e non dimostra da solo che l'errore derivi dal bersaglio; il
log-check dell'auditor cerca smoke e Unhandled senza imporne l'ordine
o l'origine nella suite. Per i log reali questa lettura ha controllato
separatamente che Unhandled segua smoke e coinvolga i test REQ-CBR-002,
con gli esiti della tabella. I risultati coprono solo gli otto bersagli,
senza promuovere durabilità, documento composito, motore o release.

## Tentativi della lettura dati

Due tentativi del reader inline sono falliti durante questa revisione,
prima della ripetizione corretta: uso del reader plist su raw state
SB-COVER che è una lista, e parentesi mancante nel frammento di lettura
dei log. Sono distinti da campagne runtime, prodotto e verificatori
registrati. Frammenti e diagnostiche disponibili sono conservati in
[estratti originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write/raw/cbor-string-write-20261011/reading-data-reader-attempts.md.txt), senza ricostruire output mancanti.
La ripetizione corretta decodifica il raw state con call-with-evidence-bytes,
READ-EVAL NIL, e legge separatamente tutti i log; nessun file tracciabile,
test o codice di prodotto è stato eseguito o modificato dalla revisione.

## Esito preliminare e parti pendenti

PASS preliminare confermato per compilazione, corpus, regressioni presenti
nel runner, lint, tracciabilità e stabilità dei sorgenti. Benchmark e suoi
sensori sono coerenti con il criterio locale di heap osservato zero;
self-test dell'auditor dei benchmark esaminato con tentativo fallito
conservato. Gli audit dei dati reali di benchmark/coverage/mutazioni sono
coerenti; tutte le lacune della copertura e i limiti dei verificatori
restano espliciti. Al congelamento di questa lettura MAKE CHECK completo
restava da confermare nella fase di integrazione. La lettura non chiude gate C1/MC/DC o qualifiche del motore
e delle dipendenze. Non sono necessari ulteriori cambiamenti al prodotto
o ai test congelati sulla base dei record esaminati.

## Registrazione successiva dell'integrazione

Il coordinatore aggiunge i metadati della verifica finale, successiva alla
lettura congelata: commit `ceac2dedfcfd6af05f2331282645bebf4b5be442`,
`make check` PASS, EXIT-CODE0, STABLE, 172.707537d0. Il record
`spikes/out/4000710709-command-45721-0/report.lisp` conserva 791 test
nominali e due smoke, 793 nomi OK senza duplicati, lint su 138 file senza
violazioni, tracciabilità senza errori e dieci spike completati.
I 643 elementi SOURCE-BLOBS-BEFORE e AFTER coincidono; il prodotto e
i tre file di prove conservano i blob indicati nella lettura originale.
Il self-test del driver coverage integrato passa nel record
`spikes/out/4000710709-command-45705-0/report.lisp`.
Questi record e i risultati grezzi degli spike sono conservati
nell'[archivio finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write-final/archive-index.lisp).
Questa registrazione non estende la lettura indipendente alle nuove
dipendenze di main e non promuove gate o qualifiche.

Dopo l'arrivo del collegamento worker/Serie in main `92decf4`, il merge
`997f5e6505cdcf4554d5f99ede7d5743ce4be7bd` passa nuovamente `make check`:
record `spikes/out/4000711291-command-57732-0/report.lisp`, 177.072076d0,
EXIT-CODE0, STABLE, 655 elementi sorgente. Risultano 817 test nominali
e due smoke, 819 nomi OK senza duplicati, lint su 142 file senza violazioni,
tracciabilità senza errori e dieci spike completati. Prodotto e corpus
del writer rimangono congelati. Il
[supplemento](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write-worker-integration/archive-index.lisp)
conserva questi dati; resta applicabile il limite della registrazione
successiva rispetto alla lettura indipendente originale.
