# Prima campagna locale — 2026-10-08

[Valutazione](README.md) · [Esperimenti](../../spikes/README.md) · [Roadmap](../roadmap.md)

Misure di esperimenti **v1**, non del motore completo né del formato v2 di
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
> dell'agente, ma non le annulla. Repliche con heap equivalente e scala maggiore
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
Il primo campione dell'agente con hash inline aveva inoltre osservato uno
split da 17,171 ms con heap diverso: resta nel suo README.

> **Proposta** — l'allocazione per GET è ridotta da circa 152 a 48 B/op nel
> campione equivalente a 100.000 documenti. Prima del motore occorre isolare
> le allocazioni del kernel da quelle dell'harness e profilare le manutenzioni.
> La scala locale 10⁷ è ora osservata; 10⁸, ARM64/x86-64, memoria debole,
> churn prolungato, indice v2 e piattaforma Linux restano aperti.

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

## Decisione operativa

> **Proposta** — conservare gli esperimenti e le ottimizzazioni misurate;
> completare gate v2, modelli mancanti e campagna Linux prima del motore C1.
> Per il prossimo lavoro: scala e allocazioni dell'indice, pool con carico
> realistico, resolver prepared e I/O con pipeline reale. Affidabilità e
> verificabilità restano superiori al throughput, secondo ADR-0031.
