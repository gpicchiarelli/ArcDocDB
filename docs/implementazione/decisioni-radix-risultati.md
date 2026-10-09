# Ordinamento misurato e letture concorrenti delle decisioni

> **Proposta misurata, 2026-10-09** — il recovery usa LSD radix stabile da
> 1.024 ID16 per decisione e da 256 DECISION fisiche; sotto le rispettive
> soglie conserva merge bottom-up. Le due scelte precedono la coalescenza
> e non cambiano API, formato persistente o classificazione della corruzione.

Il [metodo registrato](decisioni-radix-metodo.md) richiede una mediana radix
al massimo pari al 90% di merge per ogni pattern e cardinalità misurata
alla soglia o sopra. La seconda matrice soddisfa il criterio separatamente
per entrambi i percorsi. Questo confronto riguarda il solo ordinamento
locale macOS/ARM64 con SBCL e safety 3, senza I/O o applicazione dei prepared.

## Risultati e scelta delle soglie

La tabella riporta il **peggior rapporto radix/merge fra i pattern** per
ciascuna cardinalità. Un valore inferiore a uno indica meno tempo radix.
I dati completi conservano tre repliche, tick, iterazioni, allocazioni,
calibrazioni, oracoli e stato di qualità di ciascun campione.

| N | ID16: peggior rapporto | TXID: peggior rapporto |
|---:|---:|---:|
| 16 | 5,043 | non utilizzabile per la soglia |
| 64 | 1,951 | 1,928 |
| 256 | 1,160 | 0,760 |
| 1.024 | 0,858 | 0,636 |
| 4.096 | 0,732 | 0,526 |
| 16.384 | 0,623 | 0,478 |
| 65.535 | 0,555 | 0,431 |

Nelle cardinalità adottate il tempo misurato diminuisce del 14,2–86,9%
per ID16 e del 24,0–85,6% per TXID, secondo il pattern. Le percentuali
non descrivono il recovery completo o il throughput delle query. Gli
ID16 con tutti i byte variabili hanno metà correlate; il carico esterno
non è controllato. Non si estendono le misure a distribuzioni o cardinalità
non misurate, Linux/x86-64, P99 o prestazioni del motore.

La prima matrice con calibrazione a 50 ms non autorizzava una soglia TXID:
alcuni campioni scendevano sotto il minimo. È conservata, compresa quella
selezione negativa. La ripetizione integrale è stata registrata prima
con target di calibrazione 100 ms e minimo dei campioni invariato a 50 ms.
Nella seconda matrice cinque scenari TXID con N=16 raggiungono il tetto
prima del target e restano inutilizzabili; sono sotto entrambe le soglie
adottate. Non si presenta la matrice come 63 scenari tutti qualificati.

Il limite di 64 MiB riguarda il payload delle copie dell'harness. Scratch
prodotto, istogrammi u64, header e output non sono inclusi in quel limite.
Le allocazioni e gli eventuali GC dell'ordinamento sono inclusi nel clock;
non si rivendica zero heap. Il workspace prodotto segue la misura effettiva,
con un vettore scratch e 256 contatori, senza dipendere da budget inutilizzati.

## Correttezza e parallelismo

Radix ordina gli ID16 dal byte 15 al byte 0 e i TXID unsigned da cifra meno
significativa a più significativa. Lo scatter visita gli elementi in ordine
fisico e conserva la stabilità dei duplicati. Una passata viene saltata
soltanto dopo il conteggio completo di una sola classe occupata; lo scratch
non viene scambiato quando la passata è saltata. I controlli finali del
modulo continuano a rilevare partecipanti duplicati e ordinamenti incoerenti.

Le query concorrenti leggono la medesima tabella completata prima dell'avvio
dei worker. Sei thread reali usano buffer, output e stato d'errore esclusivi,
confrontati integralmente con un oracolo dichiarativo. Il buffer del log
viene riusato prima delle query. I join hanno un timeout e gli errori dei
worker non vengono promossi a successo. Il test esercita il contratto di
sola lettura e ownership; non misura accelerazione parallela né realizza
un nuovo pool di esecuzione del prodotto. L'ordinamento della tabella avviene
prima delle consultazioni concorrenti e resta seriale.

## Prove conservate

[Catalogo della campagna](../../spikes/results/2026-10-09-radix/catalogo.lisp),
[selezione della seconda matrice](../../spikes/results/2026-10-09-radix/selezione-100ms.lisp),
[inventario delle decisioni](decisioni-radix-decisioni.md) e
[letture C1](decisioni-radix-revisione.md). I dati conservano anche driver
falliti, self-test che rifiutano algoritmo errato, destinazione esistente,
report parziale e tempo nullo. La compilazione senza avvisi, i mutanti e
la copertura grezza restano prove distinte dalle misure di prestazione.

La suite contiene 43 prove DECISION dedicate e 62 insieme allo scanner.
La campagna mirata rileva 14 mutanti su 14 dopo l'avvio dei test, senza
sopravvissuti, errori di compilazione o guasti precedenti ai test. Sui sei
file `decisions-*` la copertura grezza è 1.332/1.530 espressioni e 138/176
alternative di ramo. Il nuovo file radix osserva 384/409 espressioni e
53/54 alternative: il ramo mancante controlla una lunghezza array fuori
u64, impossibile sul runtime esaminato con `index` fixnum più stretto.
Forme top-level e postcondizioni difensive mancanti restano nei totali,
come motivato nell'inventario; nessuna esclusione viene approvata.

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/decisions-sort-bench.lisp --self-test
sbcl --noinform --no-userinit --no-sysinit --script tools/decisions-sort-bench.lisp --bench spikes/out/decision-sort-new/
sbcl --noinform --no-userinit --no-sysinit --script tools/decisions-radix-mutation.lisp --self-test
sbcl --noinform --no-userinit --no-sysinit --script tools/decisions-radix-mutation.lisp --run spikes/out/decision-radix-mutants-new/
make check
```

Ogni destinazione deve essere nuova. Le guardie difensive restano nei
denominatori della copertura: nessuna esclusione approvata o qualifica
MC/DC viene introdotta da questo confronto.
