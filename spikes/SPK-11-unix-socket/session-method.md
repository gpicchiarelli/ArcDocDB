# Sessione M16 — metodo preregistrato

Variante di SPK-11, 17 ottobre 2026. Verifica preparatoria del contratto
proposto in [ADR-0056](../../docs/adr/0056-sessione-locale-m16.md), prima del
codice M16 di prodotto. REQ-IPC-002/004 e REQ-VAL-001. Il codice resta C4.

## Domande e oracoli

1. HELLO/WELCOME: fixture binarie indipendenti, cinque elementi esatti,
   versione/kind/ID/code, mappe con chiavi esatte e ordinate, capacità
   minime/massime. Negoziazione come minimo dei limiti, senza amplificazione.
2. Validazione: codec minimo di prodotto per sintassi e UTF-8; passaggio
   separato per l'ordine lessicografico dei byte delle chiavi, anche annidate.
   Niente reader Lisp su input esterno. Il profilo controllato usa messaggi
   di controllo entro 4096 byte; nessun comando dati viene definito.
3. Sessione: nessuna richiesta prima di WELCOME inviato; ID u64 positivi
   strettamente crescenti, anche dopo completamento. Risposte invertite,
   una sola risposta terminale e credito mantenuto fino all'invio completo.
   ID massimo consente solo lo svuotamento prima della riconnessione.
4. Limiti: prefisso prima del corpo, capacità in volo, budget dei risultati,
   due proprietari indipendenti. Saturazione non muta ID o stato ammesso.
   Clock logico iniettato: deadline assolute, progressi parziali senza rinnovo.
5. Gate: un indicatore simulato rifiuta PING con `unavailable` e non esegue
   lavoro; è soltanto un oracolo C4. Non è un'attestazione del recovery.
6. Due processi reali: HELLO frammentato, negoziazione, richieste accorpate e
   risposte invertite; sessioni invalide chiuse senza risposta applicativa.
   Conservare argv, PID, esiti e stdout/stderr come negli scambi esistenti.

## Controlli negativi e conservazione

Ogni famiglia di rifiuti richiede la ragione attesa. Mutazioni note devono
dimostrare sensibilità degli oracoli su capacità annunciate, ID della
risposta, credito liberato prima dell'invio e deadline rinnovata.
Conservare anche compilazioni e tentativi falliti con i sorgenti effettivi.
I risultati saranno distinti dalla campagna precedente già chiusa.

## Confini

La prova riguarda il controllo della sessione, senza AST documentale o
comandi GET/PUT, pubblicazione, commit, ritiro EBR o dispatcher di prodotto.
Il passaggio sulle mappe verifica l'ordine e i duplicati dei byte codificati;
la semantica applicativa di chiavi/tag non viene inferita. Il massimo di
profondità 8 riguarda array/map; sequenze di tag sono percorse iterativamente.
Nessuna misura di heap nativo, RSS, latenza o throughput. Restano accettazione
ADR-0056, adattatore I/O preallocato, gate reale del motore, accesso con UID
distinti e qualifica Linux. I requisiti IPC rimangono progettati.
