# Integrazione dei worker nella base comune

Il merge `a185aee95b2e40f267df26ec41024dafc0fb9b7a` unisce il worker
pubblicato `9f9f6bd3b7a219211c8f08fe9e5f2b669b849796` alla base
`edb043b1234479cadab0f39b7adf1918786fa91e`. Questa è la versione del
codice verificata dal controllo completo del 9 ottobre 2026.

Il [controllo dello scope](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-writer-worker-main/scope-integrazione-processo.lisp)
conserva l'esportazione dei tre alberi Git e i confronti dei blob. Tutti i
4.100 path della base sono presenti: 4.096 hanno gli stessi byte. I quattro
file comuni modificati sono ASDF, indice della documentazione, package
execution e inventario delle eccezioni di copertura. I venti file execution,
test e tool worker sono identici alla versione pubblicata; anche i 140 path
aggiunti rispetto alla base coincidono con quella versione. Il
[bundle degli adattatori](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-writer-worker-main/integrazione-adattatori.lisp)
conserva il confronto completo, i sorgenti degli adattatori e i relativi hash.

Il [record completo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-writer-worker-main/check-integrazione-processo.lisp)
è OK/STABLE, exit 0: 459 test in dodici suite più smoke, compilazione senza
avvisi, lint su 111 file senza errori, tracciabilità senza errori e 2.173 link
verificati. Il checker delle evidenze usa il valore Makefile predefinito di
2.048 MiB; i 4.096 MiB del processo esterno di registrazione non sostituiscono
quel valore. Il [master degli spike](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-writer-worker-main/spikes-integrazione.lisp)
è COMPLETE: dieci spike completati con exit 0 e sorgenti stabili. Il catalogo
[delle copie originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-09-writer-worker-main/catalogo.lisp)
conserva anche i registri di conservazione e il payload gzip originale.

Le letture statiche indipendenti dello scope e dei contratti confermano la
coesistenza dei worker con Serie, WAL, indice, snapshot, epoche e letture
nell'assemblaggio ASDF. Il controllo completo qualifica quell'assemblaggio.
La qualificazione specifica del worker resta quella dei
[risultati originali](writer-worker-risultati.md): 23 test dedicati,
12 mutanti rilevati e venti campioni locali senza allocazioni heap misurate.
Le campagne dedicate non sono state ripetute per questa integrazione; i loro
limiti e denominatori di copertura restano invariati.

Rimane aperto il collegamento operativo fra lease del worker e lease della
Serie. Il prossimo incremento deve acquisire entrambi prima del primo pop,
rilasciare la Serie prima di chiudere il writer e conservare gli obblighi
quando la seconda acquisizione o la chiusura restituisce busy. L'assemblaggio
verificato non prova quel protocollo, throughput o scalabilità del motore,
né chiude il gate C1 complessivo o dimostra MC/DC.

Alla ripresa dell'11 ottobre la primaria contiene ulteriori modifiche dello
scanner CBOR. La pubblicazione mantiene quindi esplicita la base qualificata
`edb043b`: l'esito qui conservato non qualifica automaticamente quei nuovi
sorgenti.

## Verifica dell'insieme aggiornato

Il merge `68890dea18f1b010b582be338fbbfaf0361a39fd` unisce la precedente
consegna `e96f99b` alla primaria `f16e978ad026e9307fde67425c35b2a8dbd1e731`.
Include scanner CBOR minimo, ricostruzione dell'indice e tutti i relativi
runner. Il [confronto nativo Git registrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-writer-worker-latest/identita-worker-processo.lisp)
conferma l'identità dei file execution, test e tool worker rispetto alla
consegna precedente. La lettura indipendente, conservata nel
[bundle integrale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-writer-worker-latest/integrazione-adattatori.lisp),
conferma anche l'identità dei sorgenti CBOR e indice rispetto a `f16e978`
e la registrazione congiunta in ASDF. Non sono emersi conflitti di contratto.

Il [controllo completo dell'11 ottobre](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-writer-worker-latest/check-completo-processo.lisp)
è OK/STABLE, exit 0, su una copia congelata del merge: 600 test in quindici
suite più smoke, compilazione senza avvisi, lint su 116 file senza errori,
tracciabilità senza errori e 2.230 link verificati. Il checker delle evidenze
ha passato il controllo con il budget Makefile predefinito di 2.048 MiB.
Il [master degli spike](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-writer-worker-latest/spikes-completi.lisp)
conserva i dieci esperimenti e il payload gzip originale; il
[catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-writer-worker-latest/catalogo.lisp)
registra le copie integre e i processi conclusi.

Questa verifica qualifica l'assemblaggio con CBOR e ricostruzione indice
sulla base `f16e978`; supera il limite della precedente consegna relativo
a quei sorgenti. Restano aperti il protocollo operativo worker–Serie e i
gate complessivi del motore descritti sopra. Le campagne dedicate worker
mantengono il proprio ambito originale e non sono state ripetute.
