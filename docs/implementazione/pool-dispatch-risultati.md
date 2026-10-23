# Verifica del collegamento pool/Serie

La qualifica segue [contratto](pool-dispatch.md),
[metodo preregistrato](pool-dispatch-metodo.md) e
[lettura indipendente C3](pool-dispatch-revisione.md).
Base congelata `14fd7738c216e3a0bd3ce9612576b9b57d648f74`, tredici
fonti dell'incremento e quattordici helper copiati byte per byte.
Gli originali sono nel [catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/).
La data del namespace segue la preregistrazione; i record conservano i propri
tempi originali e non vengono retrodatati.

## Processi

| Processo | Record originale | Esito |
|---|---|---|
| Adattatore di pubblicazione, fixture positive e negative | [4000917478-command-65255-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/publisher-selftest/report.lisp) | OK, STABLE, exit 0 |
| Reader native/HTML strict e self-test | [4000917499-command-65649-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/coverage-reader/report.lisp) | OK, STABLE, exit 0 |
| Sensore strict e self-test | [4000917499-command-65650-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| Copertura e scheduler completo | [4000917538-command-66469-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| Tre campagne locali | [4000917578-command-67114-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| Controllo completo congelato | [4000917476-command-65223-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/check-core/report.lisp) | OK, STABLE, exit 0 |
| Build, test, lint e trace dopo integrazione | [4000917560-command-66775-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/integrated-build/report.lisp) | OK, STABLE, exit 0 |

Le **14 nuove prove** passano; scheduler completo **67/67**. Usano due
writer reali con ordinali differenti, routing senza begin implicito e doppia
lease esplicita, batch confermati e fine del bridge. Verificano binding e owner
prima di ACK/claim, assenza di routing per INACTIVE/EMPTY/BUSY, ritiro pendente,
writer-busy con guard CAS e retry dell'obbligo, ricircolo full A→B e routing
del nuovo writer. Il lookup CLAIMED ignora le parole pool deliberatamente
incoerenti, mentre il gate IDLE conserva il rifiuto.

La prova di attivazione seguita da routing invalido usa un claim reale:
ACK confermato, writer/home e obbligo conservati in FAULTED, causa EQ e
controller invariati. La richiesta di attivazione è una FI quiescente del
coordinatore, non una gara casuale. Altre FI dichiarate verificano preimage
su fasi/debiti corrotti, binding privati e ritorni writer/status incoerenti;
le sentinelle di funzione sono ripristinate. Non si deduce una qualifica
dei protocolli C1 dai soli quattordici test nuovi.

Il controllo completo congelato passa **1148 prove nominate del prodotto,
due smoke e quattro fixture del linter**, oltre a lint, trace, link,
self-test degli strumenti, conservazione e dieci spike. Dura 241,266408
secondi; i 1154 marker `ok` includono le quattro fixture, senza chiamarle
test del prodotto. Compilazione senza warning/style-warning; stderr contiene
le note del compilatore, conservate nell'originale.

## Copertura

Il dato SB-COVER nativo e cinque pagine HTML originali concordano sull'intero
scope, **110/114 espressioni (96,49%) e 10/10 rami nativi (100%)**.
Il gate C3 preregistrato del 95% è superato, con **nessuna esclusione manuale**.
Il nativo originale occupa 2306672 byte; [audit della biblioteca](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/data/coverage-audit/coverage-audit.lisp)
e [audit dispatch](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/data/dispatch-coverage-audit/coverage-dispatch-audit.lisp)
conservano conteggi e percorsi mancanti.

| File | Espressioni | Rami nativi |
|---|---:|---:|
| `package.lisp` | 1/1 | 0/0 |
| `types.lisp` | 40/40 | 8/8 |
| `build.lisp` | 24/24 | 2/2 |
| `claim.lisp` | 45/49 | 0/0 |

I quattro missing sono nel solo `otherwise` di `claim.lisp:31`, che rifiuta
uno status fuori dal dominio ftype del gate. Rimangono nei 114 elementi del
denominatore. Percorsi nativi 31–34: `(1 4 3 3 4 3)`,
`(1 1 4 3 3 4 3)`, `(2 1 4 3 3 4 3)`, `(3 1 4 3 3 4 3)`.
Il denominatore zero dei rami di `claim.lisp` è quello emesso da SBCL;
non equivale ad assenza di decisioni nel sorgente. Nessuna inferenza MC/DC,
nessuna copertura dei delegati C1 nel denominatore del dispatcher.

## Misura locale

Tre campagne separate, ciascuna con cinque repliche da 4096 cicli e
128 warmup: **20480 cicli misurati per campagna**, quindici campioni nel
[rapporto originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/data/benchmark/report.lisp).
Factory, risoluzione API e GC precedono il clock. Quattro chiamate per ciclo:
EMPTY ruota 1/2/3/0; INACTIVE conserva il cursore 2; ROUTE-CURRENT seleziona
quattro volte lo stesso collegamento IDLE di un CLAIMED stabile.
Quest'ultima include oracoli scalari di fase/identità: claim iniziale e drain
finale sono fuori clock, nessun begin, lease o pop nella misura.

| Replica | Tick EMPTY | Tick INACTIVE | Tick ROUTE-CURRENT | Heap per campagna |
|---|---:|---:|---:|---:|
| 0 | 5110 | 1505 | 2021 | 0 |
| 1 | 5896 | 1057 | 2307 | 0 |
| 2 | 6652 | 1226 | 2290 | 0 |
| 3 | 5518 | 1676 | 2167 | 0 |
| 4 | 7346 | 1377 | 2175 | 0 |

SBCL 2.6.9, ARM64, Apple M4, Darwin 27.0.0, safety 3, clock 1000000
unità/s. Ogni campione completa 4096 cicli, heap osservato zero e sink
esatto: 8435712 EMPTY, 8468480 INACTIVE, 8501248 ROUTE-CURRENT.
Il controllo positivo rileva 16777472 byte deliberati; i self-test
rilevano sink errati, tutti i ritorni difformi, clock sotto risoluzione,
CLI invalida e perdita di raw parziali o destinazioni preesistenti.

Il carico esterno e gli altri processi di verifica sono incontrollati.
Nessuna soglia temporale, taratura o conclusione sul throughput del motore.
Heap zero osservato non dimostra assenza universale di allocazioni e la
misura non comprende un nuovo claim con writer realmente accodato.

## Sviluppo, integrazione e limiti

Nessun tentativo formale sopra elencato è fallito. I primi due runner di
sviluppo dei test fallivano per dichiarazioni IGNORE nella macro fixture;
il terzo aveva debiti FI incompatibili con le fasi del routing C1. Il quarto
passa 13 prove; il quinto passa le 14 definitive. Tutti i log e snapshot
restano diagnostica di sviluppo, distinti dalla qualifica congelata.
Il self-test preliminare del sensore falliva nel caricamento di quella
prima fixture con warning; il secondo è passato. Non si promuovono errori
di sviluppo a prove superate. Gli intermedi FASL sono esclusi dai bundle
UTF-8 di sviluppo; native/HTML originali restano conservati.

Il commit `bfbf687929e1f28f67ddd1a21dbab5334b8e1a67` è stato integrato
con `06cc1354cd6843c40da0570e5314fef7cf68a667`, che aggiunge la suite
GET ACTIVE. Il merge `8df3608c63c85f9d72b5c22d8d0fce67020290e5`
conserva byte per byte quattro sorgenti dispatcher, test e sensore.
Changelog e indice documentale conservano entrambe le aggiunte.
Il controllo integrato passa **1176 prove nominate e due smoke**,
compilazione strict, 198 sorgenti senza violazioni lint e trace senza errori.
Dura 34,333722 secondi. Le 28 prove GET ACTIVE entrate nel merge spiegano
la differenza rispetto al set congelato; la copertura e i dieci spike non
vengono attribuiti retroattivamente al merge.

La conservazione riusa i writer C4 verificati, con namespace nuovo e manifesto
specifico delle tre API e dei quattro sorgenti. Le famiglie generiche legacy
restano dichiarate e non ampliano lo scope. L'adattatore di pubblicazione
supera una fixture positiva e cinque negative, per sorgenti runtime mancanti
e impronta alterata, senza pubblicare quei dati di prova.

Non sono realizzati loop server, avvio/arresto fisico, park/wake, sensori
reali, admission, esecuzione dei payload o coordinamento dell'Archivio.
I protocolli C1 e durevoli restano invariati; REQ-THR-001 e i gate del
motore completo rimangono aperti.

## Ultima integrazione e chiusura

La [pubblicazione originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/publication/report.lisp)
`4000917815-command-71100-0` termina OK, STABLE, exit 0 dopo 211,37401
secondi, verificando fonti e copie senza modificarle. Nel frattempo main
ha acquisito `e599703a6d840f3788e642042facf3ea71d8d32a`, con namespace
I/O e pubblicazione CONTROL. Il merge finale
`f26a2b2b0220c061e80d93f5e3e2d577b98e7463` mantiene byte per byte i
quattro sorgenti dispatch, i quattordici test e il sensore. ASDF conserva
entrambi i nuovi insiemi di moduli; changelog e indice non perdono aggiunte.

Il [controllo dell'ultima integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/final-integrated-build/report.lisp)
`4000918109-command-76942-0` passa compilazione strict, 1176 prove nominate
e due smoke, lint su 202 sorgenti senza violazioni e trace senza errori:
OK, STABLE, exit 0, 33,961707 secondi. Verifica compatibilità di caricamento
e fixture con il backend esteso, senza qualificare le nuove API CONTROL
o rinomina. Copertura e misure rimangono quelle del set congelato dichiarato.

Il [controllo finale di link e conservazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-dispatch/processes/final-verification/report.lisp)
`4000918109-command-76941-0` termina OK, STABLE, exit 0: 155,55193 secondi,
394 Markdown, 2857 link senza rotture, 95 cataloghi, 21743 file conservati e
667652832 byte. I conteggi precedono la copia di questi tre processi e
l'aggiunta di questa sezione. La chiusura conserva report/conservazioni
originali, fonti finali di questo incremento e versione conclusiva del
documento in bundle nuovi; nessun raw precedente viene sostituito.
