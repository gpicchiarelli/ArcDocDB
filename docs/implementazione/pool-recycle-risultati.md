# Verifica del ricircolo pool/Serie

La qualifica segue [contratto](pool-recycle.md),
[metodo preregistrato](pool-recycle-metodo.md) e
[revisione indipendente C3](pool-recycle-revisione.md).
Base congelata `a5715a1aa0b2571d650d1b794e9bb7b7324e951e`, quattordici
fonti e quattordici helper copiati byte per byte. Gli originali sono nel
[catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/).

## Processi e prove

| Processo | Record originale | Esito |
|---|---|---|
| Adattatore di pubblicazione e self-test | [4000984350-command-38941-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/publisher-selftest/report.lisp) | OK, STABLE, exit 0 |
| Reader native/HTML strict | [4000984374-command-39216-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/coverage-reader/report.lisp) | OK, STABLE, exit 0 |
| Sensore strict e self-test | [4000984374-command-39217-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| Copertura e scheduler completo | [4000984374-command-39218-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| Campagne ROOM/FULL | [4000984410-command-39982-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| Controllo completo congelato | [4000984350-command-38940-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/check-core/report.lisp) | OK, STABLE, exit 0 |
| Compilazione/test/lint/trace dopo integrazione | [4000984849-command-45285-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/integrated-build/report.lisp) | OK, STABLE, exit 0 |

Passano **13 nuove prove**, scheduler completo **80/80**. Verificano una
sola operazione ready, pubblicazione FIFO senza seconda presa o routing,
count distinto dal cursore, scambio full A→B e link B ancora IDLE. Il
bridge successivo è esplicito. Porta inattiva, ritiro pendente e parole
lifecycle incoerenti non impediscono il ricircolo; l'ACK avviene soltanto
alla successiva presa IDLE esplicita.

Guard ready realmente occupata, owner su thread distinto, binding fra
contesti diversi e fasi coerenti hanno preimage e prima causa conservate.
Un errore di routing dopo full viene verificato dopo lo scambio reale:
vecchio writer nel ring, nuovo riferimento/home in FAULTED, controller e
lease Serie intatti. Non si deduce rollback da un'eccezione. Una corruzione
ready dentro il tipo INDEX verifica la diagnosi C1 originale.

Il controllo completo passa **1277 prove nominate del prodotto, due smoke
e quattro fixture del linter**, oltre a lint, trace, link, self-test C4,
conservazione e dieci spike. I 1283 marker `ok` includono le quattro fixture,
che non vengono chiamate test del prodotto. Dura 258,237184 secondi, con
856 sorgenti stabili. Compilazione senza warning/style-warning; stderr
conserva 706755 caratteri di note del compilatore.

## Guardia di stato e sviluppo

Il probe iniziale, con delegato interposto che violava il proprio ftype,
restituiva davvero `(NIL :UNKNOWN 1)`: SBCL eliminava il ramo difensivo
assumendo valido il dominio dichiarato. L'esito originale resta conservato;
non viene trasformato in una prova di rifiuto.

La versione qualificata introduce una guardia separata con argomento T e
NOTINLINE. La tredicesima prova forza sei status fuori contratto e osserva
realmente `invariant-violation :pool-dispatcher-state`, prima di routing o
gate, con una sola chiamata interposta e preimage immutata. La prima causa
FAULTED preesistente rimane EQ. È una FI quiescente del confine, non un
ritorno nominale C1 né uno stress concorrente; le funzioni sono ripristinate.

I primi due tentativi di sviluppo dei test fallivano per parentesi e un
warning su tipo costante; i successivi passano le dodici prove preliminari
e le tredici definitive. I primi due tentativi del sensore fallivano prima
delle misure, per il test ancora in scrittura e un refuso del parametro
cleanup; il terzo passa. Snapshot e raw restano distinti dalla qualifica.
Nessuno dei sette processi formali sopra elencati è fallito.

Tre riferimenti Git locali con nomi invalidi sono stati conservati in una
quarantena fuori dai refs attivi, con bytes e manifest, prima del freeze.
Fetch e sincronizzazione sono poi riusciti. Non sono stati eliminati branch
validi da quella riparazione; la diagnostica resta sviluppo, non prova C3.

## Copertura

SB-COVER nativo e sei HTML originali concordano sull'intero package di
cinque file: **155/163 espressioni (95,092%) e 10/10 rami nativi (100%)**.
Il gate C3 del 95% è superato senza esclusioni manuali. Il nativo originale
occupa 2541351 byte. [Audit della biblioteca](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/data/coverage-audit/coverage-audit.lisp)
e [audit del ricircolo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/data/recycle-coverage-audit/coverage-dispatch-audit.lisp)
conservano conteggi e tutti gli otto percorsi mancanti.

| File | Espressioni | Rami nativi | Missing |
|---|---:|---:|---:|
| `package.lisp` | 1/1 | 0/0 | 0 |
| `types.lisp` | 40/40 | 8/8 | 0 |
| `build.lisp` | 24/24 | 2/2 | 0 |
| `claim.lisp` | 45/49 | 0/0 | 4 |
| `recycle.lisp` | 45/49 | 0/0 | 4 |

I missing sono gli `otherwise` finali dei due adapter: in claim, status fuori
dal ftype del gate; in recycle, status già validato dalla guardia separata.
Restano nel denominatore. Per recycle sono indici nativi 39–42, percorsi
`(1 4 2 3 3 4 6)`, `(1 1 4 2 3 3 4 6)`,
`(2 1 4 2 3 3 4 6)`, `(3 1 4 2 3 3 4 6)`; l'audit conserva anche i quattro
di claim. La guardia operativa viene esercitata sui ritorni validi e invalidi.
Zero rami nativi nei file case non equivale ad assenza di decisioni nel
sorgente. Nessuna inferenza MC/DC e nessun denominatore dei delegati C1.

## Misure locali

Due campagne, cinque repliche da 4096 cicli e 128 warmup ciascuna, fixture
nuova per replica: **20480 cicli per campagna**, dieci campioni completi nel
[rapporto originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/data/benchmark/report.lisp).
Writer prepopolati, queue/capacità preallocate e quantum uno. Factory,
risoluzione API, GC e drain pubblico bounded restano fuori clock.

ROOM comprende ricircolo pubblicato, presa esplicita, begin/pop/ack/end
execution. FULL alterna i due link dopo uno scambio e comprende lo stesso
tratto execution. I link restano IDLE: nessun begin del bridge o lease
Serie nel clock. Protocollo C1 e oracoli scalari sono parte del costo;
il tempo non viene attribuito al solo adattatore. Nessun reset privato.

| Replica | Tick ROOM | Tick FULL | Heap per campagna |
|---|---:|---:|---:|
| 0 | 4146 | 3393 | 0 |
| 1 | 4123 | 3392 | 0 |
| 2 | 4141 | 3384 | 0 |
| 3 | 4108 | 3370 | 0 |
| 4 | 4051 | 3330 | 0 |

SBCL 2.6.9, ARM64, Apple M4, Darwin 27.0.0, safety 3 e clock 1000000
unità/s. Ogni campione completa 4096 cicli, heap osservato zero e sink
esatto: 8513536 ROOM, 8562688 FULL. Il controllo positivo rileva 16777472
byte deliberati; i self-test rilevano risultati difformi, sink errato, clock
sotto risoluzione, CLI invalida e perdita di raw parziali o destinazioni
preesistenti. Non si qualifica il coordinatore concorrente o lo shutdown
dell'Archivio. Carico esterno incontrollato, nessuna soglia, taratura o
conclusione sul throughput; heap zero non prova non allocazione universale.

## Integrazione e conservazione

Il commit `7a9614151208e75cf518b2785d47c2f6cc420d8c` è stato integrato
con `2278ad5b6ab5b796d7fba4be497f344ead476ebe`, che estende CONTROL/recovery.
Il merge `a07a66e322c032a0374e354632a42d3cc6e2531e` conserva byte per byte
i cinque sorgenti dispatch, i test e il sensore congelati; ASDF, changelog
e indice mantengono entrambe le aggiunte.

Il controllo integrato passa compilazione strict, **1277 prove nominate e
due smoke**, lint su 210 file senza violazioni e trace senza errori:
37,932058 secondi, 861 sorgenti stabili. Non qualifica le nuove API recovery,
né attribuisce retroattivamente al merge copertura o dieci spike del freeze.

La conservazione riusa i writer C4 verificati, con namespace nuovo e manifesto
specifico delle quattro API del dispatcher esteso. I formati legacy generici
restano dichiarati e non ampliano lo scope. Il nuovo adattatore passa una
fixture positiva e sei negative, per ogni sorgente runtime mancante e
impronta alterata. Solo gli intermedi FASL sono esclusi dalle fonti di
sviluppo UTF-8; nativo, HTML e raw originali rimangono conservati.

La [pubblicazione originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/publication/report.lisp)
passa in 254,541876 secondi, con 862 sorgenti stabili. La successiva
[verifica di link e archivio](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-recycle/processes/final-verification/report.lisp)
passa in 168,966589 secondi: 409 file, 2933 link senza rotture, 100 cataloghi,
3174 riferimenti a evidenze, 25311 file e 731948502 byte conservati. Entrambi
i record mantengono OK, STABLE ed exit 0; questi conteggi precedono le copie
di chiusura e i due link aggiunti in questo paragrafo. Il manifesto di
chiusura conserva i due processi originali, il documento finale e le fonti
integrate; le evidenze precedenti non vengono riscritte. Il riepilogatore
diagnostico finale distingue caratteri e byte UTF-8 dello stderr: 706755 e
706765 nel controllo congelato; la versione precedente resta conservata.

Non sono realizzati loop server, applicazione dei payload, admission,
sensori reali, park/wake, avvio/arresto fisici o coordinamento dell'Archivio.
Protocolli C1 e durevoli restano invariati; i gate del motore completo restano aperti.
