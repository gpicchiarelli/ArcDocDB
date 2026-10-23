# Verifica dell'avvio pool/Serie

La qualifica segue il [contratto](pool-begin.md), il
[metodo preregistrato](pool-begin-metodo.md) e la
[revisione indipendente C3](pool-begin-revisione.md). Base congelata
`ad829a40f6ce72837b59982d2e4f83e8c9ca9f3e`: quindici fonti e quattordici
helper copiati byte per byte; diciassette impronte della revisione coincidono
in checkout e clone. Originali nel
[catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/).

## Processi e prove

| Processo | Record originale | Esito |
|---|---|---|
| Adattatore di pubblicazione e self-test | [4000996071-command-39309-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/publisher-selftest/report.lisp) | OK, STABLE, exit 0 |
| Reader native/HTML strict | [4000996086-command-40256-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/coverage-reader/report.lisp) | OK, STABLE, exit 0 |
| Sensore strict e self-test | [4000996086-command-40255-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/selftest/report.lisp) | OK, STABLE, exit 0 |
| Copertura e scheduler completo | [4000996086-command-40257-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/coverage/report.lisp) | OK, STABLE, exit 0 |
| Campagna ACTIVE | [4000996125-command-41073-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/benchmark/report.lisp) | OK, STABLE, exit 0 |
| Controllo completo congelato | [4000996069-command-39211-0](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/check-core/report.lisp) | OK, STABLE, exit 0 |

Passano **14 nuove prove** e lo scheduler completo **94/94**. Verificano
l'avvio reale con doppia lease e tutti e quattro i valori, un solo begin,
pop/ACK/fine espliciti, e lo scambio full A→B che avvia B mentre A rimane
nel ring. Un CLAIMED con porta inattiva, comandi incoerenti o ritiro pendente
rimane completabile senza gate, ACK lifecycle, claim o recycle impliciti.

La contesa reale del writer conserva CLAIMED, link IDLE e generazione;
la contesa della Serie e l'esaurimento della sua lease restituiscono
CLOSING e token da chiudere esplicitamente. Il limite della generazione
del bridge viene invece rifiutato prima di acquisire il writer.
Owner su thread distinto, binding incoerente e fasi non ammesse precedono
l'acquisizione; debito, lease e prima causa rimangono conservati.

Routing invalido, writer realmente non pronto ed errore iniettato durante
la seconda acquisizione verificano causa C1 originale EQ e capacità
residue. Un errore inatteso non restituisce i quattro valori e non promette
cleanup: il caller conserva i riferimenti e coordina l'Archivio. Il cleanup
delle sole fixture C4 non viene presentato come recovery del prodotto.

Il controllo completo passa **1420 prove nominate del prodotto, due smoke
e quattro fixture del linter**, oltre a lint, trace, link, self-test C4,
conservazione e dieci spike. I 1426 marker `ok` comprendono le fixture,
che non vengono chiamate test del prodotto. Lint su 213 file senza
violazioni; trace su 120 requisiti, 65 invarianti, 13 scenari FI e 52 ADR,
senza errori. Il processo dura 269,513968 secondi con 891 sorgenti stabili.
Compilazione senza warning/style-warning; stderr conserva 861956 caratteri
di note del compilatore, equivalenti a 861966 byte UTF-8.

Nessuno dei sei processi formali è fallito. Il controllo dell'archivio
preesistente vede 106 cataloghi, 3241 riferimenti, 37401 file e 961373366
byte conservati: questi conteggi precedono il nuovo namespace begin.

## Copertura

SB-COVER nativo e sette HTML originali concordano sull'intero package di
sei file: **176/184 espressioni (95,652%) e 10/10 rami nativi (100%)**,
senza esclusioni. Il nuovo ingresso copre 21/21 espressioni. Il nativo
originale occupa 2769774 byte. L'[audit della biblioteca](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/data/coverage-audit/coverage-audit.lisp)
e l'[audit del componente](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/data/begin-coverage-audit/coverage-dispatch-audit.lisp)
conservano denominatori, confronto native/HTML e tutti i missing.

| File | Espressioni | Rami nativi | Missing |
|---|---:|---:|---:|
| `package.lisp` | 1/1 | 0/0 | 0 |
| `types.lisp` | 40/40 | 8/8 | 0 |
| `build.lisp` | 24/24 | 2/2 | 0 |
| `claim.lisp` | 45/49 | 0/0 | 4 |
| `recycle.lisp` | 45/49 | 0/0 | 4 |
| `begin.lisp` | 21/21 | 0/0 | 0 |

