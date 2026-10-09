# Registro degli snapshot

Il registro in [`src/mvcc/`](../../src/mvcc/) realizza registrazione, attivazione,
validazione e scadenza dei contesti di snapshot secondo
[ADR-0038](../adr/0038-orizzonte-di-visibilita.md),
[ADR-0020](../adr/0020-csn-snapshot-isolamento.md) e
[ADR-0045](../adr/0045-modello-di-esecuzione.md).
Usa l'[orizzonte CSN](orizzonte-csn.md) del proprio Archivio.

## Ambito e risorse

Un registro per Archivio; array specializzati di capacità `K` fissa, con
`1 <= K <= 65.536`. I contesti delle richieste sono preallocati e riutilizzabili.
Il registro conserva CSN, generazione, scadenza, limite dell'attesa e stato per
slot. Non copia documenti e non detiene riferimenti fisici ai segmenti.

`crea-registro-snapshot(csns, K, lifetime-ticks, wait-ticks)` richiede durate
esplicite, positive, con `wait-ticks <= lifetime-ticks`. Il controller traduce
la configurazione in queste unità; il default architetturale della durata resta
un'ora. Tutti i valori `now` provengono dalla **stessa base di tempo monotona**
dell'ambiente, sono `u64` e devono essere campionati nuovamente per ciascuna
operazione. Nessun clock globale, thread, callback o timer autonomo è creato
dal registro. I campioni di thread diversi possono arrivare in ordine diverso;
il registro non li interpreta come una regressione del clock.

I quattro array `u64` e l'array di stati `u8` occupano `33K` byte di payload,
più due parole comuni, oggetti, header e mutex. Il contesto possiede due parole
per generazione e copia del CSN. L'esaurimento di `K` rifiuta una registrazione
prima di abbassare la soglia. Il superamento di `now + lifetime-ticks` o della
generazione `u64` è un rifiuto esplicito, senza wrap.

## Interfacce

| Interfaccia | Contratto |
|---|---|
| `crea-contesto-snapshot` | Prealloca il contesto associato al registro; nessun pin acquisito. |
| `registra-snapshot(context, now)` | Restituisce generazione, CSN `s` e flag di attività. Se non pronto, il proprietario parcheggia il contesto. |
| `attiva-snapshot(context, generation, now)` | Restituisce `T` solo con `H >= s` e deadline valida, oppure `NIL` se ancora in attesa. Non blocca in attesa del commit. |
| `verifica-snapshot(context, generation, now)` | Restituisce il CSN solo per identità attiva e non scaduta; nessun mutex sul percorso riuscito. |
| `verifica-snapshot-in-buffer` | Stesse guardie; scrive il CSN in una word del buffer privato del worker. Il buffer resta intatto su rifiuto. |
| `termina-snapshot(context, generation)` | Rimuove il pin. Idempotente per la stessa identità già terminata/scaduta; una vecchia identità non termina una nuova registrazione. |
| `scadi-snapshot(registry, now, max-slots)` | Visita al più il budget configurato, restituisce visite e scadenze e avanza un cursore circolare. |
| `soglia-snapshot`, `deve-trattenere-p` | Letture acquire senza mutex per retention e potatura logica delle versioni. |
| `leggi-registro-snapshot` | Contatori coerenti sotto mutex, per osservabilità. |

Una **generazione** è l'identità del contesto; il **CSN** è l'identità della
vista. Due snapshot possono avere lo stesso CSN, incluso zero su Archivio vuoto.
La generazione cresce senza riuso nel registro; non è una seconda versione del
documento. Ogni evento e reader conserva la generazione originale.

## Registrazione e visibilità

Ordine delle operazioni, sotto il mutex degli snapshot:

1. Verificare contesto, capacità, generazione e deadline, senza mutazioni.
2. Campionare `H` dal registro CSN.
3. Invalidare con generazione zero il contesto e lo slot da riusare; barriera completa.
4. Pubblicare `soglia = min(soglia, H)`; **barriera completa**.
5. Campionare `s = ultimo CSN assegnato` e il nuovo `H`.
6. Scrivere metadati e stato; pubblicare prima la generazione dello slot e poi
   quella del contesto, con barriere di scrittura.

Lo snapshot è immediatamente attivo se il secondo campione soddisfa `H >= s`;
altrimenti resta in attesa. La soglia è già annunciata durante l'attesa: i writer
possono trattenere le versioni necessarie prima della prima lettura.

Il controller accoda un nuovo compito quando l'orizzonte avanza e richiama
`attiva-snapshot`. Non mantiene un worker occupato, non fa polling illimitato e
non risveglia i contesti mentre possiede il mutex CSN. Le liste di parcheggio,
le notifiche e l'ammissione delle richieste rimangono responsabilità dello
scheduler; questo modulo espone la macchina a stati e i suoi limiti.

## Letture, riuso e barriere

Una lettura con snapshot conserva la generazione originale ed entra nell'epoca
del worker. Poi:

```text
verifica snapshot → ricerca indice/cache/segmento → verifica snapshot → risposta
       └──────────────── stessa epoca del reader ──────────────────┘
```

La verifica finale si esegue **anche sul miss**. Una vista scaduta non può
trasformarsi in un falso «non trovato». I campioni di tempo iniziale e finale
sono distinti; riusare il primo potrebbe nascondere la scadenza durante la ricerca.

