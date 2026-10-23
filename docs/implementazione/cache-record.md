# Cache dei record per Serie

## Contratto

`arcdocdb.cache` implementa la partizione in memoria prevista da
[ADR-0025](../adr/0025-cache-per-location.md) e
[ADR-0044](../adr/0044-cache-acceleratore-puro.md): classi di dimensione,
insiemi di otto posti, sostituzione CLOCK, ricerca senza lock e inserimento
opportunistico. La chiave è la location fisica, non l’`_id`.

Requisiti: REQ-CCH-001, REQ-CCH-002, REQ-CCH-004, REQ-AFF-002,
REQ-AFF-008, REQ-OBS-002. Invarianti: INV-A2, INV-A8, INV-A12, INV-M3,
INV-P5, INV-P6. La politica CLOCK è C3; copia e verifica sono C1.
L’implementazione è disponibile; la qualifica concorrente resta aperta.

La cache non determina visibilità o commit. Il chiamante risolve prima
la versione committed nell’indice, sotto il
[contesto di lettura](compiti-lettura.md); passa location, lunghezza,
chiave, CSN, flag e versione di formato. Dopo il risultato completa il
controllo dello snapshot. La cache non conserva file, epoche, snapshot,
root dell’indice o riferimenti ad altre Serie.

## API

```lisp
;; Configurazione del controller, fuori dal percorso delle richieste.
(crea-cache-serie sizes counts budget-payload :stripes 16)
(payload-cache-serie cache)

;; Location: segment-high/segment-low u32, offset u32; CSN: due u32.
(cerca-record-cache cache segment-high segment-low offset record-length
                    key csn-high csn-low flags destination start
                    :version 2 :proof-buffer proof
                    :proof-start ps :proof-end pe)
;; => :hit | :miss | :verify-failed, value-start, value-end

(inserisci-record-cache cache segment-high segment-low offset record-length
                       key csn-high csn-low flags source start
                       :version 2 :proof-buffer proof
                       :proof-start ps :proof-end pe :scan-p nil)
;; => :inserted | :present | :busy | :unavailable | :bypassed,
;;    evicted-p, scan-without-reread-p
```

`sizes` e `counts` sono array semplici u32, stabili durante la costruzione,
non trattenuti dal risultato. Al massimo sedici classi in ordine crescente;
dimensioni potenze di due tra 1 KiB e 32 MiB. Il numero di insiemi per classe
è zero oppure una potenza di due fino a 65.536; zero omette quella classe.
La classe selezionata è la prima attiva abbastanza grande per **l’intero
record**, header e chiave inclusi. Un record oltre tutte le classi salta
la cache. Nessun limite documentale viene abbassato dalla configurazione
della cache: una classe da 16 KiB può convivere con documenti da 16 MiB.

Tutti i conteggi zero e budget zero producono una partizione vuota.
Il numero di strisce è una potenza di due tra 1 e 256, ridotta al numero
di insiemi della singola classe. Il controller verifica tutte le classi
e l’intero budget prima della prima allocazione di arena.

Nessuna operazione pubblica di invalidazione, ri-etichettatura, svuotamento
o ridimensionamento. Segment-id non riusati impediscono di confondere una
location vecchia con un file nuovo. La compaction scalda le nuove location
attraverso le letture ordinarie. Il reclaim non consulta la cache.

## Layout e budget

Ogni posto contiene, in array specializzati separati:

| Campo | Payload |
|---|---:|
| Record | Dimensione della classe |
| Tag: segment-high, segment-low, offset, lunghezza | 16 byte |
| Sequenza seqlock | 8 byte |
| CLOCK, origine scan, rilettura, rifiutato, disabilitato | 5 byte |

Per una classe con `S` insiemi e dimensione `B`, il payload è:
`8 × S × (B + 29) + S + 8 × min(S, strisce)`.
Include le mani CLOCK e il vettore dei riferimenti ai mutex. Si aggiungono
otto byte per riferimento nel vettore delle classi attive.
Il valore restituito da `payload-cache-serie` è immutabile.

Header Lisp, oggetti mutex, allineamento, buffer dei worker, partizioni
pregresse e garbage pendente non sono inclusi. Il budget è del payload,
non RSS né budget globale: lo scheduler deve riservare anche questi costi.
La capacità è fissa; sostituire una partizione richiede un’operazione del
controller con pubblicazione e contabilizzazione delle vecchie referenze.
Questo collegamento allo scheduler non è ancora implementato.

