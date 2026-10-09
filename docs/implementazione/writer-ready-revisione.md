# Revisione della lista dei writer pronti

Ambito C1: i due sorgenti della lista pronta, API/ASDF e composizione con
handoff. Nessun cambiamento persistente o qualifica dell'intero scheduler.

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0045 §§6/8, ADR-0005. La lista pronta condivisa è toccata per tratto, senza coda comune per richiesta. |
| 2. Invarianti | FIFO locale, esclusività della guard, capacità finita e proprietà dell'obbligo. La macchina del writer resta nel precedente handoff; nessuna seconda membership da sincronizzare. Oracoli e prove concorrenti sono verificati nella campagna separata. |
| 3. Errori | Input invalidi/full/busy precedono la mutazione. Busy della scansione è un risultato senza condizioni; il worker conserva il riferimento preso durante busy di avvio. Invarianti segnalati al proprietario per fail-stop, senza rollback o controller implicito. |
| 4. Limiti | Factory <=64 partizioni; scansione <=64 acquisizioni, <=128 CAS inclusi i rilasci. Nessun retry, spin, ricorsione o attesa nel prodotto; ring <=65536 slot. |
| 5. Allocazioni | Strutture/ring all'avvio; nessuna allocazione esplicita nel percorso normale. La campagna misura la composizione handoff/lista, non startup o condizioni d'errore; si riporta il heap osservato senza promessa universale. |
| 6. Dati | La lista trasporta riferimenti al tipo writer verificato; non interpreta payload o dati persistenti e non legge lo stato del writer. Nessun callback, I/O o risposta del motore. |
| 7. Decisioni | Controlli scalari separati, CASE/default e cleanup inventariati. Nessun nuovo and/or composto; raw ed esiti restano nel denominatore completo senza esclusioni approvate o MC/DC implicita. |
| 8. Proprietà | Partizioni/slots/capacity privati e read-only dove applicabile, copier assenti. Indici e contenuti sotto guard, cursore locale del worker. Obbligo caller→ring→worker; esattamente una pubblicazione è una precondizione del chiamante. |
| 9. Check | `make check` su 33aa224: 294 test più smoke, lint su 52 file senza violazioni, trace/link/evidence e dieci spike superati; record 4000522904-command-41347-0 OK/STABLE/exit0. I gate del motore restano aperti. |
| 10. Standard | Safety3, ftype/slot tipizzati, docstring, funzioni <=60 righe e complessità <=7. Strumenti C4 con self-test e preservazione dei rapporti parziali; nessuna deviazione introdotta. |
| 11. Parallelismo | Guard indipendenti per partizione, nessuna guard/contatore globale, nessuna scrittura comune per messaggio. Il lavoro dei writer avviene fuori dalle guard della ready list. Non si promettono lock-freedom, bilanciamento o starvation temporale. |
| 12. Atomicità | Nessun cambiamento durevole o eliminazione. La pubblicazione e il prelievo FIFO avvengono sotto la guard locale; non esiste cleanup scheduler che possa cancellare un'ondata successiva del writer. |

La prima lettura indipendente ha chiesto due precisazioni delle docstring,
chiuse nei sorgenti: cleanup dopo acquisizione verificata; allocazioni del
solo percorso normale. L'[inventario](writer-ready-decisioni.md) conserva
hash iniziali e finali e i confini della lettura.

Risvegli, parcheggio dopo empty, arresto dei worker, controller e pool
adattivo richiedono integrazione. La lista non garantisce progresso se il
chiamante duplica o abbandona l'obbligo. Questo limite non viene nascosto
dal risultato positivo di una fixture FIFO isolata.

## Chiusura della verifica integrata

La lettura indipendente iniziale conserva i dodici punti e i due rilievi
chiusi. Le appendici verificano l'integrazione con `fd96fb3`, `201562d` e infine `33aa224`, il runner
C4 corretto e il check completo, con gli stessi sorgenti ready e test.
Il runner separa segnali OS e fallimenti dopo completion reale dai mutanti
rilevati: SIGKILL effettivo è `:worker-error`; la campagna ripetuta rileva
12/12 mutanti con signal NIL e nessun worker error. Le due campagne e le
versioni degli strumenti rimangono nel
[catalogo](../../spikes/results/2026-10-09-writer-ready/catalogo.lisp), insieme
alle letture originali, probe e rapporti di processo. Nessuna esclusione
approvata, MC/DC completa o qualifica del pool viene dedotta dai risultati.
