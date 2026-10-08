# ADR-0052 — Header di control.log e multiserie.log

- **Stato:** Accettata; completamento del formato prima del primo codec
- **Data:** 2026-10-08
- **Rapporto con la specifica:** precisa gli offset degli header già previsti
  da [ADR-0040](0040-manifest-a-record-unico.md) e
  [ADR-0041](0041-multiserie-segmenti-autosufficienti.md).
- **Riferimenti:** [formati su disco](../formati-su-disco.md),
  [ADR-0048](0048-limiti-documentali-e-formato-v2.md)

## Contesto

I due log prevedono un header di 64 byte con magic, versione, identità e CRC.
La tabella degli offset era definita soltanto per i segmenti. Un codec richiede
un layout completo e il confronto con l'identità autorevole, prima di affidare
la versione al decoder dei record.

## Decisione

Entrambi i log usano questa intestazione, nelle versioni 1 e 2:

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `char[8]` | `ARCDCTL1` per control; `ARCDMSL1` per multiserie |
| 8 | `u16` | versione del formato dei record, little-endian |
| 10 | `byte[6]` | riservati zero |
| 16 | `byte[16]` | identità della Serie per control; dell'Archivio per multiserie |
| 32 | `byte[24]` | riservati zero |
| 56 | `u32` | CRC32C dei byte 0–55 |
| 60 | `byte[4]` | riservati zero, controllati separatamente dal CRC |

L'identità dell'Archivio è fissata a 16 byte opachi, con confronto esatto;
questo completa un dettaglio finora non definito. Il codec non genera identità.
Il magic resta invariato fra v1 e v2; decide il campo versione. Origine,
segment-id e timestamp non sono campi di questi header. L'identificativo zero
del SEAL dei log resta nel SEAL e non sostituisce l'identità dell'header.

Il chiamante fornisce tipo e identità dalla fonte autorevole. Il decoder verifica
lunghezza, CRC, magic del tipo atteso, versione supportata, tutti i riservati e
identità. Un header incompleto o non integro è un errore di integrità;
la regola della coda si applica ai lotti successivi, dopo un header verificato.
Una versione ignota con CRC corretto è `unsupported-format`.

## Conseguenze

Il primo decoder fissa questo layout: cambiamenti successivi richiedono nuova
versione e migrazione. Non occorre migrare dati di questi log, il cui header
non aveva un codec di prodotto precedente. I record e i punti di atomicità di
EDIT, DECISION e rinomina restano quelli dei rispettivi ADR.

## Alternative considerate

- Copiare origine, ID e timestamp del segmento: introduce campi senza funzione
  per questi log e ambiguità rispetto all'identificativo zero del SEAL.
- Non confrontare tipo o identità: permette di interpretare il file sbagliato.

## Valutazione

Oracolo indipendente, troncamenti, alterazioni di ogni bit, campi invalidi con
CRC corretto, due letture C1, copertura, mutazioni e misura delle allocazioni.
Le prove riguardano il codec in memoria; l'integrazione con apertura dei file,
catalogo e transizioni `FAULTED` resta responsabilità del motore.
