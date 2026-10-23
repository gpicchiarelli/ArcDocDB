# Primo item CBOR minimo — contratto e metodo

Incremento C1 preregistrato il 2026-10-15, prima del nuovo corpus,
del prodotto e delle campagne. REQ-CBR-008 deriva da ADR-0014 e
ADR-0048: lettura strutturale bounded senza AST né copie.
Riferimento: [RFC 8949 §3](https://www.rfc-editor.org/rfc/rfc8949.html#section-3).

## Contratto locale

```lisp
(leggi-item-cbor-minimo buffer start end space
 :max-bytes 16777216 :max-nodes 16777216 :max-depth 100)
;; => esattamente NODES, PEAK, NEXT
```

Verifica il primo item strutturale minimo nella finestra [START,END).
NODES include tag e radice; PEAK conta soltanto array/map; NEXT è
l'offset assoluto dopo l'item, START<NEXT<=END. La coda [NEXT,END)
non viene letta, validata o inclusa nelle statistiche. Esempi:
00 FF → 1,0,1; 81 00 1C → 2,1,2; C0 81 00 FF → 3,1,3.
Gli scanner esatti conservano l'obbligo di EOF e :cbor-trailing.

MAX-BYTES limita l'intera finestra autorizzata END-START, compresa
la coda; non soltanto i byte del primo item. Una finestra più grande
del budget è rifiutata anche se comincia con uno scalare valido.
Limiti identici allo scanner: byte0..16MiB, nodi1..16MiB, depth0..100.
Il chiamante restringe END al proprio budget prima della chiamata.

BUFFER simple u8 resta immutabile ed è condivisibile in lettura;
SPACE è privato della chiamata/worker, mai condiviso simultaneamente.
Ordine del preflight invariato: range, workspace, alias KINDS, limiti
byte/nodi/depth, byte-budget; offset NIL e scratch immutato.
Reset soltanto dopo il preflight. Span vuoto e header/payload troncati
producono :cbor-truncated all'END autorizzato. Header sintattico e
minimalità precedono contesto e budget di nodi/depth; UTF8 restituisce
gli offset assoluti esistenti. Dopo errore runtime lo scratch può essere
sporco, ma è riusabile al reset successivo. Nessun risultato parziale.

Si riusano preflight, passo e stack fissi esistenti. Il drain riceve
il cursore corrente per riconoscere la radice completata senza
richiedere EOF dell'intera finestra. Il risultato verifica radice,
conteggi e fine al cursore corrente. Al più SPAN passi, ciascuno con
drain limitato a102frame; progresso verificato. Nessuna semantica tag,
ordine/deduplica mappe, normalizzazione o profilo documentale
deterministico; nessuna attesa, I/O, thread o stato globale nel prodotto.

## Corpus indipendente e letture

Un autore distinto congela test e oracoli prima del prodotto.
Vettori letterali MT0..7 con coda valida/malformata/nonminima,
tag, UTF8 e contenitori; scansione concatenata per ricavare frontiere.
Precedenze complete, arità tre, buffer/scratch immutati nel preflight,
riuso dopo errore, confini parole/lunghezze, byte16MiB/+1,
nodi e depth0/100/101, catene di tag. Scanner esatto e roundtrip
soltanto come controlli aggiuntivi; nessun writer come oracolo primario.
Fuzz1024 con seme e distribuzione congelati nel piano del corpus.

Due worker reali riusati, due ondate di2048 chiamate ciascuno:
8192 letture con buffer condiviso read-only e scratch privati,
READY/GO/DONE, sink, timeout e cleanup limitati. Nessuna inferenza
di scaling o simultaneità sui core. Due letture C1 con checklist12
punti e inventario delle decisioni precedono la prima compilazione.

## Campagne e conservazione

Sei fixture benchmark fredde con coda non validata, cinque repliche
da1024 chiamate e warmup64. Tutti i tre valori e il buffer/scratch
nel controllo; baseline nulla e positivo16x1MiB. Criterio locale:
zero heap osservato, nessuna soglia di velocità.

Otto mutanti compilabili a sostituzione unica: scansione generica,
drain su END fisico, NEXT=END, budget nodi ignorato, depth ignorata,
byte-budget ignorato, START saltato e arità extra. Catalogo
materializzato prima delle campagne, copie/cache private e baseline
completa. Rilevamento solo con smoke esatto e test nominale congelato
nella traccia, exit1 e segnale NIL. Warning, compilefail, helper,
segnali o guasti dopo completamento non contano.

Driver congelati, self-test, copertura grezza del solo nuovo sorgente
senza esclusioni, letture DATA indipendenti e make check prima del
push. Strumenti Common Lisp, READ-EVAL NIL/EOF; sorgenti/indice/HEAD
stabili nei comandi registrati. Originali e preparazioni preservati;
raccolta con quattro worker e inventario chiuso verificato.
REQ-LIM-001/002 e qualifica C1/MC/DC restano aperti.

