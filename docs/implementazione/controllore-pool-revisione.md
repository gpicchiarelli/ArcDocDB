# Prima lettura del controllore di calcolo

Lettura statica del 2026-10-13 sulla base
`4344d9e1f2ceb45e5fa3d5076b57d09505e69ac3`, eseguita da un agente diverso
dall'autore del codice. Sono stati letti tutti i sei file del package,
l'integrazione ASDF, le fixture scheduler, il [contratto](controllore-pool.md),
il [metodo](controllore-pool-metodo.md), ADR-0011/0031/0035/0045 e lo
[standard](../affidabilita/standard-di-codifica.md).

Il componente è C3. I dodici punti C1 sono utilizzati come lista aggiuntiva:
questa lettura non attribuisce classe C1 alla policy e non sostituisce build,
copertura, misura o controllo generale. Nessun test è stato eseguito dal
revisore. I risultati delle campagne devono essere collegati separatamente.

| File letto | SHA-256 |
|---|---|
| `src/scheduler/package.lisp` | `1ae4001c0349d4e9f7d282e9c05129573149d50418880073789a46fa18b1968b` |
| `src/scheduler/types.lisp` | `3b174be0919f8b27312ada4071d831c3753d62bb12be99d7e9394c48dcab474a` |
| `src/scheduler/build.lisp` | `58baf595f221826c64e3fb38344242c3bdf403d65904193bf1a8e06e09d7c336` |
| `src/scheduler/read.lisp` | `5cdc1e5b7ba97c9aab66a5acaf74336b0df33144e24104e0242b7fc2552a1ae2` |
| `src/scheduler/policy.lisp` | `92b3ca3a81ae0b3ac342a63e5fe5c5d7524091a63065b0232c14c57ee80c4aac` |
| `src/scheduler/update.lisp` | `e35a704ee0b9445c559a768de048169a8e39837a6df21843d8df58215c482472` |
| `tests/scheduler/support.lisp` | `d8aeec53062cccf036c693ff709baf1086e331f8a247a5693b82c0ff1c7a4401` |
| `tests/scheduler/controller.lisp` | `04a223429449e26eae1a651e74b7b736e5952a08f1cee6aacf066c53c7ab0c7d` |
| `arcdocdb.asd` | `3593d876c5096f55a472f742f1de5f74eb4518f561953e75518d2e6efe93a23e` |

## Dodici punti

1. **Requisiti e ADR:** REQ-THR-001, REQ-CON-005 e REQ-AFF-008/013
   identificano policy, separazione dal percorso caldo, limiti e ingressi
   iniettati. ADR-0011 richiede EWMA/AIMD/isteresi; ADR-0031 limita C3 a
   scelte di risorse. La policy non scrive alcun dato C1/C2 e non dichiara un
   pool completo o sensori di REQ-OBS-001/002.
2. **Invarianti:** owner corrente, target minimum..maximum, since≤last;
   campioni e intermedi aritmetici limitati, nessun wrap del tick. La factory
   valida gli ordinamenti e i tipi degli slot preservano i domini. Le fixture
   leggono il getter pubblico per confrontare sensori, candidato e clock;
   le iniezioni quiescenti di target e clock verificano entrambi i rami
   invariant. Il helper AIMD è provato con un simbolo estraneo.
3. **Errori:** tutte le ragioni input sono esplicite; owner e stato si
   verificano prima di validare il campione. La validazione completa precede
   il primo setf. Configurazione e rifiuti campione sono coperti da fixture
   staticamente presenti, incluse le iniezioni dei rami invariant e della
   direzione privata inattesa. Il tipo symbol del helper rende raggiungibile
   il suo rifiuto esplicito. Non si nascondono condizioni e non esistono
   handler o rollback nel prodotto.
