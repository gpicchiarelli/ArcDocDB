# Seconda lettura degli header CBOR

Lettura statica indipendente del 2026-10-09, dopo il congelamento dei test.
Nessun difetto funzionale rilevato rispetto al contratto registrato nel
[metodo](cbor-header-metodo.md). Compilazione, esecuzione, copertura,
mutazioni e allocazioni sono **da acquisire** alla data di questa lettura;
il revisore non ha eseguito campagne.

## Provenienza e indipendenza

I tre file di test sono stati scritti senza leggere `src/codec/cbor-*`
o implementazioni CBOR degli spike. Gli expected provengono dalla sintassi
di [RFC 8949, §3 e §3.3](https://www.rfc-editor.org/rfc/rfc8949#section-3),
dal contratto pubblico congelato e da un modello aritmetico locale.
Il modello usa divisioni, resto e accumulo big-endian; può creare bignum
a freddo. Non chiama il prodotto per ricavare il risultato atteso.

Prima della lettura dei sorgenti sono stati comunicati i Git blob dei test
e verificato staticamente il bilanciamento lessicale. Nessun test è stato
modificato dopo quel congelamento. I due blob di prodotto sono stati
acquisiti solo nella seconda lettura.

| File | Git blob della lettura |
|---|---|
| [cbor-package.lisp](../../src/codec/cbor-package.lisp) | `d5f72309f3eca0a719507d257a635e5dd680013a` |
| [cbor-header.lisp](../../src/codec/cbor-header.lisp) | `db635a50678f2712ec9516be335717ea254d4d09` |
| [cbor-support.lisp](../../tests/codec/cbor-support.lisp) | `172c4a335b2d504f785b2036532346a24ccf1378` |
| [cbor-header.lisp, test](../../tests/codec/cbor-header.lisp) | `a1541916590304adccc2092c226ef3be9c644168` |
| [cbor-threads.lisp](../../tests/codec/cbor-threads.lisp) | `720d80c6dd5a962dc724835c1421635ba289b7ef` |

## Riscontro sul contratto

Il preflight controlla il tipo semplice u8 e gli indici prima del lead.
Uno span valido vuoto segnala troncatura all'offset `end`; un range invalido
resta un errore di argomento senza offset. AI 28..30 e AI31 sono trattati
prima del calcolo della larghezza. Per AI 24..27 l'intero argomento deve
rientrare nello span prima di leggere i suoi byte. Il controllo F8 sotto
32 viene dopo la disponibilità del secondo byte, con offset `start+1`.

L'accumulo legge al massimo quattro byte per ciascuna parola: anche le due
parole `FFFFFFFF` restano u32. Non assembla un valore u64 e non converte i
bit in un oggetto float. Il controllo della larghezza precede la somma
`start+width`, che resta entro `end`; il percorso immediato e i marker
consumano un byte. Il risultato contiene sempre i sei valori pubblici
nell'ordine major, AI, high, low, next, form.

Gli argomenti non minimi sono conservati. Le forme `:indefinite` e `:break`
non ricevono una validazione strutturale del contesto. Stringhe, contenitori
e tag possono avere una testa completa senza il corpo o il figlio:
l'esito riguarda soltanto la testa. Il profilo deterministico, l'UTF-8 del
testo, le chiavi delle mappe, il budget documentale e la profondità restano
responsabilità del futuro parser.

## Lista di controllo C1

| Punto | Riscontro e limite |
|---|---|
| 1. Requisiti e ADR | REQ-AFF-004/008 e supporto iniziale a REQ-LIM-002, coerenti con ADR-0014/0048. Non attesta il decoder CBOR completo. |
| 2. Invarianti e test | Range, ordine dei rifiuti, parole, progresso e immutabilità hanno oracoli indipendenti. Le guardie interne restano attive; gli input pubblici conformi non ne rendono false le postcondizioni. Copertura e mutazioni pendenti. |
| 3. Errori tipizzati | `invalid-argument`, `corruption-detected` e `invariant-violation`; motivi e offset sono dichiarati. Nessun gestore nel prodotto nasconde un errore. Il kernel non possiede una Serie: la transizione `FAULTED` spetta al futuro proprietario. |
| 4. Lavoro limitato | Un lead e al massimo otto byte aggiuntivi; nessuna ricorsione, attesa o ciclo dipendente dalla lunghezza dichiarata del payload. I test hanno tetti di iterazione, semafori entro 15 secondi, join entro 20 e controllo di cessazione nel cleanup. |
| 5. Allocazioni | Nessun costruttore sul successo nel sorgente; locali index/u8/u32 e nessuna materializzazione u64/float. Zero heap richiede la campagna registrata con sensore positivo: risultato pendente. |
| 6. Uscita verificata | I sei valori escono dopo la verifica della sintassi locale e dei confini della testa. Non escono un documento decodificato, il payload o una validazione implicita dell'item completo. |
| 7. Decisioni composte | La [tabella](cbor-header-decisioni.md) include i cinque `and`: range pubblico, progresso dell'argomento, range del marker, rifiuto F8 e progresso pubblico. Non vi sono `or` nel prodotto. Guardie e ramo `otherwise` restano nel denominatore; nessuna qualifica MC/DC dichiarata. |
| 8. Proprietà dei dati | Commenti OWNER/SHARED dichiarano buffer immutabile del chiamante e cursori/parole locali. Nessuno stato mutabile globale o scrittura sul buffer. |
| 9. Integrazione e controlli | ASDF registra package/header dopo le fondazioni, i tre file di test e `arcdocdb.cbor.tests:run`. Build, lint, tracciabilità e `make check` sono pendenti alla lettura. |
| 10. Regole di codifica | Safety 3, speed 2, FTYPE completi, argomenti pubblici T con controllo runtime e contratti delle funzioni. Nessuna violazione statica rilevata; nessuna deviazione o approvazione del gate concessa. |
| 11. Parallelismo | Nessun lock, attesa, scrittura condivisa o coda globale per operazione. Il test previsto usa due buffer privati e misura il calcolo fuori dalle barriere; l'overlap resta da osservare, senza claim sul pool o sullo scaling del motore. |
| 12. Atomicità durevole | Non applicabile: nessuna scrittura durevole, I/O, pubblicazione o eliminazione. |

## Corpus registrato

Sono presenti 17 test nominali, di cui uno con due thread reali. I conteggi
seguenti sono expected dell'oracolo, non risultati di una campagna:

| Corpus | Expected |
|---|---|
| Tutti i 256 lead, argomento fisicamente disponibile | 224 `:argument`, 4 `:indefinite`, 1 `:break`; 24 reserved e 3 indefinite illeciti |
| Tutti i 256 lead su span di un byte | 192 `:argument`, 5 marker; 32 troncati, 24 reserved e 3 indefinite illeciti |
| Tutti i 256 secondi byte F8 | 224 accettati, 32 malformati |
| Argomenti big-endian a due byte | Tutti i 65.536 valori, comprese rappresentazioni non minime |
| Prefissi delle quattro larghezze per otto major | 152 troncature, con byte mancanti fisicamente presenti fuori `end` |
| Fuzz differenziale | 4.096 span di 1..9 byte, offset 1..7; seme `8949A11F`, LCG u32 con moltiplicatore 1664525 e incremento 1013904223 |
| Calcolo concorrente previsto | 2 × 65.536 header × 16 passaggi; 2.097.152 header, 18.874.368 byte; sink 2.401.919.800.705.024 e 2.231.683.637.051.392 |

Fixture ulteriori coprono high/low asimmetrici e massimi, bit float per
zero, segno, infinity e NaN, assenza di payload/figlio, code malformate
ignorate, offset disallineati, input invalido e priorità dei rifiuti.

Questa lettura non rimuove guardie dalla copertura, non approva eccezioni e
non chiude MC/DC, fail-stop del runtime o gate di rilascio del motore.
