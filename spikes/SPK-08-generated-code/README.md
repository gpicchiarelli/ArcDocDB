# SPK-08 — Impronte e codice generato

> **Proposta** — Valutazione locale in Common Lisp/SBCL, `safety 3`.
> Le varianti sono esperimenti: nessuna è introdotta nell'indice del motore.

## Domanda e metodo

Quale codice genera SBCL per confrontare 16 ctrl byte con un'impronta a
7 bit, e quale costo resta dopo i controlli dei range? L'esperimento separa
il confronto scalare, due parole u64 con SWAR e il backend SIMD locale.
Ogni risultato è una maschera esatta: un bit per posizione, senza falsi
positivi dovuti al prestito fra byte. I ctrl empty/deleted sono dati del
confronto; lo spike non implementa probing, inserimento o seqlock.

Metodi registrati prima dei controlli e delle misure:

- [Scalar e SWAR](metodo-impronte.md), con oracolo scalare e mutante borrow.
- [SIMD](metodo-simd.md), NEON su ARM64 e ramo SSE2 su x86-64.

I dataset delle due campagne sono distinti e dichiarati nei metodi.
I confronti di tempo valgono soltanto fra metodi sullo stesso dataset e
nella stessa campagna. Un vantaggio sul singolo kernel non è un vantaggio
di throughput per il database.

## Riproduzione e registrazione

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --check SPK-08
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-08
```

`run.lisp` compila in nuovi FASL per processo; warning/style-warning e
valori warnings/failure di `compile-file` sono fatali. L'harness conserva
comando, ambiente, revisione, sorgenti prima/dopo, risultati decodificati,
stdout/stderr originali e fallimenti. I report restano in `spikes/out/`;
quelli citati sono conservati in `spikes/results/`.

Il solo modulo nativo può essere eseguito con `run.lisp --simd-check`
o `--simd-bench`, usando `tools/record-command.lisp`. Contrib o backend
assente produce `:unsupported`, senza fingere una verifica SIMD riuscita.

## Ambiente e limiti

Prima piattaforma: Apple M4, macOS ARM64, SBCL 2.6.9, 16 GiB RAM.
Le misure sono eseguite in serie, con carico esterno non controllato.
Nessuna misura su Linux x86-64, dati oltre RAM, accessi concorrenti,
directory dell'indice, seqlock, durabilità o frontiera dei commit.
Il gate SIMD delle due architetture resta aperto fino a verifiche reali.

## Primo controllo locale

Il kernel NEON supera 589.824 confronti: tutte le 65.536 maschere e
128 × 256 × 16 casi di query/ctrl/posizione. Superati anche 16 casi
di input immutato e 4 rifiuti dei parametri. Il disassemblato conservato
mostra load e confronto SIMD.
Il [record iniziale](../results/2026-10-08-avanzamento/native-simd-check-initial.lisp)
conserva ambiente, sorgenti e output originale.

## Campagna integrata e benchmark

Il CHECK scalar/SWAR passa 3.035.203 gruppi, 12.140.812 confronti,
77 controlli negativi e 28 witness del mutante. Il
[CHECK integrato](../results/2026-10-08-avanzamento/integrated-check.lisp)
legge anche il risultato SIMD senza caricare i package dei moduli.

Il [benchmark](../results/2026-10-08-avanzamento/spk08-benchmark.lisp)
conclude 70 campioni, cinque repliche/cella, con zero byte consed osservati
nei cicli misurati. Mediane NEON: 2,164 ns/gruppo sul misto, 2,168 su tutti
hit e 2,165 sui byte speciali senza hit. SWAR su u64 già preparati misura
4,745/4,791 ns/gruppo nei propri dataset; packing incluso: 17,319/17,288.
Le matrici SWAR e NEON usano dati diversi: questi numeri non confrontano
le due tecniche fra loro. I risultati completi, la dispersione, il sensore
di allocazione e la raccomandazione sono nel
[resoconto](../../docs/valutazione/risultati-SPK-07-08-2026-10-08.md).

Raccomandazione: misurare tutte le varianti nello stesso layout dell'indice,
con query variabili e accessi concorrenti, prima di scegliere un kernel.
