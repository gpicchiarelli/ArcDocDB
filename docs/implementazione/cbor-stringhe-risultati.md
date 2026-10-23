# Verifiche della scrittura delle stringhe CBOR

Campagne del 2026-10-11 sul [metodo preregistrato](cbor-stringhe-metodo.md),
blob `56342dae95caf8705e0b28b3c0ea7ac86fdd8fa0`. Prodotto congelato
`a2c5c77dd51bff760bff4508e998d94370921eda`; le dipendenze header writer,
UTF-8 e limiti non sono state modificate. L'incremento riguarda un item
MT2/3 minimo, senza composizione documentale o pubblicazione durevole.

Il titolo «Prove congelate prima del prodotto» del metodo descrive il piano
preregistrato. La cronologia effettiva è quella delle due letture: prodotto
e corpus sono stati sviluppati in parallelo; l'autore delle prove ha letto
il prodotto soltanto dopo il congelamento del corpus, prima della seconda
lettura e di ogni compilazione o campagna. Il metodo originale resta
conservato, senza attribuire al corpus un congelamento precedente al prodotto.

## Corpus e concorrenza

21 nuovi test: 20 seriali e uno con worker reali riusati. Il preliminare
`make test lint trace` passa in 13,692469 s: 681 test nominali e due smoke,
senza warning o style-warning, lint su 125 file senza violazioni,
116 requisiti/65 invarianti/13 scenari FI/52 ADR senza errori.
Il corpus cieco conserva i tre blob `e45437a5…`, `ed0f6a67…`, `33c7e6a9…`;
le [due](cbor-stringhe-revisione.md) [letture C1](cbor-stringhe-lettura.md)
non hanno rilievi statici aperti.
La [revisione dei dati](cbor-stringhe-dati.md) verifica i record completi,
anche l'origine e l'ordine dei fallimenti nei log mutati.

8.194 confronti freddi sulle lunghezze 0..4096 per entrambi i major,
1.138 capacità insufficienti e 2.048 casi differenziali seed53574342:
1.546 accettati e 502 UTF-8 rifiutati. Sono verificati soglie di larghezza,
item massimo 16 MiB e massimo+1, byte arbitrari, multibyte, NUL/BOM e
noncaratteri, offset assoluti e precedenze degli errori, alias disgiunti,
overlap della testata, arità esatta e interi array invariati sui rifiuti.
Lo scanner minimo è soltanto una verifica supplementare dopo gli attesi
freddi dei byte.

Due worker, due ondate, 8.192 item ciascuno per ondata: 32.768 scritture
e 32 MiB di payload da sorgente immutabile condivisa verso destinazioni
private. Sink 9.707.520/9.969.664 per ondata e array completi verificati.
Overlap osservato 47.821/47.752 tick a 1.000.000 tick/s nel preliminare;
semafori, join e cleanup limitati. Questo verifica concorrenza funzionale,
senza attestare simultaneità sui core, scaling o throughput del pool.

## Heap e mutazioni

Nove fixture indipendenti, cinque repliche di 4.096 chiamate con warmup
128: 45 campioni con heap osservato zero. Baseline nulla e sensore positivo
16×1 MiB, 16.777.472 byte osservati. NEXT, tutti i byte e le sentinelle
alimentano token e sink ricalcolati dall'audit indipendente. Misura seriale
83,243866 s, inclusi controlli dell'output, senza soglia di velocità;
il contatore locale non costituisce prova assoluta di non allocazione.

Otto mutazioni congelate: 8 DETECTED, zero SURVIVED/INVALID/WORKER-ERROR.
Baseline completa riuscita, copie e cache private; 210 file per ciascuna
delle nove copie nell'inventario dichiarato. L'audit confronta la baseline,
la sostituzione unica e i log runtime: 11.828 controlli riusciti.
Compilazione fallita, segnale OS o guasto dopo completamento non contano
come rilevamento; i self-test esercitano anche questi casi con processi
reali. L'overlap mutato ignora precisamente il byte iniziale della testata.

## Copertura e verificatori

