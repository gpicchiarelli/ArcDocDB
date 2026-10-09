# Lista dei writer pronti

`lista-writer-pronti` trasporta gli obblighi `:schedule` prodotti dalla
[consegna locale](writer-handoff.md). È una lista preallocata a partizioni
indipendenti, ciascuna con ring FIFO e guard a tentativo singolo. Una
partizione contesa non impedisce di prendere un tratto da un'altra.

| API | Contratto |
|---|---|
| `crea-lista-writer-pronti :shards :capacity` | Da 1 a 64 partizioni, default 4; da 1 a 65536 slot per partizione, default 1024. Costruzione prima del percorso caldo. |
| `pubblica-writer-pronto lista shard writer` | Pubblica una sola volta un obbligo già ottenuto, restituendo il nuovo count della partizione. Il writer resta un riferimento, senza lettura del suo stato. |
| `preleva-writer-pronto lista start` | Cerca in ordine circolare al più K partizioni. Restituisce riferimento, stato e cursore successivo. Nessun retry interno o attesa. |

Il cursore restituito segue la partizione servita se lo stato è `:writer`;
segue start negli altri esiti. `:busy` indica che nessun writer è stato preso
e almeno una partizione era contesa. `:empty` indica che le K osservazioni
locali erano vuote. Non è una prova di quiescenza: una pubblicazione può
avvenire dopo un'osservazione, anche prima che termini la scansione.
FIFO vale dentro ciascuna partizione; non esiste un ordine globale tra
partizioni o una garanzia di starvation temporale.

## Trasferimento dell'obbligo

1. `accoda-lavoro-writer` da idle, oppure `termina-tratto-writer` con backlog,
   restituisce `:schedule`: il chiamante possiede un obbligo.
2. `pubblica-writer-pronto` riuscita lo trasferisce al ring. Full/busy lo
   conservano al chiamante: si ritenta la pubblicazione, senza ripetere
   l'accettazione del payload. Un successo non viene pubblicato di nuovo.
3. Un prelievo `:writer` trasferisce l'obbligo al worker. Se l'avvio del writer
   segnala busy, il worker conserva il riferimento fino al retry riuscito.
   Not-ready segnala un compito non eleggibile o duplicato; non è un retry cieco.
4. Il worker elabora il tratto e lo termina. Un nuovo `:schedule` viene
   pubblicato; `:idle` non richiede alcuna pulizia dello stato scheduler.

La partizione di una Serie è una scelta del chiamante, fissata prima del
percorso caldo. Indice, struttura e capacità sono privati della lista; i
buffer dei messaggi restano privati del consumatore. Il componente non
aggiunge membership o flag `scheduled`: non può cancellare una nuova ondata
con il cleanup del tratto precedente. Non verifica duplicati, obblighi
abbandonati o l'eleggibilità del writer, che appartengono al contratto del
chiamante. Non si mescolano le primitive basse con gli oggetti privati.

## Rifiuti e limiti

| Risposta | Gestione |
|---|---|
| `invalid-argument`, `:ready-configuration` | Budget fuori dai limiti; nessuna lista pubblicata. |
| `invalid-argument`, `:ready-target` / `:ready-writer` | Indice o riferimento invalido; nessuna pubblicazione. |
| `resource-exhausted`, `:ready-queue-full` / `:ready-queue-busy` | Obbligo ancora del chiamante; rifiuto prima della mutazione. |
| `invariant-violation`, `:ready-queue-invariant` / `:ready-queue-guard` | Fail-stop del proprietario; nessun rollback promesso dopo un guasto interno. |

Pubblicazione O(1), ricerca O(K), spazio O(K·capacity), con limiti statici.
Ogni candidata richiede un tentativo CAS di acquisizione e, se riuscito,
un CAS di rilascio: al più K acquisizioni e 2K CAS totali per scansione.
La guard rende seriale solo la breve operazione sul proprio ring; non è un
algoritmo lock-free. La lista condivisa viene toccata per tratto, come
[ADR-0045 §8](../adr/0045-modello-di-esecuzione.md), senza scritture comuni
per messaggio. Non introduce thread, callback, I/O, risvegli o stato globale.
Un protocollo di parcheggio deve coordinare nuova pubblicazione e risveglio:
il solo esito `:empty` non basta. Pool adattivo, arresto e controller restano
componenti da integrare, senza qualificazione del motore completo.

Il [metodo preregistrato](writer-ready-metodo.md), l'
[inventario](writer-ready-decisioni.md) e i [risultati](writer-ready-risultati.md)
delimitano le prove di correttezza, contesa e allocazione osservata.
