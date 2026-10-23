# Verifica del registro snapshot e del collegamento CSN

## Ambito preregistrato

Questa campagna verifica le API già presenti in `arcdocdb.mvcc`, usando il
registro canonico `arcdocdb.csn` dello stesso Archivio. La pianificazione è
iniziata il 9 ottobre sul main `edb043b`; la ripresa dell’11 ottobre integra
il main `5768e02`, senza cambiamenti a snapshot e CSN. Il
[metodo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/metodo.lisp)
è stato congelato prima delle esecuzioni registrate e rimane immutato:
`:planned` e `:not-collected` descrivono quel momento, precedente alle prove.
Gli esiti osservati l’11 ottobre sono riportati sotto e nelle
[evidenze della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/README.md).
Non cambia API, formato o protocollo di prodotto.

Il perimetro comprende registrazione, cattura delle frontiere, attivazione,
verifica, terminazione, scadenza limitata e soglia di retention. Dipende dai
contratti del [registro snapshot](registro-snapshot.md) e del
[collegamento CSN](snapshot-csn.md). Le prove del registro CSN esistente
non dimostrano da sole questo collegamento.

I requisiti interessati sono REQ-MVC-003, REQ-MVC-004, REQ-MVC-005,
REQ-MVC-007, REQ-CON-004, REQ-AFF-004 e REQ-AFF-008; gli invarianti sono
INV-M1, INV-M2, INV-M4, INV-P5 e INV-A8. Il nuovo scope non dichiara tali
requisiti verificati per il motore completo.

## Decisioni e casi attesi

| Decisione | Distinzioni da esercitare |
|---|---|
| CSN-S01 | `H0 <= H1` e `H1 <= s` separatamente; frontiere coerenti, carry u32 e massimo u64. |
| CSN-S02 | Cattura riuscita, `:csn-busy`, altra `resource-exhausted`, guasto CSN e uscita non locale. |
| CSN-S03 | Annuncio con e senza pin precedenti; retention osservata dal writer; revoca senza consumo di identità o crediti. |
| CSN-S04 | Corpo che restituisce `NIL`, contesa, ricorsione e rilascio del mutex dopo uscita non locale. |
| CSN-S05 | Invalidazione terminale e ripetuta; guasto durante cattura/pubblicazione; rifiuto dei reader snapshot dopo guasto. |
| Lifecycle | Archivio vuoto, snapshot subito attivo o in attesa, commit risolti fuori ordine, attivazione soltanto a `H >= s`. |
| Risorse e tempo | Configurazione, capacità, generazioni/deadline u64, deadline esatta di attesa e durata, budget del timer. |
| Identità e risultati | Riuso del contesto/slot, evento della vecchia generazione, buffer intatto sui rifiuti, terminazione idempotente. |
| Retention | Minimo dei pin attivi e in attesa, ricalcolo dopo termine/scadenza, visita limitata e cursore del timer. |

Un caso funzionale centrale conserva i token originali di due commit:
il primo resta pendente, il secondo viene risolto. Lo snapshot cattura il
CSN più recente ma attende l'orizzonte. Risolvere il primo permette
l'attivazione; il pin trattiene la soglia finché termine o scadenza lo
rimuovono. L'oracolo controlla valori e rifiuti pubblici, non replica il
codice del prodotto.

Le fixture usano tempo esplicito e capacità piccole. Stati privati vengono
preparati soltanto per confini non raggiungibili con una sequenza breve,
come l'esaurimento della generazione u64, o per un guasto dichiarato.
Il metodo congelato elenca i 28 casi lifecycle, i 15 casi di cattura e i 10
mutanti mirati. Le esecuzioni finali hanno passato tutti i 43 casi dedicati
e rilevato i 10 mutanti a runtime.

