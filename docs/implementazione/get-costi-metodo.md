# GET: isolamento dei costi e crescita dell'insieme di lavoro

Preregistrazione C4 del 2026-10-23, prima delle misure con
[get-cost-bench.lisp](../../tools/get-cost-bench.lisp). Si affianca al
[benchmark GET corrente](get-performance-metodo.md), che comprende oracolo,
sentinelle e cleanup nel tempo misurato. Non modifica codice di prodotto,
formati, CRC, contratto di concorrenza o criteri di qualificazione.

## Domande e perimetro

1. Quanto costano CRC, verifica PUT, due copie e oracolo separatamente?
2. Quanto cambia la lookup reale passando da otto chiavi calde a una
   distribuzione sull'intero indice, mantenendo invariata la cardinalità?
3. Quanto aggiunge il calcolo XXH64 rispetto ai digest precalcolati?

Il CRC di prodotto è già slicing-by-8; le copie sono `replace` su array
specializzati u8. Non si assume che il CRC sia il collo di bottiglia.
Scalabilità fra reader senza writer non dimostra lock-freedom, assenza di
contesa, prestazioni sotto mutazione o limiti di latenza. Nessun confronto
con throughput teorici di memcpy o CRC hardware viene usato come misura.

## Campagna dei byte

Valori di 16, 256, 4096 B, chiavi di 16 B, PUT v2 non prepared, CSN 7.
Per ogni dimensione: cinque repliche, 1024 warmup, 65.536 operazioni.
Ordine fisso per dimensione, caso e replica; nessuna replica scartata.

| Caso | Lavoro nella finestra |
|---|---|
| `:crc-body` | CRC32C di chiave + valore; controllo del checksum atteso |
| `:record-verify` | `verifica-put-parole`, compresi CRC header/body, cornice, chiave e CSN |
| `:two-copies` | Record → scratch, valore → output, tramite `replace` |
| `:oracle` | Fill sentinelle, output corretto già presente, confronto di tutti i byte e somma |
| `:copy-verify-copy` | Copie precedenti con verifica PUT fra le due |
| `:copy-verify-copy-oracle` | Fill, pipeline precedente e confronto/somma dell'output |

Nel caso `:oracle` il fill riguarda un buffer separato: isola lo stesso
volume di scrittura delle sentinelle senza distruggere l'output da verificare.
Le pipeline sono microbenchmark in memoria, non GET completi: non includono
indice, EBR, resolver, cache seqlock, clock per GET, syscall o cleanup GET.
I buffer sono caldi e riusati; non rappresentano banda DRAM sostenuta.
Non si sommano o sottraggono tempi per attribuire causalmente costi del GET.
Byte/s è espresso rispetto ai byte del valore, non al traffico fisico totale.

## Campagna dell'indice

Cardinalità fissate: 1.024, 65.536, 1.048.576, 4.194.304. Capacità per
frammento `min(8192, 2N)`, directory completa con frammenti distinti e carico
medio 50%. Split vuoti pubblicati attraverso le API reali prima degli insert;
non si misura la politica dinamica di split. Nessun writer durante le letture.
Chiavi binarie di 16 B: ID univoco nei primi otto, dominio presente/assente
negli ultimi otto. Digest XXH64 reali, seme fisso high `#x01234567`, low
`#x89abcdef`. Chiavi e digest risiedono in array contigui specializzati.

Ogni dimensione ha cinque repliche per quattro casi:

- `:hot-eight`: soltanto otto chiavi presenti, nell'indice completo.
- `:uniform-hit`: presenti sull'intero corpus, digest precalcolati.
- `:uniform-miss`: assenti sull'intero corpus, digest precalcolati.
- `:hash-uniform-hit`: come uniform-hit, includendo XXH64 della chiave.

Ogni replica: 4096 warmup e `max(262144, N)` tentativi misurati. Il cursore
LCG modulo N (`1664525*x + 1013904223`, seme 17) ha periodo N per queste
potenze di due. Il percorso uniforme visita quindi ogni chiave almeno una
volta per finestra; non è una sequenza IID né una distribuzione Zipf.
Non si svuotano le cache CPU: si misura un insieme riusato la cui dimensione
cambia. Non si attribuisce ogni accesso a DRAM senza contatori hardware.

Ogni tentativo controlla lo stato e, sugli hit riusciti, CSN e location
indipendenti dall'indice. `:retry-limit` non viene ritentato né confuso con
un successo: il rapporto conserva il numero separato. Prima e dopo le
finestre si verificano tutte le chiavi presenti e i cinque campi restituiti,
confrontando inoltre la chiave nell'arena tramite la lookup reale.

Payload indice calcolato: `F * (41*C + 16*C) + 8*F`; corpus e quattro
array digest aggiungono `48*N` B. È una contabilità degli array, non RSS:
esclude header, strutture, vecchie root/garbage, runtime e compilatore.
Il driver rifiuta fixture oltre 1 GiB prima di costruirle. Il comando usa
dynamic space 4096 MiB su host con 16 GiB fisici. `/usr/bin/time -l` registra
il picco RSS dell'intero processo, distinto dalle finestre e dai payload.
Non si prova una cardinalità di 100 milioni né un indice oltre RAM.

## Integrità della misura

Un solo thread principale; safety 3, speed 2 (speed 3 per il contatore del
ciclo). GC completo prima del warmup, fuori misura. Tick monotoni SBCL e
`get-bytes-consed` globale prima/dopo; completamenti e sink preallocati.
Nessuna soglia di prestazione, nessuna sottrazione di baseline. Zero tick
produce rate NIL. Autoverifica: vettore CRC standard e oracolo bitwise
indipendente, tutte le componenti, hit/miss/hash e payload, rilevamento di
CRC corrotto e di risultato alterato, sensore positivo con array vivo da
4 MiB e controllo nullo. Le finestre, anche incomplete, vengono persistite
prima di propagare un fallimento. Rapporto scritto/riletto con READ-EVAL NIL.

CLI `--self-test`, `--bytes`, `--index`, `--negative-fixture`, più directory
nuova obbligatoria. Timeout complessivo 900 s, finestra 60 s. Un errore
produce rapporto failed, messaggio con file e COD-61, exit 1; l'opzione
negativa altera appositamente l'atteso CRC ed è tenuta distinta dai risultati.
I due comandi prestazionali eseguono prima l'autoverifica bounded.

```sh
sbcl --script tools/record-command.lisp -- sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit --script tools/get-cost-bench.lisp --self-test spikes/out/get-cost-self-test-01/
sbcl --script tools/record-command.lisp -- sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit --script tools/get-cost-bench.lisp --negative-fixture spikes/out/get-cost-negative-01/
sbcl --script tools/record-command.lisp -- /usr/bin/time -l sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit --script tools/get-cost-bench.lisp --bytes spikes/out/get-cost-bytes-01/
sbcl --script tools/record-command.lisp -- /usr/bin/time -l sbcl --dynamic-space-size 4096 --noinform --no-userinit --no-sysinit --script tools/get-cost-bench.lisp --index spikes/out/get-cost-index-01/
```

I sorgenti devono essere stabili nel registro esterno. Eventuali fallimenti
e versioni corrette rimangono conservati. Le due letture dell'autore non
sono una revisione indipendente. Il prossimo passo di prodotto dipende dai
risultati, senza disabilitare controlli o cambiare garanzie implicitamente.
