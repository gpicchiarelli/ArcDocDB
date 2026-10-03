# Limiti dimensionali

Limiti che discendono dai [formati su disco](formati-su-disco.md) e dal layout dello slot
del primary index ([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md), slot a 6 parole
per [ADR-0032](adr/0032-seqlock-a-64-bit.md)). Un limite
«hard» cambia solo con un nuovo formato; un limite «pratico» dipende dall'hardware.

## Limiti hard (dai formati)

| Grandezza | Limite | Origine |
|---|---|---|
| Lunghezza di `_id` | 1–255 byte | `key-len u8` nel record e nell'hint |
| Dimensione di un record (intestazione + chiave + documento + CRC) | 16 MiB − 1 | `length` a 24 bit nello slot |
| Dimensione di un documento | 16 MiB − 44 B − `key-len` hard; **default per Serie 4 MiB**, configurabile fino al limite hard | come sopra; catalogo |
| Dimensione di un segmento | 4 GiB − 1 | `offset` a 32 bit nello slot e nell'hint |
| Segmenti per Serie (id distinti nella vita della Serie) | 2³² | `segment-id` a 32 bit nello slot (`u64` su disco) |
| Record per segmento | 2³² | righe `u32` negli indici di segmento e nell'hint |
| Sezione chiavi di un file hint | 4 GiB | `key-off u32` nell'hint |
| Key arena per Serie (somma delle lunghezze delle chiavi) | 1 TiB | `key-off` a 40 bit nello slot |
| Versioni di un documento | 2⁴⁰ ≈ 1,1·10¹² | `version` a 40 bit nello slot (`u64` su disco) |
| Commit (CSN) nella vita di un Archivio | 2⁶⁴ (oltre 580.000 anni a 1 M lotti/s) | `csn u64` su disco e nello slot ([ADR-0032](adr/0032-seqlock-a-64-bit.md)) |
| Transazioni (TXID) | 2⁶⁴ | `txid u64` |
| Serie partecipanti a una transazione multiserie | 65 535 | `n-part u16` in `multiserie.log` |
| Indici secondari per Serie | nessun limite di formato (un file per indice e segmento) | — |
| Valori distinti in un indice `category` o `bitmap` di un segmento | 2³² | dizionario `u32` |

## Limiti pratici (dall'hardware)

| Grandezza | Ordine di grandezza | Che cosa lo determina |
|---|---|---|
| Documenti per server | **~750 milioni per 64 GB di RAM**, ~1,5 miliardi per 128 GB | primary index interamente in memoria: 56 B per entry + la chiave (16 B per gli id generati), lasciando ~15 % a cache e runtime ([stime](valutazione/stime-ordine-di-grandezza.md#memoria-del-primary-index)) |
| Dati per server | limitati dal disco, non dall'indice | a 2 KB per documento ≈ 2 TB per miliardo; documenti più grandi ⇒ più TB a parità di RAM |
| Serie per Archivio | migliaia senza accorgimenti; decine di migliaia con memoria minima per Serie ridotta | ogni Serie ha indice, key arena, buffer dell'`ACTIVE`, partizione di cache, descrittori di file (≥ 1 per segmento aperto) |
| Archivi per server | nessun limite di formato | ogni Archivio aggiunge CSN, coordinatore, `multiserie.log` |
| Segmenti aperti contemporaneamente | limite dei descrittori di file del sistema | ~4.000 segmenti per TB a 256 MB |
| Throughput per Serie | tetto del writer logico ([budget](valutazione/stime-ordine-di-grandezza.md#budget-del-writer-logico)) | si scala distribuendo su più Serie |
| Snapshot attivi | memoria delle versioni trattenute cresce con scritture × durata | durata massima configurabile ([ADR-0020](adr/0020-csn-snapshot-isolamento.md)) |
| Connessioni | limite del sistema operativo | — |

## Che cosa non è limitato

- Numero di campi di un documento e profondità dell'annidamento: solo dalla dimensione del
  documento.
- Numero di documenti per Serie: solo dalla RAM del server (vedi sopra).
- Dimensione dei file di indice e Bloom: proporzionali al segmento.

## Come si estendono i limiti hard

Un limite hard si estende con un nuovo numero di versione del formato e una migrazione
([principi](principi-di-ingegneria.md)). I più probabili candidati sono la dimensione del
record (24 bit) e dei segmenti (32 bit): entrambi vivono nello slot dell'indice e un loro
ampliamento costa 8 byte per entry. Limiti che il sistema applica **anche** come requisito di affidabilità (INV-A8): ogni coda, buffer, richiesta, connessione, snapshot e tentativo ha un valore massimo configurato; il superamento produce un rifiuto esplicito.
