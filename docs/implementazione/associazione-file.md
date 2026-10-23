# Associazione fisica dei file

`arcdocdb.io` associa una capacità readonly e una append allo **stesso file
regolare aperto**, tramite device e inode restituiti da `fstat`. È una prova
locale di identità per il [resolver ACTIVE](get-active.md), distinta da header,
CRC, frontiera WAL, commit e durability. Le decisioni architetturali restano
quelle di [ADR-0017](../adr/0017-piattaforma-e-io.md) e del
[confine I/O](io.md).

## Contratti

| API | Precondizione | Risultato |
|---|---|---|
| `associa-file input append` | controller esclusivo nel pool I/O; capacità aperte, dello stesso backend; nessuna close concorrente | associazione immutabile, restituita solo dopo confronto esatto device/inode |
| `verifica-associazione-file prova input append` | stessa ownership e durata delle capacità | verifica O(1) dei riferimenti e degli stati, senza I/O |
| `verifica-file-distinti left right` | due capacità readonly stabili del medesimo backend, nel pool I/O | due fstat/callback; rifiuta lo stesso device/inode, senza mutazioni o retry |
| `make-backend … :identity callback` | callback fidato e stabile, dello stesso dominio degli altri callback | estensione opzionale; le sei posizioni precedenti restano compatibili |
| `crea-sorgente-get-attiva … :associazione-file prova` | prova ottenuta nel pool I/O | verifica readonly della sorgente e append effettivo del log del controller prima di costruire la sorgente |

Il callback `identity` riceve il FD privato e restituisce due valori interi:
`st_dev` e `st_ino` di un file regolare. Deve segnalare `syscall-error` per errno,
mai usare un numero sentinella come identità. Un backend senza callback può
continuare a eseguire le altre operazioni; l'associazione viene rifiutata prima
di qualsiasi chiamata. Non si passa un FD simulato al sistema operativo.

Il dominio è l'istanza **esatta** del backend: `nil` per entrambi seleziona POSIX;
due istanze distinte sono rifiutate, anche se contengono le stesse funzioni.
L'identità è confrontata come due interi completi, senza hash, troncamento,
conversione a fixnum o normalizzazione del segno. Sono rappresentabili valori
firmati e non firmati a 64 bit; l'ABI di `stat` è gestita da SB-POSIX.

## Sequenza e ownership

1. Aprire il nuovo append `.tmp` e la capacità readonly dello stesso file.
2. Nel pool I/O, chiamare `associa-file`; verificare l'header attraverso il
   normale costruttore `segmento-get`.
3. Nel compito proprietario della Serie, passare la prova a
   `crea-sorgente-get-attiva`. Questa chiamata non esegue syscall.
4. Conservare le due capacità fino alla quiescenza dei loro consumatori.
   Il [protocollo EBR](epoche-e-reclaim.md) e il controller autorizzano il reclaim.

Si eseguono al massimo **due fstat**, una per capacità, senza retry. Il confronto
e la verifica finale degli stati precedono l'unica nuova associazione. Non si
consultano nomi, dimensione, timestamp, numero del FD o contenuti dell'header per
stabilire l'identità. Un hard link allo stesso inode è accettabile; lo stesso
nome che ora indica un altro file non fornisce una prova.

L'associazione conserva soltanto i due riferimenti immutabili. Dopo una close
la vecchia capacità resta chiusa: il riuso del numero FD non riabilita la prova.
Una nuova capacità, anche per lo stesso inode, richiede una nuova associazione.
Il controller impedisce close concorrenti, sostituzione dei FD tramite `dup2`
e modifica esterna del namespace/file. Questa API non introduce sincronizzazione
né rinnova tali precondizioni con una fstat su ogni lettura.

## Errori e compatibilità

| Caso | Condizione / reason | Effetto |
|---|---|---|
| modo errato | `invalid-argument / :io-mode` | nessuna syscall |
| capacità chiusa/faulted | `io-fault / :io-unavailable` | nessuna prova restituita |
| backend diversi | `invalid-argument / :io-identity-backend` | nessun callback |
| callback assente | `unsupported-format / :io-identity-unavailable` | nessun fallback |
| device o inode diversi | `invalid-argument / :io-file-mismatch` | nessuna associazione |
| risultato fuori tipo | `invariant-violation / :io-identity-result` | nessuna associazione |
| fstat fallita | `io-fault / :io-syscall`, operazione `:identity`, errno preservato | nessun retry |
| file non regolare | `io-fault / :io-file-kind` | nessuna associazione |
| prova usata con altra capacità | `invalid-argument / :io-association-capability` | nessuna syscall |

Rifiuti e guasti non mutano stato/frontiere, non chiudono file e non adottano
lotti. Il controller conserva la responsabilità del cleanup e della quarantena.
Gli errori tipizzati del callback sono propagati; non c'è un gestore generico
che li assorbe. Si ricontrollano entrambi gli stati dopo i callback.

Per compatibilità, omettere `:associazione-file` mantiene la precondizione
originaria del costruttore ACTIVE: il chiamante deve provare l'identità fisica.
Il nuovo percorso esplicito la verifica nel prodotto. La registrazione concreta
di apertura/rotazione del server deve ancora adottarlo; il costruttore non apre
automaticamente file e non rende sicuro un percorso che ignori questa prova.

Il [preparatore del nuovo segmento writer](inizializzazione-active.md) richiede
la prova prima della prima write e nell'adozione della sorgente ACTIVE,
insieme a flush, rilettura dell'header e fsync del parent.

## Decisioni e stato delle evidenze

| ID | Decisione composta | Esiti da coprire separatamente |
|---|---|---|
| FID-D01 | device e inode nei tipi ammessi | entrambi validi; ciascun risultato invalido/mancante |
| FID-D02 | backend presente e callback assente | nativo; iniettato con callback; iniettato senza callback |
| FID-D03 | device uguale e inode uguale | entrambi uguali; ciascun componente diverso; entrambi diversi |
| FID-D04 | readonly e append identici ai riferimenti della prova | entrambi esatti; ciascuna capacità sostituita |

Restano da eseguire casi funzionali, fault injection, prove di riuso FD e
concorrenza, copertura delle condizioni e revisione indipendente C1. Le letture
statiche dell'autore non chiudono queste attività. I requisiti REQ-AFF-001/004/008
e REQ-FOR-001 non cambiano stato per questa sola implementazione.

[Catalogo locale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-file-identity/catalogo.lisp):
compilazione del prodotto, controlli statici e disassemblato. Non sono benchmark
né prove di affidabilità del database completo. Il percorso GET non è modificato;
la creazione della prova alloca e può rappresentare gli interi POSIX come bignum,
soltanto durante l'associazione nel pool I/O.
