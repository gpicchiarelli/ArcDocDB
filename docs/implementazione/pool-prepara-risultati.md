# Preparazione del tratto pool/Serie: risultati locali

Incremento C3/C4 sulla base `7f1cc54477483039bd98bd8c3f6508416f5c0ced`;
[contratto](pool-prepara.md), [metodo preregistrato](pool-prepara-metodo.md)
e [rilettura con identità dei file](pool-prepara-revisione.md).
Implementazione `fa2a483778a9a56ddcb2f12c7700e3f16ff489cc`.
La qualifica usa 18 file congelati; nessuna modifica ai sorgenti C1
appartiene a questo incremento. Sono aggiunti 17 test, 129 nel package scheduler.

## Processi originali

Tutti i processi sotto sono OK/STABLE/exit 0. I riferimenti puntano alle
copie originali, compresi conservazione e payload gzip, senza promozione degli esiti.

| Processo | Wall s | Sorgenti | Esito osservato |
|---|---:|---:|---|
| [Sviluppo 01](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/development-01/report.lisp) | 27,950115 | 972 | 127 test scheduler; 15 nuovi |
| [Sensore in sviluppo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/sensor-development/report.lisp) | 25,095753 | 973 | Self-test positivo, sette oracoli negativi e controlli heap/sink/clock |
| [Reader copertura](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/reader-development/report.lisp) | 1,121031 | 973 | Self-test indipendente su otto identità, native/HTML e rifiuti |
| [Sviluppo 02](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/development-02/report.lisp) | 23,054720 | 973 | 129 test scheduler; 17 nuovi, incluso errore dopo presa e ACK |
| [Controllo completo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/check-core/report.lisp) | 300,887805 | 975 | 1.668 test nominati, 2 smoke, 4 fixture lint, tutti i 10 spike |
| [Copertura](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/coverage/report.lisp) | 30,474354 | 975 | 129 test scheduler, 8 file, gate C3 superato |
| [Misure](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/benchmark/report.lisp) | 38,320366 | 975 | 10 campioni completi, heap osservato zero |
| [Build integrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/integrated/report.lisp) | 46,588497 | 983 | 1.722 test nominati e 2 smoke; lint e tracciabilità senza errori |

La prima versione dei test è conservata per intero e confrontata con il Git
blob del suo record. La seconda aggiunge il drenaggio finale della fixture
inattiva e due scenari dopo il trasferimento riuscito, senza cambiare il
prodotto. Il sensore e il reader non sono stati modificati dopo i rispettivi
self-test. Nessun processo fallito è stato scartato: gli otto sono passati.

Compilazione stretta senza warning/style-warning. Il controllo completo e la
build integrata conservano note del compilatore in stderr: rispettivamente
1.248.815 e 1.379.752 byte UTF-8; non sono presentati come stderr vuoti.
Gli altri sei processi hanno stderr vuoto.

Il controllo completo include link, tracciabilità, fixture degli strumenti e
archivio; la sua fotografia precedente alla nuova pubblicazione conta 123
cataloghi, 3.565 riferimenti, 42.702 file e 1.138.547.016 byte. Tutti i file
originali della campagna dei 10 spike sono conservati separatamente.

## Copertura senza esclusioni

[Audit specifico](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/data/coverage/coverage-dispatch-audit.lisp):
**281/289 forme, 97,231834%; 14/14 rami nativi**. Intero `src/dispatch/`,
nessuna esclusione; non viene inferita MC/DC.

| File | Forme | Rami |
|---|---:|---:|
| package | 1/1 | 0/0 |
| types | 40/40 | 8/8 |
| build | 24/24 | 2/2 |
| claim | 45/49 | 0/0 |
| recycle | 45/49 | 0/0 |
| begin | 21/21 | 0/0 |
| step | 51/51 | 0/0 |
| start | **54/54** | **4/4** |

Le otto forme mancanti sono quelle preesistenti, conservate nel denominatore:
claim, indici nativi 31–34, path `(1 4 3 3 4 3)` e prefissi 1/2/3;
recycle, indici 39–42, path `(1 4 2 3 3 4 6)` e prefissi 1/2/3.
L'audit riporta tutti i path esatti, senza attribuirli a rami nuovi.
Il nativo originale di 3.217.144 byte, nove file HTML e i due audit sono
conservati come testo UTF-8 lossless nei bundle di sviluppo. Solo i FASL
sono intermedi esclusi. Nessun bit di copertura è riscritto.

## Allocazione e tempi grezzi

[Rapporto originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/data/benchmark/report.lisp).
SBCL 2.6.9 ARM64, Darwin 27, safety 3, clock 1.000.000 tick/s.
Cinque fixture fresche per campagna, 4096 cicli e 128 warmup per replica,
quattro chiamate alla nuova API per ciclo. I controlli scalari restano nel clock.

| Campagna | Tick delle cinque repliche | Heap byte | Sink per replica |
|---|---|---:|---:|
| EMPTY | 7507 / 7070 / 8177 / 7960 / 7980 | 0 in tutte | 8435712 |
| ACTIVE completo | 33711 / 36596 / 33516 / 76109 / 36643 | 0 in tutte | 8501248 |

