# Decisioni della scansione strutturale CBOR

Inventario statico sul kernel congelato prima delle campagne. Le 20 decisioni
composte nuove sono elencate sotto; header CBOR e UTF-8 invariati conservano
gli inventari propri. Le righe si riferiscono allo snapshot della
[seconda lettura](cbor-struttura-revisione.md). Nessuna guardia viene tolta dal
denominatore della copertura. Le fixture indicano intenzioni di verifica;
gli esiti di condizioni e rami devono ancora essere acquisiti. Non è una
qualifica MC/DC e non sono approvate esclusioni.

Le fixture sono in `tests/codec/cbor-structure.lisp`; il prefisso dei nomi è
`test-REQ-AFF-004-cbor-structure-` oppure `test-REQ-AFF-008-cbor-structure-`.
«Difesa interna» indica uno stato che non deve essere prodotto dal percorso
pubblico rispettando tipi, ownership e helper; la classificazione non prova
irraggiungibilità e non sostituisce la copertura grezza.

| ID | File, funzione e riga | Condizioni della decisione | Fixture o limite |
|---|---|---|---|
| D01 | `cbor-space.lisp`, `crea-spazio-cbor`, 40 | kinds lungo 102; remaining lungo 102 | Factory esercitata da ogni fixture; esito capacity errato è difesa interna, ancora nel denominatore. |
| D02 | stesso file/funzione, 43 | top zero; depth zero; array distinti | Factory e workspace privati; stato iniziale errato è difesa interna. |
| D03 | `cbor-scan-input.lisp`, `check-limiti-struttura-cbor`, 11 | max-bytes index; max-bytes entro 16 MiB | `limit-configuration-and-order`, `byte-budget-and-exact-16-mib`: tipo, negativo, massimo e massimo+1. |
| D04 | stessa funzione, 13 | max-nodes index; 1 <= max-nodes <= 16 MiB | `limit-configuration-and-order`, `node-boundaries-chunks-and-breaks`: tipo, zero, massimo e massimo+1. |
| D05 | stessa funzione, 15 | max-depth index; max-depth <= 100 | `limit-configuration-and-order`, `depth-100-and-map-keys`: tipo, negativo, zero, 100/101. |
| D06 | `check-input-struttura-cbor`, 26 | buffer octets semplice; start index; end index; start <= end <= length | `invalid-range-and-type-priority`: buffer generico, signed, adjusted, fill-pointer, displaced; ogni estremo invalido, range invertito, offset zero e span vuoto. |
| D07 | `cbor-scan-stack.lisp`, `tipo-frame-cbor`, 13 | kind <= 6; kind zero se e solo se top zero | Corpus con tutti i frame; kind/posizione incompatibili sono difesa interna. |
| D08 | `depila-frame-cbor`, 25 | kind array/map 1..4; depth zero | Chiusure di array/map e stringhe, profondità 100 e supplemento stringa nello slot 101; depth incoerente è difesa interna. |
| D09 | `empila-frame-cbor`, 39 | kind <= 4; depth >= massimo fisso 100 | `depth-100-and-map-keys`; la guardia pubblica precede il push, esito di invariante è difesa interna. |
| D10 | `inizia-figlio-cbor`, 60 | kind radice/definito <= 2; remaining zero | `tags-charge-parent-once`, array/map definite e indefinite; consumo oltre arità è difesa interna. |
| D11 | `svuota-frame-cbor`, 102 | kind definito <= 2; remaining zero | Contenitori vuoti/non vuoti e radice, indefiniti chiusi con break; `rfc-definite-vectors`, `rfc-indefinite-vectors`. |
| D12 | `cbor-scan-items.lisp`, `check-contesto-cbor`, 15 | form break; major diverso da 7 | Break e item ordinari; combinazione header incoerente è difesa interna del contratto header. |
| D13 | stessa funzione, 18 | frame stringa indefinita kind >= 5; form non break | `chunks-same-type-and-header-first`, `node-boundaries-chunks-and-breaks`: chunk e break in stringhe; item fuori dalle stringhe. |
| D14 | stessa funzione, 19 | form argument; major uguale a kind-3 | Chunk definiti bytes/testo validi, major errato e stringa indefinita annidata; `chunks-same-type-and-header-first`. |
| D15 | `chiudi-break-cbor`, 36 | kind mappa indefinita; remaining positivo | `break-context-and-tag-priority`: map pari/dispari, array/stringhe; tag pendente rifiutato prima. |
| D16 | `apri-contenitore-cbor`, 77 | high zero; low <= minimo byte rimasti (array: room, map: floor(room/2)) | `container-minimum-remaining-bytes`, `payload-width-and-huge-unsigned-lengths`: arità esatta, mancante e high nonzero. Profondità verificata prima. |
| D17 | `verifica-stringa-cbor`, 100 | high zero; low <= end-next | Stringhe vuote/piene, payload troncato e parole u64 enormi; `valid-unicode-and-chunk-locality`, `payload-width-and-huge-unsigned-lengths`. |
| D18 | `cbor-scan.lisp`, `passo-struttura-cbor`, 26 | lead < cursore dopo passo; cursore <= end | Tutte le fixture pubbliche, troncature, fuzz e corpus; violazioni sono difesa interna. |
| D19 | `risultato-struttura-cbor`, 38 | 1 <= nodes <= max-nodes; peak-depth <= max-depth | `node-boundaries-chunks-and-breaks`, `depth-100-and-map-keys`, scalar depth zero; risultato oltre budget è difesa interna. |
| D20 | stessa funzione, 41 | top zero; depth zero; nessun tag pendente | Item conclusi e tag/chunk/container misti; stato residuo su successo è difesa interna. |

Le selezioni semplici preservano anche le precedenze contrattuali:

| Sequenza | Ordine osservabile da verificare |
|---|---|
| Preflight | range → workspace → alias EQ kinds → byte-limit → node-limit → depth-limit → byte-budget; prima di reset, anche su span vuoto. |
| Item | header → contesto del chunk → break oppure node-budget → consumo del figlio → payload/contenitore. |
| Break | tag pendente → frame non indefinito → map con valore mancante → chiusura di un frame. Break non conta come nodo. |
| Contenitore | node-budget già verificato → depth-budget → high/low/arità minima → push. Per map la moltiplicazione 2N segue il confronto con floor(room/2). |
| Testo | payload intero disponibile → UTF-8 per singolo chunk → avanzamento. Header e UTF-8 propagano reason/offset della primitiva. |
| Radice | drain dei frame definiti → controllo trailing senza leggere il byte seguente → tre valori dopo le postcondizioni. |
| Tag | nodo contato e pending; nessun frame o figlio addebitato finché comincia il terminale non-tag. |

Restano nel sorgente e nel denominatore anche guardie semplici, `otherwise`
di `case`, fallback del ciclo e condizioni di capacità/progresso. L'inventario
non restringe la futura copertura ai soli errori pubblici o alle 20 decisioni.
