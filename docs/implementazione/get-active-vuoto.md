# Radice ACTIVE vuota con fonti recuperate

Il bootstrap pubblica le fonti GET prima del primo documento. Completa il
ponte [ACTIVE/CLOSED](get-fonti-serie.md) e usa l'header preparato dal
[modulo di apertura](inizializzazione-active.md). La decisione durevole EDIT
e l'ammissione delle richieste rimangono responsabilità del controller esterno.

## Protocollo

1. Preparare il nuovo segmento writer: header di 64 byte, file e directory
   sincronizzati, readonly associato fisicamente all'append.
2. Completare la decisione EDIT che apre il segmento nel manifest.
3. Creare un solo controller per quel log, root NIL e next-offset 64.
   Acquisire la lease e creare la sorgente GET, preferibilmente tramite
   `crea-sorgente-get-preparata`.
4. Costruire `fonti-get-serie` dai CLOSED recuperati e chiamare
   `inizializza-fonti-get-attive(source, lease, sources)`.
5. Dopo il ritorno, ammettere le richieste. Le location recuperate sono
   risolvibili dalla stessa radice; il nuovo ACTIVE non contiene documenti.
6. Registrare il primo lotto con `previous = radice-vuota`. Pubblicarlo
   con il normale protocollo WAL prima di esporre le sue location nel primary.

Il bootstrap non crea un record WAL, non incrementa CSN o generazioni evento
e non modifica frontiere, ring o ultimo CSN. Il CAS pubblica memoria nello
slot canonico della Serie. Non attesta la decisione EDIT né un commit documento.
Il controller legacy iniziale NIL può ancora registrare direttamente il primo lotto.

## API e struttura

| API | Contratto |
|---|---|
| `series:inizializza-radice-serie(controller, lease, root)` | Una sola inizializzazione con radice opaca non NIL, controller mai usato |
| `get.resolver:inizializza-radice-get-attiva(source, lease, :content)` | Header fermo a 64; radice vuota pubblicata e pianificata |
| `get.directory:inizializza-fonti-get-attive(source, lease, sources)` | Stessa vista canonica e ID ACTIVE assente dai CLOSED; content = sources |

La radice vuota contiene soltanto sorgente, contenuto e metadati scalari:
directory NIL, count/puts/nodes zero, end 64. Non alloca pagine o vettori
di righe. Il payload di pagine/righe è zero; l'oggetto Lisp della radice
e le fonti esistenti hanno comunque un costo. Il primo delta inserisce
la pagina di rango zero e quattro nodi, mantenendo immutabile la radice vuota.

Un candidato ACTIVE prima del primo lotto è impossibile: nessun offset
appartiene al range [64,64). Il resolver segnala il guasto del candidato
e libera il pin EBR; non restituisce assenza da una location pubblicata incoerente.
I CLOSED seguono il percorso esistente, con una sola acquisizione della radice.

## Rifiuti e interruzioni

Lease e salute precedono la verifica delle fonti. Owner/duplicato, radice NIL,
controller già avviato, readonly/append non aperti e file avanzato sono rifiuti ordinari
prima dell'effetto. Un controller che abbia usato e ritirato eventi rimane
avviato, anche con ring vuoto: event-generation deve essere zero.

Durante l'effetto, planned-root viene impostata prima del CAS NIL → root.
Il writer è esclusivo e l'ammissione resta chiusa fino al ritorno. Invariante
CAS/radice/ring o uscita incompleta rendono l'Archivio FAULTED, propagando
la causa originale; nessun rollback, retry, close o unlink. Il risultato
pubblicato non è una prova di quiescenza.

Il cleanup è installato prima dell'acquisizione dell'effetto locale:
un'interruzione durante quell'acquisizione non lascia il controller HEALTHY
con un effetto orfano. La rientranza è rifiutata prima del cleanup, che
non deve rilasciare una risorsa appartenente all'effetto già in corso.

Il grafo content e le capacità sono presi in prestito. Il proprietario ne
garantisce immutabilità e lifetime; le pubblicazioni successive conservano
le location ancora osservabili dai reader ammessi. Non è introdotto uno
stato condiviso tra Serie o una scrittura sul percorso GET.

## Decisioni da verificare

| ID | Decisione | Casi |
|---|---|---|
| AEV-D01 | Root non NIL | NIL e valore canonico |
| AEV-D02 | root NIL, planned NIL, event-generation zero, count zero | Ogni condizione separata, ring vuoto dopo uso, avvio ripetuto |
| AEV-D03 | Il CAS restituisce NIL | Successo e CAS discordante tramite FI; precede la postcondizione EQ |
| AEV-D03b | Root pubblicata e pianificata EQ al risultato | Entrambe vere nel protocollo; mutante che omette planned-root rileva la seconda foglia falsa |
| AEV-D04 | Readonly e append aperti | Entrambi aperti; ciascuna capacità non aperta separatamente |
| AEV-D05 | next-offset, scritto e durevole tutti a 64 | Ogni frontiera diversa separatamente |
| AEV-D06 | Vista CLOSED EQ a owner ACTIVE | Altra vista, canonica |
| AEV-D07 | ID ACTIVE assente dai CLOSED | Assente, presente, geometria impossibile |
| AEV-D08 | Nessun effetto locale già posseduto | Avvio normale e rientranza, senza rilascio dell'effetto precedente |

La revisione indipendente, le prove funzionali, le mutazioni e le misure
locali sono registrate nella campagna dell'incremento. Non qualificano
apertura completa, recovery, rotazione o reclaim del motore.

AEV-D03b è una postcondizione difensiva. Con lease esclusiva, il CAS appena
riuscito imposta root al risultato e il writer ha già impostato planned-root:
le foglie false non sono raggiungibili da una transizione conforme. Un CAS
discordante fallisce in D03 e non copre D03b. Il mutante planned-root
dimostra sensibilità al difetto strutturale, senza attestare copertura MC/DC
di quelle foglie nel prodotto conforme.
