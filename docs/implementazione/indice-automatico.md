# Selezione automatica del modo dell'indice

Primo incremento autorizzato il 2026-10-22: [ADR-0057](../adr/0057-selezione-automatica-indice.md),
REQ-IDX-008, INV-I7, INV-A8, INV-P6. Classe C1 per il selettore, C4 per il modello.
Il requisito complessivo resta progettato: l'indice usato dal motore e' ancora
il [primario residente](indice-primario.md). Non esiste ancora un backend
primario paginato o un attuatore di migrazione nel runtime.

## API e stime

`arcdocdb.index.mode:crea-politica-indice` costruisce una configurazione immutabile.
`:rientro-percentuale` e' un intero 1..99, default 75. Non abilita una scelta manuale.

`valuta-modo-indice(policy, current, budget, resident, paged, migration)` restituisce
due valori immediati: destinazione `:residente`/`:paginato` e azione.
`current` e' `:iniziale`, `:residente` o `:paginato`. Budget in 0..2^60-1 byte;
stime in 1..2^60-1. Il limite conservativo mantiene i calcoli nei fixnum SBCL64.

- `resident` e `paged`: picchi conservativi del prossimo lavoro se ammesso
  nel rispettivo modo, compresi directory, chiavi, history, metadati e transitori.
- `migration`: picco totale del cambio sul dataset corrente, con sorgente
  ancora viva, destinazione, staging, delta e versioni trattenute. Il prossimo
  lavoro resta rinviato. Deve coprire anche il picco di destinazione per
  richiedere un cambio; non deve coprire la futura crescita residente evitata.
- `budget`: quota assegnata a questa Serie dopo le riserve degli altri
  componenti. Non e' una misura istantanea della memoria libera.

Sono stime fidate e coerenti fornite dal controllore: la funzione non misura
l'OS, non prenota RAM e non dimostra che una stima fornita sia conservativa.
La futura misurazione deve includere pagine ritirate e oggetti ancora trattenuti
dal GC. Il coordinatore deve garantire che le quote simultanee entrino nel
budget globale, lasciando margine all'OS e agli altri componenti.

## Decisioni

All'avvio si preferisce il residente se entra nella quota intera. In esercizio
il residente resta tale finche' il prossimo picco non supera la quota.
Il paginato ritorna al residente quando il picco scende entro
`floor(budget * rientro-percentuale / 100)`. Il calcolo divide prima il budget,
senza moltiplicazione intermedia fuori fixnum.

| Azione | Significato e obbligo del chiamante |
|---|---|
| `:avvia` | Il modo scelto entra nella quota; costruirlo e verificarlo prima di esporlo. |
| `:mantieni` | Nessun cambio richiesto; il prossimo lavoro entra nella quota stimata. |
| `:prepara` | Destinazione e picco di migrazione entrano; prenotare, poi costruire. Non equivale a swap eseguito. |
| `:budget-insufficiente` | Non ammettere il lavoro oltre quota e non pubblicare una destinazione incompleta. Ridurre/ridistribuire risorse o applicare backpressure esplicita. |

Esempio in byte astratti: quota 1000, prossimo residente 1100, paginato 200,
migrazione del dataset corrente 950: `:paginato, :prepara`. Con migrazione
1001: `:paginato, :budget-insufficiente`. Non si attende che la crescita
oltre quota sia gia' stata ammessa. La decisione non modifica la root corrente.

`invalid-argument` segnala domini non validi e transitorio inferiore alla
destinazione di un cambio. `resource-exhausted` segnala un avvio senza modo
capiente. I motivi canonici sono verificati nei test; nessun effetto precede
il rifiuto. Un'insufficienza in esercizio e' un risultato esplicito.

La funzione non alloca sui percorsi validi, non usa lock o I/O e non viene
chiamata dal lookup GET. Non si attribuisce per questo lock-freedom al GET.
La configurazione immutabile puo' essere condivisa; nessuna quota o contatore
viene scritto fra Serie. Il campione decisionale non e' un'autorizzazione
permanente: l'attuatore deve riservare e ricontrollare prima della pubblicazione.

## Verifica preregistrata del selettore

Il metodo e' fissato prima della prima esecuzione: compilazione rigorosa,
oracoli numerici manuali ai confini, sequenza crescita/rientro, budget mutato,
stessa politica per due Serie senza stato condiviso, domini malformati,
estremo 2^60-1 e percentuali 1/99. Finestra seriale di 10.000 decisioni con
sink controllato e contatore SBCL GET-BYTES-CONSED: atteso zero byte Lisp.
Questa finestra non misura RSS, allocazioni native, concorrenza o prestazioni.
Come le altre finestre di allocazione, il test viene eseguito nella verifica
normale; il catalogo lo esclude dalla sola esecuzione strumentata SB-COVER,
che modifica le allocazioni, richiedendo la prova normale sugli stessi sorgenti.
Le regressioni del consumer CI verificano anche questa settima voce esplicita.
I [risultati iniziali](indice-automatico-risultati.md) conservano i run originali.

