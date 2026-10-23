# Attuazione logica del pool di worker

Il registro di `arcdocdb.scheduler` collega il [controllore EWMA/AIMD](controllore-pool.md)
a worker preesistenti, ciascuno proprietario del proprio contesto writer. La crescita
e il ritiro diventano richieste persistenti; il numero effettivo cambia soltanto
quando il worker conferma. È un incremento C3 di REQ-THR-001, REQ-CON-005 e
REQ-AFF-008/013 secondo [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md).
La [metodologia](pool-worker-lifecycle-metodo.md) preregistra le prove; la
[revisione indipendente](pool-worker-lifecycle-revisione.md) e
[i risultati](pool-worker-lifecycle-risultati.md) delimitano l'evidenza disponibile.

## Confine e proprietà

Il coordinatore possiede un controller e un registro, in modo esclusivo e non
rientrante. Ogni worker crea sul proprio thread un contesto e una porta; il caller
pubblica queste porte al coordinatore tramite un handshake di avvio. La factory del
registro copia il vettore, verifica tutti gli elementi e poi lega permanentemente
le porte. Un controller è usato in un solo registro; dopo il collegamento si aggiorna
esclusivamente tramite `aggiorna-registro-pool`. Il getter originale resta utilizzabile.
Il caller non accede alla rappresentazione privata né riutilizza una porta in un altro
pool. Crea una sola porta operativa per contesto e mantiene il vettore di input
esclusivo durante la factory. La factory rifiuta il secondo binding delle porte;
non rileva duplicazioni di nuove porte dello stesso contesto fra registri differenti.

Il vettore contiene esattamente `controller.maximum` porte con owner distinti. I
worker attivi iniziali sono il prefisso di lunghezza `controller.target`; gli altri
sono già creati ma logicamente inattivi. Tutti iniziano con generazione zero e stato
confermato, senza comando pendente. La costruzione alloca; i passi successivi usano
solo parole fixnum, valori multipli e scansioni bounded. La deduplicazione usa un hash
EQ all'avvio, evitando ricerche quadratiche.

`actual` conta **attivazioni logiche confermate**, non thread OS, worker sani, epoche
o richieste. Il worker usa il Boolean restituito dal proprio passo per decidere se
può iniziare altri compiti. Un dispatcher deve rispettare quel Boolean: le API
execution esistenti non consultano la porta. Non sono introdotti spawn, join, kill,
attese, semafori, mutex, clock reali o callback nel codice di prodotto. Thread e
contesti inattivi restano disponibili per il riuso.

La conferma avviene tra compiti a completamento, senza epoche di lettura né risorse
esterne al contesto writer. Il verificatore C1 esistente
`execution::%richiedi-worker :idle` è chiamato soltanto in lettura; controlla owner,
stato, riferimento al writer, lease e debito batch. L'attuatore non modifica writer,
ready, Serie o bridge. Nessuna nuova barriera d'integrità viene affidata a C3.
Questo confine rispetta [ADR-0045](../adr/0045-modello-di-esecuzione.md): non sospende
un compito e non esegue chiamate bloccanti.

## API

| API | Risultato e obblighi |
|---|---|
| `crea-porta-worker-pool context &key coordinator active` | Sul thread owner, contesto IDLE verificato; default coordinator corrente e active=T. Costruisce una porta con stato iniziale già confermato. |
| `crea-registro-pool controller ports` | Sul coordinatore del controller; vettore semplice della capacità esatta, porte owner distinti, prefisso attivo conforme e stabile. Copia privata e binding solo dopo la validazione completa. |
| `applica-stato-worker-pool port` | Sul worker owner. Restituisce active confermato e `:unchanged`, `:activated`, `:retired`, `:busy` oppure `:faulted`; massimo un comando applicato. |
| `leggi-registro-pool registry` | Sul coordinatore. Restituisce actual, target e pending senza copia heap. La scansione è progressiva durante le conferme concorrenti. |
| `aggiorna-registro-pool registry tick queue cpu p99` | Sul coordinatore. Restituisce target, azione del controller, actual letto prima del campione e pending conservativo. Tempo e metriche restano iniettati. |

Non c'è comando da applicare quando request=ack: il passo restituisce `:unchanged`
senza ispezionare lo stato execution; questo esito non certifica salute né IDLE.
Quando c'è un comando, CLAIMED, RUNNING,
BATCH, FINISHING e RESCHEDULE producono `:busy`; FAULTED produce `:faulted`.
In entrambi i casi il comando resta pendente e contesto, lease e diagnostica restano
intatti. Un contesto che dichiara IDLE ma ha obblighi incoerenti fallisce nella
barriera C1 prima della conferma.

