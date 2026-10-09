# Risultati della consegna locale dei writer

Campagna locale 2026-10-09, macOS ARM64/Apple M4, SBCL 2.6.9, safety 3.
Base delle prove mirate `85a4e05`; verifica integrata sulla base aggiornata
`4215fca`, che aggiunge la conservazione compatta delle evidenze senza
modificare il codice execution. Sorgenti e test coincidono byte per byte
tra workspace e copia verificata. Il carico esterno non è controllato.

## Correttezza e fault injection

Le 17 prove nuove, insieme alle 17 precedenti delle code, superano la
compilazione forzata senza warning/style-warning. L'oracolo a liste FIFO
verifica 7200 operazioni su nove configurazioni finite; controlla ogni count,
payload, span, quota ed obbligo di scheduling senza leggere il ring.

Le fixture esercitano entrambi gli ordini dell'accettazione rispetto al
termine vuoto, conclusione anticipata, backlog, quota cumulativa e nuova
ondata. Full/busy, gettoni vecchi/estranei, target invalidi e generazione
esaurita conservano le proprietà dichiarate. Sette stati incoerenti e i
tre helper senza guard/guard estranea sono provati tramite FI privata.

Quattro thread reali sono riusati su sei ondate, 36 messaggi e due Serie,
con producer ancora aperti durante il consumo. B termina tratti mentre A
mantiene guard e lease. Due ulteriori worker si passano otto tratti su
quattro ondate. Le attese appartengono alle fixture, con timeout e rilancio
degli errori. Non viene introdotto o qualificato un pool del prodotto.

## Copertura e mutazioni

| File execution | Espressioni raw | Esiti di ramo raw |
|---|---:|---:|
| package | 0/1 | 0/0 |
| queue | 142/184 | 24/34 |
| writer | 190/218 | 36/44 |
| handoff | 173/190 | 16/16 |
| Totale | 505/593 | 76/94 |

Le 17 espressioni non marcate del nuovo modulo comprendono dichiarazioni,
default e quattro forme del ramo otherwise difensivo; tutti i 16 esiti
strumentati sono marcati. L'[inventario](writer-handoff-decisioni.md#copertura-raw-osservata)
conserva anche le lacune legacy. Nessuna esclusione approvata o MC/DC completa.
Il ricalcolo indipendente dei vettori raw coincide con l'indice HTML.

La baseline di mutazione compila e supera tutti i 34 test execution.
Sedici mutanti compilano e sono rilevati: otto del protocollo di consegna,
otto delle primitive delegate e del refactor. Zero sopravvissuti, zero
compilation-failure, zero guasti prima dei test. Il punteggio riguarda
il set preregistrato, non tutti i possibili difetti.

## Allocazioni osservate

| Percorso preallocato | Campioni × cicli | Heap osservato | Sink per campione |
|---|---:|---:|---:|
| Capacity 1, quantum 2, termine vuoto | 5 × 4096 | 0 byte in ciascuno | 8.669.184 |
| Capacity 32, quantum 16, backlog e riaccodamento | 5 × 4096 | 0 byte in ciascuno | 23.246.848 |

Warmup di 128 cicli e GC fuori dal contatore. Fixture, parsing, compilazione
e report sono esclusi; controlli e risposte delle API sono inclusi.
Il controllo positivo rileva 16.777.472 byte su 16 MiB deliberatamente
allocati. Nessuna misura di speedup, throughput, P99 o garanzia universale
di assenza di allocazioni; errori e integrazione dello scheduler non misurati.

## Riproduzione ed evidenze

```sh
make test
sbcl --script tools/foundation-coverage.lisp --report spikes/out/handoff-coverage/ execution
sbcl --script tools/writer-handoff-mutation.lisp --self-test
sbcl --script tools/writer-handoff-mutation.lisp --run directory-nuova/
sbcl --script tools/writer-handoff-bench.lisp --self-test
sbcl --script tools/writer-handoff-bench.lisp --bench altra-directory-nuova/
make check
```

Per conservare provenance e output, usare `tools/record-command.lisp --`
prima del comando. Il [catalogo](../../spikes/results/2026-10-09-writer-handoff/catalogo.lisp)
comprende record dei processi, raw della copertura, log baseline/mutanti,
misure, self-test, tentativi falliti e sorgenti degli adattatori temporanei.
La [revisione](writer-handoff-revisione.md) conserva le due letture C1.
Il [contratto](writer-handoff.md) delimita l'obbligo locale: scheduling,
risvegli, shutdown e controller adattivo richiedono ancora integrazione.

La verifica integrata `make check` supera 203 test dei sei moduli più lo
smoke, linter (38 file, zero violazioni), tracciabilità (114 requisiti,
65 invarianti, 13 FI e 52 ADR), link, evidenze e dieci spike. Il record
[check integrato](../../spikes/results/2026-10-09-writer-handoff/check-integrato.lisp)
è `:ok`, exit 0 e sorgenti `:stable`; la
[campagna spike](../../spikes/results/2026-10-09-writer-handoff/spikes-integrati.lisp)
conserva tutti i figli nel solo master, compresso senza perdita, senza
duplicarne i report. Le aggiunte editoriali successive sono verificate
con link e cataloghi; codice e test restano quelli della verifica completa.


La successiva integrazione con `7f8ca93` conserva anche il nuovo codec UTF-8.
La [verifica finale su main](../../spikes/results/2026-10-09-writer-handoff-main/check-integrato.lisp)
passa con 220 test dei sette moduli più smoke (26 foundation, 17 codec,
34 execution, 44 storage, 18 I/O, 62 recovery, 19 WAL), zero avvisi,
40 file nel linter senza violazioni e la stessa tracciabilità. I dieci spike
sono conservati nel [master finale](../../spikes/results/2026-10-09-writer-handoff-main/spikes-integrati.lisp)
con payload compresso e hash verificati. Questo secondo
[catalogo](../../spikes/results/2026-10-09-writer-handoff-main/catalogo.lisp)
conserva il wrapper, il check completo e l’appendice di integrazione;
i raw della campagna mirata e della precedente verifica restano intatti.
