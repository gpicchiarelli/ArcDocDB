# Standard di codifica

Si applica a **tutto il codice di prodotto** (C1…C3, [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md));
gli strumenti (C4) seguono le regole contrassegnate «strumenti». Ogni regola dice **come è
verificata**: `lint` = `make lint`; `build` = compilazione senza avvisi; `rev` = lista di
controllo di revisione; `test` = test dedicato.

Adattate dalle regole «Power of 10» di G. Holzmann (JPL), da MISRA e dalla pratica Common Lisp
per sistemi critici. Una deviazione è ammessa solo se registrata in
[deviazioni.md](deviazioni.md).

## Compilazione e tipi

| ID | Regola | Verifica |
|---|---|---|
| COD-01 | Compilazione senza `warning` né `style-warning`. | build |
| COD-02 | `safety` ≥ 2 sempre; predefinito 3; mai `safety 0`; mai `safety 1` con `speed` maggiore di `safety`. | lint, rev |
| COD-03 | Vietati `truly-the` e la disattivazione dei controlli dei limiti degli array. | lint |
| COD-04 | Ogni funzione C1/C2 ha `ftype` completo; ogni slot di struttura ha un tipo; array specializzati con tipo di elemento esplicito. | rev, build |
| COD-05 | Le costanti di formato (offset, lunghezze, magic) sono definite una volta in un solo modulo. | rev |
| COD-06 | Nessun `(declare (ignore …))` su un valore che può indicare un errore. | rev |

## Controllo del flusso

| ID | Regola | Verifica |
|---|---|---|
| COD-10 | Ogni ciclo ha un limite superiore dimostrato o dichiarato e controllato (`loop … repeat`, `dotimes`, iterazione su sequenza di lunghezza nota); i cicli «finché ha successo» hanno un tetto di tentativi. | rev, test |
| COD-11 | Ricorsione ammessa solo con profondità limitata e dichiarata; altrimenti iterazione. | rev |
| COD-12 | Funzioni brevi: al più 60 righe. | lint |
| COD-13 | Complessità contenuta: al più 10 percorsi indipendenti per funzione. | rev, copertura |
| COD-14 | Nessun `go`/`tagbody` fuori dalle macro di supporto documentate; nessun `catch`/`throw` per il flusso ordinario. | lint, rev |
| COD-15 | Ogni `cond`/`case` ha il ramo finale esplicito (`t`/`otherwise`) che segnala `invariant-violation` se inatteso. | rev, copertura |

## Errori e asserzioni

| ID | Regola | Verifica |
|---|---|---|
| COD-20 | Vietato `ignore-errors`. | lint |
| COD-21 | Nessun gestore che cattura `error`/`serious-condition`/`t` se non ai confini (richiesta, worker) con registrazione e transizione di stato definita. | rev |
| COD-22 | Gli errori sono condizioni della gerarchia `arcdocdb-error` ([ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md)); mai `(error "stringa")` nel prodotto. | rev, test |
| COD-23 | Ogni valore di ritorno che può indicare un errore è controllato; un esito non gestito è un difetto. | rev |
| COD-24 | Le asserzioni sugli invarianti interni sono sempre attive in produzione e, in C1, portano la Serie in `FAULTED`. Almeno due asserzioni per funzione non banale di C1 (precondizioni e postcondizioni significative). | rev, test |
| COD-25 | Nessuna asserzione ha effetti collaterali. | rev |
| COD-26 | `unwind-protect` solo per rilasciare risorse; mai per nascondere un errore. | rev |

## Dati, memoria, ambito

| ID | Regola | Verifica |
|---|---|---|
| COD-30 | Nessuna allocazione nello heap gestito sui percorsi caldi dopo l'avvio ([ADR-0024](../adr/0024-memoria-e-gc.md)). | test di allocazione |
| COD-31 | Ambito minimo: variabili dichiarate nel punto più interno possibile; nessuna variabile speciale (`defvar`) mutabile se non registrata con proprietario. | lint, rev |
| COD-32 | Stato globale mutabile vietato, salvo strutture del runtime elencate con proprietario unico (INV-V4). | rev |
| COD-33 | `defstruct` con slot `:read-only` dove il valore non cambia dopo la costruzione. | rev |
| COD-34 | Vietati `eval`, `compile`, `load` e `intern` su dati esterni; `*read-eval*` sempre `nil`; nessun `read` su dati non fidati. | lint |
| COD-35 | Nessun `sb-sys:with-pinned-objects` o chiamata di sistema fuori dal modulo `io`. | lint, rev |
| COD-36 | Un file o una directory si elimina solo tramite la funzione del modulo `io` che riceve la prova della rimozione: nome `.tmp` non nominato dalla fonte di verità, oppure il record che registra la rimozione (INV-A10, [ADR-0036](../adr/0036-leggi-di-progetto.md)). | rev, test |
| COD-37 | Il recovery apre i segmenti esistenti in sola lettura; nessuna funzione tronca un segmento (INV-A9). | rev, test |
| COD-38 | Ogni funzione che rende durevole un cambiamento indica nella docstring il **punto di atomicità** dell'operazione e se sta prima (preparazione) o dopo (completamento idempotente) (INV-A11). | rev |

