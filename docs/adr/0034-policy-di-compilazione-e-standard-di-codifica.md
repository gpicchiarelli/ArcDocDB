# ADR-0034 — Politica di compilazione e standard di codifica

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; precisa «SIMD e ottimizzazioni native» punti
  2–4 (dichiarazioni di tipo, minimizzare boxing) nel quadro di [ADR-0031](0031-software-critico-criteri-e-priorita.md)
- **Riferimenti:** [standard di codifica](../affidabilita/standard-di-codifica.md), INV-A3,
  INV-A4, INV-A8

## Contesto

Common Lisp con `(safety 0)` o con `truly-the` rimuove i controlli che trasformano un difetto
in un errore segnalato: uno scrittura fuori limiti diventa corruzione di memoria silenziosa.
In un sistema critico un difetto deve essere **rilevato**, non propagato.

## Decisione

1. **Safety.** Nessun codice di prodotto è compilato con `safety` inferiore a 2. Con `safety 2`
   (o 3) SBCL mantiene i controlli completi di tipo e di limiti degli array
   (verificato: un accesso fuori limiti in una funzione `(safety 2) (speed 3)` segnala
   `invalid-array-index-error`). Politica predefinita: `(safety 3)`. I percorsi caldi inseriti
   nel registro delle eccezioni possono usare `(safety 2) (speed 3)`; **mai** `(safety 0)`,
   `(safety 1)` con `speed` maggiore (che indebolisce i controlli di tipo), `truly-the`,
   `(optimize (sb-c::insert-array-bounds-checks 0))`.
2. **Compilazione senza avvisi.** Il build fallisce su qualunque `warning` o `style-warning`
   (funzione o variabile non definita, tipo incoerente, variabile non usata).
3. **Dichiarazioni.** Ogni funzione C1 e C2 ha una dichiarazione `ftype` completa; ogni slot
   di struttura ha un tipo; le strutture C1 sono `defstruct` con slot tipizzati e, dove
   possibile, `:read-only`. Le costanti di formato (offset, dimensioni) sono definite una sola
   volta in un modulo di formati e usate da tutti.
4. **Divieti** (verificati da `tools/lint.lisp`): `eval`, `compile`, `load` e `intern`
   su dati esterni; `read` di dati non fidati (e `*read-eval*` sempre `nil`);
   `ignore-errors`; `truly-the`; `safety 0`; funzioni più lunghe di 60 righe; funzioni di
   prodotto senza docstring.
5. **Regole di struttura** (adattate da «Power of 10», in dettaglio nello
   [standard](../affidabilita/standard-di-codifica.md)): cicli con limite superiore dimostrato
   o dichiarato; ricorsione ammessa solo con profondità limitata e dichiarata; ambito minimo
   delle variabili; controllo esplicito di ogni valore di ritorno che può indicare un errore;
   macro ristrette e documentate; nessuno stato globale mutabile senza proprietario dichiarato
   (INV-V4).
6. **Concorrenza.** Solo `sb-thread`, `sb-ext:compare-and-swap` e `sb-thread:barrier`; ogni
   struttura condivisa ha un proprietario unico dichiarato e un protocollo descritto;
   proibito `without-interrupts` e `without-gcing` fuori dal modulo `io` (se mai necessari,
   come deviazione registrata).
7. **Registro delle eccezioni per i percorsi caldi** (`docs/affidabilita/deviazioni.md`,
   sezione «Hot path»): una funzione vi entra solo con una misura (SPK) che mostra che
   `(safety 3)` non raggiunge i [minimi di prestazione](0028-target-e-obiettivi-di-latenza.md),
   e mantiene tutti i controlli di `(safety 2)`.
8. **Strumenti.** `tools/lint.lisp` (divieti, lunghezza, docstring); la compilazione senza
   avvisi nel `make`; entrambi eseguiti dalla CI. Lo strumento è esso stesso verificato da
   fixture di codice scorretto (`--self-test`).

## Conseguenze

- Un difetto di indicizzazione o di tipo diventa un errore segnalato (→ `invariant-violation`,
  Serie `FAULTED`, [ADR-0033](0033-fail-stop-e-integrita-end-to-end.md)), non corruzione.
- Costo di prestazioni dei controlli: stimato nell'ordine del 10–30 % sui cicli più stretti;
  misurato da SPK-09. Se i minimi non sono raggiunti, si interviene sugli algoritmi.
- Il codice è uniforme e verificabile da strumenti.

## Alternative considerate

- *`(safety 0)` sui percorsi caldi con test estesi:* scartata: un difetto non rilevato dai test
  diventa corruzione silenziosa.
- *Un linter esterno:* nessuna dipendenza esterna ([ADR-0027](0027-dipendenze-e-test.md)); le
  regole sono poche e specifiche del progetto.

## Valutazione

- Rischi: RSK-19.
- Verifica: `make lint` e la compilazione senza avvisi nella CI; test di non regressione del
  linter; SPK-09 misura il costo.
