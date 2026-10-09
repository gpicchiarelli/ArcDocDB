# Decisioni delle code dei writer

Inventario C1 dei sorgenti `src/execution/queue.lisp` e `writer.lisp`,
registrato prima delle campagne. Le prove usano l'interfaccia pubblica e un
oracolo FIFO a liste; le sole preparazioni interne dichiarate sono guardia
acquisita tramite CAS, alias del vettore privato e generazione vicina al massimo.

| Punto | Condizioni elementari ed esiti | Prova prevista o limite |
|---|---|---|
| `%check-queue`: bounds | Capacità 1..65536, lunghezza uguale, head e tail sotto capacità, count entro capacità. Rifiuto `:writer-queue-invariant`. | Costruzione, ring vuoto/pieno, capacità 1/2/3/7, wrap e oracolo 9×1200 azioni. I rifiuti di corruzione interna non sono tutti raggiunti dall'API. |
| `%check-queue`: relazione | `tail = (head + count) mod capacity`. | Prima/dopo ogni enqueue e drain; mutante del wrap. Rifiuto difensivo distinto dai controlli degli input. |
| `%acquisisci-guard` | CAS restituisce NIL oppure guardia occupata; postcondizione guardia del thread. | Successo, busy deterministico, producer concorrenti. Postcondizione falsa richiede corruzione del protocollo. |
| `%rilascia-guard` | Proprietario atteso prima del CAS; vecchio valore del CAS uguale al thread. | Cleanup dopo successo, pieno e busy. I rifiuti difensivi non vengono provocati alterando campi condivisi. |
| `crea-coda-writer` | Separatamente per capacità e quantum: tipo index e range 1..65536. | Tipi errati, zero, negativo, oltre limite; minimi, default e massimo, quantum indipendente dalla capacità. |
| `accoda-messaggio` | count uguale a capacità: pieno; altrimenti accettazione FIFO. | Pieno conserva payload/ring, capacità 1, NIL, wrap, mutanti FIFO/wrap/boundary. |
| `%check-lease`: identità | Tipo index, positivo, proprietario thread corrente, generazione esatta. | Tipo/zero, gettone corrente, rientro, thread estraneo, gettone vecchio dopo nuova acquisizione, doppio rilascio. Mutanti thread/generazione. |
| `%check-lease`: quota | Quantum 1..65536, estratti ≤ quantum. | Quota cumulativa/esatta/esaurita e quantum maggiore della capacità. Rifiuti interni non coperti con scritture arbitrarie. |
| `%libera-owner` | Proprietario atteso e vecchio valore CAS uguale al thread. | Rilascio normale e cleanup dell'esaurimento generazione. Rifiuti difensivi non provocati alterando owner. |
| `acquisisci-writer`: CAS | NIL oppure writer occupato. | Due thread contendenti, rientro dello stesso thread; una sola proprietà assegnata. |
| `acquisisci-writer`: invarianti | Proprietario corrente e extracted zero. | Successo dopo rilascio; rifiuti difensivi non tutti raggiunti dall'API. |
| `acquisisci-writer`: generazione | Generazione uguale al massimo fixnum oppure incremento lecito. | Preparazione privata a max−1, ultima acquisizione e due rifiuti successivi senza wrap/proprietà trattenuta. |
| `%check-target`: vettore | SIMPLE-VECTOR e diverso dal ring. | Tipi non validi, vettore specializzato/adjustable, alias dichiarato; vettore privato valido. |
| `%check-target`: span | start/end index, start < end, end ≤ length. | Tipo, negativo, vuoto, invertito, oltre fine; span disallineato ed esatto con sentinelle. |
| `preleva-messaggi`: remaining | Zero: `0, :yield` prima del CAS; positivo: accesso al ring. | Quota su più chiamate e yield con guardia già occupata; mutante che azzera extracted. |
| `preleva-messaggi`: taken | Minimo di count, span e quota. | Ognuno dei tre limiti vincolante; mutante che ignora end. Copie ≤65536, target fuori span invariato. |
| `preleva-messaggi`: postcondizione | taken ≤ remaining ed extracted ≤ quantum. | Percorsi validi e mutante della quota; rifiuti difensivi non tutti provocati. |
| `preleva-messaggi`: statuto | taken zero: `:empty`; positivo: `:messages`. | Vuoto, drain di NIL, producer aperti durante il consumo. |
| `acquisisci-writer`: cleanup | committed falso: libera owner; vero: conserva la proprietà. | Esaurimento generazione e acquisizione riuscita. |

Questo inventario non dichiara MC/DC completa. La copertura raw conserva
l'intero denominatore, incluse forme non marcate dalla strumentazione e rami
difensivi. Le due letture C1 e i mutanti mirati non sostituiscono una deroga
approvata o la qualifica del motore, dei risvegli e del pool adattivo.
