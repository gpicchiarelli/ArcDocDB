# Verifica funzionale delle prove OUTCOME del resolver CLOSED

La suite dedicata aggiunge **42 test**: 8 per ordinamento e ricerca delle
prove, 13 per costruzione e 21 per lettura. Segue il
[metodo preregistrato](get-resolver-metodo.md), senza modificare formati,
requisiti o codice del resolver. Le
[evidenze native](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-resolver-outcome/)
conservano comandi, output e file grezzi completi, compresi i FASL come dati.
La [raccolta complementare degli output degli spike](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-resolver-spikes-raw/)
preserva anche i FASL generati fuori dalla directory generale delle prove.

## Risultati locali

Il freeze `e75caed6694e4a2c141b5ff155dfe0d418191c75` supera `make check`
senza avvisi: 1.011 test di modulo e due smoke check.
Passano regressione, controlli statici, tracciabilità,
collegamenti, verifiche delle evidenze e controlli degli spike.
La suite resolver passa anche nel processo separato di copertura.
Entrambi i record riportano exit code 0, working tree iniziale pulito e
gli stessi **731 path/blob** prima e dopo, verificati contro il freeze.
I risultati appartengono a questo commit, precedente alla presente pagina.

L'integrazione con `main` è verificata al freeze
`15fc91c824b0c49ad91dfdfc9845d4e9e2148102`: `make check` R3 passa
con 1.011 test di modulo e due smoke check, exit 0 e **735 path/blob**
stabili, corrispondenti al commit. La copertura R2 ripete separatamente
i 42 test e conserva gli stessi conteggi della tabella seguente.
La [raccolta dell'integrazione](https://github.com/gpicchiarelli/ArcDocDB/tree/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-13-get-resolver-integration/)
conserva integralmente anche il precedente `make check` R2, exit 2:
i test erano passati, ma sette collegamenti di un README temporaneo
di raccolta impedivano il controllo documentale. Quel modello è stato
rinominato `.txt`; R3 verifica il controllo completo dopo la correzione.
R2 non è qualificato come esito complessivo positivo.

Le fixture writer CLOSED usano file reali readonly, header/SEAL/manifest
v1 e v2 e encoding CRC indipendente. Gli attesi comprendono offset e valori
letterali, TXID/CSN u64, OUTCOME fisicamente riordinati, prima prova dei
duplicati e discordanza separata delle word alta/bassa. I limiti del payload
passano esatti e falliscono un byte sotto, conservando la mappa precedente.
Un buffer sorgente riusato non altera la mappa; la coda dopo `valid-bytes`
rimane intatta e non viene letta dal costruttore.

La cache prepared calda rilegge ancora OUTCOME dallo stesso FD. CRC, CSN o
TXID discordanti impediscono la risposta anche con valore già in cache;
una seconda prova identica non sostituisce una prima prova corrotta.
Le FI persistenti ripristinano i byte della sola fixture. Errori, uscita
non locale e scadenza dello snapshot dopo copia provvisoria liberano GET/EBR.
Il caso prepared senza OUTCOME conserva CSN/prova zero: con candidato
pubblico positivo fallisce prima con `:resolver-candidate-csn`; non è una
prova autonoma del guard interno `:resolver-missing-outcome`.

## Copertura diagnostica isolata

SB-COVER viene azzerato dopo caricamento e prima dei soli 42 test resolver.
Il tool salva lo stato grezzo prima di validarlo e confronta i conteggi
ricavati dai dati con quelli usati dall'HTML. Il rapporto contiene soltanto
i sette file CLOSED; ACTIVE e le altre suite non entrano nei conteggi.

| File | Espressioni eseguite/totali | Rami eseguiti/totali |
|---|---:|---:|
| package | 0/1 | 0/0 |
| types | 6/29 | 0/0 |
| scan | 246/307 | 27/40 |
| sort | 346/387 | 44/50 |
| rows | 147/167 | 12/16 |
| build | 184/260 | 21/38 |
| read | 227/265 | 27/40 |
| **Totale** | **1156/1416 (81,64%)** | **131/184 (71,20%)** |

Zero rami significa denominatore zero, senza percentuale inventata.
La copertura è una diagnosi della suite, non una misura MC/DC. Non si
attribuiscono velocità, allocazioni, RSS o risultati di mutazioni.

## Revisione e limiti

Una lettura indipendente prima del freeze ha corretto due aspettative
della fixture: vettore vuoto e budget byte compatibile con il budget lotto.
La lettura successiva dei record verifica tutti i path/blob, i 42 nomi e
l'ordine dei test, lo stato grezzo e i conteggi di ciascuna pagina HTML.
Il prodotto non ha richiesto correzioni in questa campagna.

Restano aperti qualifica C1, decisioni non esercitate e MC/DC. Questa suite
non verifica ACTIVE, prove EDIT, storico, directory mista, rotazione/reclaim,
pubblicazione concorrente o integrazione del server. Non promuove requisiti
e non chiude la Fase 0. La CI della pull request ripete `make check` su Linux
e macOS e controlla i documenti separatamente; i suoi esiti appartengono al
commit effettivamente pubblicato, distinto dal freeze locale qui riportato.
