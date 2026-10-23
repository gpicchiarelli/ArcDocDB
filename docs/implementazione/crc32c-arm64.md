# CRC32C ARM64 in Common Lisp/SBCL

[ADR-0059](../adr/0059-crc32c-arm64-sbcl.md),
[metodo preregistrato](crc32c-arm64-metodo.md). Il formato del checksum e
le verifiche di record, cache, WAL e pagine restano invariati.
Il successivo [controllo delle piattaforme](crc32c-piattaforme.md) isola
anche caricamento e dipendenze prima della scelta runtime.

## Implementazione

`crc32c` delega al kernel scelto prima dell'avvio dei worker.
`backend-crc32c` espone `:lisp` oppure `:arm64-crc32c`. Il fallback
slicing-by-8 mantiene anche i loader standalone delle fondazioni.
Il backend hardware viene attivato soltanto su macOS ARM64/SBCL 2.6.9,
dopo la conferma OS del CRC32C e della disponibilità NEON. Il rilevamento
OS è nel modulo I/O; nessuna syscall, allocazione o scrittura condivisa
viene aggiunta al GET per scegliere il backend.

I VOP sono scritti in Lisp e operano su registri interi; due istruzioni
CRC32CX consumano i 16 B caricati dalle API SB-SIMD. Queste conservano i
controlli sugli indici a safety 3. La coda usa `aref` e CRC32CB. Nessun
checksum in librerie foreign, puntatore conservato, pinning o GC disabilitato.
Il disassembler locale mostra gli opcode come byte; i due encoding
Castagnoli sono `#x9ac05c00` e `#x1ac05000`, prima dei campi registro.

## Risultati locali

Apple M4, 16 GiB, SBCL 2.6.9, safety 3, cinque repliche per cella.
La prima campagna GET è conservata integralmente: il carico host oltre
18 su dieci CPU logiche ne rende molto variabile il wall time. La seconda
campagna conserva la stessa matrice, aggiungendo tempo CPU diagnostico;
non sostituisce o elimina i risultati precedenti. Nessun intervallo di
confidenza o P99 è dedotto dalle mediane.

Seconda campagna: microsecondi per GET, mediana wall time, CSN 7.

| Valore | Cache hit, software | Cache hit, hardware | Segmento caldo, hardware |
|---:|---:|---:|---:|
| 16 B | 0,792 | 0,750 | 1,350 |
| 256 B | 1,129 | 0,777 | 1,375 |
| 4096 B | 6,758 | **1,684** | 2,359 |

Con CSN massimo u64: cache hit da 4096 B **1,683 µs**, segmento caldo
2,390 µs. Il guadagno attribuibile al CRC, a parità di driver throughput,
è circa **4,01×** per il cache hit da 4 KiB. Nel ciclo originale con
confronto di ogni byte dentro il timing: software 15,068 µs, hardware
9,886 µs. Il confronto 15 → 1,68 include anche l'esclusione dell'oracolo
dal tempo misurato e non rappresenta un'accelerazione di 9× del prodotto.

Il nuovo microbenchmark del CRC di prodotto su corpo da 4112 B misura
circa **0,748 µs**; quello dello spike compatto circa 0,73 µs. L'obiettivo
CRC 0,4–0,6 µs non è raggiunto. È raggiunto l'obiettivo di GET cache hit
da 4 KiB sotto 2 µs nel perimetro misurato. Il kernel srotolato a 64 B
misura circa 0,81 µs nello spike e non viene integrato.

Le due campagne GET hanno **720 finestre, 28,8 milioni di GET**, tutte
complete e con delta heap Lisp zero. La campagna separata dei byte ha
90 finestre complete, anch'esse con delta heap zero. Questo non dimostra
assenza di allocazione in ogni esecuzione o un limite alle pause GC/OS.
Il profilo CPU diagnostico separato raccoglie 259 campioni: CRC hardware
42,1% self; non viene usato come misura di throughput o latenza.

## Integrità e perimetro

Lo spike supera 6.624 casi per variante con oracolo bitwise e software,
offset, semi e incrementalità. I tre nuovi test di prodotto portano le
fondazioni a 31 test. Il benchmark GET esegue 72 finestre bounded prima
di ogni campagna, verifica ogni byte nel percorso `:exact`, e controlla
tutte le otto chiavi prima/dopo ogni finestra `:throughput`. La negativa
CLI conserva la finestra failed ed esce con 1. Le prove di corruzione del
prodotto rimangono distinte dal controllo negativo del driver.

Restano fuori server/rete, documenti freddi, working set oltre RAM,
cento milioni di chiavi, mutazioni concorrenti e P99. Nessuna proprietà
lock-free viene derivata dalla velocità: il contratto di concorrenza non
cambia. Altre piattaforme/versioni mantengono il software e richiedono
qualifica separata per attivare l'accelerazione.

## Letture C1 e decisioni

Due letture dell'autore, non una revisione indipendente:

- Dominio u32/u64, opcode Castagnoli, intervalli validati prima dei load,
  seed e finalizzazione, coda 0..15, vita utile GC e assenza di indirizzi
  conservati o boxing nel ciclo. L'assembler verifica opcode e registri
  prima di generare ogni istruzione.
- Selezione cold e fallback, ABI `sysctlbyname`, kernel immutato durante
  il servizio, loader standalone, binding privati del benchmark, guardie,
  comparabilità degli A/B, conservazione dei fallimenti e dei due driver.

Decisioni composte nuove: status OS/size/feature per il rilevamento,
versione/feature/NEON per la selezione. Il caso positivo è esercitato su
questo host; il software e i range sono verificati separatamente. Una
campagna MC/DC delle risposte OS sintetiche e la qualifica su altre
piattaforme restano distinte dai test locali e dal target prestazionale.

## Verifica conclusiva

`make check` completo è passato con exit 0 e sorgenti stabili: build e test
senza warning/style-warning, lint, tracciabilità (137 requisiti, 71 invarianti,
59 ADR), link, strumenti full text, controlli negativi e conservazione,
audit di 315 cataloghi, 11 spike e autotest CI. I normali messaggi compiler
NOTE non sono warning. Il primo tentativo globale si era fermato su uno
style warning preesistente in un test dei processi Unix: `ignore` dello
stream sostituito con `ignorable`, perché il cleanup lo usa. Nessun controllo
è stato disattivato; il fallimento e il sorgente precedente sono conservati.

[Catalogo conclusivo, sorgenti e dati grezzi](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-crc32c-arm64/catalogo.lisp).
L'archivio conserva i sorgenti di questa campagna. La successiva integrazione
e le relative verifiche sono nel [controllo delle piattaforme](crc32c-piattaforme.md).
