# Controllore locale dei worker di calcolo

Il componente `arcdocdb.scheduler` realizza una parte di REQ-THR-001:
propone un numero di worker usando EWMA, AIMD e isteresi. È governo delle
risorse di classe C3 secondo [ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md),
con limiti espliciti e tempo iniettato, REQ-AFF-008/013 e REQ-CON-005.
[ADR-0011](../adr/0011-thread-pool-dinamico.md) consente di partire con pochi
segnali; [il metodo preregistrato](controllore-pool-metodo.md),
[la lettura del codice](controllore-pool-revisione.md) e
[i risultati](controllore-pool-risultati.md) delimitano le prove.

Il [registro di attuazione logica](pool-worker-lifecycle.md) è il componente
successivo: collega questa politica alle conferme dei worker preesistenti.
Il controller da solo conserva il contratto e lo scope descritti qui.

Il controllore appartiene al thread che lo crea. Il solo scheduler legge e
aggiorna il suo stato; i getter rispettano lo stesso proprietario. Campioni,
worker effettivi e tick provengono dal caller. Non si legge il clock del
processo, non si raccoglie CPU o latenza e non si accede a writer, lista pronta,
Serie o richieste. Questa amministrazione è fuori dal percorso delle richieste,
come previsto dall'[elenco dello stato condiviso](../architettura.md#archivio-coordinamento-minimo).

| API | Contratto |
|---|---|
| `crea-controllore-pool cores &key minimum maximum initial period dwell queue-high` | Avvio sul thread proprietario; valida tutta la configurazione prima di costruire lo stato. Il target iniziale è nel budget. |
| `aggiorna-controllore-pool c tick queue cpu p99 actual` | Owner corrente; valida tutti gli input prima della mutazione. Restituisce target e `:hold`, `:pending`, `:grow` o `:shrink`. Ogni chiamata termina senza attese. |
| `leggi-controllore-pool c` | Owner corrente; restituisce sette valori: target, EWMA coda/CPU/P99 scalate, ultimo tick oppure NIL, candidato `:hold`/`:grow`/`:shrink`, origine della permanenza oppure NIL. Nessuna copia del controllore. |

## Domini e avvio

