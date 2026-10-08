# SPK-09 — costo dei controlli di integrità

> **Proposta** — esperimento di Fase 0, confinato a questa directory. Il codice
> non è un codec di produzione. L'autore ha autorizzato lo sviluppo degli spike
> e confermato ADR-0028/0030 nella consegna; i documenti del repository sono
> aggiornati dal parent, che eseguirà le misure in serie.

## Domanda

Quanto costano CRC32C e verifica di un record in Common Lisp/SBCL, con
`safety 2` e `safety 3`? Quali allocazioni si osservano, inclusi boxing e
interi che sul runtime utilizzato possono essere bignum?

> **Deciso (cornice unica → ADR-0039)** — intestazione di 24 byte,
> little-endian, `header-crc` a 0, `body-crc` a 4, tipo a 8, flag a 9,
> `key-len` a 10, riservato a 11, `value-len` a 12, `stamp` a 16.
> Il CRC dell'intestazione copre i byte 4–23; quello del corpo copre
> chiave e valore. Prima si verifica l'intestazione, poi si usano le lunghezze.

Riferimenti: [ADR-0039](../../docs/adr/0039-cornice-unica-dei-record.md),
[ADR-0034](../../docs/adr/0034-policy-di-compilazione-e-standard-di-codifica.md),
[ADR-0047](../../docs/adr/0047-verifica-csn-dei-record-prepared.md),
[formati](../../docs/formati-su-disco.md), [limiti](../../docs/limiti.md),
[piano SPK-09](../../docs/valutazione/piano-spike.md).
Requisiti esistenti: REQ-FOR-001, REQ-FOR-003, REQ-FOR-004, REQ-AFF-002, REQ-AFF-003,
REQ-BEN-001, REQ-BEN-002, REQ-SIM-002. Nessun requisito viene modificato.

## Metodo

> **Proposta** — package `arcdocdb.spk09`, senza dipendenze. Riferimento CRC
> bit a bit (Castagnoli riflesso `#x82f63b78`, iniziale e XOR finale
> `#xffffffff`), tabella per byte e slicing-by-8. Due funzioni distinte per
> ogni kernel ottimizzato, generate dalla stessa macro e compilate con
> `(speed 3) (safety 2)` e `(speed 3) (safety 3)`. I controlli di tipo e array
> restano attivi. La tabella è costruita al caricamento e poi solo letta.

`(check)` esegue verifiche deterministiche: vettori vuoto e `123456789`
(`0` e `#xe3069283`), confronto col riferimento su lunghezze 0–256,
allineamenti e intervalli pseudocasuali riproducibili, ulteriori taglie,
record validi, bit alterati in ogni byte dell'intestazione e del corpo,
troncamenti, limiti, campi malformati con CRC ricalcolati, chiave/CSN/flag
errati. Il verificatore restituisce gli offset del valore solo dopo la
verifica. Le corruzioni segnalano la condizione `record-invalid` con motivo.

Il parser `verify-record` verifica tipo PUT, lunghezza totale della entry,
entrambi i CRC e chiave; per un record ordinario confronta `stamp` col CSN,
per uno prepared controlla il flag corrispondente nella entry. Non risolve
OUTCOME, manifest o commit. Per un prepared è soltanto parsing della cornice;
la verifica del CSN richiede l'API aggiuntiva descritta sotto (ADR-0047).

**Controesempio della regola originale ADR-0039:** il solo parser non confronta
il TXID effettivo con un TXID atteso nella entry. Una location corrotta in RAM
può quindi puntare a un altro record prepared, con stessa chiave e lunghezza,
entrambi i CRC validi, ma TXID e CSN dell'esito diversi. Il solo confronto del
flag prepared non lo rileva. La suite costruisce due fixture con TXID 101 e
202, valori diversi ma stessa lunghezza, e mostra che entrambe sono accettate
per la medesima entry prepared con CSN 17. Il risultato riporta esplicitamente
`:format-limitations`; `:status :ok` significa conformità ai controlli
implementati. ADR-0047 richiede la prova indipendente per restituire un prepared;
gli offset restituiti dal parser non autorizzano quella restituzione.

