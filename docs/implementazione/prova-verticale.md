# Scrittura, crash e riapertura di una Serie

> **Proposta** — Prova C4 di integrazione dei componenti esistenti, con
> orchestrazione seriale esplicita nella fixture. Non è un'API del server.

La [suite](../../tests/vertical/scenarios.lisp) collega preparazione ACTIVE,
WAL/CSN, controller, indice primario e GET. Esegue inserimenti, aggiornamento,
tombstone e letture prima dell'arresto, usando file nativi. Il writer si
arresta con SIGKILL: niente shutdown o cleanup Lisp. Un nuovo processo legge
CONTROL e il decision log completo dell'Archivio, recupera ACTIVE tramite
il lettore autorevole, costruisce e pubblica il checkpoint e rilegge i dati.
Un terzo processo ricostruisce nuovamente indice e letture dai file pubblicati.

Le capacità readonly sono aperte dall'API di prodotto
`io:apri-lettura-nella-directory`, relativa al FD della directory posseduta.
Le letture di recovery di CONTROL, decision log e ACTIVE usano l'EOF
restituito insieme alla rispettiva capacità, rilevato sullo stesso FD.
Le immagini indipendenti della fixture restano disponibili per confrontare
i byte; non forniscono la dimensione di queste tre letture canoniche.

Dal 2026-10-17 anche i nuovi output `.tmp` usano la
[creazione esclusiva relativa di prodotto](io-creazione-relativa.md), tramite
`io:crea-temporaneo-nella-directory` sullo stesso parent posseduto. La fixture
registra subito la capacità append, con budget di trasferimento e dimensione
di 8 KiB; scelta dei nomi e ordine della preparazione restano C4.

| Punto di arresto, in entrambi i formati | Verifica dopo riapertura |
|---|---|
| Cinque commit durevoli | Ultimo valore aggiornato di A, C presente, B cancellato |
| Frammento di 13 byte senza SEAL | Stesso stato committed; coda conservata fisicamente |
| Checkpoint preparato, prima della pubblicazione | CONTROL precedente autorevole; temporaneo conservato; ID preparato non riusato |
| Checkpoint pubblicato e rotazione, poi tre nuovi commit | Letture fra due CLOSED; aggiornamento e tombstone nel secondo segmento prevalgono sul primo |

Gli attesi sono costanti indipendenti dalle risposte del prodotto. Il test
confronta tutti i byte dei segmenti preesistenti dopo il recovery, controlla
segnale 9 e marker del punto di arresto, frontiere, numero di record e valori
letti. Il controllo negativo cambia il valore atteso e richiede l'errore
specifico dell'oracolo, oltre all'uscita non nulla del verificatore.

