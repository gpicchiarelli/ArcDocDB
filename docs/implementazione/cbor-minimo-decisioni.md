# Decisioni delle testate CBOR minime

Inventario dell'autore, sul metodo fissato prima delle campagne. Dieci nuove
decisioni composte sono riportate sotto; il lettore sintattico invariato
conserva l'inventario proprio. I test nuovi non sono stati letti dall'autore
prima della consegna del prodotto. Le fixture indicate sono quelle del
[metodo](cbor-minimo-metodo.md), non esiti osservati. Nessuna guardia o forma
dichiarativa è esclusa dal denominatore; nessuna qualifica MC/DC.

| ID | File, funzione e riga | Condizioni | Verifica prevista / limite |
|---|---|---|---|
| D01 | `cbor-float-minimal.lisp`, `binary32-accorciabile-cbor-p`, 15 | exponent <= 255; fraction <= 0x7fffff | Campi estratti da word u32; esito errato è difesa interna, mantenuta nella copertura grezza. |
| D02 | stessa funzione, 25 | shorter; fraction con almeno un bit basso dei 13 impostato | Postcondizione di allineamento: ogni valore accorciabile ha i 13 bit bassi zero. Normali/subnormali e NaN adiacenti; violazione interna. |
| D03 | `binary64-allineato-cbor-p`, 43 | low zero; bit bassi high sotto shift-32 zero | Subnormali con shift 33..52: entrambe le parole possono rendere il significando non allineato. Confini shift 32/33 e 52. |
| D04 | stessa funzione, 45 | aligned; low con almeno uno dei 29 bit bassi impostato | Postcondizione dell'allineamento 30..52; esito errato è difesa interna. |
| D05 | `binary64-accorciabile-cbor-p`, 57 | exponent <= 2047; fraction-high <= 0xfffff | Campi estratti dalla parola alta u32; esito errato è difesa interna. |
| D06 | stessa funzione, 60 | fraction-high zero; low zero, quando exponent zero | Zero con entrambi i segni e subnormali binary64 nonzero: nessun subnormale binary64 entra in binary32. |
| D07 | stessa funzione, 67 | shorter; low con almeno uno dei 29 bit bassi impostato | Postcondizione per ogni binary64 accorciabile; guardia interna, corpus di normali/subnormali/NaN e adiacenti. |
| D08 | `cbor-minimal.lisp`, `argomento-minimo-cbor-p`, 16 | AI 27; oppure HIGH zero | Prima parola ammessa nonzero soltanto con larghezza otto byte; difesa del contratto header, distinta dalla minima larghezza. |
| D09 | `float-accorciabile-header-cbor-p`, 35 | AI 27; oppure HIGH zero | Bit float in una parola fino a binary32, due per binary64; difesa del contratto header. |
| D10 | `leggi-header-cbor-minimo`, 56 | START < NEXT; NEXT <= END | Progresso dopo header completo, prima del filtro; rifiuti sintattici propagati prima. Esito errato è difesa interna. |

## Selezioni e soglie

