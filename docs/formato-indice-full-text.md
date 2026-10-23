# Formato binario dell'indice full text

> **Deciso ([ADR-0054](adr/0054-contratto-e-formato-full-text.md))** — Formato di progetto
> `.idx` versione 2, tipo full text 5. Disponibile il [codec di prodotto](implementazione/full-text-codec.md)
> per le sei sezioni e la verifica locale rispetto al descrittore; pubblicazione durevole
> e qualifica del motore restano da completare.
> Completa la famiglia descritta in [formati-su-disco.md](formati-su-disco.md#file-indice).

Gli interi a larghezza fissa sono unsigned little-endian. Intervalli di byte e array
sono semiaperti; le somme si verificano prima dell'uso. Gli offset sono assoluti nel file,
eccetto quelli esplicitamente relativi a una sezione. I record documentali mantengono
il loro formato v1/v2: la versione del file indice è indipendente.

## Header e directory

| Offset | Tipo | Campo e vincolo |
|---|---|---|
| 0 | `char[8]` | magic ASCII `ARCDIDX1` |
| 8 | `u16` | versione del file indice: 2 |
| 10 | `u16` | tipo: 5, riservato al full text |
| 12 | `u16` | numero di sezioni: 6 |
| 14 | `u16` | flag: zero |
| 16 | `byte[16]` | identità autorevole della Serie |
| 32 | `u64` | segment-id, confrontato con manifest e hint |
| 40 | `u64` | lunghezza esatta del file, compreso footer |
| 48 | `u64` | offset della directory: 64 |
| 56 | `u32` | CRC32C dei byte `[0,56)` |
| 60 | `u32` | riservato zero, verificato separatamente |

La directory occupa `[64,208)`: sei entry da 24 byte, ordinate per tipo di sezione.
Ogni entry contiene `u16 tipo`, `u16 flag=0`, `u32 riservato=0`, `u64 offset`,
`u64 lunghezza`. Non esistono sezioni opzionali nella versione 2/type 5.

| Tipo | Sezione | Struttura |
|---|---|---|
| 1 | META | un solo array CBOR, descritto sotto |
| 2 | DICT | entry da 32 byte, una per coppia distinta campo/termine |
| 3 | TERMS | byte UTF-8 dei termini, senza terminatore |
| 4 | POSTINGS | entry da 16 byte |
| 5 | POSITIONS | array di `u32` |
| 6 | LENGTHS | entry da 16 byte per riga/campo presente |

Le sezioni sono in quell'ordine. Il primo offset è 208; ogni offset successivo è
`align8(fine della sezione precedente)`. Padding zero, massimo sette byte fra sezioni.
Una sezione vuota ha lunghezza zero e può condividere l'offset con quella successiva.
Non sono ammessi buchi ulteriori, sovrapposizioni o byte finali sconosciuti.

Il footer è un `u32 CRC32C` immediatamente dopo LENGTHS, senza padding finale: copre
tutti i byte `[64,file-length-4)`, directory e padding inclusi. Il file minimo contiene
comunque META, directory e footer; un indice privo di termini è valido se la copertura
del segmento e i conteggi sono validi. Il limite effettivo del file è configurato,
default 16 GiB, sempre entro l'intervallo positivo di `off_t` della piattaforma.

## META

Un array CBOR definito, di esattamente 12 elementi. Array e stringhe hanno lunghezza
definita; interi e testate sono minimi; niente mappe, tag, float o elementi aggiuntivi.
Il decoder applica anche il budget di 64 KiB della sezione prima di allocare.

| Indice | Elemento |
|---|---|
| 0 | `index-id`, intero positivo entro `u64` |
| 1 | `generation-id`, intero positivo entro `u64` |
| 2 | `contract-version`, intero positivo entro `u64` |
| 3 | lunghezza valida del segmento sorgente, entro `u64` |
| 4 | lunghezza esatta in byte dell'hint associato, entro `u64` |
| 5 | CRC32C di **tutti** i byte dell'hint associato, entro `u32` |
| 6 | numero di righe dell'hint, entro `2^32` |
| 7 | stringa di profilo: `unicode-word-18.0.0-v1` |
| 8 | revisione del profilo: intero 1 |
| 9 | array dei campi: ciascuno è `[field-id, alias, [chiavi del percorso]]`, ordinato per field-id |
| 10 | limiti di analisi: `[input-bytes, term-bytes, tokens-per-document, prepared-bytes, analysis-work]`, cinque interi positivi entro `u64` |
| 11 | numero di record PUT committed nel prefisso del segmento, entro il numero di righe |

ID, configurazione dei campi, profilo e limiti si confrontano integralmente con il
descrittore della generazione attesa. Non basta un hash della configurazione.
Lunghezza valida e righe devono coincidere con manifest/hint verificati. Il CRC
dell'hint lega l'ordinale ai byte esatti di quella mappa: un hint ricostruito con ordine
diverso richiede la ricostruzione dell'indice full text. La verifica dell'hint stesso
e dei documenti resta obbligatoria; il suo CRC non certifica il contenuto testuale.

Il build considera ogni PUT committed nel prefisso, anche storico; non indicizza
tombstone, OUTCOME o prepared abortiti. Un prepared committed usa il CSN autorevole
risolto secondo il contratto del segmento. Campi assenti non hanno entry LENGTHS;
campi presenti ma vuoti hanno entry con zero token. Nessun termine è comunque un
caso diverso da copertura sconosciuta o build incompleto.

## Dizionario e posting

Entry DICT da 32 byte:

| Offset relativo | Tipo | Campo |
|---|---|---|
| 0 | `u16` | field-id dichiarato |
| 2 | `u16` | riservato zero |
| 4 | `u32` | lunghezza del termine in byte, positiva ed entro il limite dichiarato |
| 8 | `u64` | offset del termine relativo all'inizio di TERMS |
| 16 | `u64` | indice della prima entry in POSTINGS |
| 24 | `u64` | numero positivo di posting |

DICT è strettamente ordinato per field-id e byte UTF-8 del termine, senza locale.
TERMS contiene le stringhe in quello stesso ordine, contigue e senza condivisione
di intervalli. Il primo offset è zero; la somma delle lunghezze è la lunghezza di TERMS.
Ogni termine è UTF-8 valido e deve già essere l'output del profilo dichiarato.

Entry POSTINGS da 16 byte: `u32 row`, `u32 frequency`, `u64 first-position`.
`row` è un ordinale zero-based nell'hint; `frequency` è positiva; `first-position`
è un indice nell'array POSITIONS, non un offset in byte. Ogni lista ha righe strettamente
crescenti, senza duplicati. Le liste seguono l'ordine DICT, sono contigue e partizionano
l'intera sezione POSTINGS. `frequency` indica quante entry POSITIONS appartengono al
posting; le relative liste seguono lo stesso ordine e partizionano POSITIONS.

Entry LENGTHS da 16 byte: `u32 row`, `u16 field-id`, `u16 riservato=0`,
`u32 token-count`, `u32 riservato=0`. Ordine stretto per `(row, field-id)`, senza
duplicati. Ogni posting trova l'entry della propria riga/campo; ogni posizione è minore
di `token-count` e le posizioni nel posting sono strettamente crescenti. La frequenza
coincide con la lunghezza della lista di posizioni. Per riga/campo la somma delle
frequenze coincide con `token-count`; la verifica completa controlla anche che l'unione
delle posizioni sia esattamente `[0,token-count)`, senza duplicati fra termini diversi.

Nella versione iniziale non si usano delta encoding, varint, front-coding, Bloom o
skip block. DICT e posting ordinati consentono ricerca binaria e intersezione degli
intervalli; un'altra rappresentazione richiede una versione del formato esplicita.

## Validazione e ammissione

Prima di esporre il file come copertura utilizzabile, il checker verifica lunghezze,
CRC, identità, tipi/versioni, riservati, padding, sezioni esatte e conteggi. Verifica
ordini, unicità, confini di ogni stringa/lista e legame con l'hint, inclusi row, CSN
ed esiti committed. Questi controlli valgono anche se tutti i CRC sono corretti.
Le lunghezze di DICT, POSTINGS, POSITIONS e LENGTHS devono essere rispettivamente
multiple di 32, 16, 4 e 16; l'array META deve consumare l'intera propria sezione.
La correttezza dei termini rispetto ai documenti richiede la verifica completa con
rianalisi indipendente: un controllo del solo file non la dimostra.

Il lavoro è diviso in compiti e buffer limitati, senza allocazione per entry e senza
I/O dal writer. Il budget viene verificato prima di acquisire memoria; se non basta,
il file non è dichiarato pronto. Un file con CRC valido ma versione ignota produce
`unsupported-format`; un'incoerenza riconosciuta produce `index-corrupt`.

I seguenti vincoli sono hard per questo formato: row entro `u32`, field-id entro `u16`,
frequenze/token-count entro `u32`, sezioni entro `u64` e limiti I/O della piattaforma.
La somma dei token per documento/indice è al massimo `2^32-1`, anche se si alzano i default.
Nessuna moltiplicazione dei conteggi può traboccare prima del confronto con la sezione.

## Limite superiore e rotazione

Per ogni documento e indice, l'analisi restituisce un limite superiore:

```
U(documento) = 16 × campi presenti
             + somma, per ogni (campo, termine) distinto nel documento,
                 di (32 + byte UTF-8 del termine + 16)
             + 4 × numero totale di token
```

La somma di questi contributi, aggiunta a header/directory (208 byte), limite META,
al massimo 35 byte di padding e footer (4 byte), è un limite superiore del file.
La somma sovrastima il dizionario quando un termine compare in più documenti e quindi
rimane conservativa. Input vuoti, PUT prepared e documenti poi aggiornati non autorizzano
a ridurre la riserva senza una prova sull'esito: un abort risolto può liberarla, mentre
le versioni committed ancora fisicamente presenti contano fino alla compaction.

M01 prenota questo costo per tutti gli indici prima dell'append/prepare. Un superamento
del budget del segmento richiede rotazione prima dell'ammissione; se la richiesta
non entra in un segmento vuoto viene rifiutata. Il budget di spazio temporaneo viene
prenotato prima del build. La stima non è una misura di spazio o prestazione: evita di
scoprire a posteriori che il formato ammesso non può rappresentare i documenti committed.

## Fixture binaria minima indipendente

Una fixture indipendente usa un campo con due righe: riga 0 `alpha beta alpha`, riga 1
`beta`. DICT contiene `alpha`, `beta`; TERMS è la concatenazione dei due UTF-8.
POSTINGS contiene le righe `[0]` per `alpha` e `[0,1]` per `beta`, con frequenze `[2]`
e `[1,1]`. POSITIONS segue l'ordine dei posting: `[0,2,1,0]`. LENGTHS contiene
`(0,campo,3)` e `(1,campo,1)`. Si verificano frase `alpha beta`, frase `beta alpha`,
duplicazione di row, scambio dell'hint, offset fuori sezione e posizioni alterate con
CRC ricalcolato. I [468 byte completi](../tests/fulltext/minimum-v2.hex) e i CRC attesi
sono calcolati da un [oracolo indipendente](../tools/fulltext-codec-fixture.lisp), senza
caricare il prodotto, e congelati prima della prima esecuzione dell'encoder.
Il [metodo implementativo](implementazione/full-text-codec.md) distingue questa prova
dalla verifica dell'hint e dalla rianalisi dei documenti.
