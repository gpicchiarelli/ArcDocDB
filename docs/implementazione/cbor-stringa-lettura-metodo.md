# Lettura delle stringhe CBOR — contratto e metodo

Incremento C1 preregistrato il 2026-10-15 prima del nuovo prodotto.
REQ-CBR-009 deriva da ADR-0014 e ADR-0048. Il corpus e il driver
sono preparati da autori distinti e congelati prima del kernel.

## Contratto

```lisp
(leggi-stringa-cbor-minima buffer start end :max-bytes 16777216)
;; => esattamente MAJOR, PAYLOAD-START, NEXT
```

Legge soltanto la prima stringa MT2/3 a lunghezza definita con testata
minima. Restituisce tre fixnum: tipo e intervallo assoluto del payload
`[PAYLOAD-START,NEXT)`, senza allocare una stringa o copiare i byte.
Vale `START < PAYLOAD-START <= NEXT <= END`; il payload vuoto è ammesso.
MT2 accetta byte arbitrari; MT3 verifica UTF-8 con i motivi e gli offset
assoluti del validatore esistente, senza normalizzazione.

La coda `[NEXT,END)` non viene interpretata. MAX-BYTES limita però tutta
la finestra autorizzata END-START, coda e testata comprese, come nel
lettore del primo item. I limiti validi sono 0..16MiB. Per esempio,
`40 FF` con budget 1 è rifiutato prima della lettura della stringa vuota.
BUFFER è un simple array u8 stabile, condivisibile in sola lettura;
nessuno scratch, stato globale, attesa o I/O appartiene al prodotto.

Precedenze congelate:

1. Range: INVALID-ARGUMENT, `:cbor-range`, offset NIL.
2. Budget fuori tipo/intervallo: INVALID-ARGUMENT, `:cbor-byte-limit`, NIL.
3. Finestra oltre budget: RESOURCE-EXHAUSTED, `:cbor-byte-budget`, NIL.
4. Testata e minimalità: errori del lettore minimo esistente.
5. Major diverso da 2/3: CORRUPTION-DETECTED, `:cbor-string-type`, START.
6. HIGH non zero o payload non interamente presente: `:cbor-truncated`, END.
7. UTF-8 del solo payload MT3, dopo la verifica della lunghezza completa.

Una testata malformata/nonminima precede il major errato. Un payload
incompleto precede eventuali byte UTF-8 errati già disponibili. Nessun
risultato parziale, mutazione o accesso fuori finestra, neppure in errore.
I limiti sono controllati prima della somma; lavoro limitato alla testata
di nove byte e al payload UTF-8 entro 16MiB. Il tipo MT2 non scandisce
il payload. Si riusano controllo span, lettore minimo e validatore UTF-8.

## Verifica preregistrata

Corpus indipendente: vettori letterali e testate ricavate aritmeticamente,
mai dal writer del prodotto come oracolo primario. Include larghezze,
lunghezze 23/24,255/256,65535/65536, limiti byte, UTF-8 valido e invalido,
offset non zero, coda non valida, precedenze, arità e immutabilità fisica.
Due worker reali condividono buffer readonly in due ondate, con rendezvous
dopo la prima chiamata controllata, timeout e cleanup. Nessuna inferenza
di scaling dai tempi della fixture.

Correzione della fixture del 2026-10-16: il clock è richiesto monotono,
senza avanzamento strettamente positivo per ondata. START, FIRST ed END
possono coincidere nello stesso tick; durata e overlap devono essere
non negativi. Rendezvous dopo la prima lettura verificata, sink esatti,
conteggi, immutabilità, timeout e join restano i controlli della fixture.
Non si aggiungono attese artificiali o chiamate per far avanzare il clock.
Il [fallimento Linux originale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-archive-csn-plan/README.md)
e la sua causa sono conservati separatamente dai controlli del prodotto CSN.

Due letture C1 e inventario di tutte le decisioni precedono la prima
compilazione. Funzioni entro 60 righe e dieci percorsi, invarianti attivi,
FTYPE completo e safety 3. Nessuna esclusione dalla copertura grezza del
nuovo sorgente; SB-COVER non viene presentato come prova MC/DC.

Driver separato con fixture fredde, almeno 1024 casi deterministici e
benchmark con warmup, repliche, checksum fisico e tre risultati. Heap
zero è un criterio locale osservato, senza soglia di velocità. Mutazioni
a sostituzione singola: major permissivo, UTF-8 saltato, NEXT=END,
budget ignorato, offset iniziale saltato e arità aggiunta. Baseline e
mutanti in processi/cache privati; contano soltanto test nominali falliti
dopo compilazione riuscita, mai warning o errori dello strumento.

Comandi registrati con sorgenti/indice/HEAD stabili. Originali, errori,
correzioni degli strumenti e risultati restano conservati; raccolta con
manifest esplicito, quattro worker e controllo dell'inventario chiuso.
REQ-LIM-001/002, profilo documentale e qualifica C1/MC/DC restano aperti.
