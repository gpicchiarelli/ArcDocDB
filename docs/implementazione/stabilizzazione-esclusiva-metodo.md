# Collegamento della stabilizzazione alla pubblicazione esclusiva

> **Proposta di integrazione** — Metodo del 2026-10-22, prima delle
> modifiche funzionali e delle diagnostiche. Applica ADR-0040 §2–3 e
> INV-A9/A10/A11 senza modificare formati, decisioni o ammissione.

## Base e incremento

Si compongono la pubblicazione esclusiva del branch
`codex/recovery-publish-temporary` (`a478cf94`) e la stabilizzazione
idempotente entrata in `main` (`52ca4f77`). L'integrazione risolve soltanto
gli elenchi di componenti/export in ASD e package, mantenendo entrambe
le API e tutti gli originali già versionati. La copia primaria non viene
modificata da questa attività.

`stabilizza-nome-fonte-recuperata` continua a verificare token semantico,
CONTROL, riga del set e FD readonly prima di delegare al modulo I/O.
`stabilizza-nome-temporaneo` mantiene le due osservazioni dei nomi e il
ritorno T/NIL; cambia soltanto il percorso di rinomina:

1. Preflight comune di nomi, modi e backend di identità.
2. Osservazione: esattamente uno dei due nomi deve designare il FD.
3. Se temporaneo, preflight della pubblicazione esclusiva **prima** del
   confine dell'effetto; callback esclusiva obbligatoria, nessun ripiego.
4. Nel confine di cleanup già esistente, il ramo temporaneo chiama
   `pubblica-temporaneo`; il ramo definitivo non invoca alcuna rinomina.
5. Postcondizione comune dei due nomi, fsync parent e FD ancora aperto.

Il ramo definitivo richiede identità e flush, senza callback di rinomina
ordinaria/esclusiva o simbolo nativo di rinomina. Il ramo temporaneo
richiede `:rename-exclusive` anche se il backend dispone di `:rename`.
L'API pubblica di pubblicazione mantiene preflight, copie private bounded
e verifica dell'identità: nessun secondo motore di rinomina.
Le copie aggiuntive di nomi brevi sono un costo dichiarato del percorso
freddo; non viene introdotto un nuovo percorso privato per evitarle.

## Guasti, autorità e limiti

Il controllo preliminare di assenza resta un diagnostico del namespace;
la syscall esclusiva impedisce la sostituzione del target anche se compare
prima della rinomina. L'identità del sorgente richiede tuttora namespace
esclusivo e stabile. Nessuna promessa di recovery concorrente.

Callback/simbolo mancante nel ramo temporaneo: rifiuto prima del confine
dell'effetto, capacità ancora aperte. Errore di rinomina, collisione alla
syscall, postcondizione o flush falliti e interruzione nel completamento:
cleanup originario, parent ancora OPEN diventa FAULTED, causa preservata.
Nessun retry, rollback, close, unlink o scrittura/troncamento del segmento.
Una nuova acquisizione osserva temporaneo o definitivo e ripete soltanto
il completamento giustificato dall'EDIT autorevole.

Il nuovo collegamento non completa l'esecuzione di tutte le azioni del
recovery, la rimozione con prova, il checkpoint, gli indici o l'ammissione.
La Serie resta l'unità indipendente: nessun thread, lock, registro o
scrittura aggiunta fra Serie; fsync parent rimane per fonte riuscita.

## Decisioni e piano delle diagnostiche

| ID | Confine da qualificare |
|---|---|
| SNE-D01 | Preflight comune senza callback di rinomina; ciascuna callback identità necessaria |
| SNE-D02 | Solo ramo temporaneo richiede callback/simbolo esclusivo, prima dell'effetto |
| SNE-D03 | Ramo temporaneo usa pubblicazione esclusiva; `:rename` non è fallback |
| SNE-D04 | Ramo definitivo senza rinomina conserva postcondizione e fsync obbligatoria |
| SNE-D05 | Due livelli di cleanup preservano la causa e non riaprono CLOSED/FAULTED |
| SNE-D06 | Token ACTIVE/CLOSED, ID u64, FD e CONTROL restano quelli della fonte verificata |

Codice e documentazione vengono committati prima dei processi; gli agenti
di revisione sono chiusi prima delle diagnostiche. Compilazione forzata
del solo prodotto con avvisi fatali e cache privata gerarchica; lint,
tracciabilità, collegamenti e lettura del disassemblato, tutti registrati
con revisione, hash, ambiente e originali. Una revisione indipendente e
due riletture C1 dell'autore restano statiche.

Non si aggiungono o eseguono test funzionali, FI, copertura, mutazioni o
benchmark. SNE-D01…D06, PIO-D01…D09 e SNR-D01…D09 restano da qualificare.
La diagnostica locale non è esecuzione della nuova API o della CI GitHub.
I registri vengono raccolti in archivi nuovi e chiusi con il collector
comune, quattro worker e checker indipendente; gli originali precedenti
restano invariati. La conservazione lossless può usare descriptor gzip
prima della raccolta; nessun FASL o cache viene pubblicato.
