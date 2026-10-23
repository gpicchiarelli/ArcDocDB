# Completamento dei nomi dell'Archivio — metodo

Metodo preregistrato il 2026-10-22 sulla base `f17535d1`, prima del codice
e delle diagnostiche. Compone il gate Archivio e il completamento Serie
gia' esistenti; realizza ADR-0040 §2–3 senza nuovi formati o punti durevoli.

## Ingresso e autorita'

`recovery.bootstrap:stabilizza-nomi-archivio-recuperato(set, decisions,
directories, sources, active, closed, :max-segmenti-serie 65536,
:max-segmenti-totali 1048576)` riceve il set canonico completo del catalogo,
lo stesso replay decisioni e quattro simple-vector paralleli alle viste.
ACTIVE/CLOSED sono i risultati dei reader canonici; ogni directory e set
rimane posseduto dal caller. Namespace, FD, vettori, CONTROL e replay sono
esclusivi/stabili nel pool I/O; traffico non ammesso e nessun close concorrente.

Non si accetta il solo piano CSN precedente come prova dei vettori attuali:
quel piano e' scalare e non trattiene fonti/token. Il gate completo viene
ricreato dai risultati realmente usati, prima degli effetti. Stesso Archivio,
vista esatta e origine del replay restano confronti per EQ.

## Ordine dei passaggi

1. Autorita', forma/lunghezze dei quattro vettori e tipi delle righe;
   count ACTIVE minimo nel budget. Cardinalita' per Serie e somma dei
   segmenti prima delle scansioni delle fonti, senza nuovi contenitori.
2. Tutti i metadata per Serie, riusando le guardie esistenti su ordine u64,
   ACTIVE, consumo CLOSED, CONTROL, ID/FD/EOF/P. Il gate canonico Archivio
   riconferma viste, replay e insieme completo CLOSED; piano solo privato.
3. Preflight I/O dei nomi di tutte le Serie, nell'ordine del catalogo.
   Nessuna rinomina o fsync prima dell'ultimo preflight riuscito.
4. Completamento per Serie riusando l'API esistente; conteggi aggregati,
   somma uguale ai segmenti ammessi e decision log ancora aperto.
   Soltanto al successo escono piano, rinominati e gia' definitivi.

Budget `index`, zero valido come limite che rifiuta l'Archivio non vuoto.
Il limite per Serie comprende ACTIVE, quello totale tutte le Serie.
Il gate CSN conta il proprio limite locale sui CLOSED; il controllo locale
che include ACTIVE e' piu' stretto e precede il gate. Nessuna scansione dei
byte o riapertura; l'osservazione dei nomi e la guardia scalare sono ripetute
prima dell'uso. Un preflight non e' una prenotazione del namespace.

## Guasti, costo e limiti

Il gruppo non e' atomico. Un errore durante il completamento conserva tutte
le fonti gia' completate, anche di Serie precedenti, e propaga la condizione
originale senza risultato parziale, rollback, retry o close. Il parent della
primitiva I/O conserva il suo fail-stop. Il coordinatore mantiene chiusa
l'ammissione fino all'intero recovery; COD-24 generale resta aperto.

I nuovi cicli sono limitati da count e budget. Nessun array/hash/piano per
fonte aggiunto: cursori e conteggi privati, piano scalare e gate canonici
esistenti. Nomi, runtime e gate esistenti possono allocare; nessuna promessa
RSS o zero heap. Sequenza di bootstrap, nessun lock/thread/stato condiviso
nuovo fra Serie. Rimozioni, nuovo ACTIVE, checkpoint, indici, binding runtime,
CSN operativo e ammissione non sono completati da questa API.

## Decisioni da qualificare

| ID | Confine |
|---|---|
| SGA-D01 | Stesso Archivio EQ, quattro vettori semplici, lunghezze e tipi riga |
| SGA-D02 | Budget minimo e per Serie/totale, zero, uguaglianza e meno uno |
| SGA-D03 | Count e somma prima dei metadata; ultima riga invalida senza effetti |
| SGA-D04 | Token e fonti allineati, vista canonica, replay esatto, gate CLOSED completo |
| SGA-D05 | Tutti i preflight dei nomi prima della prima rinomina/fsync |
| SGA-D06 | Ordine del catalogo, mix temporaneo/definitivo, fsync per fonte |
| SGA-D07 | Piano/count completi; somma conteggi, FD decisioni ancora aperto |
| SGA-D08 | Guasto/interruzione, effetti precedenti conservati e causa originale |

Codice committato e sorgenti congelati prima dei processi; due letture
dell'autore e revisione indipendente, agente chiuso. Compilazione forzata
del solo prodotto con avvisi fatali e cache gerarchica privata, lint, trace,
link e lettura del compilato. Diagnostiche registrate incluse quelle fallite;
copie lossless compatte e raccolta comune con quattro worker, inventario
chiuso verificato. Rapporti di staging con suffisso `.source`.
Non si aggiungono o eseguono test funzionali, FI, copertura, mutazioni o
benchmark. SGA-D01…D08, C1/MC/DC e filesystem/crash restano da qualificare.