## Concorrenza

| ID | Regola | Verifica |
|---|---|---|
| COD-40 | Ogni dato condiviso ha un proprietario unico dichiarato e un protocollo di accesso descritto (commento `;;; OWNER:`). | rev |
| COD-41 | Solo `sb-thread` (mutex, variabili di condizione), `sb-ext:compare-and-swap` e `sb-thread:barrier`. | lint, rev |
| COD-42 | Ogni attesa ha un limite di tempo o una condizione di uscita dimostrata; nessuna attesa illimitata su un lock tenuto da codice esterno al proprietario. | rev, test |
| COD-43 | Vietati `without-interrupts` e `without-gcing` fuori dal modulo `io`. | lint |
| COD-44 | Tempo, casualità, schedulazione e I/O solo tramite le interfacce iniettabili ([ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md)). | lint, rev |
| COD-45 | Un compito non si sospende: nessuna chiamata bloccante fuori dai compiti del pool di I/O; un'attesa è un parcheggio in una lista con lunghezza e tempo massimi (INV-P5, [ADR-0045](../adr/0045-modello-di-esecuzione.md)). | rev, test |
| COD-46 | **Parallelismo.** Nessuno stato condiviso tra Serie fuori dall'elenco chiuso di [architettura](../architettura.md#archivio-coordinamento-minimo); nessuna scrittura condivisa tra Serie sul percorso di una singola operazione; ogni struttura condivisa dichiara, accanto al proprietario, quando viene toccata (commento `;;; SHARED:` con la voce dell'elenco) (INV-P6, [ADR-0036](../adr/0036-leggi-di-progetto.md)). | rev, bench |

## Documentazione e tracciabilità

| ID | Regola | Verifica |
|---|---|---|
| COD-50 | Ogni `defun`, `defmacro`, `defstruct` di prodotto ha una docstring che dichiara precondizioni, postcondizioni e condizioni segnalate. | lint |
| COD-51 | Ogni definizione di prodotto riporta `;;; REQ: REQ-…` con i requisiti che realizza. | `make trace` |
| COD-52 | Ogni test porta nel nome l'ID del requisito che verifica. | `make trace` |
| COD-53 | Le macro sono ammesse solo per eliminare ripetizione di forma o per i controlli di invarianti; ogni macro ha test di espansione. | rev, test |
| COD-54 | Ogni decisione composta (`and`/`or` con più condizioni in `if`/`when`/`unless`/`cond`) in C1 è elencata nella tabella delle decisioni e coperta condizione per condizione. | piano di verifica |

## Strumenti (C4)

| ID | Regola | Verifica |
|---|---|---|
| COD-60 | Ogni strumento ha un `--self-test` o fixture che ne dimostra il rilevamento. | test |
| COD-61 | Uno strumento che fallisce una verifica esce con codice non nullo e un messaggio che indica file e regola. | test |

## Lista di controllo di revisione (C1)

Ogni modifica a codice C1 passa **due letture** con questa lista, e il revisore la compila nella
descrizione della modifica:

1. Il requisito `REQ-…` e l'ADR sono indicati e coerenti con il codice.
2. Gli invarianti toccati sono elencati; ciascuno ha un test che fallirebbe se violato.
3. Ogni errore possibile ha un tipo, una gestione e un test.
4. Ogni ciclo e ogni attesa è limitato; nessuna ricorsione illimitata.
5. Nessuna allocazione sul percorso caldo (misurata).
6. Nessun dato non verificato lascia il modulo.
7. Ogni nuova decisione composta è nella tabella delle decisioni.
8. Il proprietario di ogni stato condiviso è dichiarato e rispettato.
9. La matrice di tracciabilità è aggiornata e `make check` passa.
10. Nessuna regola violata senza deviazione registrata.
11. La modifica non introduce tra Serie un lock, un'attesa o una scrittura condivisa per
    operazione; ciò che rende seriale è dichiarato (INV-P6).
12. Per ogni cambiamento durevole è indicato il punto di atomicità; ciò che lo precede è
    scartabile, ciò che lo segue è idempotente; nulla è eliminato senza un record che lo dica
    (INV-A10, INV-A11).
