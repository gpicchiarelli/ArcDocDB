# Metodo preregistrato della presa governata dal pool

Preregistrazione del 2026-10-13 sulla base
`900fa93d9e14a252e6a2b5a009d19728b2de34af`, prima delle campagne congelate.
Il nuovo componente C3 è `src/scheduler/pool-claim.lisp`, con export nel
package e registrazione ASDF. Non si modificano sorgenti C1; le loro API
e verifiche vengono delegate senza indebolire proprietà o barriere.
Il [contratto](pool-worker-claim.md) fissa l'ordine dei controlli.

## Prove e revisione

- Porta inattiva con writer realmente pronto: nessun pop, rotazione del
  cursore, perdita o duplicazione di obblighi; ready e contesto conservati.
- Crescita e riduzione richieste dal controllore su owner reali distinti:
  l'attivazione precede il claim, il ritiro precede il polling di ready.
  La forma immutabile di ready viene comunque letta dalla barriera C1.
- Owner estraneo, tutte le fasi non-IDLE compresa FAULTED e IDLE incoerente:
  rifiuto prima di ACK/pop, con prima causa, riferimenti, lease e debito intatti.
  Le fault injection private dichiarate avvengono a quiescenza della fixture.
- Parole del pool incoerenti e conflitto di conferma: nessun claim riportato
  riuscito, nessuna nuova scrittura C3 nei campi d'integrità C1.
- EMPTY e BUSY conservano i risultati e la rotazione prevista da execution;
  INACTIVE restituisce il cursore originario senza scansione ready.
- Ritiro pendente dopo claim: completamento del bridge, conferma dei payload,
  rilascio Serie prima del writer e drenaggio dell'obbligo RESCHEDULE.
  Ring pieno: il writer successivo resta CLAIMED e riceve il proprio routing.
- Una lettura indipendente C3 di ordine dei controlli, owner, coupling privato,
  preservazione degli errori e costi bounded. Safety 3, compilazione senza
  warning/style-warning, lint e tracciabilità devono passare.

## Copertura

Scope completo: nuovo file `pool-claim.lisp` e `src/scheduler/package.lisp`,
senza esclusioni. Gate C3 almeno 95% di espressioni e rami, confronto esatto
su interi e denominatori non nulli. Confrontare dato nativo SB-COVER e HTML,
conservando tutti gli originali, inventario e percorsi mancanti. Il lettore
esistente resta invariato: un adattatore dichiara lo scope nuovo e passa i
self-test del lettore. Non si attribuisce la copertura C1 ereditata al gate
e non si deduce MC/DC dai conteggi.

## Misura locale

Il sensore C4 riusa quello lifecycle già verificato. Cinque repliche da
4096 cicli per campagna, 128 cicli di warmup e GC completa prima del clock.
Factory, API lookup, oracoli e setup sono fuori dal tratto misurato.
Tutti i quattro valori di ogni passo contribuiscono alla verifica del ciclo.

| Campagna | Ciclo e oracolo |
|---|---|
| EMPTY | Porta attiva, quattro shard vuoti; quattro prese, cursori 1/2/3/0 e azione `:unchanged`. |
| INACTIVE | Porta inattiva, quattro shard, cursore 2; quattro prese senza rotazione, azione `:unchanged`. |
| SWITCH | Richiesta privata di ritiro, due prese inattive; richiesta di attivazione, quattro prese EMPTY con cursori 1/2/3/0. Sei chiamate e due generazioni monotone per ciclo. |

SWITCH serializza i ruoli owner/coordinatore in una fixture C4 quiescente;
non qualifica conferme concorrenti né reimposta contesti o generazioni.
Le prove con lavoro vero e controllore concorrente appartengono ai test.
Conservare tick grezzi, heap, sink e numero di cicli completati. Clock nullo
significa sotto risoluzione; non si stabilisce una soglia di tempo né una
taratura. Zero heap osservato non è prova universale di non allocazione.

Prima delle misure, il sensore deve rilevare allocazione deliberata, sink
errato e ciascuno dei quattro risultati difformi, clock sotto risoluzione,
CLI invalida, destinazione preesistente e raw parziali dopo errore.
Ogni qualifica congelata usa `tools/record-command.lisp`, cache dedicate,
argv/output/esiti originali e identità sorgenti iniziale/finale. Fallimenti
rimangono fallimenti; copie e payload compressi sono verificati byte per byte.
Il controllo completo del repository include i dieci spike esistenti.
