# Metodo del collegamento pool/Serie

Preregistrazione del 2026-10-13, base
`14fd7738c216e3a0bd3ce9612576b9b57d648f74`, prima delle campagne formali.
Scope C3 completo: `src/dispatch/package.lisp`, `types.lisp`, `build.lisp`
e `claim.lisp`. Il [contratto](pool-dispatch.md) definisce i due ingressi.
Nessun sorgente C1 viene modificato; si riusano claim, routing e bridge
con le loro verifiche e barriere originali.

## Prove e lettura indipendente

- Tipi e binding nella factory, owner verificato prima della tabella;
  preimage di porta, contesto, ready e writer su rifiuto.
- Porta/tabella di contesti differenti: rifiuto prima di ACK/claim, anche
  con una richiesta di attivazione pendente e lavoro pronto.
- INACTIVE, EMPTY e BUSY: quattro risultati originali e nessun routing.
  Le sentinelle FI sono quiescenti, temporanee e ripristinate.
- Writer realmente pronto, scelta per ordinale e begin esplicito della
  doppia lease; pop, conferma e fine attraverso il bridge esistente.
- CLAIMED conservato, ritiro pendente e parole pool invalide: lookup del
  solo obbligo, nessuna conferma e completamento consentito.
- Ricircolo full con nuovo writer: routing ripetuto sul nuovo obbligo;
  dopo IDLE il ritiro impedisce una nuova presa.
- Attivazione valida e claim reale seguiti da routing sconosciuto:
  ACK conservato, worker FAULTED con riferimento/home e causa originale,
  nessuna acquisizione o mutazione del controller.
- Fasi errate e owner estraneo: diagnosi, debito e lease conservati.
- Ritorni del gate incoerenti vengono iniettati separatamente dalla
  normale esecuzione per verificare le difese del confine C3. Un status
  fuori dal dominio ftype non viene presentato come ritorno nominale.
- Una lettura indipendente C3 con lista di controllo, safety 3,
  compilazione senza warning/style-warning, lint e tracciabilità.

## Copertura e memoria

Gate C3 almeno 95% di espressioni e rami sull'intero scope, senza esclusioni
manuali. Conservare native SB-COVER, HTML e audit con denominatori, percorsi
mancanti e impronte esatte. Confrontare i conteggi interi native/HTML;
nessuna inferenza MC/DC e nessuna copertura C1 ereditata nel denominatore.
Il reader verificato resta invariato, l'adattatore dichiara heading e scope
dispatch e verifica file/shape/missing paths con casi negativi.

Il sensore C4 riusa campionamento e conservazione lifecycle già verificati,
con self-test dedicati. Cinque repliche da 4096 cicli e 128 cicli di warmup
per campagna, factory/API lookup/GC fuori clock, nessuna taratura.

| Campagna | Ciclo |
|---|---|
| EMPTY | Quattro nuove prese su quattro shard vuoti, cursori 1/2/3/0, NIL e azione invariata. |
| INACTIVE | Quattro nuove prese, cursore 2 invariato, NIL e nessun routing. |
| ROUTE-CURRENT | Quattro selezioni del link preallocato su un CLAIMED stabile, senza begin/pop o nuovi obblighi. |

Tutti i valori e le identità contribuiscono all'oracolo del ciclo.
Conservare heap, tick, sink e cicli completati; heap zero osservato non
dimostra assenza universale di allocazione. Carico esterno incontrollato,
nessuna conclusione sul throughput del motore. Il sensore deve rilevare
allocazione deliberata, sink errato, ritorni difformi e clock sotto risoluzione,
conservando output parziali e destinazioni esistenti.

Le campagne formali usano una copia congelata e `record-command.lisp`,
con cache dedicate, argv, stdout/stderr, exit e identità iniziali/finali.
Fallimenti rimangono tali, raw preliminari restano separati. Le copie
pubblicate sono verificate byte per byte e i nuovi manifesti non sostituiscono
gli originali. Il controllo completo include i dieci spike esistenti.
