# ADR-0035 — Strategia di verifica e tracciabilità

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** realizza «Fault injection» e «Benchmark»; aggiunge la
  tracciabilità. Nessuna emenda.
- **Riferimenti:** [piano di verifica](../affidabilita/piano-di-verifica.md),
  [tracciabilità](../tracciabilita/README.md), INV-A5

## Contesto

L'affidabilità non si dichiara: si dimostra con evidenze. Serve una strategia che renda ogni
requisito verificato, ogni verifica ripetibile e ogni collegamento controllabile da uno
strumento (ADR-0031 §2d).

## Decisione

### 1. Tracciabilità bidirezionale controllata da strumento

- I **requisiti** hanno identificativo `REQ-<area>-<nnn>`, derivano dalla specifica o dagli
  ADR, e sono elencati nel file di dati
  [`requisiti.lisp`](../tracciabilita/requisiti.lisp) con: fonte, testo, classe di integrità,
  invarianti, ADR, metodo di verifica, scenari FI.
- La **matrice di tracciabilità** ([matrice.md](../tracciabilita/matrice.md)) è **generata**
  da quel file; `make trace` fallisce se: un riferimento a INV/ADR/FI non esiste; un
  requisito non ha verifica; un invariante o uno scenario FI non è coperto da alcun
  requisito; la matrice committata non è quella generata.
- **Dal codice:** ogni definizione di prodotto e ogni test riportano il requisito in un
  commento `;;; REQ: REQ-…` (e il nome del test inizia con l'ID). Appena esiste codice,
  `make trace` verifica che ogni requisito con stato «implementato» abbia almeno un
  riferimento nel codice e uno nei test, e che ogni riferimento indichi un requisito
  esistente. Ogni commit di codice riporta `Refs:` con gli ID.

### 2. Ambiente iniettabile e simulazione deterministica

Tempo (orologio monotono e reale), casualità, schedulazione dei thread e I/O passano da
**interfacce iniettabili**. In test, il sistema gira in un **simulatore deterministico**:
un solo flusso di esecuzione cooperativo guidato da un seme, con I/O simulato che inietta
crash, scritture parziali, errori, corruzioni, e con la schedulazione esplorata per seme. Ogni
fallimento è riproducibile dal seme. Pattern: FoundationDB, TigerBeetle.

### 3. Livelli di verifica

1. **Ispezione e analisi:** revisione con lista di controllo; compilazione senza avvisi;
   linter.
2. **Test unitari e di modulo**, con copertura 100 % di istruzioni e rami per C1
   (`sb-cover`) e **copertura delle condizioni** nelle decisioni composte di C1 (equivalente
   di MC/DC: ogni condizione mostrata decisiva indipendentemente; elenco generato dal
   linter e tabella delle decisioni nel piano di verifica).
3. **Test di proprietà** e **test differenziale** contro un modello di riferimento in memoria
   (stessa sequenza di operazioni sul motore e sul modello: i risultati devono coincidere,
   anche dopo crash e recovery simulati).
4. **Modelli dei protocolli** (2PC, compaction/swap/reclaim, seqlock) esplorati in modo
   esaustivo su configurazioni piccole (SPK-07).
5. **Fault injection** (FI-01…FI-13) nel simulatore e con crash reali (`kill -9`) su file
   system reale; dopo ogni recovery, il verificatore offline e l'oracolo.
6. **Fuzzing** di tutti i decoder (record, hint, indici, Bloom, control log,
   `multiserie.log`, catalogo, protocollo): nessun crash, nessun errore non dichiarato,
   nessuna lettura fuori limiti; ogni input malformato è *rilevato*.
7. **Corruzione deliberata**: per ogni file persistente, ogni tipo di danno (bit, byte,
   troncamento, blocco azzerato, blocco duplicato) deve essere rilevato (INV-A2, INV-F1).
8. **Mutation testing** sui moduli C1: la suite deve uccidere i mutanti (operatori, limiti,
   ordine di chiamata); i sopravvissuti sono difetti della suite.
9. **Soak test** con carico misto, crash ripetuti e verifica periodica.
10. **Benchmark** riproducibili per i minimi di prestazione e per i costi dei controlli.

### 4. Gestione della configurazione

- Versione di SBCL fissata e registrata; compilazione riproducibile; hash del core registrato
  nelle note di rilascio.
- Baseline firmate (tag) a ogni gate di fase; changelog; ADR per ogni cambio di decisione.
- Nessuna modifica a codice C1 senza: requisito tracciato, test, revisione con lista di
  controllo, matrice aggiornata.

### 5. Criteri di rilascio

Un gate di fase si supera solo se: tutti i requisiti della fase hanno verifica eseguita e
verde; copertura per classe raggiunta; nessuna violazione di invarianti nei modelli e nel
fault injection; nessun rischio alto non mitigato; deviazioni solo se registrate e approvate.

## Conseguenze

- Il sistema è progettato per essere testato in simulazione: i moduli non accedono a tempo,
  casualità, thread, I/O se non tramite le interfacce (contratto 7 in
  [architettura](../architettura.md#contratti)).
- Il costo di verifica è una parte maggiore del lavoro del codice: è voluto.

## Alternative considerate

- *Soli test di esempio:* non coprono gli interleaving né le combinazioni di guasto.
- *Linguaggi di specifica e verifica esterni (TLA+, Alloy, model checker in altri linguaggi):*
  esclusi per decisione dell'autore (2026-10-03): per ora anche gli strumenti di verifica sono
  solo Common Lisp (INV-X3). I modelli dei protocolli sono programmi Common Lisp con un
  esploratore proprio. Si riesamina con un nuovo ADR, non prima.
- *Metodi formali completi sul codice:* fuori portata per un progetto in Common Lisp con
  singolo autore; si adottano modelli esplorabili dei protocolli, dove il rapporto
  costo/beneficio è massimo.

## Valutazione

- Rischi: RSK-20.
- Verifica: `make trace` e `make lint` in CI; SPK-07 e SPK-09 in Fase 0.