## Protocollo e concorrenza

Ogni porta ha due parole atomiche: `request` del coordinatore e `ack` del worker.
La codifica è `2 × generation + active-bit`, con generation da zero a
`floor(most-positive-fixnum/2)`. Una sola richiesta può essere pendente. Il coordinatore
pubblica con barriera release e CAS; il worker legge acquire, controlla IDLE e
pubblica ack con release/CAS. Il coordinatore legge ack acquire. Il solo writer di
ciascuna parola è il suo proprietario; nessun retry CAS o ciclo di attesa è necessario.

Una nuova richiesta cambia il bit active e incrementa generation di uno. Porte
già nello stato desiderato non ricevono comandi. Il target seleziona sempre un
prefisso, quindi ogni ondata contiene soltanto attivazioni oppure soltanto ritiri.
Il prefisso minimo resta sempre attivo. Finché resta un comando pendente,
actual differisce dal target e il controller conserva la proposta con `:pending`.
Il tempo passato ad attendere conferme non matura una nuova isteresi.

Le conferme possono arrivare fuori ordine: durante la crescita, un worker successivo
può attivarsi prima del precedente. Il prefisso vale per le request; non è richiesto
agli ack intermedi. Il getter restituisce un conteggio progressivo, conservativo
rispetto al completamento dell'ondata. Se pending=NIL, tutte le conferme lette sono
uguali alle richieste correnti e actual=target. Il wrapper può restituire pending=T
anche se l'ultima conferma arriva subito dopo la lettura.

L'invariante delle parole ammette request=ack, oppure una generazione di differenza
con bit active diverso. Un comando regressivo, un salto di generazione o un comando
senza cambio di stato è rifiutato. Nessuna generation fa wrap o viene azzerata.
Prima di aggiornare un controller stabile si verifica il budget di generazione di
tutte le porte: l'esaurimento è un rifiuto conservativo anche per un campione hold.
L'esaurimento richiede la sostituzione amministrativa del componente; non autorizza
a resettare contesti o abbandonare comandi. Ogni preflight precede le scritture del
campione e delle request, evitando applicazioni parziali per errori ordinari.

Il registro ha costo O(maximum) per lettura/aggiornamento; il worker fa un passo O(1),
oltre alla barriera C1 bounded. Le scritture condivise avvengono per campione e per
conferma, fuori dalle operazioni della Serie, senza un contatore globale caldo.
Rispetta quindi INV-P6 e l'[elenco di stato condiviso](../architettura.md#archivio-coordinamento-minimo).

## Errori

| Condizione | Ragione |
|---|---|
| `invalid-argument` | `:pool-owner` per coordinatore invalido/estraneo; `:pool-worker-owner` per owner del passo estraneo; `:pool-active` per Boolean invalido. |
| `invalid-argument` | `:pool-ports` per vettore/capacità/elemento/owner duplicato; `:pool-binding` per una porta già legata; `:pool-port-state` per startup non stabile, non iniziale o prefisso errato. |
| `invariant-violation` | `:pool-port-state` per parole o richieste incoerenti; `:pool-state` per target/controller/capacità o conteggio privato incoerenti. |
| `resource-exhausted` | `:pool-generation` per budget di comando esaurito, senza mutazione. |
| Verificatori delegati | Factory e passo propagano le condizioni execution; il wrapper propaga i rifiuti di campioni del controller. |

Un comando bloccato da FAULTED resta diagnosticabile. Il coordinatore deve gestire
il guasto dell'Archivio e la mancata progressione; il componente non libera risorse
o decrementa un conteggio per nascondere il problema. Non ci sono handler generici,
cleanup che occultano errori o policy di recovery implicite.

Un conflitto CAS viola l'esclusività dei proprietari ed è un'invariante terminale,
non un rifiuto ordinario recuperabile. La pubblicazione di un'ondata può essere
parziale in questo caso; non si continua a usare il registro. Il passo non attesta
una conferma fallita, e nessuno dei campi d'integrità C1 viene modificato.

## Integrazione ancora richiesta

La [presa governata dal pool](pool-worker-claim.md) rispetta active e collega il
passo IDLE alla presa C1. REQ-THR-001 resta progettato a livello del motore completo.
Mancano dispatcher del server, sensori e coordinamento dell'Archivio, avvio graduale dei thread,
risveglio persistente dalla ready, gestione del guasto del pool e arresto fisico.
Il componente non qualifica un'attesa idle nativa, il pump di risveglio, il numero
di thread da avviare sull'hardware o la latenza end-to-end. QA-12/19 restano aperte.
