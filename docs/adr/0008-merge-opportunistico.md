# ADR-0008 — MERGE opportunistico: 50 secondi di stabilità + basso carico

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Condizioni
  obbligatorie per Merge», «Low-load merge policy», «Compaction scheduler dinamico»). È la
  regola aggiunta con l'ultima revisione della specifica.
- **Riferimenti:** [07 Compaction](../07-compaction.md#merge), INV-C5, INV-C6, INV-P4

## Contesto

Il MERGE è un'ottimizzazione strutturale: migliora località e numero di segmenti, ma non è
necessario alla correttezza né al recupero di spazio. Eseguito nel momento sbagliato compete
con il traffico utente per CPU, dispositivo, memoria e cache.

## Decisione

Un segmento è candidato a MERGE solo se **tutte** le condizioni sono vere:

1. è `CLOSED`, immutabile, non `ACTIVE`;
2. è fermo da almeno **50 secondi**, misurati dal timestamp di chiusura/stabilizzazione;
3. non è necessario a uno snapshot attivo;
4. appartiene a un gruppo che supera le soglie di segmentazione;
5. il motore è in condizione di **basso carico**.

Il Compaction Scheduler valuta il carico prima di avviare un MERGE (CPU, P95/P99, code,
throughput, WAL e flush, NVMe e I/O queue, backlog, worker attivi). Con carico alto non avvia
MERGE, ne riduce la concorrenza e dà priorità a richieste e WAL. Se il carico cresce durante
un MERGE, non ne avvia altri e può rallentare o sospendere il lavoro non critico.

La regola vale per il **solo MERGE**; il CLEAN non ha vincolo di stabilità.

Priorità: traffico utente > WAL/durability > CLEAN necessario > MERGE opportunistico.

## Conseguenze

- Il MERGE non può peggiorare la latenza di coda nei momenti di carico.
- I segmenti appena chiusi non vengono rilavorati subito.
- Sotto carico sostenuto il MERGE può non partire mai: il sistema deve funzionare bene anche
  con molti segmenti piccoli.
- Serve una definizione operativa e stabile di «basso carico».
- Uno snapshot longevo sospende il MERGE dei segmenti che gli servono.

## Alternative considerate

- *MERGE a soglia, indipendente dal carico:* numero di segmenti sotto controllo, ma
  interferenza con il traffico nei momenti peggiori.
- *MERGE subito dopo il CLEAN:* esplicitamente escluso dalla specifica.

## Valutazione

- Rischi: RSK-08 (MERGE mai eseguito), RSK-12 (instabilità del controllore), RSK-09.
- Verifica: SPK-06; benchmark di burst con MERGE in attesa e in corso.
- Aperto: definizione di basso carico, preemption, eventuale soglia di emergenza (QA-12);
  timestamp di stabilizzazione e riavvio (QA-13); snapshot longevi (QA-14); soglie (QA-11).
