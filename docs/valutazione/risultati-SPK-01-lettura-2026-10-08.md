# SPK-01 — lettura in buffer, 2026-10-08

> **Proposta** — Evidenze locali di Fase 0; kernel sperimentale Common Lisp,
> non qualificazione del motore. Layout ADR-0043 v1, quattro parole o cinque
> con CSN finale aggiuntivo; questa quinta parola non è il formato v2.

## Provenienza e contratto

Checkout isolato da `74f0949`, Apple M4 ARM64, 16 GiB, Darwin 27.0.0,
SBCL 2.6.9. Tre agenti hanno sviluppato kernel, CHECK indipendente e consumer
su file disgiunti; il parent integra, profila e misura in serie. Carico esterno
non controllato, clock a 1 µs, heap del processo benchmark 4 GiB.

Il [catalogo](../../spikes/results/2026-10-08-lettura/catalogo.lisp) conserva
anche i fallimenti, sorgenti integrali dei driver, hash prima/dopo, comandi,
stdout/stderr originali e risultati decodificati. I registri sono dati schema1,
letti con `*read-eval*=nil` senza caricare i package dello spike.
Riferimenti: REQ-VAL-001, REQ-AFF-012, REQ-IDX-001, REQ-IDX-007, REQ-BEN-001.
Nessun requisito del motore cambia stato.

`arcdocdb.spk01.lettura-buffer:leggi` riceve un buffer privato simple-array
u64 di quattro parole: CSN, location, length, end-CSN. Restituisce stato e
tentativi scartati. Solo HIT scrive, dopo controllo del seqlock e ricontrollo
root/generazione; miss, retry-limit ed errori sincroni conservano il buffer.
Al massimo otto tentativi; un solo writer per indice, nessun nuovo lock o
stato condiviso fra Serie. I due percorsi, diretto e con callback di fixture,
sono espansioni dello stesso algoritmo. Entrambi mantengono `safety 3`.
La destinazione non è condivisibile durante la chiamata o pubblicata
atomicamente a un altro reader. Callback arbitrari non hanno limite temporale.

