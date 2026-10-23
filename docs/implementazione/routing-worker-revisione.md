# Revisione del routing worker/Serie

Due letture C1 del 2026-10-11: contratto, sorgenti di prodotto e
dipendenze esecuzione/Serie. Prima lettura: agente `next_execution_audit`;
seconda lettura indipendente: agente `routing_measure`, dopo RW-REV-01.
La seconda lettura ha confrontato anche le fixture, prima delle campagne.
Il root ha poi eseguito le campagne e `next_execution_audit` ne ha letto
i raw dedicati v2: target, copertura, audit nativo/HTML, misure e strict C4.
Il controllo generale sul congelamento integrato passa: 835 test,
2 smoke, 21 suite e dieci spike con sorgenti stabili. Anche questi raw
sono stati letti da `next_execution_audit`. Sono letture di agenti,
non attestazioni umane; i gate globali di qualificazione restano aperti.
Base iniziale `92decf4265554cd4959e32a1c881cf00758bb6a1`.

| Punto C1 | Prima lettura | Seconda lettura / evidenza |
|---|---|---|
| 1. REQ e ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005/0033/0045. Routing del writer già CLAIMED al binding locale, senza scheduler implicito. | Confermati nel delta writer, tre routing, package e ASDF. Nessun cambio del modello a compiti espliciti. |
| 2. Invarianti sensibili ai test | Ordinal immutabile e locale, registro denso 1..65536, controller distinti EQ, input copiati, owner worker, CLAIMED, writer EQ, link del contesto/coppia e IDLE. | Le 18 fixture v2 passano: copie, alias controller, ricircolo full, FI link, owner, fase, RW-REV-01, Serie FAULTED e shape privata. Confrontano identità e immagini prima/dopo; il limite 65536 è provato nella shape, senza costruire 65536 controller reali. |
| 3. Errori tipizzati | Configurazione invalida prima della pubblicazione; fase/owner ordinari; errore routing dopo claim rende FAULTED il worker e conserva l'obbligo. Segnalato RW-REV-01 sul confine delle ragioni recuperabili. | RW-REV-01 chiuso nel sorgente e nella campagna v2: FI su entrambi i helper con ragione `:worker-state`, condizione EQ, writer/home conservati e controller intatti. Nessun errore del lookup diventa recuperabile attraverso l'allowlist esterna. |
| 4. Cicli e attese | Due cicli di costruzione, ciascuno limitato dalla dimensione verificata N≤65536. Nessun ciclo nel lookup, nessuna attesa/ricorsione/thread/callback. | Confermato sui sorgenti finali; semafori/deadline soltanto nel harness concorrente, nessun retry nascosto. |
| 5. Allocazione calda | Slot e riferimenti immutabili, tabella locale preallocata, handler worker `dynamic-extent`. Hash EQ soltanto startup. Lettura statica non attesta heap nullo. | Cinque campioni v2 da 4096 cicli dopo warmup 128: heap `[0,0,0,0,0]`, sink 8972288 ciascuno. Controllo positivo 16777472 byte, sink errato rifiutato e clock nullo sotto risoluzione. Solo successo seriale locale preallocato, non heap zero universale. |
| 6. Dati verificati all'uscita | Range prima di `svref`; EQ prima di restituire link; owner/fase e shape verificati dai helper. Getter ordinale non attribuisce membership o lease. | Confermato ordine range, writer EQ, context/writer/controller EQ, IDLE e forma link. Nessun acquire, pop o accesso allo stato vivo della Serie dalla selezione. |
| 7. Decisioni composte | Una nuova decisione composta nella factory writer: `or` tra NIL e tipo integer0..65535. Altre decisioni scalari, cicli e boundary elencati nell'inventario. | Input NIL,0,invalido coprono VF/FV/FF, con cortocircuito dichiarato. Audit nativo/HTML dei 26 file PASS: 3250/3766 espressioni, 436/526 rami; tre routing 267/291 e 40/42. Tutte le 516 espressioni e 90 rami missing conservati; nessun MC/DC inferito. |
| 8. Proprietà condivisa | Registro privato dopo copie, condiviso in sola lettura. Contesto/tabella/link locali al thread. Lookup non legge salute, owner o ring del controller. | Confermati copie e slot read-only, assenza di scritture condivise calde e owner prima dei handler. Nessun poisoning su wrong-thread e nessun fault marking su controller senza lease. |
| 9. Tracciabilità e check | REQ sulle nuove definizioni; package/ASDF caricano routing dopo il bridge. Requisiti globali restano `progettato`. | Confermata sequenza di caricamento senza dipendenze invertite. Tracciabilità e check completo PASS sul congelamento integrato: 835 test, 2 smoke, 21 suite e dieci spike stabili. Nessuna promozione dei requisiti globali. |
| 10. Regole e deviazioni | Safety3, slot typed/read-only, ftype/docstring, pre/post, corpi≤60righe, complessità locale≤10. Nessuna syscall o deviazione nuova individuata. | Nessun nuovo difetto statico o deviazione individuato. Strict compile completo C4 e self-test FASL PASS in v1, prodotto/C4 invariati in v2; reader audit strict compile/FASL e self-test PASS in v2, entrambi stderr vuoti. Fullcheck integrato PASS, compilazione senza warning; 370114 byte di note compilatore conservati nello stderr. |
| 11. Serializzazione e INV-P6 | Nessun lock, wait, hash o scrittura globale nel lookup per tratto. O(1); coda pronta e lease restano nei protocolli già esistenti. | Fixture v2 PASS: due tabelle locali sullo stesso registro read-only, due Serie ACTIVE prima delle release. La correttezza di questo interleaving finito non è una misura di scalabilità o fairness. |
| 12. Atomicità durevole | Cambia soltanto configurazione in memoria e selezione di un oggetto. Non scrive WAL, non elimina dati, non conferma effetti. Nessun nuovo punto durevole. | Confermato: nessun I/O, record durevole, eliminazione, rollback o cleanup. Recovery/shutdown globale non sono qualificati. |

