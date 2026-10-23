# Selezione delle versioni durante il recovery

Il modulo `arcdocdb.recovery.selection` realizza il confronto per una
chiave di [ADR-0042 §2](../adr/0042-tombstone-e-indice-dei-vivi.md):
massimo CSN, poi offset fisico maggiore nello stesso segmento. Mantiene
il tombstone come vincitore provvisorio fino al termine della chiave.
Requisiti REQ-REC-001, REQ-IDX-001, REQ-IDX-006, REQ-TXM-007,
REQ-FOR-003, REQ-LIM-003, REQ-AFF-002, REQ-AFF-004, REQ-AFF-008;
invarianti INV-D1, INV-C11 e INV-I2.

È un componente a freddo della ricostruzione, non il Recovery Manager
completo. Il raggruppamento delle chiavi, la copertura di tutti i segmenti
e la pubblicazione dell'indice restano da collegare. Nessuna modifica
alle decisioni o ai formati persistenti.

## Contratto

```lisp
(crea-selettore-versione-recuperata :key-capacity 65535 :budget-payload 65647)
;; => workspace privato riusabile del worker
(inizializza-chiave-recuperata selector key start end)
;; => NIL, chiave copiata e nessun vincitore
(considera-record-recuperato selector buffer start end segment-id file-offset
                            :version 2 :prepared-csn nil)
;; => :selected | :kept | :duplicate | :ambiguous
(leggi-versione-selezionata selector)
;; => :none | :put | :tombstone, csn, segment-id, file-offset, record-bytes, version, flags
```

I nomi nel codice sono esportati dal package `arcdocdb.recovery.selection`.
Un worker possiede il selettore e lo riusa per chiavi successive. Ogni
gruppo appartiene a una sola Serie: il chiamante non mescola namespace
diversi con la stessa sequenza di byte della chiave. Prima
del reset deve avere terminato o esplicitamente abbandonato la chiave
precedente. Il reset non pubblica dati e non riabilita FAULTED.

Il chiamante fornisce solo record già riconosciuti **committed** nei
prefissi autorevoli dei reader [ACTIVE](active-recuperato.md) e
[CLOSED](closed-recuperato.md). Conserva l'identità del segmento, la
versione del file e i byte immutabili durante l'operazione. `start` è
l'indice nel buffer; `file-offset` è l'offset assoluto nel file, anche
quando il buffer contiene soltanto una porzione del segmento. Non sono
intercambiabili. Gli ID restano u64, incluso zero, senza troncamento.

Il selettore verifica nuovamente CRC header/body, formato esplicito v1/v2,
tipo PUT/TOMBSTONE, chiave binaria completa e rappresentabilità della
location prima di modificare il vincitore. Non trattiene buffer, corpo,
FD o oggetti del reader. Non verifica autonomamente SEAL, manifest,
appartenenza al segmento, contratto CBOR o completezza dell'Archivio:
un record con CRC valido da solo non autorizza il replay.

Per un record ordinario usa lo stamp della cornice e rifiuta un CSN
prepared aggiuntivo. Per un prepared richiede `prepared-csn` esplicito,
derivato dalla risoluzione canonica OUTCOME/EDIT/DECISION del chiamante.
Il TXID non viene interpretato come CSN. Un prepared abortito o irrisolto
non deve entrare nel selettore. NIL distingue l'assenza della prova dal
CSN zero; tutti i bit u64 sono preservati.

## Ordine e tombstone

Per candidati autorevoli coerenti, l'ordine di arrivo non modifica il
vincitore: una versione più vecchia non rimpiazza quella nuova, e a CSN
uguale nello stesso segmento prevale l'offset maggiore, anche passando
da PUT a TOMBSTONE o viceversa. Un tombstone resta rappresentato dalla
stessa tupla provvisoria di un PUT. Va tradotto in assenza nell'indice
dei vivi solo **dopo** la scansione completa della chiave.