> **Deciso (verifica prepared → ADR-0047)** —
> `verify-prepared-record` aggiunge una prova indipendente: un record OUTCOME
> della cornice ADR-0039, tipo 4, flag/chiave/riservato zero, valore di 8 byte
> con il CSN, `stamp` con il TXID, lunghezza totale 32 byte. Entrambi i CRC
> dell'OUTCOME devono verificare; il suo TXID deve coincidere con quello del
> prepared e il suo CSN con quello della entry. La prova assente è rifiutata.
> La funzione restituisce inizio/fine del valore, CSN risolto e TXID.

Esempio dell'API aggiuntiva, con intervalli indipendenti nei due buffer:

```lisp
(arcdocdb.spk09:verify-prepared-record
 buffer inizio fine chiave expected-csn expected-length outcome-buffer
 :outcome-start outcome-inizio :outcome-end outcome-fine)
```

I test comprendono OUTCOME con CSN o TXID sbagliato, prova mancante,
troncamenti, campi OUTCOME malformati con CRC ricalcolati e alterazione di
ogni bit di ogni byte della prova. Una fixture valida mostra il confronto
dei CSN a 64 bit. La verifica separata del prepared conserva la lacuna
documentata sopra; la nuova funzione rifiuta il cambio di location delle
fixture quando è fornito l'OUTCOME della entry originale, oppure quando
è fornito un OUTCOME del diverso prepared con CSN diverso.

Il chiamante fornisce la prova da una fonte indipendente: qui si verifica
il record OUTCOME, non l'appartenenza al segmento né il SEAL del suo lotto.
Il resolver di produzione dovrà verificare anche provenienza, visibilità
e prove del manifest; questa parte è futura. Nessun formato persistente
viene aggiunto o modificato. Il benchmark delle letture ordinarie resta
dedicato alla verifica ADR-0039 originale.

`(benchmark &key ...)` include `check`, warmup e misure su CRC di 20,
128, 2048 e 16384 byte; 20 byte rappresentano la porzione coperta dal
CRC di intestazione, le altre taglie sono byte coperti dal CRC del corpo.
Il confronto di lettura usa corpi delle stesse taglie, inclusa la chiave;
la dimensione totale di ciascun record è quindi 24 byte maggiore.
Entrambe le letture attraversano lo stesso valore e calcolano lo stesso
accumulatore; il percorso verificato aggiunge i controlli di integrità.
Sono misurati sia CSN fixnum sia `#xffffffffffffffff` per esporre l'eventuale
costo degli interi a 64 bit. L'ultimo risultato e un accumulatore sono
restituiti come sink, impedendo di scartare il lavoro.

Sono riportati durata, numero di operazioni, ns/op, byte/s e bytes-consed
(totali e per operazione) tramite `sb-ext:get-bytes-consed`. Le misure sono
a lotto, non percentili. La durata è tempo wall da `get-internal-real-time`,
non tempo CPU; `:elapsed-seconds` include check, setup e warmup dell'API,
mentre `:seconds` di ogni misura copre il ciclo e le letture dei contatori.
Setup, warmup e costruzione del risultato di ogni misura sono
fuori dall'intervallo misurato. Nessuna GC viene forzata durante le misure;
eventuali GC del runtime contribuiscono al tempo trascorso. Le allocazioni
sono del processo: usare un processo dedicato per interpretarle.
Il contatore di allocazione e la risoluzione del clock limitano le conclusioni:
una finestra con bytes-consed pari a zero non prova assenza di allocazioni.
I rapporti di costo della verifica e di safety 3 rispetto a safety 2 sono
calcolati esclusivamente dalle misure della stessa esecuzione. Finestre
troppo brevi e l'ordine fisso dei casi possono distorcere i rapporti.