La validazione legge la generazione del contesto, quella dello slot e i metadati;
una barriera di lettura precede la seconda verifica di entrambe le generazioni.
Il CSN dello slot è confrontato con la copia posseduta dal contesto. Qualsiasi
riuso che attraversi la lettura invalida la generazione prima di cambiare i campi:
il reader rifiuta la risposta, senza retry o accesso alla nuova incarnazione.

I reader riusciti non prendono mutex. Solo il percorso che scopre metadati
interni incoerenti prende il mutex per pubblicare `FAULTED`. La lettura della
soglia può essere conservativa e trattenere più versioni; non introduce per
questo un risultato scorretto.

Queste primitive usano accessi word/u8 di SBCL sulle piattaforme a 64 bit
di [ADR-0017](../adr/0017-piattaforma-e-io.md), con barriere esplicite
([manuale SBCL](https://www.sbcl.org/manual/#Barriers)). Non si estende il
contratto a runtime o architetture diverse. Il disassemblato locale ARM64
conserva i carichi word, le barriere `DMB ISHLD` e la scrittura del risultato;
è un'ispezione statica del codice generato, senza eseguire i percorsi.

## Retention, scadenza e reclaim

Prima di aggiornare lo slot dell'indice con un commit `c`, il writer usa
`deve-trattenere-p(registry, c)`: se `soglia < c`, deve conservare la versione
sostituita **prima** della pubblicazione. La soglia iniziale può restare più
bassa del minimo dei CSN registrati; viene ricalcolata quando si rimuovono pin.
Una versione con fine validità `a` può essere rimossa dalle versioni trattenute
quando `soglia >= a`, rispettando ancora le epoche dei reader.

`MAX-U64` è la soglia senza pin. Lo stesso valore può essere un CSN di snapshot
valido: al limite u64 nessun nuovo commit può superarlo; i confronti restano
corretti. Il conteggio distingue presenza e assenza dei pin per le metriche.

La durata massima parte dalla registrazione, **includendo l'attesa iniziale**.
A `now >= deadline` lo snapshot è scaduto. Un'attesa che raggiunge la propria
deadline produce `resource-exhausted` all'attivazione; uno snapshot attivo
scaduto produce `snapshot-too-old`. Il timer rimuove i pin scaduti anche senza
ulteriori richieste, con una scansione circolare limitata. Una sola scansione
di `K` slot ricalcola la soglia dopo il gruppo di scadenze: non una scansione
per ogni snapshot. La cadenza del timer è una responsabilità del controller.

La validazione rifiuta un contesto scaduto per tempo anche se il timer non lo ha
ancora visitato; fino a quella visita il pin è conservativo. Terminazione e
scadenza **non liberano i riferimenti fisici** dei reader già ammessi:
[EBR](../adr/0016-epoch-based-reclamation.md) deve proteggerli fino al termine
del compito: le [primitive di epoca](epoche-e-reclaim.md) espongono ingresso,
uscita e frontiera per i segmenti; il [contesto di lettura](compiti-lettura.md)
collega ingresso, controlli snapshot e cleanup. Indice/cache e confine dei pool
restano da integrare. Il contesto si riusa solo quando tutti i vecchi consumatori sono
terminati. Questo modulo non elimina segmenti o strutture dell'indice.

## Guasti e stato della qualifica

Le transizioni composte usano cleanup fail-stop: un'uscita non locale dopo
l'inizio della mutazione marca il registro `FAULTED`; non si tenta un rollback
parziale. Un'incoerenza di conteggio, soglia, stato o copia del CSN produce un
errore tipizzato. I registri snapshot e CSN guasti interrompono le letture di
visibilità. Il proprietario isola l'Archivio e ripete il recovery; gli snapshot
volatili non sopravvivono al riavvio.

| Requisito | Realizzazione introdotta | Qualifica ancora necessaria |
|---|---|---|
| REQ-MVC-004 | Deadline, errore `snapshot-too-old`, timer con budget. | Confini del tempo, scadenza durante il lookup, controller e timer reali. |
| REQ-MVC-005 | Annuncio, cattura di `s`, attivazione solo con `H >= s`. | Writer/index/versioni trattenute integrati, FI-11/FI-12. |
| REQ-MVC-007 | Soglia annunciata prima della cattura, ricalcolo e guardie di riuso. | Ordini concorrenti reali x86-64/ARM64, saturazione e generazioni u64. |
| REQ-MVC-003, REQ-CMP-007 | Pin logici distinti dalle epoche dei reader. | EBR, potatura, compaction e reclaim integrati. |
| REQ-AFF-008 | `K`, deadline, generazioni e passi del timer limitati. | Carico, cadenza del timer e costi sotto mutex. |

Il [catalogo delle evidenze](../../spikes/results/2026-10-09-snapshot/catalogo.lisp)
conserva compilazione del solo prodotto, controlli statici e disassemblato,
compreso il primo rifiuto del linter: scambiava l'opzione `(:read)` della
barriera per una chiamata a `CL:READ`. Il riconoscimento esclude ora i keyword;
le chiamate reali a `READ` restano vietate. Nei comandi locali non sono stati aggiunti o eseguiti
test funzionali, auto-test del linter, prove concorrenti o benchmark.

I requisiti restano **progettati**. Non si dichiara qualifica C1, copertura,
assenza di allocazioni misurata o completamento di MVCC. L'interfaccia in buffer
evita il ritorno di un intero Lisp per il CSN sul percorso previsto del reader;
scalabilità, costo delle barriere e allocazioni vanno ancora misurati.
