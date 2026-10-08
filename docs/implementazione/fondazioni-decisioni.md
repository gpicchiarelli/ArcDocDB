# Decisioni delle fondazioni binarie

Inventario dei predicati composti e casi di regressione, secondo COD-54. I nomi riportati
sono suffissi dei test in [`tests/foundation/`](../../tests/foundation/); tutti portano il
REQ nel nome. Questa tabella non certifica da sola la copertura MC/DC.

| Funzione e decisione | Condizioni e casi |
|---|---|
| `encoding-size`: alias | nessun alias, alias della chiave, alias del valore: `REQ-LIM-001-preflight-no-partial-write` |
| `encoding-size`: chiave e record entro formato | chiave 1/255/256/65.535/65.536; documento massimo, v1 rifiutato: `REQ-LIM-003-key-boundaries`, `REQ-LIM-001-document-boundaries` |
| `encoding-size`: PUT oltre budget | PUT sotto/oltre budget; controllo non PUT con valore: `REQ-LIM-001-document-boundaries`, `REQ-FOR-003-control-record-shapes` |
| `checked-header`: v1 e byte riservato non zero | v1 corto, v2 lungo, reinterpretazione v1 rifiutata: `REQ-LIM-003-key-boundaries`, `REQ-LIM-001-roundtrip-versions` |
| `checked-header`: limiti e disponibilità del record | lunghezza valida, `u32` massimo, troncamenti; chiave già limitata dal campo u16 e dalla guardia v1: `REQ-FOR-003-valid-crc-invalid-fields`, `REQ-FOR-003-every-truncation` |
| `checked-header`: PUT oltre budget | record valido con budget pieno/ridotto; tipi di controllo ammessi: `REQ-LIM-001-document-boundaries`, `REQ-FOR-003-control-record-shapes` |
| `u64-equal-p`: word bassa e alta | entrambe uguali, sola word bassa diversa, sola word alta diversa: `REQ-FOR-004-u64-both-words` |
| `key-equal-p`: lunghezza e contenuto | entrambi uguali, lunghezza diversa, singolo byte diverso: `REQ-AFF-002-index-identity` |
| `check-outcome`: fine, tipo, TXID basso/alto, CSN | prova valida; fine oltre record; tipo PUT; modifica separata delle due word del TXID e del CSN con CRC riparati: `REQ-FOR-004-prepared-outcome`, `REQ-FOR-004-outcome-provenance-fields`, `REQ-FOR-004-u64-both-words` |
| `verifica-put`: fine, tipo, flag, chiave | caso valido e singoli mismatch: `REQ-AFF-002-index-identity`, `REQ-LIM-001-semantic-boundaries` |
| `check-seal`: file, inizio, frontiera, count, checksum | mutazione di ogni campo, con CRC header/body validi: `REQ-FOR-003-batch-seal-semantic-corruption` |
| `verifica-lotto`: numero record, byte, offset u64, file-id per log | ciascuna guardia rifiutata separatamente; segmento con ID, control/multiserie con zero: `REQ-LIM-003-batch-budgets`, `REQ-FOR-003-sealed-batches` |
| `verifica-lotto`: stamp noto e diverso, alla fine e nel lotto | stamp uniforme; record discordante; TXID diverso dal CSN del SEAL: `REQ-FOR-003-batch-stamp-and-type`, `REQ-FOR-004-batch-txid-independent-of-seal-csn` |
| `verifica-lotto`: PUT/TOMBSTONE/EDIT ordinario | ogni tipo ammesso; PUT/TOMBSTONE prepared esclusi dal confronto; OUTCOME e DECISION esclusi: `REQ-FOR-003-sealed-batches`, `REQ-FOR-004-batch-txid-independent-of-seal-csn` |

## Rami interni e lettura della copertura

- `verifica-cornice`: il controllo di coerenza tra lunghezza e range del valore è una
  postcondizione difensiva. Il ramo di errore non è raggiungibile da byte esterni dopo
  `checked-header`; un difetto interno porta `invariant-violation`.
- `verifica-lotto`: dopo `max-records + 1` iterazioni ogni cammino normale ha già restituito
  il SEAL o rifiutato il budget. La coda del ciclo segnala `invariant-violation`.
- `check-value-shape`: il default inatteso è interno; i tipi sconosciuti sono rifiutati
  prima da `allowed-flags`.
- Le definizioni, le proclamazioni e le copie inline non eseguite sono presenti nei
  rapporti SBCL. Nessuna esclusione viene applicata automaticamente al rapporto.

Queste osservazioni motivano l'analisi; non sostituiscono la registrazione e revisione
delle eccezioni di copertura richiesta per il rilascio C1.