4. **Limiti:** non ci sono cicli, ricorsioni, lock, attese o retry nei sei
   sorgenti. L'aritmetica EWMA ha massimo intermedio 2^31; i tick sono interi
   limitati a 2^40−1. I due confronti temporali usano soltanto input validati
   e campi locali coerenti. Pending è un esito di una chiamata breve, non un
   thread in attesa dell'attuatore.
5. **Allocazione:** factory separata; nessuna lista, closure, copia, hash,
   allocazione esplicita o razionale crescente nei passi e nel getter.
   `%pool-range` usa tipo fixnum e confronto scalare, senza costruire una
   specifica di tipo a runtime. L'assenza di heap osservato resta da misurare
   con sensore C4 verificato, non si deduce dalla sola lettura.
6. **Dati verificati:** il getter espone sette valori scalari dopo owner e
   invarianti, senza pubblicare rappresentazione o capacità mutabile.
   L'aggiornamento espone target bounded e quattro esiti chiusi. Nessun dato
   di richiesta, Serie o storage entra o esce dal package.
7. **Decisioni:** inventario completo dei predicati espliciti e dei delegati
   qui sotto. Le soglie composte hanno fixture che rendono decisivo ogni
   operando. Per C3 non è prescritto MC/DC; non si inferisce tale proprietà
   da numeri di test o sb-cover.
8. **Proprietà:** owner immutabile creato sul thread scheduler, getter e
   aggiornamento owner-only, API non rientranti e prive di callback. Nessuno
   stato globale mutabile. La fixture foreign-owner conserva lo snapshot del
   proprietario; otto thread costruiscono ciascuno un controllore privato,
   dopo una barriera del solo harness con timeout di 15 secondi.
9. **Tracciabilità e verifica:** definizioni e test nominano i requisiti;
   ASDF carica il package dopo execution e i test scheduler nel controllo
   generale. Build, heap, copertura e `make check` non sono stati eseguiti
   dal revisore; il minimo C3 è 95% di istruzioni e rami, non una percentuale
   già raggiunta dalla presenza dei test. Le campagne e le loro lacune vanno
   lette nei [risultati](controllore-pool-risultati.md).
10. **Standard:** safety 3, tipi completi delle funzioni, slot typed/read-only
    e copier NIL, docstring e OWNER/SHARED. Corpi entro 60 righe e complessità
    contenuta; nessuna nuova macro, syscall, `ignore-errors` o eccezione di
    compilazione. Non è stata identificata una deviazione da registrare;
    lint e build rimangono verifiche eseguibili distinte dalla lettura.
11. **Parallelismo:** nessuna scrittura comune per richiesta né dipendenza
    fra Serie; la policy opera nella voce scheduler/metriche dell'elenco
    chiuso. I test paralleli verificano isolamento locale e determinismo
    delle EWMA, senza misurare scalabilità, fairness o isolamento del motore.
12. **Durabilità:** nessun cambiamento persistente, file, lease, batch,
    controller Serie o CSN toccato. Non esiste un punto di atomicità su disco
    da dichiarare per questo componente.

## Inventario dei predicati

L'inventario è una lettura del sorgente, non un rapporto di copertura.
Tipi degli slot, forme package/ASDF e codice prodotto dalle forme di
definizione restano nell'ambito dei file completi del denominatore sb-cover.

