# Decisioni dei metadati storage

Inventario COD-54; i nomi sono suffissi dei test in
[`tests/storage/`](../../tests/storage/), tutti con REQ. Non è certificazione MC/DC.

| Funzione e predicato composto | Condizioni e prove |
|---|---|
| `spazio-ripetuto`: width positivo, start ≤ end | successo, width zero, range inverso: `REQ-AFF-008-internal-range-guards`; count oltre spazio: `REQ-AFF-008-edit-cumulative-budget-and-corrupt-huge-counts` |
| `scrivi-header-segmento`: origine writer/compaction | 1/2 e valori invalidi: `REQ-FOR-002-segment-header-independent-oracle`, `REQ-FOR-002-segment-header-preflight-preserves-buffer` |
| `verifica-header-segmento`: magic entrambe word | valido e alterazione separata di ogni word con CRC valido: `REQ-FOR-002-segment-header-crc-valid-invalid-fields` |
| `verifica-header-segmento`: origine 1 o 2 | entrambe valide, 0/3 invalidi: stessi test dell'oracolo e campi invalidi |
| `verifica-riservati`: tre aree zero | tutte zero; un byte non zero in ciascuna area: `REQ-FOR-002-segment-header-crc-valid-invalid-fields` |
| `verifica-header-segmento`: identità Serie e segmento | ciascun byte Serie diverso, word bassa/alta segment-id diversa: `REQ-AFF-002-segment-header-identity` |
| `verifica-lunghezza-chiusa`: high u32 zero, low almeno 64 ed entro u32 | 64, 4 GiB−1 validi; 0/63, 2^32 e massimo u64 invalidi: `REQ-FOR-003-edit-truncation-counts-and-lengths`, `REQ-AFF-008-edit-cumulative-budget-and-corrupt-huge-counts`. Il massimo è già imposto dal tipo u32 del low. |
| `valida-valore-edit`: flags 0 o completo | entrambi validi e 1/2/9/255 invalidi: `REQ-FOR-003-edit-encoding-layout`, `REQ-FOR-003-edit-truncation-counts-and-lengths` |
| `valida-valore-edit`: ordinario e next-id diverso da zero | ordinario zero/nonzero; completo massimo u64: stessi test di layout e campi invalidi |
| `cornice-di-controllo`: fine esatta e tipo atteso | entrambi validi; byte finale extra; tipo diverso: `REQ-FOR-003-control-record-integrity-before-counts`, `REQ-FOR-003-decision-record-all-truncations-and-bit-flips` |
| `preflight-edit`: alias chiusi o rimossi | nessun alias, ciascun input alias: `REQ-AFF-008-encoder-preflight-no-partial-write` |
| `preflight-edit`: completo oppure next-id zero | ordinario valido/invalidato; completo massimo u64: layout e preflight |

## Decisioni semplici significative

Budget byte prima del CRC: `REQ-AFF-008-byte-budget-before-crc-scan`. Conteggi,
esiti cumulativi e capienza: test di budget e count corrotti. Consumo esatto:
troncamenti e byte aggiuntivi. Preflight: destinazione invariata a ogni rifiuto.
DECISION: count 2/3/65.535 validi, 0/1 invalidi, encoder 65.536 rifiutato.

## Ramo interno e copertura

`scandisci-chiusi` inizia da start e ogni avanzamento è restituito da
`spazio-ripetuto`, che esige start ≤ end, controlla il count prima della
moltiplicazione e restituisce un offset ≤ end. Il controllo finale `closed-range`
è difensivo contro un difetto interno; dati esterni non possono prenderne il ramo
di errore dopo questi controlli. Non si forza il ramo con un mock per presentare
una copertura completa. Le forme di definizione/proclamazione restano nel rapporto.

Questa spiegazione motiva la lettura dei dati; le eccezioni di copertura e la
revisione indipendente restano criteri da chiudere per il rilascio C1.
