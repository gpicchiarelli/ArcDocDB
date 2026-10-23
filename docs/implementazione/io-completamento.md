# Completamento delle operazioni I/O

Il percorso di preparazione e pubblicazione CONTROL usa gli stessi trasferimenti e flush del writer. Ogni capacità ha un solo proprietario per tutta la chiamata; i callback iniettati sono fidati e rispettano questa proprietà. Le sonde di invalidazione intenzionale verificano il comportamento del confine anche quando un callback chiude la capacità. Non costituiscono una prova contro close/dup2 concorrenti conformi al contratto.

## Append e lettura

`append-esatto` installa il cleanup dopo i rifiuti di range/budget, prima del primo possibile effetto. Qualsiasi uscita incompleta, compresa una condizione originale o un’uscita non locale dopo effetti non ancora contati, guasta soltanto una capacità OPEN. CLOSED resta chiusa. Non si ritenta, tronca o annulla; il caller riconcilia la posizione fisica. Il progresso positivo già restituito resta nella frontiera scritta, quello non restituito resta incerto. La frontiera durevole non avanza.

Dopo ciascun ritorno del writer il contatore deve essere quello iniziale più il progresso già contato, prima di aggiungere il nuovo progresso. Una mutazione esterna della frontiera viene rifiutata. Append e lettura ricontrollano la capacità prima e dopo ogni frammento: una chiusura osservata impedisce la chiamata successiva e la consegna di successo, anche se l’ultimo callback ha restituito tutto il range. La lettura non distruttiva conserva la politica esistente: la condizione originale non guasta da sola la capacità readonly, e il buffer parziale non viene consegnato come completo.

## Flush

`durable-flush` cattura la frontiera scritta prima dell’effetto; dopo il ritorno POSIX zero richiede ancora capacità OPEN e frontiera invariata. Solo allora aggiorna la frontiera durevole al valore catturato. Uscita incompleta guasta OPEN, preserva CLOSED, la frontiera durevole precedente e la condizione originale. Una sincronizzazione eseguita ma non osservata come completata non autorizza una conferma al client.

`fallisci` applica la stessa transizione monotona agli errori write/flush; la lettura resta senza mutazione. Le brevi transizioni di stato sono protette dalle interruzioni all’interno di IO, senza syscall o attese nella sezione protetta. Nessun oggetto, lock o coordinamento tra Serie è aggiunto al percorso normale.

## Decisioni del delta

| ID | Decisione | Casi dedicati |
|---|---|---|
| ICO-D01 | effetto incompleto e stato OPEN | successo, condizione originale, uscita non locale, CLOSED, FAULTED |
| ICO-D02 | risultato POSIX esattamente zero | zero, nonzero, NIL, float, errno incluso EINTR |
| ICO-D03 | frontiera scritta invariata nel flush | uguale, avanzata, capacità chiusa |
| ICO-D04 | frontiera append iniziale + done | uguale, alterata dal callback, short I/O |
| ICO-D05 | capacità ancora aperta dopo ogni frammento | short/final read/write, chiusura, nessuna seconda chiamata |
| ICO-D06 | progresso positivo confermato | errore prima del ritorno, errore dopo frammento, incremento una volta |

Le coppie MC/DC complete e le interruzioni asincrone in ciascuna istruzione non sono attestate dai test funzionali. Le prove del checkpoint verificano l’ordine locale fino al manifest riletto: inventario dei CLOSED, adozione del controller, indici, traffico e crash del motore completo restano distinti. Il metodo della campagna è nel [registro](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-14-control-verifica/README.md).