## Osservazioni della prima lettura

| ID | Osservazione | Stato |
|---|---|---|
| RW-REV-01 / P2 | L'allowlist `:worker-state` dell'API selezione racchiudeva anche i helper di lookup. Un errore `resource-exhausted :worker-state` inatteso proveniente dal lookup poteva restare recuperabile per coincidenza di ragione con il rifiuto di fase. La prima lettura non ha individuato un ramo naturale attuale che lo producesse; il rischio riguarda contenimento di guasto e coupling futuro. | Boundary lookup interno con allowlist vuote dopo il controllo CLAIMED, in `routing-select.lisp:55`, riletto da entrambi gli agenti. La regressione `test-REQ-AFF-008-routing-lookup-reason-cannot-bypass-terminal-boundary` inietta entrambi i helper e passa nel target v2. |

Il routing non possiede una lease Serie quando fallisce: non marca un
controller che potrebbe appartenere a un altro worker. La diagnosi e il
writer/home/obbligo conservati devono essere presi in carico dal futuro
coordinatore Archivio. Il fail-stop locale non dimostra arresto globale,
quiescenza, pool, shutdown o riuso sicuro dopo un errore.

## Tentativi preliminari

Il primo congelamento v1 ha compilato il prodotto senza avvisi, ma il
test dei budget massimi ha esaurito lo stack del comparatore ricorsivo
dell'immagine della fixture su vettori da65537 elementi. Il record originale
`4000711896-command-71058-0` resta un fallimento conservato, non viene
promosso a PASS. Il comparatore del solo test viene corretto prima della
campagna v2; sorgenti del prodotto e distinzione fra le campagne restano
espliciti. Il target v2 passa dopo questa correzione del solo harness.

## Gate dedicati letti

I quattro record di processo dedicati e il record dell'audit sono stati
letti con `:STATUS :OK`, `:SOURCE-CONSISTENCY :STABLE` ed exit0. Le copie
canoniche e il controllo generale sono descritti nei risultati.

