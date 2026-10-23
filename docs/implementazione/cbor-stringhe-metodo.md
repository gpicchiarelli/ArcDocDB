# Scrittura delle stringhe CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-11, prima di scrivere il prodotto e
di compilare le nuove prove. REQ-CBR-002 deriva da ADR-0014 e ADR-0048.

## Contratto

```lisp
(scrivi-stringa-cbor-minima buffer start end major source source-start source-end
                          :max-bytes 16777216)
;; => esattamente NEXT
```

BUFFER e SOURCE sono array simple u8; entrambi gli span sono half-open,
anche vuoti. MAJOR è solamente 2 o 3. La funzione scrive una testata minima
seguita dalla copia esatta dei byte sorgente: la lunghezza del testo è in
byte, non in scalari. MT2 accetta qualsiasi byte; MT3 richiede UTF-8 valido.
NUL, BOM e noncaratteri restano ammessi, senza conversione da stringhe Lisp,
escaping, normalizzazione o sostituzione. Codifica definite-length secondo
[RFC 8949 §3.1 e §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-3.1).

MAX-BYTES è un index 0..16 MiB, default 16 MiB. Il budget include testata e
payload; con il massimo il payload arriva a 16.777.211 byte. Non sostituisce
la configurazione della Serie o il budget residuo del documento composito.
Usa il limite già definito nel codec, senza ampliare il dominio UTF-8.

Preflight in ordine: range destinazione (`invalid-argument :cbor-range`),
major (`:cbor-string-major`), range sorgente (`:cbor-string-source-range`),
tipo/limite budget (`:cbor-string-budget`), budget payload e poi item
(`resource-exhausted :cbor-string-byte-budget`), capacità
(`:cbor-string-capacity`), overlap (`invalid-argument :cbor-string-overlap`),
UTF-8. I primi errori hanno offset NIL; gli errori UTF-8 propagano classe,
motivo e offset assoluto nella sorgente. Ogni errore pubblico lascia intatti
entrambi gli array, prima di qualsiasi scrittura.

BUFFER è esclusivo e i byte SOURCE restano stabili fino al ritorno.
Lo stesso array è ammesso quando `[source-start,source-end)` è disgiunto
da `[start,NEXT)`, testata inclusa. Intervalli che si toccano e sorgente
vuota sono ammessi. La capacità fisica dopo END non conta; il resto del
buffer, compreso il residuo dello span, rimane invariato.

La copia è limitata dal budget; nessun thread, attesa, I/O, AST, stato
globale mutabile o scrittura condivisa tra Serie. Non è pubblicazione
atomica o durevole. Le guardie interne segnalano invariant-violation:
il proprietario applica fail-stop, senza rollback interno.

## Prove congelate prima del prodotto

Corpus cieco con testata calcolata aritmeticamente e payload indipendente:
vuoti e soglie 23/24, 255/256, 65535/65536; payload MT2 arbitrari e MT3
ASCII, scalari multibyte, NUL/BOM/noncaratteri. Tutte le lunghezze 0..4096
per entrambi i major e fuzz 2048 con seme fisso. Errori di argomenti,
precedenze, capacità 0..size-1, budget che include la testata, massimo
16 MiB e massimo+1, alias per entrambi gli ordini, confini toccanti,
overlap della sola testata e input UTF-8 malformati con offset sorgente.
Arity esatta, sentinelle e riuso; scanner minimo soltanto come round-trip
supplementare, mai come oracolo dei byte.

Due worker riusati con destinazioni private, sorgente immutabile condivisa,
semafori/join/cleanup limitati e sink verificati. Si verifica concorrenza
funzionale, senza conclusioni su scaling o simultaneità sui core.

Misure seriali separate: fixture indipendenti MT2/3, quattro soglie e
UTF-8 multibyte, cinque repliche, 4096 chiamate, warmup 128. Baseline nulla,
controllo positivo 16×1 MiB, verifica di NEXT e di tutti i byte inclusa
nelle chiamate; criterio locale heap osservato zero, nessuna soglia di
velocità. Otto mutazioni a sostituzione unica in copie/cache private:
major errato; length scalari anziché byte; copia off-by-one; origine copia
errata; budget senza testata; capacità fisica; overlap che ignora testata;
verifica UTF-8 saltata. Baseline completa, marker esatti; errori di
compilazione/worker non contano come rilevamenti. Ogni tentativo conservato.

Due letture C1, inventario delle decisioni composte, coverage grezza del
nuovo file senza esclusioni o attestazioni MC/DC/100%. Driver con self-test
e audit dei dati; `make check` completo prima del push. Strumenti Common
Lisp (INV-X3), sorgenti stabili durante ogni processo registrato. Si
preservano i log originali e le campagne delle dipendenze, senza promuovere
la qualifica del documento completo o del motore.
