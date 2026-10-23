# Verifiche della scrittura dei valori semplici CBOR

Campagne del 2026-10-11 sul [metodo preregistrato](cbor-semplici-metodo.md),
blob `e8864f7c0124f86cebdcdbcb2449800e078e1cc8`. Il corpus cieco è stato
congelato prima di scrivere il prodotto; compilazione e campagne seguono
le [due](cbor-semplici-revisione.md) [letture C1](cbor-semplici-lettura.md).
Prodotto `58c7a3a040ec814fae2dfe636f569b5623cba8f0`, invariato nelle prove.
La primitiva scrive codici wire MT7, senza semantica applicativa aggiunta,
float, composizione o pubblicazione durevole.

## Corpus e worker

16 nuovi test: 15 seriali e uno con due worker reali riusati. Il controllo
preliminare sulla base integrata GET/cache passa in 22,106124 s: 852 test
nominali e due smoke, 854 nomi OK distinti, compilazione senza warning o
style-warning, lint su 150 file senza violazioni e tracciabilità senza errori
(117 requisiti, 65 invarianti, 13 scenari FI, 52 ADR). I 685 elementi
sorgente coincidono prima/dopo; HEAD `0865b2c` include main `6eeb501`.

Tutti i 248 codici ammessi, otto offset e tre configurazioni: 5.952
successi freddi; 3.776 capacità insufficienti e 256 rifiuti dei codici
riservati. Fuzz 2.048 casi seed53494D43: 768 successi, 512 valori invalidi,
256 capacità insufficienti, 512 destinazioni/range invalidi. Concatenazione
dei codici in 472 byte, arità esatta e confronto dell'intero array fisico.
Lettore minimo e scanner sono soltanto controlli supplementari successivi
ai byte attesi calcolati indipendentemente.

Due ondate di 8.192 item per ciascuno dei due worker: 32.768 chiamate,
destinazioni private e piani immutabili, sink 3.804.160/3.836.928 in ogni
ondata. Overlap preliminare 2.098/2.077 tick a 1.000.000 tick/s, attese,
join e cleanup limitati. Nessuna inferenza su simultaneità dei core,
scaling o throughput del pool.

La revisione del nuovo corpus ha trovato un rischio nel vecchio harness
delle stringhe: un unico GO/DONE per due ondate permetteva al worker
veloce di consumare il permesso destinato all'altro. READY/GO/DONE sono
ora distinti per ondata, nel nuovo corpus e nella fixture delle stringhe.
Originali e diff sono conservati; gli archivi precedenti restano immutati.
La prova corretta delle stringhe conserva i sink 9.707.520/9.969.664,
con overlap preliminare 48.278/48.460 tick. Il test delle testate ha una
sola ondata e resta invariato. Il rilievo riguarda falsi fallimenti/timeout
del protocollo, senza attribuire falsi PASS alle campagne precedenti.

## Misure e mutazioni

Sei fixture 0/20/22/23/32/255, cinque repliche di 4.096 chiamate con
warmup128: 30 campioni con heap osservato zero. Baseline nulla e sensore
positivo 16×1 MiB, 16.777.472 byte osservati. Byte, interi array, NEXT,
token e sink sono ricalcolati dall'audit indipendente: 20.409 controlli.
Il processo bench dura 1,2138 s, i campioni misurati sommano 0,02209 s,
inclusi i controlli dell'output. Il contatore locale non prova assenza
assoluta di allocazione; non vi è soglia di velocità. L'arità è controllata
a freddo nelle sei fixture e in tutte le chiamate del corpus; la misura
calda usa il valore primario e il token dell'output completo.

Otto mutazioni: 8 DETECTED, zero SURVIVED/INVALID/WORKER-ERROR. Baseline
completa riuscita e copie/cache private. L'audit verifica 254 file dichiarati
per copia, sostituzioni uniche e nove log, con 15.320 controlli.
La lettura indipendente controlla separatamente origine e ordine dei
rifiuti, perché la classificazione automatica ereditata non dimostra
causalità dal solo marker smoke e dalla presenza di Unhandled.
L'inventario dichiarato non attesta la chiusura degli alberi privati.

Il mutante della capacità usa MAX tra span e capacità fisica, conservando
l'uso tipizzato di SPAN per evitare un possibile style-warning spurio.
La revisione è statica, prima di compilare le copie: nessun INVALID di
compilazione viene inventato. Il mutante dell'arità sostituisce un unico
frammento DECLAIM+DEFUN: nella sola copia, il FTYPE dichiara il secondo
NIL e il corpo restituisce due valori. Il difetto runtime è uno, l'arità.
Versioni precedenti dei cataloghi e diff sono conservati.

