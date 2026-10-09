# Registro strutturato di prove e benchmark

> **Deciso (richiesta dell'autore, 2026-10-08)** — ogni prova, diagnostica e
> benchmark è registrato in forma strutturata, compresi fallimenti, campagne
> parziali e ipotesi di ottimizzazione smentite. Realizza REQ-VAL-001 e INV-X2.

## Record della campagna

`tools/run-spikes.lisp` conserva una plist Common Lisp con `:schema-version 1`.
Si legge con `*read-eval* nil`, senza caricare o eseguire il file. Il report
comprende:

- modalità `--check`, `--bench` o `--profile`, stato della campagna;
- ambiente SBCL/OS/CPU/RAM, heap dei processi, data in universal time;
- commit Git, stato dell'albero e blob Git dei sorgenti effettivi;
- per ogni processo: argv esatto, inizio/fine, tempo wall, exit code ed esito;
- `:result` decodificato come dati, con parametri, quantità, unità, risultati,
  sink, limiti e parti omesse restituiti dal singolo esperimento;
- stdout/stderr originali, diagnostica del fallimento e percorsi dei record.

Ogni processo registra i blob dei soli sorgenti che carica, prima e dopo
l'esecuzione. Se cambiano, l'harness conserva il record con `:source-changed`
e fallisce: quella misura non è attribuibile a una variante stabile. Il commit
identifica la storia; i blob identificano anche le modifiche non committed.
`:stable` confronta due snapshot; non sorveglia ogni apertura dei file.
I sorgenti selezionati devono restare immutati durante la prova.

La campagna scrive il proprio stato prima di partire e dopo ogni processo.
Il record del processo è salvato **prima** di validarne l'output. Un errore di
compilazione o di parsing resta una prova fallita, conservata; non scompare
dal registro. `:complete` significa che tutti i processi selezionati sono
terminati; eventuali `:unsupported` o budget esauriti restano esiti distinti.
Nessuna prova di prodotto è promossa dal solo successo degli esperimenti.

Il direttorio nasce con `mkdir` esclusivo e tentativi limitati: un run non
sovrascrive quello precedente, anche se parte nello stesso secondo. Compilazione
e controlli non sono esclusi dal tempo del processo; i microbenchmark espongono
separatamente le finestre effettivamente misurate. Le misure si eseguono in serie.

## Comandi

```sh
make spikes-check
make spikes-bench
make check
sbcl --script tools/record-command.lisp -- make lint
sbcl --script tools/run-spikes.lisp --check SPK-10
sbcl --script tools/run-spikes.lisp --bench SPK-01 -- --documents 10000000 --seconds 60 --memory-mib 2048
sbcl --script tools/run-spikes.lisp --profile SPK-01
```

L'harness imposta heap 4 GiB e disabilita inizializzazioni utente/sistema nei
figli. Le opzioni dopo `--` sono ammesse solo per un benchmark selezionato;
sono argomenti del processo, mai codice shell. SPK-07 esegue il proprio modello
anche in modalità benchmark, senza inventare throughput del motore.

`make check` esegue `make check-core` tramite `tools/record-command.lisp`:
un record schema 1 di tipo `:command-verification` conserva argv, ambiente,
blob prima/dopo, exit code e stdout/stderr dell'intera verifica. Il testo
dei controlli resta output grezzo, senza dedurne conteggi o promuovere requisiti.
Il wrapper può registrare anche altri comandi con `-- argv...`, sempre senza
shell. I singoli spike producono inoltre i propri risultati decodificati.
La CI conserva `spikes/out/` come artefatto anche quando un controllo fallisce;
la sua esecuzione su Linux/macOS resta distinta dalla verifica locale.

## Conservazione e interpretazione

I run locali restano in `spikes/out/`. Ogni numero pubblicato nei documenti
rimanda a dati conservati in `spikes/results/<data>/`: output originali e
record strutturati, con provenance e versione del formato. Un record importato
non inventa metadata assenti; i campi mancanti sono dichiarati.
Il [catalogo delle evidenze](../../spikes/results/README.md) tiene distinti controlli,
benchmark, profili, fallimenti e varianti; ambiente e comandi restano nei singoli
record originali.

I registri superiori a 1 MiB vengono conservati senza perdita secondo il
[metodo di conservazione compatta](conservazione-compatta.md): il percorso
originale contiene un descriptor e il payload gzip è accanto. Dimensioni e
SHA-256 permettono di verificare i byte originali. `tools/read-evidence.lisp`
risolve il descriptor senza eseguire il record. `make compact-evidence`
registra la compattazione, con quattro worker indipendenti; `make evidence`
controlla integrità e limiti di dimensione, anche per file non catalogati.

I metodi si registrano prima dell'esecuzione. Si indicano campione, clock,
allocazioni misurate e loro scope; la memoria degli array non è RSS. Non si
stima P99.9 da pochi campioni e un contatore pari a zero non dimostra assenza
universale di allocazioni. Carico esterno non controllato e sorgenti modificati
durante un run devono essere dichiarati. Il blob identifica il contenuto
registrato, non una prova di affidabilità del compilatore o del supporto.
