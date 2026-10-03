# Piano di verifica

Attua [ADR-0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md). Il principio: un
requisito è «verificato» solo se esiste un'evidenza **eseguibile e ripetibile** che fallirebbe
se il requisito fosse violato.

## Metodi

| Sigla | Metodo | Evidenza |
|---|---|---|
| `test` | test unitari e di modulo | suite automatica, copertura misurata |
| `prop` | test di proprietà | generazione con seme riproducibile |
| `diff` | test differenziale contro il modello di riferimento | motore e modello eseguono la stessa sequenza; i risultati coincidono |
| `model` | modello del protocollo, esplorato in modo esaustivo | rapporto di esplorazione con numero di stati e invarianti verificati |
| `fi` | fault injection (simulatore e crash reali) | scenari FI, con verificatore e oracolo dopo ogni recovery |
| `fuzz` | fuzzing dei decoder e del protocollo | nessun crash, ogni input malformato rilevato |
| `corr` | corruzione deliberata dei file persistenti | ogni danno rilevato o riparato |
| `mut` | mutation testing | punteggio di mutazione e mutanti sopravvissuti analizzati |
| `soak` | prove di lunga durata con crash ripetuti | nessuna violazione, verificatore pulito |
| `bench` | benchmark riproducibili | minimi di prestazione e costo dei controlli |
| `rev` | revisione con lista di controllo | lista compilata nella modifica |
| `analisi` | analisi statica, compilazione senza avvisi, linter | esito della CI |

Nel file di requisiti i metodi sono indicati come parole chiave: `:test :prop :diff :model
:fi :fuzz :corr :mut :soak :bench :rev :analisi`.

## Copertura

| Classe | Istruzioni e rami | Condizioni nelle decisioni composte | Note |
|---|---|---|---|
| C1 | 100 % (`sb-cover`) | 100 % (equivalente di MC/DC) | le righe non raggiungibili sono elencate e motivate in `docs/affidabilita/copertura-eccezioni.md` |
| C2 | 100 % | decisioni segnalate dal linter | — |
| C3 | ≥ 95 % | — | — |

**Limite dichiarato.** `sb-cover` misura la copertura delle forme e dei rami; non misura
MC/DC. La copertura delle condizioni si ottiene così: lo strumento `lint` estrae le decisioni
composte di C1 in una **tabella delle decisioni**; per ciascuna, la suite deve contenere casi in
cui ogni condizione cambia da sola l'esito (coppie di indipendenza). La tabella è un artefatto
verificato in revisione e dai test di mutazione sugli operatori logici.

## Livelli di test

1. **Unitari/modulo:** ogni modulo prova le proprie funzioni, le proprie condizioni di errore,
   i propri invarianti. I decoder sono provati con vettori noti e con ogni campo ai valori
   limite.
2. **Differenziale:** modello di riferimento in memoria (tabella hash e liste di versioni) con
   la stessa semantica di GET/PUT/DELETE/transazioni/snapshot; sequenze casuali di operazioni
   sul motore e sul modello con confronto di ogni risposta; con crash e recovery simulati, il
   motore deve restare uguale al modello **limitatamente a ciò che era stato confermato**.
3. **Modelli:** protocollo 2PC + recovery; compaction + swap + reclaim; seqlock; esplorati
   esaustivamente su configurazioni piccole e con crash in ogni punto.
4. **Simulazione deterministica:** il sistema intero con tempo, casualità, schedulazione e I/O
   simulati; milioni di scenari per seme; ogni errore riproducibile dal seme.
5. **Crash reali:** `kill -9` a istanti casuali su file system reale; dopo ogni riavvio, il
   verificatore offline e il confronto con l'oracolo.
6. **Corruzione:** per ogni file persistente e ogni tipo di danno, la rilevazione è provata.
7. **Fuzzing:** copertura guidata dei decoder; il corpus entra nei test di regressione.
8. **Saturazione:** ogni limite di risorsa (INV-A8) è portato al superamento; la risposta è un
   rifiuto controllato.
9. **Soak:** carico misto e crash ripetuti per ore, con scrubbing e verifica periodici.

## Revisione e configurazione

- Lista di controllo del [standard di codifica](standard-di-codifica.md#lista-di-controllo-di-revisione-c1)
  per ogni modifica a C1; due letture.
- Nessuna modifica senza requisito tracciato; `make check` obbligatorio.
- **Indipendenza:** l'autore non è l'unico a leggere il codice C1. Mitigazioni: strumenti
  automatici, lista di controllo, rilettura con un secondo revisore (anche automatico)
  **su dati verificabili** (diff, rapporti di copertura, esiti dei test), non su conclusioni.
- Versione di SBCL e hash del core registrati a ogni baseline; baseline firmate.

## Criteri di rilascio di una fase

Una fase è chiusa solo se, per tutti i requisiti che la riguardano:

- [ ] ogni requisito ha le verifiche del suo elenco eseguite e verdi;
- [ ] la copertura raggiunge i valori della tabella per la classe;
- [ ] nessun modello né scenario di fault injection viola un invariante;
- [ ] il verificatore offline è pulito dopo la suite di crash;
- [ ] il punteggio di mutazione di C1 raggiunge la soglia fissata a inizio fase e i mutanti
      sopravvissuti sono spiegati;
- [ ] `make check` è verde; matrice aggiornata; nessuna deviazione non approvata;
- [ ] i rischi con esposizione alta sono mitigati o accettati per iscritto.

## Strumenti (stato)

| Strumento | Stato |
|---|---|
| `tools/check-links.lisp` | attivo |
| `tools/check-trace.lisp` | attivo |
| `tools/lint.lisp` | attivo (divieti, lunghezza, docstring) |
| harness di test e simulatore | Fase 1 |
| esploratore di modelli | Fase 0, SPK-07 |
| verificatore offline `arcdocdb-verify` | Fase 1 (formati definiti) |
| mutation testing | Fase 1 |
| fuzzing | Fase 1 |
