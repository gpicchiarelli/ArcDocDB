# Scrittura dei valori semplici CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-11, prima del corpus, del prodotto
e delle campagne. REQ-CBR-003 deriva da ADR-0014; ADR-0048 mantiene
il budget del documento al livello superiore.

## Contratto locale

```lisp
(scrivi-semplice-cbor-minimo buffer start end value)
;; => esattamente NEXT
```

BUFFER è un array simple u8 esclusivo; START/END sono index e delimitano
uno span half-open valido anche vuoto. VALUE è il codice wire del simple
value: integer 0..23 oppure 32..255. I codici 24..31 sono riservati e
rifiutati. Non è una conversione dei numeri, booleani o NIL di Common Lisp.
I codici 20/21/22/23 identificano false/true/null/undefined; ai codici
non assegnati non viene attribuita semantica applicativa.
Questo dominio e la rappresentazione unica sono definiti da
[RFC 8949 §3.3, tabelle 3/4](https://www.rfc-editor.org/rfc/rfc8949.html#section-3.3).
Il profilo applicativo, gli eventuali float e la composizione di documenti
rimangono al livello superiore.

0..23 usa un solo byte E0+VALUE; 32..255 usa F8 e VALUE. Non si emettono
F8 seguito da un codice sotto 32, float, AI28..30 o break. Si scrivono
al massimo due byte, senza payload, AST, stato condiviso, attese o I/O.

Preflight in ordine: destinazione/range (`invalid-argument :cbor-range`),
VALUE (`invalid-argument :cbor-simple-value`), capacità dello span
(`resource-exhausted :cbor-simple-capacity`). Tutti hanno offset NIL
e lasciano l'intero array fisico intatto. Il suffisso dopo END non è
capacità disponibile. Dopo il successo NEXT=START+dimensione e soltanto
`[START,NEXT)` cambia; prefisso, suffisso e residuo dello span restano intatti.
Le guardie interne segnalano invariant-violation senza rollback; il
proprietario applica fail-stop. Non è pubblicazione atomica o durevole.

## Corpus e misure congelati prima del prodotto

Un autore distinto prepara e congela le prove senza leggere il nuovo
prodotto; soltanto dopo si scrive il prodotto. Prima compilazione e
campagne seguono le due letture statiche e il congelamento di tutti i file.

Vettori letterali 0/19/20/21/22/23/32/255 e confronto aritmetico freddo
su tutti i 248 codici ammessi, con più offset, capacità esatta e residua.
Tutti gli otto codici riservati, tipi/range esterni invalidi, destinazioni
non simple u8, span vuoti, capacità 0..dimensione-1, priorità degli errori,
arità esatta, sentinelle, riuso e concatenazione. Fuzz 2.048 casi seed
53494D43, senza oracolo dipendente dal decoder; lettore minimo e scanner
sono controlli supplementari successivi al confronto dei byte.

Due worker reali riusati, due ondate di 8.192 item per worker: 32.768
scritture con destinazioni private, piani immutabili, sink e interi array
verificati. Attese, join e cleanup limitati. Intervalli osservati, senza
inferire scaling o simultaneità sui core.

Benchmark seriale su sei fixture 0/20/22/23/32/255, cinque repliche,
4.096 chiamate, warmup 128. Ogni invocazione verifica NEXT e tutti i byte,
inclusi quelli esterni. Baseline nulla, controllo positivo 16×1 MiB,
criterio locale heap osservato zero; nessuna soglia di velocità.

Otto mutazioni a sostituzione unica: codici riservati ammessi; soglia23
errata; major sbagliato; lead esteso sbagliato; capacità fisica; secondo
byte azzerato; NEXT errato; valore di ritorno extra. Copie e cache private,
baseline completa e marker non ambigui; errori di compilazione/worker
non valgono come rilevamento. Tutti i tentativi e le copie sono conservati.

Coverage grezza del solo file nuovo, inventario delle decisioni composte
senza esclusioni o attestazioni MC/DC/100%, due letture C1, self-test dei
driver, audit dei dati e `make check` completo prima del push. Strumenti
Common Lisp (INV-X3), sorgenti e index stabili durante ogni comando
registrato. Le prove locali non promuovono la qualifica del motore.
