# Prima lettura della struttura CBOR

Il coordinatore ha stabilito il contratto e collegato ASDF, senza scrivere
il kernel o gli oracoli. La lettura statica riguarda i sei file dello scanner e si conclude sul kernel e sui tre file di test congelati il
2026-10-09, prima di compilazione e campagne runtime. La seconda lettura è attribuita all’autore degli oracoli nel referto separato. Le letture locali non sono approvazioni umane.

Il preflight controlla tipi e span prima di accedere all'array privato; l'alias
EQ viene rifiutato prima di qualsiasi reset. Le configurazioni e il budget
byte precedono le scritture. Il reset elimina stato residuo e riferimenti
attivi; la struttura non conserva il buffer e gli array hanno slot read-only.
Il chiamante possiede entrambi e assegna uno spazio distinto a ogni worker.

Il frame radice conta un figlio. Ogni item non-tag addebita il padre prima di
aprire un eventuale contenitore; il tag mantiene soltanto pending e non
consuma arità. Un figlio contenitore mantiene sullo stack il padre finché è
completo. Una map indefinita cambia parità all'inizio del figlio completo,
compresi key/value contenitori o taggati. Il break richiede un frame indefinito,
assenza di tag pendente e parità pari della map. I chunk restano item contati,
ma non addebitano il contenitore esterno già consumato dalla stringa.

Il drain collassa solo array/map definiti a zero. Il tetto di 102 iterazioni
comprende la verifica finale della radice dopo 101 pop; una stringa indefinita
non si annida in un'altra stringa indefinita. Array/map, anche vuoti, verificano
il budget prima di essere empilati e contribuiscono al picco. Una catena di tag
non usa frame e rimane limitata dai budget nodi/byte. Ogni passo consuma almeno
un byte, payload compreso; il ciclo esterno ha tetto span e drain finale.

High/low restano u32. Stringhe verificano high zero e low entro bytes rimasti
prima della somma e del payload. Array confronta il minimo di un byte per
figlio; map confronta coppie con floor(bytes/2) prima di moltiplicare per due.
La guardia di profondità precede questi controlli. Il testo delega alla
primitiva UTF-8 già verificata, mantenendo offset assoluti e controllandone
il conteggio restituito. Il risultato pubblico esce solo dopo radice completa,
cursore end, nessun frame/tag residuo e conteggi entro i budget.

Tutti gli helper hanno FTYPE, contratti e condizioni tipizzate; safety 3.
Gli errori interni e i default impossibili sono espliciti e restano nel
denominatore della copertura. Il sorgente non ha costruttori sul successo,
ricorsione, I/O, attese o stato mutabile globale. La factory fredda alloca due
array e la struttura: la campagna di heap riguarda le chiamate riuscite con
scratch e input preallocati, non gli errori o la factory.

Il test concorrente usa due buffer/spazi distinti, confronta esattamente tre
valori e verifica le copie integrali. Barriere e join hanno timeout e cleanup
che controlla la cessazione; l'overlap è osservato fuori dalla barriera.
È una verifica di isolamento del calcolo, non dello scaling del pool.

Nessun difetto funzionale aperto rilevato nella lettura statica. Build,
copertura, mutazioni e misure sono pendenti a questa lettura; il blocco non
attesta semantica dei tag, chiavi duplicate, rappresentazione deterministica,
writer admission, fail-stop del runtime o gate di rilascio del motore.

## Riscontro dei dodici punti C1

| Punto | Riscontro |
|---|---|
| 1. Requisiti | REQ-LIM-001/002 e AFF-004/008; ADR-0014/0048 limitati al contratto dello scanner. |
| 2. Invarianti | Progresso, arità, parità, frame/depth, ownership e oracoli indipendenti; campagne pendenti. |
| 3. Errori | Condizioni tipizzate, reason/offset e precedenze esplicite; il proprietario runtime resta futuro. |
| 4. Limiti | Span passi, 102 pop, 16MiB/16Mi nodi/100 livelli; nessuna ricorsione o attesa. |
| 5. Heap | Nessun costruttore sul successo; factory fredda separata, sensore positivo e misure pendenti. |
| 6. Uscita | Tre valori dopo radice esatta e postcondizioni; nessun AST o interpretazione implicita. |
| 7. Decisioni | Inventario separato, guardie interne mantenute; copertura grezza, nessuna qualifica MC/DC. |
| 8. Dati | Buffer immutabile, scratch esclusivo senza buffer trattenuto; alias kinds rifiutato. |
| 9. Integrazione | ASDF dopo header/UTF8; suite separata e scope cbor-structure esatto. |
| 10. Codifica | FTYPE, safety3, contratti, helper brevi e default di invariante; controlli runtime pendenti. |
| 11. Parallelismo | Due worker con spazi privati; attese limitate, tutti3 valori e input controllati. |
| 12. Durabilità | Nessuna scrittura durevole o I/O in questo modulo. |
