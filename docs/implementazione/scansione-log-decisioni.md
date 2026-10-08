# Decisioni della scansione dei log

Inventario dei predicati composti secondo COD-54. I casi di regressione sono in
[`tests/recovery/`](../../tests/recovery/). Questa tabella non certifica da sola
copertura MC/DC o qualifica del recovery completo.

| Funzione e decisione | Condizioni e casi |
|---|---|
| `check-scan-arguments`: tipo del log e file-id | segmento con ID opaco; control/multiserie con zero; altro tipo e ID non zero rifiutati, anche a log vuoto |
| `check-scan-arguments`: tipi, minimi e somme dei budget | budget valido; ogni parametro negativo o nullo non ammesso; batch-records oltre u32; lotto sotto 56 byte; overflow di file-offset + end |
| `check-scan-arguments`: EOF fisico | file-size u64 e uguale alla fine assoluta; valore assente o invalido; finestra che non arriva all'EOF |
| `check-scan-arguments`: byte del log | intervallo esatto al budget accettato; un byte oltre rifiutato |
| `checked-batch`: progressione e risultato del verificatore | lotto integro; errore interno del verificatore distinto da corruzione esterna; solo corruption-detected avvia la ricerca |
| `seal-witness`: filtro del tipo | nessun SEAL; candidato presente, incluso non allineato; nessuna lunghezza esterna guida una lettura |
| `seal-witness`: postcondizioni della cornice | 56 byte, tipo SEAL, flag zero, chiave vuota e corpo 32 byte già garantiti dal codec; controlli difensivi sempre attivi |
| `seal-witness`: identità e posizioni | file esatto/diverso; inizio del lotto prima dell'area dei record, nell'area e oltre il candidato; frontiera non oltre/oltre il batch-start |
| `search-durable-witness`: candidato e frontiera | candidato invalido; D < P, D = P e D > P; corpo del lotto testimone danneggiato con SEAL integro |
| `search-durable-witness`: tutte le posizioni | primo/ultimo candidato, un SEAL non conclusivo prima del testimone; avanzamento di un byte e ricerca fino a end − 56 incluso |
| `search-durable-witness`: budget | nessuna posizione possibile; budget esatto; una posizione mancante rifiuta la classificazione |
| `scan-prefix`: fine, errore e limite lotti | log vuoto; fine esatta; lotto fallito con P al suo inizio; byte residui dopo l'ultimo lotto consentito; conteggi del solo prefisso |

Le prove `REQ-AFF-009-every-log-truncation`,
`REQ-AFF-009-frontier-boundary-and-failed-batch-start`,
`REQ-AFF-009-invalid-witnesses-are-ignored` e
`REQ-AFF-008-invalid-configuration-is-never-tail` coprono i confini del
prefisso, la frontiera stretta, ciascun campo esterno del testimone e i
parametri della scansione. Le prove di tutti i bit sono in
[`corruption.lisp`](../../tests/recovery/corruption.lisp), con chiamate
dirette alla versione e agli offset espliciti dello scanner.
`REQ-AFF-009-overlapping-seal-after-noncovering-frontier` costruisce due
SEAL con CRC validi sovrapposti a distanza di 32 byte: quello non conclusivo
non deve nascondere il successivo testimone `D > P`.

## Rami difensivi e confini della prova

`checked-batch` verifica le postcondizioni di `verifica-lotto`: progressione,
range e conteggi. `seal-witness` ricontrolla la forma restituita dal codec.
Il superamento di questi controlli non è ottenibile da byte esterni dopo una
verifica corretta del livello inferiore; segnala un difetto interno.
`scan-prefix` controlla inoltre che il conteggio dei record sia compatibile
con i byte effettivamente consumati.

Definizioni, proclamazioni e rami difensivi restano nel denominatore della
copertura grezza. Qualsiasi eccezione richiede registrazione e revisione
secondo il [piano di verifica](../affidabilita/piano-di-verifica.md).
Il [catalogo delle evidenze](../../spikes/results/2026-10-08-recovery/catalogo.lisp)
conserva il rapporto grezzo, la campagna di nove mutanti e le due letture
indipendenti del modulo. La seconda lettura ha aggiunto al caso di
configurazione invalida un budget di lotto oltre `most-positive-fixnum`;
il controllo del tipo viene quindi esercitato separatamente dal minimo di
56 byte. I rami difensivi elencati sopra non vengono sottratti dai totali.
Il rapporto finale misura 416/480 espressioni (86,7%) e 52/66 rami (78,8%)
in `scan.lisp`. I 14 rami non presi sono cinque postcondizioni/precondizioni
di `checked-batch`, sei di `seal-witness`, il confine iniziale della ricerca
e due controlli di `scan-prefix`; richiederebbero una violazione del contratto
interno o un codec difettoso. Anche `package.lisp` resta nel rapporto con
una definizione non eseguita e nessun ramo. Questi risultati non chiudono
un gate di copertura o di qualifica del motore.
I test di corruzione in memoria non simulano persistenza, flush o transizioni
`FAULTED`; verificano il risultato della scansione sui byte forniti.