## Ricerca

1. Verifica gli argomenti fisici e di formato, sceglie una classe e un insieme.
   Il mescolamento deterministico include segmento a 64 bit e offset a 32 bit.
2. Esamina al massimo otto tag. Un match provvisorio avvia **una** lettura
   seqlock: contatore pari, barriera acquire, tag e stato, copia nel buffer
   privato, barriera, ricontrollo del contatore e dello stato.
3. Dispari, contatore oltre limite, cambiamento o posto scartato/disabilitato
   diventano `:miss`. Non ripete il tentativo e non legge fuori dall’insieme.
4. Verifica la copia privata con `arcdocdb.record:verifica-put-parole`:
   CRC header/body, cornice e lunghezza esatta, PUT, flag, chiave completa,
   CSN oppure TXID e prova OUTCOME autorevole per un prepared.
5. Solo dopo la verifica restituisce `:hit` e il range del valore. Aggiorna
   i byte CLOCK e rilettura: il loro valore non decide coerenza o visibilità.

`destination` è scratch esclusivo del worker. Deve contenere il record
completo a partire da `start` e non essere alias di arena, chiave o prova.
Un esito negativo può aver copiato byte provvisori: i range sono zero e
il chiamante deve scartare lo scratch. Anche una condizione o un’uscita
non locale rende il risultato inutilizzabile.

La stessa verifica a due parole è disponibile alle letture dal segmento.
`verifica-put` mantiene la firma precedente e delega al verificatore
comune; la cornice v1/v2 non cambia. La cache conserva solo il PUT; la
prova prepared viene risolta dal caller e resta autorevole. Un hit di un
prepared richiede la prova, già stabile nel compito corrente: la cache
non certifica da sola il commit multiserie.

## Scarto, inserimento e CLOCK

Una `corruption-detected` durante la verifica della **copia in cache**:

- restituisce `:verify-failed`, senza range del valore;
- marca il posto rifiutato senza attesa;
- richiede al caller metrica/allarme `cache-verify-failed` e rilettura
  dal segmento; solo quest’ultima può accusare il dato persistente.

Il bit di rifiuto è conservativo: una sostituzione concorrente può ricevere
lo scarto di una copia precedente. Questo provoca un miss aggiuntivo;
non rende valido un record errato. Il successivo inserimento sotto mutex
può riutilizzare il posto rifiutato. Errori di argomenti, risorse o invarianti
non vengono assorbiti dal gestore della corruzione.

L’inserimento verifica **il proprio input** con lo stesso verificatore
prima di acquisire il mutex della striscia, con `wait-p nil`:

- classe assente: `:bypassed`; il caller conserva la responsabilità di
  verificare il record dal segmento anche quando la cache è disattivata;
- contesa: `:busy`, nessuna attesa o copia;
- stessa location già leggibile: `:present`, nessuna copia;
- nessuna vittima con credito entro due giri CLOCK: `:unavailable`;
- altrimenti: sequenza dispari, barriera, record/tag/stato, barriera,
  nuova sequenza pari e `:inserted`.

La corruzione del buffer **inserito dal segmento** propaga al caller del
segmento, distinta da `:verify-failed`: non viene nascosta come difetto
della cache. La copia inserita è una verifica supplementare; il suo costo
CRC rispetto alla lettura già verificata va misurato.
PUT e prova OUTCOME possono risiedere in intervalli dello stesso buffer
input stabile: l’inserimento lo legge soltanto. Il divieto di alias con
la prova riguarda la destinazione modificata dalla ricerca.

CLOCK visita al massimo sedici posti, azzerando i riferimenti accesi.
Le scansioni entrano con riferimento zero; le richieste puntuali con uno.
La mano è mascherata a tre bit, quindi non può uscire dall’insieme.
Una rilettura può riaccendere tutti i riferimenti durante entrambe le
passate: l’inserimento rinuncia invece di attendere una vittima.

Sequenze a 64 bit limitate sotto `2^62`, nessun wrap. Un posto con sequenza
dispari inattesa, credito esaurito o mutazione interrotta viene disabilitato
per tutta la vita della partizione. Il cleanup disabilita prima del rilascio
del mutex e propaga l’errore originale. La disponibilità residua può calare
fino a zero; il percorso dal segmento resta disponibile. Non c’è rollback
del contatore né riapertura del posto disabilitato.

