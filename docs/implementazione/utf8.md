# Validazione UTF-8 limitata

`arcdocdb.utf8:verifica-utf8` verifica integralmente uno span `[start,end)` di
un `arcdocdb.binary:octets` immutabile e restituisce il numero di valori
scalari Unicode. Il buffer deve essere un array semplice a byte. Il parametro
`:max-bytes` vale 16 MiB per default e accetta interi da 0 a 16 MiB.
Lo span vuoto restituisce zero, anche con budget zero.

| Rifiuto | Condizione, motivo e offset |
|---|---|
| Buffer o span invalido | `invalid-argument`, `:utf8-range`, nessun offset. |
| Budget invalido | `invalid-argument`, `:utf8-budget`, nessun offset. |
| Span oltre budget | `resource-exhausted`, `:utf8-byte-budget`, nessun offset; precede ogni lettura. |
| Byte iniziale invalido | `corruption-detected`, `:utf8-leading`, offset del byte iniziale. |
| Sequenza fuori dallo span | `corruption-detected`, `:utf8-truncated`, offset `end`. |
| Continuazione fuori da 80..BF | `corruption-detected`, `:utf8-continuation`, offset del primo byte errato. |
| Overlong, surrogate o valore oltre U+10FFFF | `corruption-detected`, `:utf8-scalar`, offset del secondo byte. |
| Incoerenza tra helper | `invariant-violation`; il futuro confine del worker applica il fail-stop. |

Gli offset sono assoluti nel buffer. Prima si controlla il range, poi il
budget; riconosciuto il lead, si controlla la disponibilità dell'intera
sequenza, poi tutte le continuazioni, infine le restrizioni scalari. Byte
validi fuori dallo span non completano una sequenza troncata.

NUL, BOM e noncaratteri sono ammessi. Il conteggio riguarda valori scalari,
non grafemi: una lettera seguita da un accento combinante conta due. Il modulo
non produce stringhe, non normalizza e non sostituisce sequenze invalide.
Controlla la grammatica di [RFC 3629](https://www.rfc-editor.org/rfc/rfc3629)
usata per il testo [CBOR](https://www.rfc-editor.org/rfc/rfc8949#section-3.1).
Non interpreta struttura, chunk o profondità CBOR.

Il chiamante mantiene il buffer immutabile fino al ritorno. Ogni chiamata
usa solo cursore e conteggio locali; non scrive stato condiviso, non crea
thread e non attende. Worker diversi possono validare documenti in parallelo
prima di inviarli alla coda del writer della Serie. Il collegamento al parser
e al runtime sarà un componente successivo.

Il [metodo registrato](utf8-metodo.md) e la
[tabella delle decisioni](utf8-decisioni.md) distinguono gli input malformati
dalle guardie interne. Questo kernel supporta REQ-LIM-001/002 e REQ-AFF-004/008;
nessun requisito del decoder completo o del motore viene promosso.

## Verifica locale del 9 ottobre 2026

Diciassette test UTF-8 passano nella build rigorosa: tutti i 256 byte singoli
e le 65.536 coppie (18.304 valide, 47.232 rifiutate), confini e priorità degli
errori, massimo di 16 MiB e immutabilità degli input. Il fuzz con seme
`3629A11F` confronta 4096 span di 3..8 byte: 234 validi e 3862 rifiutati.
Un oracolo separato codifica 521 scalari e verifica le slice ai loro confini.

Due worker validano buffer distinti da 655.360 byte, 64 volte ciascuno:
83.886.080 byte complessivi, sink atteso 16.777.216 per worker e contenuto
invariato. Il primo run osserva 265.891 tick di sovrapposizione, con timer
da 1.000.000 tick/s, fuori dai semafori. Sono intervalli di lavoro su thread
reali; non attestano scalabilità del pool o throughput del database.

La copertura SBCL conserva il denominatore completo: 231/301 espressioni
e 49/60 esiti di ramo. Le forme non marcate sono una del package, otto
dichiarative, un default e sessanta nei dieci errori difensivi. Gli undici
esiti non marcati appartengono alle guardie interne. Il default pubblico
è esercitato dai test ma resta non marcato nello strumento. Nessun esito
operativo o di input risulta scoperto in questa strumentazione; MC/DC e
falsificazione completa delle guardie difensive restano aperte.

La baseline di mutazione completa passa; tutti i nove mutanti compilano e
sono rilevati dopo lo smoke. Le cinque fixture delle allocazioni hanno
cinque repliche di 64 chiamate ciascuna, warmup 128 e conteggi/sink esatti:
zero byte di heap osservati in tutti i 25 campioni. Il sensore registra
baseline zero e controllo positivo di 16.777.472 byte. Nessuna soglia
temporale o prova assoluta di assenza di allocazioni è dedotta da questi dati.

Il [catalogo](../../spikes/results/2026-10-09-utf8/catalogo.lisp) conserva
sorgenti prima/dopo, output integrali, stato/HTML di copertura, baseline e log
dei mutanti, letture C1 e controlli degli strumenti. Conserva anche il primo
self-test del benchmark fallito per un refuso nella stringa FORMAT degli
hash e la prova riuscita dopo la correzione. Le letture automatizzate
non sostituiscono l'approvazione umana o i gate di rilascio del motore.