| Campo | Decisione locale |
|---|---|
| Header sintattico | `leggi-header-cbor` viene chiamato per primo: range, reserved, truncated, illegal indefinite e simple F8<32 precedono qualunque `:cbor-nonminimal`. Nessun corpo o payload letto. |
| Form | `:indefinite` e `:break` sintatticamente ammessi vengono rifiutati al lead. È il confine locale scelto dal contratto; non una verifica dell'intero profilo documentale. |
| Major 0..6 | AI0..23 minimo; AI24 low >=24; AI25 low >=256; AI26 low >=65536; AI27 high nonzero. Mai ricostruito l'argomento u64. |
| Major 7 | Simple e binary16 accettati; binary32/64 rifiutati soltanto se accorciabili. Interi e float restano distinti. |
| binary32 exponent 0 | Fraction zero rappresenta ±0 accorciabile; ogni altra fraction è troppo piccola per binary16. |
| binary32 exponent 113..142 | Gamma normale di binary16: fraction deve avere 13 bit bassi zero. |
| binary32 exponent 103..112 | Gamma subnormale di binary16: significando24 con bit implicito, allineamento `126-exponent`, cioè 14..23. |
| binary32 exponent 255 | ±infinito e NaN accorciabili quando 13 bit bassi di fraction sono zero; segno e payload alto si conservano. |
| binary32 altri exponent | Non accorciabile: fuori dall'intervallo di valori di binary16. Il `t nil` è l'esito previsto, non uno stato inatteso. |
| binary64 exponent 0 | Fraction-high e low zero rappresentano ±0; qualsiasi altro valore è troppo piccolo per binary32. |
| binary64 exponent 897..1150 | Gamma normale di binary32: 29 bit bassi low zero. |
| binary64 exponent 874..896 | Gamma subnormale di binary32: significando53 HIGH21/LOW32 e shift `926-exponent`, cioè 30..52. Nessuna unione u64. |
| Shift <=32 | Maschera dei soli bit bassi LOW; shift32 verifica tutta la parola bassa. |
| Shift >32 | LOW zero e maschera su HIGH dei soli `shift-32` bit bassi. |
| binary64 exponent 2047 | ±infinito e NaN: padding di 29 bit bassi zero; si preservano segno, payload e posizione quiet/signaling. |
| binary64 altri exponent | Non accorciabile; `t nil` previsto. |

Le formule derivano dalla posizione dell'unità subnormale destinazione:
binary16 usa 2^-24, quindi il significando binary32 deve essere divisibile
per 2^(126-exponent); binary32 usa 2^-149, quindi il significando binary64
deve essere divisibile per 2^(926-exponent). Per NaN si confrontano soltanto
i bit mediante zero-padding a destra, senza conversioni floating point.
Il controllo non impone un solo NaN, ordinamento o unicità delle chiavi,
semantica dei tag o un tipo radice documentale.

## Lettura statica dell'autore

La consegna comprende cinque helper e il lettore pubblico. Tutti hanno FTYPE,
docstring con pre/post/condizioni, safety3 e almeno due guardie di invariante
significative per i propri campi, allineamenti, larghezze o progresso. Nessuna
funzione supera 60 righe; la separazione del dispatch float mantiene contenuto
il numero di percorsi del lettore pubblico. Non sono presenti cicli,
ricorsione, costruttori, handler, stato globale mutabile, copie, I/O o attese.
Le parole rimangono u32; la maschera più ampia prodotta da uno shift è 2^32-1,
immediata sul target SBCL a 64 bit del metodo. Ciò non sostituisce la misura
heap sul target effettivamente usato.

| Punto C1 | Riscontro dell'autore e prova ancora richiesta |
|---|---|
| 1 | LIM-002, AFF-004/008 e contratto locale ADR-0014/0048; non attestato il profilo completo. |
| 2 | Invarianti di campi, parole, allineamento e avanzamento elencati; oracoli indipendenti e campagne pendenti. |
| 3 | Sintassi propagata prima; `corruption-detected :cbor-nonminimal` al lead; difese `invariant-violation`. Nessun owner Serie/FAULTED in questo kernel. |
| 4 | Lavoro costante dopo lettura di massimo nove byte; nessuna attesa o ricorsione. |
| 5 | Nessun costruttore sul successo, solo maschere/parole; heap **pendente**, non attestato dalla lettura. |
| 6 | Esattamente sei valori dopo header completo e filtro; nessun corpo decodificato esce. |
| 7 | Dieci decisioni composte inventariate; denominatore integrale, copertura e MC/DC non attestati. |
| 8 | Input immutabile del chiamante e sole variabili locali; nessuno scratch o stato condiviso scritto. |
| 9 | Export aggiunto; integrazione ASDF, trace e `make check` del coordinatore pendenti. |
| 10 | FTYPE/safety/docstring/guardie presenti; build/lint e letture indipendenti pendenti. Nessuna deroga approvata. |
| 11 | Nessun lock, attesa o scrittura per operazione tra Serie; prova concorrente indipendente pendente. |
| 12 | Nessun cambiamento durevole, delete o pubblicazione: non applicabile. |

Questa è la lettura dell'autore, non una lettura C1 indipendente o
un'approvazione umana. Nessuna prova, compilazione, benchmark o nuova suite
di oracoli è stata eseguita o letta dall'autore prima di questa consegna.
