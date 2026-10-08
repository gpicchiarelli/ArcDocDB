# SPK-08 — Metodo del confronto SIMD a 16 byte

> **Proposta** — Microesperimento preregistrato il 2026-10-08. Solo Common
> Lisp/SBCL, `safety 3`. REQ-SIM-001, REQ-SIM-002, REQ-VAL-001; nessuna
> modifica dell'indice o dei requisiti del motore.

## Domanda e contratto

Un confronto SIMD di 16 ctrl byte, seguito da riduzione a una maschera u16,
conserva ogni posizione esatta e riduce il costo rispetto al ciclo scalare?
Query 0..127; ctrl 0..255, compresi empty/deleted. Il kernel controlla il
range completo prima del load e legge soltanto un array semplice u8.

NEON: load u8.16, broadcast della query, confronto di uguaglianza,
reinterpretazione u64.2 e compressione dei bit alti. SSE2: stesso confronto
con movemask. L'ordine dei bit deve corrispondere ai 16 byte, anche per load
non allineati. Il ramo SSE2 resta non misurato sulla macchina ARM64 locale.

Le API provengono dal [manuale SBCL 2.6.9, §17.11](https://www.sbcl.org/manual/#sb_002dsimd)
e dai sorgenti del contrib installato, consultati prima dell'esecuzione.
Gli intermedi SIMD restano dentro funzioni tipizzate; il check conserva il
disassemblato. La presenza di istruzioni da sola non attesta correttezza.

## Correttezza

Oracolo scalare indipendente dalla riduzione. Si esauriscono le 65.536
maschere su una query fissa e le 128 × 256 × 16 combinazioni di query,
ctrl e posizione. Offset 8..23 esercitano ogni allineamento modulo 16.
Si controllano input immutato, buffer corti, offset negativi e oltre il
range, query non ammesse. Tetto: 600.000 casi di confronto; esaurimento
o mancato supporto non viene interpretato come prova hardware riuscita.

## Misure

Tre dataset preallocati da 16.384 gruppi: byte misti deterministici,
tutti corrispondenti, e soli ctrl speciali senza hit. Ogni metodo legge
gli stessi byte con query 42: 256 attraversamenti, 4.194.304 gruppi per
campione. Cinque repliche con ordine alternato, warmup separato e GC prima
di ciascun campione. Il risultato alimenta un accumulatore u32 verificato.

Si registrano campioni grezzi, durata monotona, operazioni, ns/gruppo e
delta `get-bytes-consed` del solo ciclo. Preparazione, verifica e raccolta
del report sono escluse. Un controllo positivo del contatore alloca un
array e lo rende osservabile. Nessuna soglia di tempo promessa; benchmark
eseguiti in serie, carico esterno non controllato. Non sono GET del database,
non misurano seqlock, cache, memoria debole, concorrenza o dati oltre RAM.

## Riproduzione

```sh
sbcl --script tools/run-spikes.lisp --check SPK-08
sbcl --script tools/run-spikes.lisp --bench SPK-08
```

Per il solo modulo usare `run.lisp --simd-check` o `--simd-bench` attraverso
`tools/record-command.lisp`. Il registro conserva argv, ambiente, revisione,
hash prima/dopo, risultato e output originale, anche in caso di fallimento.
L'assenza del contrib o del backend è registrata come `:unsupported`.

## Primo controllo osservato

Il [record iniziale](../results/2026-10-08-avanzamento/native-simd-check-initial.lisp)
riporta SBCL 2.6.9, backend NEON e `:status :ok`: 589.824 confronti,
16 controlli di input immutato e 4 rifiuti dei parametri, compilazione
senza avvisi. Il disassemblato mostra `LDR Q` e `CMEQ`. Il successivo
controllo integrato verificherà gli stessi kernel insieme alle altre varianti.