Il candidato HIT rappresenta l'intervallo stabile del seqlock; il ricontrollo
della root è il punto di accettazione. Un writer può aggiornare lo slot dopo
la seconda lettura della sequenza: non si attribuisce al payload lo stato
all'istante della successiva rilettura root. Valgono le qualificazioni di
ADR-0050. [Metodo del kernel](../../spikes/SPK-01-primary-index/metodo-lettura-buffer.md)
e [metodo d'integrazione](../../spikes/SPK-01-primary-index/metodo-integrazione-lettura-buffer.md).

## Profilo e diagnosi del residuo

Il [profilo iniziale](../../spikes/results/2026-10-08-lettura/profile-before.lisp)
osserva, su un milione di chiamate e chiave fissa, 47.960.640 byte allocati
dal lookup, cioè 47,96064 B/op. Generazione della chiave e hash in array u64
osservano zero. La
[prima matrice](../../spikes/results/2026-10-08-lettura/benchmark.lisp)
completa 80 campioni: la variante buffer riduce le allocazioni dei campi
u64 alti ma conserva 47,604375 B/op in tutte le celle. Il risultato che
contraddice l'ipotesi di zero allocazione resta pubblicato.

Il validatore generico `intero-limitato` costruisce `(integer minimo massimo)`
a ogni chiamata. La
[diagnostica isolata](../../spikes/results/2026-10-08-lettura/validazione-profilo.lisp)
confronta controlli dinamici e statici su 1.000.000 di valori 1..8, warmup
10.000 separato, sink uguale e rifiuti equivalenti su cinque ingressi invalidi:
il dinamico osserva **47.960.640 byte**, lo statico **zero**. Questa diagnosi
sostiene l'attribuzione del residuo al validatore in questo percorso.

Il kernel buffer usa quindi il tipo letterale `(integer 1 8)` e lo stesso
`type-error`, mantenendo i controlli degli ingressi. Il core del confronto
rimane identico. Il confronto finale riguarda l'intera variante: buffer,
intermedi tipizzati, sondaggio espanso e controllo statico, con `speed 3`
contro `speed 2` del core. Non isola il solo cambio di API.

## Prove funzionali

[Metodo indipendente](../../spikes/SPK-01-primary-index/metodo-check-lettura-buffer.md),
[primo CHECK](../../spikes/results/2026-10-08-lettura/check-indipendente.lisp)
e [CHECK finale](../../spikes/results/2026-10-08-lettura/check-finale.lisp).
Il launcher verifica sempre sia il core sia il buffer; la nuova suite è
compresa in `make check`.

| Controllo | Risultato |
|---|---:|
| Casi principali | 54 |
| Confronti mappa indipendente / kernel / baseline | 2.032 |
| Witness root/seqlock e callback | 18 |
| Budget retry distinti, per entrambe le larghezze | 16 |
| Controlli negativi | 79 |
| Mutanti rilevati con ragione pertinente | 16 |
| Assert finali / tetto | 26.227 / 200.000 |

Il journal viene rigiocato integralmente e confrontato con la mappa attesa;
ogni larghezza esegue 1.024 operazioni seeded, 576 eventi di storia, sei split
e 18 rebuild. La ricerca bounded trova sette chiavi con stessa impronta e
sonda iniziale, includendo il wrap 15→0; visita 11.870 candidati.
Confini: zero, fixnum-max/+1, 2^63, max64, location con due u32 massimi e
length massima a 24 bit. Sono verificati conservazione dell'output, errori
originali dei callback e rifiuti di ingressi/budget. I mutanti eliminano
root/seqlock, troncano u64 oppure scrivono prematuramente nel buffer.

Gli interleaving sono sincroni e deterministici; non sono stress con scheduler
o una prova del modello di memoria hardware. Le compilazioni strict finali
riescono senza warning/style-warning. Sono conservati anche un errore iniziale
di ordine degli argomenti SBCL, un errore sintattico del consumer e una
ridefinizione DEFMACRO rifiutata. Il consumer finale usa MACROLET locale.
Quattro rifiuti CLI attesi sono separati dai CHECK: variante ignota,
opzione duplicata, opzione della matrice estranea, zero operazioni.

## Matrice seriale finale

[Metodo](../../spikes/SPK-01-primary-index/metodo-bench-lettura-buffer.md),
[dati grezzi](../../spikes/results/2026-10-08-lettura/benchmark-finale.lisp)
e [statistiche con sorgente](../../spikes/results/2026-10-08-lettura/statistiche-finali.lisp).

```sh
sbcl --noinform --no-userinit --no-sysinit --script tools/run-spikes.lisp --bench SPK-01 -- --variant buffer
```

4.096 documenti per cella, capacità 8.192, cinque repliche, 128.000 lookup per
campione, 4.096 di warmup per metodo/cella. Otto celle, 40 coppie, 80 campioni,
**10.240.000 lookup misurati**, metà per metodo. Ordine 20 AB / 20 BA.
Un solo indice immutabile serve entrambi i metodi nella coppia; nessun writer
durante la misura. Query, oracle e buffer sono preparati prima dei campioni.
Full GC prima di ogni campione; GC nel ciclo incluso. Il consumatore verifica
quattro campi, hit/miss, retry e checksum, uguali per ogni coppia.

Mediane locali, tempi comprensivi di lookup, oracle, checksum e guardie:

| Parole | Campi | Query | Baseline ns/op | Buffer ns/op | Baseline B/op | Buffer B/op |
|---|---|---|---:|---:|---:|---:|
| 4 | fixnum | hit | 153,16 | 78,09 | 47,60 | 0 |
| 4 | fixnum | hit/miss | 150,28 | 68,70 | 47,60 | 0 |
| 4 | u64 massimi | hit | 171,58 | 79,34 | 111,60 | 0 |
| 4 | u64 massimi | hit/miss | 160,33 | 68,59 | 79,86 | 0 |
| 5 extra-end | fixnum | hit | 153,60 | 78,74 | 47,60 | 0 |
| 5 extra-end | fixnum | hit/miss | 149,36 | 68,43 | 47,60 | 0 |
| 5 extra-end | u64 massimi | hit | 177,30 | 78,75 | 143,86 | 0 |
| 5 extra-end | u64 massimi | hit/miss | 166,08 | 69,23 | 96,24 | 0 |

Tutti i **40 campioni buffer** osservano zero byte consed, anche per valori
oltre fixnum e per miss. Le mediane dei rapporti fra tempi delle singole
coppie vanno da 1,95 a 2,40; intervalli e tutte le repliche rimangono nel
registro, senza significatività statistica dichiarata.

Il controllo positivo pubblica un array u8 in un globale e lo mantiene vivo
oltre la misura: payload 262.144 byte, dimensione primitive-object-size
262.160, delta consed 262.160, contenuto finale osservato 172. Questo controlla
il sensore senza presumere che un array non escaped venga allocato sullo heap.
Il contatore è cumulativo di processo; non misura RSS. Lo zero osservato
non garantisce ogni percorso, callback o configurazione futura del compilatore.

## Valutazione e seguito

> **Proposta** — Usare questa variante come riferimento per il futuro reader
> tipizzato: tipi letterali per vincoli fissi, u64 mantenuti in array/registri,
> buffer privato e pubblicazione solo dopo validazione. Prima di adottarla nel
> motore occorrono integrazione v2 e misure alla scala del suo indice.

Il dataset è piccolo e residente in memoria; non misura GET/s del database,
P99, latenza I/O, WAL, snapshot, MVCC, compaction, scala oltre cache/RAM,
writer concorrente, Linux o x86-64. La campagna non chiude ADR-0028, il gate
v2 o RSK-02. Non sono introdotte dipendenze foreign, stato globale nel reader
o abbassamenti della priorità dell'integrità dei dati.

## Verifica dell'integrazione

Il [record completo](../../spikes/results/2026-10-08-lettura/verifica-integrazione.lisp)
verifica `362f3f3` in checkout pulito, con sorgenti stabili: compilazione
senza warning/style-warning, 26 test delle fondazioni, 18 storage, 18 I/O,
19 recovery, lint e relativo self-test, tracciabilità, link e cataloghi.
La [campagna dei dieci spike](../../spikes/results/2026-10-08-lettura/spikes-verifica.lisp)
include output originali e risultati di ogni processo, conservando anche
le dipendenze del lavoro già integrato su I/O e bitmap. Le note informative
del compilatore SBCL rimangono negli stream originali. La verifica non
promuove requisiti del motore sulla base delle sole prove sperimentali.
È conservato il [rifiuto durante la pubblicazione](../../spikes/results/2026-10-08-lettura/verifica-pubblicazione-incompleta.lisp):
il packager iniziale non accettava il risultato legacy `:pass` e il catalogo
riferiva un artefatto composito ancora mancante. Il packaging corretto conserva
gli esiti originali `:ok`/`:pass`; la verifica viene ripetuta prima del push.
