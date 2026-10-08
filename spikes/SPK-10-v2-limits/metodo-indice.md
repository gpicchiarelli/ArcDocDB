# SPK-10 — metodo del frammento primario v2

> **Deciso (limiti e layout → ADR-0048)** — `_id` binario di 1–65.535
> byte; slot di cinque parole u64 e un byte di controllo; offset chiave u32,
> lunghezza chiave u16 e lunghezza record u32. Fonti: ADR-0032, ADR-0043,
> ADR-0050; REQ-LIM-001/003 e REQ-IDX-003/005/007.

> **Proposta** — esperimento Common Lisp/SBCL indipendente, `safety 3`,
> in `indice.lisp`, package `arcdocdb.spk10.indice`. Questo metodo è registrato
> prima della compilazione e dell'esecuzione. L'ambito comprende il frammento
> primario sperimentale e il relativo metodo.

## Domanda e ambito

Il layout v2 rappresenta senza troncamenti chiavi arbitrarie e record contenenti
16 MiB documentali, mantenendo limitati sondaggio, tentativi, arena e manutenzione?
Un inserimento rifiutato lascia identici root, array, metadati e contatori?

> **Proposta** — un frammento Swiss scalare, sondato in gruppi di otto,
> `ctrl[C]` e `slots[5*C]`. Un writer proprietario; reader con seqlock e
> ricontrollo della root/generazione anche sul miss, massimo otto tentativi.
> Rebuild e CAS della root sono implementati. Directory estendibile, split,
> versioni trattenute e inoltro effettivo al writer dopo `:retry-limit` sono
> pendenti. La capacità scelta dal benchmark contiene l'intero carico richiesto.

## Preparazione e budget

> **Proposta** — l'arena parte da zero byte e cresce geometricamente secondo
> i byte usati, con tetto configurato; nessuna prenotazione `C*65535`.
> Le chiavi pubblicate sono copie private; aggiornare una entry riutilizza la
> copia immutabile esistente. Un inserimento nuovo prepara una copia privata
> prima di modificare il frammento. Rebuild e crescita preparano gli array nuovi
> fuori dalla root. Tutti i rifiuti previsti precedono la pubblicazione.

Budget distinti: capacità e carico 7/8, massimo della singola chiave, massimo
dell'arena, byte delle chiavi copiati per operazione (comprende staging e copia
finale, oltre ai byte esistenti spostati), payload transitorio vecchio + nuovo
+ staging, tempo cooperativo della preparazione. Rebuild visita al massimo C
slot sorgenti; la directory rappresentata dalla root contiene un riferimento.
Generazione e seqlock non fanno wrap; vicino alla soglia il seqlock richiede rebuild.

Il tempo usa `get-internal-real-time`, iniettabile nel solo harness: controlli
tra blocchi di copia limitati e prima della pubblicazione. È un budget di wall
time cooperativo: allocazioni, GC, scheduling e la fase finale di pubblicazione
non sono interrompibili e possono superarlo. La memoria contata è payload degli
array e riferimenti, **non RSS**; header Lisp, runtime, garbage e root trattenute
dai reader richiedono ulteriori risorse. Il singolo writer serializza preparazione
e pubblicazione dell'indice; nessuno stato condiviso tra Serie.

## Verifica corta

1. Compilare soltanto `indice.lisp` in un FASL temporaneo; ogni warning o
   style-warning è fatale, come i valori warnings/failure di `compile-file`.
   Conservare `out/indice-check.lisp` (ignorato) come plist schema 1, leggibile
   con `*read-eval* = nil`: comando, ambiente, blob Git dei sorgenti, stato della
   compilazione, risultato decodificato, limiti, tempi, stdout/stderr e fallimenti.
2. `(check)` restituisce una plist con `:status :ok`, conteggi e limiti effettivi.
3. Fixture dei confini 0/1/255/256/65.535/65.536; layout e riservati;
   record massimo 16.842.775 byte, documentale configurabile e limite u32;
   CSN/location u64 alti; confronto completo di chiavi con prefisso comune e
   impronta uguale; mutazione dell'input dopo l'inserimento.
4. Saturazione di arena, copie e transitorio; tempo esaurito tramite clock
   deterministico. Ogni rifiuto confronta snapshot completo prima/dopo.
   Churn e rebuild recuperano byte morti e tombstone. Saturazione degli slot
   produce un rifiuto esplicito.
5. Hash streaming FNV-1a u64 con seed fisso: golden e confronto con calcolo
   indipendente; workload deterministico contro `hash-table :test 'equalp`.
   Le copie dell'oracolo non sono usate dall'indice.
6. Iniezioni deterministiche: campi cambiati sotto seqlock, contatore dispari,
   hit/miss su root ritirata, cambiamenti ripetuti fino a `:retry-limit`.

## Benchmark nell'harness integrato

