# M1 — Single-Series Durable Core

Milestone [Production Engine Bootstrap](https://github.com/gpicchiarelli/ArcDocDB/milestone/1).
Il [metodo preregistrato](production-engine-bootstrap-metodo.md) concentra il lavoro
sul percorso esistente, senza nuove funzionalita' full text o una roadmap parallela.

## Ingresso di produzione

```lisp
(arcdocdb.engine:apri-motore directory archive-uuid series-uuid
 :create t :clock #'get-internal-real-time)
;; Restituisce soltanto un motore READY, altrimenti segnala una condizione.
```

La directory privata deve esistere. `:create t` e' un'inizializzazione
esplicita, ammessa solo se vuota; l'apertura normale non crea file mancanti
o sovrascrive uno storage esistente. I due UUID sono octets di sedici byte,
copiati e confrontati con gli header canonici. Un solo attore I/O seriale
possiede l'handle e tutti i FD: nessuna chiamata da altro thread o reentrata
durante una richiesta, neppure dai callback d'osservazione.

L'esclusione advisory non bloccante e' acquisita sul FD della directory,
prima di osservare o mutare lo storage, e dura fino al suo close. Tutti gli
scrittori M1 devono usarla; non protegge da processi ostili che ignorano flock
o dalla sostituzione esterna degli antenati del path. La directory privata
e l'assenza di mutatori esterni restano precondizioni.

`apri-motore` possiede l'intero ciclo:

1. Configurazione, risorse private, apertura parent e lock esclusivo.
2. Eventuale init con i preparatori ACTIVE/CONTROL e header decision log canonici.
3. CONTROL e inventario completi, fonti readonly possedute, reader semantici
   e gate Archivio/CSN prima degli effetti.
4. Completamento dei nomi gia' decisi, ID fresco dal planner e nuovo ACTIVE
   durevole. Il publisher esistente rinomina CONTROL e sincronizza il parent:
   questo resta il punto di atomicita' del recovery della Serie.
5. Nuova lettura canonica, massimo CSN invariato, tutti i nomi completati.
6. Runtime canonico a M, mappe CLOSED dello stesso FD, replay dell'indice
   privato, adozione del nuovo ACTIVE e radice GET completa.
7. Solo infine READY: nessun gate simulato nel test o nel futuro trasporto.

Il nuovo ACTIVE viene preparato nella vista del recovery, richiesto dal
publisher CONTROL. Dopo la decisione il wrapper del runtime rilegge il
medesimo header/FD, conserva log e associazione fisica e usa il registro
canonico del nuovo ambito. Nessun file viene preparato due volte o riaperto
in scrittura. Le fonti e i FD pregressi restano posseduti fino al close.

## Richieste e conferma

```lisp
(arcdocdb.engine:scrivi-documento engine key encoded-value) ; CSN u64 strong
(arcdocdb.engine:leggi-documento engine key output :start 0) ; :found/:absent, byte
(arcdocdb.engine:cancella-documento engine key)              ; tombstone strong
(arcdocdb.engine:chiudi-motore engine)
```

Le chiavi e i valori sono byte delle cornici canoniche. Il nucleo di
persistenza M1 non aggiunge Query Engine, estrazione CBOR o validazione del
documento applicativo. La sessione Unix dovra' applicare il suo contratto
documentale prima dell'ammissione. Nessun decoder o formato alternativo.

Il writer riusa lotto, gruppo e scratch. Preflight di formato/capienza prima
del CSN, inclusi load, arena chiavi, credito slot e revisione dell'indice.
Il preflight canonico non muta l'indice e non prenota risorse concorrenti:
vale per l'unico owner M1, senza altro mutatore fino all'applicazione.
Un limite prevedibile dell'indice lascia READY, CSN e file invariati;
update e tombstone ammissibili restano utilizzabili, anche dopo reopen
con gli stessi budget. DELETE non recupera byte dell'arena append-only.
Una salute/invariante dell'indice guasta chiude invece admission anche se
rilevata nel preflight, conservando la causa e senza append o consumo CSN.
Seguono SEAL, write, flush, pubblicazione canonica della radice e
risoluzione del CSN, indice e ritiro dei riferimenti. La conferma esce solo
alla fine. Radice prima dell'indice e' corretta solo con l'attore M1 seriale:
GET concorrenti e MVCC storico non sono esposti. Una perdita della risposta
puo' lasciare un esito ignoto; non si ritenta automaticamente.

Il replay attraversa solo prefissi CLOSED verificati dalle API esistenti,
richiede CSN ordinari strettamente crescenti e considera anche le tombstone.
Un conflitto o un dato corrotto chiude il bootstrap. Il massimo non deriva
da ID segmento, offset o stamp CONTROL. Il contesto CSN zero dell'ispezione
non ha writer: il solo registro operativo e' quello creato dal piano finale.

## Errori, risorse e limiti M1

Startup, recovering, faulted e closed rifiutano richieste. Una richiesta
ammessa incompleta rende FAULTED e conserva la causa, senza conferma,
rollback o riuso dei buffer incerti. Il close chiude admission prima delle
risorse; tutti i set e FD ricevono un tentativo, parent ultimo. Gli errori
secondari sono conservati, il fallimento startup aggrega eventuali cleanup
senza perdere la primaria. Il thread owner non viene cancellato asincronamente;
SIGKILL termina il processo e il kernel rilascia i descrittori/lock.

I segmenti preesistenti sono sempre readonly. Code senza SEAL, temporanei
orfani e CONTROL non pubblicati sono conservati; gli ID osservati non sono
riusati. `control.log.tmp` pregresso viene spostato sotto nome distinto senza
sostituire un target presente, poi fsync parent. Un definitivo inatteso e'
un'anomalia bloccante: non viene eliminato. Non si implementa garbage collection
degli orfani; budget esaurito richiede un intervento esplicito, senza perdita silenziosa.

M1 configura esattamente una Serie e decision log senza DECISION; non scopre
il catalogo multiserie. Prepared, compaction/REMOVED e location oltre u32
sono rifiutati. Il formato resta v1/v2; questa e' una restrizione dell'ingresso,
non una modifica dei tipi storage u64. Ogni reopen prepara un nuovo ACTIVE.
La rotazione a caldo non e' esposta: al limite il nucleo rifiuta nuove scritture.

Default: file 16 MiB, cornice 64 KiB, 64 segmenti, 65.536 record per file,
indice di capacita' 4096 e arena chiavi 1 MiB. Budget configurabili e
controllati, senza clamping. Non sono limiti del formato definitivo ne'
misure di prestazione. Startup, indice, radici e runtime possono allocare;
ottimizzazioni, budget heap/GC e qualifica COD-30 completa restano fuori M1.

## Verifica del percorso reale

La campagna preesistente resta distinta dalla nuova suite di produzione:

- `tools/vertical-crash.lisp --self-test`: 18 scenari, 71 processi,
  26 SIGKILL intenzionali e due negativi, con sintesi derivata dagli eventi.
- `tools/engine-crash.lisp --self-test`: usa soltanto apertura e richieste
  del motore nei figli; nessun checkpoint, replay, scelta ID o reset CSN nel
  test. Due SIGKILL e riavvio per v1/v2, piu' crash durante recovery,
  coda incompleta, errori dichiarati, admission e oracolo negativo.

I comandi passano dal recorder. Test e diagnosi sono distinti da benchmark,
qualifica C1/MC/DC, power loss, Linux non eseguito e guasti permanenti del
disco. P3 usa ora il [servizio Unix di produzione](production-unix-m1.md)
su questo ciclo qualificato; il modello PING di SPK-11 resta un esperimento.

## Evidenze del nucleo

Il [rapporto con originali e sintesi strutturate](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-production-engine-bootstrap/report.md)
lega le prove al sorgente `73436eac`: 2164/2164 casi in 51 suite senza
esclusioni, 15 test engine, 80 dell'indice primario e due negativi sul writer
precedente. La campagna engine dedicata osserva 31 processi e 22 SIGKILL;
quella verticale preesistente 71 processi e 26 SIGKILL. Le ripetizioni nel
catalogo completo non sono sommate a questi conteggi.

P0 e il nucleo P1–P2 sono verificati nel modello dichiarato. Il
[rapporto P3](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md)
verifica ora il percorso Unix reale su `11d2e95a`: 2215/2215 test, 74 processi
locali, quattro SIGKILL e perdita dell'ACK dopo commit strong. Il validatore
opzionale dei record applicativi rifiuta dati incompatibili prima del checkpoint.
La matrice FI completa e il gate di fase restano aperti. Nessun benchmark o
qualifica C1/MC/DC/power loss e' dedotto dai passaggi funzionali.
