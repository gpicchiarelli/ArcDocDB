# Float CBOR — lettura dei dati di coverage e audit benchmark

Questa pagina pubblica la [lettura originale archiviata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-cbor-float-write/raw/readings/coverage-review-draft.md.txt),
congelata con Git blob `7c8d22854d345aafae3c5fe6ba12977d5e0abb0f`.
Il testo seguente è conservato integralmente, senza adattamenti dei percorsi
o dei riferimenti storici. I [risultati finali](cbor-float-scrittura-risultati.md)
presentano l'esito complessivo della campagna e la conservazione degli archivi.


Lettura del 2026-10-13 su sorgenti congelati, senza LOAD di prodotto,
driver, auditor o helper di dati. I rapporti, lo stato SB-COVER e i sorgenti
sono stati letti come dati con READ-EVAL NIL, readtable standard,
CL-USER ed EOF; i sorgenti non sono stati eseguiti. Per leggere i simboli
qualificati delle condizioni è stato creato soltanto un package vuoto.
L'helper della campagna precedente è stato studiato staticamente.

Questa lettura ha autore distinto dal prodotto e dal corpus. Lo stesso
autore ha però scritto `tools/cbor-float-write-audit.lisp`: la lettura
del risultato di quel programma non è una revisione indipendente del
proprio codice. Il coordinatore ha letto il codice C4 completo separatamente.

## Identità e registri

- Narrow: Git blob `cd5749edc0a757ee3a5b470eda566a6685d32fd8`.
- Write: Git blob `03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c`.
- Auditor benchmark: Git blob `485544868eeadff247968b86c2d5da9b3b610295`.
- Coverage: `spikes/out/4000905717-command-32850-0/report.lisp`, comando
  `foundation-coverage --report .../coverage/ cbor-float-write`.
- Audit benchmark: `spikes/out/4000905717-command-32851-0/report.lisp`,
  `--bench` sul record `4000905677-command-32530-0/report.lisp`, con
  entrambi i Git blob del prodotto passati esplicitamente.

I due registri richiesti e il benchmark originale sono OK, exit 0,
source-consistency STABLE; ciascuno dichiara 738 voci nello snapshot
prima/dopo, confrontate uguali. Il benchmark interno dichiara 167 voci
MD5 prima/dopo, uguali. Non si inferisce completezza di inventario o
autenticità da questi metadata. I Git blob selezionati nel registro
dell'audit corrispondono ai tre valori sopra.

## Conteggi di coverage

Lo stato contiene 274 file salvati. Sono presenti esattamente una entry
per ciascuno dei due nuovi percorsi assoluti. I vettori dei path e i
bit-vector hanno la stessa lunghezza; i path espressione iniziano con
numero, quelli dei rami con keyword, e i bit osservati sono 0/1.

| Sorgente | Espressioni coperte/totali | Esiti di ramo coperti/totali | Espressioni mancanti | Esiti mancanti |
|---|---:|---:|---:|---:|
| cbor-float-narrow.lisp | 175/220 | 26/36 | 45 | 10 |
| cbor-float-write.lisp | 190/220 | 35/40 | 30 | 5 |
| Totale | 365/440 | 61/76 | 75 | 15 |

I conteggi sono ricavati dai bit raw e coincidono sia con l'indice HTML
sia con i due riepiloghi HTML dei sorgenti. L'inventario HTML è esattamente
`cover-index.html`, `23a33ec5ac2b59d1b9d7819bf40c11d1.html` e
`8cf55e316599aaec35dd1fc1f1566797.html`.
Il parser delle righe rispetta la chiusura implicita TR di SB-COVER:
quando il TR successivo precede un tag di chiusura, chiude la riga
precedente. Non fonde la riga intestazione con quella successiva.

La classificazione associa sintatticamente i path raw alle forme lette,
invertendo i path SB-COVER e togliendo THEN/ELSE per localizzare il
predicato. Non dimostra irraggiungibilità o copertura delle condizioni.

