# Prima verifica funzionale GET

La campagna verifica la composizione del [percorso GET](get-record.md) con
indice primario, cache, file readonly, snapshot ed epoche. Il
[metodo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/metodo.lisp) è registrato
prima delle esecuzioni sulla base `65972a4`. Il prodotto rimane distinto dalle
fixture: dati e tempi sono scelti dalla suite, gli esiti sono confrontati con
byte e valori espliciti.

## Metodo e confini

Il [supporto](../../tests/get/support.lisp), con i casi di
[lifecycle](../../tests/get/lifecycle.lisp) e
[segmento/cache](../../tests/get/segment.lisp), costruisce registri, indice con seme,
vista e contesto reali, e file readonly con header, PUT e OUTCOME scritti dalle
API pubbliche. Il valore atteso è una sequenza nota, indipendente dal valore
restituito da GET. I contatori del backend I/O distinguono la costruzione della
capacità dalle letture del compito. Ogni caso possiede risorse separate e
installa il cleanup prima dell'avvio.

| Gruppo | Decisioni | Osservazioni |
|---|---|---|
| Configurazione e lifecycle | GET-D01..D03 | Budget, copie dell'identità, Archivio canonico, rientro, miss corrente e storico, CSN rispetto allo snapshot |
| Target, record e cache | GET-D04..D08 | Identità e frontiera autorevoli, buffer, assenza di I/O nel calcolo, OUTCOME, corruzioni e fallback |
| Risposta e conclusione | GET-D09 | Byte copiati nella risposta privata, range e alias, scadenza e rilascio delle protezioni |

I rifiuti prima della presa in carico devono preservare il compito già attivo
di un chiamante annidato. Gli errori operativi devono rilasciare le protezioni.
La risposta copiata diventa consegnabile soltanto se `concludi-get` ritorna
normalmente: una scadenza successiva alla copia deve ancora impedirne la
consegna. Un prepared richiede la prova dal file anche su hit cache; scratch
insufficiente precede la richiesta della prova e non esegue I/O.

Le modifiche dello stato privato sono limitate alle fixture dichiarate di
fault injection, per provocare incoerenze o danneggiare la copia cache.
L’osservatore I/O usa il backend pubblico e delega agli adattatori nativi
invariati per contare le letture. Nessuno di questi accessi fornisce gli
oracoli di CSN, valore o frontiera.

## Raccolta dei risultati

Le esecuzioni registrate seguono il freeze di sorgenti, documentazione e
indice Git. Compilazione e suite complete, self-test dello strumento di
copertura e scope `get` usano processi separati. La copertura conserva HTML,
stato SB-COVER e FASL privati; misura espressioni e rami, non MC/DC.
I [risultati](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/risultati.lisp), la
[revisione indipendente](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/revisione.lisp)
e il [catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/catalogo.lisp)
conservano i riferimenti originali. Tutti i record sono letti come dati.

## Risultati locali

Le 70 prove GET passano sia nella suite ordinaria sia nella compilazione con
copertura. Il primo freeze `f1bd3cd` passa 840 prove dei moduli e due smoke.
Il [metodo d’integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/integrazione-metodo.lisp)
registra gli aggiornamenti concorrenti CBOR e worker/Serie di `0d0ec4b`.
Il freeze integrato `222b9fd` passa 887 prove dei moduli e due smoke. I sette
file GET e i tre file della suite sono identici nei due freeze; ASD e lo
strumento di copertura conservano anche le route introdotte a monte.

La successiva integrazione del resolver CLOSED di `d155db3` è registrata nel
[metodo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/resolver-integrazione-metodo.lisp)
e nei [risultati](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/resolver-integrazione-risultati.lisp).
Il freeze `5d6490a` compila senza avvisi e passa le stesse 887 prove dei moduli,
due smoke, lint, tracciabilità e link; anche le 70 prove GET strumentate passano.
I 667 sorgenti sono stabili prima/dopo. I file GET e della suite restano identici,
con gli stessi conteggi di copertura. Questi run verificano caricamento e
composizione della suite; la qualifica funzionale del resolver rimane distinta.

