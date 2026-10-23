# Ricostruzione verificata dei frammenti v2

## Contratto

`arcdocdb.index.primary:ricostruisci-frammento-indice` completa il costruttore
per rebuild e split dell'[indice primario](indice-primario.md).
Riferimenti: ADR-0015, ADR-0032, ADR-0043, ADR-0048 e ADR-0050.
Requisiti C1: REQ-IDX-001, REQ-IDX-003, REQ-IDX-005, REQ-IDX-007,
REQ-LIM-003, REQ-AFF-004, REQ-AFF-008. Invarianti INV-I3, INV-A8 e INV-P6.

Il writer mantiene il gettone esclusivo della Serie per tutta la chiamata.
Sorgente e root restano correnti e scrivibili fino alla successiva
`pubblica-directory-indice`. Il risultato è un piano privato monouso.
La pubblicazione usa il protocollo esistente: sorgente congelato, barriera,
CAS della root, nessun riavvio dei frammenti ritirati.

```lisp
(ricostruisci-frammento-indice index source highs lows budget
                             :split-p nil)
;; => piano, capacità-sorgente, byte-chiavi-copiati,
;;    riferimenti-nuova-directory, payload-transitorio
```

`highs` e `lows` sono array specializzati di C u32 ciascuno, privati e
immutati durante la chiamata, indicizzati per **slot originale**.
Il chiamante fidato calcola il digest con funzione e seed della Serie.
Gli elementi dei posti liberi sono ignorati. Il costruttore verifica per
ogni chiave viva prefisso, fingerprint e ricerca nello slot originale.
I bit alti non ancora discriminati dalla directory non si possono ricavare
dal payload: coerenza del digest e gestione del seed restano al chiamante.
Questo controllo non sostituisce una funzione hash del prodotto.

`calcola-digests-frammento` produce ora le due mappe dagli slot fisici
tramite [XXH64 e seme immutabile dell'indice](hash-chiavi.md), verificando
la coppia completa del seme prima delle scritture e il lookup originale
per ogni chiave. La gestione del seme al riavvio resta al controller.

## Tre fasi prima della pubblicazione

1. Scansione di C slot: controllo Swiss, payload stabile, intervallo della
   chiave entro i byte usati, lookup originale, conteggio vivo e byte
   necessari per ciascun candidato.
2. Preflight dei budget e dei crediti; allocazione di uno o due frammenti
   BUILDING con arena esattamente sufficiente alle chiavi vive, almeno un
   byte nel candidato vuoto; seconda scansione per la copia.
3. Terza scansione: ogni chiave sorgente viene cercata byte per byte nella
   destinazione, e vengono confrontati CSN, location, lunghezza record,
   fine validità e metadati della chiave, salvo l'offset locale dell'arena.
   Solo dopo si prepara la nuova directory.

Il confronto di tutte le chiavi precede il piano: l'uguaglianza del numero
vivo da sola non basta. La rimozione dei byte di chiavi cancellate rende
il rebuild una compattazione dell'arena. Lo split segue il bit successivo
della metà alta del digest; il resto dei frammenti rimane condiviso.

## Budget, interruzioni e costi

Il preflight include payload della root corrente, nuovi banchi/controlli/
arene e nuova directory. Verifica anche budget dei singoli frammenti,
profondità, dimensione della directory, generazione e credito di revisione
per tutte le copie e per la successiva pubblicazione, senza wrap.
Il rifiuto di input o budget precede la costruzione dei candidati e non
modifica la revisione, la root o lo stato del sorgente.

Il controller deve prenotare memoria e tempo prima della chiamata e
contabilizzare separatamente digest, tre buffer fissi di cinque u64,
strutture del runtime, root pregresse, garbage e lavori pendenti.
Il payload transitorio restituito **non è RSS** o un tetto di memoria del DB.
Non sono presenti callback, thread, I/O, lock o contatori comuni fra Serie.

Ogni fase visita C slot distinti: tre scansioni complete, oltre ai probe
interni. Ogni probe writer visita al massimo C slot, confrontando chiavi
lunghe al massimo 65.535 byte. Il caso ostile è quindi limitato ma può
costare O(C² × lunghezza-chiave). Directory: O(2^G) riferimenti. Copia:
byte vivi delle chiavi. Nessuna garanzia di pausa costante o P99 del motore.
La manutenzione alloca e deve essere programmata fuori dal percorso caldo.

Le mutazioni dei candidati avanzano la revisione locale: anche un piano
precedente diventa conservativamente stale. Un'interruzione dentro una
mutazione segue il suo protocollo fail-stop e il cleanup del contesto.
Fra mutazioni, i candidati privati incompleti sono scartabili dal GC;
nessuna root è pubblicata e il sorgente non richiede rollback.
Una copia incoerente rilevata rende terminale la salute dell'indice.

## Qualifica

Metodo e risultati vengono conservati nella
[campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-index-rebuild/README.md).
La revisione delle decisioni è in
[indice-ricostruzione-revisione.md](indice-ricostruzione-revisione.md).
La campagna riguarda questo componente in memoria: hashing, versioni
trattenute ricercabili, prenotazioni transazionali, recovery, storage,
GET completo e qualificazione su x86-64 restano integrazioni successive.
