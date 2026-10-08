# SPK-02 — GC di SBCL sotto carico

> **Proposta** — Esperimento di Fase 0, classe C4. Metodo sintetico per valutare
> ADR-0024, ADR-0043 e ADR-0045; non costituisce codice di produzione o verifica
> dei minimi di ADR-0028. L'autore ha confermato ADR-0028/0030.

## Domanda

Come variano i tempi di collection con memoria viva in un array specializzato
grande, frammenti da 256 KiB, frammenti sostituiti e memoria foreign? Come incidono
tasso di allocazione e numero di worker attivi oppure in attesa di semaforo?

## Metodo previsto prima dell'esecuzione

- Package `arcdocdb.spk02`, API `(check)` e `(benchmark &key ...)`, solo Common
  Lisp e facility SBCL, `safety 3`, senza dipendenze esterne.
- Payload vivo predefinito: 128 MiB, configurabile in byte. I quattro layout sono
  `:heap-large`, `:heap-fragments`, `:heap-replacement` e `:foreign`. I primi tre
  usano array `(unsigned-byte 8)`; il confronto foreign usa
  `sb-alien:make-alien`/`free-alien`, sempre con `unwind-protect`. Le pagine sono
  toccate prima della misura; l'ultimo frammento può essere più piccolo.
- Un controller è il solo allocatore intenzionale: inietta payload transitori
  da 64 KiB a tassi aggregati richiesti di 0, 4 MiB/s e 128 MiB/s. Riporta i byte
  effettivamente prodotti e il tasso osservato, senza supporre che il tasso
  richiesto sia stato raggiunto. Un anello limitato trattiene gli ultimi payload.
  Nei casi di rimpiazzo il controller sostituisce un frammento per passo, con
  limite dichiarato. I worker ripetono lavoro numerico su buffer privati oppure
  attendono un semaforo: non sono il motore ArcDocDB e non accedono al payload.
  Non si dichiara zero allocazione per i worker: si riporta l'allocazione
  misurata del processo nella finestra, inclusa quella dello strumento. Il tasso
  zero richiesto riguarda l'iniezione di payload; i rimpiazzi sono separati.
- Campagna sequenziale con 1, 16 e 64 worker; 256 è opzionale. Il report include
  anche il numero di thread del processo al completamento della barriera ready.
  Per ogni layout:
  tre tassi con worker attivi e tasso zero con worker in attesa. Le configurazioni
  escluse sono dichiarate: non è una matrice fattoriale completa.
- Avvio con stato protetto da mutex, semafori ready/start e conferma running;
  arresto cooperativo, risveglio dei worker e join di tutti i thread anche nei
  percorsi di errore. Gli errori dei worker sono conservati e propagati.
- Dopo il riscaldamento si misurano separatamente collection richieste con
  `(sb-ext:gc :gen 0)` e `(sb-ext:gc :full t)`, poi una finestra con GC automatico.
  `:gen 0` può raccogliere anche generazioni più vecchie. Si conserva e ripristina
  `sb-ext:bytes-consed-between-gcs`.
- Campioni in vettori preallocati, nessuna lista di campioni nel percorso
  misurato. P50/P99 usano nearest rank: elemento ordinato in posizione
  `ceil(p * count)`, contando da 1. I vettori pieni riportano campioni scartati;
  i quantili descrivono il prefisso conservato; il massimo include anche i
  campioni scartati. I worker conservano 256 latenze/ritardi ciascuno: un buffer
  saturo può dare quantili poco rappresentativi della fase finale. Nessun campione significa valori
  `nil`, non zero. Nessuna stima di P99.9 da questa campagna breve.

## Che cosa viene misurato

