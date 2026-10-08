# SPK-10 — metodo CBOR

Registrato prima della compilazione e dell'esecuzione del modulo `cbor.lisp`.
Ambito assegnato: esclusivamente questo metodo e il modulo sperimentale, fuori da
`src/`. Requisiti esercitati: REQ-LIM-002, REQ-AFF-008, REQ-SIM-002.

## Domanda e fonti

Il validatore può applicare i limiti di ADR-0048 senza ricorsione sullo stack
nativo, senza allocazioni proporzionali a lunghezze dichiarate nell'input e
attraversando sia le chiavi sia i valori delle mappe?

Fonti del repository: `AGENTS.md`, ADR-0014, ADR-0027, ADR-0048,
`docs/invarianti.md`, `docs/affidabilita/standard-di-codifica.md` e registro
dei requisiti. ADR-0014 richiede CBOR deterministico ma non sceglie esplicitamente
fra i due ordinamenti descritti da RFC 8949.

> **Proposta** — per questo esperimento si usa il profilo core deterministic di
> [RFC 8949 §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1):
> argomenti minimi, lunghezze definite, chiavi in ordine lessicografico dei byte
> della codifica. Non si usa l'ordinamento alternativo length-first (§4.2.3).
> Le chiavi duplicate sono rifiutate (§5.6.1). Il confronto fra codifiche è
> sufficiente nel sottoinsieme ammesso, in cui ogni valore ha una codifica unica;
> sono ammesse anche chiavi array e mappa, validate prima del confronto.

> **Proposta** — il sottoinsieme comprende interi positivi e negativi fino ai
> limiti dei major type 0/1, stringhe binarie, testo UTF-8, array, mappe,
> booleani e null. Floating point, tutti i tag e altri simple value producono
> `:unsupported`. Non si dichiara validazione completa del CBOR di ADR-0014.
> Un tag consuma un nodo, non un livello di contenitore, prima del rifiuto;
> non si attraversa il suo contenuto e non si deduce che la sua semantica sia valida.

## Algoritmo e risorse

Una macchina iterativa mantiene una pila preallocata di contenitori, con
conteggi residui, offset della codifica e della chiave precedente. La mappa
conta due figli per coppia. Un array/mappa radice è livello 1; scalari livello 0.
Si completano gli antenati iterativamente quando si esauriscono i figli.
Le stringhe non sono copiate né decodificate in oggetti Lisp. UTF-8 è controllato
per byte, inclusi overlong, surrogate, continuazioni e limite U+10FFFF.

Prima di creare la pila o leggere l'input si controllano tipo, configurazione,
dimensione effettiva del buffer, limite documentale e budget dei byte. Lunghezze
e conteggi sono controllati rispetto ai byte residui e al budget dei nodi;
non determinano allocazioni. L'header legge al massimo otto byte di argomento.
La pila è O(limite-profondita), al massimo 100 frame. Nessuno stato condiviso,
lock, I/O o scrittura durevole: la sola sequenza seriale è il percorso di un documento.
Il chiamante deve mantenere immutabile il buffer durante la validazione.

Il budget byte è un limite sui byte codificati in input, distinto dal limite
documentale e dal budget nodi. Il confronto delle chiavi può rileggere byte:
il suo lavoro è limitato dalla dimensione dei due span, ripetuto al più per
ogni coppia adiacente di chiavi e ogni contenitore (tetto profondità 100).
Non è un budget sul numero totale di accessi alla memoria.

## API prevista

Package indipendente `arcdocdb.spk10.cbor`; dipendenze solo Common Lisp/SBCL.
`valida-documento` riceve un `simple-array (unsigned-byte 8) (*)` e keyword
`:limite-documento` (default 16.777.216), `:limite-profondita` (100),
`:budget-nodi` (16.777.216), `:budget-byte` (16.777.216).
I limiti possono essere ridotti; budget nulli rifiutano il lavoro pertinente,
budget negativi/non interi sono errori di configurazione. Profondità zero
ammette solo scalari. Si restituisce una plist con `:status :ok`, conteggi,
limiti applicati e ambito `:partial`. Gli errori sono `errore-cbor`, con
ragione keyword, posizione e contatori accessibili pubblicamente.

`check` restituisce una plist `:status :ok` con conteggi delle fixture, mutazioni
e limiti effettivi. `benchmark` restituisce una plist; parametro `:seconds`,
default 2,5 secondi, parametro ammesso 0–3 secondi, sei finestre e al massimo
100.000 iterazioni per finestra. Le fixture sono costruite prima delle finestre;
il clock si controlla prima di ogni chiamata, quindi una chiamata iniziata
può completarsi oltre la scadenza. Il tempo non è una garanzia di correttezza.
Il benchmark misura validazione, non decodifica in oggetti; il payload di una
stringa binaria viene saltato dopo il controllo della lunghezza. Il throughput
è calcolato sui byte della codifica, non sui byte di payload effettivamente letti.
I sei casi sono binario 1 KiB, testo 1 KiB, binario 16 MiB, testo 64 KiB,
100 livelli e un array con 4096 figli. Non è stato eseguito un benchmark locale.

