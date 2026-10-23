# Production Engine Bootstrap — metodo M1

Preregistrato il 2026-10-22 sulla base `eebd5685`. L'indicazione dell'autore
concentra lo sviluppo sul ciclo startup → recovery → admission della Serie,
riusando il percorso verticale esistente. Le nuove funzionalita', incluso
ulteriore full text non necessario al bootstrap, sono sospese in questo lavoro.

## Perimetro

Una Serie, un owner seriale nel processo I/O, append-only, formati canonici
v1/v2, CRC32C, PUT/GET/tombstone, commit strong, reopen e due SIGKILL reali.
Identita' Archivio/Serie configurate esplicitamente e verificate sugli header.
Non viene inferita una nuova autorita' dal nome della directory. Catalogo
multiserie, 2PC, compaction, MVCC storico e ottimizzazioni restano esclusi.
Nessun formato alternativo, append sui vecchi segmenti o troncatura.

L'ingresso di produzione possiede FD, set di recovery e writer fino a close.
Acquisisce l'esclusione non bloccante sulla directory prima di osservare o
modificare lo storage. Apertura e recovery mantengono admission chiusa;
solo dopo CONTROL, fonti, nuovo ACTIVE durevole, gate CSN, indice e radice
GET completi il motore passa a READY. I fallimenti propagano una condizione
tipizzata e chiudono admission; non restituiscono una capacita' parzialmente pronta.

## Ordine

1. Rafforzare e qualificare la campagna verticale esistente, conservando
   output anche su timeout ed errori. Attesi costanti, 18 scenari/71 processi,
   26 SIGKILL e due controlli negativi; nessuna attribuzione alla qualifica C1.
2. Trasferire il coordinamento nello strato di produzione: creazione esplicita
   in directory vuota oppure apertura autorevole; gate canonici prima degli
   effetti, scelta ID dall'inventario completo, checkpoint con publisher
   esistente, vecchi segmenti readonly e nuove capacita' possedute.
3. Ricostruire l'indice privato dai soli prefissi committed verificati;
   tombstone considerate nel massimo CSN, stesso registro per writer e GET,
   nessuna richiesta ammessa prima della radice completa.
4. Usare le API di produzione nei processi di prova, senza bootstrap/replay
   manuale nel test. Due crash, restart, nuove scritture e verifica da processo
   distinto; oracoli indipendenti su dati, CSN e byte preesistenti.
5. Collegare il client/server Unix esistente al medesimo ingresso, rispettando
   ADR-0055/0056. Il trasporto non apre admission e non ricostruisce lo stato.

## Decisioni e verifiche

| ID | Confine e oracolo |
|---|---|
| M1-D01 | Configurazione e identita' errate; nessun dato mutato |
| M1-D02 | Secondo owner/processo rifiutato dal lock prima degli effetti |
| M1-D03 | Init esplicito solo su storage vuoto, open non inizializza file mancanti |
| M1-D04 | Recovery completo e CRC; coda non sigillata conservata, corruzione dichiarata |
| M1-D05 | Nuovo ID fresco, checkpoint atomico esistente e nomi completati prima di READY |
| M1-D06 | Massimo CSN comprende tombstone; ripresa strettamente successiva, nessun reset |
| M1-D07 | Admission rifiutata in startup/recovery/fault/closed e da owner estraneo |
| M1-D08 | Conferma solo dopo write+flush+pubblicazione indice/radice; errore senza conferma |
| M1-D09 | Short I/O/errori: primitive canoniche, stato faulted, nessun retry o rollback implicito |
| M1-D10 | Due SIGKILL e reopen da processi distinti; ogni strong confermato recuperabile |
| M1-D11 | Cleanup tenta tutte le capacita', preserva causa primaria e guasti secondari |
| M1-D12 | Interfaccia reale riusa il medesimo percorso, senza harness nel processo server |

Sorgenti committati/congelati, due letture e revisione indipendente prima
delle esecuzioni. Test deterministici, negativi e FI autorizzati dall'autore;
ogni comando passa dal recorder, fallimenti inclusi. Evidenze compatte
lossless nel repository, hash dei sorgenti e collector comune con worker
paralleli. Nessun benchmark in questa milestone e nessuna pretesa di qualifica
power loss, filesystem guasto permanentemente, Linux non eseguito o MC/DC
senza relative campagne. La milestone resta aperta finche' lo scenario reale
e i suoi criteri non sono dimostrati; i controlli statici non la chiudono.

## Integrazione preregistrata: capienza dell'indice

Dopo la verifica completa della variante `b5f09b96` viene chiuso un ulteriore
confine di M1-D08/D09: load, arena chiavi, credito slot e revisione vanno
verificati prima di CSN/append, con gli stessi controlli canonici dei mutatori.
Nessuna prenotazione concorrente: l'owner M1 resta unico fino all'applicazione.

Le due regressioni, v1/v2, saturano rispettivamente il carico 28/32 e un'arena
di 64 byte con quattro chiavi di 16 byte. La richiesta ulteriore deve produrre
RESOURCE-EXHAUSTED lasciando READY, CSN e tutti i byte invariati. Si verificano
update ammesso, DELETE, nuova apertura con gli stessi budget e arena non
recuperata implicitamente dalla tombstone. Un processo negativo isolato carica
il solo writer precedente, dal commit immutabile `b5f09b96`, e deve rilevare
esattamente FAULTED al posto di READY. Nessun risultato del processo mutato
qualifica il prodotto; sorgente sostituito e storage del negativo sono conservati.

La verifica integrale finale puo' eseguire in parallelo i controlli indipendenti:
test del prodotto; lint/trace e autocontrolli/esperimenti; conservazione storica.
Il controllo dei link segue la chiusura di tutti i produttori e la raccolta.
L'unione deve coprire esattamente i dodici target di `check-core`, senza benchmark;
ogni gruppo ha un record originale e un esito terminale, senza dedurre un passaggio
da un altro gruppo. Si conserva anche il `make check` seriale della variante
precedente, distinguendone commit e perimetro dal controllo finale parallelo.
