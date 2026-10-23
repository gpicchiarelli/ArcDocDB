# ADR-0048 — Limiti documentali e formato v2

- **Stato:** Accettata per il progetto; implementazione e verifica da produrre.
- **Data:** 2026-10-08
- **Rapporto con la specifica:** precisa il contratto documentale; sostituisce in parte ADR-0014 (limiti), ADR-0039 (key-len), ADR-0043 (slot). Non cambia atomicità, parallelismo o reclaim.
- **Riferimenti:** INV-F1, INV-A8, REQ-LIM-001…003.

## Decisione

1. Un documento CBOR deterministico occupa al massimo **16 MiB esatti (16.777.216 byte)**, inclusa la sua codifica CBOR, esclusi chiave e header dello storage. Questo è anche il default; una Serie può configurare un massimo inferiore. Il limite si applica ai byte non compressi.
2. Un documento ammette **100 livelli di contenitori**: una mappa o un array radice conta come livello 1; ogni mappa o array annidato aggiunge 1. Chiavi e valori della mappa sono attraversati. Il decoder mantiene contatori e budget espliciti; non dipende dallo stack nativo. Nodi, byte, richieste e risposte hanno budget distinti. Il documento viene validato prima di essere ammesso al writer.
3. `_id` resta una sequenza binaria confrontata byte per byte, lunga **1–65.535 byte**. Il default ammette l'intero intervallo; limiti inferiori sono configurabili per Serie. Gli identificatori generati restano di 16 byte. Non si introduce la semantica dei tipi BSON; l'estensione a 65.535 byte è una scelta ArcDocDB, non un limite copiato da MongoDB.
4. Record e hint adottano **versione di formato 2**. La cornice resta di 24 byte: offset 10 è `u16 key-len`, senza byte riservato a 11; CRC header e body invariati. Lunghezza massima PUT: **16.842.775 byte** (24 + 65.535 + 16.777.216). Le entry hint restano di 24 byte: `u32 offset`, `u32 len`, `u64 csn`, `u32 key-off`, `u16 key-len`, `u8 tipo`, `u8 flag`.
5. Slot primario: **5 parole u64**, più controllo (41 byte/slot): CSN; location; `key-off(32) · key-len(16) · flag(8) · riservato(8)`; seqlock; `record-len(32) · riservato(32)`. Versioni trattenute aggiungono una parola. I frammenti restano limitati in slot; la copia delle chiavi ha anche un budget di byte, tempo e memoria. Non si prealloca l'arena per tutte le chiavi massime. L'esaurimento del budget rifiuta l'operazione prima del commit, senza conferme parziali.
6. I segmenti mantengono target 256 MiB e limite 4 GiB − 1. Nessun limite fisso alla dimensione totale della Serie, oltre a identificativi, risorse e filesystem. Il record e il suo SEAL devono rientrare nel segmento: si ruota prima dell'append se necessario.

## Versionamento e migrazione

I decoder scelgono il layout dalla versione del file; non interpretano v1 come v2. Gli spike esistenti restano esperimenti v1 e le loro misure non verificano v2. Un convertitore offline legge v1, scrive e verifica v2 in nuovi file, pubblica il nuovo manifest con EDIT e conserva i sorgenti fino al reclaim. Mai aggiornamenti in-place. Tale convertitore è progettato, non implementato.

## Costi e verifica

+8 byte per slot rispetto ad ADR-0043; chiavi lunghe aumentano hashing, confronto, memoria e costo di split. Le stime precedenti non sono capacità garantite del nuovo layout.

Verifiche richieste: documenti di 16 MiB accettati e 16 MiB + 1 rifiutati; profondità 100/101; chiavi 1/255/256/65.535/65.536; entrambe le versioni e versioni sconosciute; lunghezze corrotte, troncamenti, saturazione dei budget; crash durante conversione. Il gate v2 precede l'implementazione del motore.

## Riferimento esterno

MongoDB limita il documento BSON a 16 MiB e l'annidamento a 100 livelli. Le dimensioni complessive di collection/database dipendono da risorse e filesystem. Questi sono riferimenti di prodotto, non equivalenza di formati o prestazioni: [limiti ufficiali](https://www.mongodb.com/docs/manual/reference/limits/) (consultati il 2026-10-08).
