# ADR-0047 — Verifica indipendente del CSN di un record prepared

- **Stato:** Accettata
- **Data:** 2026-10-08
- **Rapporto con la specifica:** nessuna emenda; rafforza la verifica in lettura del punto 4
  di [ADR-0039](0039-cornice-unica-dei-record.md), in applicazione di INV-A2.
- **Riferimenti:** [SPK-09](../../spikes/SPK-09-integrity/README.md), INV-A2, INV-S7,
  REQ-FOR-004, FM-11.

## Contesto e controesempio

Nel record ordinario `stamp` è il CSN e si confronta con l'indice. Nel record prepared è il
TXID: la prima regola di ADR-0039 controllava solamente che anche la entry avesse il flag
prepared. Due record prepared per la stessa chiave, della stessa lunghezza, possono
appartenere a commit diversi. Una location corrotta in RAM può indirizzare il record
sbagliato: entrambi i CRC sono validi, chiave e flag coincidono, ma la versione restituita
non è quella dell'indice o dello snapshot.

## Decisione

1. Un controllo di CRC, chiave e flag di un prepared è **soltanto parsing**. Per restituire
   il valore al chiamante occorre verificare il suo CSN effettivo.
2. Il reader risolve il TXID attraverso la fonte autorevole del segmento: un record OUTCOME
   nello stesso segmento, oppure gli esiti dell'EDIT che lo ha chiuso in recovery.
   Anche la prova è letta e verificata prima di usarne TXID e CSN.
3. Il TXID della prova deve coincidere con `stamp` del record; il CSN della prova deve
   coincidere con il CSN della entry. Una prova assente, alterata o incoerente produce errore
   di integrità, mai un valore.
4. La ricerca può usare un indice derivato e una cache, ma la prova durevole resta la fonte
   di verità. Il verificatore deve controllare anche l'identità della prova, così una
   location errata nell'indice di risoluzione non viene accettata. Le strutture hanno limiti
   proporzionali ai record del segmento. Nessun lookup modifica stato condiviso tra Serie.
5. Il valore risolto negli hint è utile alla ricostruzione dell'indice; da solo non esenta
   dalla verifica in lettura. Dopo CLEAN/MERGE il record è ordinario e non ha questo costo.

Non cambia alcun formato su disco né il layout a quattro parole dell'indice. Il costo
aggiuntivo riguarda i record prepared non ancora normalizzati dalla compaction: è una
ricerca e verifica della prova. Il budget del resolver e la sua cache sono da misurare in
SPK-05, senza rimuovere il confronto quando il resolver non è disponibile.

## Verifica e limiti

SPK-09 usa un OUTCOME reale nella cornice di ADR-0039, verifica i CRC e confronta TXID e
CSN; deve rifiutare una prova riferita a un'altra transazione o versione. La lettura di una
prova dal manifest, la ricerca posizionale, la cache e gli errori di I/O appartengono al
futuro motore. I test dello spike non promuovono il resolver a componente implementato.
