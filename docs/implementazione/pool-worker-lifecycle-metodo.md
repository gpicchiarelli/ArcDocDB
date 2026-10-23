# Metodo preregistrato dell'attuazione logica dei worker

Preregistrazione del 2026-10-13, prima delle campagne congelate, sulla base
`105ae0dd28a6ae3e7ee60ab1477815a49b1b350b`. Scope: cinque nuovi sorgenti
`src/scheduler/lifecycle-{types,build,read,worker,update}.lisp`, modifiche
del package e di ASDF, test e strumento locale C4. Il componente C3 collega
il target del controllore a richieste e conferme per worker preallocati.
Non crea thread, non esegue attese, non segnala semafori e non modifica
ready, lease, obblighi o collegamenti Serie dei componenti C1.

L'attivazione e il ritiro sono logici: soltanto il thread del contesto può
confermare una richiesta, dopo la barriera completa del worker IDLE.
Il conteggio effettivo proviene dalle conferme; l'invio di un comando non
equivale al suo completamento. La porta conserva proprietari e contesto;
una generazione monotona impedisce riuso o sovrascrittura di comandi
pendenti. Un owner fisico e la sua porta non si trasferiscono.

## Verifiche previste

- Factory della porta sul proprietario del contesto e registrazione sul
  proprietario del controllore; configurazione valida, contesti liberi,
  porte e owner distinti, massimo coerente e prefisso iniziale attivo.
  Copia del vettore di porte; input originario modificabile senza cambiare
  il registro pubblicato. Domini e configurazioni errati devono essere
  rifiutati prima di pubblicare o legare una struttura incompleta.
- Valori packed e generazioni ai limiti; separazione fra comando e
  conferma, conservazione della richiesta pendente e rifiuto di riuso,
  regressione o esaurimento prima di qualsiasi mutazione.
- Comando identico già applicato, passaggio attivo/inattivo e ritorno
  attivo. Conferma soltanto sull'owner reale. Gli stati CLAIMED, RUNNING,
  BATCH, FINISHING, RESCHEDULE e FAULTED non attestano IDLE; lease, debito,
  riferimento e fault devono restare integri dopo un rifiuto o rinvio.
- Tutti i conteggi di una lettura si riferiscono a conferme osservate;
  richieste in corso non entrano nel numero dei worker attivi. Il registro
  controlla owner e legame, intervalli e relazione richiesta/conferma.
  Non dedurre quiescenza globale da una lista ready EMPTY o BUSY.
- Wrapper del campione: preflight completo di metriche, tempo, conteggi e
  budget di generazione prima delle scritture; target conservato quando
  ci sono conferme pendenti. Un errore del campione non deve lasciare
  comandi o un controllore aggiornati solo parzialmente.
- Tracce finite con crescita, riduzione e inversione del carico, worker
  occupato e conferma ritardata; prove su due owner reali con deadline nel
  solo harness. Verificare che nessun comando sostituisca quello ancora
  pendente e che il feedback attenda le conferme.
- Lettura del codice per tipi, safety 3, dichiarazioni, REQ/OWNER/SHARED,
  funzioni bounded, nessun callback, thread o attesa nel prodotto e nessuna
  scrittura globale condivisa nel percorso di una richiesta. Le letture
  automatiche indipendenti non sono una certificazione umana.

## Copertura e misure

Il gate C3 è almeno 95% di espressioni e rami, confrontato tramite interi
esatti senza arrotondare. Lo scope include tutti i cinque nuovi file e
`src/scheduler/package.lisp`, compresi i percorsi generati dalle strutture;
nessuna esclusione. I vecchi file del controllore e dei worker non sono
attribuiti al nuovo componente. Il lettore verifica l'inventario completo,
concordanza fra dato nativo SB-COVER e indice HTML, denominatori non nulli,
identità e posizioni di ogni percorso mancante. I checkpoint pubblici
SAVE-COVERAGE dopo il caricamento preservano i segni di startup prima che
il runtime recuperi i code component; non alterano i segni. Conservare il
dato nativo e tutti gli HTML originali anche nei tentativi falliti.
SB-COVER non attesta MC/DC.

La misura heap separa prodotto e coordinamento del test. Startup, factory,
thread, sincronizzazione, oracoli e GC sono fuori dal tratto misurato.
Warmup 128 cicli, cinque repliche da 4096 cicli, safety 3; nessun reset o
wrap delle generazioni. Il sensore conserva byte heap, tick grezzi,
conteggio completato e sink deterministico; un clock nullo significa
sotto risoluzione, non tempo nullo. Nessuna soglia di tempo o prestazione
viene ricavata dalla campagna e il carico esterno resta incontrollato.

La campagna A applica sull'owner corrente del contesto una fixture C4 di
comandi packed preallocata. Ogni ciclo conserva la progressione monotona
e verifica ritiro, conferma ripetuta, attivazione e conferma ripetuta.
La fixture può scrivere una richiesta a quiescenza senza concorrenti e conservando
la progressione del protocollo, ma è dichiarata privata e non qualifica il coordinatore.
La campagna B crea durante startup due contesti su owner reali distinti,
con prefisso iniziale attivo, e misura soltanto update/lettura del registro
sul coordinatore nelle condizioni hold e pending. Le barriere del test
restano fuori dal sensore heap. Crescita, riduzione e conferme realmente
concorrenti si verificano nei test d'integrazione; non si presentano come
una misura priva di allocazioni del relativo harness.

Lo strumento C4 deve rilevare un'allocazione deliberata, un sink errato,
un risultato di API diverso dall'oracolo, un clock sotto risoluzione,
CLI invalida, destinazione preesistente e raw parziali dopo un errore.
Il lettore di copertura deve respingere bit, lunghezze, duplicati e schema
HTML malformati, conteggi discordanti e gate sotto soglia. Compilazione
senza warning/style-warning e self-test precedono le misure del prodotto.

Ogni processo di qualifica congelato usa `tools/record-command.lisp`:
argv, ambiente, output originali, esito e identità sorgenti iniziale/finale.
Cache dedicate evitano contaminazioni. I tentativi falliti rimangono prove
fallite; nessun raw mancante è ricostruito o promosso. SHA e byte originali
degli artefatti pubblicati sono verificati. Park/wake fisico, avvio e join,
shutdown, worker morti, I/O, admission, sensori reali e taratura restano
fuori scope: questa campagna qualifica l'attuazione logica bounded.