## Metriche e costi

Gli enum distinguono hit, miss, errore di verifica, contesa, bypass e
indisponibilità; i due booleani di inserimento descrivono espulsione e
origine scan senza rilettura osservata. Il caller li conta nei contatori
del worker, da aggregare fuori dal percorso della richiesta. Nessun
contatore centrale o scrittura fra Serie.

Calore e osservazione delle riletture sono approssimativi: una scrittura
conservativa di un reader precedente può influenzare la vittima successiva.
La scan pollution esposta è una metrica diagnostica, non un conteggio
linearizzabile. Scheduler, aggregazione, allarme e decisione su 2Q restano
integrazioni successive; non si cambia politica senza misure e ADR.

La [suite di pubblicazione e sostituzione](../../tests/cache/README.md)
aggiunge casi deterministici sugli stati dei posti e prove con quattro
worker sullo stesso insieme. Il metodo distingue gli interleaving osservati
dalla copertura delle finestre interne e dalla qualifica C1 completa.

Ricerca: al massimo sedici classi, otto tag, una copia e una verifica
proporzionali alla lunghezza del record e della eventuale prova. Inserimento:
verifica dell’input, un tentativo di mutex, otto tag, al massimo sedici
visite CLOCK e una copia. Nessun I/O o lavoro non limitato nel modulo.
Array specializzati, nessun oggetto per entry, CSN in due u32. Allocazioni
ed efficienza reale dei percorsi di successo restano da misurare, così
come P95/P99 e scan pollution; non vengono dichiarate pari a zero.

## Decisioni C1 e qualifica

| ID | Decisione composta | Copertura ancora richiesta |
|---|---|---|
| CCH-D01 | Configurazione: dimensioni/conteggi, classi ordinate, potenze e budget | Ogni limite, classe omessa, budget zero e preflight senza allocazione |
| CCH-D02 | Location/CSN non zero, chiave, record, range e flag | Campi zero, estremi u32/u64, v1/v2, limiti documento |
| CCH-D03 | Alias distruttivo in lettura, input stabile in inserimento, spazio e prova prepared | Ogni alias, PUT/OUTCOME nello stesso input, start finale, prova mancante e intervalli errati |
| CCH-D04 | Tag composto e seqlock pari/stabile con posto leggibile | Ogni campo discordante, scrittura concorrente e lettura mista |
| CCH-D05 | CRC/tipo/flag/chiave/CSN o TXID+OUTCOME | Ogni discordanza, due parole alte, prova di altro lotto |
| CCH-D06 | Credito, parity e stato terminale del posto | Ultimo credito, contatore dispari e interruzioni prima/dopo il pari |
| CCH-D07 | Vittima vuota/rifiutata/fredda o doppio giro esaurito | Ogni ramo, tutti caldi e contesa con calore concorrente |
| CCH-D08 | Espulsione di uno scan senza rilettura osservata | Origine/rilettura e race conservative nelle metriche |
| CCH-D10 | Disponibilità prima del tag: posto disabilitato/rifiutato o candidato leggibile | Vecchio tag rifiutato/disabilitato seguito da copia valida; secondo controllo nella copia e race conservative |
| CCH-D09 | Corruzione della copia contro corruzione dell’input | Cache scartata senza quarantena; input propagato al caller storage |

Metodo ed evidenze statiche nella
[campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-cache-record/README.md).
Compilazione e controlli statici non chiudono la qualifica C1.
La suite della cache documenta una prima campagna concorrente limitata;
restano prove differenziali cache attiva/budget zero, stress prolungato,
fault injection completa, misure di allocazione, integrazione GET/EBR/snapshot,
resolver OUTCOME, I/O, scheduler e metriche. I requisiti mantengono lo
stato progettato fino alla qualifica richiesta dalla tracciabilità.

## Riparazione opportunistica del percorso GET

Il reader salta i posti già rifiutati o disabilitati prima del confronto del tag.
Una copia valida reinserita in un altro way resta raggiungibile; le guardie
della copia sotto seqlock vengono ricontrollate. Il primo errore CRC resta
`:verify-failed` e impone il fallback al segmento. La scansione conserva il
budget di otto way e non ritenta una copia concorrente non confermata.
Regressione e misure: [campagna GET](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-performance/README.md).
