# Verifiche della composizione dei tag CBOR

Campagna del 2026-10-14 per [REQ-CBR-007](cbor-tag-metodo.md):
composizione strutturale MT6 da un item già codificato. La semantica
applicativa dei tag e il profilo documentale restano ai livelli superiori.
Le [prove originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-cbor-tag-write/catalogo.lisp)
conservano corpus, letture, processi registrati e risultati grezzi.

## Sorgenti e cronologia

Metodo `3175390e496173398781bf8b39170cb33892125f`, preregistrazione
`44017fe7d117f7107989c453687b8f68280b78bf`. Il corpus cieco precede
il prodotto; due letture C1 precedono la prima compilazione.
Il freeze compilato è `df37306ed0e97f1665fb9f59aca79842c49d96a5`,
con working tree pulito.

| File | Blob Git |
|---|---|
| src/codec/cbor-tag-input.lisp | 6dfad07035ac8040b2aec0a455c175ea15dfd9ad |
| src/codec/cbor-tag-write.lisp | 16b91fc27eabafd7ff12bfb0a56ed34208c2bd4b |
| tests/codec/cbor-tag-write-support.lisp | 15978d05251705387205d6468031a701ad95ec85 |
| tests/codec/cbor-tag-write.lisp | df97950ec8d24157bb6566c7995262f7beea7742 |
| tests/codec/cbor-tag-write-threads.lisp | def870295400af2c84ca00e7a9b5cd5b747ec315 |

Le sei funzioni misurano 9/19/11/24/21/33 righe e 4/6/8/5/8/4
percorsi. Inventario completo: 23 guardie e relativi ERROR, cinque
AND/OR con 11 operandi, due confronti concatenati con quattro
relazioni, 21 confronti binari, nessun nuovo ciclo.
I witness pubblici coprono alias e overlap; i rami interni non osservati
restano nei denominatori e negli obblighi aperti.

La matrice era ancora progettata durante le letture statiche: viene
rigenerata prima del freeze e della prima compilazione. Lo scope
aggregato codec include il RUN dei tag. Prodotto e corpus restano
invariati durante tutte le campagne e l'integrazione.

## Corpus e parallelismo

Passano 20 test nominati, 19 seriali e uno parallelo, con oracoli
freddi per testata, payload, interi buffer, sorgente e scratch.
Sono verificati i confini u32 e tutte le larghezze della testata,
sentinelle wire, range, precedenze, alias, overlap comprensivo della
testata, capacità logica, limite completo di 16 MiB, nodi comprensivi
della radice, profondità zero/100/101, catene di oltre mille tag senza
frame aggiuntivi, parsing completo e arità. I 116 roundtrip dello
scanner sono controlli secondari.

Fuzz: 1024 chiamate con seed `54414737`, 512 successi e 512 rifiuti.
Lo stato finale `F8004B37` è asserito nel corpus e ricalcolato
indipendentemente; la campagna non lo stampa.

Due worker reali riusati per due ondate di 2048 chiamate ciascuno:
8192 composizioni con sorgente condivisa in lettura e destinazioni
e scratch privati. NEXT 13/17, token 32601/47515 e sink
66766848/97310720 per worker e ondata concordano con gli oracoli.
Nel primo build si osservano overlap di 2333/2329 tick a un milione
di tick/s; nel check completo 1687/2704 tick. Gli intervalli
individuali non sono stampati; non si deducono scaling o simultaneità
sui core.

Le 9658 chiamate alla nuova API sono un totale aritmetico dal piano:
442 non fuzz, 1024 fuzz e 8192 parallele; 8848 successi e 810 rifiuti.
Non è un contatore strumentato.

## Benchmark e mutazioni

Sei fixture fredde, cinque repliche da 1024 chiamate e warmup di 64:
30 campioni, tutti con contatore heap presente e pari a zero.
Baseline nulla zero e controllo positivo di 16 × 1 MiB superato.
NEXT 4/7/6/10/14/17 e token 5368/10359/9825/10464/16425/43144
concordano con le fixture. Il wrapper dura 3,047504 s.
Carico esterno non controllato e costo dei controlli incluso:
non si attestano assenza assoluta di allocazioni o throughput
del motore. L'audit indipendente passa 68028 verifiche sui dati.

Otto mutanti compilabili risultano DETECTED: capacità fisica, MT5,
metà high/low scambiate, scansione omessa, overlap senza testata,
nodo radice escluso, profondità del figlio decrementata e arità extra.
Ogni log contiene smoke esatto, Unhandled e una funzione nominale
della whitelist congelata, con exit 1, segnale NIL e nessun errore
worker. Warning, compilazioni fallite, segnali e guasti dopo il
completamento non valgono come rilevamento. La baseline passa
1412 nominali e due smoke; il wrapper dura 286,719013 s.

