# Revisione indipendente dell'attuazione logica dei worker

Lettura statica del 2026-10-13 sulla base
`105ae0dd28a6ae3e7ee60ab1477815a49b1b350b`, eseguita da un agente diverso
dall'autore dei sorgenti. Esito della lettura finale: **positivo per lo scope
C3**, dopo le due correzioni descritte sotto. Questo esito non attesta build,
test, copertura, misura heap o qualifica del motore.

Sono stati letti integralmente i cinque nuovi sorgenti lifecycle, package e
integrazione ASDF, il [contratto](pool-worker-lifecycle.md) e il
[metodo preregistrato](pool-worker-lifecycle-metodo.md). Sono stati riletti
controllore, verificatore IDLE, claim/cessione del worker e bridge worker/Serie;
ADR-0011/0031/0035/0045, invarianti e
[standard di codifica](../affidabilita/standard-di-codifica.md) delimitano la
valutazione. Il revisore non ha eseguito compilazione, test o benchmark e non
ha modificato sorgenti, test, ASDF, contratto o Git.

Prima del congelamento è stata riletta l'integrazione sulla base
`c4bbb037b779d33ee9e8c01b4a33aac875ccf96f`, dopo l'inclusione dei float CBOR
e delle evidenze precedenti. Sono stati riletti integralmente ASDF,
README dell'implementazione e contratto corrente. L'ordine execution,
controllore e lifecycle e la registrazione dei test scheduler sono
preservati; la nuova voce README rimanda al contratto e al sorgente corretti.
Il contratto mantiene invariato il proprio SHA. La tabella seguente riporta
l'identità dell'ASDF integrato, senza attribuire a questa revisione la
qualifica dei nuovi componenti codec.

## Identità dei file della lettura finale

| File | SHA-256 |
|---|---|
| `src/scheduler/lifecycle-types.lisp` | `4fe980e00f1d273e9b8278cd2daace6b4a9e4ab948ddfac83b79f4b0c537cb7c` |
| `src/scheduler/lifecycle-read.lisp` | `c60e1d5f67eeafb216b374fa001d27f87d1a734c5d066fc092902c0301069200` |
| `src/scheduler/lifecycle-build.lisp` | `d6d67faf8721f26e7fcd228d6ab9a7dfdc36ff5ec56c67ed9e5fb6d914006a9e` |
| `src/scheduler/lifecycle-worker.lisp` | `ec8b462ff3f5f7a6435f0f0c01b62034d8de2a784a9e354d469a0adfec9cf837` |
| `src/scheduler/lifecycle-update.lisp` | `2020e46809e9fe8fa74e061a420b8085679d5f461eabd8b044f3975c1024800e` |
| `src/scheduler/package.lisp` | `5a139172de1648b30e09fdc6fc068141299c2034702f8d5b5f44bb0de14a3112` |
| `arcdocdb.asd` | `a81c523ececccd4f1f5deaea037cfa419738c881ef37a89f7869f18f6becc7db` |
| `docs/implementazione/README.md` | `b863d42ce333caa19e9e87c9b67d8b12472aba47d2586d0681ff56df445a7aba` |
| `docs/implementazione/pool-worker-lifecycle.md` | `39c95f21b87752208b77844bca26092a4cd9f4f45900a04ead6c3ed42b10dba4` |
| `docs/implementazione/pool-worker-lifecycle-metodo.md` | `e529f3c3959b8143b099febef773ebc880aeae0424c01e3ddec89583d2d3615b` |

## Rilievi corretti prima dell'esito positivo

1. **Valore dei CAS non verificato, COD-23.** Nella prima versione i CAS di
   request e ack ignoravano il valore restituito; un conflitto inatteso
   poteva essere seguito da un falso successo. L'autore ha introdotto
   `%pool-request-command` e `%pool-ack-command`: entrambi verificano il
   valore atteso e segnalano `invariant-violation :pool-port-state`.
   La rilettura conferma la correzione. Non è un retry: un conflitto rompe
   l'esclusività e impone di interrompere l'uso del componente; un'ondata
   parzialmente pubblicata non viene annullata. Nessun campo C1 è toccato.
