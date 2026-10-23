# Scrittura dei float CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-13, prima del nuovo corpus,
del prodotto e delle campagne. REQ-CBR-004 deriva da ADR-0014;
ADR-0048 mantiene il budget del documento al livello superiore.

## Contratto locale

```lisp
(scrivi-float-cbor-minimo buffer start end ai high low)
;; => esattamente NEXT
```

BUFFER simple u8 esclusivo, START/END index delimitano uno span half-open
valido anche vuoto. AI 25/26/27 descrive bit IEEE binary16/32/64;
HIGH/LOW u32 sono parole raw. HIGH deve essere zero per AI25/26;
LOW deve essere u16 per AI25. Non sono float nativi Common Lisp.

Si accettano tutte le codifiche IEEE, anche quelle accorciabili.
Si sceglie la larghezza esatta piu corta, anche passando da 64 a 32 e 16:
nessun arrotondamento, ricomposizione u64, AST o conversione applicativa.
Segno, zero, infinito e significando NaN con padding a destra sono
preservati, compreso signaling/quiet. E la preferenza locale del
[contratto vigente](cbor-minimo-metodo.md), coerente con
[RFC 8949 §4.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.1).
Profilo documentale, equivalenze applicative e normalizzazione dei NaN
rimangono superiori; non si attesta determinismo dell'intero documento.

Output: F9/FA/FB, parole big-endian, 3/5/9 byte. NEXT=START+dimensione;
solo [START,NEXT) cambia, compresi residuo dello span e coda fisica
immutati. Al massimo nove byte, variabili immediate, nessuna scrittura
condivisa, attesa, I/O o pubblicazione durevole/atomica.

Preflight: range (:cbor-range), AI (:cbor-float-ai), HIGH
(:cbor-float-high), LOW (:cbor-float-low), coerenza parole
(:cbor-float-words), capacita della forma scelta (:cbor-float-capacity).
I primi cinque segnalano INVALID-ARGUMENT, l'ultimo RESOURCE-EXHAUSTED;
offset NIL e intero array fisico intatto. END e il limite, non la coda
fisica. Errori di invariante interni senza rollback: proprietario fail-stop.
Le nuove conversioni esatte raw sono il rischio principale dell'incremento.

## Corpus congelato prima del prodotto

Un autore distinto prepara il corpus senza leggere i nuovi sorgenti,
poi ne comunica le impronte. Solo dopo viene scritto il prodotto;
compilazione e campagne seguono due letture statiche C1.

Oracolo freddo aritmetico su interi/razionali, indipendente dagli helper
del prodotto. Byte letterali per 1.5 nelle tre larghezze, zero con entrambi
i segni, infinito, finiti solo32/solo64 e NaN. Tutti i 65.536 binary16 e
le espansioni esatte32/64; soglie normali/subnormali, adiacenti e payload
NaN allineati/non allineati. Offset multipli, capacita esatta/residua e
tutte quelle insufficienti, tipi/range, precedenza degli errori, destinazioni
non simple/displaced, arita esatta, sentinelle, riuso e concatenazione.
Fuzz 2.048 casi seed464C5434 e conteggi congelati. Decoder e scanner sono
soltanto controlli supplementari dopo il confronto freddo dei byte.

Due worker reali riusati, due ondate di 8.192 chiamate per worker,
destinazioni private e piani immutabili: 32.768 scritture. READY/GO/DONE
distinti per ondata, sink e intero buffer verificati, timeout/join/cleanup
limitati. Intervalli osservati senza inferenza di scaling o simultaneita
sui core. Parallelismo tra chiamate indipendenti.

## Misure, difetti e conservazione

Benchmark separato seriale: sei fixture congelate prima del prodotto,
che includono riduzione64→16,64→32,64 mantenuto, subnormale e NaN.
Cinque repliche ×4.096 chiamate, warmup128; NEXT e tutti i byte nel sink,
arita fredda esatta. Baseline nulla, controllo positivo16×1MiB; criterio
locale heap osservato zero, senza soglia di velocita o prova assoluta.

Otto mutazioni compilabili e uniche: riduzione32 omessa; riduzione64
omessa; segno16 perso; frazione normale16 errata; subnormale32 errato;
capacita fisica; lead float errato; arita extra. Catalogo congelato prima
della campagna, copie/cache private, baseline completa, smoke/fine esatti.
Compilazione, segnali e guasti worker non valgono come rilevamento;
si controllano ordine e origine del rifiuto runtime nei log completi.

Coverage grezza dei soli nuovi sorgenti, inventario completo delle
decisioni composte, senza escludere guardie/dichiarazioni o attestare
MC/DC. Due letture C1 con checklist12punti, self-test dei driver, letture
indipendenti dei dati, make check completo prima di push.

Strumenti Common Lisp (INV-X3), READ-EVAL NIL ed EOF per i dati;
sorgenti, indice e HEAD stabili durante ogni comando registrato.
Sorgenti, stdout/stderr, copie mutanti, fallimenti, misure e coverage
conservati con impronte e copie verificate. Nessuna promozione del gate C1
o del motore completo da queste prove locali.
