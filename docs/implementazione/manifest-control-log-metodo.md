# Metodo di verifica del manifest

Metodo definito prima della campagna. Ambito: ricostruzione in memoria
del manifest di una Serie, versioni 1 e 2; nessuna prova di I/O durevole.

## Fixture e oracle

Le fixture impacchettano EDIT, cornice e SEAL con scrittura bytewise e
CRC bitwise del harness. Non usano gli encoder EDIT del prodotto. Le
storie dichiarano stato completo iniziale, rotazioni e sostituzioni di
compaction; un oracle a liste interpreta gli insiemi senza chiamare
decoder, hash table o funzioni di ripiegamento del prodotto.

La suite confronta ACTIVE, lunghezze, esiti, CLOSED, rimossi, sconosciuti
e prossimo ID. Distingue CSN zero da esito assente. Permuta sezioni e
duplicati, conserva l'ordine degli EDIT, prova limiti u64 e lunghezze
da 64 a `#xffffffff`.

Ogni troncamento della fixture deve preservare soltanto i lotti sigillati:
nessun manifest utilizzabile senza completo iniziale. Una corruzione
testimoniata successiva deve prevalere su un errore semantico o un budget
degli EDIT anteriori. Si provano esattamente i limiti, il superamento e
il consumo dei duplicati fisici. Il buffer resta invariato; avvelenarlo
dopo la costruzione non cambia le query.

## Esecuzione parallela

Una prova usa quattro thread SBCL, ciascuno con otto ricostruzioni di
una Serie indipendente, e confronta i risultati con l'oracle. Il padre
costruisce inoltre un manifest comune; dopo il riuso del buffer sorgente,
tutti i worker lo consultano in sola lettura. I thread hanno input e
workspace separati per le 32 ricostruzioni private. I join hanno
un limite finito e un fallimento di worker deve fallire la prova. Questa
è una prova di correttezza concorrente, senza inferenze di throughput,
scalabilità o isolamento delle latenze del motore.

La campagna di mutazione esegue una baseline integra prima delle copie
modificate. Seleziona solo i test manifest, verifica i marker di avvio e
completamento e distingue rilevamento runtime, sopravvivenza, errore di
compilazione, errore prima dei test ed errore dei worker. Un exit nonzero
dopo il marker di completamento non conta come rilevamento. Tutti i
mutanti copiano la baseline integra già verificata. Le copie possono
eseguire in parallelo con directory, cache FASL e log propri, tramite
`--jobs 4`. La baseline resta seriale. Il self-test dello strumento
include un handshake fra processi che fallirebbe con avvio seriale,
exit nonzero e guasti di avvio e raccolta. Le attese dei subprocessi della
campagna non hanno un timeout automatico; questa campagna usa soltanto
mutazioni note che conservano i limiti dei cicli.

## Evidenza

`tools/record-command.lisp` registra comando, ambiente, revisione,
hash prima/dopo, exit code e output originale. La campagna definitiva
parte soltanto quando sorgenti, test e tool sono stabili. Fallimenti e
tentativi precedenti restano distinti e conservati.

La copertura `recovery` include scanner e tabella DECISION; il riepilogo
del manifest seleziona soltanto i suoi file, conservando il denominatore
grezzo e lo stato originale `sb-cover`. Le forme mancanti non diventano
esclusioni approvate. Due letture C1 controllano invarianti, errori,
proprietari, cicli e predicati composti; copertura e mutazioni non
certificano MC/DC o il recovery del motore.
