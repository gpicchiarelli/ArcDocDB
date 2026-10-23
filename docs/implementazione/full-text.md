# Nucleo full text

Implementazione autorizzata dall'autore il 16 ottobre 2026, secondo
[ADR-0053](../adr/0053-ricerca-full-text-indici-invertiti.md) e
[ADR-0054](../adr/0054-contratto-e-formato-full-text.md).
Sono disponibili analizzatore Unicode, run invertito posizionale in memoria e
cornice binaria dell'indice. Il successivo [codec completo](full-text-codec.md) aggiunge
serializzazione delle sezioni e query su viste verificate. La ricerca su una Serie con commit, snapshot,
catalogo delle generazioni e persistenza completa rimane da integrare.
REQ-SEC-003…REQ-SEC-010 restano **progettati** nel loro perimetro complessivo.

| Componente di prodotto | Disponibile | Confine |
|---|---|---|
| `arcdocdb.fulltext.analysis` | UTF-8 rigoroso, NFC, full case fold, NFC, Word_Break e filtro L/N | Un campo scalare alla volta; estrazione dei percorsi CBOR successiva |
| `arcdocdb.fulltext.index` | Run ordinato per campo/termine/riga/posizione; `all`, `any`, frase | La riga identifica una versione locale, non certifica commit o visibilita MVCC |
| `arcdocdb.fulltext.format` | Header, directory, padding, footer e CRC del `.idx` v2/type 5 | META, dizionario, posting, hint e copertura non sono validati da questa API |
| `arcdocdb.fulltext.codec` | [Sei sezioni complete e vista di ricerca verificata](full-text-codec.md) | Autorita di hint/decisioni fornita dal chiamante; pubblicazione/MVCC ancora da integrare |

Il server NNTP rimane un'applicazione futura. Il nucleo puo indicizzare separatamente
oggetto e corpo degli articoli, senza conoscere MIME, gruppi o comandi NNTP.

## Analisi e proprieta dei buffer

`crea-spazio-full-text` alloca solo durante la configurazione del worker. I limiti
`:max-scalars`, `:max-tokens`, `:token-bytes` determinano array specializzati privati;
`:max-memory` verifica il loro payload piu 4096 byte conservativi di overhead.
Non misura il consumo dell'intero processo o delle tabelle condivise.

`inizia-analisi-full-text(space, input, start, end)` prende in prestito lo span UTF-8
immutabile e invalida i risultati precedenti. I limiti per operazione sono
`:max-term-bytes`, `:max-tokens`, `:max-work`; il limite dei token deve rientrare
nello scratch. Le capacita non crescono automaticamente. Lo span e limitato a 16 MiB.
Un nuovo avvio durante un'analisi attiva e rifiutato senza sovrascriverla.

`passo-analisi-full-text(space, quantum)` esegue al massimo 1…65536 passi e restituisce
`:running` o `:done`. Il quantum conta passi di stato; lookup, espansioni e byte
consumano anche il budget di lavoro. Il riordino dei segni combinanti fa al massimo
uno scambio per passo, evitando un ciclo quadratico indivisibile. La decomposizione
ha uno stack fisso di 64 scalari; Hangul usa la decomposizione/composizione algoritmica.

`risultati-analisi-full-text` restituisce cinque valori solo dopo `:done`:
buffer dei termini UTF-8, array degli inizi, array delle fini, numero dei token,
byte usati. La posizione e l'indice del token, da zero. Gli intervalli non includono
separatori e rimangono validi fino al prossimo avvio sullo stesso spazio. Non sono
stringhe Lisp allocate per parola. Input vuoto o privo di lettere/numeri produce zero token.

Il profilo e esattamente `unicode-word-18.0.0-v1`; non dipende dalle tabelle di SBCL.
I [dati UCD e le licenze](../../data/unicode/18.0.0/README.md) sono versionati con
SHA256; il generatore Common Lisp e controllato per riproducibilita in `make check`.
Un budget esaurito o un errore Unicode passa l'analisi a `:failed`, rilascia l'input
e rende inaccessibili i risultati parziali. Una nuova analisi puo riutilizzare lo scratch.

## Run invertito in memoria

`crea-indice-posizionale` prealloca capacita per occorrenze, byte e campi presenti.
Ogni occorrenza usa cinque `u32`: campo, riga, posizione, offset e lunghezza del termine.
I termini sono in un buffer a byte; le lunghezze dei campi sono triple `u32` separate.
Questo layout interno non e il layout serializzato DICT/POSTINGS/LENGTHS del `.idx`.

`inizia-campo-full-text(run, row, field, analysis)` accetta un'analisi `:done`,
`row u32` e `field` da 1 a 65535. I campi devono arrivare in ordine stretto
`(row, field)`: stessa riga/campo duplicata e ordine retrogrado sono errori.
Capacita per tutti i token, i byte e la lunghezza del campo sono controllate
prima della transizione `:copying`. Una stringa presente vuota registra lunghezza zero;
per un campo assente non si chiama questa funzione.

