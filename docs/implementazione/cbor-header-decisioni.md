# Decisioni degli header CBOR

Inventario statico di `src/codec/cbor-header.lisp`, letto dopo il congelamento
dei test indipendenti. Ogni controllo resta nel denominatore della copertura;
questa tabella non costituisce MC/DC né un'eccezione approvata.

| Decisione | Oracolo o invariante |
|---|---|
| `check-header-cbor-range`: AND tipo buffer/start/end e catena numerica | Array generico, adjustable, fill-pointer, displaced, multidimensionale; indici non interi, negativi, oltre fixnum, invertiti e oltre lunghezza, tutti rifiutati prima del lead. |
| `check-header-cbor-range`: start=end | Span vuoti validi a 0, 1 e 3 con offset end; buffer invalido vuoto conserva la priorità del range. |
| `leggi-argomento-header-cbor`: start<=end<=length | Guardia del contratto interno: il helper pubblico ha verificato lo span e il lead. Nessun input pubblico valido falsifica questa guardia. |
| `leggi-argomento-header-cbor`: width>end-start | Tutti i 152 prefissi troncati di lead+larghezze 1/2/4/8 per otto major; i byte mancanti sono fisicamente presenti ma fuori end. |
| `leggi-argomento-header-cbor`: i<high-bytes | Larghezze 1/2/4 high zero; larghezza 8 high e low asimmetrici, massimi e zero. Tutti i 65536 argomenti a due byte verificati. |
| `leggi-argomento-header-cbor`: AND start<next e next<=end | width positiva e fit precedente garantiscono progresso e somma index; nessuna simulazione di helper incoerente. |
| `leggi-indefinito-header-cbor`: AND start<end e end<=length | Guardia interna dopo lead presente, nessuna falsificazione pubblica. |
| `leggi-indefinito-header-cbor`: AI=31 | Helper invocato solo dal ramo pubblico AI31; guardia interna conservata. |
| `leggi-indefinito-header-cbor`: CASE major | 0/1/6 rifiutati; 2/3/4/5 indefiniti; 7 break. Otherwise impossibile per il tipo unsigned-byte3, resta nel report. |
| `leggi-header-cbor`: 28<=AI<=30 e AI=31 | Tutti i 256 lead su span completo e di un byte, rifiuti con motivo/offset e priorità esatti. |
| `leggi-header-cbor`: AI<24 e width=0 | Tutti i 192 immediati, poi quattro larghezze. Argomenti non minimi ammessi anche per lunghezze/tag senza payload. |
| `leggi-header-cbor`: AND major=7, AI=24, low<32 | Tutti i 256 secondi byte F8 (32 rifiutati, 224 accettati), stesso low negli altri major e float raw; F8 troncato precede simple. |
| `leggi-header-cbor`: AND cursor<next e next<=limit | Immediato e marker consumano uno; gli argomenti consumano tutta la larghezza guardata. Contratto interno sempre vero per input pubblico, salvo errore del helper. |

La composizione in corto circuito delle guardie di range e del rifiuto F8
ha test che isolano i confini esterni. Le postcondizioni tra helper e le
guardie difensive non sono rese false da input pubblici; una lettura e una
copertura di ramo non provano MC/DC completa.
