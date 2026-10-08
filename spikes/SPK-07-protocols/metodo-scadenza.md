# SPK-07 — Metodo preregistrato: scadenza, reader ed epoche

Metodo registrato il 2026-10-08 prima dell'implementazione e delle esecuzioni.
Ambito: solo `scadenza.lisp`, questo metodo e nuovi artefatti esclusivi in
`spikes/SPK-07-protocols/out/`. Common Lisp/SBCL, `safety 3`, nessun motore,
benchmark, modifica delle decisioni o operazione Git.

## Fonti e interpretazione

Letti ADR-0033 §§8–9 (errori definiti, limiti controllati), ADR-0038 §§3–4
(registrazione, soglia, attesa `H >= s`, verifica dopo la ricerca), ADR-0020
(durata massima e `snapshot-too-old`), ADR-0016 (EBR), architettura
§§Reclaim/Snapshot e MVCC, `06-mvcc-e-snapshot.md`, INV-M1/M2/M4 e INV-R1.
Si usa soltanto il significato di H: il vecchio anello di ADR-0038 §2 è già
sostituito da ADR-0046, come indicano architettura e intestazione di ADR-0038.

Il pin snapshot rappresenta l'iscrizione del CSN nel registro, non un puntatore
diretto al segmento. Scadenza, rimozione del pin, potatura, ritiro ed eliminazione
sono passi distinti. Un reader entrato pubblica la propria epoca e la mantiene
fino all'uscita, anche se nel frattempo lo snapshot scade. La risposta viene
validata dopo la ricerca: una lettura già iniziata può accedere a bytes protetti,
ma restituisce `snapshot-too-old` se lo snapshot è scaduto alla validazione.
Validazione e fissazione della risposta sono un unico passo astratto.

## Modelli finiti e oracoli

1. **Registrazione:** un documento, versioni immutabili 0/1, un writer con
   assegnazione CSN, lettura della soglia, pubblicazione e avanzamento di H
   separati; uno snapshot con annuncio conservativo `min(soglia,H)`, acquisizione
   di s e nascita separati; due letture. Si enumerano gli interleaving, compresa
   la soglia campionata prima dell'annuncio. Il valore atteso deriva dal CSN
   dello snapshot e dalla storia logica fissa, indipendentemente dalle location
   mantenute. Nascita e prima lettura richiedono H >= s; entrambe le letture
   devono restituire il valore atteso.
2. **Lifetime:** stato iniziale raggiungibile con snapshot S0 a s=0, S1 a s=1,
   H=1, versione corrente 1 e versione 0 trattenuta. Una pubblicazione atomica
   ulteriore porta a CSN/H=2. Due risorse esterne immutabili (versioni 0/1),
   tre tentativi di lettura (due di S0, uno di S1), due campioni per lettura,
   epoca globale 0..2, due ritiri e due reclaim al massimo. Ogni lettura separa
   ammissione/pubblicazione epoca, ricerca location, due accessi, validazione
   della risposta e rilascio dell'epoca. Una ricerca dopo potatura può fallire
   solo per uno snapshot ormai scaduto, con risposta `snapshot-too-old`.

Tick globali 0..2; scadenza eleggibile a tick 1 per S0 e 2 per S1. Sono soltanto
un ordine astratto per enumerare le corse: non modellano un orologio, la durata
reale delle lease o una garanzia in secondi. L'evento di scadenza è il punto
astratto di invalidazione. Non si inferisce una garanzia temporale da un tick.

Oracoli: vista immutata per ogni accesso ammesso; nessun accesso a bytes
eliminati; nessuna ammissione su snapshot scaduto; risposta positiva solo quando
attivo al punto di validazione; soglia ricalcolata sul minimo dei pin rimasti
dopo ogni rimozione; reclaim soltanto senza riferimenti logici e dopo tutte le
epoche <= epoca di ritiro. Il confronto di epoche è stretto (`reader > r`).

Si controlla che da **ogni** stato lifetime raggiunto esista un percorso verso
il terminale (pubblicazione, tick finali, scadenze, rilascio pin, completamento o
rifiuto di tutti i reader, potatura, ritiro e reclaim). Si usa raggiungibilità
inversa sul grafo completo; non basta osservare un solo terminale. Questo prova
solo drenabilità con scheduling astratto che esegue i passi abilitati, senza
garanzia di progresso per uno scheduler che non li esegue.

