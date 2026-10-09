# Orizzonte dei commit

Il modulo [`arcdocdb.mvcc`](../../src/mvcc/package.lisp) realizza il registro
limitato dei CSN in volo di [ADR-0046](../adr/0046-orizzonte-con-registro-limitato.md).
Una prenotazione appartiene a un solo Archivio. Il CSN nasce alla chiusura del
lotto o della decisione multiserie, secondo
[ADR-0038](../adr/0038-orizzonte-di-visibilita.md).

## Ambito

Il registro assegna identità, conserva i commit pendenti e determina l'orizzonte
`H`. Non scrive WAL, non pubblica indici, non decide COMMIT/ABORT e non conferma
client. Il completamento rimuove un CSN dal registro solo quando il proprietario
ha già soddisfatto le condizioni di visibilità.

Il normale GET non consulta questo registro. Gli snapshot useranno `H` per
stabilire quando possono iniziare. Il [registro snapshot](registro-snapshot.md)
aggiunge annuncio della soglia, attivazione e scadenza dei contesti. Versioni
trattenute, parcheggio e risveglio restano da integrare. La query
dei tre contatori fornisce una lettura coerente sotto mutex, utile al controllo e
all'osservabilità; non è ancora il percorso ottimizzato di lettura atomica di `H`
previsto da ADR-0038.

## Contratto

| Interfaccia | Effetto |
|---|---|
| `crea-registro-csn` | Alloca il registro, inizialmente vuoto, con `ultimo = H = recovered-max`. |
| `crea-prenotazione-csn` | Alloca una volta il contesto di commit, legato a quel registro. Non consuma credito. |
| `riserva-csn` | Incrementa il CSN e lo registra indivisibilmente; restituisce il CSN da sigillare. |
| `concludi-csn` | Verifica contesto e CSN originale, libera il credito e restituisce `H` e un flag di avanzamento. |
| `leggi-prenotazione` | Restituisce stato e CSN coerenti. |
| `leggi-orizzonte` | Restituisce `H`, ultimo CSN e numero di pendenti coerenti. |
| `orizzonte-raggiunto-p` | Verifica `H >= s`, senza attendere il commit. Rifiuta un CSN futuro. |
| `capienza-registro-csn`, `stato-registro-csn` | Espongono capacità immutabile e salute. Nessun array è esportato. |

La capacità predefinita è **256**, proposta già presente in ADR-0046. L'attuale
budget di implementazione accetta **1–65.536** slot. Non è un limite documentale;
limita memoria e lavoro sotto mutex. Una capacità elevata richiede misure prima
dell'uso: ogni completamento visita tutte le `K` parole.

## Identità e riuso

```text
prenotazione libera
        │ riserva-csn
        ▼
prenotazione attiva ── concludi-csn(CSN originale) ──► conclusa
        ▲                                                │
        └──────────────── nuova riserva ──────────────────┘
```

Il contesto conserva slot e CSN; gli eventi conservano **il CSN originale** fino
al proprio consumo. Una prenotazione conclusa può essere riusata solo quando i
vecchi consumatori sono terminati. Un vecchio evento con il CSN precedente è
rifiutato anche se lo slot o il contesto sono stati riusati. Il consumatore non
ricava la propria identità rileggendo un contesto già riusato.

Due riserve simultanee dello stesso contesto sono serializzate: la seconda
trova lo stato attivo e fallisce. Due completamenti dello stesso CSN sono
serializzati: il secondo trova lo stato concluso e fallisce. Il registro rimane
sano; questi errori non liberano credito.

Non si usa `CSN mod K`. Un commit lento può essere superato da molti commit
conclusi senza perdere la propria identità o consumare crediti per la distanza
tra il suo CSN e l'ultimo assegnato.

## Atomicità e ordinamento

Tutte le mutazioni e le query coerenti usano il mutex del singolo Archivio.
Non esiste un mutex del Server, una coda globale o una sezione critica per ogni
documento. Le sezioni non contengono I/O, callback, allocazione di contesti o
attese di altri commit. Il mutex può essere conteso; il costo sotto carico resta da
misurare, senza attribuirgli una latenza massima dimostrata.

