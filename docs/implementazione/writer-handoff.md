# Consegna locale dei tratti del writer

`arcdocdb.execution` aggiunge `writer-programmabile`: possiede una
[coda writer](code-writer.md) privata e coordina accettazione e fine del
tratto tramite la stessa guard del ring. Un messaggio che arriva dopo
l'ultimo prelievo mantiene l'obbligo di eseguire il prossimo tratto.
Ogni oggetto appartiene a una Serie distinta, senza una guard fra Serie.

| Operazione | Risultato |
|---|---|
| `crea-writer-programmabile :capacity :quantum` | Coda privata preallocata e stato idle; medesimi limiti/default delle code basse. |
| `accoda-lavoro-writer writer payload` | Conteggio dopo l'accettazione e `:schedule` solo su idle→ready; `:queued` se ready/running. NIL resta un payload valido. |
| `inizia-tratto-writer writer` | Ready→running con lease legata al thread; nessun prelievo implicito. |
| `preleva-lavori-writer writer lease target start end` | FIFO, quota cumulativa e span come `preleva-messaggi`. |
| `termina-tratto-writer writer lease` | Rilascia la lease; ready e `:schedule` se resta lavoro, idle e `:idle` se vuoto. |

Il consumatore elabora i messaggi estratti prima di terminare il tratto.
Può concluderlo anche prima del quantum: eventuali messaggi residui richiedono
comunque un nuovo compito. Accettazione e completamento condividono la guard;
la lease conserva l'esclusività del writer durante l'elaborazione.

`:schedule` è un obbligo trasferito al chiamante: pubblicare una sola volta
il prossimo compito e conservarlo fino all'avvio riuscito. Se l'invio allo
scheduler fallisce, si conserva e ritenta la notifica; non si ripete
l'accettazione del payload. L'oggetto interno della coda resta privato:
usare su di esso le API basse invaliderebbe il protocollo.

## Ordini del passaggio di consegna

| Ordine sotto la guard locale | Esito |
|---|---|
| Producer accetta mentre running, poi termina il writer | `:queued`, poi il termine vede il backlog e restituisce `:schedule`. |
| Writer termina vuoto, poi accetta il producer | `:idle`, poi accettazione idle→ready con `:schedule`. |
| Altri producer accettano mentre ready | `:queued`; rimane il singolo compito già dovuto. |

In ciascun ordine il lavoro accettato rimane associato a un tratto corrente
o a un prossimo compito. Non si legge count senza guard per decidere il
riaccodamento. La futura lista delle Serie pronte viene toccata solo per
avviare o riaccodare un tratto; i messaggi ordinari modificano soltanto
lo stato della propria Serie, come richiede
[ADR-0045 §8](../adr/0045-modello-di-esecuzione.md).

## Rifiuti e responsabilità

| Rifiuto | Proprietà e azione del chiamante |
|---|---|
| `:writer-queue-busy` | Un solo tentativo CAS. Nessuna accettazione/estrazione; al termine lease, quota e stato conservati. Ritentare la sola operazione rifiutata. |
| `:writer-queue-full` | Payload ancora del producer, nessun cambiamento di stato o notifica. |
| `:writer-not-ready` | Avvio rifiutato su idle/running: assegnazione non eleggibile o duplicata. Non accodare un retry cieco che possa consumare un'ondata futura. |
| `:writer-generation` | Esaurimento permanente senza wrap; ready e messaggi conservati, nessuna nuova lease. Il controller gestisce il rifiuto. |
| `:writer-lease` / `:writer-target` | Lease vecchia/errata/di altro thread o target invalido; proprietà correnti conservate. |
| `invariant-violation` | Stato/ring/owner incoerenti; il controller deve applicare il fail-stop della Serie. |

Le condizioni appartengono alla gerarchia di ArcDocDB. Il modulo non possiede
ancora il controller della Serie, quindi segnala gli invarianti al chiamante.
Non modifica dati persistenti e non introduce un punto di atomicità durevole.

## Verifica e confini

Il [metodo preregistrato](writer-handoff-metodo.md) richiede un oracolo FIFO
indipendente, ordini deterministici della race, worker reali riusati, fault
injection, copertura raw, mutanti, allocazioni preallocate e due letture C1.
I [risultati locali](writer-handoff-risultati.md), la
[tabella delle decisioni](writer-handoff-decisioni.md) e la
[revisione](writer-handoff-revisione.md) conservano lo scope della verifica.

Questo blocco trasferisce l'obbligo locale di scheduling. Lista pronta,
risvegli, arresto dei worker e controller adattivo richiedono integrazione;
non viene provato il progresso se il chiamante abbandona il compito o la lease.
Le primitive non creano thread né eseguono callback o I/O. Nessun requisito
viene promosso e nessun gate del motore viene chiuso.
