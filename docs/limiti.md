# Limiti dimensionali

Limiti che discendono dai [formati su disco](formati-su-disco.md) e dal layout dello slot
del primary index ([ADR-0043](adr/0043-primary-index-a-frammenti.md)). Un limite «hard»
cambia solo con un nuovo formato; un limite «pratico» dipende dall'hardware. Le cifre dei
limiti pratici sono **stime** (INV-X2), da sostituire con le misure degli spike.

## Limiti hard (dai formati)

| Grandezza | Limite | Origine |
|---|---|---|
| Lunghezza di `_id` | 1–65.535 byte | `key-len u16` v2 nel record e nell'hint |
| Dimensione di un record (intestazione + chiave + documento) | 16.842.775 byte per PUT | documento + chiave + header; lunghezza u32 nello slot v2 |
| Dimensione di un documento | **16 MiB esatti**, default e massimo; limite inferiore configurabile | documento CBOR non compresso, esclusi header e chiave; ADR-0048 |
| Dimensione di un segmento | 4 GiB − 1 | `offset` a 32 bit nello slot e nell'hint |
| Segmenti per Serie (id distinti nella vita della Serie, mai riusati) | 2³² | `segment-id` a 32 bit nello slot (`u64` su disco); all'esaurimento la Serie rifiuta le scritture |
| Record per segmento | 2³² | righe `u32` negli indici di segmento e nell'hint |
| Sezione chiavi di un file hint | 4 GiB | `key-off u32` nell'hint |
| Commit (CSN) nella vita di un Archivio; è anche il numero di versione di un documento | 2⁶⁴ (oltre 580.000 anni a 1 M lotti/s) | `stamp u64` nel record, parola 0 dello slot ([ADR-0038](adr/0038-orizzonte-di-visibilita.md)) |
| Transazioni multiserie (TXID) | 2⁶⁴ | `stamp u64` |
| Serie partecipanti a una transazione multiserie | 65 535 | `n-part u16` in `multiserie.log` |
| Indici secondari per Serie | nessun limite di formato (un file per indice e segmento) | — |
| Valori distinti in un indice `category` o `bitmap` di un segmento | 2³² | dizionario `u32` |
| Profondità documentale | 100 livelli di mappe/array, radice inclusa | ADR-0048; controllo nel decoder |

Il formato v2 usa slot a 5 parole (41 B più chiavi), offset delle chiavi a 32 bit e budget espliciti per le arene. Il formato v1 e gli esperimenti esistenti non sono evidenze del nuovo layout.

## Limiti pratici (dall'hardware)

| Grandezza | Ordine di grandezza | Che cosa lo determina |
|---|---|---|
| Documenti per server | nessun massimo universale; capacità residente da rimisurare per v2 | indice primario in RAM; slot 41 B più chiavi e risorse; percorso oltre RAM in ADR-0049, ancora proposto |
| Dati per server | limitati dal disco, non dall'indice | a 2 KB per documento ≈ 2 TB per miliardo; documenti più grandi ⇒ più TB a parità di RAM |
| Serie per Archivio | migliaia senza accorgimenti | ogni Serie ha almeno un frammento di indice (~0,3 MB), i buffer dei lotti, una partizione di cache, descrittori di file (≥ 1 per segmento aperto) |
| Archivi per server | nessun limite di formato | ogni Archivio aggiunge CSN, orizzonte, coordinatore, `multiserie.log` |
| Segmenti aperti contemporaneamente | limite dei descrittori di file del sistema | ~4.000 segmenti per TB a 256 MB |
| Throughput per Serie | tetto del writer logico ([budget](valutazione/stime-ordine-di-grandezza.md#budget-del-writer-logico)) | si scala distribuendo su più Serie |
| **Query su un indice secondario** | costo proporzionale al **numero di segmenti** della Serie | gli indici sono per segmento ([ADR-0026](adr/0026-indici-secondari-segmentati.md)): una query di uguaglianza consulta un filtro per segmento, una di intervallo l'indice di ogni segmento non escluso da min/max. Con ~4.000 segmenti per TB è il primo limite che una Serie grande incontra: da misurare, con l'indice riassuntivo per Serie come rimedio previsto |
| Snapshot attivi | numero massimo configurato; memoria delle versioni trattenute cresce con scritture × durata | durata massima configurabile ([ADR-0020](adr/0020-csn-snapshot-isolamento.md)) |
| Commit in volo per Archivio | capacità configurata del registro (default proposto 256) | oltre, i writer non chiudono nuovi lotti; si parcheggia entro limiti di byte e tempo ([ADR-0046](adr/0046-orizzonte-con-registro-limitato.md)) |
| Tombstone su disco | al più quanti sono i record morti non ancora recuperati, più i falsi positivi dei filtri (~1 %) | [ADR-0042](adr/0042-tombstone-e-indice-dei-vivi.md) |
| Worker di I/O | tetto configurato | concorrenza sul dispositivo e pausa del GC (SPK-02) |
| Connessioni | limite del sistema operativo | — |

## Che cosa non è limitato

- Numero di campi: entro dimensione e budget del decoder; annidamento massimo 100 livelli.
- Numero di documenti per Serie: solo dalla RAM del server (vedi sopra). I documenti
  **eliminati** non occupano memoria.
- Dimensione dei file di indice: proporzionali al segmento.

## Come si estendono i limiti hard

Un limite hard si estende con un nuovo numero di versione del formato e una migrazione
([principi](principi-di-ingegneria.md)). I più probabili candidati sono la dimensione del
record (32 bit in v2) e dei segmenti (32 bit): entrambi vivono nello slot dell'indice e un loro
ampliamento costa 8 byte per slot.

Limiti che il sistema applica **anche** come requisito di affidabilità (INV-A8): ogni coda,
buffer, richiesta, connessione, snapshot, lista di parcheggio e tentativo ha un valore massimo
configurato; il superamento produce un rifiuto esplicito.

## Capacità oltre la RAM

[ADR-0049](adr/0049-capacita-oltre-la-ram.md) propone un indice persistente con cache limitata per Serie. Richiede un esperimento e una decisione sul formato prima dell’adozione; non è una funzione disponibile.
