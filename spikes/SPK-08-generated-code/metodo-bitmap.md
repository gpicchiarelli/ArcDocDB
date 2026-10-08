# SPK-08 — confronto delle bitmap

> **Proposta** — Estensione preregistrata prima della compilazione e delle
> misure del modulo `bitmap.lisp`. Nessuna modifica del motore o degli ADR.

## Domanda e correttezza

Quanto costa contare i bit comuni di due bitmap in array specializzati,
per byte oppure per parole u64? Entrambi i kernel restituiscono lo stesso
conteggio; non producono una bitmap e non rappresentano una query del database.
Il layout u64 viene preparato fuori dalle misure, esplicitamente little endian.
L'oracolo controlla ciascun bit separatamente, senza LOGAND/LOGCOUNT.

Array semplici, lunghezze uguali, da zero a 65.536 byte e multipli di otto;
word array equivalenti con al più 8192 elementi. Check di limiti, tipi,
lunghezze e input immutati; fixture zero, tutti uno, alternate e miste
deterministiche, anche con bit alto u64 acceso. Safety 3, warning e
style-warning fatali. Il CHECK deve riuscire prima del benchmark.

## Misure preregistrate

Tre dimensioni: 128, 8192 e 65.536 byte per bitmap. Tre dataset:
`:mixed`, `:zero`, `:ones`. Due kernel, cinque repliche con ordine alternato:
**90 campioni**. Ogni campione attraversa 16 MiB complessivi dei due input;
passaggi = 16 MiB / (2 × byte per bitmap), da 128 a 65.536. Otto passaggi
di warmup per kernel, fuori dalla misura. Nessuna scadenza usata come garanzia.
Il lavoro è finito e i parametri fissi precedono l'esecuzione.

Preparazione, packing, oracoli e report sono esclusi. Ogni risultato alimenta
un sink fixnum verificato rispetto al conteggio atteso × passaggi. Il tempo
monotono e il delta `get-bytes-consed` delimitano solo il ciclo del controller;
GC prima di ogni campione, nessun worker del carico. Si conserva il costo
di una chiamata vuota con lo stesso ciclo, senza sottrarlo dai campioni.
Un controllo positivo alloca un array e lo rende osservabile: un contatore
che non lo rileva fa fallire la prova. Il delta nullo non è una garanzia.

> **Proposta** — Revisione del controllo positivo dopo il primo tentativo
> di benchmark, fermato prima dei campioni: l'array da 64 KiB non supera il
> controllo del sensore. Prima della nuova esecuzione il payload del controllo
> è fissato a 1 MiB e gli errori includono il delta osservato. I kernel e
> la matrice restano gli stessi; il primo fallimento viene conservato.

Il disassemblato dei due kernel e del ciclo effettivo è registrato come
testo nel report. Si distingue un'istruzione SIMD usata per una singola
operazione LOGCOUNT da un ciclo che tratta più elementi simultaneamente.
Le diagnostiche del contrib registrano disponibilità e API, senza dedurre
supporto per operazioni non esportate o prestazioni su altre architetture.

## Riproduzione e limiti

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-08-generated-code/run-bitmap.lisp --check
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-08-generated-code/run-bitmap.lisp --bench
```

Runner e sorgenti sono distinti dai moduli impronte/SIMD già esistenti.
FASL per processo sotto `out/`. Output: una plist di esito; il registro
conserva comando, ambiente, sorgenti prima/dopo e stdout/stderr, inclusi
fallimenti. I record citati vengono conservati in `spikes/results/`.

Prima piattaforma locale: Apple M4 ARM64, SBCL 2.6.9; ambiente effettivo
nel report. Array piccoli, residenti nello heap, cache e carico esterno non
controllati. Nessuna misura x86-64, oltre RAM, I/O o concorrenza. Il packing
è escluso: un vantaggio del layout u64 vale solo se quel layout è già disponibile.
Nessuna promozione di codice sperimentale o ottimizzazione senza profiling
del motore, secondo INV-X1 e ADR-0012.
