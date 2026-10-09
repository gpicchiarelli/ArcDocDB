# Testate CBOR minime — contratto e metodo

Ambito fissato prima delle campagne: completamento locale delle testate di
ADR-0014 e ADR-0048, classe C1. Non cambia il profilo documentale: ordinamento
delle mappe, equivalenza delle chiavi e semantica dei tag restano separati.

## Contratto

`arcdocdb.cbor:leggi-header-cbor-minimo(buffer, start, end)` restituisce
esattamente i sei valori del lettore sintattico: major, AI, high u32, low u32,
next, `:argument`. Il buffer simple u8 resta immutabile; lo span è half-open.
Non legge payload né figli. Argomenti u64 e float rimangono parole, senza
materializzare interi u64, float, AST o copie. Nessuno stato, scratch, lock,
attesa o I/O; chiamate indipendenti utilizzabili dai worker di calcolo.

Prima viene eseguito `leggi-header-cbor`: range, riservati, troncatura, simple
value illegali e AI31 illegali conservano tipo, motivo, offset e precedenza.
Solo dopo una testata sintatticamente completa il nuovo controllo segnala
`corruption-detected :cbor-nonminimal` all'offset START:

- lunghezza indefinita o break, anche senza corpo;
- major 0–6 con argomento rappresentabile in meno byte: AI24 richiede almeno
  24; AI25 almeno 256; AI26 almeno 65536; AI27 high diverso da zero;
- binary32 rappresentabile esattamente in binary16, binary64 rappresentabile
  esattamente in binary32. Ogni binary16 è già della larghezza minima.

Simple value sintatticamente ammessi sono accettati. Float e interi rimangono
tipi distinti. Segno di zero e infinito sono preservati; NaN si confrontano
per significando con zero-padding a destra, preservando segno e payload,
senza imporre una singola codifica NaN. Questa è la regola locale di
[RFC 8949 §4.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.1),
usata anche dal core deterministic di
[§4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1).
Il controllo non attesta determinismo dell'intero item né validità dei tag.

## Prove fissate

Oracolo indipendente aritmetico su interi/razionali nei test, senza helper
del prodotto. Vettori RFC, tutti i 65536 binary16 e loro espansioni esatte
binary32/binary64; tutte le soglie di larghezza dei major 0–6; zero con
entrambi i segni, infinito, NaN con payload accorciabile e non accorciabile;
minimi e massimi normali/subnormali e adiacenti; tutti i lead, troncature,
range e precedenze, sentinelle e sei valori esatti. Fuzz finito con seme e
conteggi registrati. Due worker effettivi con input privato e timeout:
nessuna deduzione di scaling o simultaneità sui core dal tempo reale.

Due letture C1 del diff con checklist a 12 punti, inventario delle decisioni
composte e copertura grezza `sb-cover` sui nuovi file, conservando stato e
HTML. Mancanze dichiarate, senza trasformare copertura in prova MC/DC.
Mutazioni: almeno otto difetti compilabili, conteggio fissato nel driver
prima della campagna; baseline completa e marker esatti di smoke/fine;
fallimenti di compilazione o infrastruttura non contano come rilevamento.
Obiettivo locale: tutti rilevati, sopravvissuti analizzati.

Allocazioni misurate in processo distinto, seriale, input preallocati,
safety 3, warmup 128, cinque repliche da 4096 chiamate per fixture minima
intera, float finito, subnormale e NaN. Sei valori controllati nel sink;
baseline nulla e controllo positivo 16 × 1 MiB. Heap osservato zero è
criterio locale, senza soglia di velocità o prova assoluta di nonallocazione.
`make check` completo richiesto prima di integrazione e push.

Registri, stdout/stderr, codice degli strumenti, copie di mutazione e dati
grezzi vengono conservati anche in caso di errore. Strumenti e lettori
trattano i rapporti come dati con read-eval NIL, senza load/eval esterni.