| Gate | Record originale | Esito e ambito |
|---|---|---|
| Target v2 | `4000712082-command-76603-0` | 18 test routing PASS; include FI shape, Serie FAULTED e RW-REV-01. |
| Suite e copertura v2 | `4000712082-command-76602-0` | 88 test Serie e 89 execution PASS nello stesso processo; unione nativa/HTML dei 26 file completi. |
| Audit copertura v2 | `4000712247-command-79840-0` | Strict COMPILE-FILE completo reader, FASL, self-test e concordanza nativo/HTML PASS; stderr vuoto. 26 righe, 3250/3766 espressioni e 436/526 rami; 24 espressioni e 2 rami missing nei tre routing, tutte le identità preservate. |
| Strict C4 v1 | `4000711978-command-74703-0` | COMPILE-FILE completo e self-test FASL PASS, warning/style-warning fatali, stderr vuoto. C4 SHA invariato in v2. |
| Misura v2 | `4000712105-command-77187-0` | Cinque campioni da 4096 cicli: heap0, sink8972288, ticks6792/6802/6814/6820/6815. Controllo positivo 16777472 byte; badsink3 atteso1 rifiutato, clock0 sotto risoluzione, raw parziale e CLI verificati. |

Il report C4 originale `routing-bench-01/report.lisp` contiene 53759 byte,
SHA-256 `9f8fb919d590c230ce75063ca754782537759779048cddfb2490fea97bf58b93`.
I ticks sono in unità 1e6/s della piattaforma locale e non sono throughput,
P99 o confronto parallelo. Startup/compilazione/GC/stampa restano fuori
sensore; il ciclo è seriale, con due Serie alternate e I/O mock della fixture.

## Controllo generale finale

Il record `4000712542-command-86913-0` del congelamento integrato d155db3
con il delta routing passa con `:OK/:STABLE`, exit0 e 673 source blob.
Il processo esegue `make check-core`, nucleo richiamato da `make check`,
con cache ASDF privata: 835 test nominati, 2 smoke e 21 suite in
182.076021 secondi. Lo stderr originale contiene 370114 byte di note
del compilatore, senza warning o condizioni non gestite.

Il master `4000712691-check-90489-0` è `:COMPLETE`: tutti i dieci spike
hanno sorgenti stabili, exit0 e stderr vuoto; SPK-007 è PASS, gli altri OK.
La proiezione compatta `4000712744-routing-fullcheck-projection-92144`
è stata confrontata con i record originali. Le prove ausiliarie conservano
14 file originali e 2 file di orchestrazione; i fallimenti intenzionali
dei self-test sono distinti dal successo della campagna e non sono nuovi
gate C4.

La pubblicazione conserva questi dati nei file canonici
`full-check.lisp`, `fullcheck-summary.lisp` e `fullcheck-selftests.lisp`,
con provenienza e verifica dei byte dichiarate nei risultati. La copertura
rimane parziale, nessun MC/DC è inferito e la qualificazione generale del
motore e il gate F0 restano aperti. I sorgenti routing, le fixture e il C4
qualificati in questo congelamento restano invariati.

## Integrazione con main avanzato

La qualificazione dedicata rimane sul congelamento v2 della base92decf4.
Il congelamento generale integra
`d155db3f977677fa95280f59c23fbe46a5e116d2`:
aggiunge scrittura di stringhe CBOR e resolver GET, senza modificare
execution/Series o foundation/hash/io/wal/csn. Il delta ASDF aggiunge le
nuove unità e la suite CBOR; il delta `foundation-coverage.lisp` aggiunge
lo scope CBORstring-write e non cambia i predicate Series/execution.

L'avanzamento remoto successivo a
`8fb30517a72c5a7bf51f0f5746c6d04a0a8c3486` aggiunge soltanto artefatti:
il diff da d155db3 non cambia sorgenti, strumenti, documenti o ASDF.
Questa distinzione conserva la base effettiva nei record del congelamento.

Questi delta non cambiano i tre routing, il bridge, la modifica writer,
le fixture routing o il C4. I raw dedicati mantengono base, fonti e scope
originari: non sono presentati come nuove misure sulla base integrata.
ASDF, indice implementazione e changelog vengono composti conservando
entrambe le aggiunte. Il controllo generale sul pacchetto integrato passa
nel record `4000712542-command-86913-0`, con dieci spike nel relativo
master: questo esito viene dai raw finali, senza dedurlo dai gate dedicati.