Le suite sono `tests/mvcc/support.lisp`, `lifecycle.lisp` e `capture.lisp`:
package `arcdocdb.mvcc.tests`, registro `*mvcc-tests*`, funzione `run`.
Il runner `tools/snapshot-mutation.lisp` seleziona il test mirato con il
nome esatto del registro, senza filtri sul prefisso dei requisiti.

## Errori da distinguere

| Condizione | Ragioni attese nel relativo percorso |
|---|---|
| `invalid-argument` | `:snapshot-registry-configuration`, `:snapshot-context-pinned`, `:snapshot-not-ready`, `:snapshot-sweep-budget`, `:snapshot-result-range`, `:snapshot-commit-zero`. |
| `resource-exhausted` | `:snapshot-capacity`, `:snapshot-generation-exhausted`, `:snapshot-deadline-overflow`, `:snapshot-wait-timeout`. |
| Contesa recuperabile | `resource-exhausted` con `:snapshot-busy` o `:csn-busy`; nessuna attesa o retry interno. |
| `snapshot-too-old` | `:snapshot-stale-identity`, `:snapshot-age-expired`, `:snapshot-ended`. |
| `invariant-violation` | Guasto terminale, frontiere discordanti o metadati corrotti; non convertire in normale contesa. |

La contesa dopo l'annuncio ripristina soltanto la soglia provvisoria.
Un'altra condizione o un'uscita non locale dopo l'annuncio rende il registro
`FAULTED`. Terminazione occupata conserva pin e obbligo di riprogrammarla;
timer occupato conserva il cursore. La verifica in buffer non pubblica un
risultato su rifiuto.

## Metodo e due letture

Le prove concorrenti coordinano i worker con semafori e deadline finite
per attesa e join. Non usano `sleep` per presumere un ordine. Il cleanup
è limitato: rilascia i semafori, raccoglie i worker oppure li termina su
fallimento della fixture, e propaga gli errori. Nessun caso può lasciare
un thread bloccato o nascondere un fallimento.

Le iniezioni alla cattura sono confinate al processo di test isolato.
Ogni sostituzione temporanea dell'adattatore viene ripristinata tramite
`unwind-protect`. Non si introduce una callback o una nuova API nel
prodotto; le funzioni originali si conservano per i casi non iniettati.

I mutanti alterano guardie o transizioni specifiche dello snapshot in
copie isolate. La baseline deve prima completare la suite invariata,
con fase strutturata `:complete` e lista esatta dei test passati.
Errore di compilazione, segnale OS, mancato completamento della baseline
o exit non nullo dopo completamento sono errori del worker, non mutanti
rilevati. Il runner conserva exit, segnale, log e sorgenti generati;
fixture e controllo CLI negativo verificano COD-60 e COD-61.
Il target `snapshot-mutation-selftest` è incluso in `make check-core`,
quindi anche nei job CI Linux e macOS. La campagna di mutazione rimane
un'esecuzione locale esplicita;
runner, log e report dei processi figli del self-test vengono conservati.

La copertura parziale riusa `tools/foundation-coverage.lisp` con scope
`mvcc`. Il driver strumenta i sorgenti di prodotto ma esegue soltanto la
suite `arcdocdb.mvcc.tests:run`; il report seleziona gli otto file di
`src/mvcc/`. Sono stati eseguiti il self-test e il report finale; stato
SB-COVER e HTML sono conservati con denominatori e lacune. È un'osservazione parziale:
non misura MC/DC e non chiude un gate di rilascio.

Prima delle esecuzioni sono state compiute le letture sui sorgenti effettivi,
con autore, revisori indipendenti, hash, rilievi e lista C1 espliciti nel
[record di revisione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/revisione.lisp).
I registri dei comandi conservano argomenti,
ambiente, output, exit e hash prima/dopo. Sorgenti, documenti e indice Git
rimangono congelati durante ciascun comando registrato.

## Esiti osservati l’11 ottobre 2026

