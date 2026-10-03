# Analisi dei guasti

Modello dei guasti e FMEA. Per ogni guasto: che cosa succede, come lo si **rileva**, come si
**risponde**, quale requisito o invariante lo governa, come si **verifica**. Un guasto senza
risposta definita e verifica è un difetto di progetto.

## Modello dei guasti

**Tollerati (con risposta definita):**

1. arresto improvviso del processo o della macchina in qualsiasi istruzione (crash, `kill -9`,
   perdita di alimentazione);
2. scritture parziali o non ordinate non ancora sincronizzate (coda troncata, settore
   incompleto);
3. errori restituiti dal sistema operativo (`EIO`, `ENOSPC`, `EMFILE`, errore di `fsync`);
4. alterazione dei dati a riposo (bit-rot, blocco azzerato, blocco duplicato, troncamento);
5. alterazione dei dati in memoria (bit flip nell'indice o nella cache);
6. esaurimento di risorse (memoria, descrittori, spazio, code);
7. input malformato o ostile al protocollo e ai decoder;
8. difetti del software (violazione di invarianti interni);
9. errore dell'operatore (doppia apertura, file rimossi).

**Non tollerati (dichiarati, resi rilevabili dove possibile):**

10. flush dichiarato riuscito ma non durevole (cache di scrittura del supporto senza barriere,
    firmware difettoso);
11. perdita simultanea di tutti i supporti;
12. difetti del compilatore, del GC, del runtime di SBCL, del kernel;
13. comportamento bizantino o avversario.

## FMEA

| ID | Guasto | Effetto | Rilevazione | Risposta | Governo | Verifica |
|---|---|---|---|---|---|---|
| FM-01 | Perdita di alimentazione o crash durante append | coda del segmento `ACTIVE` parziale | lunghezza incoerente o CRC errato | scansione di risincronizzazione: se nulla di valido segue, troncare; altrimenti `FAULTED` ([ADR-0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) §4) | INV-F1, INV-D1 | FI-01, FI-02; simulatore |
| FM-02 | `fsync`/`rename`/`write` restituisce errore | stato delle pagine indefinito | codice di ritorno | **nessun retry**; Serie/Archivio `FAULTED`; nessuna conferma del lotto | INV-A1 | simulatore con errori di I/O |
| <a id="fm-03"></a>FM-03 | Flush riuscito ma non durevole (supporto o firmware) | perdita di dati confermati | non rilevabile a runtime; rilevabile dalla verifica a posteriori | `F_FULLFSYNC` su macOS, `fdatasync` su Linux; **rischio residuo dichiarato** | — | prova con interruzione di alimentazione fuori dalla CI |
| FM-04 | Alterazione di un segmento chiuso | dato sbagliato | CRC alla lettura; scrubbing | segmento in quarantena (`DEGRADED`); errore `corruption-detected`; ripristino da backup | INV-A2, INV-A6 | corruzione deliberata di ogni file; scrubbing |
| FM-05 | Scrittura persa o indirizzata male (supporto la conferma, i dati non ci sono) | record mancante o altrui | CRC e confronto chiave/versione alla lettura; scrubbing e confronto hint ↔ segmento ↔ control log | quarantena; `FAULTED` se riguarda log di controllo | INV-A2, INV-A6, INV-F1 | scenari di scrittura persa nel simulatore |
| FM-06 | Alterazione a metà del segmento `ACTIVE` seguita da record validi | rischio di scartare dati committed | scansione di risincronizzazione trova record valido dopo l'anomalia | `FAULTED`; nessun troncamento; decisione dell'operatore | INV-A1, INV-F1 | FI-01 con danno a metà log |
| FM-07 | Spazio disco esaurito | scritture impossibili | spazio libero sotto riserva; `ENOSPC` | rifiuto controllato `resource-exhausted` prima dell'esaurimento; `ENOSPC` in scrittura = errore di scrittura (FM-02) | INV-A8, INV-A1 | simulatore con disco pieno |
| FM-08 | Errore di lettura (`EIO`) | dato non disponibile | codice di ritorno | errore `io-fault` per quella lettura; ripetuti → quarantena del segmento; **mai** un dato non verificato | INV-A2 | simulatore con errori di lettura |
| FM-09 | Descrittori di file esauriti | impossibile aprire segmenti | `EMFILE` | rifiuto controllato; limite di segmenti aperti e cache dei descrittori limitata | INV-A8 | test di saturazione |
| FM-10 | Esaurimento dello heap | possibile uscita fatale del runtime | bilancio di memoria; soglie interne | rifiuto ben prima del limite (backpressure); heap dimensionato esplicitamente all'avvio; bilancio verificato all'avvio | INV-A8 | test di saturazione; SPK-02 |
| FM-11 | Bit flip nell'indice o nella cache | location o dato sbagliato | confronto chiave/versione/CSN con il record; CRC | errore `corruption-detected`; indice ricostruibile dagli hint | INV-A2 | iniezione di bit flip in memoria nel simulatore |
| <a id="fm-12"></a>FM-12 | Difetto del compilatore, GC o runtime | corruzione arbitraria | controlli end-to-end; asserzioni | versione fissata e provata su due piattaforme; **rischio residuo dichiarato** | INV-A2, INV-A3 | CI su Linux e macOS; soak test |
| FM-13 | `kill -9` del processo | arresto improvviso | al riavvio | recovery ([architettura](../architettura.md#recovery)) | INV-D1, INV-A7 | crash reali ripetuti + verificatore |
| FM-14 | Crash durante il recovery | recovery incompleto | al riavvio successivo | **recovery idempotente**: si riesegue | INV-A7 | interruzione del recovery in ogni punto nel simulatore |
| FM-15 | Salto dell'orologio di sistema | durate sbagliate | — | si usa solo l'orologio **monotono** per le durate; l'orologio reale è solo informativo | — | simulatore con orologio manipolato |
| FM-16 | File o directory rimossi o rinominati dall'esterno | struttura incoerente | confronto control log ↔ directory all'avvio e in scrubbing | file mancante di un segmento → quarantena; di un log → `FAULTED` | INV-A6 | test del verificatore |
| FM-17 | Doppia apertura dello stesso Archivio | due scrittori sullo stesso log | lock esclusivo su `LOCK` | la seconda apertura fallisce subito | REQ-AFF-011 | test di doppia apertura |
| FM-18 | Violazione di un invariante interno (difetto) | stato non valido | asserzioni sempre attive | `invariant-violation`; Serie `FAULTED` | INV-A3, INV-A4 | iniezione di difetti (mutation testing) |
| FM-19 | Richiesta malformata o ostile | rischio di crash o di lettura fuori limiti | validazione di ogni campo; limiti di dimensione | `invalid-request`; mai effetti sullo stato | INV-A8 | fuzzing del protocollo |
| FM-20 | Crash del coordinatore tra decisione e OUTCOME | transazione multiserie a metà | `multiserie.log` e `PREPARE` senza `OUTCOME` | recovery completa COMMIT o ABORT (presumed abort) | INV-T4 | FI-03, FI-04, FI-05, FI-12 |
| FM-21 | Crash durante la creazione di una Serie | catalogo e directory incoerenti | stato `creating`/`dropping` nel catalogo | completa o rimuove in recovery | INV-A7 | FI-13 |
| FM-22 | Backup alterato o incompleto | restore non valido | verificatore offline sul backup | il restore rifiuta un backup che non verifica | REQ-AFF-014 | test di backup/restore |
| FM-23 | Snapshot che non termina | spazio trattenuto senza limite | età dello snapshot | terminazione dopo la durata massima (`snapshot-too-old`) | INV-A8 | test di snapshot longevo |
| FM-24 | Contatore seqlock che torna indietro (wrap) | lettura incoerente non rilevata | soglia 2⁶² controllata | fail-stop della Serie | INV-A8, [ADR-0032](../adr/0032-seqlock-a-64-bit.md) | test con contatore iniziale alto |

## Rischi residui accettati

| ID | Rischio | Perché accettato | Mitigazione |
|---|---|---|---|
| RES-01 | FM-03: flush non durevole | fuori dal controllo del software | primitive di flush corrette; documentare i requisiti dell'hardware; backup |
| RES-02 | FM-12: difetti del runtime | SBCL non è qualificato | verifica end-to-end; due piattaforme; versione fissata |
| RES-03 | Perdita di tutti i supporti | un solo dispositivo nella v1 | backup consistente e verificabile ([ADR-0030](../adr/0030-scope-v1.md)); replica in una fase successiva |
| RES-04 | Indipendenza della verifica limitata | autore unico | strumenti automatici, liste di controllo, revisione su dati ([ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md)) |

Ogni voce è anche nel [registro dei rischi](../valutazione/registro-rischi.md).
