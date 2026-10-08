# SPK-04 — prima campagna locale, 2026-10-08

[Valutazione](README.md) · [Metodo e codice](../../spikes/SPK-04-writer-pool/README.md)

> **Proposta** — Evidenza sperimentale del writer e dei modelli di attesa,
> con `safety 3`. Non verifica il motore né i target di ADR-0028.

## Ambiente e prove conservate

SBCL 2.6.9 su macOS ARM64; heap dei processi 4 GiB. Ambiente hardware,
carico esterno non controllato, comando e blob dei sorgenti sono conservati
nei report. Il commit di riferimento è `6913318`, con modifiche locali
esplicite. I quattro sorgenti dello spike e l'harness sono identificati
prima/dopo: entrambi i run riusciti riportano `:source-consistency :stable`.

- [Controlli](../../spikes/results/2026-10-08/spk04-check.lisp).
- [Benchmark](../../spikes/results/2026-10-08/spk04-bench.lisp).
- [Verifica completa del repository](../../spikes/results/2026-10-08/spk04-full-check.lisp):
  `make check` riuscito, sette spike, tracciabilità e collegamenti validi.
- [Primo tentativo fallito](../../spikes/results/2026-10-08/spk04-check-initial-failed.lisp)
  e [diagnostica](../../spikes/results/2026-10-08/spk04-check-initial-failed-process.lisp).
- [Secondo tentativo fallito](../../spikes/results/2026-10-08/spk04-check-parking-failed.lisp)
  e [diagnostica](../../spikes/results/2026-10-08/spk04-check-parking-failed-process.lisp).

Il primo tentativo rileva un avviso sulla ridefinizione della macro al
caricamento: la macro locale ora è definita nella fase di compilazione,
mentre il FASL contiene le sue espansioni. Il secondo rileva una parentesi
di chiusura in eccesso nel modello dei parcheggi. Le correzioni non
cancellano i fallimenti. Compilazione e caricamento finali senza avvisi.

## Correttezza osservata

| Ambito | Controllo ed esito |
|---|---|
| Ring della Serie | Capacità 2, rifiuto senza mutazione e wrap-around FIFO |
| Produttori e writer reali | 8 produttori, 4 Serie, 4 worker, 256 richieste; 40 tratti e 44 accessi alla lista pronta; nessuna richiesta persa o duplicata |
| Passaggio di consegna | Una Serie, quattro thread successivi; sequenza di worker 0/1/0/1 |
| Burst deterministico | Serie calda con 64 richieste, tre fredde con 4 ciascuna; tutte le fredde completate entro il quarto tratto con un worker |
| Errore worker | Errore iniettato propagato e quattro thread terminati |
| Parcheggi | 15 fixture su client di lotto, snapshot e coordinatori; saturazione, scadenza inclusiva, FIFO, riuso e notifiche obsolete |
| Ripartenza lettura | 9 combinazioni e 54 asserzioni sul modello; nessuna location o epoca nel contesto migrato |

L'equità del caso burst è un risultato in **tratti**, non una promessa di
latenza. I produttori terminano prima del drain; non è esercitato l'arrivo
di nuove richieste mentre i writer lavorano. Parcheggi e letture sono
modelli finiti, distinti dal pool con thread reali.

## Benchmark diagnostico

54 casi: carico uniforme/sbilanciato, 1/4/16 Serie, 1/2/4 worker,
tratti di 1/8/64 richieste, 4.096 richieste per caso e 32 passi sintetici.
Totale: **221.184 operazioni**. Il processo dura **0,968645 s**, compresi
compilazione, controlli e misure; non è una singola finestra di throughput.

Esempio con 16 Serie e tratti da 64 richieste:

| Carico | Worker | Tempo wall, ms | Tratti | Accessi lista pronta | Byte allocati nel processo |
|---|---:|---:|---:|---:|---:|
| Uniforme | 1 | 0,937 | 64 | 65 | 65.520 |
| Uniforme | 2 | 0,727 | 64 | 66 | 131.040 |
| Uniforme | 4 | 0,737 | 64 | 68 | 262.080 |
| Sbilanciato | 1 | 0,983 | 78 | 79 | 65.520 |
| Sbilanciato | 2 | 0,959 | 78 | 80 | 131.040 |
| Sbilanciato | 4 | 1,167 | 78 | 82 | 262.080 |

Il contatore della lista pronta è pari ai tratti più i ritiri dei worker,
senza aggiornamenti globali da ogni richiesta. Con tratti di una richiesta
il costo comune è per operazione: quel caso è soltanto diagnostico.

Le finestre della tabella sono inferiori a 2 ms e hanno un solo campione:
**non permettono una conclusione sulla scalabilità**. Comprendono avvio
sequenziale dei thread, join, controlli FIFO/bitmap e clock per richiesta;
escludono preallocazione e generatore. Le allocazioni comprendono harness e
thread del processo, con la granularità del contatore SBCL. Non sono RSS
né una misura isolata del kernel. I tempi per Serie nel report misurano
l'intervallo dall'avvio comune al completamento, incluso il servizio.

## Conseguenze e limiti residui

> **Proposta** — Il pool e i modelli danno una prima evidenza eseguibile di
> ADR-0045. RSK-04 resta quantitativamente aperto: servono pool già avviato,
> finestre lunghe, repliche, produttori durante il drain, messaggi del writer,
> adattamento dinamico e piattaforma Linux di riferimento. CSN, orizzonte,
> epoche, I/O e commit durevole non sono implementati dallo spike.

L'acquisizione dei mutex usa tentativi non bloccanti con tetto 100.000;
il corpo sintetico non fa I/O. Il tentativo può cedere lo scheduling:
non dimostra esecuzione senza sospensioni del runtime. Il controller ha
join con timeout diagnostico e un solo secondo tentativo dopo lo stop;
un thread ancora vivo produce `cleanup-incomplete`, mai un esito riuscito.
Nessun budget di tentativi o tempo viene presentato come garanzia.
