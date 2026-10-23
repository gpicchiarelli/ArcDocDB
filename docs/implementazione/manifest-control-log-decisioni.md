# Decisioni del manifest

Inventario dei contratti da leggere insieme al
[metodo](manifest-control-log-metodo.md) e al
[contratto applicativo](manifest-control-log.md#applicabilità-e-duplicati).
Le guardie interne restano nel denominatore grezzo della copertura.

| Controllo | Casi indipendenti |
|---|---|
| Configurazione | ciascun budget valido, zero, negativo o oltre il tipo; controllo anche senza record |
| Prefisso | log integro, coda completa di ricerca, testimone durevole successivo, ricerca incompleta; nessuno stato su errore |
| Primo EDIT | completo iniziale presente, differenziale iniziale, log vuoto, primo lotto incompleto, completo successivo |
| Stato completo | ACTIVE nonzero; next-id nonzero e superiore a ogni ID; sezioni disgiunte |
| Rotazione | ACTIVE ripetuto; sostituzione con chiusura; apertura senza chiusura; chiusura senza apertura |
| CLOSED | nuovo output di compaction; chiusura ACTIVE; ripetizione uguale; lunghezza o esiti discordanti; ID rimosso |
| Rimozione | CLOSED presente; già rimosso; duplicato nello stesso EDIT; ACTIVE o ID sconosciuto |
| Esiti | TXID presente/assente; CSN zero, alto e massimo; duplicato coerente o discordante |
| Identificativi | prenotazione inferiore al limite pubblicata dopo; checkpoint alto; rimozione conserva il limite; esaurimento u64 |
| Budget | fisico esatto e superato; cumulativi fra EDIT; duplicati consumati prima della coalescenza |
| Ownership | input invariato; input riusato dopo; query scalari senza vettori interni |
| Parallelismo | quattro costruzioni indipendenti; query condivise in lettura; errori dei worker e join limitati |

## Predicati del prodotto

I nomi sotto corrispondono alle funzioni private del modulo. I casi sono
esercitati tramite l'API pubblica; le proprietà strutturali già garantite
dal passaggio precedente restano guardie difensive, senza esclusioni dal
denominatore della copertura. Questo inventario non dichiara indipendenza
MC/DC dei singoli operandi.

| Funzione / predicato | Casi o giustificazione |
|---|---|
| `checked-manifest-limits`: tre conteggi `index`, tre conteggi `u32`, byte `index` entro 16 MiB | `zero-empty-sections-and-invalid-budgets`: zero, negativo e oltre il tipo per ogni budget; `physical-duplicate-budgets`: limite esatto e superamento |
| `manifest-frame`: avanzamento, fine entro prefisso, chiave vuota, payload fino alla fine; flags SEAL zero; span CLOSED/REMOVED ordinati | Guardie interne: scanner e codec hanno già verificato queste proprietà; cornici e payload corrotti in `semantic-corruption-in-sealed-prefix` e `scanner-and-eof-contracts` |
| `preflight-manifest`: conteggi EDIT/frame coerenti, consumo esatto; riferimenti OPEN solo se nonzero | Guardie di conteggio/consumo; `physical-duplicate-budgets` e `zero-empty-sections-and-invalid-budgets` verificano separatamente OPEN, CLOSED, REMOVED e duplicati |
| `decode-manifest`: consumo, conteggi e budget precedentemente attestati tutti uguali; stato presente | Guardie di coerenza fra passaggi; `snapshot-required-and-valid` e `every-cut-keeps-whole-sealed-prefix` verificano assenza dello snapshot |
| `check-closed-shape`: lunghezza 64..u32 massimo, mappa EQL | Guardie di costruzione privata: lunghezza già verificata dal codec e mappa sempre creata con EQL; nessuna esclusione |
| `same-closed-p`: lunghezza, cardinalità degli esiti, presenza TXID e uguaglianza CSN | `idempotent-closures-removals-and-outcomes`, `conflicting-outcome-and-closed-proof`: uguaglianza, lunghezza diversa, cardinalità diversa, TXID diverso a cardinalità uguale, CSN diverso |
| `decode-closure-outcomes`: duplicato presente con CSN diverso; consumo esatto e cardinalità non oltre conteggio | Duplicato coerente/discordante e CSN zero/alto/massimo nei test degli esiti; consumo/cardinalità sono guardie interne |
| `decode-edit-closed`: duplicato presente e prova diversa; consumo esatto e cardinalità limitata | Duplicati CLOSED nei test di idempotenza e conflitto; span e consumo sono guardie interne |
| `decode-edit-removed`: span esatto e cardinalità limitata | Rimozione ultima, duplicata e ripetuta; guardie dopo codec e coalescenza |
| `check-edit-sections`: OPEN nonzero e presente in CLOSED oppure REMOVED; CLOSED presente in REMOVED | `section-overlap-is-invalid` distingue le tre collisioni e `zero-empty-sections-and-invalid-budgets` esercita OPEN zero |
| `initial-manifest-state`: completo, ACTIVE nonzero, next-id maggiore del massimo | `snapshot-required-and-valid`, `snapshot-sizes-and-permuted-sections`, `u64-boundaries-and-id-exhaustion` |
| `check-active-rotation`: OPEN nonzero e diverso dall'ACTIVE; cambiamento uguale a chiusura; cambiamento verso CLOSED oppure REMOVED | `reserved-old-ids-and-unchanged-active`, `invalid-transitions-never-reactivate`, storie di rotazione valida |
| `check-closed-additions`: ID rimosso; ID CLOSED presente con prova diversa | Riattivazione proibita, compaction nuova, ripetizione uguale e conflitti di prova |
| `check-removed-additions`: ID ACTIVE; presenza fra CLOSED oppure REMOVED | `invalid-transitions-never-reactivate` e `idempotent-closures-removals-and-outcomes`: ACTIVE, sconosciuto, CLOSED e già rimosso |
| `apply-manifest-delta`: alias di una delle mappe; ACTIVE nonzero e next-id non decrescente | Guardie di ownership e stato privato; le storie esercitano chiusure, rimozioni, OPEN zero e nonzero e conservazione del limite |
| `fold-manifest-edit`: stato assente/presente e completo ripetuto | `snapshot-required-and-valid`; completo iniziale e delta nelle storie |
| Query: prossimo ID rappresentabile u64; ACTIVE/CLOSED/REMOVED/sconosciuto; CLOSED presente e TXID presente | Tutti gli stati nell'oracle; esaurimento u64, CSN zero distinto da assenza, esiti scomparsi dopo rimozione; query readonly condivise e input riusato |
| API pubblica e default | `direct-api-defaults-and-required-options` omette budget e offset, verifica versioni 1/2, versione obbligatoria, EOF obbligatorio e ownership; il wrapper delle altre fixture passa i keyword esplicitamente |

I nomi abbreviati dei test mantengono il suffisso dei simboli `test-REQ-…`
in [manifest.lisp](../../tests/recovery/manifest.lisp) e
[manifest-audit.lisp](../../tests/recovery/manifest-audit.lisp).
La misura dei rami non è MC/DC. Il gate del motore resta aperto.