40.960 cicli misurati e 163.840 preparazioni totali; ACTIVE elabora 81.920
payload sentinel nei soli campioni, con enqueue, pubblicazione ready,
preparazione, pop, ACK e end inclusi. Factory, lookup API, GC e chiusura del
backend sono esclusi. Tutti i campioni completano 4096 iterazioni.
Il controllo positivo rileva 16.777.472 byte; sink errato, clock zero,
CLI, destinazione esistente e raw parziale sono verificati dal self-test.

Il picco di 76109 tick è conservato. Le campagne sono seriali nel loro
processo, mentre altre verifiche locali possono essere in esecuzione:
carico esterno non controllato. Non si isola il costo dell'adapter e non si
confrontano questi due percorsi diversi come speedup o regressione.
Il contatore zero non è una prova assoluta di non allocazione per ogni ingresso.
Current/recycle, rifiuti e coordinatore concorrente non sono misurati qui.

## Integrazione e confini

È stato integrato il parent `b2536f616f34f297aec7ba67b77096cd556271cc`,
qualifica del recovery Archivio, con merge
`680f675237585e9d99a91a440c0f675817c892ea`. I 17 file frozen diversi da ASDF
restano identici; ASDF comprende anche la suite Archivio aggiunta dal parent.
Il controllo integrato esegue l'intera suite: 238 file lint/0 violazioni;
122 requisiti, 65 invarianti, 13 FI, 52 ADR/0 errori.

Il [manifesto](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/manifesto.lisp)
e il [catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/catalogo.lisp)
collegano sorgenti finali, tutte le copie frozen con suffisso `.txt`, processi
e sviluppo. I writer C4 verificati sono riusati invariati; le loro famiglie
generiche sono dichiarate e non ampliano lo scope della qualifica.

Nessun nuovo test di concorrenza positiva, loop server, applicazione payload
del database o I/O durevole è qualificato da questa campagna. CLOSING e
guasti terminali restano responsabilità esplicite del caller e dell'Archivio.

## Controllo finale e conservazione conclusiva

La [pubblicazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/publication/report.lisp)
è OK/STABLE/exit 0, 295,396073 s, 984 sorgenti e stderr vuoto.
Sono preservati tutti i 49 file UTF-8 dello sviluppo: un controllo aggiuntivo
confronta i byte originali con il testo estratto dai bundle, inclusi i nove
HTML e il nativo. I 18 file dei primi otto processi sono inoltre confrontati
byte per byte con gli originali; nessun descriptor viene riscritto.

Dopo questa pubblicazione è stato integrato il componente CLOSED, parent
`31c3776ff8304d04aed314f60c2ad66435b8654a`, con merge
`81c0e57dc9a9b79e27967832fbc524e9109c2027`. L'unico conflitto era nel
changelog e sono conservate entrambe le voci. I 17 file frozen diversi da
ASDF rimangono identici; nessuna nuova misura è attribuita al codice CLOSED.

Il [controllo finale integrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/processes/final-verification/report.lisp)
esegue test, lint, tracciabilità, link ed evidenze: OK/STABLE/exit 0,
239,448811 s, 992 sorgenti. Superati 1.722 test nominati e 2 smoke;
245 file lint/0 violazioni; 122 requisiti/65 invarianti/13 FI/52 ADR/0 errori;
483 Markdown/3.256 link/0 rotti. Archivio: 127 cataloghi, 3.686 riferimenti,
42.949 file e 1.154.887.206 byte. Compilazione stretta senza avvisi;
le note in stderr sono conservate integralmente (1.401.121 byte UTF-8).
Questi conteggi precedono le copie di chiusura e i tre collegamenti aggiunti qui.

Il [manifesto conclusivo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara/chiusura-01.lisp)
conserva i due registri originali e le loro capacità di lettura compressa,
insieme alle sorgenti finali e agli script della chiusura. Non riscrive né
promuove gli esiti delle campagne precedenti.

## Integrazione finale degli strumenti C4

È stato poi integrato il collector del parent
`7c7255fad65336f7a7fff361ba569ad12fec1537`. Prodotto, test, ASDF e CI sono
identici al controllo finale già riportato; gli strumenti precedenti non
sono modificati. Makefile aggiunge il self-test del nuovo collector.
Il [record aggiuntivo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara-integrazione/processes/collector-self-test/report.lisp)
è OK/STABLE/exit 0, 159,863601 s, 996 sorgenti e stderr vuoto:
59 casi, 2.807 controlli, fixture conservate. Nessuna campagna del prodotto
viene promossa da questa verifica C4.
Il [supplemento chiuso](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-prepara-integrazione/archive-index.lisp)
conserva il record originale e le sorgenti finali selezionate tramite manifest
esplicito; la raccolta usa quattro worker e un checker indipendente.
Le copie dei documenti mantengono i byte originali con suffisso `.md.txt`,
così i collegamenti relativi restano riferiti alla documentazione originale.