## Pubblicazione e conservazione dei byte

Il wrapper di pubblicazione `4000712318-command-81618-0` ha exit0,
ma stato `:SOURCE-CHANGED` e source consistency `:CHANGED`: non è un
test PASS. La proiezione dei blob prima/dopo mostra 672→673 file e due
delta documentali concorrenti: creazione di `routing-worker-risultati.md`
e aggiornamento dei link di `routing-worker.md`. Gli altri blob rimangono
identici, compresi tutti i sorgenti di prodotto, test e strumenti.
Il record originale conserva questo stato senza normalizzarlo.

La copia dei raw e la costruzione del catalogo sono state completate con
verifica dei byte originali ed espansi. Il successivo controllo separato
`4000712554-command-87125-0`, letto dopo che i documenti erano stabili,
rilegge tutti i byte raw/espansi del catalogo e passa con `:OK/:STABLE`,
exit0 e stderr vuoto. Questo gate attesta la conservazione degli artefatti;
non trasforma il wrapper precedente in PASS e non sostituisce `make check`
sul codice finale.

## Ultima integrazione prima del push

Una lettura separata del delta d155→6eeb501 conferma che non modifica
execution/Series/routing o relativi contratti. Cache/read salta posti
disabilitati/rifiutati entro gli otto way prima del tag; la copia ricontrolla
ancora disponibilità e sequenza. La nuova suite GET e i tre strumenti
associati non invocano API routing. ASDF conserva entrambe le aggiunte e
`foundation-coverage.lisp` mantiene identici i predicati Series/execution.

Il nuovo snapshot683 sorgenti/documenti su
`6eeb501d2eace49fad8e2ec333ed0c6c1386dd6c` è verificato dal processo
`4000713646-command-11645-0`: OK/STABLE/exit0,854 test più2smoke,
22suite, nessun warning/style-warning. Dieci esperimenti aggiuntivi sono
riusciti nel master `4000713800-check-18712-0`, tutti stabili.
I raw835+2 precedenti rimangono storici; non sono reinterpretati come
prova della nuova base. Le due letture C1, le misure e il denominatore
dedicati mantengono fonte e scope originari. Il nuovo controllo generale
non chiude Fase0 o la qualifica del motore.

## Composizione finale con resolver ACTIVE

Il delta6eeb501→be9d2dd non modifica execution/Series/routing o loro
contratti. Sei unità ACTIVE sono caricate dopo il resolver CLOSED,
senza cicli o riordino del routing. Le nuove API leggono la radice della
Serie, non agganciano automaticamente il bridge o il lookup routing e
non ridefiniscono le loro funzioni. L'allocazione dei metadati ACTIVE per
lotto rimane fuori dallo scope delle misure seriali routing.

Il build della tree combinata, record `4000714586-command-55084-0`,
è OK/STABLE/exit0 con690 sorgenti/documenti e854 test più2smoke,
senza avvisi. I test esistenti non esercitano le nuove API ACTIVE: questo
PASS non ne attesta C1/C4. I congelamenti F0/copertura/misura precedenti
mantengono fonte e scope. Preimage di ASDF, indice e changelog sono
conservate; entrambe le aggiunte rimangono nella tree finale.

## Integrazione della suite GET finale

La PR9 porta main a `644e53f176d0dce2c5ac5870659e7d89c0c9df3e`:
aggiunge70 test GET, caricamento della suite, scope GET di copertura e
documentazione. Non modifica sorgenti di prodotto o i predicati di
copertura Series/execution. L'integrazione conserva i precedenti delta.

Il build combinato `4000715110-command-98694-0` è OK/STABLE/exit0,
con694 sorgenti/documenti,924 test nominati e2smoke, senza avvisi;
cache FASL privata, circa22,71s. Questo controllo ripete la suite con i
nuovi test; F0, copertura e misure routing mantengono le basi originali.
Non è una nuova qualifica delle API ACTIVE, del pool o del motore.