`cores` è un intero da 1 a 65536; `1 ≤ minimum ≤ maximum ≤ 2×cores`.
Il default di minimum è 1, quello di maximum è 2×cores, quello di initial è
minimum. Initial deve appartenere a minimum..maximum. Il tetto è quello del
pool di calcolo di [architettura](../architettura.md#thread-pool), non una
raccomandazione di usare sempre il massimo e non un tetto del pool di I/O.

Period è da 1 a 2^20, default 500; dwell è da period a 2^20, default 2000;
queue-high è da 1 a 2^20, default 8. Il caller assegna un'unità coerente ai tick,
a period e a dwell. I default non fissano millisecondi né una calibrazione.

Un campione contiene tick da 0 a 2^40−1, queue da 0 a 2^20, CPU da 0 a 1000
permille, P99 da 0 a 10000 permille del target di latenza e actual da minimum
a maximum. Il pool è quindi già avviato con un numero confermato di worker:
actual=0 è rifiutato. P99=1000 significa raggiungere il target di latenza.
La scelta del target, i sensori e l'aggregazione delle metriche restano al
caller; il componente non realizza REQ-OBS-001/002.

Dopo il primo campione il tempo deve avanzare almeno di period. Tick
duplicati, regressivi o troppo ravvicinati sono rifiutati senza cambiare
sensori, candidato o target. Tick non fa wrap; raggiungere il suo massimo
non autorizza a riutilizzare zero sullo stesso controllore.

## EWMA e decisione

I tre sensori hanno scala 256. Il primo campione inizializza `E=256×x`;
i successivi aggiornano `E=floor((7×E+256×x)/8)`. Alpha è 1/8 per campione,
con arrotondamento verso il basso. Il numero di bit degli interi resta
limitato dal dominio, senza crescita di denominatori razionali. Un salto
di tempo maggiore di 2×period inizializza di nuovo i sensori dal campione
corrente e azzera la permanenza: un intervallo senza campioni non attesta
carico stabile. La soglia di 2×period è inclusiva per continuare la EWMA.

La riduzione ha precedenza sulla crescita. Le soglie si applicano alle EWMA
scalate, non ai soli input istantanei:

| Candidato | Condizioni |
|---|---|
| `:shrink` | P99≥1200×256, oppure coda<256 e CPU≤300×256. |
| `:grow` | Coda≥queue-high×256, CPU<700×256 e P99≤1000×256. |
| `:hold` | Altri casi. |

Il primo campione con un candidato registra il tick di inizio. Cambiare
direzione o tornare hold azzera la permanenza. La stessa direzione deve
durare almeno dwell: alla soglia inclusiva la crescita è target+1, limitata
a maximum; la riduzione è floor(3×target/4), limitata a minimum. Dopo un
cambiamento serve una nuova permanenza per agire ancora. Una direzione che
non può cambiare il target perché è già al limite restituisce hold e non
crea un comando senza effetto.

Se actual è diverso dal target, i sensori si aggiornano ma l'esito è
`:pending`: il target resta identico e la permanenza viene azzerata. Quando
actual raggiunge target, il candidato riparte dal nuovo campione; il tempo
passato pending non contribuisce all'isteresi. Il caller conferma soltanto
worker effettivamente attivi, senza assumere che un target sia già applicato.

## Errori e confini

Owner estraneo, configurazione errata o campione fuori dominio producono
`invalid-argument` con le ragioni seguenti:

| Controllo | Ragione |
|---|---|
| Thread estraneo, in getter e aggiornamento | `:pool-owner` |
| Factory: cores, minimum, maximum, initial | `:pool-cores`, `:pool-minimum`, `:pool-maximum`, `:pool-initial` |
| Factory: period, dwell, queue-high | `:pool-period`, `:pool-dwell`, `:pool-queue-threshold` |
| Campione: tick, queue, CPU, P99, actual | `:pool-tick`, `:pool-queue`, `:pool-cpu`, `:pool-p99`, `:pool-actual` |
| Tick duplicato, regressivo o troppo ravvicinato | `:pool-sample-period` |

Input e proprietario sono verificati prima delle scritture; un rifiuto
ordinario non applica un prefisso dell'aggiornamento. Il verificatore privato
controlla target fra minimum e maximum e origine della permanenza non
successiva all'ultimo tick; incoerenze producono `invariant-violation`
`:pool-state`. I domini degli altri slot sono protetti dai tipi e dalla
factory. Non è promessa la rilevazione di ogni modifica arbitraria della
rappresentazione privata, né una riparazione o un rollback al guasto.
Il componente non registra un FAULTED della Serie perché non possiede né
accede a una Serie.

Una crescita pending non viene revocata se la latenza peggiora. Non c'è un
timeout dell'attuatore nel controllore: pending può durare per un numero
arbitrario di chiamate brevi. Il caller deve diagnosticare un target non
applicato e governare errore o scadenza dell'attuatore. Revoca, precedenza dei
comandi e rifiuto di comandi obsoleti richiedono il futuro protocollo del pool.

Il calcolo normale è O(1), con strutture allocate soltanto dalla factory,
senza thread nuovi, attese, lock, I/O, callback o scritture condivise per
richiesta. Controllore e getter non creano, parcheggiano, risvegliano o
ritirano worker. Un target è una proposta: non trasferisce obblighi, lease
o batch e non cambia dati o stato di una Serie.

Pool vivo, wake senza notifiche perse, admission, retirement, shutdown,
coordinatore Archivio, pool di I/O, compaction, metriche reali e calibrazione
rimangono da integrare. EMPTY/BUSY della lista pronta non sono una prova di
quiescenza per dormire o arrestarsi; i [contesti worker](writer-worker.md)
rimangono sul thread creatore e conservano gli obblighi ancora posseduti.
Questa policy non promette equità, P99, throughput, scalabilità o stabilità
del feedback reale. RSK-12 e i gate del motore restano aperti; gli stati
globali dei requisiti restano `progettato`.