| Categoria espressioni mancanti | Narrow | Write | Totale |
|---|---:|---:|---:|
| Dichiarazioni top-level | 5 | 6 | 11 |
| Nodi delle forme ERROR interne | 40 | 24 | 64 |
| Altre espressioni | 0 | 0 | 0 |

I path dichiarazione raw sono `(0) (1) (2) (4) (6)` in narrow e
`(0) (1) (2) (4) (6) (8)` in write. Ciascuna delle sedici forme ERROR
interne sotto contribuisce quattro nodi espressione mancanti; nessuna
forma viene sottratta dal denominatore.

| File | Motivo della forma ERROR | Riga ERROR | Esiti mancanti associati direttamente |
|---|---|---:|---:|
| narrow | :cbor-float32-narrow-input | 15 | 1 |
| narrow | :cbor-float32-narrow-exponent | 24 | 0, più fallback descritto sotto |
| narrow | :cbor-float32-narrow-sign | 30 | 1 |
| narrow | :cbor-float64-narrow-significand | 42 | 1 |
| narrow | :cbor-float64-narrow-alignment | 44 | 1 |
| narrow | :cbor-float64-narrow-high | 50 | 1 |
| narrow | :cbor-float64-narrow-low | 54 | 1 |
| narrow | :cbor-float64-narrow-input | 64 | 1 |
| narrow | :cbor-float64-narrow-exponent | 75 | 0, più fallback descritto sotto |
| narrow | :cbor-float64-narrow-sign | 80 | 1 |
| write | :cbor-float-write-span | 21 | 1 |
| write | :cbor-float-write-ai | 39 | 0 |
| write | :cbor-float-selection-input | 52 | 1 |
| write | :cbor-float-selection-output | 60 | 1 |
| write | :cbor-float-write-target-span | 82 | 1 |
| write | :cbor-float-write-progress | 89 | 1 |

La ricerca legacy per sola sottostringa del REASON colloca erroneamente
`:cbor-float64-narrow-sign` sulla prima occorrenza di `...-significand`.
Il path esatto `(7 5 3 2)` delle forme forward e il sorgente letto
identificano invece la riga 80. Conteggi e associazione alla forma ERROR
non cambiano; la riga è stata corretta leggendo il sito esatto.

Per i rami, l'associazione diretta dà otto guardie interne narrow e
cinque write. I due restanti path raw narrow sono:

- `(:ELSE 0 4 1 3 1 5 3)` → `(3 5 1 3 1 4 0)`, falso del predicato
  finale `(<= 103 exponent 112)` alla riga 22, seguito dal fallback
  `:cbor-float32-narrow-exponent` alla riga 24.
- `(:ELSE 0 4 1 3 1 5 7)` → `(7 5 1 3 1 4 0)`, falso del predicato
  finale `(<= 874 exponent 896)` alla riga 72, seguito dal fallback
  `:cbor-float64-narrow-exponent` alla riga 75.

Questi due esiti risultano `:other` per il matcher del prefisso del
genitore ERROR: il predicato precedente non è figlio del ramo `t`.
Il sito è identificato esplicitamente, senza reinterpretare i due
esiti come coperti o eliminarli. In totale restano tredici esiti di
guardia direttamente associati e due fallback numerici, quindici mancanti.
Nessun claim MC/DC, gate C1 o dimostrazione di irraggiungibilità.

## Log della campagna di coverage

Il registro 32850 conserva stdout completo con 18 test riusciti, incluso:
65.536 half e 131.072 espansioni, 196.608 successi e altrettanti rifiuti
di capacità; fuzz 2.048 casi con 768 successi, 256 capacità, 128 AI,
128 HIGH, 128 LOW, 256 parole e 384 range/destinazioni; due ondate
di 16.384 item ciascuna su due worker riusati. Sink osservati per ondata
2.115.584/2.148.352; overlap 2.733/2.719 tick con 1.000.000 tick/s.
Questi intervalli non provano scaling o esecuzione simultanea sui core.

## Risultato dell'audit benchmark

Il rapporto dati dell'auditor riporta OK e 55.824 controlli, sei fixture,
trenta campioni con heap osservato zero e arità fredda uno. L'osservazione
before/after del benchmark originale è uguale e coincide con byte/hash
del file osservato in questa lettura: 198.507 byte, SHA256 `1154975a…`.
Non è una firma o attestazione dell'esecuzione dichiarata.

