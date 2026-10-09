# Decisioni del pianificatore di inventario

Leggere con [contratto](inventario.md) e [metodo](inventario-metodo.md).
Forme e rami mancanti, incluse guardie private, restano nel denominatore
grezzo `sb-cover`. La tabella non dichiara MC/DC né eccezioni approvate.

| Funzione / controllo | Casi |
|---|---|
| `check-inventory-budgets`: ogni budget `index` | valido, zero, negativo, oltre fixnum, separatamente |
| file fisici `> max-files` | uguale, superiore; precedenza su entry invalide/duplicati |
| richiesti `1+CLOSED > max-segments` | uguale, superiore; CLOSED mancanti inclusi |
| somma dei conteggi `index` | guardia aritmetica interna, nessuna esclusione |
| `inventory-presence`: descrittore, forma, nome ripetuto | valido/invalido; tmp/final; duplicato uguale/due forme |
| cardinalità presenza entro file fisici | guardia dopo coalescenza |
| `inventory-ids`: ACTIVE positivo, CLOSED valido, bound, maschera | guardie private; union di live mancanti; ID0/high/max |
| `single-file-action`: stato/nome | ACTIVE/CLOSED/REMOVED/UNKNOWN × temporary/final; next-id irrilevante |
| `check-single-file-action`: delete ⇒ removed oppure unknown temporary; rename ⇒ live | i singoli stati nella matrice; guardie di prova, errori interni non esclusi |
| `inventory-entry`: quattro maschere | assente solo live; tmp, final, entrambe; conflitto prevalente |
| `inventory-entry`: ID, stato e forma dell'entry uguali agli input verificati | guardia di ownership/coerenza della decisione, nessuna esclusione |
| `entry-severity`: missing oppure conflict, stato | ACTIVE2, CLOSED1, altri0; use/rename/delete/anomaly0 |
| `entry-severity`: missing ⇒ live; severità positiva ⇒ missing/conflict | guardie di coerenza, nessuna esclusione |
| `pianifica-riconciliazione`: massimo severità e consumo | FAULTED domina DEGRADED; tutte le permutazioni; guardia consumo |
| `azione-riconciliazione`: intervallo0..count−1 | primo/ultimo validi, negativo e count invalidi |

Le condizioni di appartenenza `:active`/`:closed` e `:missing`/`:conflict`
sono provate separatamente nella matrice. Le comparazioni concatenate
verificano range e bound. Tipi di argomenti/slot sono pre/postcondizioni
sempre attive; le guardie controllano relazioni fra cardinalità e passaggi.
