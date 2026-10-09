# Registro CSN — risultati locali del 2026-10-09

Implementazione di [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md),
[metodo preregistrato](csn-metodo.md), [contratto](csn.md),
[decisioni](csn-decisioni.md), [due letture C1](csn-revisione.md).
I [registri strutturati](../../spikes/results/2026-10-09-csn/catalogo.lisp)
conservano argv, ambiente, hash prima/dopo, output grezzo ed esiti.

Il prodotto è stato congelato in `d9eeda4`; il registratore dei benchmark è stato
corretto in `3173866` e `435d91d`. Il codice CSN è identico nei tre commit.
La campagna finale è `4000521409-command-21277-0`, audit di lettura
`4000521458-command-24266-0`. Hardware Apple M4 ARM64, SBCL 2.6.9,
safety 3; carico esterno non controllato. Sono misure del registro, con il costo
dell'oracolo nell'intervallo misurato, prive di soglie di throughput del motore.

## Correttezza

La build isolata supera 240 test, più due smoke check, senza warning/style-warning.
I 20 test CSN confrontano il prodotto con interi Lisp e liste indipendenti:

- K=2, sei commit: 850 prefissi e 243 storie complete;
- K=3, sei commit: 7.310 prefissi e 2.403 storie complete;
- 10.000 azioni, seme `#x46c5a71b`: assegnazione, rifiuto full, risoluzione,
  lettura e token stale; carry a 2^32, confine fixnum, massimo u64;
- quattro worker, 1.000 assegnazioni ciascuno, K=3: identità uniche e contigue,
  riuso di ogni slot, rifiuti busy/full senza consumo di CSN, H monotono e convergente;
- mutex trattenuto da altro worker, acquisizione ricorsiva e macro con valori
  multipli, NIL, errore e uscita non locale: nessuna attesa nel prodotto e cleanup;
- FI di forma, frontiere e cardinalità: errori tipizzati prima della mutazione.

I quattro mutanti sono rilevati da probe nominati dopo compilazione riuscita:
registrazione omessa, H anticipato, carry high omesso, identità stale accettata.
I probe sono dedicati e separati dalla suite ASDF. Si conservano copie dei sorgenti,
driver, probe e log grezzi; un errore di compilazione non conta come rilevazione.

`sb-cover`: `registry.lisp` 361/387 espressioni (93,3%) e 68/72 rami (94,4%).
Le quattro direzioni non percorse appartengono ai controlli di tipo generati dal
`defstruct`, sui domini della capacità e dei vettori. Dichiarazioni e forme di
caricamento contribuiscono al denominatore delle espressioni. Stato grezzo e HTML
sono conservati; nessuna dichiarazione di copertura MC/DC o di interleaving esaustivi.

## Allocazioni e costo sequenziale

60 campioni finali: 50 assegnazione/risoluzione e 10 letture coerenti delle
frontiere. Tutte le finestre hanno durata positiva, almeno 20 tick e **zero byte
di heap misurati**. Il controllo positivo vede 16 MiB di allocazioni deliberate;
la baseline costante resta zero. Le due basi sono `(0,0)` e
`(#x80000000,#xfffffff0)`, la seconda oltre fixnum e attraverso carry low.

Mediane di cinque campioni; una coppia include due API, non due documenti:

| Scenario | Base piccola, milioni/s | Base alta, milioni/s |
|---|---:|---:|
| Assegna/risolvi, K=1 | 5,25 | 5,34 |
| Assegna/risolvi, K=16 | 4,53 | 4,39 |
| Assegna/risolvi, K=256 | 1,46 | 1,44 |
| Assegna/risolvi, K=1024 | 0,461 | 0,461 |
| Più vecchio pendente, secondo slot riusato, K=2 | 4,89 | 4,85 |
| Lettura coerente di ultimo e H | 13,29 | 13,30 |

La scansione a K parole domina al crescere di K; il default 256 rimane una
configurazione iniziale da rivalutare nel percorso WAL. Nessun heap o costo del
controller, dell'indice, di un documento o del flush è dedotto da queste misure.

## Worker reali

Tre repliche per modalità, 10.000 coppie per worker, K=256, fixture e thread
creati prima della finestra. Mediane di coppie/s:

| Worker | Un Archivio condiviso, milioni/s | Un Archivio per worker, milioni/s |
|---|---:|---:|
| 1 | 1,29 | 1,26 |
| 2 | 1,16 | 2,47 |
| 4 | 1,01 | 5,14 |

Ogni replica verifica esattamente le identità emesse con bitmap e checksum,
e ultimo=H al termine. Nel caso condiviso le tre repliche totalizzano 50.644
retry busy a due worker e 348.290 a quattro; full è zero. Nei registri indipendenti
busy/full sono zero. La condivisione per Archivio serializza il coordinamento
**per lotto**, come previsto dall'ADR; non si deduce la scalabilità per documento.
Le condizioni di contesa allocano. Le finestre di allocazione dei worker usano
un contatore del processo, si sovrappongono e non sono sommabili.

## Diagnostiche e integrazione

La prima campagna conservava tempi, lavoro e heap ma perdeva i campi derivati
del throughput: `getf` su una chiave nuova preponeva una testa non condivisa.
Il registratore ora predispone i campi di entrambe le metriche, ne verifica la
persistenza nei record e include un controllo C4. Si conservano tutte e tre le
campagne, i tentativi di lettura falliti e i sorgenti dei due helper diagnostici.
Questi errori erano negli strumenti di raccolta; nessun fallimento del prodotto
CSN è stato osservato nelle campagne descritte.

Il manifest e gli header CBOR aggiunti nel frattempo su `main` sono integrati prima della
verifica completa della consegna. Il catalogo conserva l'esito effettivo di
`make check`; le prove isolate non sostituiscono tale controllo.
WAL/controller, massimo globale del recovery, snapshot, parcheggi e fail-stop
restano integrazioni successive. Nessun requisito completo viene promosso.
