# CRC32C: scelta del kernel e conferma del GET da 4 KiB

Campagna locale del 2026-10-23: Apple M4, SBCL 2.6.9, safety 3,
[metodo preregistrato](../../spikes/SPK-08-generated-code/metodo-crc32c-unroll32.md).
Si mantiene il kernel di prodotto da **16 byte** di
[ADR-0059](../adr/0059-crc32c-arm64-sbcl.md), con il caricamento portabile
di [ADR-0060](../adr/0060-crc32c-caricamento-portabile.md).
Le varianti a 32 B restano nello spike: nessuna modifica a `src/` o ASDF.

## Confronto dei kernel

Due campagne complete da 240 finestre ciascuna, quattro metodi, due offset,
sei dimensioni, cinque repliche. La seconda include le due asserzioni
esplicite presenti nel prodotto; costituisce la base della scelta. La prima
è conservata integralmente, insieme al sorgente antecedente. Tempi unitari
medi per finestra, mediana delle cinque repliche, senza sottrazioni.

Seconda campagna, offset 24 come il corpo del record; nanosecondi per CRC:

| Byte | Software | Prodotto 16 B | 32 B, coda byte | 32 B, coda 4/1 B |
|---:|---:|---:|---:|---:|
| 16 | 23,36 | **11,91** | 20,29 | 44,99 |
| 64 | 78,01 | **14,76** | 15,33 | 15,88 |
| 256 | 347,87 | **34,49** | 35,37 | 34,59 |
| 4096 | 5762,41 | 734,12 | **724,26** | 726,02 |
| 4112 | 5786,15 | **738,96** | 746,52 | 770,40 |

Il corpo di un documento da 4 KiB con chiave da 16 B è lungo **4112 B**.
Su questa dimensione entrambe le varianti peggiorano; su 4096 B il guadagno
è circa l'1%, sotto il 15% preregistrato. Il candidato con coda 4/1 B peggiora
anche a 64 B oltre il 5%. Non si procede alla promozione o alla campagna
GET del candidato. Il kernel attuale è già sotto il microsecondo ed è più
semplice da verificare. L'ipotesi di arrivare a 0,45–0,5 µs con questo
srotolamento non è confermata; questi dati non dimostrano che tutto il
residuo sia dovuto al controllo del ciclo. Non viene introdotto PMULL.

Tutte le **480 finestre CRC** sono complete, con sink corretto e delta
heap zero. I dati grezzi conservano anche offset zero, 65536 B, campioni
individuali, tempo CPU, disassemblati, sensori positivo e vuoto.

## Integrità e selezione

Ogni esecuzione completa verifica **13.536 casi** di lunghezza/offset/seme,
con tutti gli split piccoli e le frontiere 4/16/32 B, contro software e
oracolo bitwise indipendente. Il vettore letterale ASCII `123456789`
restituisce `E3069283` per tutti i kernel e per l'oracolo; è presente anche
nei test di prodotto già integrati. La negativa cambia l'atteso e termina
con exit 1. Sono verificati range, immutabilità, corruzione e byte esclusi.

Il driver legge il candidato soltanto dopo che il backend di prodotto è
stato qualificato e selezionato a runtime. In un processo fresco con software
forzato risulta `:unsupported`, il CRC pubblico resta Lisp e non vengono
caricati candidato o package SIMD. I controlli OS/CPU/versione e il fallback
del prodotto restano quelli già verificati. Nessuna nuova qualifica di ISA,
piattaforma, SBCL o concorrenza deriva dallo spike.
Le [suite CI di prodotto](https://github.com/gpicchiarelli/ArcDocDB/actions/runs/40010510208)
del commit `d8ac5c2f` sono passate su Linux x86-64 e macOS ARM64.

## GET completo

Il [driver A/B](../../tools/get-throughput-bench.lisp) è rimasto invariato:
stessi GET reali, fixture, API, EBR e contatori. Cinque repliche, valori
16/256/4096 B, cache hit/segmento caldo/assente, CSN 7/massimo u64,
software/kernel selezionato e percorso esatto/throughput.

Cache hit da 4096 B, CSN 7; microsecondi per GET:

| Percorso | Software | Kernel attuale |
|---|---:|---:|
| Oracolo originale nel timing (`:exact`) | 14,972 | **9,813** |
| Oracolo prima/dopo la finestra (`:throughput`) | 6,716 | **1,647** |

Il segmento caldo con cache disabilitata misura 2,334 µs nel percorso
throughput hardware. Le **360 finestre**, 14,4 milioni di GET, sono complete
e hanno delta heap zero; 72 finestre bounded precedono le misure. L'integrità
di ogni risposta resta controllata nel percorso esatto e nella suite; il
throughput verifica tutte le chiavi prima e dopo ogni finestra. Nessun P99
è dedotto dalle medie. Il perimetro è il backend engine con dati caldi;
la misura di ARTICLE attraverso protocollo e socket resta separata.

## Verifica e conservazione

Compilazione rigorosa dei due nuovi file C4 senza warning/style-warning.
Due letture dell'autore, distinte dalla revisione indipendente e dalla
qualifica C1 complessiva. Il primo driver C4 non poteva leggere il package
prima di caricare il prodotto; corretto separando i form di bootstrap.
Il primo helper di compilazione ricaricava due volte i VOP del prodotto;
corretto usando una sola inizializzazione in un processo fresco. Entrambi
i fallimenti e i sorgenti originali sono conservati. Nessun warning soppresso.

[Archivio completo: sorgenti, disassemblati, fallimenti e dati grezzi](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-crc32c-unroll32/catalogo.lisp).
