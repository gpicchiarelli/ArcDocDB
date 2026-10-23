# Verifiche della composizione delle mappe CBOR

Campagna del 2026-10-14 per [REQ-CBR-006](cbor-map-metodo.md):
composizione strutturale MT5 da chiavi e valori già codificati.
Ordinamento, unicità delle chiavi e profilo documentale restano ai livelli
superiori. Le [prove originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-cbor-map-write/catalogo.lisp)
conservano corpus, letture, processi registrati e risultati grezzi.

## Sorgenti e cronologia

Metodo `636dd2706c2903542978606cf029e7198bf4dbb3`, preregistrazione
`2968cdc8ef50e35f418b96d58e27b6a5ecf7fcb3`. Il corpus cieco è congelato
prima dei due sorgenti di prodotto; due letture C1 precedono la prima
compilazione.

| File | Blob Git |
|---|---|
| src/codec/cbor-map-input.lisp | d7a593badeb6e6b71f28dc4e80c641b07189d0b8 |
| src/codec/cbor-map-write.lisp | 22e814ea68e606c5bc58033c2a31e945303a9d65 |
| tests/codec/cbor-map-write-support.lisp | a389e51f2416437d608c4f7745b9680eca27bc60 |
| tests/codec/cbor-map-write.lisp | 6ad0e9b5a48ba9c32c46d720f2f7f1821368d6c8 |
| tests/codec/cbor-map-write-threads.lisp | 6a65b58ce236b92b33772e1861dbd8c1257bee13 |

Le letture inventariano dieci funzioni di 9–38 righe e 3–9 percorsi,
cinque AND/OR con 14 operandi, nove confronti concatenati, 40 guardie
e due cicli, senza esclusioni. Prima delle campagne viene aggiunto il
RUN delle mappe allo scope aggregato codec del tool di copertura.
Prodotto e corpus restano invariati; il tool verificato è `e273f103`.

Una correzione documentale usa erroneamente nomi transitori dei test:
viene annullata prima della prima compilazione, ripristinando
l'inventario `16c60314`. Entrambe le versioni e la nota sono conservate.
Il freeze compilato è `15c458eff76896f3fc83ad7756ae922f64eb22d7`,
con working tree pulito.

## Corpus e parallelismo

Passano 20 test nominati: 19 seriali e uno parallelo, con oracoli freddi
per testata, payload e interi buffer. Sono verificati COUNT 0/1/23/24/255/256,
tipi e range, tutte le precedenze, metà tabella e span prima del raddoppio,
code inattive pari e dispari, alias anche vuoti, overlap della testata,
capacità esatta e insufficiente, budget completo di 16 MiB e superamenti,
nodi/tag/radice, profondità 99/100 dei figli, parsing delle chiavi e valori,
riuso dello scratch e arità. Sono aggiuntivi 65 roundtrip dello scanner.

Fuzz: 1024 chiamate con seed `4D415035`, 512 successi e 64 rifiuti
per ciascuna delle otto famiglie d'errore. Lo stato finale `0D123435`
è asserito nel corpus e ricalcolato dal lettore indipendente; la campagna
non lo stampa.

Due worker reali riusati per due ondate di 2048 chiamate ciascuno:
8192 composizioni, con sorgente e tabella condivise in lettura e
destinazioni/scratch privati. Sink 54677504/77537280, NEXT 12/16 e
buffer 19/23 concordano con gli oracoli freddi. Nel primo build si
osservano overlap di 3107/3104 tick a un milione di tick/s; il check
completo osserva 3160/3067 tick. Gli intervalli individuali non sono
stampati; non si deducono scaling o simultaneità sui core.

Le 9499 chiamate alla nuova API sono un totale aritmetico dal piano:
283 non fuzz, 1024 fuzz e 8192 parallele; non è un contatore strumentato.

## Benchmark e mutazioni

Sei fixture fredde, cinque repliche da 1024 chiamate e warmup di 64:
30 campioni con zero byte osservati dal contatore heap. Baseline nulla
zero e controllo positivo di 16 × 1 MiB: 16777472 byte. NEXT, interi
buffer, sorgente e tabella vengono verificati durante la misura; l'arità
è controllata a freddo. I campioni sommano 0,682974 s, il wrapper dura
2,388207 s. Carico esterno non controllato e costo dei controlli incluso;
non si attestano assenza assoluta di allocazioni o throughput del motore.
L'audit indipendente passa 79357 verifiche sui dati.