> **Proposta** — `(benchmark)` usa chiavi di 16/256/65.535 byte e massimi
> di 10.000/1.000/64 documenti; un solo termine wall time condiviso,
> default 3 secondi, massimo configurabile 3 secondi; payload transitorio
> massimo 128 MiB. Riporta documenti realmente inseriti, letture e modifiche
> realmente completate, durata e statistiche. Ogni fase verifica il termine
> tra operazioni: il limite temporale è cooperativo. L'harness esegue le misure
> in serie; la verifica locale comprende soltanto strict compile e check breve.

## API

> **Proposta** — le keyword inglesi corrispondono al harness; i termini di
> dominio nel modulo sono italiani. Solo un writer chiama mutazioni e
> `statistiche`; il chiamante mantiene stabile il buffer chiave durante ogni
> chiamata. Dopo l'inserimento può modificarlo: l'indice conserva la copia privata.

| Funzione | Contratto |
|---|---|
| `make-indice` | Keyword e default: `:capacity 16384` (potenza di due, 8–32768), `:max-key-bytes 65535`, `:max-document-bytes 16777216`, `:max-arena-bytes 8388608`, `:copy-byte-budget 16777216`, `:transient-byte-budget 134217728`, `:maintenance-seconds 1/2`, `:clock #'get-internal-real-time`. L'arena iniziale è vuota. |
| `inserisci indice chiave csn segmento offset lunghezza` | `csn` u64; segmento, offset e lunghezza u32. Lunghezza totale del record: header di 24 byte + chiave + documento, massimo documentale configurato. Restituisce `t` per entry nuova, `nil` per aggiornamento. |
| `elimina indice chiave` | `t` se eliminata, `nil` se assente; non rende durevole alcunché. |
| `leggi indice chiave` | Cinque valori: CSN u64, location u64 (`segmento` nei 32 bit alti), record-len u32, stato `:hit/:miss/:retry-limit`, numero dei tentativi scartati. Su miss/limite i campi sono zero. Keyword `:attempts` 1–8; hook del solo test `:after-fragment` e `:after-fields`. Nessun inoltro implicito al writer. |
| `statistiche indice` | Plist con payload, byte usati/capacità/vivi, conteggi, costi massimi e budget effettivi; non conta il RSS. |
| `check` | Plist `:status :ok`, otto gruppi di fixture, conteggi, limiti e attività pendenti; segnala errore se una fixture fallisce. |
| `benchmark &key (seconds 3)` | Termine globale cooperativo, `seconds` reale 0–3. Conteggi effettivi per carico e per fase, compresi separatamente delete/reinsert di churn; documenti finali nelle statistiche. Riporta anche l'eventuale superamento del termine. |

Rifiuti previsti: `limite-indice`, con `limite-motivo` per arena, byte copiati,
memoria transitoria, tempo, capacità, lunghezza chiave/record e generazione.
Un valore fuori dal tipo dichiarato segnala `type-error`; non si tronca.
I costi del clock di preparazione escludono validazione, hash e sondaggio iniziali;
questi hanno limiti di lavoro dati da lunghezza chiave e capacità. Il confronto
è scalare e il hash non è crittografico: nessuna difesa da collisioni avversarie
o prestazione media garantita. La fixture misura le allocazioni del kernel hash
inline, non pretende assenza di allocazioni in tutte le API.
Il limite documentale è verificato sul totale numerico del record; questo modulo
non alloca né valida un documento CBOR e non duplica il codec o la migrazione offline.

## Ambiente e risultato

Ambiente osservato prima dell'esecuzione: macOS Darwin ARM64, Apple M4,
SBCL 2.6.9, `internal-time-units-per-second = 1000000`.

Risultato locale: strict compile senza warning/style-warning; `(check)` restituisce
`:status :ok` per otto gruppi, 600 operazioni differenziali e 664 confronti
con `hash-table equalp`, 64 cicli con 384 inserimenti e 384 eliminazioni.
Sette fixture di budget confrontano integralmente lo stato prima/dopo il
rifiuto. Due chiavi lunghe 255 e 256 byte, con prefisso comune di 255 byte e
impronta uguale, restano distinte. Nella fixture locale il kernel hash inline ha allocato zero byte
per 256 attraversamenti di una chiave di 256 byte. Il churn termina con arena
vuota; il differenziale esercita rebuild che copiano anche entry vive.

L'artefatto `out/indice-check.lisp` conserva tutte le esecuzioni locali,
con risultato, blob e tempi effettivi. Il primo tentativo falliva perché SBCL
rilevava a compilazione i dati negativi intenzionali delle fixture; il confine
dinamico del solo harness ora esercita quei typecheck a runtime. Il benchmark
non è stato eseguito localmente.

Nessuna evidenza di questo frammento
completa il gate v2, valida la concorrenza su entrambe le architetture o
conferma un commit di produzione; non implementa storage né conversione offline.
