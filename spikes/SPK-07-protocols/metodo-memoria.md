# SPK-07 — ordini di osservazione e barriere

> **Proposta** — modello Common Lisp registrato prima dell'esecuzione,
> `safety 3`. Riferimenti: REQ-IDX-003, REQ-AFF-017,
> [ADR-0032](../../docs/adr/0032-seqlock-a-64-bit.md).

## Domanda e metodo

Le due barriere writer e le due barriere reader del seqlock impediscono di
accettare campi appartenenti a una generazione diversa dal contatore letto?

Un writer, un reader, un contatore senza wrap e due campi. Si enumerano ordini
di otto eventi: quattro scritture **osservate dal reader**, quattro letture.
Le letture vedono l'ultima scrittura osservata di quella posizione; contatore
odd precede contatore even. Le barriere aggiungono archi di precedenza:
odd → campi → even; prima lettura del contatore → campi → seconda lettura.
I campi fra loro possono essere osservati in entrambi gli ordini.

Il modello ammette riordini quando si rimuove uno degli archi: quattro mutanti,
uno per ciascuna barriera. L'oracle confronta **entrambi i campi con la
generazione del contatore accettato**, non soltanto la coerenza fra campi.
Ogni mutante deve produrre un ordine testimone; il modello completo deve
avere zero violazioni. Il tetto è 8! ordini per configurazione, 5 configurazioni.
Il risultato conserva quantità e testimoni deterministici.

Il contratto delle barriere e il fatto che le forme nel corpo precedano la
barriera provengono dal [manuale SBCL 2.6.9, §13.7](https://www.sbcl.org/manual/#Barriers),
consultato il 2026-10-08. Il modello è una **astrazione** di quel contratto,
non un'implementazione del modello di memoria completo di ARM64 o x86-64.

## Controllo del compilatore e limiti

Due piccoli kernel sugli array u64, a `safety 3`, usano le primitive reali.
Il check confronta la risposta e conserva il disassemblato del runtime locale,
senza dedurre la correttezza hardware dalla sola presenza di istruzioni.

Restano esclusi: due reader/due slot, tearing, riuso della memoria, effetti del
GC, compilatori diversi, più osservatori e propagazione non atomica fra loro,
semantiche architetturali complete, test su Linux x86-64. Nessun throughput e
nessuna garanzia dipendente dalla durata dei thread. La copertura hardware
richiesta dal gate resta aperta.

## Risultato locale del 2026-10-08

Apple M4, macOS ARM64, SBCL 2.6.9. Comando registrato:

```bash
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- \
  sbcl --noinform --no-userinit --no-sysinit --script \
  spikes/SPK-07-protocols/run-module.lisp memoria
```

| Variante | Ordini completi | Letture accettate | Violazioni |
|---|---:|---:|---:|
| Quattro barriere | 280 | 8 | 0 |
| Senza barriera writer iniziale | 840 | 96 | 54 |
| Senza barriera writer finale | 840 | 96 | 54 |
| Senza barriera reader iniziale | 840 | 96 | 54 |
| Senza barriera reader finale | 840 | 96 | 54 |

Il [record strutturato](../results/2026-10-08/spk07-memoria-check.lisp)
conserva comando, hash dei sorgenti, ambiente, stdout originale e testimoni.
Le barriere dei kernel risultano compilate in `DMB ISHST` per le scritture e
`DMB ISHLD` per le letture nel disassemblato conservato. Il risultato non
dimostra la correttezza di un motore concorrente né l'assenza di riordini
esclusi da questo modello.
