# Metodo preregistrato — CSN e orizzonte

Metodo definito prima dell'esecuzione, 2026-10-09. Classe C1,
REQ-MVC-005, REQ-MVC-008, REQ-AFF-008; realizza il registro di
[ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md).

## Ipotesi e oracoli

1. Un solo registro per Archivio. Due parole u32 rappresentano tutti i 64 bit;
   assegnazione positiva e strettamente crescente, nessun wrap.
2. Assegnazione e registrazione indivisibili. `H` non supera alcun pendente;
   una lista indipendente di interi Lisp calcola `min(pendenti)-1`, oppure
   l'ultimo CSN quando è vuota. Gli oracoli possono allocare.
3. I crediti limitano i veri pendenti: il più vecchio può restare aperto mentre
   l'altro slot viene riusato molte volte. Riprodurre il controesempio di ADR-0046.
4. I rifiuti di capacità, esaurimento, token e contesa preservano lo stato.
   Un token risolto non può consumare un credito di una successiva ondata.
5. Il mutex non attende. La ripetizione appartiene allo scheduler; fixture e
   strumenti hanno deadline e cleanup dei thread, nessun retry senza limite.

## Prove previste

Test sequenziali, completamenti invertiti, oracolo pseudocasuale deterministico,
esplorazione di azioni con capacità piccola e profondità finita, carry a 2^32,
confine fixnum, massimo u64 e rifiuto successivo. Test con mutex deliberatamente
occupato e quattro worker reali verificano identità uniche e convergenza di H.
Le letture C1 del realizzatore e del revisore sono registrate con i limiti.
La copertura tramite `sb-cover` usa una cache separata e conserva stato grezzo
e rapporto HTML; l'autoverifica deve rilevare un ramo deliberatamente mancante.
Copertura strumentale e tabella delle decisioni sono letture complementari.

Mutanti isolati devono passare la compilazione e fallire un'asserzione pertinente:
registro omesso, H anticipato, carry omesso, token stale accettato. Baseline e
autoverifica C4 precedono i mutanti; un errore di compilazione non conta come kill.
Una mancata rilevazione viene conservata, analizzata e risolta prima della consegna.

## Misure

Cinque campioni sequenziali di assegnazione/risoluzione, capacità 1, 16, 256,
1024, base piccola e base oltre fixnum; caso con il pendente più vecchio fisso.
Buffer e registro precedono la misura; warmup e GC precedono ciascun campione.
Il sensore verifica una baseline senza allocazione e un'allocazione deliberata.
Ogni finestra ha durata positiva e risoluzione dichiarata; finestre troppo brevi
richiedono aumento limitato del lavoro. Accettazione: zero byte di heap nei
successi sequenziali, compresi CSN alti, e correttezza degli esiti.

Campagne con 1, 2, 4 worker: Archivio condiviso e Archivi indipendenti. Riusare
worker precreati; riportare quantità di lavoro, tempo, retry busy/full e H finale.
Le condizioni di contesa possono allocare: nessuna pretesa di zero heap del
percorso di errore. Le campagne sono eseguite una alla volta. Il carico esterno
non è controllato; nessun target di throughput del database viene dedotto.

## Conservazione

Ogni invocazione tramite `record-command.lisp` conserva argv, ambiente, commit,
hash dei sorgenti prima/dopo, stdout/stderr, durata, exit code ed esito. Conservare
anche tentativi falliti, campagne grezze e registri di compattazione automatica.
La verifica finale avviene con sorgenti fermi; i risultati pubblicati seguono
il limite di dimensione e la compressione integra già prevista dal progetto.

Il componente non rende dati durevoli, non pubblica l'indice e non crea snapshot.
Integrazione WAL, recovery del massimo globale, parcheggi e lifecycle dell'Archivio
restano passi distinti; nessun requisito del motore completo viene promosso.
