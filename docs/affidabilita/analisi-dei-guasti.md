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
| FM-01 | Perdita di alimentazione o crash durante append | ultimi lotti del log parziali o assenti | lotto non valido (CRC, SEAL mancante o non corrispondente) | **coda** se nessun SEAL successivo dichiara una frontiera durevole oltre l'anomalia: la lunghezza valida è l'inizio del primo lotto non valido; nulla viene troncato, il segmento è chiuso a quella lunghezza ([ADR-0037](../adr/0037-lotto-sigillato.md) §3–4) | INV-F1, INV-F2, INV-F3, INV-D1, INV-A9 | FI-01, FI-02; simulatore |
| FM-02 | `fsync`/`rename`/`write` restituisce errore | stato delle pagine indefinito | codice di ritorno | **nessun retry**; Serie/Archivio `FAULTED`; nessuna conferma del lotto | INV-A1 | simulatore con errori di I/O |
| <a id="fm-03"></a>FM-03 | Flush riuscito ma non durevole (supporto o firmware) | perdita di dati confermati | non rilevabile a runtime; rilevabile dalla verifica a posteriori | `F_FULLFSYNC` su macOS, `fdatasync` su Linux; **rischio residuo dichiarato** | — | prova con interruzione di alimentazione fuori dalla CI |
| FM-04 | Alterazione di un segmento chiuso | dato sbagliato | CRC alla lettura; scrubbing | segmento in quarantena (`DEGRADED`); errore `corruption-detected`; ripristino da backup | INV-A2, INV-A6 | corruzione deliberata di ogni file; scrubbing |
| FM-05 | Scrittura persa o indirizzata male (supporto la conferma, i dati non ci sono) | record mancante o altrui | CRC e confronto chiave/versione alla lettura; scrubbing e confronto hint ↔ segmento ↔ control log | quarantena; `FAULTED` se riguarda log di controllo | INV-A2, INV-A6, INV-F1 | scenari di scrittura persa nel simulatore |
| FM-06 | Alterazione di dati già durevoli nel segmento `ACTIVE` o in un log di controllo | rischio di scartare dati committed | un SEAL valido successivo dichiara una frontiera durevole oltre l'anomalia | `FAULTED`; nessuna scrittura; decisione dell'operatore | INV-A1, INV-F3 | FI-01 con danno sotto la frontiera |
| FM-07 | Spazio disco esaurito | scritture impossibili | spazio libero sotto riserva; `ENOSPC` | rifiuto controllato `resource-exhausted` prima dell'esaurimento; `ENOSPC` in scrittura = errore di scrittura (FM-02) | INV-A8, INV-A1 | simulatore con disco pieno |
| FM-08 | Errore di lettura (`EIO`) | dato non disponibile | codice di ritorno | errore `io-fault` per quella lettura; ripetuti → quarantena del segmento; **mai** un dato non verificato | INV-A2 | simulatore con errori di lettura |
| FM-09 | Descrittori di file esauriti | impossibile aprire segmenti | `EMFILE` | rifiuto controllato; limite di segmenti aperti e cache dei descrittori limitata | INV-A8 | test di saturazione |
| FM-10 | Esaurimento dello heap | possibile uscita fatale del runtime | bilancio di memoria; soglie interne | rifiuto ben prima del limite (backpressure); heap dimensionato esplicitamente all'avvio; bilancio verificato all'avvio | INV-A8 | test di saturazione; SPK-02 |
| FM-11 | Bit flip nell'indice o nella cache | location o dato sbagliato | confronto chiave/CSN con il record; CRC di intestazione e corpo | in cache: la entry è scartata e si rilegge dal segmento, senza quarantena; nell'indice: errore `corruption-detected`, indice ricostruibile dagli hint | INV-A2, INV-A12 | iniezione di bit flip in memoria nel simulatore |
| <a id="fm-12"></a>FM-12 | Difetto del compilatore, GC o runtime | corruzione arbitraria | controlli end-to-end; asserzioni | versione fissata e provata su due piattaforme; **rischio residuo dichiarato** | INV-A2, INV-A3 | CI su Linux e macOS; soak test |
| FM-13 | `kill -9` del processo | arresto improvviso | al riavvio | recovery ([architettura](../architettura.md#recovery)) | INV-D1, INV-A7 | crash reali ripetuti + verificatore |
| FM-14 | Crash durante il recovery | recovery incompleto | al riavvio successivo | **recovery idempotente e non distruttivo**: fino alla rinomina del control log compattato nulla è cambiato; si riesegue | INV-A7, INV-A9 | interruzione del recovery in ogni punto nel simulatore |
| FM-15 | Salto dell'orologio di sistema | durate sbagliate | — | si usa solo l'orologio **monotono** per le durate; l'orologio reale è solo informativo | — | simulatore con orologio manipolato |
| FM-16 | File o directory rimossi o rinominati dall'esterno | struttura incoerente | confronto control log ↔ directory all'avvio e in scrubbing | file mancante di un segmento → quarantena; di un log → `FAULTED` | INV-A6 | test del verificatore |
| FM-17 | Doppia apertura dello stesso Archivio | due scrittori sullo stesso log | lock esclusivo su `LOCK` | la seconda apertura fallisce subito | REQ-AFF-011 | test di doppia apertura |
| FM-18 | Violazione di un invariante interno (difetto) | stato non valido | asserzioni sempre attive | `invariant-violation`; Serie `FAULTED` | INV-A3, INV-A4 | iniezione di difetti (mutation testing) |
| FM-19 | Richiesta malformata o ostile | rischio di crash o di lettura fuori limiti | validazione di ogni campo; limiti di dimensione | `invalid-request`; mai effetti sullo stato | INV-A8 | fuzzing del protocollo |
| FM-20 | Crash del coordinatore tra decisione e OUTCOME | transazione multiserie a metà | `multiserie.log` e `PREPARE` senza `OUTCOME` | recovery completa COMMIT o ABORT (presumed abort) | INV-T4 | FI-03, FI-04, FI-05, FI-12 |
| FM-21 | Crash durante la creazione o l'eliminazione di una Serie | catalogo e directory incoerenti | directory `.tmp`; stato `dropping` nel catalogo | `.tmp` senza documento: eliminata; `.tmp` con documento: rinominata; `dropping`: rimozione completata ([ADR-0040](../adr/0040-manifest-a-record-unico.md) §5) | INV-A7, INV-A11 | FI-13 |
| FM-22 | Backup alterato o incompleto | restore non valido | verificatore offline sul backup | il restore rifiuta un backup che non verifica | REQ-AFF-014 | test di backup/restore |
| FM-23 | Snapshot che non termina | spazio trattenuto senza limite | età dello snapshot | terminazione dopo la durata massima (`snapshot-too-old`) | INV-A8 | test di snapshot longevo |
| FM-24 | Contatore seqlock che torna indietro (wrap) | lettura incoerente non rilevata | soglia 2⁶² controllata | ricostruzione del frammento, che azzera i contatori ([ADR-0043](../adr/0043-primary-index-a-frammenti.md)) | INV-A8, [ADR-0032](../adr/0032-seqlock-a-64-bit.md) | test con contatore iniziale alto |
| FM-25 | Persistenza non ordinata delle scritture non sincronizzate (un lotto successivo è su disco, uno precedente no) | lotto valido dopo un lotto mancante | frontiera durevole dei SEAL | è una coda: i lotti oltre il primo non valido non erano confermati e sono ignorati; **non** è un guasto | INV-F3 | FI-01, FI-02 con sottoinsiemi arbitrari dei lotti non sincronizzati |
| FM-26 | File o directory con nome definitivo che nessuna fonte di verità conosce | possibile difetto del manifest o intervento esterno | riconciliazione al riavvio; verificatore | **non si elimina**: evento registrato, oggetto lasciato intatto | INV-A10 | test del verificatore; FI-09, FI-13 |
| FM-27 | Un commit resta in volo a lungo (flush lento o bloccato di una Serie) | gli snapshot dell'Archivio non nascono | distanza tra CSN e orizzonte; tempo di attesa | attesa con tempo massimo, poi `resource-exhausted`; letture e scritture senza snapshot non sono toccate; una Serie `FAULTED` libera l'orizzonte | INV-M4, INV-A8, INV-P3 | simulatore con flush ritardato |

## Rischi residui accettati

| ID | Rischio | Perché accettato | Mitigazione |
|---|---|---|---|
| RES-01 | FM-03: flush non durevole | fuori dal controllo del software | primitive di flush corrette; documentare i requisiti dell'hardware; backup |
| RES-02 | FM-12: difetti del runtime | SBCL non è qualificato | verifica end-to-end; due piattaforme; versione fissata |
| RES-03 | Perdita di tutti i supporti | un solo dispositivo nella v1 | backup consistente e verificabile ([ADR-0030](../adr/0030-scope-v1.md)); replica in una fase successiva |
| RES-04 | Indipendenza della verifica limitata | autore unico | strumenti automatici, liste di controllo, revisione su dati ([ADR-0031](../adr/0031-software-critico-criteri-e-priorita.md)) |
| RES-05 | Danno a riposo ai soli lotti resi durevoli dall'ultimo flush prima di un arresto improvviso, non ancora testimoniati dal SEAL di un lotto successivo: è indistinguibile da una coda | è il confine di ciò che un log può sapere di sé; richiede la coincidenza di un arresto improvviso e di un danno in quei pochi lotti | un arresto ordinato chiude il segmento (nessuna finestra); scrubbing; backup ([ADR-0037](../adr/0037-lotto-sigillato.md)) |

Ogni voce è anche nel [registro dei rischi](../valutazione/registro-rischi.md).
