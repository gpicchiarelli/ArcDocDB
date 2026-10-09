# Un solo registro CSN per Archivio

## Contratto e ambito — 2026-10-09

I writer e gli snapshot dello stesso Archivio usano **lo stesso**
`arcdocdb.csn:registro-csn`. L'adattatore
[`snapshots-csn.lisp`](../../src/mvcc/snapshots-csn.lisp) usa esclusivamente
`leggi-frontiere-csn`, senza leggere campi, slot o mutex privati del componente.
Il registro e la sua API di `main` rimangono invariati. La prima implementazione
CSN di questo ramo è stata [ritirata](orizzonte-csn.md).

Non cambiano [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md),
[ADR-0038](../adr/0038-orizzonte-di-visibilita.md) o
[ADR-0045](../adr/0045-modello-di-esecuzione.md). L'integrazione è C1:
REQ-MVC-005, REQ-MVC-007, REQ-CON-004, REQ-AFF-004, REQ-AFF-008;
INV-M1, INV-M2, INV-M4, INV-P5 e INV-A8. I requisiti restano progettati.

## Cattura, contesa e pubblicazione

Il controller costruisce il registro CSN dalla base recuperata, lo assegna
ai writer e passa lo stesso oggetto a `crea-registro-snapshot`. Nessun altro
registro assegna le versioni di questo Archivio.

Per registrare uno snapshot:

1. Tentare il mutex snapshot una sola volta; su contesa, `:snapshot-busy`
   prima di qualsiasi cambiamento. Anche l'acquisizione ricorsiva è rifiutata.
2. Validare capacità, riuso, generazione e deadline.
3. Leggere `H0` dalla API CSN: `:csn-busy` qui non modifica alcun dato snapshot.
4. Conservare la vecchia soglia e pubblicare `min(vecchia, H0)`, con barriera completa.
5. Catturare ultimo CSN `s` e nuovo orizzonte `H1` da **un solo campione coerente**.
6. Verificare `H0 <= H1 <= s`, invalidare le vecchie identità e pubblicare
   metadati, pin e generazione. Attivo solo se `H1 >= s`; altrimenti in attesa.

Nel passo 5, normale `:csn-busy` ripristina la vecchia soglia prima di
propagare il rifiuto. Contesto, slot, generazione, conteggio e cursore non
sono ancora stati modificati. La soglia provvisoria può aver indotto il
writer a trattenere versioni aggiuntive: è conservativo. La sua revoca
mantiene la protezione dei pin precedenti e non revoca uno snapshot nato,
perché nessuna nuova identità è stata pubblicata. Un nuovo tentativo usa
un tempo fresco e cattura un nuovo CSN.

La revoca riguarda **solo la soglia provvisoria** su quella contesa
riconosciuta. Uscita non locale, corruzione o errore inatteso dopo l'annuncio
rendono il registro snapshot `FAULTED`; non si annulla una pubblicazione
parziale dei metadati. Un'interruzione dopo la pubblicazione e prima della
consegna al chiamante è conservativamente un guasto da isolare.

## Coordinamento senza attese

Registrazione, attivazione, terminazione, timer e diagnostica usano
`with-mutex :wait-p nil`. La flag locale di acquisizione distingue un corpo
che restituisce `NIL` da un mutex occupato. Il runtime gestisce il rilascio
su uscita non locale. Non è introdotta una macro di sincronizzazione o una
API con callback; i corpi rimangono nelle funzioni di coordinamento.

| Rifiuto | Stato conservato e azione del controller |
|---|---|
| `:snapshot-busy` | Nessuna mutazione; conservare e riprogrammare il compito. |
| `:csn-busy` prima dell'annuncio | Nessuna mutazione snapshot. |
| `:csn-busy` dopo l'annuncio | Soglia ripristinata; nessuna identità o credito consumato. |
| Attivazione con `:csn-busy` | Pin e stato di attesa conservati. |
| Terminazione con `:snapshot-busy` | Pin e obbligo di terminarlo conservati. |
| Timer con `:snapshot-busy` | Nessuna visita o avanzamento del cursore. |

