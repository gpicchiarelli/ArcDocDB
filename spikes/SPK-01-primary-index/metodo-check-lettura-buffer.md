# Metodo preregistrato — CHECK lettura-buffer, Fase 0

> **Proposta** — Verifica sperimentale preregistrata prima di compile/CHECK;
> riferimenti REQ-IDX-001, REQ-IDX-007 e REQ-VAL-001. Non codice di produzione.

Owner esclusivo: `check-lettura-buffer.lisp`, questo metodo e nuovi
`out/check-lettura-buffer-*/`. Checkout: indice-lettura/ArcDocDB. Nessuna
modifica a core, kernel dell'agente A, runner, tools, documenti condivisi.
Solo Common Lisp/SBCL, safety 3; warning e style-warning sono errori.
Nessun BENCH, commit o push. La misura e l'integrazione spettano al parent.

## Ipotesi e criteri registrati prima di compile/CHECK

API sotto prova: `ARCDOCDB.SPK01.LETTURA-BUFFER:LEGGI`, destinazione privata
simple-array u64 di lunghezza esattamente 4; due valori, status keyword e
retry fixnum. Layout v1 words4 / words5-extra-end. HIT pubblica CSN,
location, length, end-CSN soltanto dopo validazione seqlock e root; MISS,
retry-limit e ogni errore conservano tutte le parole della destinazione.
Le callback seguono il core: after-fragment su ogni tentativo, after-fields
per ogni candidato ctrl con seq iniziale pari, anche se la chiave non coincide.

Il modello è una mappa EQUAL di liste dei 16 ottetti, con journal indipendente
di PUT/DELETE e replay finale. Generazione chiavi, tuple e location aritmetica
sono nel CHECK, senza usare pattern o LEGGI del core per ottenere attesi.
Ogni lettura ordinaria confronta kernel, modello e baseline; il baseline
viene adattato alla destinazione solo dopo aver restituito HIT. Gli interleaving
usano fixture nuove per ciascun reader e gli stessi callback, senza scheduler.

Per layout: 64 chiavi iniziali; LCG32 seed 424242, 128 blocchi di otto
operazioni (1024): PUT, overwrite, hit, delete, miss, reinsertion, hit,
miss assente. Assert esatti: 384 PUT, 128 DELETE, 512 letture di campagna,
64 letture iniziali e 384 finali (960 confronti kernel/modello/baseline).
Il journal contiene 576 eventi per layout, replay completo e nessun limite
esaurito trattato come successo. Split deve essere realmente avvenuto.

Casi principali separati: valori 0/1/fixnum-max/fixnum-max+1/2^63/max64,
location con segment e offset max32, length 0/1/max24, chiavi zero/all-FF;
rebuild per tombstone e soglia seqlock; sette chiavi con ctrl 53 e sonda
iniziale 15 a capacità 16, ricerca limitata a 131072 candidati. Sei slot
occupati devono risultare 15,0,1,2,3,4; il settimo è un MISS e visita sei
candidati. I callback devono avere tracce identiche al baseline.

Witness, entrambi i layout e reader: root ritirata HIT e MISS; update/delete
in after-fields; odd persistente introdotto dopo i campi; swap root su tutti
gli otto tentativi; update su tutti gli otto tentativi; errori originali nelle
due callback. Ogni callback controlla il buffer prima e dopo il writer;
HIT dopo retry verifica la tupla corrente, non quella ritirata. Retry-limit
richiede conteggio esatto e destinazione intatta. Budget 1..8 anche con odd
già presente: otto distinti casi, non una sola prova del default.

Controlli negativi separati: index/key/destination/attempts/callback invalidi,
keyword sconosciuta, rifiuto writer di u64 oltre max64 e length oltre max24,
budget del CHECK esaurito con condizione esplicita. Gli array, incluse le
regioni di backing di viste/displaced, vengono confrontati per intero.
Budget strutturali: sette record in capacità 8/profondità massima 0, ottavo
PUT rifiutato per profondità e sette record conservati; capacità 32768 con
1 MiB rifiutata per payload iniziale. Totali attesi: 54 casi principali,
79 controlli negativi (46 ingressi, 16 rifiuti writer/budget strutturali,
1 budget assert, 16 mutanti), 2032 letture contro mappa e baseline.

Mutanti locali al CHECK, senza ridefinire o modificare kernel/core: omettere
ricontrollo root (witness HIT e MISS), omettere secondo seqlock (update,
delete, odd), troncare u64 a fixnum (boundary), scrivere prima della
validazione (update e delete). Otto rifiuti richiesti per layout, con ragione
pertinente verificata; un errore generico non conta come mutante rigettato.
Non è una prova universale del modello di memoria o hardware. Nessuno
stress threaded: i witness sono interleaving sincroni con un solo writer.