L’ultimo aggiornamento `6eeb501` corregge la ricerca delle copie cache già
scartate e aggiunge 19 prove GET performance. Il [metodo d’integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/cache-integrazione-metodo.lisp)
e i [risultati locali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-get-verification/cache-integrazione-risultati.lisp)
registrano il freeze `b2a847e`: le 70 prove GET strumentate passano anche con
questa dipendenza modificata, con gli stessi conteggi riportati sotto, e il
self-test dello strumento passa. I 677 sorgenti sono stabili prima/dopo.
Le suite `get` e `get-performance` e i rispettivi scope rimangono distinti.
La CI completa sul commit pubblicato deve passare 906 prove dei moduli e due
smoke; le precedenti esecuzioni complete restano associate ai propri freeze.

I record dei due freeze attestano rispettivamente 633 e 659 file sorgente
identici prima e dopo le esecuzioni. I self-test reader e snapshot conservano
le classificazioni previste dei worker terminati; i dieci spike sono conclusi
con exit zero, mantenendo `:PASS` per SPK-07 e `:OK` per gli altri.

| File GET | Espressioni | Rami |
|---|---:|---:|
| build | 124/147 | 14/20 |
| lifecycle | 181/195 | 18/20 |
| lookup | 127/140 | 25/26 |
| package | 0/1 | 0/0 |
| segment | 293/312 | 19/24 |
| target | 190/205 | 27/30 |
| types | 11/55 | 0/14 |
| **Totale** | **926/1055 (87,77%)** | **103/134 (76,87%)** |

HTML e stato SB-COVER, letto come dati, coincidono per ciascun file nei freeze
confrontati. I denominatori includono package e types: le definizioni generate e
gli accessor INLINE senza hit locali non ricevono copertura per inferenza.
Gli stati dei run sono conservati separatamente con gzip senza perdita.

Due fixture che ripubblicavano lo stesso CSN sono state corrette durante la
revisione, prima delle esecuzioni. Non è stata necessaria una modifica al
codice di prodotto GET. Tracciabilità, link e conservazione vengono controllati
dopo la pubblicazione locale; la CI viene verificata sul commit pubblicato.

### Preregistrazione dell’ultima integrazione ACTIVE

L’aggiornamento `be9d2dd6816f8c999fcab383702c7a133c061902`, arrivato dopo il
freeze locale, aggiunge sei file del resolver ACTIVE e ne collega il caricamento
in ASD. Prima dell’integrazione si registra il seguente controllo: revisione
indipendente della composizione e delle differenze, conservazione integrale
dei run precedenti, quindi CI completa su Linux e macOS e controllo della
documentazione sul commit finale pubblicato. Sono attese 906 prove dei moduli
e due smoke, con 70 GET funzionali e 19 della suite prestazioni distinti.
La CI deve attestare sorgenti identici prima/dopo e corrispondenti al commit
esatto. I sette file GET, i tre file della suite e la dipendenza cache devono
restare invariati rispetto al freeze locale; la copertura riportata resta riferita
ai suoi run conservati. Questa integrazione verifica il caricamento del nuovo
resolver, senza aggiungere qualifica funzionale ACTIVE o misure di prestazione.

## Limiti

Questa è una prima suite funzionale e i test sono testimonianze parziali
delle decisioni, non una qualifica C1 completa. Restano coppie di indipendenza
MC/DC, mutazione degli operatori, stress concorrente, crash e fault injection
del motore. La finestra interna INLINE di ammissione EBR non viene qualificata
tramite interposizione di funzioni. Restano senza witness il retry dell’indice,
la conclusione di un retry, alcuni guard interni, le letture corte/EOF e gli
esiti cache busy, bypass o unavailable.

Non si attesta resolver storico, endpoint server, scheduler, integrazione
delle frontiere committed, memoria debole, zero heap, prestazioni o chiusura
di fase. Le garanzie del controller e la validità del lotto cui appartiene
OUTCOME rimangono precondizioni del modulo.