| Decisione composta C1 (COD-54) | Condizioni | Coppie verificabili |
|---|---|---|
| Percentuale valida | fixnum; 1 <= p <= 99 | 75; 75.0; 0; 100; estremi 1/99 |
| Byte validi | fixnum; minimo <= x <= massimo | 0 budget; 1 stima; -1; 0 stima; 1/2; max+1; max |
| Stima di cambio valida | non iniziale; modo diverso; picco < destinazione | stesso campione iniziale/residente/paginato, 699/700 per destinazione 700 |

Le altre scelte sono confronti singoli o rami ordinati: avvio, capienza della
destinazione, uguaglianza dei modi, capienza del transitorio. I test coprono
uguaglianza e byte adiacente; i requisiti non vengono marcati qualificati.

## M0: lifetime dei frame e progresso

Il [modello eseguibile](../../spikes/SPK-07-protocols/page-lifetime.lisp) segue
il [metodo preregistrato](../../spikes/SPK-07-protocols/metodo-page-lifetime.md).
Uno slot hazard appartiene a un worker nella cache della Serie, nessuna
scrittura globale per richiesta. Nel modello SC:

```text
reader: token = leggi READY(frame)
        annuncia hazard privato = token
        se READY(frame) != token: cancella hazard; MISS
        copia campo A; copia campo B
        cancella hazard; HIT con copia privata

reclaimer: chiudi READY -> RETIRING
           scansiona ogni hazard
           se presente token corrente: rimanda il riuso
           altrimenti BUILDING; nuova generazione senza wrap
           scrivi A; scrivi B; pubblica READY
```

Safety: un annuncio precedente alla chiusura, seguito da riconferma positiva,
deve essere visto da ogni scansione che autorizzerebbe il riuso; la protezione
resta fino alla fine della copia. Un annuncio successivo alla scansione non
permette accesso al contenuto, perche' la riconferma fallisce. Questi ordini
richiedono primitive e barriere documentate nella futura traduzione SBCL.
In SC il tentativo accettato acquisisce al secondo confronto READY; la pagina
rimane utilizzabile durante RETIRING. Questo e' il punto dell'acquisizione,
non il punto di linearizzazione della transazione o del GET.

Liveness: ogni reader completa un tentativo in al massimo sei passi propri;
non attende il writer. Un tentativo MISS non completa necessariamente la
ricerca richiesta. Un thread sospeso puo' impedire il riuso di un frame;
tutti i frame protetti possono bloccare un miss con I/O. Non e' dimostrato
un resident-index lookup lock-free completo: mancano directory, scelta del
frame, primitive SBCL e relativa prova sul modello di memoria reale.
Le pause del runtime/GC non sono escluse per ipotesi implicita.

Il test ABA ricicla deliberatamente il token dopo due riusi, mentre l'oracolo
delle incarnazioni resta distinto. In prodotto confronto completo
PageRef/frame/generazione, identita' persistenti non riusate, esaurimento
senza wrap e array dei frame a vita lunga sono obblighi ancora da decidere.
Nessuna reclamation del contenuto degli snapshot e' autorizzata da questo modello.

## Incrementi successivi e completamento

| Incremento | Moduli e interfacce | Criterio di completamento |
|---|---|---|
| I1, introdotto | `index.mode`, contratto puro; M0 C4 separato | Test e modello riproducibili, integrazione CI, tracciabilita'; attuatore ancora assente. |
| I2, corrente | [ADR-0058](../adr/0058-pagine-indice-primario.md), [codec C1 delle pagine](pagine-indice.md), PageRef, checksum | Fixture indipendenti 4/16/64 KiB, collisioni e chiavi lunghe, pagine piene, corruzioni e immagine da split; nessun cambio dei log. |
| I3 | Cache a frame fissi, protocollo acquisizione/rilascio, budget completo | Prova di safety/progresso con primitive SBCL; fault injection, sospensione dei reader, saturazione, ABA; miss separato e bloccante dichiarato. |
| I4 | Backend paginato e directory multilivello, writer/GET/recovery | Confronti differenziali col residente per PUT/GET/DELETE, snapshot, prepared/outcome, riavvio e crash a ogni frontiera; indice maggiore della RAM senza swap. |
| I5 | Controllore/attuatore per Serie e misuratore iniettabile | Avvio e cambi automatici in entrambe le direzioni, limiti RSS/picchi, delta senza buchi, swap coerente, writer e snapshot concorrenti. |
| I6 | Migrazione operativa e qualifica | Failpoint prima/dopo ogni swap, rientro controllato, benchmark caldo/freddo e write amplification; gate Linux x86-64 e macOS ARM64. |

I2 aggiunge un formato derivato ancora non collegato al runtime: fino a I4
il rollback rimuove i componenti senza migrare dati utente. Dopo I4 il primario resta
derivato da segmenti, manifest e decisioni esistenti: un indice nuovo incompleto
non diventa autorevole. Il rollback deve ricostruire una vista compatibile
con la memoria disponibile, senza presumere che il dataset paginato entri in RAM.
Commit, SEAL, snapshot, WAL e recovery conservano i loro punti di decisione;
l'ADR di integrazione dovra' precisare le frontiere di pubblicazione dell'indice.
