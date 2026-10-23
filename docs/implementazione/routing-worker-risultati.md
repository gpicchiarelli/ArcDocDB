# Risultati locali del routing worker/Serie

Campagna del 2026-10-11, SBCL2.6.9/macOS ARM64 AppleM4, safety3.
Il [metodo preregistrato](routing-worker-metodo.md), la
[revisione in due letture](routing-worker-revisione.md) e
[l'inventario](routing-worker-decisioni.md) delimitano la fondazione.
Dati canonici in [`2026-10-11-worker-routing`](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-worker-routing/).
Nessuna esclusione o deviazione nuova è approvata.

Le prove mirate, la copertura e la misura sono congelate sulla base
`92decf4265554cd4959e32a1c881cf00758bb6a1`. La successiva integrazione
comprende `d155db3f977677fa95280f59c23fbe46a5e116d2`: nuove stringhe CBOR,
resolver GET e prove associate, senza modificare execution/Series o i loro
contratti. ASDF, indice e changelog mantengono entrambe le aggiunte.
I dati della prima base restano distinti dal controllo generale integrato;
nessuna misura viene reinterpretata come qualifica dei componenti successivi.

| Processo | Esito letto |
|---|---|
| `4000711896-command-71058-0` / target v1 | Fallito, STABLE/exit1: comparatore ricorsivo della fixture su65537 slot esaurisce lo stack. Prodotto compilato senza avvisi; sorgenti v1 e raw conservati. |
| `4000711978-command-74703-0` / C4 v1 | OK/STABLE/exit0, stderr0: COMPILE-FILE integrale con ogni warning/style-warning fatale, caricamento FASL e self-test. Il comparatore del test non è eseguito dal sensore. |
| `4000712082-command-76603-0` / target v2 | OK/STABLE/exit0:18 test dedicati, inclusi preimage iterativa, health FAULTED, shape FI, due Serie ACTIVE e RW-REV-01 su entrambi i helper. |
| `4000712082-command-76602-0` / copertura v2 | OK/STABLE/exit0: suite Series ed execution nello stesso processo, raw nativo e27HTML conservati (26 sorgenti più indice). |
| `4000712247-command-79840-0` / audit copertura | OK/STABLE/exit0: reader C4 integralmente compilato senza avvisi, self-test FASL positivi/negativi, identità e conteggi nativi confrontati con l'HTML effettivo. |
| `4000712105-command-77187-0` / misura v2 | OK/STABLE/exit0:5×4096 cicli completi, due writer alternati, sensori e sorgenti stabili. |

## Copertura con denominatore completo

| Scope | Espressioni eseguite/totali | Esiti branch eseguiti/totali | Mancanti espressioni / branch |
|---|---|---|---|
| Execution,11 file interi |1470/1676|201/234|206/33|
| Series,15 file interi |1780/2090|235/292|310/57|
| Unione26 file |3250/3766|436/526|516/90|
| Tre file routing nuovi |267/291|40/42|24/2|
| Handoff writer intero |189/206|18/20|17/2|

`coverage-audit.lisp` conserva tutte le identità native mancanti, indice,
kind e path, e tutti i conteggi per file. `coverage-bundle.lisp` conserva
entrambi i raw nativi originali e tutti gli HTML, compressi senza perdita.
I file interi, compresi package e verificatori difensivi, restano nel
denominatore. La decisione composta H01 è letta separatamente con input
VF/FV/FF e cortocircuito esplicito; non si inferisce MC/DC da sb-cover.
Copertura parziale e prove locali non chiudono il gate C1 del motore.

## Allocazione e sensori

| Replica | Cicli dopo128 warmup | Heap osservato, byte | Tick raw | Sink indipendente |
|---|---|---|---|---|
|0|4096|0|6792|8972288|
|1|4096|0|6802|8972288|
|2|4096|0|6814|8972288|
|3|4096|0|6820|8972288|
|4|4096|0|6815|8972288|

Timer1000000 unità/s. Sink `4096*143+4096*4095/2=8972288`;
143/ciclo è fissato nel driver prima delle campagne, indipendentemente
dalle API. Ogni ciclo verifica enqueue, publish, claim, lookup ripetuto,
identità/ordinali, doppia lease, span/payload, ack e fine IDLE. Tutti gli
oggetti e le API sono preallocati o risolti prima del sensore; GC e stampa
sono fuori misura. I token bridge/Serie crescono per writer, batch per worker.

Il controllo positivo16×1MiB rileva16777472 byte; baseline zero, sink
errato, CLI invalida, destinazione precedente, clock nullo e misura
interrotta sono rilevati dai self-test. La misura interrotta conserva
cicli completati, tick7, heap e sink, senza inventare dati dopo l'errore.
La sola eccezione runtime ASDF riguarda `sb-kernel:redefinition-warning`
come nel build; il COMPILE-FILE del C4 non esclude avvisi.

La fixture mock I/O è usata soltanto all'avvio. Queste sono misure seriali
locali del percorso riuscito, con carico esterno non controllato: non
qualificano heap nullo universale, fairness, throughput, P99, scalabilità,
pool, dispositivo, fault cleanup o durata delle Serie. Registro e tabelle
restano configurazione statica O(N) per worker, senza inserimenti/retirement.

## Controllo generale integrato

Il processo `4000712542-command-86913-0` è OK/STABLE/exit0 sulla base
integrata d155, con673 sorgenti/documenti invariati:835 test nominati,
2smoke e21suite, incluse88 prove Series. Nessun warning/style-warning;
i370114 byte stderr sono note di compilazione e restano integri.
Durata complessiva182.076021s, che include tutti i controlli e non è una
misura del percorso caldo. Linter, tracciabilità, link, evidenze e self-test
passano. La cache FASL è privata nello snapshot; il recorder conserva
l'argv effettivo `env ASDF_OUTPUT_TRANSLATIONS=… make check-core`, lo stesso
core richiamato da `make check`.

Il master F0 `4000712691-check-90489-0` è COMPLETE:10 esperimenti,
ciascuno STABLE/exit0/stderr0; SPK07 PASS, gli altri OK. I raw completi
sono nel catalogo distinto `2026-10-11-worker-routing-spikes-check`.
Le prove dei runner snapshot/reader sono PASSED con due rifiuti attesi
ciascuna (SIGKILL9/exit137 e completionexit7). I14 file originali, inclusi
runner/stdout/stderr, sono conservati nel bundle ausiliario; fallimenti
iniettati non diventano failure del prodotto.

La pubblicazione iniziale `4000712318-command-81618-0` ha verificato le
copie e completato il catalogo, ma il recorder dichiara SOURCE-CHANGED:
mentre scriveva i raw, il root ha creato questo documento e aggiornato i
link del contratto. Gli altri sourceblob sono invariati. Il tentativo
resta conservato come non-PASS. La rilettura indipendente dei byte
`4000712554-command-87125-0` è OK/STABLE/exit0/stderr0.

Il byteproof ausiliario `4000712842-command-93594-0` è OK/exit0:
16 file (14 raw originali e2runner di orchestrazione) sono confrontati
byte per byte dopo reencoding UTF-8 e SHA256. Una prima utility ignored
aveva una parentesi mancante ed è fallita prima del corpo; il suo sorgente
rimane conservato ma il raw originario non era registrato. Il replay
identico `4000712876-command-94086-0` è un nuovo probe FAILED/exit1, con
stdout/stderr conservati: non sostituisce il raw mancante e non è un gate
C4 o un fallimento del prodotto.

## Integrazione successiva della cache e delle prove GET

Prima della pubblicazione main avanza a
`6eeb501d2eace49fad8e2ec333ed0c6c1386dd6c`. Il delta aggiunge la suite
GET-performance e fa saltare al lookup cache i posti disabled/rejected
entro gli otto way. Execution, Series, bridge, routing, fixture dedicate e
C4 di misura sono invariati. ASDF e indice sono composti con preimage
originali conservate; lo scope Series/execution del reader di copertura
rimane invariato. Le misure sulla base92 restano storiche.

Il nuovo congelamento generale passa nel processo
`4000713646-command-11645-0`: OK/STABLE/exit0,683 sorgenti/documenti,
854 test nominati più2smoke,22suite, comprese le19 nuove prove GET.
Durata185.668746s; nessun warning/style-warning,407320 byte stderr
originali conservati. Il master `4000713800-check-18712-0` è COMPLETE,
con10 run STABLE/exit0/stderr0. I raw del master restano separati dal
precedente nella sottodirectory `2026-10-11-worker-routing-spikes-check/latest`.
I self-test snapshot e reader sono PASSED, inclusi due rifiuti OS attesi
per ciascuno. Proiezione, sorgenti dei lettori e byteproof rimangono distinti
dalla campagna C4 e dal primo congelamento d155.

## Composizione finale con GET ACTIVE

L'ultimo avanzamento `be9d2dd6816f8c999fcab383702c7a133c061902`
aggiunge sei unità ACTIVE nel resolver e relativa documentazione.
Non cambia execution, Series, routing, fixture dedicate, strumenti o
suite esistenti. ASDF carica le nuove unità dopo il resolver CLOSED;
indice e changelog conservano entrambe le aggiunte, con preimage originali.

La tree combinata è verificata dal processo
`4000714586-command-55084-0`: `make build`, OK/STABLE/exit0,
690 sorgenti/documenti,854 test nominati e2smoke, senza avvisi.
Il controllo usa una cache FASL privata e dura circa20,36s. Queste prove
esercitano la suite esistente; non qualificano le nuove API ACTIVE o
le loro allocazioni. F0, copertura e misure mantengono i congelamenti
precedenti: non vengono ripetuti o reinterpretati per questo delta.

I sorgenti del routing, le fixture dedicate e il C4 qualificati restano
invariati. La configurazione ASDF composta è verificata dal nuovo build. Requisiti
globali restano `progettato`, Fase0 e qualifica del motore rimangono aperte.

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
