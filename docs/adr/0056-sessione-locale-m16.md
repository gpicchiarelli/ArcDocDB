# ADR-0056 — Contratto della sessione locale M16

- **Stato:** Profilo M1 autorizzato per l'integrazione di produzione dall'autore;
  estensione completa M16 ancora proposta; profilo qualificato localmente
  nel [rapporto M1](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md)
- **Data:** 2026-10-17
- **Rapporto con la specifica:** completa il framing di ADR-0029 e i budget richiesti
  da ADR-0055; non cambia formati persistenti o semantica del motore
- **Riferimenti:** [contratto proposto](../implementazione/sessione-locale.md),
  [ADR-0055](0055-interfaccia-locale-unix-socket.md), REQ-IPC-001…REQ-IPC-004,
  [SPK-11](../../spikes/SPK-11-unix-socket/README.md)

## Contesto

La priorità del socket Unix è accettata. Prima di implementare M16 occorre
fissare byte order, envelope, correlazione, errori e budget. Un listener di
prova non può certificare recovery, ammissione, commit o isolamento del motore.

## Decisione proposta

L'indicazione di proseguire con startup → recovery → admission → PUT/GET del
2026-10-22 autorizza il [profilo M1](../implementazione/production-unix-m1.md),
che fissa prima del codice payload dei quattro comandi, limiti piu' piccoli,
un proprietario e una richiesta in volo. Il profilo riusa frame, correlazione,
errori e confini durevoli di questo ADR. Non adotta i default di concorrenza
del contratto esteso; la loro proposta e i relativi gate restano aperti.

Il [contratto della sessione](../implementazione/sessione-locale.md) propone
un prefisso u32 big-endian e un solo item CBOR deterministico, handshake
versionato, ID strettamente crescenti nella connessione e risposte fuori ordine.
Le capacità sono assegnate ai proprietari I/O all'avvio; ammissione e contatori
del trasporto sono locali al proprietario, senza nuovo lock globale per richiesta.

Si fissa il trasporto prima del dispatcher: la prima versione definisce HELLO
e PING; ogni operazione dati richiede contratto del payload e percorso del motore
verificati prima di comparire fra le capacità annunciate. Nessuna operazione
applicativa, incluso PING, viene ammessa prima del gate di recovery del motore.

La sola serializzazione nuova è lo stream della connessione. L'assegnazione
del proprietario è fatta all'apertura, non per documento o Serie. Il trasporto
non ha un punto di atomicità durevole: restano quelli dei rispettivi comandi.
Nessun retry implicito o deduplicazione attraverso riconnessioni.

## Conseguenze

Driver e server condividono fixture binarie indipendenti. Un documento massimo
e una chiave massima entrano nello stesso frame; il budget dell'envelope resta
distinto dalla profondità e dimensione del documento. Le scadenze assolute
impediscono che piccoli progressi rinnovino indefinitamente un'attesa.
I valori sono politiche proposte, non risultati di prestazione.

## Alternative considerate

- Un protocollo testuale: introduce un secondo vocabolario e un parser aggiuntivo.
- ID riutilizzabili appena inviata la risposta: richiedono più stato e rendono
  ambigue risposte ritardate; l'esaurimento u64 impone una nuova connessione.
- Budget globale conteso a ogni richiesta: aggiunge una serializzazione evitabile.
- Esporre subito PUT/GET come echo: non verifica le garanzie del database.

Il pattern di correlazione e versionamento è pubblicato nella
[specifica JSON-RPC 2.0](https://www.jsonrpc.org/specification), senza adottarne il formato;
il vocabolario binario resta quello di [RFC 8949](https://www.rfc-editor.org/rfc/rfc8949.html).
L'implementabilità locale usa il contrib
[SBCL sb-bsd-sockets](https://www.sbcl.org/manual/index.html#Local-Domain-Sockets).
Questi riferimenti giustificano i meccanismi, non i default proposti.

## Valutazione

SPK-11 verifica il trasporto e i relativi oracoli in processi reali. Restano
da provare handshake/dispatcher, accesso con utenti distinti, pool e memoria
del prodotto, gate di recovery, perdita della risposta dopo commit e crash.
Il contratto del profilo autorizzato precede il suo codice; l'estensione M16
richiede ancora una decisione specifica. La prova non chiude
RSK-14/RSK-16 né promuove i requisiti IPC.
