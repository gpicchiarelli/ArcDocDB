# Verifica dell'attuazione logica dei worker

La campagna C3 verifica porte, richieste e conferme dei worker preallocati
secondo [contratto](pool-worker-lifecycle.md),
[metodo preregistrato](pool-worker-lifecycle-metodo.md) e
[lettura del codice](pool-worker-lifecycle-revisione.md).
La copia congelata parte da `c4bbb037b779d33ee9e8c01b4a33aac875ccf96f`
e conserva i tredici file dell'incremento. Byte originali e identità sono
raccolti nel [catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/).

## Processi congelati

| Processo | Record | Esito |
|---|---|---|
| Compilazione strict e self-test C4 | [4000910603-command-11895-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| Due campagne del percorso normale | [4000910621-command-11962-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| Copertura e suite scheduler | [4000910644-command-12377-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| Controllo completo del repository | [4000910703-command-13310-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/check-core/report.lisp) | OK, STABLE, exit 0 |

Il build degli strumenti e del prodotto tratta warning e style-warning
come errori. La suite della copertura passa 41 prove: 23 del controllore
esistente e 18 nuove dell'attuazione logica. I self-test C4 rilevano
16777472 byte di allocazione deliberata, respingono sink e risultati API
difformi, distinguono il clock sotto risoluzione e conservano raw parziali
e destinazioni preesistenti. Il controllo completo passa 1076 prove nominate,
gli smoke test, lint, tracciabilità, link, self-test degli strumenti, conservazione
delle evidenze e i dieci spike. L'esecuzione dura 201,656 secondi.

Due tentativi preliminari del controllo completo restano falliti e conservati:
[opzioni shell](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/check-core-attempt-1/report.lisp)
e [configurazione della cache](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/check-core-attempt-2/report.lisp).
Entrambi terminano prima dei test del prodotto; i loro esiti non vengono promossi.

## Copertura

Nativo SB-COVER e indice HTML concordano sui cinque nuovi file lifecycle
e sul package: **414/415 espressioni (99,759%), 60/60 rami (100%)**.
Il minimo C3 del 95% è superato senza esclusioni di file o percorsi.
I vecchi sorgenti del controllore e dei worker non contribuiscono a questi
denominatori; i percorsi generati dei nuovi sorgenti restano inclusi.
Non si deduce MC/DC dai conteggi.

L'unica espressione mancante resta nel denominatore: file
`src/scheduler/lifecycle-build.lisp`, indice nativo 36, percorso `(3 2 3)`;
l'HTML la colloca nell'inizializzatore facoltativo `(active t)` alla linea
10. L'[inventario degli originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/development-manifest.lisp)
identifica stato nativo, indice e sei pagine HTML, conservati senza perdita
nei bundle; l'[audit esatto](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/data/coverage-audit/coverage-audit.lisp)
conserva conteggi e percorsi mancanti. La misura
passa al primo tentativo congelato; i raw preliminari conservano la loro
identità distinta.

## Misura locale

Due campagne separate, ciascuna con cinque repliche da 4096 cicli misurati
e 128 cicli di warmup per replica: **20480 cicli misurati per campagna**,
dieci campioni complessivi nel [rapporto del sensore](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/data/benchmark/report.lisp). Factory, avvio dei thread della fixture,
sincronizzazione e GC completa precedono il tratto misurato.

APPLY esegue ritiro, conferma ripetuta, attivazione e conferma ripetuta su
un contesto autentico IDLE. Le richieste private C4 sono seriali e le
generazioni progrediscono senza reset; questa fixture non misura il
coordinatore concorrente. REGISTRY usa due registri distinti con quattro
contesti creati su due owner reali; ogni ciclo esegue due update e due
letture nelle condizioni hold e pending, senza attese nel sensore.

| Replica | Tick APPLY | Tick REGISTRY | Byte heap APPLY / REGISTRY |
|---|---:|---:|---:|
| 0 | 647 | 1351 | 0 / 0 |
| 1 | 640 | 1425 | 0 / 0 |
| 2 | 646 | 1271 | 0 / 0 |
| 3 | 655 | 1261 | 0 / 0 |
| 4 | 644 | 1271 | 0 / 0 |

SBCL 2.6.9, ARM64, Apple M4, Darwin 27.0.0; safety 3 e carico esterno non
controllato. Il clock ha 1000000 unità al secondo. Tutti i dieci campioni
completano 4096 cicli con sink atteso e zero byte heap osservati.
I tick sono osservazioni locali, senza soglia di tempo, taratura o
conclusione sul throughput. Il sensore non dimostra assenza universale di
allocazioni.

L'attuazione verificata è logica: nessun thread OS viene avviato,
sospeso o distrutto dal prodotto. Park/wake, shutdown, worker morti,
admission, I/O, sensori reali e un pool completo restano fuori scope.

## Integrazione su main

Dopo la campagna congelata, il commit `0714638e56a4a058b74839064a2b00dd583c5384`
è stato integrato con `ba78d8272a475af25e89b7df8c5033ff50e30b3b`, contenente
i nuovi componenti GET e inizializzazione ACTIVE. Il merge
`a95dab36f40560157a6631557e4774a8b320fde5` conserva byte per byte package,
cinque sorgenti lifecycle, test e sensore della qualifica. ASDF integra i moduli
aggiuntivi; il changelog conserva entrambe le aggiunte concorrenti.

Il [controllo integrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/integrated-build/report.lisp)
`4000911049-command-19367-0` passa 1099 prove nominate e gli smoke test,
compilazione strict, lint e tracciabilità: OK, STABLE, exit 0, 30,059868 secondi.
La campagna completa e i dieci spike restano quelli della base congelata; non
si attribuisce retroattivamente quel processo al merge. Le evidenze conservano
separatamente sorgenti qualificati e sorgenti finali, inclusi i documenti aggiunti.

## Conservazione C4

Il [self-test della conservazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/publication-selftest/report.lisp)
`4000911543-command-23689-0` passa 58 controlli: OK, STABLE, exit 0.
Verifica copie esclusive, byte e identità originali, inventario UTF-8,
payload gzip senza perdita e rifiuto di file speciali o fonti mutate.

Il [primo tentativo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/publication-selftest-attempt-1/report.lisp)
resta FAILED, STABLE, exit 1: la fixture cercava il pathname `/tmp`
nel record che conservava l'identità canonica `/private/tmp`. La correzione
normalizza soltanto quel lookup; byte, SHA, Git blob e roundtrip restano
verificati dalle medesime asserzioni. Fonti, diagnostica e payload originali
del tentativo sono conservati con il loro esito distinto.

La [pubblicazione delle copie](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/publication/report.lisp)
`4000911736-command-27429-0` termina OK, STABLE, exit 0, dopo aver verificato
gli originali e le copie. Il [controllo finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-lifecycle/processes/final-verification/report.lisp)
`4000911991-command-38401-0` passa link e conservazione: OK, STABLE, exit 0,
154,602746 secondi, 370 file Markdown e 2748 link senza rotture;
84 cataloghi, 18868 file conservati, 535386346 byte. Questi conteggi
appartengono al processo prima dell'aggiunta delle sue copie di chiusura.
Un nuovo manifesto conserva quei record e la versione conclusiva di questo
documento senza sostituire i raw o i manifesti precedenti.
