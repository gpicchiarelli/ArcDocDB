# ADR-0054 — Contratto operativo e formato degli indici full text

- **Stato:** Accettata per il progetto; nessun componente full text implementato o qualificato
- **Data:** 2026-10-15
- **Rapporto con la specifica:** completa i dettagli rinviati da
  [ADR-0053](0053-ricerca-full-text-indici-invertiti.md): profilo iniziale, query, budget,
  interfacce, generazioni e formato binario. Estende il formato `.idx` di
  [ADR-0026](0026-indici-secondari-segmentati.md) con una versione specifica per il
  full text; precisa la pubblicazione dei derivati di
  [ADR-0040](0040-manifest-a-record-unico.md). Gli altri indici e i record v1/v2 restano invariati.
- **Riferimenti:** [contratto full text](../full-text.md),
  [formato binario](../formato-indice-full-text.md), REQ-SEC-007…REQ-SEC-010,
  INV-I4, INV-I5, INV-I6

## Contesto

La ricerca full text è approvata, ma i dettagli lasciati alla fase 8 consentono ancora
interpretazioni incompatibili: versione Unicode implicita, riuso degli ordinali di un
altro hint, risultati parziali durante il build e saturazione dopo una decisione durevole.
L'autore chiede di completare la progettazione senza sviluppare codice.

## Decisione

I due documenti collegati sopra sono parte normativa di questa decisione. Fissano:

1. Profilo `unicode-word-18.0.0-v1`, con tabelle Unicode 18.0.0, NFC, case folding
   completo non turco e parole secondo UAX #29 revisione 49. La versione è esplicita;
   non viene ereditata da SBCL, dal sistema operativo o dalla locale.
2. Foglie AST full text con indice e campo espliciti, `all/any` e frasi. Ogni query ha
   uno snapshot, una generazione per indice e un esito terminale; un risultato consegnato
   prima di un errore non equivale a una ricerca completata.
3. Indice invertito `.idx` versione 2, tipo 5, con header di 64 byte, sei sezioni,
   dizionario e posting a larghezza fissa, posizioni `u32`, identità della generazione
   e legame verificato con i byte dell'hint. Nessuna compressione o Bloom nel primo codec.
4. Identificativi di indice e generazione allocati dal catalogo, mai riusati. Ogni
   generazione ha file propri. Rebuild di un file definitivo corrotto passa a una nuova
   generazione; non sovrascrive il vecchio file. La rimozione di una generazione è
   autorizzata dal catalogo e completata dopo la quiescenza dei reader.
5. Copertura verificata sull'inventario dei segmenti e sulle frontiere pubblicate,
   con acquisizione dei nuovi commit durante il build. Readiness è stato derivato:
   solo il writer della Serie pubblica la nuova vista completa.
6. Capacità di delta e buffer riservata prima di SEAL o PREPARE; un limite superiore
   conservativo alla dimensione del futuro file indice guida anche la rotazione.
   Il documento di configurazione dichiara limiti finiti, con default di progetto.
7. Contratti per analisi, ammissione, pubblicazione, query, I/O, build e reclaim, con
   ownership e rifiuti espliciti. La ricerca iniziale riguarda una Serie; la combinazione
   con le appartenenze NNTP in altre Serie appartiene all'applicazione sullo stesso snapshot.

### Serializzazione e atomicità

Il writer della Serie serializza adozione del contratto, prenotazioni, applicazione dei
delta e scambio della vista. Analisi, costruzione e verifica dei file operano su buffer
privati nei pool esistenti. L'I/O passa dal pool dedicato. Nessuna scrittura condivisa
per documento tra Serie, nuovo coordinatore globale o attesa dentro un'epoca EBR.

SEAL e DECISION conservano il loro ruolo per i documenti. Una modifica della configurazione
degli indici è decisa da un documento di catalogo con durability `:strong`. La rinomina
di un derivato preparato completa una configurazione già decisa e non introduce un
secondo commit del documento. La readiness in memoria si perde e si verifica nuovamente
al riavvio. Rotazione e compaction restano decise da EDIT.

## Conseguenze

- Formato, semantica e confini dei moduli sono abbastanza precisi da sviluppare codec,
  analizzatore e modelli senza scegliere comportamenti incompatibili fra loro.
- Il primo formato usa più spazio rispetto a posting compressi; è una scelta di
  verificabilità, da misurare prima di un eventuale nuovo codec/versione.
- Un cambio profilo può rendere temporaneamente indisponibili le nuove query. I reader
  già ammessi conservano la propria generazione e il proprio snapshot entro i budget.
- Default e limiti sono politiche di ammissione, non risultati o promesse prestazionali.
- Lo stato dei requisiti resta `:progettato`; i gate della fase 8 rimangono aperti.

## Alternative considerate

- Affidare l'analisi alla versione Unicode del runtime: rende instabile il significato
  degli indici esistenti durante un aggiornamento del processo.
- Comprimere subito con varint, front-coding e salti: aumenta i casi del primo decoder;
  si conserva un punto di estensione tramite nuova versione del formato.
- Ricalcolare il full text dopo la conferma: introduce una finestra di risultati incompleti.
- Sostituire in posto un file corrotto: complica identità, reader attivi e conservazione
  dell'anomalia; una nuova generazione esplicita il passaggio.

## Valutazione

La [matrice di accettazione](../full-text.md#criteri-di-accettazione) specifica corpus,
oracoli, crash, saturazione e casi negativi. Sono prove da realizzare, distinte dai
controlli documentali eseguiti ora. Il profilo si qualifica con i corpus ufficiali
Unicode della versione fissata e con attesi manuali; il codec con fixture binarie
indipendenti, alterazioni anche con CRC ricalcolato e decoder/encoder separati.