L'ordine resta snapshot → CSN. Writer e coordinatore devono rilasciare il
mutex CSN prima di accodare attivazioni/notifiche. Il modulo non implementa
code, risvegli o timer autonomi. Il controller applica budget e deadline;
nessuna delle API ritenta internamente.

La conversione delle quattro parole u32 in due u64 è confinata al
coordinamento degli snapshot. Non compare nel GET corrente o nella verifica
del reader. I valori u64 restituiti dal coordinamento possono richiedere
boxing oltre il range fixnum: non si dichiara zero heap per la registrazione.
Capacità e scansioni restano limitate; il percorso di lookup usa i contesti
e i buffer preallocati già definiti.

## Propagazione dei guasti

`invalida-registro-snapshot` pubblica soltanto lo stato terminale `FAULTED`,
senza mutex, senza reset e senza toccare pin logici o reader fisici.
Questa scrittura è monotona; manutenzione e lettori non ripristinano `:open`.
Il confine fidato dell'Archivio la chiama dopo un guasto del registro CSN
osservato nel writer o nel coordinatore e isola il dominio. La conversione
di frontiere intercetta soltanto `invariant-violation`, invalida gli snapshot
e rilancia **la stessa** condizione. Non interpreta il guasto come contesa.

I reader campionano la salute snapshot con le guardie esistenti, senza
consultare i campi privati CSN. Scoprire metadati incoerenti pubblica lo
stesso stato terminale senza attendere il mutex. Una registrazione ricontrolla
la salute dopo la pubblicazione prima di restituire successo.
L'invalidazione non elimina versioni o segmenti e non cancella un annuncio EBR
di un worker vivo. L'isolamento effettivo dell'Archivio resta da collegare
al futuro confine eseguibile del motore.

## Decisioni da coprire — COD-54

| ID | Decisione o transizione | Distinzioni richieste |
|---|---|---|
| CSN-S01 | Progresso delle frontiere | `H0 <= H1` e `H1 <= s`, separatamente; carry u32 e massimo u64. |
| CSN-S02 | Cattura dopo annuncio | Successo; `:csn-busy`; altra `resource-exhausted`; guasto CSN; uscita non locale. |
| CSN-S03 | Revoca della soglia | Nessun pin precedente; pin precedenti; writer che ha visto la soglia provvisoria; nessuna identità consumata. |
| CSN-S04 | Acquisizione del mutex | Corpo con valore `NIL`; contesa; ricorsione; interruzione con mutex posseduto. |
| CSN-S05 | Guasto concorrente | Prima/durante/dopo cattura o pubblicazione; reader attivo; invalidazioni ripetute. |

Le decisioni precedenti del registro snapshot restano da coprire. Questa
tabella non dichiara test o copertura raggiunta.

## Evidenze e qualifica

La [campagna dedicata](../../spikes/results/2026-10-09-snapshot-csn/README.md)
conserva compilazione del solo prodotto, lint, tracciabilità, link, controllo
dei cataloghi e disassemblato statico, inclusi i tentativi falliti.
Un confronto dei blob Git verifica che gli otto report iniziali spostati
coincidano con `10d08ec` e i due sorgenti CSN canonici con `673987a`.
Non esegue funzioni del prodotto.
Non vengono aggiunti o eseguiti localmente test funzionali, prove concorrenti,
fault injection, modelli, benchmark o auto-verifiche degli strumenti.

Le prove del [registro CSN](csn-risultati.md) coprono il suo ambito:
non dimostrano questo collegamento. Restano la verifica di contesa/revoca,
gli interleaving ARM64/x86-64 con retention e invalidazione, le misure di
allocazione/latency e l'integrazione di writer, indice, timer e pool.