CHECK ha budget finito di 200000 assert, ricerche finite, conteggi di
campagna e categorie separati. `:status :ok` viene costruito soltanto dopo
tutte le prove e gli assert finali. Output composto da liste, keyword,
stringhe e numeri; tipi, funzioni e condizioni descritti come stringhe.

## Registrazione schema1 di ogni esecuzione

Prima di ogni compile/CHECK viene scritto un piano numerato in un nuovo
out esclusivo, con argv e stdin esatti e rinvio a questo metodo. Driver SBCL
separato dall'esistente runner: snapshot source-before/after (contenuti e
MD5 dichiarato per core, kernel, CHECK, metodo e driver); stdout/stderr
originali su file, exit code e risultato decodificato nel record schema1.
Il driver promuove warning/style-warning a errori e verifica compile-file.
Errori/fallimenti restano nei record e non vengono sovrascritti. Qualsiasi
revisione del metodo precede l'esecuzione a cui si applica.

Un secondo processo SBCL, senza caricare package spike, legge risultato e
record con `*read-eval* = nil`, rigetta simboli non keyword e oggetti non
ammessi e salva i dati leggibili. Nessun CHECK prima del kernel completo;
la sua esistenza non è una dichiarazione di correttezza o prontezza.

### Esecuzione K1 preregistrata

Driver nuovi in `out/check-lettura-buffer-campagna-20261008-01/`: `record.lisp`,
`child.lisp`, `decode.lisp`. K1 compila in ordine core, kernel completo e CHECK,
carica i FASL e chiama CHECK. Avvio solo dopo conferma A di kernel congelato.
Budget: heap 1024 MiB, timeout figlio 90 secondi, registratore 105 secondi,
cleanup 5 secondi, 200000 assert. Massimo sei revisioni compilate; ciascuna
richiede un nuovo piano e conserva i fallimenti precedenti. Il timer protegge
l'esecuzione da blocchi; non viene usato per la correttezza degli interleaving.
Ogni snapshot include anche i tre driver. Source-after diverso implica errore.

Comando esatto dalla radice del checkout isolato:

```sh
/opt/homebrew/bin/sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-01-primary-index/out/check-lettura-buffer-campagna-20261008-01/record.lisp k1
```

Il registratore non carica i package spike e scrive preregistered.sexp prima
del lancio; stdout/stderr sono conservati originali, inclusa diagnostica del
compilatore su stderr. Dopo il record, un ulteriore processo senza package
spike verifica record e decoded.sexp con read-eval disabilitato.
Il registratore richiede handoff A `:ready`/`:frozen` e conserva quell'handoff
nel piano e nel record; il parent ha chiesto i commenti REQ prima di C3.

### Esito K1 e consegna congelata

K1 completato al primo tentativo: compile/load core, kernel C3 e CHECK senza
warning o style-warning; stderr vuoto, exit 0, CHECK `:status :ok`. Snapshot
before/after identici per tutti i sorgenti registrati. Record schema1:
`out/check-lettura-buffer-campagna-20261008-01/k1/record.sexp`; dati leggibili
in `decoded.sexp`, stdout/stderr originali in `stdout.raw` e `stderr.raw`.
Readback indipendente exit 0 / status ok, read-eval false e package spike
assenti; nessun simbolo foreign nei dati decodificati.

Conteggi verificati: 54 casi principali, 79 controlli negativi (46 ingressi,
16 writer/budget strutturali, 1 budget CHECK esaurito, 16 mutanti), 2032
confronti mappa/kernel/baseline, 18 witness e 16 budget retry. Per layout:
1024 operazioni seeded, 576 eventi journal, replay e popolazione finale 64;
6 split e 18 rebuild nella campagna. Collisioni trovate in 11870 candidati
su budget 131072. Assert consumati 26227 su 200000. Nessun esito parziale.

Hash Git blob del CHECK testato e congelato:
`fd32c5260ffb7c6e96cf1a420765eb01effe70bc`; kernel C3
`28002439f931387cd6baebcf57adde7e88e2961b`; core
`c019f6ad53e173a0d336a4dbfaf903e274a66f08`.
Questa annotazione di consegna è aggiunta dopo K1; il sorgente Lisp non è
cambiato. CHECK e metodo rimangono congelati per integrazione e misure del
parent. Nessun BENCH, commit/push o modifica a runner/tools effettuati da B.