Otto mutanti compilabili risultano DETECTED: capacità fisica, MT4,
numero di item nella testata, scansione omessa, overlap senza testata,
fini non verificati, nodo radice escluso e arità extra. Ogni log contiene
smoke esatto, Unhandled e una funzione nominale del corpus congelato,
con exit 1, segnale NIL e nessun errore worker. Warning, compilazioni
fallite, guasti helper, segnali e errori dopo il completamento non valgono
come rilevamento. La baseline passa 1284 nominali e due smoke; il wrapper
della campagna dura 236,203910 s.

Nove copie/cache private, 345 file per copia, 350 impronte interne e
860 fonti esterne stabili. Il lettore DATA confronta binariamente tutti
i file: baseline senza differenze, una sostituzione esatta del catalogo
in ciascun mutante. FTYPE e corpo dell'arità extra cambiano coerentemente
nella sola copia. Il confronto non autentica l'esecuzione né dimostra
causalità esclusiva.

## Copertura grezza

| Sorgente | Espressioni | Rami |
|---|---:|---:|
| cbor-map-input.lisp | 272/317 | 45/54 |
| cbor-map-write.lisp | 190/266 | 19/36 |
| Totale | 462/583 | 64/90 |

Denominatori integrali: 583 espressioni e 90 rami; copertura 79,245283%
e 71,111111%, sotto il requisito C1. Le 121 espressioni mancanti includono
14 dichiarazioni top-level, 104 sottoforme ERROR di 26 guardie interne e
tre default keyword. Tutti i 26 rami mancanti restano nel dato grezzo.
Reader, summary e HTML concordano; nessun punto è escluso o
riclassificato. SB-COVER non attesta MC/DC.

Il primo reader DATA fallisce per una parentesi prima di leggere il
record; la variante corretta passa senza nuova campagna del prodotto.
Entrambi i tentativi sono conservati. Dopo la lettura il raw di 2573180
byte viene compattato senza perdita; SHA256 decodificato
`22d23eb3d3f6929d92952713ca9f60287a2c1becf4c5c3b6c538b6ee59e4ef86`.
Il payload misura 363928 byte; restano i limiti 1 MiB plain e 8 MiB gzip.

## Verifiche integrate

Sul freeze `15c458ef` passano il check completo, 1284 nominali e due
smoke, quattro self-test linter, 207 file con zero violazioni, 120
requisiti, 65 invarianti, 13 scenari FI e 52 ADR senza errori; 440 file
e 2914 link senza rotture. Passano i self-test di conservazione, 98
cataloghi con 3136 riferimenti e 25236 file, e tutti i dieci spike.
Wrapper: 260,414101 s; 860 fonti stabili. I fallimenti intenzionali
dei self-test e le note del compilatore rimangono nei dati grezzi.

Dopo l'integrazione di `main` a `55149bfd`, sul merge `e4b3b826`
passano build, lint, trace e link: 1297 nominali e due smoke, 212 file
con zero violazioni, gli stessi 120 requisiti/65 invarianti/13 FI/52 ADR,
452 file e 2952 link senza rotture. Wrapper: 41,161955 s; 872 fonti
stabili e working tree pulito. I cinque blob di prodotto/corpus delle
mappe restano identici. La verifica completa precedente conserva il
proprio scope; questo secondo comando non riesegue gli spike globali.

## Conservazione

La raccolta iniziale usa quattro worker e chiude 311 file per 14
processi; copie per worker: 103/34/70/104, senza errori. Le impronte
dell'origine prima/dopo e della copia concordano, i processi decodificati
sono identici e il validator indipendente verifica l'inventario chiuso.

Le append seriali conservano preparazione, preflight, raccolta, lettura
DATA e copie verificate dell'osservazione/closure originali. L'inventario
finale contiene 19 processi registrati, tutti OK/exit 0/STABLE, e 325 file
indicizzati (327 con indice e catalogo). I file indicizzati sommano
7644795 byte; l'indice misura 118625 byte. I limiti restano 1 MiB plain
e 8 MiB gzip. L'audit delle impronte e dei metadata passa prima e dopo
ogni append. Il validator indipendente dell'inventario chiuso riguarda
la raccolta iniziale di 311 file; il suo esito non si estende alle append.

Le nove copie integrali dei mutanti restano nel backup locale verificato.
L'archivio pubblicato conserva log, ASDF, runner, prodotti/corpus delle
mappe per tutte le copie e il report con le impronte complete. Gli altri
sorgenti immutati sono ricostruibili dal commit `15c458ef`; i nove mirror
integrali non sono tutti duplicati nell'archivio.

Le preparazioni e i tentativi falliti riportati nelle letture sono preservati.
Le verifiche conservano questi scope distinti. C1 e MC/DC restano aperti.
