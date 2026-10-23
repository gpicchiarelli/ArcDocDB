# ADR-0044 — La cache è un acceleratore puro

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda; realizza «Cache» e «Cache e snapshot».
  **Sostituisce in parte** [ADR-0025](0025-cache-per-location.md): punto 3 (tabella della
  cache) e punto 5 (ri-etichettatura). Restano: unità = record, chiave = location, CLOCK,
  partizione per Serie con budget dallo scheduler, metrica di scan pollution.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-09;
  [architettura](../architettura.md#percorso-di-lettura); INV-M3, INV-A2, INV-A12

## Contesto

ADR-0025 sceglie bene la chiave: una location in un segmento immutabile non cambia mai
contenuto, quindi la cache non ha bisogno di invalidazione. Ma poi le chiede due cose che la
riportano dentro i protocolli di coerenza: ri-etichettare le entry quando la compaction
riloca un record, ed eliminarle quando un segmento viene reclamato. Inoltre non definisce la
concorrenza di una struttura in cui inseriscono molti reader. Il registro dei rischi (RSK-10)
diceva già: misurare prima di complicare.

## Decisione

1. **Contratto.** La cache è una funzione parziale `(segment-id, offset) → byte del record`.
   Due sole operazioni: *cerca* (copia nel buffer del chiamante, o *miss*) e *inserisci*.
   **Non esistono** invalidazione, ri-etichettatura, svuotamento per segmento. Poiché un
   segment-id non è mai riusato ([ADR-0040](0040-manifest-a-record-unico.md)), una entry non
   può diventare falsa: al più diventa inutile, e CLOCK la espelle.
2. **Il sistema è corretto senza la cache** (INV-A12). Con budget zero ogni lettura va al
   segmento. La cache non compare in alcun protocollo: né nella compaction, né nel reclaim,
   né nel recovery.
3. **Struttura.** Per ogni partizione (Serie) e classe di dimensione, un **insieme
   associativo**: la location seleziona un insieme di 8 posti contigui; ogni posto ha
   un'etichetta (la location), un contatore seqlock, un byte di riferimento per CLOCK, e
   l'area dati in un'arena di byte. Nessuna tabella hash separata, nessun sondaggio oltre
   l'insieme: il costo di ogni operazione è limitato per costruzione.
4. **Reader senza lock.** Confronta le etichette dell'insieme; sul posto trovato legge
   contatore, etichetta e byte, e di nuovo il contatore — lo stesso protocollo seqlock
   dell'indice ([ADR-0032](0032-seqlock-a-64-bit.md)). Contatore dispari o cambiato: **miss**.
   Non ci sono nuovi tentativi: il ripiego è la lettura dal segmento.
5. **Inserimento opportunistico.** Dopo una lettura dal segmento, il reader prova ad
   acquisire **senza attesa** il mutex della striscia a cui appartiene l'insieme; se è
   occupato rinuncia. Con il mutex: sceglie la vittima con CLOCK, porta il contatore a
   dispari, scrive etichetta e byte, lo riporta a pari.
6. **Verifica.** Ogni record ottenuto dalla cache passa la stessa verifica in lettura di un
   record letto da disco ([ADR-0039](0039-cornice-unica-dei-record.md) §4). Se fallisce: il
   posto viene liberato, l'evento è contato (`cache-verify-failed`, con allarme: indica
   memoria alterata o un difetto), e **si rilegge dal segmento**. Solo una verifica fallita
   su una lettura dal segmento porta alla quarantena: la cache non può accusare il disco.
7. **Calore dopo la compaction.** I record rilocati tornano in cache alla prima lettura
   successiva, dalla page cache del sistema operativo, dove la compaction li ha appena
   scritti. La perdita è misurata (SPK-05); se una misura mostra che pesa, un nuovo ADR
   valuta il trasferimento.

Pattern: cache a insiemi associativi con sostituzione CLOCK (cache dei processori;
HyperClockCache di RocksDB: tabella a dimensione fissa, letture senza lock); chiave per
posizione fisica immutabile (block cache per file immutabili).

## Conseguenze

- La cache esce dall'insieme dei componenti che possono compromettere la coerenza: un suo
  difetto produce al più un *miss* o una rilettura. La sua politica (CLOCK, budget) è di
  classe C3; il percorso di copia e verifica resta C1.
- La compaction e il writer non toccano la cache.
- Due letture della stessa location possono collidere nello stesso insieme: è una questione
  di efficienza, misurata dalla hit rate.

## Alternative considerate

- *Ri-etichettatura alla rilocazione (ADR-0025):* conserva il calore, ma fa scrivere al writer
  una struttura condivisa con i reader e rende la cache parte del protocollo di compaction.
- *Mutex anche in lettura:* più semplice da verificare, ma mette un lock sul percorso di
  lettura, che il progetto esclude.
- *Nessuna cache propria, solo la page cache:* il più snello; la specifica chiede una cache
  partizionabile per Serie contro i burst, che la page cache non offre. Con questo ADR la
  scelta resta aperta a costo zero: budget zero.

## Valutazione

- Rischi: RSK-10 (accettato, misurato da SPK-05).
- Verifica: test differenziale con cache attiva e con budget zero (stesse risposte);
  stress con inserimenti concorrenti e verifica; iniezione di bit flip nell'arena (rilevata,
  riletta, mai quarantena).