## Controlli negativi e witness

Mutanti obbligatori: `:expiry-ignores-readers` elimina una risorsa dopo la
scadenza ignorando le epoche attive; `:admit-after-expiry` ammette nuovi reader;
`:no-threshold-recount` lascia la vecchia soglia dopo rimozione del pin minimo.
L'ultimo è un errore di riconta e sovratrattenimento, non una perdita di bytes:
il witness deve rendere espliciti pin residui, soglia attesa ed effettiva.
Controlli supplementari: annuncio della soglia omesso nella registrazione e
nascita anticipata prima di H. Ogni mutante deve produrre la violazione
specifica attesa e un percorso non vuoto, rieseguito e corredato di stati
prima/dopo; un controesempio generico non basta.

I risultati positivi richiedono anche witness di copertura: writer che campiona
la soglia prima/dopo l'annuncio, letture ripetute dello stesso snapshot,
snapshot attivo che impedisce potatura, accesso in corso dopo scadenza e rilascio
pin, rifiuto nuovo accesso, risposta scaduta dopo ricerca, reclaim vecchio con
reader più nuovo ancora attivo, terminale. I conteggi sono misurati dal grafo.

## Esecuzione e registrazione

`CHECK` esportato da `arcdocdb.spk07.scadenza` restituisce una plist con
`:status :ok`, rapporti positivi, controlli negativi, witness, conteggi e
assunzioni. Usa l'esploratore e `require-outcome` del core esistente, caricato
prima del modulo, aggiungendo il confronto esatto della violazione attesa.
Limite iniziale: 500.000 stati per esplorazione; un limite esaurito è fallimento.
Durante l'integrazione il limite è ridotto a 200.000; il grafo osservato
resta di 67.507 stati. Il nuovo blob è verificato nella campagna integrata.

Ogni tentativo di compilazione/check ha un nuovo record leggibile come dati
con `*read-eval* nil`, schema 1, in `out/scadenza-attempt-NNN.sexp`.
Il record conserva argv, cwd e stdin esatto; ambiente SBCL/OS/macchina,
contenuto integrale dei sorgenti (blob senza Git), risultati `compile-file`,
conteggi warning/style-warning, risultato o condizione registrata, limiti e
raw stdout/stderr. Un harness solo Common Lisp, fornito via stdin e conservato
nel record, compila core e modulo in FASL nuovi in `out/`, controlla tutti i
valori di `compile-file`, carica core prima del modulo e invoca un solo CHECK.
Warning e style-warning sono fatali anche durante caricamento/check. Il
confine harness registra condizioni e stato di fallimento, poi esce non zero.

## Tentativi locali

Il tentativo 001 è fallito in compilazione per una parentesi chiusa in eccesso
in `run-model`; core compilato/caricato, CHECK non eseguito, zero warning e
style-warning. Il record `out/scadenza-attempt-001.sexp` conserva l'errore e i
blob precedenti alla correzione. Prima del tentativo successivo si corregge la
parentesi e si rende la copertura delle corse dipendente dalla transizione
effettiva: un accesso dopo scadenza e pin rimosso, e un reclaim mentre il reader
più nuovo è già attivo. Ogni reclaim del grafo positivo è anche verificato
indipendentemente dalla guardia delle transizioni contro riferimenti ed epoche.

Il tentativo 002 ha compilato entrambi i file senza warning/style-warning e
concluso CHECK con `:status :ok`: registrazione 51 stati/69 archi; lifetime
67.507 stati/256.902 archi, 128 terminali e tutti gli stati drenabili; i cinque
mutanti hanno prodotto le violazioni specifiche attese. Il record 002 contiene
tutti i witness, ma il contatore di copertura è errato (2 anziché 12), perché
calcolato dopo un `nreverse` senza conservarne la nuova testa. Prima del
tentativo 003 si corregge il contatore e si richiedono altri due witness:
rifiuto di una nuova lettura dopo reclaim già avvenuto, e lettura ammessa prima
della scadenza che trova la location potata e risponde `snapshot-too-old`.
Queste modifiche non estendono il grafo degli stati.

### Esito finale — tentativo 003