Coverage del solo nuovo file: **256/308 espressioni, 39/52 rami**.
Restano 52 espressioni e 13 esiti di ramo nel denominatore: sette
dichiarazioni, 44 forme di errore interno e il default MAX-BYTES nella
lambda-list, riga 99, percorso grezzo `(8 2 11)`, senza deduzioni di
irraggiungibilità. I 13 esiti mancanti sono associati sintatticamente a guardie interne.
Stato grezzo e due HTML concordano, verificati con 74 controlli.
L'[inventario](cbor-stringhe-decisioni.md) conserva cinque AND e sei
relazioni concatenate, senza esclusioni o attestazioni MC/DC/100%.
Il gate C1 di ADR-0035 rimane aperto; il motore non è qualificato da questi dati.

Il primo autotest del verificatore indipendente del benchmark fallisce
con exit 1: mancavano i setter degli accessori delle fixture sintetiche.
Il sorgente originale `1e0fe5b8…`, il processo fallito e il diff sono
conservati. Il fix `ae591bf0…` aggiunge soltanto due setter: retry riuscito
con quattro fixture positive e 54 negative, 37.424 controlli. Prodotto,
driver di misura e corpus restano invariati. Il reader preserva T/NIL,
blocca READ-EVAL e richiede EOF; il clock ammette l'ordine effettivo di
raccolta dei metadati. Anche l'helper di coverage/mutazioni passa i propri
self-test, derivati dal verificatore precedente preservato.

Questi audit controllano coerenza dei dati e stabilità dei byte, senza
autenticare l'esecuzione. L'inventario delle copie riguarda le impronte
dichiarate; non attesta automaticamente la chiusura degli alberi privati.
Le associazioni dei gap sono sintattiche e non dimostrano irraggiungibilità.

## Conservazione e integrazione

[Archivio originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write/archive-index.lisp)
con processi, tentativo fallito, sorgenti congelati, helper, stato/HTML,
copie e log. La compressione gzip preserva e verifica i byte ricostruiti;
non riscrive campagne precedenti o deduce qualifiche dai loro esiti.
L'audit chiuso verifica 2.026 file indicizzati e i due metadati dell'archivio,
compresi i file nascosti: impronte e inventario completi, 15 processi.

Integrazione su `ceac2dedfcfd6af05f2331282645bebf4b5be442`, conservando
hash/key-hash, GET e suite EBR/read. `make check` passa in 172,707537 s,
con sorgenti STABLE: 791 test nominali e due smoke, 793 nomi OK distinti,
138 file prodotto senza violazioni, tracciabilità senza errori e dieci
spike completati. I 643 elementi sorgente coincidono prima/dopo;
compilazione senza avvisi, corpus e prodotto congelati invariati.
Le due ondate del writer conservano i sink precedenti, con overlap
49.011/47.867 tick a 1.000.000 tick/s. Il self-test dei selettori di coverage
integrati passa separatamente. Blob ASD `4a4734596cada6eac70dda6709b4804a25acb9de`,
coverage `3a4af4b1efe2a2c37599ec804f6ed06c80733491`.

L'[archivio finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write-final/archive-index.lisp)
conserva raccolta, audit chiuso originale, controllo integrato, self-test,
risultati dei dieci spike e copie dei due file di integrazione.
Il passaggio dei controlli non chiude i gap C1/MC/DC descritti sopra.

L'ulteriore aggiornamento di main `92decf4` aggiunge il collegamento
worker/Serie; è unito nel commit `997f5e6505cdcf4554d5f99ede7d5743ce4be7bd`.
Un secondo `make check` passa in 177,072076 s: 817 test nominali e due
smoke, 819 nomi OK distinti, compilazione senza avvisi, lint su 142 file
senza violazioni, tracciabilità senza errori e dieci spike completati.
I 655 elementi sorgente restano STABLE; prodotto e corpus del writer
sono invariati. Overlap delle due ondate 47.829/47.750 tick, sink invariati.
L'ASD integrato ha blob `3b163722ff7b49e6ada85e37e21a7665cc7ce28f`;
il driver coverage conserva il blob `3a4af4b1…`.
Il [supplemento worker/Serie](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-cbor-string-write-worker-integration/archive-index.lisp)
conserva il nuovo controllo completo, i suoi spike e i file integrati,
senza riscrivere le campagne precedenti.
