# Ricircolo atomico dei writer pronti

`ricircola-writer-pronto(lista, shard, writer)` integra la
[lista pronta](writer-ready.md) con uno scambio FIFO quando il ring è pieno.
Il chiamante possiede un obbligo unico `:schedule` ottenuto dalla
[consegna locale](writer-handoff.md) e deve poter prendere un altro writer.
La primitiva trasporta riferimenti senza leggere lo stato dei writer.

| Spazio nel ring | Valori restituiti | Proprietà dopo il successo |
|---|---|---|
| Disponibile | NIL, `:published`, nuovo count | Il nuovo obbligo appartiene al ring. |
| Esaurito | Vecchia testa, `:writer`, capacity | Il nuovo obbligo appartiene al ring; la testa appartiene al chiamante. |

Nel caso pieno `[C,B,…,Z]` diventa `[B,…,Z,A]`: un solo slot viene sostituito,
head e tail avanzano di uno modulo capacity e count resta invariato.
Capacity 1 è `[C]`→`[A]`. Le verifiche della forma garantiscono head=tail
quando count=capacity. La guard rende indivisibile il trasferimento rispetto
agli altri producer e consumer; un pop e una pubblicazione separati non
soddisfano lo stesso contratto.

Un successo non si ritenta. Con `:writer`, il chiamante prende il riferimento
restituito e conserva la sua proprietà durante un eventuale busy di avvio.
Il writer appena inserito resta nel ring. Il consumo e la fine del tratto
avvengono fuori dalla guard della lista. Dopo una fine `:idle` non esiste
cleanup dello scheduler: una nuova ondata può essere già pubblicata.

## Saturazione e parallelismo

Se tutti i consumer terminano con backlog mentre i producer hanno riempito
i ring, la sola pubblicazione può lasciare ogni consumer impegnato a
ritentare l'inserimento, senza più consumare. Il ricircolo permette invece
al consumer di pubblicare il proprio obbligo e prendere la testa nella
stessa operazione, senza una coda aggiuntiva o capacità crescente.
La regressione conserva questo controesempio con due consumer e due
riferimenti di refill.

Il costo è O(1): un tentativo CAS di acquisizione e, se riuscito, un CAS di
rilascio; nessun retry, attesa, scansione o stato globale nel nuovo codice.
Le guard restano indipendenti per shard e vengono toccate per tratto,
come [ADR-0045 §8](../adr/0045-modello-di-esecuzione.md).
Non vi sono scritture comuni per messaggio, thread di prodotto, I/O o callback.
Factory e sorgenti queue/writer/handoff/ready rimangono invariati.

## Rifiuti e responsabilità

| Condizione | Effetto e gestione |
|---|---|
| `invalid-argument :ready-target` / `:ready-writer` | Indice o riferimento errato, prima della guard e della mutazione. |
| `resource-exhausted :ready-queue-busy` | Nessun trasferimento; il chiamante conserva il proprio obbligo e governa il retry. |
| `invariant-violation :ready-queue-invariant` / `:ready-queue-guard` | Forma, payload o proprietà incoerenti: fail-stop del proprietario, senza rollback promesso dopo un guasto interno. |
| `invariant-violation :ready-recycle-full` | Il helper privato di scambio è stato chiamato fuori dalla sua precondizione full; non è un rifiuto ordinario della API pubblica. |

La capienza piena non è un rifiuto di questa API. L'obbligo unico e la capacità
del chiamante di assumere un altro writer sono precondizioni: non esiste
deduplicazione o verifica dell'eleggibilità. Per un producer che non può
consumare resta disponibile `pubblica-writer-pronto`, con conservazione
dell'obbligo su full/busy e politica bounded definita dal controller.

Lo scambio risolve il blocco dovuto alla sola capacità nel protocollo
modellato. Una catena full resta sul proprio shard e non dimostra equità,
assenza di starvation o progresso con guard perpetuamente contese, obblighi
abbandonati/duplicati o Serie guaste. Empty è un'osservazione locale e non
prova quiescenza per parcheggio o arresto. Pool, risvegli, controller FAULTED,
admission e shutdown richiedono ancora integrazione.

Il [metodo](writer-recycle-metodo.md), l'[inventario](writer-recycle-decisioni.md),
i [risultati](writer-recycle-risultati.md) e la [revisione](writer-recycle-revisione.md)
conservano l'ambito e i limiti delle verifiche locali.