SBCL documenta acquisizione e rilascio dei mutex come barriere di memoria
([manuale, Barriers](https://www.sbcl.org/manual/#Barriers)). Il proprietario
pubblica gli indici prima di chiamare `concludi-csn`; il registro non sostituisce
il protocollo dell'indice. Per una multiserie il completamento avviene solo dopo
l'applicazione su tutti i partecipanti richiesti da
[ADR-0041](../adr/0041-multiserie-segmenti-autosufficienti.md).

Prima del rilascio si calcolano e verificano conteggio e nuovo orizzonte,
escludendo lo slot da concludere:

```text
se rimangono pendenti: H = min(CSN pendenti) - 1
altrimenti:           H = ultimo CSN assegnato
```

Il valore non diminuisce. Slot, contatori e stato della prenotazione sono
modificati sotto lo stesso mutex. Se una transizione iniziata viene abbandonata
con uscita non locale, il cleanup marca il registro `FAULTED` prima di rilasciare
il mutex. Non si tenta un rollback parziale. Un'uscita dopo una transizione
completa può nascondere il valore restituito al chiamante: la prenotazione
conserva comunque l'identità. Il proprietario deve gestire anche questa finestra.

## Errori e recovery

| Caso | Esito |
|---|---|
| Capacità esaurita | `resource-exhausted / :csn-capacity`; nessuna mutazione. Il writer conserva il lotto aperto o parcheggia il contesto con budget e scadenza. |
| Ultimo CSN = `2^64 - 1` | `resource-exhausted / :csn-sequence-exhausted`; nessun wrap, nessun incremento. |
| Configurazione fuori intervallo | `invalid-argument / :csn-registry-configuration` prima di allocare il registro. |
| Prenotazione già attiva | `invalid-argument / :csn-reservation-active`. |
| Completamento duplicato o CSN discordante | `invalid-argument / :csn-completion-identity`; nessun credito liberato. |
| Slot, conteggio o frontiera incoerenti | `invariant-violation`, registro `FAULTED`. |
| Registro `FAULTED` | Riserve, completamenti e query di visibilità falliscono; solo salute e capacità restano consultabili. |

`recovered-max` deve comprendere **tutti i CSN osservati** dopo il recovery
dell'Archivio, incluse Serie e decisioni multiserie, prima di ammettere traffico.
Il primo CSN nuovo è quel massimo più uno. Non si ripristinano prenotazioni
volatili e non si riapre un registro guasto: il proprietario isola l'Archivio e
ne ripete il recovery. Il registro non aggiorna autonomamente il massimo quando
si apre una Serie; questo è un obbligo del coordinatore di apertura.

## Risorse e prestazioni

- Array specializzati `u64`: `8K + 16` byte di payload per il registro, oltre a
  header, oggetto e mutex. Una prenotazione ha un'ulteriore parola `u64` e il
  piccolo oggetto di contesto.
- Nessuna crescita dinamica, lista di completamenti storici o oggetto per documento.
- Ricerca dello slot libero a partire dal cursore, al massimo `K` parole; ricalcolo
  di `H` al massimo `K` parole. Il cursore non dipende dal CSN.
- I contesti si allocano all'ammissione, poi si riusano. I valori `u64` restituiti
  come interi Lisp possono richiedere boxing oltre il range fixnum. Non è stata
  dimostrata assenza di allocazioni o scalabilità su molti core.

## Tracciabilità e stato della qualifica

| Requisito / invariante | Realizzazione | Evidenza ancora necessaria |
|---|---|---|
| REQ-MVC-008, INV-M6 | Riserva indivisibile, slot esclusivo, identità al rilascio, scansione limitata. | Concorrenza reale, saturazione, commit lento, riuso e completamenti tardivi. |
| REQ-MVC-006, INV-M5 | CSN crescente senza wrap, inizializzazione da massimo recuperato. | Confini u64 e integrazione con versioni dei documenti. |
| REQ-MVC-005, INV-M4 | Predicato `H >= s` e avanzamento dopo pubblicazione. | Registro snapshot, soglia, writer, scadenza e FI-11/FI-12 integrati. |
| REQ-AFF-004, INV-A8 | Errori tipizzati e budget finito, transizione interrotta fail-stop. | Iniezione di uscite non locali e gestione del guasto da parte dell'Archivio. |

Questo incremento conserva la compilazione del solo prodotto e i controlli
statici, con output originali nel [catalogo](../../spikes/results/2026-10-09-csn-origine/catalogo.lisp).
Non aggiunge né esegue test funzionali o benchmark. La compilazione non prova la
correttezza concorrente: i requisiti restano **progettati**, senza dichiarazioni
di qualifica C1, copertura o prestazioni del motore.
