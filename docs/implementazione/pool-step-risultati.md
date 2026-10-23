# Verifica del passo pool/Serie

La qualifica segue il [contratto](pool-step.md), il
[metodo preregistrato](pool-step-metodo.md) e la
[revisione indipendente C3](pool-step-revisione.md). Base congelata
`5be241d8f295e3c82df06e75c9b12e0bf75eb202`: sedici fonti e quattordici
helper copiati byte per byte; diciotto impronte della revisione coincidono
in checkout e clone. Originali nel
[catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/).

## Processi e prove

| Processo | Record originale | Esito |
|---|---|---|
| publisher-selftest | [4001073020-command-38578-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/publisher-selftest/report.lisp) | OK, STABLE, exit 0 |
| coverage-reader | [4001073020-command-38579-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/coverage-reader/report.lisp) | OK, STABLE, exit 0 |
| selftest | [4001073020-command-38582-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| coverage | [4001073032-command-39128-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| benchmark | [4001073141-command-45181-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| check-core congelato | [4001073020-command-38577-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/check-core/report.lisp) | OK, STABLE, exit 0 |
| Compilazione/test/lint/trace integrati | [4001073480-command-67324-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/integrated-build/report.lisp) | OK, STABLE, exit 0 |

Passano **16 nuove prove**, scheduler completo **110/110**. I contatori
inoltrano alle API reali e verificano un solo ingresso operativo: claim
IDLE, current CLAIMED o recycle RESCHEDULE. I cinque risultati distinguono
cursore, count e assenza di trasferimento; NIL per lifecycle fuori claim
non viene reinterpretato come osservazione di comando invariato.

Attivazione e ritiro precedono la nuova presa. CLAIMED reale da adozione,
presa o full rimane completabile anche con porta inattiva, ritiro pendente
o comandi incoerenti; nessun gate, ACK, begin, pop o end implicito.
Room conserva FIFO, distingue count 2 da cursore 0 e termina il passo senza
secondo claim. Full seleziona B, lascia A nel ring e permette poi current
senza altri trasferimenti. Soltanto il successivo passo IDLE applica il ritiro.

Una guard CAS realmente occupata distingue il ritorno BUSY del claim dalla
condizione `:ready-queue-busy` del ricircolo, conservando l'obbligo.
Owner su thread distinto e binding incoerente precedono getter e ingressi.
RUNNING/BATCH/FINISHING e FAULTED sono rifiutati con zero operazioni;
debiti, lease e prima causa rimangono intatti. Non si deduce overlap o
stress positivo dalla prova negativa dell'owner.

Routing fallito dopo full conserva lo scambio già avvenuto e la causa C1
originale EQ; dopo claim conserva l'ACK di attivazione già riuscito.
Le FI quiescenti del getter oltre il suo ftype sono rifiutate realmente dal
case T/NOTINLINE, anche con causa FAULTED preesistente. Sei valori fuori
dominio esercitano la difesa C3; non sono ritorni nominali C1. Nessun nuovo
handler, rollback, cleanup, campo di fault o secondo stato mutabile.

Il controllo completo congelato passa **1544 prove nominate del prodotto,
due smoke e quattro fixture del linter**, oltre a lint, trace, link,
self-test C4, conservazione e dieci spike. I 1550 marker `ok` includono le
fixture, che non vengono chiamate test del prodotto. Lint su 225 file senza
violazioni; trace su 121 requisiti, 65 invarianti, 13 scenari FI e 52 ADR,
senza errori. Il processo dura 435,846382 secondi con 928 sorgenti stabili.
Compilazione senza warning/style-warning; stderr conserva 1034758
caratteri di note del compilatore, equivalenti a 1034772 byte UTF-8.

L'archivio preesistente comprende 114 cataloghi, 3393 riferimenti, 40699 file
e 1072092045 byte conservati, prima del nuovo namespace step. I link del
congelamento sono 3075 su 451 file, nessuno rotto. Nessuno dei sette
processi formali nella tabella è fallito.

## Copertura

SB-COVER nativo e otto HTML originali concordano sull'intero package di
sette file: **227/235 espressioni (96,596%) e 10/10 rami nativi (100%)**,
senza esclusioni. Il nuovo `step.lisp` copre **51/51 espressioni**, nessun
missing. Il nativo originale occupa 2997008 byte. L'[audit della biblioteca](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/data/coverage-audit/coverage-audit.lisp)
e l'[audit del componente](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/data/step-coverage-audit/coverage-dispatch-audit.lisp)
conservano denominatori, confronto native/HTML e tutti i percorsi mancanti.

| File | Espressioni | Rami nativi | Missing |
|---|---:|---:|---:|
| `package.lisp` | 1/1 | 0/0 | 0 |
| `types.lisp` | 40/40 | 8/8 | 0 |
| `build.lisp` | 24/24 | 2/2 | 0 |
| `claim.lisp` | 45/49 | 0/0 | 4 |
| `recycle.lisp` | 45/49 | 0/0 | 4 |
| `begin.lisp` | 21/21 | 0/0 | 0 |
| `step.lisp` | 51/51 | 0/0 | 0 |

Restano gli otto missing dei due adapter precedenti, nel denominatore.
Claim: indici 31–34, percorsi `(1 4 3 3 4 3)`, `(1 1 4 3 3 4 3)`,
`(2 1 4 3 3 4 3)`, `(3 1 4 3 3 4 3)`. Recycle: indici 39–42,
percorsi `(1 4 2 3 3 4 6)`, `(1 1 4 2 3 3 4 6)`,
`(2 1 4 2 3 3 4 6)`, `(3 1 4 2 3 3 4 6)`.
Sono i finali otherwise eliminabili dal dominio del gate o dalla guardia
precedente; non vengono esclusi manualmente. Il finale inatteso del nuovo
passo viene invece esercitato realmente. Nessuna inferenza MC/DC e nessun
denominatore C1 ereditato; zero sonde native di ramo non equivale ad
assenza di decisioni nel sorgente.

## Misure locali

Il [rapporto originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/data/benchmark/report.lisp)
conserva due campagne di cinque repliche: **4096 cicli e 128 warmup** per
replica, 20480 cicli per campagna e quattro chiamate per ciclo. Tutti i
dieci campioni completano i cicli previsti con heap osservato zero e sink
esatto: 8435712 EMPTY, 8501248 CURRENT-INACTIVE.

| Replica | Tick EMPTY | Tick CURRENT-INACTIVE | Heap per campagna |
|---|---:|---:|---:|
| 0 | 9224 | 3529 | 0 |
| 1 | 9866 | 3680 | 0 |
| 2 | 8655 | 5305 | 0 |
| 3 | 8957 | 6781 | 0 |
| 4 | 8282 | 4345 | 0 |

SBCL 2.6.9, ARM64, Darwin 27.0.0, safety 3 e clock 1000000 unità/s.

Ogni ciclo esegue quattro passi e verifica tutti e cinque i risultati.
EMPTY ruota il cursore 1/2/3/0 su quattro shard vuoti con pool attivo.
CURRENT-INACTIVE seleziona quattro volte un CLAIMED reale con porta
inattiva, controllando identità, fase e cursore 1. Ogni replica usa una
fixture nuova. Factory, lookup API, claim iniziale, GC e drain pubblico
finale del solo payload sentinel restano fuori clock; nessun reset privato,
begin o lease attiva nel tratto misurato.

Il tempo comprende i delegati e gli oracoli, senza attribuzione al solo
adapter. Carico esterno incontrollato, nessuna soglia o taratura; heap zero
osservato non prova non allocazione universale. Non sono misurati RECYCLE,
CLOSING, contese, claim IDLE con lavoro reale o coordinamento concorrente.
INACTIVE/IDLE è solo nel self-test, con un oracolo sintetico RECYCLE.

I self-test verificano cinque valori difformi, sink errato, clock sotto
risoluzione, 16777472 byte deliberati rilevati, CLI, destinazioni
preesistenti e raw parziali. Il reader verifica scope e denominatori di
sette file; la pubblicazione una fixture positiva e otto negative, per
ogni sorgente runtime mancante e impronta alterata.

## Integrazione e conservazione

Il commit prodotto `c5550332911aaf1c2b7d36161d8997282a8b3974` contiene gli stessi
byte qualificati. Nessun sorgente execution, series o scheduler è cambiato.
La nuova politica C3 delega senza aggiungere controlli dopo il trasferimento.
Il bridge precedente chiuso rimane precondizione del caller, senza scansione
globale dei link o prova di quiescenza.

Il prodotto è integrato con `2cf3c38d297cf513df1d7c6312613099d79ad213`, che
aggiunge il recovery readonly del log multiserie. Il merge
`6ede7dbf6ab44660b7294047df45351275a71c48` conserva byte per byte i sette
sorgenti dispatch, i test, il sensore e le barriere delegate del freeze;
ASDF, indice e changelog conservano entrambe le aggiunte.

La verifica integrata passa compilazione strict, 1544 prove nominate e
due smoke, lint su 231 file e trace senza errori: 44,130150 secondi con
936 sorgenti stabili. Non qualifica le nuove API recovery-archive C1,
né attribuisce retroattivamente copertura o dieci spike al nuovo modulo.

Le evidenze di sviluppo rimangono separate: sedici nuove prove e scheduler
passati al primo tentativo; compilazione prodotto strict e lint/trace
superati; reader e sensore verificati. La prima variante del sensore,
compilata senza eseguire le campagne, riusava la fixture; la seconda
applica cinque fixture per campagna, come nel preregistrato, ed è quella
qualificata. Snapshot e raw precedenti rimangono conservati. Solo i FASL
intermedi sono esclusi dalle fonti UTF-8 di sviluppo.

I processi formali conservano argv, output, exit e impronte iniziali/finali.
Writer C4 e formati generici legacy sono riusati con manifesto specifico,
senza ampliare lo scope. Nessun protocollo durevole cambia. Admission dei
messaggi, payload, sensori, park/wake, avvio/arresto fisici e coordinamento
Archivio restano aperti; non si chiude alcun gate del motore completo.

La [pubblicazione originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/publication/report.lisp)
passa in 491,607474 secondi e la successiva
[verifica di link e archivio](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-pool-worker-step/processes/final-verification/report.lisp)
in 265,611008 secondi. Entrambi mantengono OK, STABLE ed exit 0, con 936
sorgenti stabili e stderr vuoto. La verifica controlla 454 file e 3102 link,
nessuno rotto; 116 cataloghi, 3429 riferimenti, 40772 file e 1078188211 byte
conservati. I conteggi precedono le copie di chiusura e i due link aggiunti
qui. Il manifesto di chiusura conserva questi due processi originali,
il documento finale e le fonti integrate; le prove precedenti non vengono
riscritte.
