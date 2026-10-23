# Revisione indipendente della presa governata dal pool

Lettura statica del 2026-10-13 sulla base
`900fa93d9e14a252e6a2b5a009d19728b2de34af`, eseguita da un agente diverso
dall'autore del nuovo gate. Esito finale: **positivo per lo scope C3**, dopo
la precisazione documentale descritta sotto. Non sono stati modificati
codice di prodotto o test dal revisore. Questa lettura non è una revisione
umana e non attesta esiti di build, test, copertura o misure.

Sono stati letti il [contratto](pool-worker-claim.md), il
[metodo preregistrato](pool-worker-claim-metodo.md), il gate, l'export,
l'ordine ASDF e i dodici test nuovi. Il quadro applicato è
[ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
[ADR-0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0045](../adr/0045-modello-di-esecuzione.md) e lo
[standard di codifica](../affidabilita/standard-di-codifica.md).

## Identità della lettura finale

Le identità SHA-256 seguenti si riferiscono ai file letti, prima delle
campagne congelate. Gli eventuali risultati successivi devono dichiarare
se hanno usato queste stesse versioni.

| File | SHA-256 |
|---|---|
| `src/scheduler/pool-claim.lisp` | `e384f6091a5fcb506e718e12e77b06ab8dd4233a41024bc57ca3b14425e10b14` |
| `src/scheduler/package.lisp` | `a44fd2c3d435e1f6729bf861b6caeb54a184f31c92e7909aad9c18b491f03cdf` |
| `arcdocdb.asd` | `766acc26f77abbcf6c19b9d1e4ba02042a31f14f70fdf62b53d71e6ea3965937` |
| `tests/scheduler/pool-claim.lisp` | `f968d57b6ff4dfc3cc31f1b1979afa896d95435093406b36320800783629901f` |
| `tests/scheduler/support.lisp` | `300234f9ac7931f8c8b9bf305498a2742a3b8868dd9158dbab8c7fdceed5a1e4` |
| `docs/implementazione/pool-worker-claim.md` | `20240f3011569792d86d0369e374b3e6c43dcac48192ea34c0fd37b54f211ef7` |
| `docs/implementazione/pool-worker-claim-metodo.md` | `aedfadbf875ef9b58ba54bc4b5269aba438983e53137c5c3eef645e1265f1e19` |

Il coupling C1 e il protocollo lifecycle sono stati verificati su queste
fonti preesistenti, senza modifiche nei relativi file:

| Fonte | SHA-256 |
|---|---|
| `src/execution/worker-types.lisp` | `62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317` |
| `src/execution/worker-boundary.lisp` | `4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a` |
| `src/execution/worker-claim.lisp` | `62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e` |
| `src/execution/ready-types.lisp` | `0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f` |
| `src/scheduler/lifecycle-worker.lisp` | `ec8b462ff3f5f7a6435f0f0c01b62034d8de2a784a9e354d469a0adfec9cf837` |
| `src/scheduler/lifecycle-read.lisp` | `c60e1d5f67eeafb216b374fa001d27f87d1a734c5d066fc092902c0301069200` |

## Rilievo corretto

La prima formulazione diceva che un worker inattivo non consultava ready
e che il ritiro precedeva ogni suo accesso. La funzione esegue invece
sempre `%richiedi-worker :idle` prima del lifecycle. Il verificatore C1
legge la dimensione del vettore delle partizioni, gli indici cursor/home
e il tipo delle due partizioni riferite dal contesto. Non legge head,
tail, count o slots del ring; non acquisisce una guardia e non cerca lavoro.

Il contratto e il metodo finali distinguono questa verifica della forma
immutabile da polling, scansione e mutazione dei ring. La docstring ora
promette la conservazione di ready/cursore. La rilettura conferma la
correzione; il corpo eseguibile del gate è rimasto invariato.

La versione precedente del gate aveva SHA-256
`37d8e2f60d7da8f5de1f5df6774bb2ac32e430771d370adc3689c25dd3222ddb`.
Le prime versioni di contratto e metodo avevano rispettivamente
`ee7cbc96be1e4a9895025ea4d9580dab034315c82786f27d8fe1015e4dbbec4e`
e `af28052c22ebe07e4d26d93d8ff618d960ea5221a80190436a51e606c08ac1df`.
Queste identità distinguono le formulazioni precedenti dalla lettura finale.

## Confine C3 e protocollo

Il gate controlla quando delegare una nuova presa. La porta contiene il
contesto immutabile, quindi il caller non può fornire separatamente un
contesto diverso. L'owner della porta precede ogni accesso al contesto;
il getter della fase verifica anche l'owner execution. Ogni fase non-IDLE,
compresa FAULTED, è rifiutata senza leggere una lease live, applicare un
comando o sostituire la prima causa del fault.

Sul contesto IDLE la barriera C1 completa precede il lifecycle anche quando
la porta è inattiva o request=ack. Il valore `:unchanged` non viene quindi
usato come prova di IDLE o salute. Dopo il gate, solo il ramo attivo chiama
`execution:prendi-writer-worker`, che conserva verificatori, trasferimento
dell'obbligo e confine di fault propri. Il nuovo file non scrive campi di
integrità C1 e non racchiude gli errori del pool in `%passo-worker`.

Le dipendenze private sono `%richiedi-worker` e la lettura del cursore
validato. Richiedono attenzione nelle future modifiche a execution: il
gate deve conservare l'ordine owner/fase/forma e la lettura senza mutazione.

Un ritiro pubblicato dopo la lettura active può lasciare partire un singolo
claim. Il comando resta pendente fino al ritorno a IDLE. Gli obblighi
CLAIMED, batch, FINISHING e RESCHEDULE continuano a usare le API esistenti;
un ring pieno può assegnare un nuovo writer e impedire ancora il ritiro.
Il contratto non promette convergenza sotto saturazione perpetua.

Il quarto valore conserva il dominio del lifecycle di base. Sul percorso
normale, esclusivo e IDLE, sono attesi `:unchanged`, `:activated` e `:retired`;
la dichiarazione ammette anche `:busy` e `:faulted` come l'API delegata.
Non viene attribuita a questi due valori una raggiungibilità nuova.

## Lista di controllo

I dodici punti della lista C1 sono usati come controllo aggiuntivo. Non
cambiano la classe C3 né costituiscono le due revisioni richieste a C1.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005 e REQ-AFF-008 coerenti con governo delle nuove prese, proprietà e limiti. REQ-THR-001 resta aperto per il motore completo. |
| 2. Invarianti | Owner prima dei campi, contesto associato alla porta, non-IDLE prima dell'ACK, IDLE C1 completo anche per porta inattiva, claim solo nel ramo active. Preservazione degli obblighi coperta nelle fixture lette. |
| 3. Errori | Ragioni typed per owner e fase; invarianti delegate senza occultamento. I rifiuti del gate non fanno poisoning C1. Gli errori del claim mantengono il confine execution. Nessun rollback dell'ACK dopo un claim fallito. |
| 4. Limiti | Nessun ciclo, ricorsione, attesa, syscall o retry nel gate. O(1) oltre ai verificatori C1; il solo ramo attivo delega la scansione bounded su al più 64 partizioni. |
| 5. Allocazione | Nessuna lista, closure o struttura creata esplicitamente nel gate; valori multipli. L'assenza di heap resta da misurare e non viene attestata dalla lettura. |
| 6. Risultati | Writer, esito e cursore del claim sono inoltrati senza reinterpretazione; inattivo restituisce NIL e cursore già validato. Quarto valore del lifecycle conservato; nessun valore d'errore ignorato. |
| 7. Decisioni | Due `unless` semplici e un `if`; nessun nuovo predicato composto. Complessità ciclomatica 4. MC/DC non richiesto a C3; copertura di espressioni e rami resta separata. |
| 8. Proprietà | Porta e contesto del worker non rientrante, ACK delegato al suo owner; request del coordinatore. Nessun nuovo stato globale o protocollo di sincronizzazione. |
| 9. Tracciabilità | REQ sulla funzione e nei nomi dei dodici test. ASDF carica il gate dopo execution/lifecycle e registra i test. Build, lint, trace e controllo completo non eseguiti dal revisore. |
| 10. Standard | Safety 3, ftype completo, docstring e commenti OWNER/SHARED; funzione di 18 righe. Nessun handler, cleanup, dichiarazione che rimuove controlli o deviazione individuata. |
| 11. Parallelismo | Nessuna scrittura globale per messaggio. ACK per ondata e ready partizionata, toccata dalla sola presa C1 attiva. La revisione non misura scalabilità, equità o progressione sotto carico. |
| 12. Durabilità | Nessun effetto su payload, CSN, file o controller Serie; nessun cambiamento durevole o eliminazione. Atomicità su disco non applicabile a questo gate. |

## Lettura delle prove nuove

Il file test contiene dodici prove nominate. Sono state lette come codice,
senza eseguirle e senza attribuire alla revisione il PASS riportato da altri.
Il caller usa writer e liste pronte reali; i claim riusciti sono verificati
con identità del writer e completamento attraverso le API execution.

| Gruppo di prove | Evidenza prevista dal codice e limite |
|---|---|
| Inattivo con lavoro pronto | Immagini di porta, contesto, ring e writer conservate; sentinella FI in `%prova-pronta` distingue nessuna scansione da scansione senza pop. |
| Crescita e ritiro reali | Controller e registro reali con owner distinti; crescita porta al claim di un writer già accodato, ritiro lascia il writer nel ring. |
| Owner e fasi | Owner estraneo prima di fase/parole corrotte; tutte le sei fasi non-IDLE conservano riferimenti, debito e prima causa, anche deliberatamente incoerenti. |
| IDLE e protocollo corrotti | FI quiescenti su cursor/home/writer/lease/pending/fault, quattro configurazioni active/request/ack e parole invalide. Immagini preservate prima dell'ACK/pop; nessun fault C1 aggiunto dal pool. |
| CAS della conferma | La fixture invoca il vero helper CAS con OLD errato; conta l'invocazione e verifica rifiuto senza pop, poi applica il comando originale. |
| EMPTY e BUSY | Esiti e rotazione del cursore verificati su shard reali; guardia occupata impedisce il claim e conserva il lavoro. |
| Comando tardivo | FI al confine dopo il vero campione active, prima del pop; un compito viene completato e il ritiro confermato alla presa successiva. L'interleaving è iniettato, non una gara casuale osservata. |
| Bridge e ring pieno | Pop sotto le due lease, conferma, chiusura e trasferimento esplicito dell'obbligo; ricircolo pieno restituisce un nuovo writer e il routing seleziona la sua Serie. |

Le FI che sostituiscono temporaneamente funzioni ripristinano le definizioni
con `unwind-protect` e dichiarano quiescenza. I bypass diretti di execution
nelle prove sono esplicitamente setup, drenaggio o cleanup C4; non sono
presentati come claim autorizzati da una porta inattiva. I payload sentinella
sono controllati nel buffer; ciò non qualifica effetti durevoli di operazioni
applicative. Il backend Serie in memoria non qualifica I/O nativo.

## Limiti dell'esito

La lettura non esegue build, lint, trace, test, self-test degli strumenti,
campagne di copertura o benchmark. Il gate C3 di almeno 95% su espressioni
e rami, la misura di heap e il controllo completo restano da attestare su
fonti congelate e output originali. La dichiarazione che l'ACK resta valido
se il claim successivo fallisce è verificata staticamente nell'ordine del
codice; nelle dodici prove lette non c'è una FI dedicata a quel preciso caso.

Non sono attestati wake/park, avvio graduale, worker morti, sensori,
coordinamento Archivio, admission dei messaggi, shutdown fisico o dispatcher
completo. QA-12/19 e il requisito di thread del motore restano aperti.
Nessun risultato di una revisione umana o qualifica formale è implicato.
