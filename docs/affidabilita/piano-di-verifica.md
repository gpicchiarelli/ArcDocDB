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
3. **Modelli:** protocollo 2PC + recovery; compaction + swap + reclaim; seqlock; lotto e
   frontiera durevole; orizzonte di visibilità e registro degli snapshot; segmenti
   autosufficienti; tombstone; divisione di un frammento; un crash prima e dopo ogni
   [punto di atomicità](../analisi-progettuale.md#punti-di-atomicità); esplorati
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
10. **Parallelismo (INV-P6):** benchmark di scalabilità con il numero di Serie e di core, e
    di isolamento (un burst su una Serie non altera latenza e throughput delle altre); la
    revisione controlla che l'elenco di ciò che le Serie condividono resti quello di
    [architettura](../architettura.md#archivio-coordinamento-minimo).

## Interfaccia locale Unix socket

[ADR-0055](../adr/0055-interfaccia-locale-unix-socket.md) aggiunge
REQ-IPC-001…REQ-IPC-004 e INV-N1, tutti ancora **progettati**.
Le prove esistenti del motore non verificano un listener o un client locale.
La prima integrazione M16, anticipata nella [roadmap](../roadmap.md), deve
produrre queste evidenze con due processi reali e I/O iniettabile:

| Requisito | Evidenza da realizzare |
|---|---|
| REQ-IPC-001 — trasporto e priorità | Configurazione predefinita con solo socket Unix, percorso esplicito, errore su socket assente/inaccessibile e nessun tentativo o listener TCP implicito; prima integrazione delle operazioni disponibili indipendente dal completamento query/TCP |
| REQ-IPC-002 — framing e ammissione | Header/corpo ricevuti a frammenti, frame accorpati, invii parziali, versione e lunghezze errate, CBOR malformato, correlazione delle risposte fuori ordine; massimo documento più envelope; saturazione di ogni limite e client lento con traffico su un'altra Serie, senza epoche trattenute né starvation |
| REQ-IPC-003 — risorse runtime | Percorsi mancanti, invalidi o troppo lunghi, account ammessi e negati, directory con proprietario/permessi errati; nome occupato da listener, socket orfano, file o link, sempre preservato all'avvio; arresto e nodo sostituito; crash e riavvio con diagnostica dell'orfano |
| REQ-IPC-004 — confini del commit | Disconnessione prima dell'ammissione, durante il commit e dopo pubblicazione prima della risposta; confronto con l'oracolo durevole dopo riapertura, nessun replay alla riconnessione, nessuna conferma anticipata e nessun traffico applicativo prima del recovery |

Framing e ordinamento si esplorano su modelli finiti e con fuzzing del decoder;
gli scenari FI-01/FI-02/FI-05 sono ripetuti attraversando il socket locale.
Le verifiche di accesso devono usare identità distinte sulla piattaforma di
riferimento. Si applicano copertura, revisione e metodi delle classi assegnate.
La [prova SPK-11](../../spikes/SPK-11-unix-socket/README.md) esercita il solo
trasporto con due processi; il [contratto di sessione](../implementazione/sessione-locale.md)
resta una proposta. Nessun requisito IPC viene promosso dal successo dello spike.
Le misure del [percorso locale](../13-benchmark.md#interfaccia-locale-unix-socket)
seguono le prove di correttezza e restano distinte dai benchmark del solo motore.

## Ricerca full text

[ADR-0053](../adr/0053-ricerca-full-text-indici-invertiti.md) aggiunge
REQ-SEC-003…REQ-SEC-006 e INV-I4; il completamento in
[ADR-0054](../adr/0054-contratto-e-formato-full-text.md) aggiunge
REQ-SEC-007…REQ-SEC-010 e INV-I5/INV-I6. Sono requisiti **progettati**: le prove
esistenti del primary index, del codec e del recovery non li qualificano.
Il [nucleo full text](../implementazione/full-text.md) aggiunge corpus Unicode,
oracolo posizionale, corruzione della cornice, budget, allocazioni e controlli negativi;
non qualifica ancora i requisiti nel perimetro completo della Serie.
La fase 8 deve produrre queste evidenze, prima dei benchmark:

| Requisito | Evidenza da realizzare |
|---|---|
| REQ-SEC-003 — semantica e analisi | Oracolo indipendente a scansione per parole, frasi, all/any, and/or/not, filtri e campi assenti; profili Unicode fissati, accenti, equivalenze canoniche, ripetizioni e confini dei campi |
| REQ-SEC-004 — commit e snapshot | Stessa versione per testo e filtri; update/delete, abort, ACTIVE/CLOSED, snapshot storici e compaction; esplorazione dei punti di pubblicazione e fault injection prima/dopo SEAL e DECISION |
| REQ-SEC-005 — generazioni e derivati | Build concorrente, cambio analizzatore, riavvio/restore, file mancanti, CRC/identità errati e copertura incompleta; generazione unica per query ed errore esplicito fino a readiness completa |
| REQ-SEC-006 — limiti e isolamento | Saturazione di ogni budget, rifiuto della scrittura prima della decisione durevole, cancellazione e timeout; errore di query distinto dal limit richiesto, senza risultati parziali silenziosi; carico sulle altre Serie |
| REQ-SEC-007 — profilo e query | Corpus Unicode 18.0.0 e attesi manuali; mapping C/F, frasi ripetute, ordinamento stabile e riconoscimento dello stato terminale |
| REQ-SEC-008 — codec e identità | Fixture binarie indipendenti del `.idx` v2/type 5, corruzione anche con CRC valido, hint scambiati, ordini/offset e riservati |
| REQ-SEC-009 — protocollo generazioni | Cattura concorrente con confine iniziale, inventario cambiato prima dello swap, file distinti, ritiro autorizzato e reader già ammessi |
| REQ-SEC-010 — riserve e completamento | Delta/staging e limite superiore del file prenotati prima della decisione; rotazione, saturazione, errore dopo batch, cleanup e singola continuazione terminale |

Si applicano le classi già assegnate: C2 alla semantica di interrogazione
e C1 ai percorsi di pubblicazione, visibilità e recovery dei derivati.
Copertura, condizioni, revisione, mutazioni e modelli seguono le regole
della classe. Corpus, profili, generazioni e attesi devono essere
riproducibili; un controllo negativo deve dimostrare la sensibilità
dell'oracolo. La [campagna prestazionale](../13-benchmark.md#ricerca-full-text)
misura separatamente analisi, ricerca, commit, build/rebuild e interferenza.
La [matrice di accettazione dettagliata](../full-text.md#criteri-di-accettazione)
lega questi requisiti a ingressi, oracoli e condizioni di riuscita. I default dei budget
sono politiche di progetto da qualificare; non sono prestazioni misurate.

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
