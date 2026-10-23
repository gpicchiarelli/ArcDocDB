# Verifica della presa governata dal pool

La qualifica C3 segue [contratto](pool-worker-claim.md),
[metodo preregistrato](pool-worker-claim-metodo.md) e
[revisione indipendente](pool-worker-claim-revisione.md).
La copia congelata parte da `900fa93d9e14a252e6a2b5a009d19728b2de34af`
e conserva dieci file dell'incremento, con identità distinte dai documenti
finali aggiunti dopo. Gli originali sono nel
[catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/).

## Processi congelati

| Processo | Record | Esito |
|---|---|---|
| Compilazione strict e self-test C4 | [4000913361-command-73795-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| Copertura e suite scheduler | [4000913361-command-73794-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| Tre campagne del percorso normale | [4000913399-command-74843-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| Lettore native/HTML strict e self-test | [4000913465-command-76699-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/coverage-reader/report.lisp) | OK, STABLE, exit 0 |
| Controllo completo del repository | [4000913331-command-73208-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/check-core/report.lisp) | OK, STABLE, exit 0 |

La suite scheduler passa **53 prove nominate: 41 esistenti e 12 nuove**.
Verifica ready realmente popolata, crescita e ritiro su owner distinti,
assenza di polling quando inattivo, tutti gli stati non-IDLE, IDLE incoerente,
parole del pool invalide e conflitto CAS. Conferma che una richiesta tardiva
lascia completare il singolo claim già autorizzato e viene applicata al
successivo IDLE. Bridge e ricircolo pieno conservano le lease, il debito e
il routing del writer successivo. Le FI al confine sono quiescenti e dichiarate;
il comando tardivo è un interleaving iniettato, non una gara casuale osservata.

Gli strumenti compilano senza warning/style-warning. I self-test verificano
oracoli separati per tutti i quattro valori della nuova API, rilevano
16777472 byte di allocazione deliberata e sink errati, distinguono il clock
sotto risoluzione e conservano raw parziali e destinazioni preesistenti.
Il lettore originale viene riusato invariato con uno scope esplicito nuovo;
i suoi casi negativi precedono la misura del prodotto.

Il controllo completo passa **1109 prove nominate del prodotto, due smoke
test e quattro fixture del linter**, oltre a lint, tracciabilità, link,
self-test degli strumenti, conservazione e dieci spike. Il processo dura
237,501985 secondi. I 1115 record di output con prefisso `ok` comprendono
le quattro fixture del linter; non vengono chiamati 1115 test del prodotto.

## Copertura

Il dato nativo SB-COVER e l'HTML concordano: **44/44 espressioni e 4/4 rami,
100%**, su tutto `src/scheduler/pool-claim.lisp` e il package. Nessuna
esclusione, nessun percorso mancante. Il nuovo file conta 43/43 espressioni
e 4/4 rami; il package conta 1/1 espressioni e nessun ramo. Il confronto
esatto supera il gate C3 del 95%; non si deduce MC/DC.

Il nativo originale occupa 2205402 byte; l'indice e le due pagine HTML
rimangono originali. L'[inventario](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/development-manifest.lisp)
identifica fonti e bundle senza perdita. L'[audit della biblioteca](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/data/coverage-audit/coverage-audit.lisp)
e l'[audit del nuovo scope](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/data/claim-coverage-audit/coverage-claim-audit.lisp)
conservano gli stessi conteggi e percorsi, con metadati distinti.
I file C1 delegati non contribuiscono ai denominatori del componente nuovo.

## Misura locale

Tre campagne separate, ciascuna con cinque repliche da 4096 cicli e 128 cicli
di warmup per replica: **20480 cicli misurati per campagna**, quindici campioni
totali nel [rapporto del sensore](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/data/benchmark/report.lisp).
Factory, risoluzione delle API e GC completa precedono il clock.

EMPTY esegue quattro prese su quattro shard vuoti, verificando rotazione
1/2/3/0 e azione invariata. INACTIVE esegue quattro prese conservando il
cursore 2. SWITCH esegue sei prese: ritiro, conferma ripetuta, attivazione
e quattro EMPTY complessivi con rotazione 1/2/3/0. Due generazioni monotone
per ciclo, nessun reset. La fixture SWITCH serializza owner e coordinatore
e pubblica richieste private soltanto dopo la conferma precedente; non
qualifica il coordinatore concorrente.

| Replica | Tick EMPTY | Tick INACTIVE | Tick SWITCH | Heap per ciascuna campagna |
|---|---:|---:|---:|---:|
| 0 | 4394 | 892 | 5328 | 0 |
| 1 | 4504 | 912 | 5355 | 0 |
| 2 | 4476 | 899 | 5317 | 0 |
| 3 | 4403 | 1069 | 5345 | 0 |
| 4 | 4433 | 901 | 5300 | 0 |

SBCL 2.6.9, ARM64, Apple M4, Darwin 27.0.0, safety 3 e clock di 1000000
unità al secondo. Tutti i campioni completano 4096 cicli, con heap osservato
zero e sink esatto: 8435712 EMPTY, 8468480 INACTIVE, 8574976 SWITCH.
Il carico esterno, compresi gli altri processi di verifica, è incontrollato.
I tick non definiscono una soglia, taratura o conclusione sul throughput.
Zero heap osservato non dimostra assenza universale di allocazioni.

## Conservazione e limiti

Non ci sono tentativi formali falliti nei cinque processi congelati elencati.
Il primo runner di sviluppo dei test falliva nella configurazione relativa
della cache prima della compilazione; runner e output restano diagnostica
di sviluppo, senza promozione a prova superata. Le versioni dei test e gli
altri raw preliminari restano distinti dagli originali congelati.

La conservazione riusa i writer C4 già verificati e dichiara esplicitamente
le famiglie generiche dei manifesti. Il manifesto del componente identifica
API e sorgenti claim; i formati legacy non ampliano lo scope di prodotto.
Solo gli intermedi FASL sono esclusi dalle fonti di sviluppo UTF-8.

Il gate qualifica la nuova presa logica. Non modifica sorgenti C1, payload,
lease o protocolli durevoli; non realizza dispatcher completo, avvio, park/wake,
sensori, coordinamento Archivio, admission dei messaggi o shutdown fisico.
L'ACK conservato se un successivo claim fallisce è verificato staticamente
nell'ordine del codice, senza FI dedicata a quel preciso caso nei dodici test.
REQ-THR-001 e QA-12/19 restano aperti a livello del motore completo.

## Integrazione su main

Il commit `3751494703a848cd911cc1c13c11f0692bef4a38` è stato integrato con
`061e638200f0d97fc2443c7dec38d4362ef274e1`, contenente la preparazione del
checkpoint CONTROL. Il merge `e1ad69b1bae70fa8a2a0def075024206ff20391c`
conserva byte per byte gate, package, dodici test e sensore della qualifica.
ASDF integra i nuovi moduli, l'indice documentale e il changelog mantengono
entrambe le aggiunte.

Il [controllo integrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/integrated-build/report.lisp)
`4000913736-command-84415-0` passa compilazione strict, 1109 prove nominate
e due smoke, lint e tracciabilità: OK, STABLE, exit 0. Non si attribuiscono
retroattivamente al merge la copertura, il benchmark o i dieci spike della
copia congelata. Le fonti finali vengono conservate separatamente.

## Chiusura della conservazione

La [pubblicazione delle copie](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/publication/report.lisp)
`4000913849-command-86077-0` termina OK, STABLE, exit 0, dopo le verifiche
degli originali e delle copie. Il [controllo finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-pool-worker-claim/processes/final-verification/report.lisp)
`4000914088-command-91880-0` passa link e conservazione: OK, STABLE, exit 0,
152,397584 secondi, 376 file Markdown e 2786 link senza rotture; 86 cataloghi,
18938 file conservati e 542334642 byte. Questi conteggi precedono l'aggiunta
delle copie del processo stesso. Un nuovo manifesto conserva questi due
record e la versione conclusiva di questo documento, senza sostituire
raw o manifesti precedenti.