La funzione può consegnare il massimo del sottoinsieme già considerato;
la completezza è una precondizione del coordinatore prima dell'uso
definitivo. La lettura con chiave inizializzata ma senza candidati
restituisce `:none` con campi zero, versione 2 e flag zero. `:none` è
distinto da un vincitore effettivo con CSN zero. Le restrizioni della
location e del CSN nell'indice primario restano controlli della futura
materializzazione; non si restringono qui i valori per farli entrare.

## Ambiguità e guasti

ADR-0042 definisce lo spareggio all'interno dello stesso segmento.
CSN uguale in segmenti diversi restituisce `:ambiguous`, senza inventare
un ordine per ID del segmento. Anche metadati discordanti alla stessa
location producono questo esito. CRC e metadati uguali identificano
soltanto un candidato ripetuto alla stessa location; non dimostrano
uguaglianza del body contro collisioni o file mutati.

Lo stato ambiguo impedisce `leggi-versione-selezionata`. Resta tale
anche dopo un candidato più vecchio o un offset successivo con lo
stesso CSN; un CSN strettamente maggiore domina tutti quei candidati
e permette una nuova selezione. Il coordinatore deve gestire l'esito,
non scegliere una replica senza una prova esterna. Su ingressi che
violano l'immutabilità dei file il comportamento è conservativo, senza
garanzia di accettazione indipendente dall'ordine.

I rifiuti del codec, della chiave, del budget o della prova prepared
precedono la modifica del vincitore. Lo scratch privato può essere
riusato: nessun risultato vi fa riferimento. Un'interruzione durante
reset o adozione rende il selettore FAULTED; una tupla privata incoerente
viene rifiutata prima della consegna. Un'asserzione del codec rende
FAULTED anche il selettore, conservando la condizione originale.
Le asserzioni locali non sostituiscono
il confine COD-24 della Serie, ancora da integrare nel coordinatore.

## Memoria e lavoro

Il workspace possiede un array u8 per la chiave e due tuple da sette u64:
**key-capacity + 112 byte di payload**. Il budget viene verificato prima
degli array. Esclude header degli array, struttura, GC, stack e buffer del
chiamante; non è RSS. Nessun oggetto per documento è conservato e nessun
array nuovo viene creato esplicitamente per candidato o reset.

Ogni candidato legge il corpo per il CRC e confronta al massimo 65.535
byte di chiave, quindi O(record-bytes + key-bytes), anche quando risulta
superato. Confronto/copia della tupla: sette parole al massimo. Non è un
percorso di lookup: non aggiunge lavoro a GET/PUT in esercizio, lock fra
Serie, I/O, thread o assegnazione di CSN. Allocazioni effettive, boxing,
GC, throughput e latenza non sono stati misurati in questo incremento.

## Decisioni da qualificare

| ID | Decisione | Stato |
|---|---|---|
| SVR-D01 | Configurazione e payload prima degli array | Aperta |
| SVR-D02 | Reset: stato, range, lunghezza e capacità prima della copia | Aperta |
| SVR-D03 | Chiave esatta, con confronto completo e limiti del buffer | Aperta |
| SVR-D04 | PUT/TOMBSTONE, offset fisico e CRC prima del candidato | Aperta |
| SVR-D05 | Stamp ordinario / CSN prepared esplicito, zero e u64 alto | Aperta |
| SVR-D06 | Massimo CSN, offset successivo e candidato ripetuto | Aperta |
| SVR-D07 | Ambiguità fra segmenti o metadati alla stessa location | Aperta |
| SVR-D08 | Ambiguità trattenuta a parità CSN, risolta solo da CSN maggiore | Aperta |
| SVR-D09 | Reset/adozione incompleti e invarianti private => FAULTED | Aperta |
| SVR-D10 | Lettura: nessun candidato, PUT, TOMBSTONE e ambiguità | Aperta |

Il [metodo e i risultati locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-recovery-selection/README.md)
distinguono controlli statici e qualifica. Test dedicati, proprietà sulle
permutazioni, FI, MC/DC, copertura, revisione indipendente e integrazione
con indice/radici/ammissione restano aperti.