È stato letto anche il benchmark originale: sei fixture nell'ordine
congelato, cinque repliche ciascuna, 4.096 chiamate e warmup 128,
byte attesi e cold-values conformi ai vettori preregistrati.

| Fixture | NEXT | Token |
|---|---:|---:|
| half-identity | 5 | 6.445 |
| double-to-half | 5 | 6.445 |
| double-to-single | 7 | 8.421 |
| double-only | 11 | 11.632 |
| double-to-half-subnormal | 5 | 6.202 |
| double-nan-payload | 11 | 12.440 |

La somma dei secondi dei trenta campioni è 0,033414; il processo
benchmark ha wall 1,416727 secondi. Il rapporto dell'auditor riporta
0,000068 secondi per i due controlli, baseline heap zero e controllo
positivo 16.777.472 byte. Non sono soglie di prestazione, prova assoluta
di non allocazione, throughput del motore o misura di scaling.
MD5 interni e Git blob esterni rimangono metadata dichiarati distinti,
senza un legame autenticato fra loro. La verifica dei grafi dell'auditor
attraversa cons, non vettori generali con ulteriori cons/cicli.

## Osservazioni dei byte prima/dopo

Nove file sono stati osservati prima e dopo il confronto HTML/raw:
nome, dimensione e SHA256 identici. I valori riguardano i byte fisici
attuali, prima di eventuali successive compressioni lossless.

| File | Byte | SHA256 |
|---|---:|---|
| 32850/report.lisp | 155106 | `183c3eb8273d8ad4f3348df9dfd3d6d09afeab74c7bc097e56119297c2d5ae24` |
| 32851/report.lisp | 154777 | `a648824ca0f0ec2c3520cfa885dc6a9f6909f723fafc0e6e0b364b7a4d9cce61` |
| 32530/report.lisp | 198507 | `1154975a7c27c433d402c7b7549a62fb321b1e43fb806f5def86dd8825bfceb6` |
| coverage-state.lisp | 1991414 | `e6d67d0e7c452205c2531375b68ec584740e47d6e45302ebdaef1f5d730a54f4` |
| cover-index.html | 1956 | `0fd3fda477a1b039a03ce29a359c15b65fe2ad188b1c7a598068317294cc58bd` |
| 23a33ec5ac2b59d1b9d7819bf40c11d1.html | 30109 | `287ed54697c0e8f92596c28f3678cce462fad6ca82aedfec4f4ac8a95392b64a` |
| 8cf55e316599aaec35dd1fc1f1566797.html | 31681 | `c85c97a0932b23fc93d328958117d6b45ca160ba8ac47e9d8168f584b5b6d7e8` |
| cbor-float-narrow.lisp | 4546 | `479754d83cd9f11e53f7c1a4c81986a9be4327e3b1040dde0314ee29c2f87cbb` |
| cbor-float-write.lisp | 5083 | `28ff27ac1f077477f92d5932ae3c76ab319356c3b4b070aee1cd168cbdce1442` |

Prima/dopo non significa osservazione atomica dell'intero insieme.
L'archivio chiuso e la relativa verifica restano attività del coordinatore.

## Tentativi del lettore analitico

Tre tentativi ad hoc del codice di lettura via stdin sono falliti:
il primo aveva una parentesi mancante e un GETF usato con un posto
SETF basato su IF; il secondo usava invertiti gli argomenti del
predicato UIOP per i suffissi; un successivo controllo benchmark aveva
una parentesi mancante. Sono stati corretti. La lettura dei path raw,
il confronto completo HTML/raw con nove osservazioni immutate e
la lettura del benchmark/audit sono poi terminati con exit 0.
I messaggi sono osservazioni di questa sessione, non registri completi
di comandi preservati, né risultati di campagne del prodotto. Le
campagne qui lette rimangono OK/0/STABLE; nessun dato di input è stato
riscritto e nessun file tracked è stato modificato per questa lettura.
