# Inventario delle decisioni del routing worker/Serie

Lettura del 2026-10-11 sulla base
`92decf4265554cd4959e32a1c881cf00758bb6a1`, dopo RW-REV-01.
Questo inventario manuale non è una misura di copertura o MC/DC.
Il [metodo](routing-worker-metodo.md), il [contratto](routing-worker.md)
e la [revisione C1](routing-worker-revisione.md) delimitano lo scope.

| Sorgente letto | SHA-256 |
|---|---|
| `src/execution/handoff.lisp` | `3ce9f47008416f210173fd3a83ee7665b2103f26039d36e2601b31e5e3ebd72a` |
| `src/execution/package.lisp` | `833e501e6ee6e3acb8a6d37139c4605a05e06c425a35318adbcf651aa2f9db30` |
| `src/series/worker-package.lisp` | `dcab7a17e4fabcf256c2eddfb655d18145a1d789dd8d64a889945badc418e4b7` |
| `src/series/routing-types.lisp` | `31ae51c0fb11a802164a4d1e11ec63f835a2c67b52c751c5685bcc8947e5e0f1` |
| `src/series/routing-build.lisp` | `70135e73ecb1f6080683dd615c47a50530485061797382d74441743cd9a0f92d` |
| `src/series/routing-select.lisp` | `796e3ace762dd6c3d86119981a37c1904a637e664551ca0f5289544f0806714a` |
| `arcdocdb.asd` | `a4852ba400f91c52af42df0143b921fbcb1895479d4e250f16d57ad8d65f7fb9` |

## Controlli locali

Gli ID comprendono tutti i 21 predicati scalari dei tre file nuovi,
la decisione composta aggiunta alla factory writer, i due cicli startup
e i due gate macro della selezione. Le decisioni già presenti in handoff,
worker e bridge restano nei loro inventari; non si eliminano dal
denominatore della copertura dei file completi.

| ID / posizione | Decisione | Esiti e obbligo |
|---|---|---|
| H01 / handoff:71–72 | Factory writer, `unless (or A B)` | A: indice NIL; B: indice del tipo integer0..65535. Almeno uno vero accetta; entrambi falsi `invalid-argument :writer-configuration` prima della coda. |
| T01 / types:33 | `%routing-size`, `unless (<= 1 size 65536)` | Nel budget prosegue; fuori produce `invariant-violation :worker-serie-routing`. Nessuna scansione. |
| T02 / types:35 | Stesso helper, lunghezze writers/controllers uguali | Uguali restituisce size; diverse invariante prima di usare elementi. |
| I01 / build:12 | `%routing-input-size`, writers simple-vector | Tipo accettato prosegue; altro `invalid-argument :worker-serie-routing-configuration`. |
| I02 / build:14 | Stesso helper, controllers simple-vector | Tipo accettato prosegue; altro stesso rifiuto, prima delle copie. |
| I03 / build:17 | Stesso helper, size1..65536 | Budget accettato prosegue; vuoto/eccessivo stesso rifiuto. |
| I04 / build:19 | Stesso helper, lunghezze uguali | Uguali restituisce size; diverse stesso rifiuto. |
| E01 / build:28 | `%routing-input-entry`, tipo writer | Writer valido prosegue; altro `invalid-argument :worker-serie-routing-binding`. |
| E02 / build:30 | Stesso helper, indice writer EQL ordinal | Ordinale esatto prosegue; NIL, ordinal diverso o writer duplicato nello slot diverso stesso rifiuto. |
| E03 / build:32 | Stesso helper, tipo controller | Controller valido prosegue; altro stesso rifiuto. Non consulta salute/owner/ring. |
| E04 / build:34 | Stesso helper, `when (gethash controller seen)` | Già visto EQ rifiuta il duplicato; nuovo entra nel solo hash startup. |
| R01 / build:51 | Factory registro, size finale uguale a size input | Postcondizione coerente restituisce registro; diversa invariante, senza pubblicazione. |
| W01 / build:68 | Factory tabella, lunghezza links uguale a size | Postcondizione coerente restituisce tabella; diversa invariante, nessuna lease assunta. |
| O01 / select:14 | `%routing-ordinal`, lunghezza links uguale al registro | Uguale prosegue; diversa invariante prima dell'accesso link. |
| O02 / select:16 | Stesso helper, ordinal del tipo index | Index prosegue; NIL/invalido invariante dopo claim. |
| O03 / select:18 | Stesso helper, ordinal minore di size | Nel range prosegue; fuori invariante prima di `svref`. |
| O04 / select:20 | Stesso helper, writer EQ nello slot | Identico restituisce ordinal; estraneo, anche con stesso numero, invariante. |
| L01 / select:31 | `%routing-link`, tipo link | Collegamento valido prosegue; altro invariante. |
| L02 / select:33 | Stesso helper, contesto link EQ contesto tabella | Identico prosegue; estraneo invariante prima dell'accesso alle capacità. |
| L03 / select:35 | Stesso helper, writer link EQ writer corrente | Identico prosegue; altro invariante. Nessun riuso del link del tratto precedente. |
| L04 / select:37–38 | Stesso helper, controller link EQ controller registro | Identico prosegue; altro invariante, senza leggere lo stato del controller. |
| L05 / select:40 | Stesso helper, fase link IDLE | IDLE delega forma/lease locale a `%check-worker-serie` e restituisce link; altro invariante, nessun cleanup. |
| C01 / select:53 | Gate FAULTED di `%passo-worker` esterno | Terminale rifiuta prima del handler preservando la prima diagnosi; operativo esegue il preflight CLAIMED. Owner è controllato prima del gate. |
| C02 / select:55 | Gate FAULTED di `%passo-worker` interno | Terminale rifiuta prima del handler; operativo protegge soltanto i helper lookup con allowlist vuote. RW-REV-01. |
| Q01 / build:48 | `dotimes` della factory registro | Esattamente N iterazioni, N validato1..65536; nessun retry e nessun ciclo nel lookup. |
| Q02 / build:64 | `dotimes` della factory tabella | Esattamente N binding preallocati; limite dal registro T01/T02 prima dell'array. |