La verifica integrata locale sul commit `aa4f462` è riuscita:
[core-finale.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/core-finale.lisp)
conserva `:status :ok`, exit 0 e sorgenti stabili. Sono passati 501 test
dedicati dei moduli, inclusi i 43 nuovi casi MVCC e i 22 casi CBOR già
integrati dal main, oltre allo smoke test. Compilazione senza warning,
lint, self-test, tracciabilità, link, verifiche delle evidenze e i dieci
spike sono riusciti.

Il primo tentativo
[core-iniziale.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/core-iniziale.lisp)
rimane `:failed`, exit 2: COD-01 ha rifiutato una variabile `REGISTRY`
inutilizzata nella fixture lifecycle. La
[correzione registrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/correzione-fixture.lisp)
aggiunge un’asserzione sull’identità pubblica del registro nel contesto.
Il blob della fixture passa da `4e9a15f` a `2cc481d`; conteggio dei test e
sorgenti di prodotto restano invariati. Questa differenza rispetto al
freeze originale è esplicita; il metodo e gli esiti iniziali sono conservati.

In [mutazioni-finale.lisp](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/mutazioni-finale.lisp)
la baseline completa esattamente i 43 test previsti, fase `:complete`,
exit 0. Tutti i dieci mutanti nominati falliscono il test mirato a runtime
con exit 1, senza segnali o timeout; gli errori dei worker sono zero.
Le fixture del runner hanno invece prodotto realmente SIGKILL 9 e un
exit 7 dopo `:complete`: entrambi sono classificati `:worker-error`,
come previsto, con log e runner conservati. Il controllo CLI negativo
rimane `:failed`, exit 1, con il rifiuto COD-61 atteso.

Il [comando di copertura finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/copertura-finale-comando.lisp)
è riuscito. L’[indice HTML](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/raw/copertura-finale/cover-index.html)
riporta 784/1084 espressioni (72,3247%) e 88/132 rami (66,6667%): restano
300 espressioni e 44 rami senza conteggio. Per `snapshots-read.lisp` sono
31/209 espressioni (14,8%) e 0/28 rami. Le suite esercitano le API reader;
le espansioni `INLINE` limitano l’attribuzione dei contatori al file,
quindi questi valori non dimostrano che i relativi percorsi non siano
stati eseguiti. Una lettura indipendente ha ricostruito tutti gli otto
HTML e verificato l’identità dei sorgenti annotati.

Prima del push è stato integrato anche il main `f16e978`, che aggiunge
la campagna degli indici senza modificare snapshot o CSN. La
[verifica integrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/integrazione.lisp)
sul commit `ac52376` passa 620 test più smoke, inclusi 64 casi slot e 55
casi indice primario. Il self-test del driver di copertura unito è
riuscito; una revisione indipendente conferma entrambe le suite e gli
scope `mvcc` e `index`. Le prove precedenti rimangono originali.

## Criteri di chiusura e limiti

La campagna si chiude quando il mapping concordato è esercitato dalla
suite dedicata, il runner distingue i guasti nelle proprie fixture, i
mutanti mirati sono rilevati o analizzati, le verifiche integrate passano
e la CI riguarda l'esatto commit pubblicato. Alla pubblicazione di questi
risultati la CI di tale commit è **in attesa**; gli esiti locali non ne
anticipano il risultato. Il [catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-snapshot-verification/catalogo.lisp) conserva record
schema 1 con nomi LEAF, byte originali e stati dei tentativi falliti.
Gli eventuali casi non esercitati restano lacune esplicite.

La preregistrazione rimane distinta da questi risultati. La misura di
espressioni/rami conserva il denominatore e non misura MC/DC.
Le sequenze coordinate non provano la memoria debole ARM64/x86-64 e non
sono benchmark. Restano EBR/reclaim, primary index, versioni trattenute,
GET, timer/scheduler del motore, durability e crash recovery. Non si
dichiara zero heap, latency misurata, qualifica C1 completa o chiusura di
una fase. Le evidenze runtime rimangono separate dalle precedenti
ispezioni statiche.