La condizione pubblica è `errore-cbor`; gli accessor esportati sono `ragione`,
`posizione`, `nodi`, `profondita`, `tag-letti`. Ragioni: `:invalid-buffer`,
`:invalid-limit`, `:invalid-budget`, `:document-limit`, `:byte-budget`,
`:node-budget`, `:depth-limit`, `:truncated`, `:trailing-data`, `:nonminimal`,
`:indefinite`, `:reserved`, `:utf8`, `:duplicate-key`, `:key-order`,
`:malformed-simple`, `:unsupported`, `:internal-invariant`. Il benchmark
rifiuta parametri fuori contratto con `:invalid-benchmark-budget`.
È dichiarato il primo difetto incontrato: un duplicato in una mappa già fuori
ordine può produrre `:key-order`. Tutti i rifiuti precedenti alla lettura hanno
posizione, nodi e profondità zero.

## Controlli pianificati

Compilazione isolata con `safety 3`, warning e style-warning fatali, controllo
dei tre valori di `compile-file`, caricamento del FASL e chiamata a `check`.
FASL temporaneo fuori dal repository. Nessun benchmark lungo: le misure
comparative dei moduli appartengono al runner parent, che li carica nell'ordine
codec, index, cbor, migration dopo il CRC di SPK-09.

Fixture con aspettative indipendenti dal parser:

- radice array/mappa, annidamento 100 accettato e 101 rifiutato, anche nelle
  chiavi e nei valori delle mappe; completamento di fratelli e antenati;
- codifica binaria di esattamente 16 MiB accettata e 16 MiB + 1 rifiutata
  prima di attraversare l'input, verificabile dai contatori della condizione;
- conteggi array/mappa e lunghezze enormi con buffer piccolo, troncamenti
  degli header e payload, input vuoto, byte aggiuntivi, forme indefinite;
- interi/lunghezze minimi, ordinamento core distinto da length-first,
  duplicati scalari e composti, UTF-8 valido e invalido;
- budget esatto, insufficiente, zero e negativo; parametri non validi;
- mutazioni con semi fissi e numero finito: trasformazioni di fixture che
  conservano validità o inseriscono un difetto noto, con esito atteso
  dichiarato senza usare il parser come oracolo.

Obiettivi locali: `check` entro 5 secondi e array vivi inferiori a 128 MiB.
Questi sono budget dell'esperimento, non garanzie temporali del motore.
La verifica non prova accettazione sicura di qualsiasi input e non completa
il gate v2. Nessuna modifica dei requisiti o dei documenti condivisi.

## Ambiente e risultato

Ambiente di preparazione: SBCL 2.6.9, macOS, eseguibile
`/opt/homebrew/bin/sbcl`.

Compilazione stretta locale: `safety 3`, zero warning/style-warning,
`compile-file` con valori avvisi/fallimento entrambi `nil`, FASL caricato.
Solo le note di ottimizzazione di SBCL vengono silenziate: il loro conteggio
è registrato nell'artefatto; warning e style-warning restano fatali.

`check` locale: **614 casi**, di cui 68 fixture esplicite (21 valide,
47 rifiutate), 12 casi di profondità, 19 di budget/configurazione, 3 di
dimensione e 512 mutazioni (128 valide, 384 rifiutate). Le catene di sole
mappe controllano annidamento nelle chiavi e nei valori. Entrambi i buffer
di confine sono stringhe binarie CBOR con lunghezza definita e testata minima:
16.777.216 byte (payload 16.777.211) e 16.777.217 byte (payload 16.777.212).
Il secondo viene rifiutato prima del parser con contatori zero.
I due buffer grandi occupano insieme 33.554.433 byte di elementi; nessun
altro array dell'esperimento supera 100 frame o pochi KiB durante `check`.
Il tempo locale preliminare del controllo è stato circa 0,011 s; il valore
esatto dell'esecuzione registrata e l'ambiente effettivo sono nell'artefatto.

La prova strutturata è [v2-cbor-check.lisp](../results/2026-10-08/v2-cbor-check.lisp),
copia invariata del report locale `out/cbor-check.lisp`. È una sola plist con schema 1,
`:command` (argv e sorgente stdin), `:environment`, `:source-blobs`
(blob Git dei due file assegnati), `:compile-status`, `:result`, `:limits`,
`:time`, `:stdout`, `:stderr` e `:failures`. Si registra anche un fallimento
al confine del runner. Il runner verifica la rilettura con `*read-eval* nil`.
Il comando completo riproducibile è conservato nell'artefatto; il FASL è in
`/tmp/arcdocdb-spk10-cbor.fasl`. Le verifiche precedenti durante lo sviluppo
non sono benchmark né evidenze di completamento del gate.

Limiti ancora aperti: floating point, semantica/canonicalizzazione dei tag,
eventuali equivalenze delle chiavi definite dall'applicazione e integrazione
prima del writer. Il profilo core scelto qui è una proposta locale: il
progetto deve confermarlo per il codec completo. Il check locale non chiude
il gate v2 né promuove i requisiti del motore a verificati. La pubblicazione
dell'evidenza integrata versionata spetta al parent.
