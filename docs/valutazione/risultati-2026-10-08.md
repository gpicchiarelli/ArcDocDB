# Prima campagna locale — 2026-10-08

[Valutazione](README.md) · [Esperimenti](../../spikes/README.md) · [Roadmap](../roadmap.md)

Misure di esperimenti **v1** e della successiva campagna **v2**, tenute distinte;
non sono misure del motore completo. Il formato v2 segue
[ADR-0048](../adr/0048-limiti-documentali-e-formato-v2.md). I requisiti del
motore restano progettati. Nessuna cifra seguente conferma i minimi di ADR-0028.

## Riproducibilità

Apple M4, ARM64, 10 CPU logiche, 16 GiB RAM, Darwin 27.0.0, SBCL 2.6.9 GENCGC.
Filesystem del workspace APFS, disco interno. Clock wall: 1.000.000 tick/s.
Heap dei processi figli: 4.096 MiB. Ogni spike compila senza warning né
style-warning; `safety` 3, salvo i kernel CRC distinti a `safety` 2/3.

```sh
make check
make spikes-bench
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-09
```

L'harness esegue i processi **in serie**. Il workspace è una macchina di
sviluppo: carico esterno non controllato, `vm.loadavg` osservato all'avvio
`{4.60 3.77 3.12}`, frequenza CPU e temperatura non registrate. Una campagna
iniziale, non una distribuzione di repliche. I figli disabilitano le
inizializzazioni utente e di sistema; comandi, revisione e modifiche locali
sono nei report. I nuovi report aggiungono i blob Git dei sorgenti.

Dati grezzi conservati, leggibili con `*read-eval* nil`:

- [Campagna iniziale](../../spikes/results/2026-10-08/baseline.lisp), dalla
  directory locale `4000472823-bench`, revisione `7301991` con modifiche dichiarate.
- [Verificatore inline](../../spikes/results/2026-10-08/crc-inline.lisp), dalla
  directory locale `4000472979-bench`, stessi parametri CRC.
- [Indice inline, 100.000 documenti](../../spikes/results/2026-10-08/index-inline-100k.lisp),
  directory `4000473749-bench`, parametri predefiniti e blob dei sorgenti.
- [Indice inline, 10 milioni](../../spikes/results/2026-10-08/index-inline-10m.lisp),
  directory `4000473801-bench`, comando riportato sotto e blob dei sorgenti.
- [Controlli integrati v2](../../spikes/results/2026-10-08/v2-integration-check.lisp),
  directory `4000475177-check-53215-0`; risultato decodificato e blob prima/dopo.
- [Prima campagna v2](../../spikes/results/2026-10-08/v2-bench-initial.lisp),
  directory `4000475258-bench-54418-0`; tre moduli misurati in serie.

I report precedenti al campo `:result` hanno importazioni strutturate separate:
[baseline](../../spikes/results/2026-10-08/baseline-structured.lisp),
[CRC inline](../../spikes/results/2026-10-08/crc-inline-structured.lisp),
[indice 100k](../../spikes/results/2026-10-08/index-inline-100k-structured.lisp),
[indice 10M](../../spikes/results/2026-10-08/index-inline-10m-structured.lisp).
Conservano ambiente e output originali; non inventano metadata mancanti.

Ogni file conserva stdout/stderr originali e comandi. La revisione è precedente
alle ottimizzazioni descritte: l'albero modificato è esplicito, non si attribuisce
la campagna a un checkout pulito. Le varianti sono documentate nei README degli spike.

## SPK-01 — indice primario

Prima campagna: 100.000 documenti, chiavi di 16 byte, frammenti da 8.192 slot,
quattro parole, due reader. Lookup scalare per gruppi; hash, generazione della
chiave e controllo della risposta sono inclusi. Nessuna lettura del segmento.

| Fase iniziale | Operazioni | Operazioni/s | Byte allocati/op, processo |
|---|---:|---:|---:|
| INSERT | 100.000 | 1.657.275 | 551,75 |
| GET | 800.000 | 2.915.048 | 151,95 |
| Ricambio, DELETE + INSERT | 100.000 | 1.604.518 | 428,15 |
| GET concorrenti sulla stessa chiave | 2.000.000 | 8.212.372 | 129,76 |

Il payload degli array vivi è **6.422.656 byte, 64,22656 byte/documento**,
prima e dopo 50.000 sostituzioni di chiave. Sono esclusi header Lisp, runtime,
garbage e frammenti trattenuti dai reader. 15 split, 16 rebuild; massimo split
1,613 ms e rebuild 1,453 ms nel campione. La directory copia complessivamente
426 riferimenti, al massimo 16 per manutenzione. Questa scala piccola non
verifica il suo costo massimo, precisato da [ADR-0050](../adr/0050-pubblicazione-e-costi-della-directory.md).