2. **Complessità della validazione startup, COD-13.** La prima
   `%pool-validate-ports` raggiungeva complessità ciclomatica 11 contando
   il ciclo e i cortocircuiti Boolean. L'autore ha estratto
   `%pool-startup-owner`; forma/capacità e deduplicazione rimangono nel
   validatore. Entrambi i corpi sono ora sotto il massimo di 10 percorsi
   indipendenti. Il contratto startup e il binding dopo validazione
   completa sono preservati.

Le identità precedenti erano `ee00fa5436a02bd467368b7eb199f1e1364826c1f01257f731e323ccb4da051f`
per lifecycle-worker, `ef52c911164e7dfe7f0ab0a8d90e5bfc9583a9725de5c546e01639ab76217bf9`
per lifecycle-update e `5fec1f6e81fc7f1d87e15e4cdcf7904fb9bb75ecb08d92ccc5596e9181a35191`
per lifecycle-build. Non sono le versioni approvate dalla lettura finale.

## Classificazione e barriere

Il componente resta C3 secondo ADR-0031: decide l'abilitazione logica e
conta conferme, senza modificare dati, code ready, writer, lease, debiti,
bridge o controller Serie. La barriera C1 esistente
`execution::%richiedi-worker :idle` è chiamata soltanto in lettura prima
di una conferma; non è sostituita da un predicato C3 più debole. L'ack
packed è esso stesso lo stato active: non esiste una seconda copia da
sincronizzare. La chiamata factory verifica IDLE prima della costruzione.

Il dispatcher deve rispettare il Boolean confermato e non iniziare nuovi
compiti su una porta inactive. Senza questa cooperazione le API execution
restano utilizzabili: il nuovo componente non promette un pool esecutivo
completo. Epoche o risorse esterne al contesto devono essere già rilasciate
dal caller; il verificatore IDLE non può attestarle. Il bridge va usato
senza bypass delle API sottostanti durante un tratto.

## Lista di controllo

I dodici punti C1 sono impiegati come lista aggiuntiva; non cambiano la
classe né trasformano questa lettura nella qualifica richiesta a C1.

| Punto | Valutazione statica e limite |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-001/002/004/005, REQ-AFF-008/013 indicano adattamento, barriera del worker, parallelismo, limiti e ingressi iniettati. REQ-THR-001 resta progettato per il motore completo. |
| 2. Invarianti | Owner/coordinatore immutabili; request e ack non negativi entro fixnum; una sola generazione pendente con bit diverso; capacità uguale al maximum; request a prefisso e minimo sempre attivo. Il conteggio usa ack, non invio del comando. |
| 3. Errori | Ragioni tipizzate per owner, input, binding, parole, target e generazione. Rifiuti ordinari precedono binding o campione; conflitto CAS è un'invariante terminale. Nessun handler generico, rollback o errore occultato. |
| 4. Limiti | Cicli bounded dal vettore di massimo 131072 porte, nessuna ricorsione, attesa, syscall, callback o retry CAS. Worker O(1) oltre al controllo C1 bounded; lettura/aggiornamento O(maximum). |
| 5. Allocazione | Hash, copia e strutture solo in startup. Nei passi non compaiono liste, closure o strutture nuove; preflight mantiene l'aritmetica packed entro fixnum. Zero heap osservato resta da misurare, non è dedotto dalla lettura. |
| 6. Risultati verificati | Getter e wrapper controllano owner, legame, parole, prefisso delle request e conteggio. `:unchanged` legge soltanto la conferma precedente: non attesta salute o IDLE. Nessun dato applicativo viene restituito. |
| 7. Decisioni | Predicati composti circoscritti a parole, startup, legame e intervallo del conteggio; inventario sotto. Per C3 non è prescritto MC/DC. Copertura dei file completi e forme generate ancora da eseguire. |
| 8. Proprietà | Request/binding del coordinatore, ack del worker; barriere read/write e CAS verificati. Accessi non rientranti, handshake startup esplicito, vettore privato dopo copia. Nessuno stato globale mutabile nuovo. |
| 9. Tracciabilità e verifica | REQ su definizioni; ASDF carica lifecycle dopo execution e controllore e include il file test lifecycle. Test e campagne non eseguiti dal revisore; gate C3 almeno 95% di istruzioni/espressioni e rami resta pendente. |
| 10. Standard | Safety 3, ftype completi per le 13 funzioni, slot typed/read-only dove immutabili, copier NIL, docstring, OWNER/SHARED. Funzioni entro 60 righe e complessità sotto 10 dopo estrazione. Lint e compilazione restano verifiche separate. |
| 11. Parallelismo | Parole indipendenti per worker, scritture per campione/conferma fuori dal corpo delle operazioni della Serie. Nessun lock o contatore globale sul percorso di una richiesta. Non si misura qui scalabilità o equità. |
| 12. Durabilità | Nessun file, cambiamento durevole, effetto sui payload, CSN o controller Serie. I CAS sono punti di pubblicazione in memoria, senza atomicità su disco da rivendicare. |