## Riproduzione

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/record-command.lisp -- sbcl --noinform --no-userinit --no-sysinit --script tools/vertical-crash.lisp --self-test
make check
```

Il [metodo preregistrato](../../tests/vertical/method.md) definisce budget,
workload e limiti. I [risultati conservati](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-vertical-crash/README.md)
distinguono sviluppo e controllo completo finale, senza attribuire prove
precedenti a sorgenti modificati successivamente.

## Ripresa delle scritture e secondo crash

La [nuova fixture](../../tests/vertical/resume.lisp) estende ciascuno degli
otto scenari: un processo nuovo verifica tutti i prefissi CLOSED e ACTIVE
vuoto, ricava il massimo CSN anche dalle tombstone e costruisce un ambiente
distinto con registro, snapshot e controller sulla stessa base. Dopo un
checkpoint esegue quattro nuovi commit e verifica subito i GET e H.
Segue un secondo SIGKILL; due processi nuovi recuperano e rileggono gli
effetti. Il CSN massimo finale appartiene a una chiave cancellata.

La suite esegue 16 scenari positivi e due controlli negativi: 71 processi,
26 SIGKILL intenzionali, attesi costanti e conservazione dei segmenti.
Il nuovo negativo reinizializza il registro a zero: deve rilevare il riuso
del CSN prima dell'append e lasciare il nuovo ACTIVE di soli 64 byte.
Le [evidenze della ripresa](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-vertical-resume/README.md)
conservano anche i tentativi falliti della fixture.
La [verifica completa finale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-vertical-resume-verifica/README.md)
conserva `make check`, le sorgenti verificate e i risultati dei dieci spike.
La successiva [integrazione documentale del full text](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-15-vertical-resume-integrazione/README.md)
verifica la tracciabilità aggiornata, mantenendo distinti i nuovi requisiti progettati.

## Confine rispetto al prodotto

Bootstrap, budget di otto ID proposti, scelta dei nomi, ordine
del recovery e replay dell'indice sono codice di test. Il replay accetta
solo record ordinari, dopo verifica di tutti i prefissi CLOSED; rifiuta
prepared/OUTCOME. La pubblicazione seriale dei candidati segue la radice
del controller: non dimostra l'atomicità fra indice e radice sotto concorrenza.
UUID e completezza del namespace sono fatti della fixture.
Anche con aperture, EOF e creazione esclusiva dei temporanei di prodotto, bootstrap,
selezione tramite probe fra nome temporaneo e definitivo e coordinamento
restano C4. La fixture
registra le capacità restituite e ne mantiene l'ownership fino al cleanup;
non viene introdotta una raccolta di capacità gestita dal motore.

Dal 2026-10-16 la scelta del nuovo ID usa l'[ingresso di prodotto dalla directory](id-directory-recovery.md)
sul manifest autorevole e sul parent posseduto: nomi canonici e una sola
enumerazione attestata, senza costruire un inventario C4 di otto ID.
La fixture controlla separatamente il proprio limite di otto ID e lo stato
`:ready`; non esegue le azioni di rimozione del piano. La scansione dei nomi
è di prodotto; ordine del recovery e replay restano C4.

La ripresa ricostruisce H/CSN nel solo caso della fixture e verifica GET
correnti; non implementa il gate di ammissione del motore o snapshot storici
dopo il crash. Il decision log è vuoto: l'ingresso autorevole viene
esercitato, la semantica multiserie
completa resta nelle campagne dedicate. I file sono piccoli e in cache;
nessuna misura di prestazione, power loss o qualifica C1/MC/DC.

La prova rende concreta la composizione di una Serie e il suo recovery.
Resta da trasferire il coordinamento nel motore con contratti, errori e
verifiche propri, integrare MVCC e multiserie, e qualificare carichi prolungati,
GC, piattaforma di riferimento e funzionalità successive della roadmap.

## Revisione dell'estensione C4

Una lettura con lista di controllo verifica: budget di file/processi/cicli;
verifica di tutti i CLOSED prima del replay; ACTIVE vuoto prima del rebasing;
ambiente nuovo senza riuso delle capacità dell'ispezione; un registro comune
a WAL/controller/snapshot; oracoli costanti per dati e CSN; errore tipizzato
prima dell'append nel negativo; byte originali immutati dopo entrambi i crash.
La cancellazione di una chiave già assente è ammessa solo se il GET ne
conferma l'assenza. Quella estensione non modificava sorgenti C1. Il successivo
collegamento alla scelta ID di prodotto ha contratto e verifiche dedicati;
questa lettura C4 non è una revisione indipendente o una qualifica C1 del
Recovery Manager.

### Acquisizione delle fonti — 2026-10-17

ACTIVE e CLOSED vengono ora aperti tramite il [set posseduto di prodotto](fonti-recovery.md),
una volta per manifest canonico della fixture. Il test usa le capacità prestate,
termina i reader e chiude i set prima del parent; non scansiona più gli ID
CLOSED da uno a otto. Otto resta il budget C4, senza restringere ID o inventario
nel prodotto. La campagna mantiene i 16 scenari positivi e i due controlli
negativi; replay e coordinamento complessivo restano nel test.
