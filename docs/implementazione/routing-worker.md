# Routing preallocato dal writer alla Serie

Fondazione C1 per REQ-CON-001/002/004/005 e REQ-AFF-008;
ADR-0005, ADR-0033 e ADR-0045. Il routing connette il writer già
preso dalla lista pronta al suo [collegamento worker/Serie](worker-serie.md).
Il [metodo preregistrato](routing-worker-metodo.md), [le decisioni](routing-worker-decisioni.md),
[la revisione](routing-worker-revisione.md) e [i risultati](routing-worker-risultati.md) delimitano le prove.

Il caller assegna all'avvio un `routing-index` immutabile al writer.
L'indice è locale al registro, da 0 a 65535; `NIL` conserva il contratto
dei writer esistenti che non usano questo routing. Non esiste un contatore
globale per attribuire gli indici. Un registro ha da 1 a 65536 associazioni
dense: il writer nello slot i deve avere indice i. I controller del registro
sono distinti per identità EQ, così due writer non rappresentano la stessa
Serie nel medesimo registro. Una sola associazione logica per Serie fra
registri diversi resta una precondizione di configurazione del caller.

| API | Contratto |
|---|---|
| `crea-writer-programmabile :routing-index` | Costruzione all'avvio; indice `NIL` oppure intero nel budget dichiarato. Nessuna attribuzione implicita. |
| `indice-routing-writer writer` | Legge l'ordinale immutabile, senza assumere obblighi o lease. |
| `crea-registro-worker-serie writers controllers` | Copia i vettori del caller, valida tipo, lunghezza, ordinali e unicità dei controller; produce un registro condivisibile immutabile. Nessun claim. |
| `crea-tabella-worker-serie context registro` | Owner corrente, worker IDLE; prealloca un collegamento locale per ogni associazione. Non acquisisce writer o Serie. |
| `collega-writer-worker-serie tabella` | Worker CLAIMED; seleziona lo slot dell'ordinale corrente, controlla identità writer/contesto e collegamento IDLE, restituisce il collegamento. Nessun begin o pop. |

Il registro copia i vettori e mantiene privata la loro rappresentazione:
modificare gli input dopo la factory non cambia le associazioni. Il registro
può essere letto da più worker; ciascuno possiede la propria tabella e i propri
collegamenti sul thread che ha creato il contesto. Nessun collegamento migra
fra thread. La tabella contiene O(N) collegamenti per worker e deve essere
contabilizzata nel budget di memoria all'avvio: il limite massimo ammesso
non è una raccomandazione di dimensionamento.

La selezione usa l'ordinale del writer CLAIMED e un solo accesso indicizzato.
Verifica anche EQ del writer: un writer estraneo con lo stesso numero non
può selezionare una Serie valida per caso. Dopo un ricircolo a ring pieno il
worker può avere un altro writer; il caller ripete la selezione sul nuovo
CLAIMED, senza conservare come corrente il collegamento del tratto precedente.
Ripetere la selezione finché il collegamento è IDLE restituisce lo stesso
oggetto e non crea un nuovo obbligo o una seconda capacità.

La selezione riuscita precede `inizia-worker-serie`; pop, ack, chiusura e
ricircolo usano i contratti già esistenti. Il routing non consulta la salute
del controller, così resta possibile il drenaggio I/O già consentito su una
Serie FAULTED. Non trasferisce una lease e non applica i payload.

Owner estraneo è rifiutato prima del confine, senza avvelenare gli oggetti.
Fase worker errata resta un rifiuto ordinario. Un ordinale assente o fuori
tabella, un writer estraneo, una tabella privata incoerente o un collegamento
già impegnato sono invece difetti della configurazione/protocollo dopo claim:
il worker diventa FAULTED e conserva writer, home e obbligo, insieme alla
condizione originale. Nessun controller viene marcato senza una sua lease;
fermare e coordinare l'Archivio sulla diagnosi resta compito del caller.
Non sono promessi rollback, pubblicazione, cessione o riuso automatici.

Il lookup normale è O(1), senza scansioni, hash, allocazioni, scritture
condivise, thread, attese, callback o I/O. La costruzione è separata dal
percorso caldo e può usare un hash EQ per verificare i controller distinti.
La scansione bounded della lista pronta resta O(K), al più 64 partizioni,
ed è già implementata dal worker. Questo componente non realizza il pool,
wake/park, admission, adattamento EWMA/AIMD, retirement o shutdown.
Non introduce cambiamenti durevoli né qualifica il motore completo.