`sb-ext:*gc-real-time*` è il tempo reale cumulativo di collection del runtime.
Si misurano i delta, senza azzerare o legare dinamicamente il contatore. Le
letture vengono ripetute se cambia l'epoca fra la prima e l'ultima lettura;
32 tentativi senza un'istantanea coerente segnalano un errore. Il tempo
wall intorno a `gc` include chiamata, coordinamento e altro lavoro del runtime;
non è la durata dello stop di tutti i thread. Il codice SBCL 2.6.9 aggiorna il
contatore nella fase di collection dopo l'arresto del mondo: i delta **non**
misurano l'intero protocollo stop/resume. I report distinguono esplicitamente
`:forced-gc` e `:automatic-gc`, con `:exact-stop-world-time nil`.
[Manuale SBCL](https://www.sbcl.org/manual/#Introspection-and-Tuning),
[implementazione SBCL 2.6.9](https://github.com/sbcl/sbcl/blob/sbcl-2.6.9/src/code/gc.lisp).

Per rilevare anche collection con delta zero si cerca per introspezione
`SB-KERNEL::*GC-EPOCH*`. È un'interfaccia interna: lo spike dichiara la capacità
rilevata e rifiuta la misura se manca. Un cambio d'identità fra due osservazioni
rileva **una o più** collection: non fornisce il loro numero esatto. I quantili
automatici sono quindi **delta cumulativi per finestra con collection**, non
una distribuzione garantita delle singole pause. Collection durante uscita dei
thread e preparazione sono escluse dalle finestre della campagna.

I ritardi tra richieste dei worker e le loro latenze comprendono scheduling e
contesa CPU; non si attribuiscono interamente al GC. Il costo dell'orologio,
della lettura dei contatori e della registrazione è misurato separatamente come
overhead del benchmark; non viene sottratto dai campioni di GC. Si riportano
anche tempo totale di collection nella finestra e frequenza minima delle
finestre osservate, senza inventare il numero di collection.

## Limiti e risorse

> **Proposta** — Default: budget cooperativo di 12 secondi per la campagna,
> finestre automatiche da 80 ms, tre campioni per ciascun GC forzato, nursery
> richiesta da 4 MiB. Si mira a circa 15 secondi includendo preparazione/check,
> con payload vivo inferiore a 1 GiB. Si interrompe l'avvio di nuovi casi al
> budget; una collection o il join già iniziati possono superarlo. La durata
> effettiva, i casi omessi e quelli troncati sono riportati, non garantiti dal tempo.

Il payload configurabile è limitato a 512 MiB. Campioni, anello transitorio e
numero di rimpiazzi sono limitati. Questo è un limite dei dati dello spike,
non una misura di RSS: runtime, stack, pagine del collector e allocator foreign
richiedono memoria aggiuntiva. Il controller serializza l'iniezione del carico
e la misura. Il mutex del gruppo serializza le transizioni di stato, la lettura
degli errori e il polling stop dei worker fra batch: può influenzare i ritardi
di scheduling e non è incluso interamente nella baseline del solo controller.
Questo protocollo del harness non introduce lock fra Serie nel prodotto (INV-P6).

Le dimensioni ridotte non rappresentano gli heap da decine di GB previsti dal
piano originale. Attendere un semaforo non riproduce ogni chiamata di I/O.
Tre campioni forzati e finestre brevi servono a diagnosticare lo strumento;
servono campagne dedicate per valutare le code della distribuzione. Su macOS
nessuna conclusione è trasferita all'hardware Linux di riferimento.

## Ambiente e comandi

L'output registra versione SBCL, sistema operativo, macchina, feature del
collector, risoluzione dell'orologio, spazio dinamico e nursery effettiva.
Per riproducibilità si annotano anche hardware, RAM, carico esterno
e comando; le misure si eseguono in serie.

```sh
# Solo verifica deterministica, piccola e rapida.
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-02-gc/run.lisp --check

# Campagna predefinita: include check; da eseguire in serie.
sbcl --noinform --no-userinit --no-sysinit --dynamic-space-size 768 \
  --script spikes/SPK-02-gc/run.lisp --bench

# Diagnostica breve, payload piccolo, un worker.
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-02-gc/run.lisp \
  --bench --live-mib=2 --threads=1 --budget-ms=1000 --case-ms=10 --forced-samples=1

# Esempio di personalizzazione Lisp dopo aver caricato core.fasl.
# (arcdocdb.spk02:benchmark :live-bytes (* 256 1024 1024)
#   :thread-counts '(1 16 64 256) :budget-seconds 12 :case-seconds 0.08d0)
```

`run.lisp` risolve `core.lisp` rispetto a `*load-truename*`, compila
`out/core.fasl` con warning/style-warning fatali e scrive una sola plist
s-expression leggibile. Errori: plist `:status :error` e exit code non nullo.
Gli artefatti locali in `out/` sono ignorati da Git.

## Risultato

README scritto prima dell'esecuzione. Il 2026-10-08, su SBCL 2.6.9,
Darwin/ARM64, `--check` è passato con compilazione priva di warning e
style-warning. Le fixture verificano quantili/overflow, contenuto e rimpiazzo
degli array, conservazione attraverso GC, rilascio foreign su errore, barriere,
arresto/join, propagazione degli errori worker e distinzione dei contatori.
Il runner è stato eseguito anche da `/tmp` con percorso assoluto.

La sola diagnostica breve è stata eseguita con `--bench --live-mib=2
--threads=1 --budget-ms=1000 --case-ms=10 --forced-samples=1`:
16 casi completati sui quattro layout, tutti i worker joined, una sola plist
leggibile su stdout. Il contatore interno `:actual-wall-ms` della campagna ha
misurato **265.231 ms**; questa durata comprende preparazione e misura della
campagna, esclude compilazione, check e stampa finale. Sono state osservate
quattro finestre con GC automatico: non si deduce il numero esatto di collection.
Output locale: `out/diagnostic.sexp`. Questo risultato verifica il percorso
del harness con input piccoli; non è una misura sull'hardware di riferimento.

La campagna predefinita da 128 MiB, i profili con 16/64 worker e il profilo
opzionale con 256 worker non sono stati misurati in questa diagnostica.
Le misure si eseguono in serie. Durata e memoria effettive del default non sono
quindi verificate; il budget e i limiti descritti sopra sono parametri.

Non è stato dimostrato un bug architetturale. Resta un limite della verifica
di ADR-0024/0045: i delta del contatore di collection e la durata di `:forced-gc`
non bastano a certificare la pausa completa stop/resume né il criterio P99.9
di ADR-0028. Occorrono ulteriori misure sull'ambiente previsto.

Requisiti collegati: REQ-SIM-001, REQ-SIM-002, REQ-OBS-001, REQ-BEN-001,
REQ-BEN-002, REQ-AFF-003, REQ-AFF-008 e REQ-AFF-016. Nessuna modifica di
requisito o di documenti in `docs/`; l'aggiornamento di tracciabilità e valutazione
rientra nella fase di integrazione.
