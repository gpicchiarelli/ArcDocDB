# ADR-0011 — Thread pool dinamico con EWMA/AIMD/isteresi

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Thread pool
  dinamico», «Compaction scheduler dinamico»)
- **Riferimenti:** [10 Concorrenza e scheduling](../10-concorrenza-e-scheduling.md), INV-P2,
  INV-P4

## Contesto

Il carico varia per intensità e per distribuzione tra Serie. Un numero fisso di thread è
sbagliato in entrambe le direzioni; creare thread a richiesta è costoso e imprevedibile.

## Decisione

- Un pool dinamico di worker riutilizzati; nessun thread per richiesta né per Serie.
- Lo scheduler adatta il numero di worker in base a: profondità delle code, CPU, throughput,
  P50/P95/P99, numero di Serie attive e distribuzione del carico, I/O, throughput del WAL,
  backlog di compaction.
- Strategia: EWMA per i segnali, AIMD per la variazione, isteresi contro le oscillazioni.
- Regole indicative: coda in crescita e CPU libera → più worker; coda in crescita e CPU satura
  → non aumentare ciecamente; P99 in peggioramento → fermare l'espansione o ridurre; coda
  vuota e CPU bassa → ridurre.
- Lo stesso scheduler coordina query, writer, WAL e compaction.
- Il Compaction Scheduler ha limiti indipendenti dal request scheduler.

## Conseguenze

- Il sistema si adatta senza configurazione manuale del numero di thread.
- Le metriche diventano parte del funzionamento, non solo della diagnosi: devono essere
  economiche e sempre disponibili.
- Un controllore è un componente da progettare, tarare e verificare a sé.

## Alternative considerate

- *Pool fisso pari al numero di core:* semplice e prevedibile, ma inadatto quando molti worker
  sono bloccati in I/O.
- *Pool separati e fissi per tipo di lavoro:* isolamento netto, nessun adattamento.

## Valutazione

- Rischi: RSK-12.
- Verifica: SPK-04 (meccanismo), SPK-06 (controllore su tracce di carico).
- Aperto: definizione degli stati di carico (QA-12); worker bloccati in I/O (QA-19).
- Indicazione: iniziare con pochi segnali e regole semplici; aggiungere segnali solo quando
  una misura mostra che servono.
