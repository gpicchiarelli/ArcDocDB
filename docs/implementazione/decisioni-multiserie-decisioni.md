# Decisioni della tabella multiserie

Inventario COD-54 da verificare in due letture C1. I casi sono in
[`tests/recovery/`](../../tests/recovery/). La tabella non certifica da sola
copertura MC/DC, durability o applicazione atomica del motore.
L'[inventario radix](decisioni-radix-decisioni.md) completa questo documento
con i due dispatch, istogrammi, scatter e guardie dell'ordinamento adottato.

| Controllo | Condizioni e casi |
|---|---|
| Configurazione | budget in intervallo; zero valido; valori negativi o oltre il tipo; controllo anche a log vuoto |
| Scansione prima del risultato | prefisso completo; coda finale; corruzione testimoniata successiva; ricerca incompleta; nessuna tabella su errore |
| Conteggio dei record | count zero; esattamente al limite; un record oltre; i duplicati consumano budget |
| Payload DECISION | almeno due partecipanti; consumo esatto; conteggio incompatibile con i byte e byte residui nel prefisso con cornici verificate |
| Cornice DECISION corta | lunghezza sotto il minimo prima del prefisso; coda senza testimone e corruzione con frontiera durevole successiva oltre l'inizio del lotto |
| Conteggio dei partecipanti | limite per record; totale esatto; totale superato fra record, anche duplicati |
| Ordinamento dei partecipanti | ID distinti, incluso zero; primo/ultimo byte diverso; bit alto; uguaglianza completa |
| Coalescenza del TXID | nuovo TXID; duplicato con CSN/set uguali; set permutato; CSN o solo set discordante |
| Ricerca del TXID | primo, intermedio e ultimo; assente sotto/fra/sopra; TXID/CSN zero e massimi; CSN condiviso |
| Query di appartenenza | partecipante presente/assente; TXID assente; ID da slice non allineata; range invalido o lunghezza diversa da 16 anche a TXID assente |
| Ownership | sorgente invariato durante costruzione; sorgente sovrascritto dopo costruzione; query stabili; nessun vettore interno esposto |
| Progressione interna | cornici e conteggi coerenti con il prefisso verificato; ordinamento/range/capienza rispettati; guardie difensive sempre attive |

I loop di ordinamento sono limitati dai conteggi effettivi; le query usano
ricerca binaria su dati ordinati. Le definizioni e le guardie interne restano
nel denominatore grezzo della copertura. Eventuali forme non raggiungibili
vengono motivate dopo la misura, senza sottrarle dai totali pubblicati.

Il [metodo](decisioni-multiserie-metodo.md) distingue prove di cornice,
semantica e recovery completo. Una decisione semanticamente invalida dentro
il prefisso con cornici e SEAL verificati non può trasformarsi in assenza e
quindi presumed abort. I danni alla cornice restano soggetti alla ricerca del
testimone e ai limiti dichiarati dallo scanner.


## Predicati composti dei sorgenti

Le prove citate sono in `decisions.lisp` e `decisions-audit.lisp`;
si omette soltanto il prefisso `test-REQ-…` dei nomi. Le guardie interne
sono motivate nell'[inventario della copertura](../affidabilita/copertura-eccezioni.md).
La distinzione fra casi osservati e invarianti interni non elimina forme
dal denominatore e non costituisce una qualifica MC/DC.

| Funzione e decisione | Clausole e verifica |
|---|---|
| `check-decision-budgets`: `and` dei due tipi `index` | entrambi validi; invalido solo `max-decisions`; invalido solo `max-participants`. `invalid-decision-budgets-even-empty` prova negativi e overflow separati; `physical-duplicate-record-budgets` prova i limiti esatti |
| `decision-frame`: `and` su avanzamento, confine, chiave vuota e flag zero | tutte vere per ogni cornice ammessa dallo scanner; le negazioni contraddicono il prefisso stabile già verificato. Guardia interna `decision-control-frame` |
| `decision-frame`: `and` su range del payload e misura `count × 16` | range restituiti dal codec e consumo esatto; errore semantico provato da `sealed-invalid-decision-payload-is-not-tail` e `sealed-trailing-decision-payload`. Guardia interna `decision-payload-range` |
| `preflight-decisions`: `and` su posizione finale e numero di decisioni | scanner e rilettura di un buffer stabile contano le stesse cornici. Guardia interna `decision-prefix-consumption` |
| `decode-decisions`: `and` su posizione finale, entry prodotte e partecipanti letti | conteggi fissati da scanner e preflight; nessuna mutazione del buffer. Guardia interna `decision-prefix-consumption` |
| `same-decision-p`: `and` su CSN, count e uguaglianza di ogni byte | `conflicting-csn-set-or-count` prova CSN diverso a set costante, set diverso a count costante e count diverso a CSN costante; `seeded-histories-and-permuted-duplicates` verifica uguaglianza dopo canonizzazione |
| `unique-decision-count`: `and` su predecessore presente e TXID decrescente | primo record e successivi osservati; TXID decrescente impossibile dopo l'ordinamento stabile. Guardia interna `decision-entry-order` |
| `unique-decision-count` e `collapse-decisions`: `and` su predecessore presente e TXID uguale | primo record, TXID nuovo, duplicato coerente o discordante; `decision-table-ordered-unordered-oracle`, `seeded-histories-and-permuted-duplicates`, `first-physical-decision-conflict-across-txid-groups` |
| `merge-id-runs`: `and` su vettori non vuoti, misura uguale, identità distinta e multiplo di 16 | copie e workspace privati di misura verificata; negazioni contraddicono la costruzione. Guardia interna `decision-sort-arrays` |
| `merge-entry-runs`: `and` su misura uguale e identità distinta | scratch della stessa lunghezza del vettore privato; guardia interna `decision-sort-arrays` |
| Entrambi i merge: `or` su run destro esaurito e `and` su run sinistro disponibile/confronto | input inversi, permutazioni, duplicati, cardinalità dispari e massimo u16; `decision-table-ordered-unordered-oracle`, `seeded-histories-and-permuted-duplicates`, `maximum-u16-participant-count` |
| Entrambi i merge: `and` sul consumo dei due run | un avanzamento per iterazione e `right-left` iterazioni; guardia interna `decision-sort-consumption` |
| `partecipante-decisione-p`: `and` su TXID trovato e partecipante presente | TXID assente, presente con ID assente, presente con ID esatto; `participant-exact-bytes-and-query-ranges`, `participant-every-byte-and-every-bit` |

I confronti fra byte nel ciclo `same-decision-p` terminano alla prima
ineguaglianza e restano limitati alla misura verificata. I test cambiano
anche l'ultimo byte e ciascuno dei 128 bit, senza confondere una differenza
di ID con la sola presenza del TXID. `public-default-budgets-and-explicit-version`
chiama direttamente l'API e verifica i budget predefiniti e la versione obbligatoria.