Nello stress concorrente: 200.000 update del writer, 74.888 tentativi scartati,
42 ripieghi al mutex del solo harness. Non è il pool di produzione. Il workload
su una sola chiave calda non rappresenta lookup casuali su un archivio grande.

> **Proposta** — ridurre il boxing dei passaggi interni, conservando hash e
> fixture. Il primo inlining del solo hash riduce le allocazioni nella diagnostica
> locale, ma non le annulla. Repliche con heap equivalente e scala maggiore
> devono precedere una conclusione sul throughput.

### Inlining e scala 10⁷

L'esperimento successivo include anche gli helper del reader e della chiave,
con tipi u64 espliciti. Hash e golden restano gli stessi; `safety 3` e API
autonoma. Campioni distinti, medesimo heap di 4 GiB:

| Fase | 100.000 documenti, operazioni/s | Byte allocati/op | 10 milioni, operazioni/s | Byte allocati/op |
|---|---:|---:|---:|---:|
| INSERT | 2.817.616 | 171,09 | 1.650.123 | 225,83 |
| GET | 3.556.994 | 47,99 | 2.097.987 | 48,00 |

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp \
  --bench SPK-01 -- --documents 10000000 --seconds 60 --memory-mib 2048
```

I 10 milioni di INSERT sono completati; GET: 75.400.960 operazioni, fermati
dal budget della fase prima del tetto di 80 milioni. La campagna misura
42,214258 secondi. Il payload vivo è **822.099.968 byte, 82,2099968 B/doc**,
prima e dopo 50.000 sostituzioni. 2.048 frammenti, profondità 11, 2.047 split,
nessun rebuild in questo ricambio breve. 234.766.336 byte di chiavi copiati;
2.796.202 riferimenti di directory copiati, al massimo 2.048 per manutenzione.

Massimo split **98,827 ms**, contro 1,030 ms nel campione inline da 100.000
documenti; massimo tempo di copia della directory 0,025 ms. Tempo di copia
del frammento comprende allocazione, scheduler e possibili GC. La causa del
massimo non è stata profilata: **non** si attribuisce al collector per deduzione.
Le allocazioni residue includono harness e boxing; non si promette zero.
Il primo campione locale con hash inline aveva inoltre osservato uno
split da 17,171 ms con heap diverso: resta nel suo README.

> **Proposta** — l'allocazione per GET è ridotta da circa 152 a 48 B/op nel
> campione equivalente a 100.000 documenti. Prima del motore occorre isolare
> ulteriormente le allocazioni del reader e profilare le manutenzioni.
> La scala locale 10⁷ è ora osservata; 10⁸, ARM64/x86-64, memoria debole,
> churn prolungato, indice v2 e piattaforma Linux restano aperti.

### Diagnostica di allocazione

[Profilo speed 2](../../spikes/results/2026-10-08/profile-speed2.lisp) e
[profilo speed 3](../../spikes/results/2026-10-08/profile-speed3.lisp): tre finestre
di 1.000.000 operazioni, precedute ciascuna da 10.000 warmup e full GC fuori
dalla finestra. Una chiave fissa, riuso del buffer, frammento da 8.192 slot.

| Finestra | Allocazioni osservate, speed 2 | Allocazioni osservate, speed 3 |
|---|---:|---:|
| Generazione chiave nel buffer riusato | 0 byte | 0 byte |
| Hash e scrittura diretta in array u64 | 0 byte | 0 byte |
| API `leggi`, chiave fissa | 47.960.640 byte | 47.960.640 byte |

Il residuo di circa **47,96 B/lookup** è quindi osservato anche chiamando
l'API su chiave fissa, senza attribuirlo interamente alla generazione delle
chiavi nel benchmark. Non è ancora isolata la singola istruzione responsabile.
La variante `speed 3` del reader non ha ridotto il residuo ed è stata ritirata;
`safety 3` in entrambe. Un campione non prova allocazione zero universale.

Il primo tentativo del nuovo runner di profiling aveva una parentesi in eccesso:
[campagna fallita](../../spikes/results/2026-10-08/profile-compile-failed.lisp) e
[diagnostica del processo](../../spikes/results/2026-10-08/profile-compile-failed-process.lisp)
sono conservate. La correzione e le esecuzioni riuscite non cancellano il fallimento.

## SPK-02 — GC

48/48 casi completati in 6.953,525 ms: 128 MiB vivi, quattro layout, worker
1/16/64, tre tassi richiesti di allocazione e confronto con worker parcheggiati.
Tre richieste di collection per tipo e caso; finestra automatica di 80 ms.

Massimi del **tempo wall della chiamata `gc`**, tra i profili di ciascuna riga:

| Layout | Worker | Gen 0, ms | Full, ms |
|---|---:|---:|---:|
| Array grande | 1 | 0,993 | 4,787 |
| Array grande | 16 | 16,013 | 15,485 |
| Array grande | 64 | 197,966 | 36,013 |
| Frammenti | 1 | 1,050 | 5,122 |
| Frammenti | 16 | 2,023 | 5,581 |
| Frammenti | 64 | 61,359 | 52,297 |
| Frammenti sostituiti | 1 | 1,190 | 5,403 |
| Frammenti sostituiti | 16 | 4,666 | 28,302 |
| Frammenti sostituiti | 64 | 32,340 | 13,040 |
| Foreign | 1 | 0,928 | 5,365 |
| Foreign | 16 | 2,507 | 7,361 |
| Foreign | 64 | 40,695 | 81,843 |

Il tempo include coordinamento e scheduling; **non** è la misura esatta dello
stop/resume di tutti i thread. I delta del contatore runtime sono separati nei
report. Le finestre automatiche possono aggregare più collection o non
osservarne alcuna: campioni assenti non sono pause nulle. Con 64 worker su 10
CPU si esercita anche la contesa per le risorse di calcolo.

> **Proposta** — misurare il pool reale distinguendo worker attivi, parcheggiati
> e bloccati in I/O. Il passaggio alla memoria foreign da solo non risolve i
> costi osservati. Heap da decine di GB, più campioni e Linux restano necessari
> per giudicare l'obiettivo GC; questa campagna non certifica P99 o P99.9.

## SPK-03 — append e flush

12/12 casi, record di 2.048 byte, lotti 1/32/128, file 1/4, 16 flush misurati
per file oltre al warmup. Ogni octet è verificato dopo riapertura; cleanup limitato
ai file creati. Nessun errore o fallback di primitiva.

| File | Record/lotto | F_FULLFSYNC, mediana ms | Record/s sincronizzati |
|---|---:|---:|---:|
| 1 | 1 | 3,971 | 249,7 |
| 1 | 32 | 3,981 | 7.800,1 |
| 1 | 128 | 3,852 | 32.034,0 |
| 4 | 1 | 11,800 | 279,4 |
| 4 | 32 | 11,747 | 9.800,8 |
| 4 | 128 | 11,818 | 39.593,8 |

Il throughput copre il solo intervallo I/O, non formazione del lotto, protocollo
SEAL, rete o latenza client. `fsync` ordinario è riportato separatamente: sul
Mac non soddisfa il contratto richiesto, perciò il suo throughput non è usato
come throughput durevole. Per un file/lotto da un record la mediana `fsync`
è 0,032 ms contro 3,971 ms di `F_FULLFSYNC`: il confronto cambia il contratto.

> **Proposta** — mantenere group commit e serialità di append/flush per file;
> misurare concorrenza, lotti formati durante il flush e code sul dispositivo
> Linux di riferimento. Riapertura e syscall completata non provano la
> persistenza dopo perdita di alimentazione. Sedici campioni non descrivono P99.

## SPK-07 — protocolli

Esplorazione deterministica di configurazioni finite, con controlli negativi.
Modelli corretti: orizzonte 43 stati/72 transizioni; multiserie 59/114;
EDIT/reclaim 19/28; seqlock 127/164; registrazione snapshot 28/34. Enumerazioni:
85 combinazioni di persistenza, due corruzioni testimoniate, 2.256 casi di
compaction/ricostruzione, 25 di riconciliazione/recovery.

Il controesempio dell'anello è corretto da ADR-0046; i mutanti di forget precoce,
reclaim con riferimenti, seqlock non validato e soglia snapshot omessa sono
rilevati. Restano pubblicazione dei frammenti, memoria debole, scadenza snapshot,
crash sui byte reali e compaction con writer attivo. Non è copertura FI-01…FI-13
su un motore esistente.

## SPK-09 — integrità e ottimizzazione

23.370 confronti CRC; corruzioni e troncamenti di PUT e OUTCOME rifiutati nei
casi dichiarati. `verify-prepared-record` confronta TXID e CSN con OUTCOME
verificato, secondo ADR-0047; provenienza, SEAL e resolver del manifest restano
da implementare.

CRC slicing-by-8 a `safety 3`, campagna iniziale:

| Byte coperti | ns/operazione | MB/s decimali |
|---|---:|---:|
| 20, header | 38,354 | 521,5 |
| 128 | 175,420 | 729,7 |
| 2.048 | 2.894,889 | 707,5 |
| 16.384 | 23.317,339 | 702,7 |

L'inlining di verificatore e accumulatore evita il passaggio del CSN come
oggetto Lisp intermedio. Stessi byte, fixture e controlli, `safety 3`:

| Corpo / CSN | Prima, ns/op | Inline, ns/op | Prima, byte allocati/op | Inline, byte allocati/op |
|---|---:|---:|---:|---:|
| 20 / 17 | 127,121 | 116,410 | 0 osservati | 0 osservati |
| 20 / 2⁶⁴−1 | 132,790 | 116,245 | 32,054 | 0 osservati |
| 2.048 / 17 | 4.954,069 | 4.942,166 | 0 osservati | 0 osservati |
| 2.048 / 2⁶⁴−1 | 5.102,767 | 4.946,888 | 31,864 | 0 osservati |

È una singola coppia di esecuzioni, con ordine fisso dei casi. Non si deduce
una garanzia di allocazione zero per ogni API: il parser pubblico che restituisce
un u64 può ancora richiedere boxing. Il contatore di allocazione ha granularità
e misura il processo; anche tempi e confronti sono soggetti al rumore dichiarato.

## SPK-10 — limiti v2 e integrazione

Strict compile senza warning/style-warning, `safety 3`. Copertura della
[verifica integrata](../../spikes/results/2026-10-08/v2-integration-check.lisp):

| Ambito | Esito locale e quantità |
|---|---|
| Codec v1/v2 | 416 casi; documenti 16 MiB e record massimo 16.842.775 byte |
| Indice v2 | 8 gruppi, 600 operazioni differenziali, 664 confronti con oracle; 7 snapshot di rifiuti per budget |
| CBOR iterativo | 614 casi; profondità 100/101, 16 MiB/+1, nodi e byte; chiavi/valori delle mappe attraversati |
| Fileheader | 8 accettati e 2.393 rifiutati; parser non selezionato su header invalidi |
| Migrazione su modello | 208 crash, 4.160 interruzioni recovery, 208 rerun; 3/3 mutanti rilevati; massimo 22/32 passi |
| Collegamento dei cinque componenti | 16 combinazioni positive, 1 negativa, 113 asserzioni; chiavi 1/255/256/65.535 byte, profondità 100 e documento di 16 MiB |

La fixture negativa ha entrambi i CRC validi ma CBOR non minimo: supera il
codec e viene rifiutata dal validatore. I dati dei moduli includono anche i
tentativi locali: [codec](../../spikes/results/2026-10-08/v2-codec-check.lisp),
[indice](../../spikes/results/2026-10-08/v2-indice-check.lisp),
[CBOR](../../spikes/results/2026-10-08/v2-cbor-check.lisp),
[migrazione](../../spikes/results/2026-10-08/v2-migrazione-check.lisp).

La [prima campagna v2](../../spikes/results/2026-10-08/v2-bench-initial.lisp)
termina in 6,127524 s, inclusi compilazione e controlli. Codec: 283.430
verifiche di record da 41 byte in una finestra di 0,25 s; non è il costo
del record massimo. Indice, carichi distinti senza split:

| Chiave, byte | Documenti | Operazioni, comprese modifiche | Finestra, ms | Payload finale, byte | Picco transitorio, byte |
|---:|---:|---:|---:|---:|---:|
| 16 | 10.000 | 30.128 | 12,003 | 933.896 | 1.064.984 |
| 256 | 1.000 | 3.128 | 2,962 | 608.264 | 870.664 |
| 65.535 | 64 | 320 | 60,336 | 4.199.560 | 12.658.959 |

Con chiavi massime il carico esercita un rebuild: 128 slot visitati, 63 entry
copiate, 4.325.310 byte copiati nella manutenzione massima, tempo massimo
di preparazione 8,357 ms. Memoria contata come payload degli array, esclusi
header, runtime e root ritirate; il budget temporale è cooperativo. Nessun
confronto di throughput tra carichi di dimensioni diverse è dedotto dalla tabella.

Il primo validatore CBOR alloca circa **7.742 B/chiamata** anche su scalar:
prealloca 100 frame della pila. I campioni testuali richiedono validazione UTF-8:
testo codificato 1 KiB, 68.274 operazioni in 0,416670 s; 64 KiB, 1.425 in
0,416874 s. Le bytestring verificano lunghezza e saltano il payload: i valori
`:encoded-mib-per-second`, soprattutto a 16 MiB, **non sono banda di lettura,
CRC o scansione**. L'allocazione della pila è oggetto di una variante successiva,
con risultati conservati separatamente.

### CBOR con pila creata su richiesta

La variante successiva conserva i 614 casi e aggiunge 15 fixture sul numero
di frame realmente creati: **629 casi**; [controlli registrati](../../spikes/results/2026-10-08/v2-cbor-allocation-check.lisp).
Scalari e contenitori vuoti non creano pila; al primo contenitore non vuoto
si crea il vettore limitato a 100 riferimenti e solo i frame necessari, riusati
tra fratelli. Nessuno stato globale o pool condiviso, stessa API e `safety 3`.

[Prima misura della variante](../../spikes/results/2026-10-08/v2-bench-lazy-stack.lisp)
e [replica](../../spikes/results/2026-10-08/v2-bench-lazy-stack-replica.lisp), con
gli stessi sei carichi e limiti; processi terminati in 6,542664 e 5,431828 s,
controlli integrati compresi, blob dei sorgenti invariati nei due snapshot.

| Caso | Prima, byte allocati/chiamata | Variante, prima misura | Variante, replica |
|---|---:|---:|---:|
| Bytestring codificata 1 KiB | 7.742,63 | 528,52 | 528,52 |
| Bytestring codificata 16 MiB | 7.742,05 | 527,42 | 528,08 |
| 4.097 nodi, profondità 1 | 7.743,63 | 1.416,05 | 1.416,04 |
| Profondità 100 | 7.742,71 | 7.679,48 | 7.678,88 |

Circa **93% di riduzione delle allocazioni** nei due carichi binari, senza
dedurne zero allocazioni o una garanzia universale. La profondità 100 richiede
quasi tutti i frame e conserva un costo simile; il miglioramento dipende dal
numero di frame evitabili. Il contatore è del processo e ha granularità.

I tempi UTF-8 sono variabili: testo 1 KiB, 68.274 operazioni iniziali e
28.665/85.716 nelle due misure della variante, ciascuna in circa 0,41667 s;
testo 64 KiB, 1.425 iniziali e 495/1.382 nelle repliche. Il carico esterno
è non controllato (`vm.loadavg` all'avvio 10,08/11,16/10,56 nella campagna
iniziale e 13,98/13,33/11,78 nella prima variante). Non si attribuisce
causalmente la differenza né si dichiara un aumento generale di throughput.
La replica conserva anche la misura più lenta.

I [quozienti delle allocazioni](../../spikes/results/2026-10-08/v2-cbor-allocations.lisp)
sono conservati come dati derivati: byte allocati divisi per operazioni,
con riferimenti e hash dei tre report d'origine. Nessuna nuova misura o
estrapolazione viene aggiunta dal calcolo.

> **Proposta** — questi controlli danno evidenza dei confini rappresentabili e
> del collegamento in memoria. Il gate v2 resta aperto: subset CBOR senza tag,
> float e altri simple; indice con un solo frammento; modello di migrazione senza
> conversione dei byte, filesystem o reader reali; CRC delle sezioni hint e
> prepared esclusi. Occorrono decoder completo, directory/split, memoria debole,
> budget RSS e conversione reale interrotta sulla piattaforma di riferimento.

## Decisione operativa

La [verifica locale completa](../../spikes/results/2026-10-08/full-verification.lisp)
termina con exit code 0 e sorgenti invariati nei due snapshot: build senza
avvisi, due smoke test, linter e controlli negativi del linter, tracciabilità,
link, catalogo delle evidenze e [sei spike](../../spikes/results/2026-10-08/full-spikes-check.lisp).
114 requisiti, 65 invarianti, 13 scenari FI, 51 ADR al momento della verifica.
Sono controlli locali; non si dichiara eseguita la nuova CI Linux/macOS.

> **Proposta** — conservare gli esperimenti e le ottimizzazioni misurate;
> completare gate v2, modelli mancanti e campagna Linux prima del motore C1.
> Per il prossimo lavoro: scala e allocazioni dell'indice, pool con carico
> realistico, resolver prepared e I/O con pipeline reale. Affidabilità e
> verificabilità restano superiori al throughput, secondo ADR-0031.
