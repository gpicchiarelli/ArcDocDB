# Lettura C4 degli strumenti per la struttura CBOR

Lettura statica conclusa il 2026-10-09, prima delle campagne del prodotto. Il lettore è l'autore del nuovo kernel: questo referto riguarda gli strumenti C4 e non costituisce una lettura C1 indipendente del prodotto né un'approvazione umana. Non sono stati eseguiti prodotto, prove, compilazioni, copertura o collector durante questa lettura. Il benchmark e il mutatore restano nella lettura assegnata al responsabile dell'integrazione.

Sono stati letti `tools/foundation-coverage.lisp`, il metodo preregistrato e i due strumenti esterni `/tmp/collect-cbor-structure-evidence.lisp` e `/tmp/cbor-structure-collector-guard-test.lisp`. Non restano difetti concreti aperti nel perimetro esaminato; l'esito statico consente il congelamento degli strumenti, senza anticipare gli esiti delle campagne.

## Copertura e metodo

Il filtro `cbor-structure` ammette soltanto il suffisso esatto dei sei file `cbor-package`, `cbor-space`, `cbor-scan-input`, `cbor-scan-stack`, `cbor-scan-items` e `cbor-scan`. Il controllo statico del self-test comprende i sei casi ammessi e rifiuta il vecchio header, UTF-8, i test e suffissi aggiunti. La suite `codec` esegue UTF-8, header e struttura; lo scope dedicato esegue soltanto la suite struttura. Il driver salva lo stato SB-COVER completo prima del report HTML filtrato e conserva nel denominatore anche dichiarazioni e guardie dei file selezionati. Le prove del self-test e i numeratori effettivi attendono la campagna registrata; non si attesta MC/DC.

Il metodo corrisponde al contratto congelato: un item esatto, limiti separati di byte/nodi/profondità, nodi per tag e chunk ma non BREAK, profondità delle sole mappe e array, stack preallocato e UTF-8 per ciascun chunk testo. Preserva input non minimi, bit dei float, tag e chiavi duplicate senza attribuire validità semantica o canonicalità. La fixture mirata sull'ultimo slot, aggiunta dopo la lettura statica, è dichiarata separatamente e il corpus precedente conserva il freeze originale. La descrizione dei due worker è stata corretta prima delle campagne: gli intervalli di lavoro sovrapposti sono su tempo reale e non provano esecuzione simultanea su core distinti. Allocazioni, tempi, sink e stabilità della fonte restano risultati da acquisire. Il chiamante deve assegnare una directory nuova al driver di copertura; il driver non garantisce da solo l'esclusività della directory.

## Raccolta e provenienza

Il collector legge le evidenze come dati con `*read-eval* NIL` e guardia EOF. Conserva gli originali byte per byte, tutti gli stati dei wrapper e tutti i log delle mutazioni; i canali incorporati sono stringhe con provenienza esplicita, mentre canali NIL o assenti non diventano stringhe inventate. Lo scope della copertura è una lista quotata dei sei file e il prefisso dei test è `tests/codec/cbor-structure*.lisp`. Stato e tutti gli HTML, compreso l'indice, hanno copia originale e associazione dichiarata. I metadati usano `:formats NIL` e accettano gli alias `:schema` e `:schema-version`; gli artefatti principali sono dati schema 1 con basename, e i file raw sono associazioni separate.

La creazione rifiuta destinazioni esistenti. L'append legge una sola cattura dei byte del catalogo precedente, controlla la corrispondenza con i dati prima della scrittura, conserva lo storico originale e pubblica lo stage solo dopo rilettura. Queste verifiche statiche non sostituiscono l'audit bytewise del futuro dataset reale e del catalogo finale.

## Tentativi conservati

Il primo guard del collector è realmente fallito con **10/11**: la fixture attendeva ancora i due vecchi nomi di file. Sono conservati codice, report e log `-first`; non è un esito del prodotto. La sola aspettativa del guard è stata aggiornata ai sei nomi corretti. Il successivo tentativo verso lo stesso report è stato rifiutato senza sovrascrittura: la registrazione `cbor-structure-collector-rejected-attempt.lisp` è una trascrizione di un risultato strumento troncato, non un flusso originale completo. Il nuovo guard `-v2`, eseguito dal responsabile dell'integrazione, riporta **11/11 PASS**; questa lettura ha verificato i report come dati e l'identità degli stdout incorporati con i rispettivi log, senza rieseguire il guard.

Le impronte, i percorsi dei tentativi e i limiti sono registrati anche in `/tmp/cbor-structure-tools-audit.lisp`. Restano da acquisire le campagne del prodotto, il self-test della copertura e l'integrità del catalogo delle evidenze reali.
