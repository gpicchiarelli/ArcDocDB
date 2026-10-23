# Codec full text — decisioni e due letture

Perimetro C1: [codec e vista verificata](full-text-codec.md), secondo ADR-0054.
Due letture dello stesso autore il 16 ottobre 2026: non sono una revisione indipendente
o una qualifica C1 completa. Copertura diagnostica e prove di allocazione sono separate.

| Decisione composta | Rami e prove |
|---|---|
| Confini pubblici | Buffer simple u8, span e budget positivi prima dell'accesso; null, tipi/range errati e budget zero/insufficiente rifiutati |
| Descriptor freddo | Identita 16 byte, segment/source u64, hint span e bitmap bounded; META 1…65536, budget prima delle copie |
| META | Forma minima definita; ID positivi, righe e PUT uguali all'autorita; alias/percorso e ID duplicati, ordine retrogrado, profilo ignoto e coda rifiutati |
| Configurazione | Cinque limiti positivi, token entro u32, percorsi 1…100; fino a 16 campi e capacita dei termini entro scratch, con errore di risorse distinto da corruzione |
| Alias dei buffer | Destinazione e input separati da META/identita/scratch analitico; destinazione separata dal run; nessun prestito mutabile durante una vista |
| Piano | Somme solo entro residuo; lunghezze e posizioni entro capacita; output/lavoro riservati prima di fill/copia/CRC |
| LENGTHS | Ordine stretto row/field, riservati zero, campo dichiarato, row entro bitmap e bit committed; token per documento e somma totale controllati |
| Termini del run | Campo/termine ordinati, righe e posizioni crescenti; contatori partizionano tutte le sezioni e postcondizioni dei byte scritti |
| U64 esterni | Parole high/low confrontate col massimo prima della ricomposizione; UINT64_MAX nei riferimenti rifiutato senza bignum sul percorso caldo |
| ID segmento posseduto | Intero boxed una volta nella cella privata del descrittore; nessuna lettura di raw slot u64 da passare alla cornice. Il test con UINT64_MAX resta invariato dopo il fallimento CI x86-64 |
| META del file | Confronto integrale con la copia canonica autorevole, oltre a identita e CRC della cornice; configurazione/hint non sostituibili con un semplice hash |
| DICT | Campo dichiarato e riservato zero; lunghezza positiva entro limite e residuo; offset e primo posting esatti; ordine stretto, almeno un posting |
| Normalizzazione | Input termine entro scratch, un solo token identico; maiuscole, segmenti multipli, sola punteggiatura e UTF-8 invalido rifiutati con CRC corretto |
| Posting | Row crescente, frequenza positiva entro posizioni residue, LENGTHS presente e primo ordinale esatto |
| Posizioni | Ordine stretto, posizione < token-count e bitmap prima non marcata; duplicati fra termini e buchi non certificati |
| Query | Vista/analisi pronte, field/row entro tipo, 1…256 token e modo noto; saturazione distinta da assenza e nessuna somma ordinale oltre u32 |

## Lettura 1: formato e failure

Rilette tutte le larghezze e gli offset contro ADR-0054 e la fixture indipendente.
La cornice rimane separata dal validatore completo. Le moltiplicazioni usano conteggi
gia limitati dalle sezioni/capacita; nessun riferimento u64 esterno viene usato come
indice prima del confronto con il residuo. La frequenza non determina un'allocazione.
LENGTHS fissa i prefissi della bitmap: ogni posizione e marcata una volta; un controllo
finale verifica tutti i bit richiesti. Il CRC non viene usato come sostituto dei controlli.

Riletti errori e ownership: rifiuti di preflight prima dei byte, fallimenti interni senza
rollback, scratch riusabile e input analitico rilasciato anche su errore. Il costruttore
del descriptor copia l'autorita fornita e non puo provare da solo che il chiamante abbia
eseguito replay e verifica dell'hint. Il tipo non viene promosso a prova di readiness.

## Lettura 2: concorrenza, lavoro e ambito

Rilette le dipendenze: run SEALED e descriptor immutabili, un solo proprietario dello
scratch, viste create solo dopo verifica; buffer di una vista mai riscritto. Le query
mutano solo il loro budget privato. Nessun contatore, lock, callback o I/O tra Serie.
Costruttori e viste allocano solo sul percorso freddo; le misure escludono tali aperture.
Il lavoro di completamento del writer e riservato prima della prima modifica.
Le attese dei child della prova C4 hanno un limite e cleanup dei soli processi propri.

INV-I5 e sostenuto dal legame ai byte hint e dalla verifica locale degli ordinali,
ma la sua dimostrazione complessiva richiede hint/record verificati e rianalisi.
INV-I4 e INV-I6 non sono chiusi dal codec: mancano pubblicazione, MVCC, inventario,
riserve predecisione e ciclo di vita della generazione. MC/DC completa, fault injection
dei confini del worker e campagna di carico restano aperte; i test negativi e la
copertura locale non vengono presentati come qualifica completa del motore.