## Ambiente e comandi

> **Proposta** — usare SBCL senza inizializzazione utente. Il risultato
> registra versione Lisp, sistema, macchina, tick del clock, caratteristiche
> del runtime, taglie e budget. Il parent aggiungerà il modello hardware
> preciso e le condizioni di carico alle misure pubblicate.

Dal repository:

```sh
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-09-integrity/run.lisp --check
sbcl --noinform --no-userinit --no-sysinit --script spikes/SPK-09-integrity/run.lisp --bench
```

È possibile eseguire lo script da un'altra directory tramite un percorso
assoluto. `run.lisp` trova `core.lisp` rispetto a `*load-truename*`, compila
sempre in `out/core.fasl` e trasforma warning e style-warning in errori.
Standard output contiene una sola s-expression plist leggibile; gli errori
terminano l'esecuzione. Senza argomento viene eseguito `--bench`.

Per una diagnostica breve o per un budget personalizzato, il parent può
caricare il core compilato e invocare l'API:

```lisp
(arcdocdb.spk09:check)
(arcdocdb.spk09:benchmark :seconds 0.15d0 :sizes '(20 128))
(arcdocdb.spk09:benchmark :seconds 6d0
                         :sizes '(20 128 2048 16384)
                         :warmup-iterations 8)
```

> **Proposta** — il default assegna 6 secondi complessivi alle finestre
> di misura, oltre a compilazione, check e warmup; obiettivo di durata
> complessiva circa 15 secondi, dipendente dall'ambiente, non una garanzia
> temporale. Ogni finestra ha anche un tetto di operazioni. Parametri e
> dataset sono limitati esplicitamente per mantenere gli array vivi ben
> sotto 1 GiB; niente dataset grande, thread o I/O nel ciclo misurato.

## Limiti e risultato

Verifica eseguita il 2026-10-08: SBCL 2.6.9, ARM64, Apple M4, Darwin 27.0.0
(dati restituiti dal runtime). `--check` passa con compilazione stretta e senza
warning/style-warning. Verificato anche il comando assoluto da `/tmp`.

| Verifica deterministica | Casi osservati |
|---|---:|
| Vettori golden | 2 |
| Intervalli CRC / confronti di kernel | 4672 / 23370 |
| PUT validi, per policy | 84 |
| Bit alterati nell'header / corpo, per policy | 192 / 1200 |
| Troncamenti PUT, per policy | 348 |
| Malformazioni / confronti entry, per policy | 27 / 13 |
| Limiti espliciti / controlli runtime | 26 / 7 |
| Equivalenza del calcolo delle letture | 24 |
| Controesempio del parser prepared | 4 fixture accettate come previsto |
| Prove OUTCOME valide / bit alterati / troncamenti / rifiuti | 4 / 256 / 64 / 29 |

Diagnostica dell'harness delle misure: API con `:seconds 0.2d0`, tutte le
quattro taglie, warmup 2. Il report contiene 52 campioni ed è stato riletto
con `*read-eval* nil`, verificando una sola s-expression e EOF. Sono state
osservate allocazioni non nulle nelle letture con CSN a 64 bit; le finestre
brevi non permettono di classificare prestazioni o assenza di allocazioni.
Output locali in `out/check.sexp` e `out/diagnostic.sexp`, ignorati da git.
Le misure estese in serie e la valutazione dei minimi spettano al parent.

CRC32C rileva le alterazioni verificate da questa suite; non esclude collisioni
e non autentica dati ostili. Una corruzione con CRC ricalcolati è rifiutata
solo se viola un controllo semantico o la entry attesa. La suite deterministica
non prova l'assenza di tutti i difetti, né l'affidabilità di SBCL. Non vengono
misurati I/O, recovery, scrubbing completo, concorrenza o throughput di un
database. Non si deduce il raggiungimento dei minimi ADR-0028 da questo
microbenchmark e non si rivendica allocazione nulla senza misura.
