# Pubblicazione e sostituzione della cache

Questa suite C4 completa le letture concorrenti della
[fixture GET](../get-performance/README.md) con inserimenti e sostituzioni
nella stessa partizione. Il prodotto in `src/cache/` resta il riferimento
da verificare. Requisiti: REQ-CCH-001/002/004, REQ-AFF-002/008 e REQ-CON-004.

## Metodo fissato prima dell'esecuzione

Una classe da 8192 byte, un insieme di otto posti e almeno 32 record distinti
forzano la sostituzione senza dipendere dalla funzione di hash. Le cornici
v1/v2 e le CRC sono costruite con l'oracolo indipendente già usato dalla
fixture GET. Chiavi, valori, CSN e location sono distinti; le parole alte
non sono sempre zero. I valori hanno 16 oppure 4096 byte.

Ogni worker possiede il proprio buffer di destinazione. Record e attese
sono preparati prima del lancio; gli input condivisi restano immutabili.
Ogni HIT deve coincidere con **l'intero record atteso** e il valore,
con sentinelle prima e dopo il range autorizzato. MISS restituisce due
frontiere zero; VERIFY-FAILED con soli record validi fallisce la prova.
Gli esiti di inserimento BUSY e UNAVAILABLE sono leciti, ma non provano
che una pubblicazione sia riuscita.

I casi deterministici verificano sequenza dispari, credito esaurito e
posto disabilitato. Una copia corrotta deve essere scartata; un input
corrotto deve propagare l'errore prima di mutare qualsiasi array della cache.
La prova di contesa tiene il mutex della striscia
da un altro thread con rendezvous limitati: l'inserimento deve restituire
BUSY prima del rilascio. Le prove con quattro worker mescolano inserimenti
e ricerche su più record dei posti disponibili. HIT ed espulsioni devono
essere osservati esplicitamente; un test costituito soltanto da MISS/BUSY
non è sufficiente.

Tutte le attese e i join hanno un limite. Ogni condizione seria del worker
torna al controller come errore della prova; il cleanup termina e attende
i worker ancora vivi prima di accedere ai risultati. Gli input vengono
ricontrollati dopo tutti i join.

## Ambito delle conclusioni

Le prove deterministiche verificano gli stati dichiarati, mentre lo stress
esercita interleaving scelti dallo scheduler. Il solo avvio con rendezvous
non prova esecuzione simultanea sui core né ogni finestra interna del
seqlock. Questa suite non misura velocità, allocazioni o MC/DC e non chiude
la qualifica C1, la memoria debole o i gate del motore.

## Risultato locale del 2026-10-17

Superati **14 casi**: otto deterministici, quattro scenari con quattro
worker e due prove di contesa controllata. La verifica integrata ha
compilato senza warning e superato tutti i test di prodotto, lint,
tracciabilità e collegamenti: esito OK/exit0, sorgenti STABLE,
106,660 secondi per l'intero comando, senza attribuire quel tempo alla cache.

La tabella conta soltanto il carico misto dei worker; ogni scenario
aggiunge separatamente il controllo iniziale del worker zero.

| Formato / valore | Tentativi | INSERTED | PRESENT | BUSY | HIT | MISS | Espulsioni |
|---|---:|---:|---:|---:|---:|---:|---:|
| v1 / 16 byte | 2048 | 1398 | 430 | 220 | 2109 | 1987 | 1398 |
| v2 / 16 byte | 2048 | 1498 | 325 | 225 | 2138 | 1958 | 1498 |
| v1 / 4096 byte | 2048 | 1606 | 424 | 18 | 2152 | 1944 | 1606 |
| v2 / 4096 byte | 2048 | 1466 | 546 | 36 | 2219 | 1877 | 1466 |

UNAVAILABLE non è stato osservato nello stress; i casi deterministici
lo richiedono per posti tutti disabilitati o senza credito. VERIFY-FAILED
compare soltanto nella fault injection della copia corrotta, come atteso.
Nei due formati la prova del mutex ha restituito BUSY prima del rilascio,
seguito da INSERTED e HIT dello stesso worker. Input immutati e destinazioni
disgiunte sono verificati dopo tutti i join.

Il [catalogo delle prove](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-17-cache-concurrency/catalogo.lisp)
conserva comando, ambiente, impronte dei sorgenti, log e copie dei tre
file della suite. La raccolta verifica l'inventario chiuso e le copie
dei record compressi senza alterare gli originali.
