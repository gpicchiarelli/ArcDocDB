# Recupero del vecchio ACTIVE: metodo delle prove funzionali

Metodo registrato prima delle esecuzioni per il modulo
[`src/recovery-active/`](../../src/recovery-active/), già descritto in
[active-recuperato.md](active-recuperato.md). L'incremento aggiunge una suite
dedicata; usa lettori, decoder e publisher esistenti.

La suite corrente è in `tests/recovery-active-checkpoint/`, nel package
`arcdocdb.recovery.active.checkpoint.tests`. Il primo congelamento
`b92c1a25619279f1d4e1244fc970b3829c0ecca4` e le relative prove conservate
usavano `tests/recovery-active/` e `arcdocdb.recovery.active.tests`.
La successiva integrazione di una campagna distinta su `main` ha richiesto
di isolare questa suite: restano invariati i 27 nomi e i corpi dei test.
La CI del nuovo commit verifica insieme entrambe le suite.

## Autorità e risorse

Ogni fixture possiede un namespace temporaneo esclusivo, file nativi,
capacità, backend osservato e scratch privati. Il vecchio `control.log` è
letto attraverso `leggi-control-recuperato`; il suo manifest identifica il
vecchio ACTIVE. Il segmento è letto dal proprio FD readonly distinto dal
control log. EOF e identità fisica provengono dal FD mantenuto stabile.

La tabella DECISION è ricostruita dal decoder pubblico su un log completo
dichiarato dalla fixture, con partecipanti e risultati noti prima della
codifica. Non si usa una tabella privata costruita a mano o NIL come
scorciatoia per l'assenza di decisioni. Completezza e appartenenza allo
stesso Archivio restano precondizioni del controller: la prova non realizza
il lettore del log dell'Archivio né l'esclusione di altri processi.

La campagna esercita l'ingresso `leggi-active-recuperato` con tabella nuda.
L'ingresso `leggi-active-con-decisioni`, introdotto successivamente nel
[lettore dell'Archivio](decisioni-recuperate.md), mantiene una qualifica
dedicata distinta da questi casi.

Packing little-endian, CRC bitwise, record e SEAL delle fixture sono
indipendenti dagli encoder di prodotto. Offset, prefisso atteso, conteggi
e coppie TXID/CSN sono fatti dichiarati della fixture. Le factory reali
costruiscono i wrapper di prodotto; nessun risultato viene forgiato.

## Casi e oracoli

Ogni caso funzionale esercita separatamente v1 e v2:

- header-only e lotti ordinari PUT/tombstone;
- prepared con OUTCOME locale, DECISION concordante o assente; DECISION
  senza OUTCOME; assenza di entrambe e presumed abort;
- CSN zero presente, TXID/CSN u64 alti, duplicati OUTCOME identici e
  OUTCOME senza prepared nel segmento;
- contraddizioni tra partecipanti, CSN, duplicati e lotti; prepared dopo
  OUTCOME; budget esatti e insufficienti;
- prefisso completo, coda non sigillata conservata e corruzione attestata
  da un SEAL durevole successivo;
- query pubbliche e serializer CLOSED: solo esiti derivati, TXID ordinati,
  dimensione `20 + 16 × E`, offset e sentinelle attorno al range;
- chiusura verso un checkpoint completo, pubblicazione attraverso il
  publisher unico e riapertura del nuovo control log; rifiuti di P/esiti
  e capacità chiusa prima del claim.

`esito-chiusura-active = NIL/0` indica assenza di un esito **derivato da
conservare**; un OUTCOME già locale può avere la stessa risposta. Le
statistiche verificano `prepared = locali + derivati + abort`, distinguendo
i record fisici dagli identificativi di transazione distinti.

Durante la lettura non devono avvenire append, flush, rename o chiusure.
Le osservazioni prima/dopo comprendono byte, EOF, inode, offset e frontiere
delle capacità. Dopo il risultato lo scratch può essere sovrascritto per
verificare che query e serializer non lo prendano in prestito. Le risorse
native restano aperte fino al cleanup esclusivo della fixture.

Il nuovo controllo della pubblicazione precede il claim: un rifiuto lascia
il publisher preparato e il nome autorevole invariato. Il successo segue
la rinomina atomica e il fsync del parent; la riapertura verifica il
manifest effettivamente nominato. Le prove del publisher generico restano
distinte dalle nuove prove del collegamento ACTIVE.

## Esecuzione e conservazione

Gli autori lavorano su file distinti e rileggono il codice prima delle
esecuzioni. Sorgenti e metodo vengono congelati in un commit. La verifica
completa usa `make check`, che conserva ambiente, comando, sorgenti prima
e dopo, esito e output originali anche quando fallisce. I sorgenti restano
immutati durante il processo. La CI ripete la verifica su Linux e macOS.
Ogni correzione successiva appartiene a un nuovo commit e conserva il
tentativo precedente.

Le evidenze citate vengono conservate nel catalogo con i registri originali;
si leggono come dati, con `*read-eval* NIL`, senza caricare report o FASL.
La copia e la conservazione precedono la pulizia del worktree.

Requisiti interessati: REQ-REC-001, REQ-REC-002, REQ-STO-003, REQ-TXM-005,
REQ-TXM-007, REQ-FOR-001, REQ-FOR-003, REQ-AFF-001, REQ-AFF-002,
REQ-AFF-008, REQ-AFF-009, REQ-AFF-018 e REQ-VAL-001. Le decisioni locali
ARV-D01…D14 sono un riferimento per i casi; questa campagna funzionale non
attesta MC/DC o qualifica C1 completa. Non misura prestazioni o heap e non
ricostruisce primary, orizzonte CSN, inventario o gate di ammissione.
