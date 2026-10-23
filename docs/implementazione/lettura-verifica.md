# Verifica EBR e compiti di lettura

La campagna del 2026-10-11 verifica i contratti già implementati di
[epoche e reclaim](epoche-e-reclaim.md) e [compiti di lettura](compiti-lettura.md).
Il prodotto, le API e i formati rimangono quelli della base integrata `2a0011f`.
Il [metodo preregistrato](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/metodo.lisp)
congela 34 casi EBR, 30 casi di lettura e otto mutanti prima delle esecuzioni
registrate. I controlli esplorativi degli autori non sono evidenza qualificata.

## Casi e osservazioni

Le aspettative sulle epoche e sulle identità sono liste e interi indipendenti.
Le suite osservano le API pubbliche; le immagini private servono alla
conservazione dello stato dopo un rifiuto o a FI esplicite su fixture isolate.
I test di lettura usano registri CSN, snapshot ed epoche reali, token originali
e tempi logici espliciti. I buffer hanno sentinelle prima e dopo il campo scritto.

| Decisioni | Testimonianze previste |
|---|---|
| EBR-D01..D02 | Capacità minime/massime, rifiuti, contatori e crediti di epoca |
| EBR-D03..D04 | Identità zero/vecchie, riuso dei ticket, metadati e stato faulted |
| EBR-D05..D08 | Generazione/credito esauriti, duplicati, pubblicazione e riferimenti conservati |
| READ-D01 | Quattro parole residue variate separatamente e snapshot residuo |
| READ-D02..D03 | Generazione zero, registro estraneo e binding valido |
| READ-D04 | Generazione/CSN della lettura corrente e buffer conservato |
| Conclusione/abbandono | Snapshot terminato o scaduto, tempo regredito, rilascio del pin e fault irreversibile |

Due thread reali competono per lo stesso claim; un reader completa con il
mutex di manutenzione posseduto da un altro thread. La migrazione termina
il primo compito, avanza l'epoca e ammette un secondo worker con uno slot
proprio. Semafori e join hanno budget finiti e nessuna attesa avviene in
un'epoca di lettura attiva. La sequenza scadenza/reclaim è un interleaving
logico fra API pubbliche, distinto dalle gare interne.

La lettura indipendente conferma il mapping parziale; restano slot fuori
range, alcune combinazioni dei metadati, credito nullo in pubblicazione
e anomalie della ricerca dei posti. Soglia stretta e claim esclusivo sono
verifiche aggiuntive, non testimonianze MC/DC delle decisioni EBR-D01..D08.

## Strumento e criteri

Il runner copia 26 file prodotto e sette file di test, usa FASL privati e
processi distinti. Il baseline deve passare esattamente tutti i 64 nomi,
in ordine EBR poi lettura. Ogni mutante esegue soltanto il test nominato:
la rilevazione richiede exit 1 e fallimento runtime di quel test. Avvisi di
compilazione, segnali, timeout e exit nonzero dopo `:complete` sono errori
del worker. Due fixture reali provano SIGKILL 9 ed exit 7 dopo completamento;
il controllo CLI negativo conserva il rifiuto COD-61 come esito fallito.

Gli scope di copertura `epochs` e `read` hanno directory e FASL separati,
eseguono la rispettiva suite e conservano stato SB-COVER e HTML. Numeratori e denominatori sono riportati di seguito, con le lacune.
L'espansione INLINE limita l'attribuzione dei contatori ai file originari.

## Risultati locali e conservazione

La [verifica completa](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/verifica-completa.lisp)
sul freeze `9d07fff` passa **724 test più smoke**, inclusi 34 casi EBR e
30 compiti di lettura, compilando senza avvisi. Tracciabilità, link,
conservazione delle evidenze e gli esperimenti SPK esistenti passano.
La [campagna di mutazioni](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/mutazioni.lisp)
passa il baseline esatto di 64 nomi in ordine e rileva tutti gli otto
mutanti nel rispettivo test runtime: exit 1, nessun segnale, timeout
o errore worker. Le quattro campagne delle fixture reali del runner
conservano SIGKILL 9 con exit 137 osservato ed exit 7 dopo `:complete`,
classificati come `:worker-error`. Il
[CLI negativo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/cli-negativo.lisp)
con `--invalid` rimane `:failed`, exit 1, rifiuto COD-61 atteso.

