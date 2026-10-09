# Lettura C4 dei driver della struttura CBOR

Lettura del coordinatore sui driver congelati, prima delle campagne. Il
coordinatore non ha scritto kernel, test o driver. Esito statico: nessun
difetto aperto; compilabilità dei mutanti e misure restano da acquisire.

Il benchmark ha sei fixture, cinque repliche di 32 chiamate e warmup128.
Ogni chiamata confronta nodi, profondità e fine con tre costanti indipendenti
e calcola nodes + 65536·depth + 16777216·next. Token ricontrollati con sola
aritmetica: 184549377, 549839699969, 1717829732, 386007052, 68803432449,
68769812481. Somma attesa N·token + N(N−1)/2, modulo most-positive-fixnum;
anche la cella massima ×32 resta fixnum SBCL64. Input, copie, closure, spazio,
warmup, GC e report precedono o seguono il tratto misurato. Il costo include
confronti e sink. Baseline zero e 16 allocazioni da 1MiB vive sono richieste;
un tick zero produce rate NIL, non un throughput inventato.

Il mutator acquisisce tutti i file ASDF effettivamente copiati, usa mkdir
esclusivo e cache distinta per baseline e mutanti. Dieci anchor sono unici
nel kernel congelato: budget nodi/profondità, span header/payload, trailing,
parità map, consumo del figlio taggato, major chunk/UTF8 e arità map. Non è
una ricerca esaustiva di ogni difetto possibile. Baseline richiede exit0,
smoke e completamento su righe esatte. Una citazione in backtrace, un prefisso
indentato o un suffisso non basta. Compilazione fallita è INVALID; exit0 senza
completamento è INVALID anche per il mutante. Dopo smoke reale, un errore
runtime è DETECTED; la pertinenza di ogni errore dovrà essere letta sui log.

Gli strumenti registrano identità prima/dopo, salvano un report anche sul
fallimento e conservano log/copie degli esiti INVALID. Il runner del
coordinatore assegna directory nuove e mantiene le misure seriali, fuori
da copertura e mutazioni. Nessuna soglia di velocità o claim di scaling.

| File | Git blob della lettura |
|---|---|
| tools/cbor-structure-bench.lisp | `a0a676c0107dee9429f27d3fdcdc78bb3d7f2957` |
| tools/cbor-structure-mutation.lisp | `dd6e9fb1f3655b78eb64285bee0de35474e12eba` |

La lettura di copertura e collector è attribuita separatamente nel referto
C4 degli strumenti. Nessuna lettura equivale ad approvazione umana o qualifica
del profilo semantico CBOR e del motore completo.
