# ADR-0024 — Modello di memoria: array specializzati a vita lunga, zero allocazione sul hot path

- **Stato:** Accettata (ipotesi sulle pause verificata da SPK-02)
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-18; realizza «SIMD e ottimizzazioni native» punti 1–5
- **Riferimenti:** [architettura](../architettura.md#memoria), RSK-01

## Contesto

Il collector di SBCL ferma tutti i thread. Le pause dipendono da quanto deve esaminare (oggetti
con puntatori) e copiare (oggetti piccoli vivi), e dalla frequenza (tasso di allocazione).

## Decisione

1. **Tutte le strutture grandi sono array specializzati** (`(unsigned-byte 8)`,
   `(unsigned-byte 64)`) **allocati una volta** e a vita lunga: tabelle dell'indice, key
   arena, versioni trattenute, arena della cache, buffer dei segmenti e di I/O, delta degli
   indici secondari, istogrammi delle metriche. Non contengono puntatori: il collector non li
   esamina; essendo oggetti grandi, non li copia.
2. **Zero allocazione sul hot path**: GET, PUT, lookup, lettura dal segmento, aggiornamento
   delle metriche non allocano nello heap gestito. I risultati si scrivono in buffer forniti
   dal chiamante; i record si passano come (array, inizio, fine). Le interfacce tra moduli
   sono progettate di conseguenza ([architettura](../architettura.md#contratti)).
3. **Crescita** delle strutture per sostituzione: nuova area, copia, scambio atomico, ritiro
   con EBR ([ADR-0016](0016-epoch-based-reclamation.md)). Nessuna struttura cresce «a pezzi»
   con puntatori.
4. **Memoria nello heap gestito**, non esterna: evita pinning esplicito e doppia gestione; gli
   array passati alle chiamate di sistema sono pinnati per la durata della chiamata.
5. **Parametri del collector** fissati all'avvio in funzione della RAM: dimensione dello heap
   dinamico, soglia di allocazione tra collezioni ampia, generazioni tarate perché le
   strutture a vita lunga raggiungano presto la generazione più vecchia.
6. Ogni allocazione residua su un percorso caldo è un difetto e ha una metrica (tasso di
   allocazione per worker).

Pattern: arene e strutture «flat» senza puntatori; zero-allocation hot path (motori di storage
in linguaggi con GC: Cassandra off-heap, Go pebble).

## Conseguenze

- Il GC vede uno heap grande ma quasi privo di puntatori e un tasso di allocazione basso:
  collezioni rare e brevi è l'ipotesi, da misurare.
- Stile di codice vincolato: dichiarazioni di tipo, `simple-array`, niente liste né chiusure
  sui percorsi caldi.

## Alternative considerate

- *Memoria esterna allo heap (alien):* nessun vantaggio sul GC rispetto agli array
  specializzati grandi, e costo di gestione manuale.
- *Oggetti per entry:* esclusi dalla specifica.

## Valutazione

- Verifica: SPK-02 misura le pause con heap da decine di GB e carico sintetico; SPK-01 e
  SPK-05 misurano l'allocazione per operazione (obiettivo: 0 byte).
- Rivedere se: pause oltre l'obiettivo di P99 ([ADR-0028](0028-target-e-obiettivi-di-latenza.md))
  anche con allocazione nulla → sostituire con ADR su collector alternativo o memoria esterna.