La prima correzione statica della fixture aveva introdotto una parentesi
in eccesso. Le esecuzioni iniziali rimangono fallite: core exit 2,
baseline di mutazione exit 2 classificato errore di compilazione, parent
mutazione e copertura exit 1. Il percorso con suffisso `.lisp` era
accettato come directory e il suo fallimento di baseline non è una
verifica CLI negativa. La [rettifica preregistrata](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/rettifica.lisp)
conserva il metodo originale e fissa il solo cambio sintattico prima
delle ripetizioni, senza variare casi, mutanti o prodotto. Una seconda
lettura ha verificato sintassi e proprietà dei worker sul blob corretto.

| Scope SB-COVER | Espressioni | Rami | Senza conteggio |
|---|---:|---:|---|
| EBR, sei file | 651/838 (77,68%) | 85/110 (77,27%) | 187 espressioni, 25 rami |
| Lettura, quattro file | 108/306 (35,29%) | 11/52 (21,15%) | 198 espressioni, 41 rami |

Gli [HTML EBR](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/raw/reader-coverage-epochs-finale/cover-index.html)
e [lettura](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/raw/reader-coverage-read-finale/cover-index.html)
concordano con i dettagli e con i byte dei sorgenti annotati, secondo
la [lettura indipendente](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/copertura-revisione.lisp).
`epochs/read.lisp` mostra 0/88 espressioni e 0/10 rami anche se i test
eseguono ingressi e uscite riusciti: l'attribuzione INLINE impedisce di
interpretare questi zeri come assenza di esecuzione delle API.

Il [catalogo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/catalogo.lisp)
usa nomi LEAF. L'[audit delle copie](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/audit-copia.lisp)
verifica byte e SHA-256 dei grezzi: runner, log, copie dei sorgenti,
FASL privati, coppie descriptor/payload native e stati SB-COVER compressi
senza perdita. I riferimenti di consultazione generati per record
compressi sono dichiarati esplicitamente; i record nativi nei gruppi
`raw` mantengono byte, nomi payload, esiti e provenienza originali.

## Limiti e CI

La CI del primo commit pubblicato `00ce558` è passata su Ubuntu e macOS,
oltre alla documentazione ([run 38135803760](https://github.com/gpicchiarelli/ArcDocDB/actions/runs/38135803760)).
La CI della successiva integrazione è in attesa alla raccolta dei risultati locali.
Il mapping delle decisioni rimane parziale e la
copertura non misura MC/DC. La preregistrazione resta distinta dagli
esiti effettivamente osservati.

Restano fuori dalle prove la finestra interna INLINE, l'ingresso che
restituisce NIL dopo un cambio d'epoca e l'interruzione interna del cleanup.
Non si attesta memoria debole, MC/DC, zero heap, latency, qualifica C1
completa o chiusura di fase. GET, SegmentManager, durability e crash
recovery richiedono integrazione e campagne ulteriori.

## Integrazione con hash delle chiavi

Prima dell'unione della PR #8, il ramo principale è avanzato a `8101eb8`.
Il [metodo d'integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/integrazione-metodo.lisp)
conserva le prove precedenti e preregistra una nuova verifica completa
della base comune. Una lettura indipendente conferma che i 26 file
prodotto della campagna reader, i sei file di test e il mutator sono
invariati; ASD e copertura mantengono le suite e gli scope di entrambi
i rami. I [risultati integrati](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/integrazione-risultati.lisp)
confermano **770 test più due controlli smoke**, 34 casi EBR e 30 di lettura,
con sorgenti stabili. Passano il self-test del driver di copertura, le
fixture reali dei processi reader e snapshot e i dieci esperimenti SPK;
record e diagnostiche originali sono conservati nel catalogo.

Il ramo principale è poi avanzato a `96c0f4f` con i sette file del nucleo GET,
integrati senza cambiare la campagna reader. Il
[metodo aggiuntivo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-11-reader-verification/integrazione-get-metodo.lisp)
registra compilazione, suite esistenti, controlli degli artefatti e nuova CI
completa prima dell'unione. Questo aggiornamento non introduce test
funzionali GET e non ne attesta la qualifica.