Il chiamante mantiene lo spazio di analisi esclusivo fino al ritorno `:building`
di `passo-indice-posizionale(run, quantum)`. La copia procede per byte e record;
poi lo spazio puo essere riutilizzato per il campo successivo.
`sigilla-indice-posizionale` avvia heapsort in-place, con lavoro massimo configurato
comprensivo della copia. Un passo ripara un sottoalbero di profondita al massimo 32;
ciascun confronto conta tutti i byte esaminati. Il costo del passo dipende anche dalla
lunghezza dei termini, limitata in analisi. Un errore durante copia/ordinamento lascia
il run `:failed` e rilascia il prestito dello scratch; quel run non e interrogabile.

Dopo `:sealed`, il run e immutabile e puo essere letto da piu worker. Nessun lock,
stato globale per documento o contatore condiviso viene aggiornato dai reader.
Il proprietario mantiene vivo il run per tutta la lettura; il raccordo con EBR e
le generazioni della Serie e un passo successivo.

`corrisponde-riga-full-text(run, row, field, query, mode)` accetta un'analisi completa
con 1…256 token e `mode` uguale a `:all`, `:any` o `:phrase`. La ricerca usa limiti
binari sulle occorrenze ordinate; una frase verifica posizioni consecutive nella stessa
riga e nello stesso campo, anche con termini ripetuti. Il budget esclusivo di `query`
include analisi e confronti su tutte le righe esaminate; la saturazione e un errore,
mai un risultato negativo. Anche una ricerca su run vuoto consuma lavoro.

Il predicato non enumera l'universo dei documenti: `not`, filtri strutturati,
ordinamento per `_id`, top-N, deduplicazione e verifica della versione committed
visibile spettano al Query Engine. Un risultato positivo di questo predicato non
costituisce da solo una risposta completa alla query di una Serie.

## Cornice binaria

`scrivi-cornice-indice-full-text` riceve buffer, span, identita Serie, segment-id e
le sei lunghezze. Scrive solo header, directory, padding e CRC dopo il preflight;
payload e byte esterni restano intatti. Un rifiuto di preflight non cambia la destinazione.
`verifica-cornice-indice-full-text` restituisce fine file e span META solo dopo
CRC, identita, versione, campi riservati, dimensioni, allineamenti e contiguita.
Le docstring indicano condizioni e motivi distinti; le incongruenze interne
segnalano `invariant-violation` al futuro confine del worker.

Il payload e deliberatamente opaco a queste due funzioni. Un CRC corretto su META
o posting senza senso passa la verifica della cornice: un test dedicato impedisce
di promuovere questa API a validatore semantico. Non viene aperto o pubblicato alcun
file, e non esiste qui un punto di atomicita durevole.

## Verifica

`make test` compila senza warning/style-warning e include i 24 test del primo nucleo,
piu 15 test del [codec completo](full-text-codec.md#prove-e-confini-residui):

- 20.171 righe NFC, 100.855 confronti; 1.944 righe Word_Break, 8.487 confini;
  1.606 mapping C/F e lettura di tutti gli 1.112.064 scalari Unicode.
- 115.200 confronti dei predicati posizionali con una scansione indipendente;
  ripetizioni, campo assente/vuoto, righe/versioni distinte, quantum diversi e reader paralleli.
- Fixture wire indipendente, tutti i 3.168 bit e tutti i troncamenti del file campione;
  corruzione con CRC ricalcolato, riservati, offset, identita e limiti delle sezioni.
- Saturazione di lavoro, scalari, byte, token e capacita del run; riuso dello scratch
  dopo errore e immutabilita della destinazione sui rifiuti di preflight.
- Dopo warm-up: zero byte consed per 1000 analisi con ricerca di frase e per
  1000 scritture con verifica della cornice, su SBCL 2.6.9 arm64 con safety 3.

`make fulltext-check` verifica anche gli strumenti e introduce quattro mutanti
semantici temporanei, in un processo di test: NFC senza composizione, confine ovunque,
frase sempre accettata e header non verificato. Tutti devono essere rilevati; le funzioni
originali sono ripristinate. Il codec aggiunge altri due mutanti e una prova di riapertura
in processi separati. Non e una campagna di mutazione esaustiva.
La [revisione delle decisioni](full-text-decisioni.md) registra le due letture del nucleo.
Copertura diagnostica separata dalle misure di allocazione:

```sh
sbcl --script tools/fulltext-qualification.lisp --coverage spikes/out/fulltext-coverage-R1/
make check
```

Le prove qui descritte non qualificano ancora l'ammissione pre-SEAL/PREPARE,
la pubblicazione prima di H/ACK, il build concorrente,
il recovery delle generazioni o la ricerca con MVCC. Questi sono i successivi raccordi
previsti dal [contratto full text](../full-text.md).
