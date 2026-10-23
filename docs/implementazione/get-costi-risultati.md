# GET: costi dei byte e insieme di lavoro misurati

Campagna C4 del 2026-10-23, secondo il
[metodo preregistrato](get-costi-metodo.md), su Apple M4 ARM64, 16 GiB,
Darwin 27.0.0, SBCL 2.6.9, safety 3. Base `93a24872`, strumento e metodo
nuovi non committed, inclusi nelle impronte prima/dopo. Carico esterno,
scheduler e cache CPU non controllati; nessun writer concorrente.
Nessun cambiamento al percorso GET o ai controlli d'integrità del prodotto.

## Risposta alla diagnosi iniziale

I numeri di partenza sono quelli della
[campagna GET dell'11 ottobre](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-performance/risultati.md):
il throughput comprende confronto byte per byte, sentinelle, clock e cleanup.
Il [CRC prodotto](../../src/foundation/crc32c.lisp) è già slicing-by-8;
le copie della [cache](../../src/cache/read.lisp) usano array u8 specializzati.
La diagnosi «CRC byte per byte oppure copia generica» non descrive il codice.
La misura isolata conferma però che il CRC è il primo candidato da ottimizzare.

Mediane di cinque repliche, microsecondi per operazione:

| Valore | CRC body | Verifica PUT | Due copie | Oracolo | Copia/verifica/copia | Pipeline con oracolo |
|---:|---:|---:|---:|---:|---:|---:|
| 16 B | 0,050 | 0,206 | 0,021 | 0,032 | 0,217 | 0,253 |
| 256 B | 0,378 | 0,549 | 0,046 | 0,319 | 0,582 | 0,876 |
| 4096 B | 5,798 | 5,976 | 0,402 | 4,279 | 6,358 | 10,611 |

Per il valore da 4096 B il CRC elabora realmente 4112 B, circa **709 MB/s**
decimali. Le due copie costano circa quattordici volte meno del solo CRC
in questa fixture calda. La pipeline con verifica completa raggiunge circa
157 mila operazioni/s; includendo l'oracolo scende a circa 94 mila.
Sono microbenchmark, non nuove prestazioni del GET completo: non includono
EBR, indice, resolver, seqlock cache, syscall o clock per richiesta.
Non si sottraggono questi tempi da quelli storici né si prevede un fattore
di accelerazione del database dal loro rapporto.

Conclusione operativa: il prossimo esperimento deve confrontare un CRC32C
più veloce con quello corrente, mantenendo safety, checksum incrementale,
range, CSN e rilevamento delle corruzioni. La copia non è il primo intervento
giustificato da queste misure. Un backend nativo/SBCL specifico dell'ISA
richiede verifica di disponibilità, fallback, disassemblato e nuovo ADR
prima di entrare nel prodotto. Non è stato implementato in questa campagna.

## L'effetto della cardinalità è osservabile

Mediane di cinque repliche. Nanosecondi per tentativo dell'intera lookup,
compresi selezione del cursore, controllo dello stato e CSN/location sugli
hit; non sono latenze di un singolo accesso DRAM.

| Chiavi | Payload indice | Directory | Otto chiavi calde | Hit uniforme | Miss uniforme | Hash + hit uniforme |
|---:|---:|---:|---:|---:|---:|---:|
| 1.024 | 114,01 KiB | 8 B | 97,4 ns | 113,9 ns | 86,9 ns | 155,4 ns |
| 65.536 | 7,125 MiB | 128 B | 97,8 ns | 154,7 ns | 110,8 ns | 193,5 ns |
| 1.048.576 | 114,002 MiB | 2 KiB | 102,4 ns | 361,0 ns | 143,7 ns | 438,4 ns |
| 4.194.304 | 456,008 MiB | 8 KiB | 101,6 ns | 437,0 ns | 232,3 ns | 589,1 ns |

A cardinalità massima l'hit uniforme costa **4,30 volte** il caso su otto
chiavi nello stesso indice. Il rapporto è calcolato fra mediane, non è un
intervallo di confidenza. L'hit uniforme raggiunge 2,288 milioni di
tentativi/s; includendo XXH64, 1,697 milioni. Il miss non legge payload/chiave
di uno slot vivo quando il fingerprint non coincide: non ci si aspetta lo
stesso costo dell'hit.

Il corpus contiene digest reali e directory con 1024 frammenti distinti;
non è una tabella finta indicizzata direttamente dall'ordinale. Ogni finestra
uniforme visita tutte le chiavi. Il carico medio è 50%, l'arena è prenotata
per C chiavi: non sono misure a saturazione 7/8, sotto split o compaction.
Il driver verifica tutte le chiavi e i cinque campi prima e dopo le finestre.

Il payload massimo indice + fixture è **679.485.440 B**, circa 648 MiB;
il picco RSS dell'intero processo è **1.386.151.936 B**, circa 1,291 GiB,
osservato da `/usr/bin/time -l`. Il picco include startup, runtime e
garbage, non rappresenta RSS per singola cardinalità. Il processo indice
dura 46,85 s; quello byte 14,77 s. Sono tempi complessivi, fuori dalla
definizione delle finestre. Non è misurato un working set oltre RAM.

La crescita osservata è compatibile con un costo della gerarchia di memoria,
ma non identifica LLC miss, TLB miss, numero di accessi DRAM o latenza DRAM:
servono contatori hardware e un controllo dell'ambiente. Cento milioni di
chiavi, distribuzione Zipf, più reader, writer concorrente, cache paginata,
pressione RAM e storage freddo restano campagne distinte. Questi dati non
qualificano ancora la capacità di c0rvus.

## Verifiche e provenienza

- 90 finestre byte, 5.898.240 operazioni; 80 finestre indice,
  115.343.360 tentativi. Tutte complete, nessuna replica scartata.
- **170/170 finestre prestazionali con delta heap Lisp zero** e nessun
  esito `:retry-limit`. Non significa assenza universale di allocazione,
  assenza di tentativi interni o garanzia sul GC/OS.
- Entrambe le campagne passano le 23 finestre bounded preliminari e i
  controlli negativi interni; il sensore rileva almeno 4 MiB vivi.
- Negativa CLI: checksum atteso alterato, finestra conservata con zero
  completamenti, rapporto failed ed exit 1, sorgenti stabili. È un
  fallimento atteso, separato dai dati prestazionali.
- Compilazione C4 separata senza warning/style-warning; nessuna modifica C1.
  Prima e seconda lettura statica dell'autore: forma dei record, dominio dei
  digest, budget, periodo del cursore, ownership, sink e separazione dei clock.
  Non sono una revisione indipendente.

La prima autoverifica precede l'aggiunta del controllo esplicito che il miss
lasci intatto l'output; la versione finale viene autoverificata in entrambe
le campagne. Un'ulteriore autoverifica lanciata senza registro esterno è
conservata come dato accessorio e non fonda le conclusioni quantitative.
Registri, sorgenti delle due versioni, dati grezzi, derivazione delle mediane
e controlli statici sono conservati nel
[catalogo della campagna](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-get-costs/catalogo.lisp).

Le letture senza writer e la scalabilità storica non dimostrano lock-freedom.
Resta applicabile la distinzione fra lookup residente, acquisizione sicura
della pagina e I/O: nessuna proprietà di progresso è stata promossa da questi
benchmark. La selezione automatica residente/paginato rimane il progetto
dell'[indice automatico](indice-automatico.md), separato da questa diagnosi.