Nove copie/cache private, 361 file per copia, 366 impronte interne
e 892 fonti esterne stabili. Il lettore DATA esegue 3249 confronti
binari contro l'intero contesto Git del freeze e gli originali:
baseline senza differenze e una sostituzione esatta del catalogo
in ciascun mutante. FTYPE e corpo dell'arità extra cambiano
coerentemente nella sola copia. Il confronto non autentica
l'esecuzione né dimostra causalità esclusiva.

## Copertura grezza

| Sorgente | Espressioni | Rami |
|---|---:|---:|
| cbor-tag-input.lisp | 176/206 | 26/34 |
| cbor-tag-write.lisp | 115/158 | 10/20 |
| Totale | 291/364 | 36/54 |

Denominatori integrali: 364 espressioni e 54 rami, copertura
79,945055% e 66,666667%, sotto il requisito C1. Le 73 espressioni
mancanti includono dieci dichiarazioni, 60 sottoforme ERROR e tre
default keyword; restano inoltre 18 rami ELSE, per 91 record mancanti.
Tutti i punti rimangono nel dato
grezzo, senza esclusioni. Reader, indice e HTML concordano.
SB-COVER non attesta MC/DC.

Dopo la lettura indipendente il raw di 2775201 byte viene compattato
senza perdita; SHA256 decodificato
`3309ea12a2d6acc7d734101748ecbf73e8461284f4c3889d1159127384ee2625`.
Il payload misura 395719 byte; restano i limiti 1 MiB plain e 8 MiB gzip.

## Verifiche integrate

Sul freeze `df37306e` passa il check completo: 1412 nominali,
due smoke, quattro self-test linter, 214 file con zero violazioni,
121 requisiti, 65 invarianti, 13 scenari FI e 52 ADR senza errori;
472 file e 2988 link senza rotture. Passano i self-test di
conservazione, 102 cataloghi con 3237 riferimenti e 28687 file,
e tutti i dieci spike. Wrapper 314,315971 s; 892 fonti stabili.
I fallimenti intenzionali dei self-test e le note del compilatore
rimangono nei dati grezzi.

Dopo l'integrazione di `main` a `505f531f`, sul merge `7fbd327f`
passano build, lint, trace e link: 1440 nominali e due smoke, 224 file
con zero violazioni, gli stessi 121 requisiti/65 invarianti/13 FI/52 ADR,
490 file e 3041 link senza rotture. Wrapper 45,121117 s; 912 fonti
stabili e working tree pulito. I cinque blob di prodotto/corpus dei tag
restano identici. Le 8192 composizioni parallele osservano overlap
2336/2284 tick. La verifica completa precedente conserva il proprio
scope; questo secondo comando non riesegue gli spike globali.

## Conservazione

La raccolta iniziale usa quattro worker e chiude 397 file per 15
processi; copie per worker: 132/132/132/1, senza errori. Le impronte
dell'origine prima/dopo e della copia concordano, i processi decodificati
sono identici e il validator indipendente verifica l'inventario chiuso.

Le append seriali conservano preparazione, preflight, raccolta, lettura
DATA e copie verificate dell'osservazione/closure originali. L'inventario
finale contiene 20 processi registrati: 19 OK/exit 0 e un tentativo
preparatorio FAILED/exit 1; tutti hanno fonti STABLE. I 411 file
indicizzati sommano 8444662 byte; i file complessivi sono 413 includendo
indice e catalogo.
L'indice misura 147480 byte; i limiti restano 1 MiB plain e 8 MiB gzip.
L'audit delle impronte e dei metadata passa prima e dopo ogni append.
Il validator indipendente dell'inventario chiuso riguarda la raccolta
iniziale di 397 file; il suo esito non si estende alle append.

L'archivio pubblicato conserva i log, ASDF, runner, prodotto e corpus
dei tag per tutte le nove copie e il report con le impronte complete.
Le nove copie integrali restano nel backup locale verificato; gli
altri sorgenti immutati sono ricostruibili dal commit `df37306e`.

Il primo mutator materializzato contiene due pin di helper ancora
riferiti alle mappe: vengono corretti prima dei self-test e delle
campagne, preservando la versione precedente e il diff. Un tentativo
registrato usa opzioni CLI di self-test invalide: fallisce prima
del prodotto, resta FAILED nell'archivio e viene seguito dal comando
corretto. Le due preparazioni del reader mutazioni vengono conservate
prima della lettura conclusa. Anche la parentesi del cloner C4 è
corretta in una variante preservata: il diagnostico originale è
riportato nella nota, senza attribuirgli un log locale non disponibile.
Le altre varianti preparatorie sono inventariate nelle letture.

Le verifiche conservano questi scope distinti. C1 e MC/DC restano aperti.

