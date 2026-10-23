# ADR-0061 — Conservazione esterna delle prove storiche

- **Stato:** Accettata per la pulizia autorizzata del 2026-10-23
- **Data:** 2026-10-23
- **Riferimenti:** REQ-VAL-001, REQ-AFF-012, INV-X2, INV-X3;
  [registro delle prove](../valutazione/registro-delle-prove.md).
- **Rapporto con la specifica:** nessun cambio al motore o ai formati documentali;
  precisa la conservazione C4 e sostituisce la residenza locale di tutte le prove storiche.

## Contesto

I risultati pubblicati comprendono 52.277 file: copie sorgenti, compilati SBCL,
fixture, log e registri strutturati. Compattare ogni registro singolarmente conserva
il numero elevato di file. Eliminare elementi degli archivi chiusi ne romperebbe
l'inventario; l'autore richiede di mantenere localmente solo i risultati recenti rilevanti.

## Decisione

1. Prima della rimozione, creare uno snapshot completo dei byte pubblicati, un
   inventario SHA-256 per file e un asset esterno compresso. Estrarlo in una
   directory indipendente e confrontare inventario e contenuti con gli originali.
2. Pubblicare archivio e inventario nella release del repository, rileggerli e
   confrontarne gli hash. Registrare nel checkout revisione, hash e istruzioni
   di recupero. Gli originali degli archivi chiusi restano immutati nell'asset.
3. Conservare localmente una sintesi delle campagne recenti rilevanti e le tre
   pubblicazioni CI più recenti. Reindirizzare le citazioni precedenti alla
   revisione Git originale. Nessun force-push o riscrittura della cronologia.
4. `make evidence` verifica i dati e i cataloghi locali; non certifica nuovamente
   i raw esterni. L'audit integrale si esegue esplicitamente dopo il recupero
   verificato. Un riferimento esterno non rappresenta una nuova esecuzione.
5. Compilati, temporanei e copie di lavoro non appartengono alle nuove pubblicazioni.
   I log CI oltre 4 KiB vengono compressi senza perdita; i budget aggregati restano invariati.

## Verifica, conseguenze e rollback

La migrazione conserva 52.277 byte stream originali, compresi fallimenti e fixture.
Gli hash del TAR ricostruito da gzip e zstd coincidono; l'asset scaricato da GitHub
coincide con il locale. Il checkout e la CI ordinaria evitano il ripristino massivo.

La disponibilità del servizio esterno è necessaria per recuperare i raw se manca
una copia offline. La cronologia Git mantiene gli oggetti precedenti: il risparmio
sul checkout non equivale a una riduzione della storia o del download di un clone
completo. Il rollback ripristina le directory dal commit originale o dall'asset
verificato, senza reinterpretare risultati e senza modificare il prodotto.