| ID / funzione | Predicato o ramo esplicito | Effetto |
|---|---|---|
| B01 / `%pool-range` | `and` di tipo fixnum e range lower..upper | Entrambi veri restituisce il valore; altrimenti invalid typed prima della mutazione. |
| B02 / factory | Maximum presente | Usa maximum, oppure default 2×cores. NIL esplicito usa il default. |
| B03 / factory | Initial presente | Usa initial, oppure minimum. NIL esplicito usa il default. |
| C01 / `%check-pool` | Owner EQ thread corrente | Estraneo invalid prima di ogni lettura di stato pubblica o scrittura. |
| C02 / `%check-pool` | Minimum≤target≤maximum | Incoerente invariant `:pool-state`. |
| C03 / `%check-pool` | Since≤last | Incoerente invariant `:pool-state`. |
| G01, G02 / getter | Initialized, due occorrenze | Last/since numerici dopo campione, NIL prima. |
| E01 / `%pool-ewma` | Reset | Campione×256, oppure floor della media 1/8. |
| D01 / `%pool-direction` | `or` di P99≥1200×256 e `and` coda<256/CPU≤300×256 | Shrink con precedenza. |
| D02 / `%pool-direction` | `and` coda≥queue-high×256, CPU<700×256, P99≤1000×256 | Grow soltanto se shrink falso e tutti veri. |
| D03 / `%pool-direction` | Fallback cond | Hold esplicito. |
| A01 / `%pool-apply` | Case grow/shrink/hold/otherwise | Target successivo bounded; direction privata estranea invariant. |
| A02 / `%pool-apply` | Target successivo uguale al corrente | Hold e reset, anche quando una direzione incontra il limite. |
| A03 / `%pool-apply` | Direzione diversa dal candidato | Avvia nuova permanenza; nessuna azione. |
| A04 / `%pool-apply` | Elapsed<dwell | Hold; soglia inclusiva agisce nel fallback. |
| A05 / `%pool-apply` | Fallback cond | Applica target e resetta candidato hold/since=tick. |
| S01 / `%pool-sample` | Initialized | Prima chiamata senza delta; dopo, valida almeno period. |
| S02 / `%pool-sample` | Delta≥period | Troppo breve/regressivo invalid prima delle scritture. |
| U01 / aggiornamento | `or` non-initialized/gap>2×period | Reset sensori e permanenza; gap esatto 2 period continua. |
| U02 / aggiornamento | Reset | Candidato :hold e since=tick, poi valutazione del campione corrente. |
| U03 / aggiornamento | Actual diverso dal target | Sensori aggiornati, pending con target identico e reset della permanenza. |

Delegati dell'aggiornamento: `%check-pool` prima e dopo, `%pool-sample`
completo prima del setf, tre `%pool-ewma`, `%pool-direction` e `%pool-apply`.
Il getter delega un `%check-pool`. Le chiamate a `%pool-range` hanno limiti
letterali o derivati dalla configurazione validata; non sono loop o retry.

## Lacune e rischi dichiarati

Nessun bug funzionale è stato identificato nella lettura della versione
descritta. La rilettura finale include i due verificatori invariant, il
rifiuto del simbolo direction estraneo e la barriera degli otto thread;
gli SHA sopra identificano questi sorgenti. Nessun ramo va rimosso dal
denominatore prima di valutare il 95%.

L'oracolo parallelo della suite confronta i sensori EWMA; gli esiti della
policy nelle inversioni P99 sono controllati da vettori attesi manuali.
Il C4 `tools/pool-controller-bench.lisp` aggiunge un oracolo startup della
traccia grow/shrink con CPU/P99 costanti, confrontando tutte le sette uscite
ad ogni passo, più pending e hold. È una trace finita specifica, non una
dimostrazione esaustiva della policy o del feedback reale.

La policy non rileva ogni alterazione arbitraria dei campi privati. Una
crescita pending resta target anche se P99 peggiora; nessuna revoca o
scadenza dell'attuatore è implementata. Gap resetta l'evidenza di permanenza
e può ritardare indefinitamente un comando in presenza di campioni troppo
sporadici; è una scelta conservativa, non una garanzia di progresso.

Actual è un numero attestato dal caller, non contato dal componente.
Conferme sbagliate o metriche errate possono produrre scelte sbagliate di
risorse, ma la policy non può modificare dati C1/C2. Mancano attuatore,
protocollo di comandi obsoleti, wake/park e shutdown; RSK-12 resta aperto su
feedback reale e calibrazione. La verifica finale del prodotto e del C4 e
i byte delle prove sono responsabilità delle campagne separate.