Gli otto missing sono uguali, nei dati e nei percorsi, alla campagna di
ricircolo precedente: gli otherwise finali di claim e recycle, mantenuti
nel denominatore. Claim: indici 31–34, percorsi `(1 4 3 3 4 3)`,
`(1 1 4 3 3 4 3)`, `(2 1 4 3 3 4 3)`, `(3 1 4 3 3 4 3)`.
Recycle: indici 39–42, percorsi `(1 4 2 3 3 4 6)`,
`(1 1 4 2 3 3 4 6)`, `(2 1 4 2 3 3 4 6)`, `(3 1 4 2 3 3 4 6)`.
Nel primo caso il dominio dichiarato del gate consente la rimozione del
ramo; nel secondo la guardia precedente valida lo status. Nessuna nuova
lacuna in begin, nessuna inferenza MC/DC e nessun denominatore C1 ereditato.
Zero sonde native di ramo non equivale ad assenza di decisioni nel sorgente.

## Misura locale ACTIVE

Il [rapporto originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/data/benchmark/report.lisp)
conserva cinque repliche, ciascuna con una fixture nuova: **4096 cicli e
128 warmup**, 20480 cicli misurati complessivi. Un payload simbolico reale
rimane in coda. Nel clock: avvio del bridge con oracolo dei quattro valori,
token monotono e doppia lease, fine senza pop, ricircolo room C1 e presa C1
esplicita. Nessun reset privato. Factory, lookup API, GC e drain pubblico
finale con pop/ACK/end restano fuori clock.

| Replica | Tick | Cicli completati | Heap osservato | Sink |
|---|---:|---:|---:|---:|
| 0 | 4930 | 4096 | 0 | 8579072 |
| 1 | 4863 | 4096 | 0 | 8579072 |
| 2 | 4886 | 4096 | 0 | 8579072 |
| 3 | 4866 | 4096 | 0 | 8579072 |
| 4 | 4878 | 4096 | 0 | 8579072 |

SBCL 2.6.9, ARM64, Darwin 27.0.0, clock 1000000 unità/s e safety 3;
il protocollo C1 e gli oracoli scalari
sono parte del costo. Non si attribuisce il tempo al solo adapter. Carico
esterno incontrollato, nessuna soglia o taratura; heap zero osservato non
prova non allocazione universale. Non vengono misurati CLOSING, busy,
coordinamento concorrente o throughput del motore.

Il self-test rileva 16777472 byte deliberati, sink errato, quattro valori
difformi e clock sotto risoluzione; verifica anche l'oracolo CLOSING,
CLI, destinazioni preesistenti e raw parziali conservati. Il reader C4
verifica sei file e denominatori/missing inattesi. La pubblicazione verifica
una fixture positiva e sette negative: ogni sorgente runtime mancante e
un'impronta alterata. Nessun risultato fuori contratto viene attribuito a
un ritorno nominale C1.

## Integrazione e conservazione

Il commit del prodotto `5b3673f407777ebeeefa7caa6320f387a14c85db`
contiene gli stessi byte qualificati. Il nuovo ingresso inoltra direttamente
i tre valori del bridge: nessuna guardia C3 dopo acquisizione separa il
token dal caller. Non cambia alcun sorgente C1.

Le evidenze preliminari rimangono separate: quattordici prove e scheduler
passati al primo tentativo; sensore con due self-test di sviluppo passati
(il secondo con cache privata), reader passato e compilazione strict del
prodotto senza avvisi. Solo i FASL intermedi sono esclusi dai bundle.
I processi formali mantengono argv, output originali, exit e impronte,
con fonti stabili. Writer C4 e formati generici legacy sono riusati senza
ampliare lo scope del nuovo manifesto specifico.

La [pubblicazione originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/publication/report.lisp)
passa in 306,647160 secondi e la successiva
[verifica di link e archivio](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-pool-worker-begin/processes/final-verification/report.lisp)
in 221,384083 secondi. Entrambi i processi mantengono OK, STABLE ed exit 0,
892 sorgenti stabili e stderr vuoto. La verifica controlla 431 file e 3007
link, nessuno rotto; 107 cataloghi, 3252 riferimenti, 37444 file e 965767686
byte conservati. I conteggi precedono le copie di chiusura e i due link
aggiunti in questo paragrafo. Il manifesto di chiusura conserva i due
processi originali, il documento finale e le fonti; le prove precedenti
non vengono riscritte.

Non sono realizzati loop server, applicazione dei payload, admission,
sensori reali, park/wake, avvio/arresto fisico o coordinamento dell'Archivio.
Protocolli durevoli e gate del motore completo restano aperti.
