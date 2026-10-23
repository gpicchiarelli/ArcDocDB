# Seconda lettura del controllore del pool

Lettura del 2026-10-13 da un agente distinto dall'autore del prodotto, su
`src/scheduler/{package,types,build,read,policy,update}.lisp`, test e
strumento `tools/pool-controller-bench.lisp`. Il componente è C3; questa
lettura usa anche i dodici punti C1 come controllo ulteriore. Ho letto la suite finale di 23 test, inclusa la fixture EQUALP con
cinque differenze singole provate in entrambi gli ordini. Non è una
revisione umana né una certificazione. Il [contratto](controllore-pool.md),
il [metodo](controllore-pool-metodo.md), l'[inventario](controllore-pool-decisioni.md)
e i [risultati conservati](controllore-pool-risultati.md) delimitano le conclusioni.

| Punto | Esito della lettura |
|---|---|
| 1. Requisiti e ADR | REQ-THR-001, REQ-CON-005 e REQ-AFF-008/013 indicati nelle definizioni. ADR-0011 consente la policy iniziale con pochi segnali; ADR-0031 la classifica C3 e ADR-0045 delimita l'esecuzione non bloccante. La modifica realizza il calcolo del target, senza dichiarare un pool operativo. |
| 2. Invarianti | Target entro minimum..maximum e since≤last controllati prima e dopo gli aggiornamenti. Test di fault injection della rappresentazione privata e della direzione inattesa; domini, clamp e proprietario hanno regressioni dedicate. Gli slot tipizzati proteggono la forma della rappresentazione. |
| 3. Errori | INVALID-ARGUMENT distingue configurazione, campioni, periodo e owner; INVARIANT-VIOLATION segnala stato privato. Il campione completo viene validato prima della prima scrittura. Test confrontano la preimmagine dopo rifiuti, anche sullo stato inizializzato/pending. Un errore del caller non viene trasformato in un comando applicato. |
| 4. Limiti | Prodotto senza loop, ricorsione, callback, attesa, thread nuovi o I/O. Core≤65536, worker≤131072, tempo<2^40 e segnali bounded; EWMA usa interi di grandezza fissa, senza denominatori crescenti. |
| 5. Heap caldo | Factory e trace sono startup. Update e getter restituiscono valori scalari e modificano slot preallocati. Il tool preregistra cinque repliche di 4096 cicli con 128 warmup, verifica tutti i sette valori e gli esiti grow/shrink/hold/pending. L'evidenza qualificata e i limiti del contatore sono nei risultati; la sola lettura non prova heap zero. |
| 6. Dati in uscita | Il getter verifica owner e invarianti. I due risultati dell'update arrivano dopo il controllo finale; sette risultati del getter senza riferimenti mutabili allo stato. La policy propone un target: il caller conferma actual e applica le variazioni con un futuro protocollo. |
| 7. Decisioni | Tabella delle decisioni per range, soglie e reset. Test esercitano operandi decisivi, soglie inclusive/esclusive, precedenza shrink, isteresi interrotta, pending, gap e limiti. La copertura include package, factory, helper, accessor e confronto EQUALP generati; i cinque confronti degli slot numerici sono verificati con uguaglianza e differenza singola. Non è MC/DC. |
| 8. Proprietario | Owner immutabile è il thread creatore. Getter e update verificano lo stesso thread; due controller non condividono stato. Commenti OWNER/SHARED collocano il controllo nella voce scheduler/metriche dell'elenco chiuso dell'architettura. |
| 9. Tracciabilità e check | Definizioni e test nominano gli ID esistenti; gli stati globali dei requisiti restano progettato. Build senza avvisi, copertura integrale C3, lint, trace, link e controllo generale devono risultare nello snapshot congelato descritto nei risultati. I dryrun durante gli edit non sostituiscono questi gate. |
| 10. Deviazioni | Safety3, tipi degli slot, configurazione read-only, ftype completi, funzioni brevi, docstring e REQ presenti. Nessuna deviazione nuova richiesta o identificata nella lettura. Gli strumenti C4 hanno self-test positivo/negativo e diagnosi nonzero. |
| 11. Parallelismo | Il controller serializza soltanto la propria amministrazione periodica sul suo owner. Nessun lock né scrittura condivisa per operazione tra Serie, nessun accesso alla ready list e nessuna inferenza EMPTY=quiescenza. Metriche reali, attuatore, park/wake e scaling restano fuori scope. |
| 12. Durabilità | Nessun cambiamento durevole, syscall, cancellazione, segmento, log o lease attraversa questa policy. Non introduce nuovi punti di atomicità o autorizzazioni di rimozione. |

Ho verificato due dettagli che limitano l'interpretazione della policy.
Dopo l'inizializzazione il getter restituisce un tick `since` anche quando
il candidato è `:hold`; NIL è riservato allo stato precedente al primo
campione. Se actual è diverso dal target, la policy continua ad aggiornare
i sensori e mantiene `:pending` anche se P99 peggiora. I test rendono
esplicito questo comportamento; diagnosi, revoca e scadenza dei comandi
sono responsabilità del futuro attuatore, senza claim di sicurezza del
feedback reale.

La revisione non identifica difetti bloccanti nel contratto limitato.
L'esito di pubblicazione dipende dai gate e dagli artefatti dello snapshot
congelato, non da questa lettura né dai dryrun. RSK-12 e lo sviluppo del
pool vivo restano aperti.
