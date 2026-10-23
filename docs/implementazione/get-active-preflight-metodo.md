# Verifica dei rifiuti OPEN del GET ACTIVE

Metodo registrato prima delle esecuzioni del 2026-10-14, sulla base
`a5715a1aa0b2571d650d1b794e9bb7b7324e951e`. La campagna completa la
[prima suite ACTIVE](get-active-verifica.md) nel tratto che precede la
sigillatura e l'assegnazione del CSN. Non modifica il protocollo del prodotto.

## Perimetro

Il punto d'ingresso è `verifica-capienza-get-attiva`, in
`src/get-resolver/active-preflight.lisp`. Le decisioni GSA-D09 e GSA-D14
sono descritte nel [contratto ACTIVE](get-active.md). Si verificano i rifiuti
di identità, stato, ordine e capacità e la propagazione dei guasti degli
header OPEN. Il bootstrap vuoto e le fonti GET della Serie hanno campagne
distinte; non se ne ricontano i mutanti.

Si aggiungono quattordici test nominali in `tests/get-active/preflight.lisp`,
con l'ID del requisito nel nome. La suite ACTIVE attesa passa da 28 a 42
test; il numero e i nomi effettivi vengono ricavati dai sorgenti congelati
e confrontati con il registro caricato. Il totale dell'intero sistema viene
ricavato separatamente: altri incrementi possono aggiungere test a `main`.

| Caso | Attesa indipendente |
|---|---|
| ID del lotto | Controllo conforme e solo file-ID diverso, in v1/v2 |
| Versione del lotto | Controllo conforme e sola versione diversa, in v1/v2 |
| Lotto OPEN vuoto | Rifiuto prima del CSN |
| OPEN con binding CSN | Token reale SEALED, FI del solo stato a OPEN; rifiuto senza acquisizione |
| Lotto SEALED | Rifiuto di stato; token del caller ancora pendente |
| Radice precedente | Radice vecchia o estranea rifiutata prima dell'adozione |
| Ring pieno | Nessun nuovo evento, slot o token |
| Generazione esaurita | FI tipizzata del limite, nessun wrap |
| Contiguità | Offset iniziale discordante e radice stabile |
| Spazio del segmento | Estremo ammesso e un byte oltre, senza creare file giganti |
| Numero di record | Limite esatto e superamento |
| Byte del lotto | SEAL incluso: limite esatto e un byte sotto |
| CRC dell'header OPEN | Causa originale e controller FAULTED di Archivio |
| Count OPEN incongruente | Invariante o corruzione tipizzata, senza adozione |

I casi che costruiscono uno stato impossibile tramite campi interni sono
FI esplicite. Non attestano che quello stato sia raggiungibile dal protocollo
conforme. Il progresso impossibile dopo un `checked-header` conforme resta
una difesa da analizzare; non si altera la funzione per simularne la copertura.

## Oracoli e risorse

Le fixture possiedono file nativi distinti readonly/append e la relativa
associazione. Per ogni chiamata si conservano byte e stato del lotto,
binding/token CSN, frontiere del registro, radici per identità, ring e
generazione, offset del controller e posizioni scritta/durevole del file.
Il backend osserva letture, scritture, flush e interrogazioni di identità.
La preflight conforme e i rifiuti non producono queste operazioni.

Un rifiuto ordinario mantiene il controller HEALTHY; gli errori di
corruzione o invariante seguono il fail-stop di Archivio. In questi ultimi
casi si confrontano comunque gli altri dati e si controlla separatamente
la transizione di salute. Nessun errore di cleanup viene ignorato.
I token SEALED mai adottati sono annullati esplicitamente dopo le osservazioni.
Le FI sono ripristinate prima di rilasciare risorse che richiedono lo stato
originario; il ripristino non viene presentato come rollback del prodotto.

## Mutazioni preregistrate

Si estende lo strumento C4 `tools/get-active-init-mutation.lisp` con
`--suite preflight`; senza questa opzione restano selezione e comportamento
del bootstrap. Il nuovo profilo ha quattro modifiche isolate del solo
`active-preflight.lisp`, con anchor univoco e diff conservato.

| Mutante | Test di rilevamento |
|---|---|
| Omettere il confronto file-ID | `test-REQ-WAL-005-active-preflight-batch-file-id` |
| Omettere il confronto versione | `test-REQ-WAL-005-active-preflight-batch-version` |
| Escludere il SEAL dal budget dei byte | `test-REQ-AFF-008-active-preflight-seal-byte-boundary` |
| Rifiutare il numero esatto di record con `>=` | `test-REQ-AFF-008-active-preflight-record-boundary` |

La baseline esegue l'intera suite ACTIVE. Ogni mutante esegue il test
preregistrato, già passato nella baseline; registro completo e definizioni
ASDF rimangono verificati. Si conservano separatamente suite intera e test
eseguiti. Le copie e le cache FASL dei cinque child sono private.

Una mancata compilazione, un timeout, un errore della fixture o I/O, un
segnale e un child non raccolto sono errori della campagna. Un mutante è
rilevato soltanto da un'asserzione o condizione semantica del prodotto nel
test preregistrato, con identità di sorgenti, patch, configurazione, registro
e artefatti verificata. La campagna salva anche fallimenti e risultati parziali.

Il nuovo profilo impone limiti osservabili ai processi e ai subprocessi
usati per i digest e ne verifica la terminazione. Il self-test prova il
classificatore e gli errori d'infrastruttura. Si eseguono anche la regressione
del profilo bootstrap preesistente e fixture CLI per suite ignota/duplicata.

## Esecuzione e conservazione

Prima dei run si committano metodo, test, configurazione ASDF e strumento;
poi restano fermi durante esecuzioni, letture indipendenti e raccolta.
`tools/record-command.lisp` registra i comandi. `make check` e il profilo
SB-COVER ACTIVE usano processi e cache separati; la copertura conserva
l'elenco esplicito dei dieci file originali. Non comprende `active-init.lisp`.
Il default CLOSED viene ricontrollato con la propria suite separata.

Si conservano gruppi completi, stdout/stderr, configurazioni e driver,
manifest originali, patch e FASL utilizzati, letti solo come byte. I source
canonici sono identificati dal Git congelato; i source mutati e i loro hash
sono conservati insieme alle patch. Le prove sono lette tramite il reader
di evidenze del repository con `read-eval` disabilitato, mai caricate come codice.
Gli esiti locali e quelli della CI Linux/macOS restano attribuiti ai rispettivi commit.

## Limiti

Quattro difetti selezionati non misurano l'adeguatezza generale delle prove.
I witness delle condizioni e SB-COVER non costituiscono una qualifica MC/DC
globale. Restano aperti C1, interruzioni in ogni fase, stress concorrente,
prepared/OUTCOME ACTIVE, indice concreto, rotazione/reclaim e motore completo.
Non si misurano throughput, latenza, RSS o allocazioni in questa campagna.
