# Raccolta degli archivi di comandi

Lo strumento C4 `tools/collect-command-archive.lisp` raccoglie record di
comandi già conclusi in un archivio nuovo. Applica il registro delle prove
di [ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) e i
controlli COD-60/COD-61 dello [standard](../affidabilita/standard-di-codifica.md).
Non interviene sul motore o sui suoi formati persistenti.
Le [verifiche conservate](raccolta-comandi-risultati.md) riportano tentativi,
risultati e limiti della prima campagna.

La lista degli ingressi è esplicita. Il chiamante sceglie ogni file e ogni
record; un file vicino al record non entra automaticamente nell'archivio.
Descriptor e payload gzip vanno elencati entrambi. Questo consente di
conservare sorgenti, output e fallimenti senza ripulirne o reinterpretarne
il contenuto.

## Manifest

Il manifest è una sola plist, letta come dati con READ-EVAL NIL ed EOF
obbligatorio. I percorsi SOURCE relativi partono dalla directory del
manifest. PATH e RECORD-PATH sono relativi alla nuova radice dell'archivio.
Il campo DATE contiene la data della raccolta, senza date nel sorgente
dello strumento.

```lisp
(:schema-version 1 :kind :command-archive-manifest :date "2026-10-15"
 :files ((:source "runs/build/report.lisp"
          :path "processes/build/report.lisp")
         (:source "runs/build/report.lisp.gz"
          :path "processes/build/report.lisp.gz")
         (:source "review.txt" :path "raw/review.txt"))
 :processes ((:label "build" :record-path "processes/build/report.lisp")))
```

Il payload gzip si elenca soltanto quando il record ha effettivamente un
descriptor di compressione. Ogni LABEL è un singolo segmento univoco;
ogni RECORD-PATH deve comparire in FILES. I file
`collection-manifest.lisp` e `collection-source.lisp` sono aggiunti dallo
strumento. Questi nomi, `archive-index.lisp` e `catalogo.lisp` sono riservati.
Sono rifiutati duplicati e collisioni fra un file e una directory.

I record devono avere schema 1, kind COMMAND-VERIFICATION, fine registrata
e stato terminale. Restano distinti OK, FAILED e SOURCE-CHANGED. Anche un
comando fallito può essere conservato: la riuscita della raccolta attesta
la copia e la verifica dell'archivio, non la riuscita del comando copiato.
COMMAND, STATUS, EXIT-CODE e SOURCE-CONSISTENCY devono essere presenti;
un errore infrastrutturale può avere EXIT-CODE NIL.

## Esecuzione

```bash
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit \
  --script tools/collect-command-archive.lisp \
  --collect spikes/out/campagna/manifest.lisp \
  spikes/results/campagna/ \
  --observations spikes/out/campagna/raccolta/ --jobs 4
```

Destinazione e directory delle osservazioni devono essere nuove e
separate, senza contenersi a vicenda. Le osservazioni rimangono esterne
all'archivio: includerle nella stessa raccolta cambierebbe l'insieme appena
verificato. Per conservare l'esito della raccolta si può usare il record
del comando concluso come ingresso di un archivio successivo.

L'API Common Lisp `collect-archive` accetta stringhe o pathname per
manifest, destinazione e osservazioni. I percorsi contenuti nel manifest
restano stringhe, come prescritto dallo schema.

Il preflight controlla manifest, percorsi, dimensioni e record prima di
creare la destinazione. Le copie usano quattro worker, con una prima copia
privata per worker quando ci sono almeno quattro file e una coda condivisa
protetta da mutex. Ogni risultato
ha un solo proprietario; indice e catalogo sono costruiti dopo i join.
Gli hash SHA256 confrontano gli ingressi prima e dopo le copie e le
destinazioni. I metadati dei record copiati sono riletti e confrontati con
quelli degli originali; la verifica SHA256 copre l'intero contenuto.

L'ultima verifica avvia `tools/check-command-archive.lisp` in un processo
separato. Controlla l'inventario chiuso, gli hash e i metadati dei processi;
il suo output rimane nella directory delle osservazioni. Nessun append
segue questa verifica.

In caso di errore il comando termina con codice non nullo e un motivo.
Le copie parziali e le osservazioni rimangono disponibili; non si cancellano
o sovrascrivono archivi esistenti. Una nuova esecuzione richiede nomi nuovi.

## Verifica e limiti

```bash
sbcl --noinform --no-userinit --no-sysinit \
  --script tools/collect-command-archive.lisp --self-test
```

Il self-test usa fixture locali e rifiuti con motivi attesi, comprendendo
copie concorrenti, record compressi, comandi falliti, percorsi invalidi,
destinazioni esistenti e alterazione delle copie. Non esegue campagne del
prodotto. Fa parte dei controlli della conservazione in `make check`.

I limiti dei file pubblicati sono 1 MiB per file ordinario, 8 MiB per gzip
e 128 MiB per record espanso. Il piano ha un numero massimo dichiarato di
voci. L'osservazione resta locale e per file: non è una transazione del
filesystem né una pubblicazione durevole atomica. Gli ingressi devono
rimanere fermi durante la raccolta. I quattro worker non costituiscono
una misura di scalabilità o prestazione del database.

La raccolta non promuove requisiti, risultati dei benchmark o gate di
rilascio. La qualifica C1/MC/DC del motore resta distinta.