## Inventario del protocollo letto

| Confine | Decisioni ed effetto |
|---|---|
| Parole | Uguali, oppure generation request=ack+1 con bit diverso; ogni altro caso è invariante. |
| Porta startup | Coordinator thread valido, Boolean valido e contesto IDLE completo prima di costruire. |
| Registro startup | Vettore semplice di capacità esatta; porta/coordinatore validi, bound falso, generation zero, request=ack, prefisso corretto e owner distinti prima del binding. |
| Registro vivo | Owner corrente, controller/target/capacità coerenti, request a prefisso; actual da ack entro minimum..maximum e pending da ogni disuguaglianza. |
| Applicazione | Owner prima di ogni accesso; nessun comando restituisce unchanged. Un comando su faulted/busy conserva entrambi i word; IDLE completo precede CAS ack e risultato activated/retired. |
| Budget | Quando pending è falso, tutte le generation devono avere spazio prima del campione; esaurimento rifiutato anche per hold. Pending non crea un'altra ondata. |
| Pubblicazione | Solo porte con bit da cambiare ricevono generation+1; CAS verificato, target locale aggiornato dopo la pubblicazione. Nessun comando identico sovrascrive un pending. |
| Wrapper | Delega il campione al controllore esistente; target diverso pubblica una sola ondata e pending conservativo. Metriche e tick invalidi non pubblicano request. |

Le letture request/ack non richiedono uno snapshot atomico di tutto il
pool: nel coordinatore request resta stabile durante la scansione; nel
worker ack ha un solo writer locale non rientrante. Un'ondata cambia tutti
i bit nella stessa direzione, quindi gli ack possono arrivare fuori ordine
e il conteggio osservato resta monotono. I buchi nel prefisso degli ack
intermedi sono leciti. Se pending è falso, tutte le parole lette coincidono
e actual=target; un pending già osservato può invece restare vero dopo una
conferma sopraggiunta. Il wrapper non presenta actual come misura della
salute dei worker o del numero di thread OS.

## Obblighi residui e verifiche mancanti

Un controller appartiene a un solo registro; dopo il binding viene
aggiornato esclusivamente tramite il wrapper. Una sola porta operativa
per contesto, anche fra registri differenti, rimane obbligo del caller:
bound impedisce il riuso della stessa porta, non individua nuove porte
duplicate. Startup e vettore di input restano esclusivi fino alla factory;
la pubblicazione fra owner richiede l'handshake documentato.

FAULTED conserva il comando e può bloccare l'ondata indefinitamente in
tempo esterno; ogni API resta bounded. La risposta del coordinatore al
guasto, il dispatcher, avvio/arresto fisico, park/wake, I/O, sensori reali
e taratura non sono realizzati. Nessun timeout nativo o garanzia di
progressione del motore è attestato da questa revisione.

Prima della qualifica conservare risultati eseguibili per owner errato,
startup invalido senza binding parziale, copia dell'input, stati execution
non IDLE senza perdita di capacità, word incoerenti/esaurimento, conflitti
dei due helper CAS, ack fuori ordine e campioni invalidi senza mutazione.
Le prove concorrenti richiedono deadline nel solo harness. Build, lint,
trace/check, copertura completa dello scope, self-test C4 e misura heap
restano pendenti al termine di questa lettura: nessun loro risultato è
stato assunto o promosso a PASS.
