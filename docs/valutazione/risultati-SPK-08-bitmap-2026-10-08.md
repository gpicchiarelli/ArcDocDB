# SPK-08 — bitmap e codice generato, 2026-10-08

[Valutazione](README.md) · [Metodo preregistrato](../../spikes/SPK-08-generated-code/metodo-bitmap.md)

> **Proposta** — Estensione delle prove SPK-08: conteggio dei bit comuni
> in due bitmap con lo stesso contenuto, per byte oppure per parole u64.
> Nessuna ottimizzazione introdotta nel motore.

## Evidenze e correttezza

Apple M4 ARM64, SBCL 2.6.9, Darwin 27.0.0, `safety 3`, carico esterno
e cache non controllati. Ambiente, comando, revisione e sorgenti prima/dopo
sono nei [record originali](../../spikes/results/2026-10-08-bitmap/catalogo.lisp).
Il [benchmark finale](../../spikes/results/2026-10-08-bitmap/benchmark.lisp)
comprende CHECK, disassemblati e 90 campioni; le sorgenti risultano stabili.

I controlli confrontano i kernel con un oracolo bit per bit indipendente:
24 fixture, dimensioni 0/8/16/128/8192/65.536 byte, zero, tutti uno, misti,
alternate e bit alti. Superati 30 rifiuti di tipi, lunghezze e parametri.
I layout byte/u64 coincidono byte per byte in little endian e gli input
restano immutati, anche dopo i rifiuti e dopo ciascuna cella della matrice.
Compilazione e caricamento finali senza warning o style-warning.

Due tentativi falliti restano nel catalogo. Il primo falliva durante la
raccolta del disassemblato, perché `*print-readably*` impediva di stampare
gli oggetti interni del compilatore; il testo ora è raccolto con quella
variabile disattivata. Il secondo fermava il benchmark prima dei campioni:
l'array del controllo positivo da 64 KiB non superava il controllo del
contatore. Prima di ripetere la prova il payload è stato fissato a 1 MiB.
Il sensore finale osserva 1.048.592 byte consed per quel payload osservabile;
kernel, input e matrice non sono stati cambiati per scegliere una misura.

## Misure locali

Cinque repliche per dimensione/dataset/kernel; ordine alternato. Ogni
campione attraversa 16 MiB logici dei due input, con passaggi fissi da
128 a 65.536. Packing, oracoli, warmup, GC e report sono fuori dal ciclo.
Ogni conteggio alimenta un sink verificato. La chiamata vuota dello stesso
ciclo misura 262 tick per 65.536 passaggi, circa 4,00 ns/passaggio; il suo
costo è conservato e non sottratto dai tempi dei kernel.

Mediane delle cinque repliche; il rapporto è la mediana dei confronti
abbinati per replica. MiB/s indica byte logici dei due array elaborati;
dispersione e campioni grezzi sono nel
[confronto derivato](../../spikes/results/2026-10-08-bitmap/comparison.lisp).

| Byte per bitmap | Dataset | Per byte, MiB/s | Per u64, MiB/s | Rapporto u64/byte |
|---:|---|---:|---:|---:|
| 128 | misto | 1618,61 | 10012,52 | 6,17 |
| 128 | zero | 1644,40 | 10389,61 | 6,32 |
| 128 | tutti uno | 1650,85 | 10050,25 | 6,11 |
| 8192 | misto | 1891,25 | 14773,78 | 7,80 |
| 8192 | zero | 1897,53 | 15094,34 | 7,98 |
| 8192 | tutti uno | 1888,80 | 14773,78 | 7,81 |
| 65536 | misto | 1852,28 | 14571,95 | 7,87 |
| 65536 | zero | 1889,91 | 15122,87 | 8,01 |
| 65536 | tutti uno | 1890,36 | 14678,90 | 7,75 |

Tutti i 90 cicli registrano delta zero per `get-bytes-consed`, come la
baseline. È un'osservazione del sensore SBCL in questi campioni; il controllo
positivo non dimostra sensibilità a ogni singola allocazione piccola.
La durata minima dei campioni u64 supera 1 ms; la risoluzione del clock
registrata è un microsecondo. Non si deducono percentili o garanzie temporali.

## Codice generato e raccomandazione

Il kernel byte ha due caricamenti `LDRB`; quello u64 ha due caricamenti
di parole a 64 bit. Entrambi usano `AND` e la sequenza `FMOV`, `CNT .8B`,
`UADDLV` per il popcount del singolo elemento. Il secondo tratta otto byte
per iterazione e riduce il numero di caricamenti, conteggi e iterazioni.
Non si osserva un ciclo vettorizzato tra più parole o caricamenti `LDR Q`.
I controlli di tipo, range e overflow restano presenti; nel percorso normale
dei kernel gli u64 restano nei registri senza boxing in bignum visibile.

Le [diagnostiche del contrib](../../spikes/results/2026-10-08-bitmap/simd-availability.lisp)
confermano NEON disponibile nel SBCL installato; l'inventario non trova
un'API pubblica popcount in `SB-SIMD-NEON`. Questo non impedisce al compilatore
di usare internamente `CNT` per il `LOGCOUNT` scalare.

> **Proposta** — Per bitmap già rappresentate in parole u64, il kernel
> scalare tipizzato è un candidato da profilare nel motore prima di introdurre
> SIMD esplicito. Il vantaggio misurato esclude la conversione del layout.
> ADR-0012 e INV-X1 restano applicati: i microbenchmark non dimostrano che
> l'operazione sia un hot path del database.

Mancano x86-64, dataset oltre RAM, accessi concorrenti, cache del motore,
query e costi di conversione. Le prove sulle impronte e sulle loro maschere
restano nel [risultato distinto](risultati-SPK-07-08-2026-10-08.md).
