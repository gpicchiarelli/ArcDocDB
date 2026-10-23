# ID del nuovo segmento dopo il recovery

> **Incremento C1, metodo preregistrato il 2026-10-15.**
> Parte della pianificazione di apertura, non un Recovery Manager completo.

`arcdocdb.recovery.manifest:scegli-id-segmento-recovery(manifest, files, …)`
restituisce tre valori: ID proposto, high-water successivo e piano di
riconciliazione. Usa una sola chiamata al planner canonico con gli stessi
budget `max-files` e `max-segmenti`; nessun file o manifest è modificato.

## Contratto

Dal 2026-10-16 l'[ingresso dalla directory](id-directory-recovery.md)
compone inventario nativo e selezione ID con un'unica enumerazione.
Le due API riusano l'helper privato di selezione dal piano canonico.
Le misure del 2026-10-15 sotto restano riferite alla versione allora verificata;
la composizione e il refactoring hanno metodo e risultati separati.

Il manifest è completo e autorevole; l'inventario contiene tutti i nomi
fisici `.seg`/`.seg.tmp`, è stabile e appartiene al controller esclusivo.
Il planner valida descrittori, duplicati e budget e possiede il piano.
Il massimo ID si legge dall'ultima entry del piano, ordinato unsigned u64;
include nomi sconosciuti, temporanei, rimossi e referenze vive mancanti.
Il high-water del manifest protegge anche gli ID storici non più presenti.

La proposta è il minimo ID almeno pari al high-water e maggiore di ogni
ID del piano. Anche il high-water successivo deve essere rappresentabile
su u64: nessun wrap, riuso di un buco o sentinel nuovo su disco.
`resource-exhausted :recovery-segment-id-exhausted` non restituisce valori
parziali. Errori del planner sono propagati senza reinterpretazione;
incoerenze private segnalano `invariant-violation`.

La scelta non riserva l'ID. Namespace e inventario restano esclusivi fino
alla creazione del nuovo temporaneo; l'EDIT è pubblicato dal protocollo
canonico. Ripetere gli stessi input può restituire la stessa proposta.
Lo stato del piano resta esplicito: un ID proposto non autorizza traffico,
non attesta header/CRC, non risolve anomalie e non elimina file.

Costi: quelli del planner esistente, poi scelta O(1) dal piano ordinato.
È un percorso di apertura con allocazioni, fuori dagli hot path; nessun
nuovo thread, lock o accesso condiviso in scrittura fra Serie.

## Verifica prevista prima dell'implementazione

- Oracolo indipendente a ricerca finita: minimo candidato che supera tutti
  gli ID dichiarati; 1.024 inventari, tre ordini e formati v1/v2.
- High-water con buchi e ID rimossi, temporanei non pubblicati e definitivi
  sconosciuti; disponibilità ready/degraded/faulted conservata nel piano.
- ID zero, bit 63, estremi u64, ID/high-water successivo non rappresentabili;
  input e manifest invariati dopo successo o rifiuto.
- Budget esatti/insufficienti, duplicati, tipi e condizioni originali;
  quattro Serie concorrenti con piani privati e attese limitate nel test.
- Guardie private e coppie di indipendenza delle condizioni; copertura
  nativa del nuovo file senza trasferire il risultato all'intero planner.
- Mutazioni isolate degli operatori di selezione, frontiera e guardie:
  obiettivo tutti i mutanti non equivalenti rilevati, con baseline riuscita.
- Due letture C1 con lista di controllo; indipendenza e limiti dichiarati.
- Prova verticale esistente collegata alla nuova API, poi `make check`.

| Decisione | Condizioni / esiti da coprire |
|---|---|
| RID-D01 | high-water positivo, candidato almeno al high-water, candidato oltre il massimo: ciascuna condizione falsa da sola |
| RID-D02 | high-water successivo = candidato + 1: uguale / discordante |
| RID-G01 | high-water disponibile / esaurito |
| RID-G02 | piano canonico con entry / vuoto per fault injection |
| RID-G03 | high-water successivo u64 / fuori range |

Requisiti: REQ-REC-001/002, REQ-FOR-003, REQ-AFF-008/018.
Invarianti: INV-A7/A8/A9/A10/A11, INV-P6.
Il perimetro full text di ADR-0053 resta nella fase 8: questa funzione non
costruisce indici né ne attesta la copertura.

## Esiti locali del 2026-10-15

La [raccolta delle prove](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-recovery-segment-id/README.md)
conserva registri originali, sorgenti, varianti, log e dati nativi.
Otto nuovi test nella suite recovery: 125 test superati, inclusi i 6.144
confronti con l'oracolo indipendente e 64 chiamate su quattro Serie private.
High-water con buchi, rimozioni storiche, temporanei orfani, nomi sconosciuti,
tipi e budget sono verificati senza modificare manifest o inventario.