Il getter `indice-routing-writer`, le strutture e i package non aggiungono
altre decisioni. La factory tabella delega il controllo IDLE del worker
prima di allocare; la selezione delega CLAIMED prima del boundary interno.
Entrambi verificano il proprietario attraverso execution.

## Decisione composta H01

A è `(null routing-index)`; B è
`(typep routing-index '(integer 0 65535))`.
Le assegnazioni richieste dalle fixture sono indipendenti rispetto alla
decisione di accettazione:

| Input della fixture | A | B | Decisione | Contrasto |
|---|---|---|---|---|
| Simbolo estraneo | F | F | Rifiuta configurazione. | Base comune. |
| `NIL` | V | F | Accetta writer compatibile senza routing. | Con base cambia soltanto A. |
| `0` | F | V | Accetta ordinale0. | Con base cambia soltanto B. |
| `65535` | F | V | Accetta limite superiore. | Verifica ulteriore del budget. |
| `65536`, `-1`, float o stringa | F | F | Rifiuta configurazione. | Verifica ulteriore di tipo/range. |

`or` cortocircuita: con A vero B non viene valutato. I valori della tabella
sono quelli degli input, non una attestazione di esecuzione di ogni operando.
Non si inferisce MC/DC da sb-cover o dal solo successo della fixture.

## Confine degli errori e controlli delegati

| Passo | Resource recuperabili | Invalid recuperabili |
|---|---|---|
| Factory writer/registro/tabella | Nessun handler nuovo; input/fase rifiutati prima della pubblicazione. | Nessun handler nuovo. |
| Selezione esterna, preflight owner/CLAIMED | Soltanto `:worker-state`. | Nessuna. |
| Selezione interna, helper lookup | Nessuna. | Nessuna. |

La selezione esterna permette la chiamata fuori fase senza mutazione.
Il lookup interno non può usare quella allowlist: un errore del lookup
con la stessa ragione `:worker-state` viene registrato come terminale prima
del passaggio nel confine esterno. La condizione è propagata senza cambiarne
l'identità; se l'esterno la riconosce, il worker è comunque già FAULTED.
Un nuovo passo sul worker terminale rifiuta fuori dai handler senza
sostituire la diagnosi. Wrong-thread è analogamente rifiutato prima del
handler, senza poisoning del contesto, tabella, link o controller.

| Delegato letto | Obbligo |
|---|---|
| `execution::%passo-worker` | Valutazione singola del contesto, owner/gate terminale fuori dal handler, valori del corpo preservati e diagnosi persistente. Due istanze locali dynamic-extent; macro già documentata e testata nel worker. |
| `execution::%richiedi-worker` | Forma/capacità/cursori del worker e fase richiesta; factory IDLE, selezione CLAIMED. Non assume un nuovo obbligo. |
| `writer-worker-writer` | Getter owner-only; riferimento current writer conservato dopo claim. |
| `%check-worker-serie` | Forma IDLE, fault NIL e lease locali zero; non consulta lo stato vivo della Serie in IDLE. |
| `crea-collegamento-worker-serie` | Preallocazione sul thread del contesto, riferimenti immutabili, nessuna lease. |

Questo coupling interno resta esplicito e richiede rilettura se cambiano
worker, macro, binding o forma del registro. Nessuna salute Archivio è
scritta sul percorso normale. Non si marca una Serie su un errore routing
senza averne la lease: il coordinamento del guasto rimane aperto.

## Limiti e denominatori

La complessità locale si conta come una base più ogni `when`/`unless`,
un ingresso ulteriore per il secondo operando di `or` e un ingresso per
ogni `dotimes`; i controlli dei delegati restano nei loro helper. Il massimo
dei tre file nuovi è6 in `%routing-link`; `%routing-input-size`,
`%routing-input-entry` e `%routing-ordinal` sono5, `%routing-size` è3,
le due factory sono3. La selezione pubblica è3 includendo i due gate delle
espansioni macro; la factory writer modificata è3. Corpi entro60righe,
nessuna nuova ricorsione, attesa, callback, retry, thread o syscall.

Ogni accesso hot è O(1). La factory registro occupa O(N) spazio e usa hash
EQ solo per l'unicità all'avvio; non si promette un costo worst-case O(N)
del runtime hash. La tabella occupa O(N) spazio per worker. Il limite
N≤65536 controlla memoria/cicli del componente; il caller deve includerlo
nel budget complessivo di startup.

La copertura dedicata deve mantenere i file completi: 15 sorgenti Series,
inclusi package e tre nuovi file late, e 11 sorgenti execution, incluso
handoff modificato. L'ordinal writer e i controlli del worker non vengono
attribuiti allo scope Series. Rapporti nativi/HTML, denominatori e tutte
le identità missing restano nel risultato grezzo; nessuna esclusione è
approvata. Il numero di test passati non attesta copertura totale, tutti
gli interleaving, heap nullo universale o qualifica del motore.

La tabella degli SHA sopra identifica lo scope delle campagne dedicate
v2 sulla base92decf4. Il congelamento generale integra d155db3, che cambia
ASDF per CBORstring-write e GETresolver senza cambiare execution/Series;
8fb3051 aggiunge poi solo artefatti, senza cambiare sorgenti, tool o docs.
La [revisione](routing-worker-revisione.md#integrazione-con-main-avanzato)
mantiene distinti qualificazione dedicata e controllo generale integrato.
