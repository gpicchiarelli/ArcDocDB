# Seconda lettura del verificatore CBOR con testate minime

Lettura statica locale completata il 9 ottobre 2026 dopo il congelamento dei tre file di test indipendenti. Non sono emersi difetti concreti nel nuovo diff. Questa lettura non costituisce approvazione umana né esito delle campagne: compilazione rigorosa, lint, esecuzione, copertura, mutazioni, misura dell'heap e verifica integrata sono ancora da acquisire.

Il revisore ha scritto il corpus corrente senza leggere il nuovo prodotto e ha contribuito in passato ai kernel CBOR e UTF-8 già integrati. La seconda lettura riguarda la nuova export, il riuso del ciclo comune e la selezione del lettore minimo; non rappresenta una nuova lettura cieca dei componenti precedenti.

## Provenienza

Il corpus cieco comprende 22 test nominali, con oracoli freddi già congelati, aritmetica intera/razionale per le testate, un modello strutturale limitato, 768 confronti sulle testate iniziali, 512 alberi generati e 4096 casi fuzz preregistrati con seme `#x53434d31`. Le due attività concorrenti usano buffer e spazi privati, limiti di attesa 15/20 secondi e intervalli temporali locali; nessuna prova di core distinti o di accelerazione è dedotta. Non è stato aggiunto un supplemento dopo la lettura del prodotto.

| File di test congelato prima della lettura | Git blob |
| --- | --- |
| `tests/codec/cbor-minimal-scan-support.lisp` | `c2af64af4e5f8b5f669819fd56a00f416b3aaf0d` |
| `tests/codec/cbor-minimal-scan.lisp` | `1742189ff6845197ba76996c09c1097d59216fcb` |
| `tests/codec/cbor-minimal-scan-threads.lisp` | `56318b1632a7a0ae11f2987cdf0d4bec68e465cb` |

| Sorgente letto dopo quel congelamento | Git blob |
| --- | --- |
| `src/codec/cbor-package.lisp` | `9c9edc4775c24188cd38e4620da77b8bad349344` |
| `src/codec/cbor-scan.lisp` | `e3d7d77407046338d23e26eb0b8a2e8fdc3d699d` |
| `src/codec/cbor-scan-minimal.lisp` | `f1afe79c7a4d49abd6a6e5f6975dec830ef7b1f6` |

La lettura sintattica dei soli test come dati Common Lisp, con `*read-eval* NIL` e controllo EOF, ha contato 20/22/2 forme e 0/21/1 test. Non ha caricato o eseguito prodotto o test. Il lettore e i due log sono esterni al repository: `/tmp/cbor-minimal-scan-source-read.lisp`, `/tmp/cbor-minimal-scan-source-read-first.log` e `/tmp/cbor-minimal-scan-source-read-final.log`.

## Checklist C1

| # | Controllo | Riscontro statico e limite |
| --- | --- | --- |
| 1 | Requisiti e ADR | REQ-LIM-001/002 e REQ-AFF-004/008 sono collegati al controllo locale di struttura, UTF-8 e testate minime. ADR-0014/0048 non sono estesi a ordine delle mappe, duplicati o semantica dei tag. |
| 2 | Invarianti e casi | INV-A8/P6, preflight, reset, budget, precedenze e risultati hanno casi nominali indipendenti. La loro esecuzione resta da acquisire. |
| 3 | Condizioni tipizzate | Il lettore minimo precede contesto, nodi, profondità e payload. Le condizioni sintattiche e UTF-8 si propagano; `:cbor-trailing` precede la lettura della coda. Il confine FAULTED resta esterno al codec. |
| 4 | Cicli e ricorsione | Il ciclo comune resta limitato dallo span e lo svuotamento dalla capacità 102 dello spazio. Nessuna nuova ricorsione o seconda scansione è introdotta. |
| 5 | Allocazioni | Il nuovo percorso usa argomenti e stato locale, senza closure o materializzazione di float/u64. L'assenza di allocazione sul successo richiede misura. |
| 6 | Risultati verificati | La postcondizione condivisa verifica cursor/end, conteggio/picco e stato finale prima dei tre valori. I test richiedono esattamente tre valori. |
| 7 | Decisioni composte | D01, D02 e D03 della tabella dedicata sono preservate. Il selettore booleano è una decisione semplice; nessun ramo è escluso dal denominatore di copertura. |
| 8 | Proprietà dei dati | Buffer immutabile del chiamante, spazio esclusivo e nessun riferimento al buffer trattenuto. Il selettore T/NIL è locale alla chiamata, non un campo condiviso. |
| 9 | Integrazione | Ordine ASDF compatibile con dipendenze prodotto e oracoli congelati; suite dedicata aggiunta dopo quella strutturale. Build, trace, lint e full check restano da acquisire. |
| 10 | Standard del sorgente | FTYPE completi, safety 3, funzioni contenute e guardie significative nelle funzioni non banali. Le due API pubbliche sono deleghe sottili al ciclo comune. Nessuna promozione di stato C1 è dedotta. |
| 11 | Concorrenza | Nessuna scrittura globale o sincronizzazione nuova. Due worker con spazi e buffer privati sono previsti; REQ-CON-005 è coperto solo per la chiamabilità locale. Esito e sovrapposizione restano da misurare. |
| 12 | Durabilità e atomicità | Non applicabili a questo kernel senza I/O, WAL o pubblicazione di dati. Non si rivendicano garanzie del motore. |

Le tre decisioni composte sono: D01, avanzamento positivo del passo e cursor entro end; D02, nodi entro il limite e picco entro max-depth; D03, top e profondità a zero senza tag pendente. Le guardie false restano parte della copertura integrale; questa lettura non dimostra MC/DC.

Il wrapper generico conserva firma, valori di default e selezione NIL. Il wrapper minimo passa T al medesimo ciclo/preflight/reset/risultato. La validazione minima si applica solo alle testate effettivamente raggiunte: i payload restano opachi, mentre chiavi, valori e tag annidati sono visitati. La capacità minima dichiarata da un contenitore può determinare un errore di troncatura prima di raggiungere un figlio. Non risultano rilievi statici aperti; gli esiti dinamici saranno conservati separatamente secondo il [metodo preregistrato](cbor-minimo-struttura-metodo.md).