Compilazione e caricamento strict di core e modulo riusciti, `warnings-p` e
`failure-p` entrambi NIL, conteggi warning/style-warning entrambi zero. Una
chiamata a CHECK, `:status :ok`. Record finale
`out/scadenza-attempt-003.sexp`, riletto come dati con `*read-eval* nil` e
confrontato integralmente con la plist salvata; raw stderr vuoto.

| Modello corretto | Stati distinti | Archi | Witness di copertura |
| --- | ---: | ---: | ---: |
| Registrazione | 51 | 69 | 3 |
| Lifetime | 67.507 | 256.902 | 11 |
| Totale | 67.558 | 256.971 | 14 |

Lifetime: 128 stati terminali; tutti i 67.507 stati raggiunti hanno un percorso
verso un terminale. Verificati indipendentemente 3.430 archi di reclaim; in
29.440 stati almeno un ritiro resta bloccato da un'epoca reader <= epoca di
ritiro. Tutti i 14 witness positivi e i 5 negativi sono rieseguiti dalle
transizioni pure; il record conserva azioni e stati completi prima/dopo.

| Mutante | Stati scoperti fino al controesempio | Archi generati | Violazione specifica |
| --- | ---: | ---: | --- |
| expiry ignora reader | 5.291 | 16.154 | accesso dopo reclaim |
| ammissione dopo expiry | 108 | 192 | ammissione su snapshot scaduto |
| riconta omessa | 104 | 186 | soglia effettiva 0, minimo residuo 1 |
| annuncio soglia omesso | 35 | 49 | s=0 attende valore 100, location assente |
| nascita prima di H | 28 | 33 | s=1 nasce con H=0 |

I conteggi negativi sono prefissi BFS arrestati sulla prima violazione, non
esaurimenti del grafo mutante. Il witness del primo mutante mostra reader 0
con epoca 0, scadenza di S0, rilascio del pin, potatura della versione 0,
ritiro all'epoca 0, reclaim che ignora quello slot e accesso al dato eliminato.
Il terzo mostra che, rimossa S0, S1 mantiene un pin a 1 ma la soglia resta 0:
errore di riconta/sovratrattenimento, senza dichiarare perdita di bytes.

File consegnati: `scadenza.lisp` e `metodo-scadenza.md`. Nuovi file locali in
`out/`: record `scadenza-attempt-001.sexp`, `-002.sexp`, `-003.sexp`; FASL
`scadenza-attempt-001-core.fasl`, `-002-core.fasl`, `-002-scadenza.fasl`,
`-003-core.fasl`, `-003-scadenza.fasl`. Il tentativo 001 fallito e il contatore
errato del tentativo 002 restano nell'evidenza, senza sovrascritture.
Il blob del metodo nel record 003 è quello precedente a questa annotazione dei
risultati; il blob del modulo è quello finale compilato. Il gate resta aperto:
questo risultato copre scadenza/reclaim nel dominio finito dichiarato, senza
chiudere memoria debole o gli altri ambiti esclusi. Nessun benchmark o commit.

I record [001](../results/2026-10-08/spk07-scadenza-001-failed.lisp),
[002](../results/2026-10-08/spk07-scadenza-002.lisp) e
[003](../results/2026-10-08/spk07-scadenza-003.lisp) sono conservati nel
repository senza modificare i dati originali. Il limite ridotto e il
marcatore REQ aggiunti durante l'integrazione sono verificati separatamente.

## Limiti e conflitti

Atomicità dei passi e memoria sequenzialmente consistente assunte; barriere,
memoria debole, ARM64/SBCL macchina, filesystem, CRC, crash, I/O, cache,
rilocazione/compaction concreta, wraparound CSN/epoche, transazioni, salute
Serie/Archivio e carichi arbitrari sono fuori ambito. Le risorse rappresentano
bytes/descrittori esterni; directory e frammenti heap restano sotto GC.
Il lifetime parte da una registrazione già conclusa; la race di nascita è
esaurita separatamente, non nel prodotto dei due modelli. L'aggancio fra
controllo attività e pubblicazione epoca è un passo atomico assunto.

Nessuna decisione cambiata. ADR-0016 contiene una frase di ritardo massimo
«millisecondi–secondi, mai di più» insieme alla possibilità che un worker
bloccato trattenga il reclaim: il modello non può sostenere quel limite reale
senza un'ipotesi sul completamento dei reader. Si segnala questa tensione e si
verifica soltanto il progresso terminale sotto scheduling astratto.