## Copertura e verificatori

Coverage del solo nuovo file: **95/111 espressioni, 20/24 esiti di ramo**.
Tutte le 16 espressioni (quattro dichiarazioni e dodici forme di errore
interno) e i quattro esiti di guardia mancanti rimangono nel denominatore.
Stato grezzo, due HTML e associazioni sintattiche dei gap
sono verificati con 1.178 controlli. L'[inventario](cbor-semplici-decisioni.md)
comprende due AND, la relazione concatenata e l'unione TYPEP dei codici;
non attesta MC/DC o irraggiungibilità. Il gate C1 di ADR-0035 resta aperto.

La [lettura degli strumenti](cbor-semplici-verificatori.md) conserva anche
i limiti del classificatore e degli inventari dichiarati.
La [lettura indipendente dei dati](cbor-semplici-dati.md) confronta i
registri completi, i nove log e i risultati con il corpus congelato.
I self-test dei driver e degli audit passano. L'helper di coverage/mutazioni
esercita 27 fixture sintetiche con 529 controlli; i suoi negativi accettano
un errore generico, senza provare il motivo esatto. L'auditor del benchmark
verifica anche il motivo del rifiuto. Questi controlli verificano coerenza
e stabilità dei byte, senza autenticare l'esecuzione.

Il primo orchestratore locale fallisce con exit1 associando due registri
creati in parallelo tramite differenza delle directory. Entrambi i comandi
figli sono riusciti; nessun prodotto o corpus cambia. La correzione legge
il marker del proprio wrapper e verifica l'argv, con una fixture positiva
e quattro negative riuscite. Originale, osservazione del fallimento e
registri completi dei figli sono conservati; l'osservazione del terminale
è dichiarata parziale. Una correzione di commento dell'auditor chiarisce
la cronologia effettiva, senza cambiare logica o attesi.

## Conservazione

L'[archivio delle campagne](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-simple-write/archive-index.lisp)
conserva processi, sorgenti congelati, revisioni degli strumenti, stato e
HTML di coverage, copie e log. Compressione gzip con verifica dei byte
ricostruiti, senza riscrivere le campagne precedenti o promuovere qualifiche.
Sono 2.439 file indicizzati e 15 processi; il verificatore chiuso conta
2.441 file effettivi, inclusi indice e catalogo, e verifica tutti i byte
e le impronte pubblicate. Processi OK/exit0/STABLE, inventario chiuso.

Il [supplemento finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-simple-write-final/archive-index.lisp)
conserva raccolta, audit dell'archivio originario, controllo completo,
self-test coverage integrata, raccolta finale e primo audit del supplemento,
oltre ai dieci risultati spike, log dei self-test e lettura dati originaria.
Sono 58 file indicizzati, 60 effettivi e sei processi. Anche il sigillo
successivo all'aggiunta dell'audit passa sul contenuto finale; il suo
registro resta nella copia locale completa degli output ignorati.
La verifica chiusa non confronta le origini e non attesta pubblicazione
atomica, autenticità o qualifica C1.

## Integrazione finale

`make check` passa su `b5dcb1a59aa594978d6d3779d039dd03c3a054d3`, che
integra main `7568456cde708007b751e34312d5a3ae6fb0a38b`: routing worker
e suite GET sono inclusi insieme al nuovo writer. **940 test nominali
e due smoke**, compilazione senza warning o style-warning, lint,
self-test dei verificatori, tracciabilità, link, conservazione e dieci
spike riusciti. Durata del comando completo 214,37419 s; i 709 elementi
sorgente coincidono prima/dopo. Prodotto e corpus CBOR conservano i blob
congelati nelle campagne precedenti.
Le 942 righe OK della build e quattro self-test del linter sono tutte
distinte: 946 righe OK nell'output completo. Lint: 159 file, zero violazioni.

Il corpus simple conserva i sink 3.804.160/3.836.928 in entrambe le
ondate, overlap 2.651/2.565 tick; quello stringhe corretto conserva
9.707.520/9.969.664, overlap 50.189/55.312 tick. Timer 1.000.000 tick/s.
Il self-test coverage integrato passa anche dopo l'unione degli scope
GET e simple-write. Nessuna nuova misura di heap o copertura è inferita
dal controllo completo; i limiti delle campagne restano invariati.
