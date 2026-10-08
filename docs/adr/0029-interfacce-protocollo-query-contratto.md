# ADR-0029 — Interfacce: protocollo a frame CBOR, query come dati, contratto della Serie

- **Stato:** Accettata (dettagli di superficie rinviati alla fase 8–9 della roadmap)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-20 e QA-21
- **Riferimenti:** [architettura](../architettura.md#interfacce), [ADR-0014](0014-formato-record-documento-id.md)

## Decisione

### Protocollo di rete

- TCP, **frame binari a lunghezza prefissata** (`u32 len` + corpo CBOR), richieste con
  identificativo per il multiplexing sulla stessa connessione, risposte in qualsiasi ordine.
- Lo stesso vocabolario CBOR serve per documenti, richieste e risposte: un solo codec.
- Nessuna compatibilità con protocolli di altri database.
- Autenticazione e cifratura: fuori scope v1 ([ADR-0030](0030-scope-v1.md)); il protocollo
  prevede un campo di versione e un handshake estendibile.

### Query

- Le query sono **dati** (una struttura CBOR, in Lisp una s-expression): predicati su campi
  (`=`, `<`, `prefix`, `in`, `and/or/not`), ordinamento, limite, proiezione, uso esplicito
  o automatico degli indici. Nessun linguaggio testuale nella v1: un parser testuale può
  essere aggiunto sopra senza toccare il motore.
- Il Query Engine compila la query in una pipeline di iteratori su indici di segmento
  ([ADR-0026](0026-indici-secondari-segmentati.md)) con filtro di visibilità e fetch dei
  documenti.

### Contratto della Serie

- Il contratto è un documento CBOR nel catalogo: campi dichiarati con tipo, obbligatorietà e
  vincoli semplici; indici con tipo e campo; politica per i campi non dichiarati (ammessi o
  rifiutati).
- Validazione al momento della scrittura, nel worker che riceve la richiesta (fuori dal
  writer).
- **Evoluzione additiva**: aggiungere campi opzionali e indici è sempre ammesso; rimuovere o
  cambiare tipo richiede una nuova versione del contratto e i documenti esistenti restano
  validi rispetto alla versione con cui furono scritti (il record porta la versione del
  contratto nell'intestazione CBOR del documento).

Pattern: protocolli a frame length-prefixed con multiplexing (Redis RESP3, PostgreSQL wire);
query come AST dati (MongoDB, Datalog); evoluzione additiva degli schemi (Protocol Buffers).

## Conseguenze

- Un solo codec e un solo formato dati da un capo all'altro.
- Il motore è indipendente dalla sintassi: linguaggi testuali e driver sono livelli sopra.

## Contratto documentale v2

[ADR-0048](0048-limiti-documentali-e-formato-v2.md) definisce documenti CBOR fino a 16 MiB e 100 livelli. Il budget di frame è distinto dal documento: deve ammettere un documento massimo più chiave e envelope della richiesta, con un limite esplicito e verifica della lunghezza prima di allocare. I batch hanno budget separati e non sono ammessi senza limite.