La copertura del solo nuovo file è **71/77 forme, 10/10 alternative di ramo**.
Le sei forme non marcate sono quattro dichiarazioni e due default keyword
esercitati dalle chiamate senza opzioni: nessuna esclusione, nessuna ricarica
per cambiare i bit. Dati nativi e HTML sono concordanti tramite un lettore C4
con self-test. L'[inventario delle forme non marcate](../affidabilita/copertura-eccezioni.md#proposta-id-dopo-recovery--2026-10-15)
conserva il denominatore grezzo; il risultato non si estende agli altri file.

RID-D01 usa le tuple `(minimum maximum candidate next)`:
`(10 9 10 11)` passa; `(0 9 10 11)`, `(10 8 9 10)` e `(10 10 10 11)`
rendono falsa, da sola, ciascuna delle tre condizioni. RID-D02 confronta la
prima tupla con `(10 9 10 12)`. RID-G01/G03 usano manifest e inventari u64
reali; RID-G02 inietta un piano privato vuoto, ripristinando sempre il planner.

La campagna finale ha baseline riuscita e **11/11 mutanti rilevati dai test**,
con quattro processi isolati alla volta, nessun sopravvissuto, errore di
compilazione o guasto worker. Il primo tentativo aveva scoperto un copier
obsoleto dello strumento: ora deriva i sorgenti dai due sistemi ASDF e il
self-test ne controlla completezza e omissioni. Una campagna intermedia
aveva 10 rilevamenti e un mutante respinto dal compilatore: quest'ultimo non
è contato come kill. Il bersaglio è stato sostituito con il controllo errato
del candidato anziché del successore, che compila ed è rilevato sui limiti u64.
Tutti i tentativi e le rispettive varianti sono conservati.

La fixture verticale usa l'API con tutti i propri nomi e verifica 16 scenari
positivi e due negativi, 71 processi e 26 SIGKILL intenzionali. I byte dei
segmenti preesistenti restano immutati dopo entrambi i crash; nessuna azione
di rimozione è eseguita da questa nuova funzione.

La [verifica completa della versione integrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-recovery-segment-id-verifica/README.md)
è `OK / exit 0 / STABLE`, 484,751351 s su 1.012 sorgenti, al commit
`c8a1adab7da1adf171e1beaf41cc71ac2e801601`, comprendente anche il recupero CSN
pubblicato nel frattempo. Passano 1.734 test nominati, due smoke test,
249 file di prodotto senza violazioni, tracciabilità, link, controlli delle
evidenze e dieci spike. Il tentativo precedente, interrotto per integrare
il recupero CSN, resta conservato come `FAILED / exit 143`, non come test
riuscito. La raccolta finale conserva entrambi i registri e gli originali
degli spike; i successivi aggiornamenti dei risultati non cambiano codice,
test o strumenti verificati. Nessuna promozione della qualifica C1 del motore.

## Due letture con lista C1

Le due letture dell'autore riguardano prima contratto/algoritmo, poi diff,
oracoli, log, mutanti e copertura grezza. **Non sono una revisione indipendente**:
quel controllo e la qualifica C1 complessiva restano aperti.

| Punto della lista C1 | Prima lettura | Seconda lettura |
|---|---|---|
| 1. Requisiti e ADR | REQ sopra e ADR-0040 coerenti con high-water e non riuso | Commenti delle due funzioni e tracciabilità controllati |
| 2. Invarianti | Idempotenza della proposta, nessuna mutazione/distruzione | Modello, ownership e prove verticali |
| 3. Errori tipizzati | Condizioni originali, esaurimento e incoerenza privata | Budget, duplicati, tipi, u64 e fault injection |
| 4. Cicli/attese | Solo planner limitato; selezione senza ciclo | Worker del test con deadline e cleanup |
| 5. Allocazioni | Percorso freddo, piano privato; nessun hot path nuovo | Nessuna pretesa di zero allocazioni o prestazione |
| 6. Dati in uscita | Due u64 e piano validato | Tre valori esatti, frontiera e successore controllati |
| 7. Decisioni composte | RID-D01/D02 esplicite | Coppie di indipendenza e mutazioni degli operatori |
| 8. Proprietà | Manifest/inventario stabili, controller esclusivo | Piani distinti, input riutilizzabili, quattro Serie private |
| 9. Tracciabilità/check | Requisiti esistenti, nessuna promozione di stato | Controllo completo finale registrato separatamente |
| 10. Deviazioni | Nessuna esclusione di copertura | Sei forme non marcate e indipendenza aperta dichiarate |
| 11. Fra Serie | Nessun nuovo lock, thread o contatore condiviso | Chiamate private concorrenti, nessuna misura di scalabilità |
| 12. Atomicità | Nessun effetto durevole o prenotazione | EDIT e creazione esclusiva restano al protocollo canonico |
