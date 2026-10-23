# CRC32C accelerato e GET: metodo della qualifica

Preregistrazione del 2026-10-23, successiva allo
[spike CRC](../../spikes/SPK-08-generated-code/metodo-crc32c.md) e precedente
alle misure di prodotto. [ADR-0059](../adr/0059-crc32c-arm64-sbcl.md).
Tutto il codice resta Lisp/SBCL, safety 3, nessun controllo d'integrità rimosso.

## Prodotto

La suite delle fondazioni confronta pubblico, fallback e oracolo bitwise:
0..128, 255/256/257, 4095/4096/4097, 65535/65536/65537 B; offset 0..15,
semi zero/massimo/arbitrario, incrementalità e split piccoli, range,
immutabilità, byte esclusi dal range e corruzione inclusa nel range.
Le suite record, GET, cache, WAL e recovery restano obbligatorie.
Il build deve essere privo di warning/style-warning, l'intera verifica deve
passare. Le due letture dell'autore sono distinte da una revisione indipendente.

La selezione OS/CPU è cold; il fallback è verificato anche tramite loader
standalone. Il disassemblato deve conservare bounds check dei load, CRC32C
sui registri e assenza di chiamate foreign/boxing nel ciclo. Gli opcode
non hanno mnemonico nel disassembler SBCL installato e vanno letti dai byte.

## GET: confronto A/B sullo stesso prodotto

[get-throughput-bench.lisp](../../tools/get-throughput-bench.lisp) riusa le
fixture pubbliche del [benchmark GET](get-performance-metodo.md) tramite
caricamento C4 come libreria, senza eseguirne il main. Stesso indice, EBR,
resolver, cache e FD; otto chiavi, dati caldi. Non è il benchmark di cardinalità.

Due kernel CRC, selezionato di prodotto e software, con binding privato
al solo thread principale e ripristino automatico dopo ciascuna finestra.
Nessuna modifica della funzione globale o del formato; i due kernel devono
restituire gli stessi checksum. Il kernel selezionato viene registrato.

Per ogni dimensione 16/256/4096 B, CSN 7/massimo u64 e scenario
cache-hit/segmento con cache disabilitata/assente: due percorsi del driver,
cinque repliche e due kernel in ordine alternato per replica. Sono
360 finestre da 20.000 GET, 1000 warmup, **14,4 milioni di GET** misurati.

- `:exact`: ciclo originale, verifica ogni byte/sentinella/stato nel timing.
- `:throughput`: GET, controlli degli esiti/range, clock fresco per avvio/fine
  e cleanup nel timing. Nessun fill o confronto byte per byte del driver.
  Prima e dopo ogni finestra, otto GET con l'oracolo originale verificano
  tutte le chiavi, guardie, contenuto e rilascio EBR. Le prove funzionali e
  `:exact` qualificano gli output; questo percorso non dichiara un confronto
  indipendente di tutti i byte di ogni risposta misurata.

L'intervallo è un ciclo continuo, non la somma di cronometraggi individuali;
nessuna sottrazione di baseline. GC completo, fixture, closure, persistenza
e oracolo prima/dopo restano fuori dal timing. Heap globale, tick monotoni,
completamenti e sink sono salvati anche su fallimento. Nessun thread
creato nella finestra. Niente P99, server/rete, commit o I/O freddo.

Autoverifica bounded: matrice con 8 GET e 8 warmup, entrambi i percorsi e
kernel, con le stesse fixture a file reali. Sensore positivo >=4 MiB vivi,
baseline nulla con completamento/sink esatti. Negativa CLI forza un atteso
errato e deve conservare finestra failed ed exit 1. Timeout 900 s processo,
60 s finestra. CLI `--self-test`, `--bench`, `--negative-fixture`, directory
nuova obbligatoria. Il benchmark esegue prima l'autoverifica; la negativa
non è una misura prestazionale. Il rapporto è scritto/riletto con READ-EVAL NIL.

Comando registrato dopo il freeze dei sorgenti:

```sh
sbcl --script tools/record-command.lisp -- sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit --script tools/get-throughput-bench.lisp --bench spikes/out/crc32c-get-bench-01/
```

La mediana del GET cache-hit da 4 KiB va confrontata direttamente con
l'obiettivo 2 microsecondi. Un esito più lento resta pubblicato; non viene
dedotto dal rapporto tra microbenchmark CRC. Misure e originali vengono
archiviati con sorgenti stabili, compresi i tentativi falliti.

## Diagnostica dopo la prima campagna

La prima campagna completa resta conservata: carico host salito oltre 18
su 10 CPU logiche e forte variabilità anche negli assenti, che non eseguono
CRC. Non si attribuisce questa variabilità al checksum. Prima di una seconda
campagna si aggiunge il tempo CPU del processo all'esterno dei confini del
timer wall/heap. Il tempo CPU è diagnostico, non sostituisce wall time o P99.
La seconda campagna conserva tutte le stesse celle e repliche; nessuna
selezione di risultati fra campagne. Un profilo SB-SPROF CPU separato può
individuare il lavoro residuo, ma non produce numeri di throughput qualificati.
