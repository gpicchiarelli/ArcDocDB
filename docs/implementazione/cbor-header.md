# Lettura degli header CBOR

`arcdocdb.cbor:leggi-header-cbor(buffer,start,end)` legge soltanto la testata
nello span `[start,end)` di un array semplice u8 immutabile. Restituisce sei
valori: major type, additional information (AI), high u32, low u32, offset
successivo, forma. Per AI 0..23, high vale zero e low contiene AI; AI 24..27
legge rispettivamente 1/2/4/8 byte unsigned big-endian. La lettura completa
consuma al massimo nove byte. Per otto byte, i primi quattro compongono high.

| Caso | Risultato o condizione |
|---|---|
| Array non semplice u8 o span invalido | `invalid-argument :cbor-range`, offset NIL |
| Span valido vuoto o header incompleto | `corruption-detected :cbor-truncated`, offset `end` |
| AI 28..30 | `corruption-detected :cbor-reserved`, offset `start` |
| AI31 per major 0/1/6 | `corruption-detected :cbor-indefinite`, offset `start` |
| AI31 per major 2..5 | Parole zero, `next=start+1`, forma `:indefinite` |
| AI31 per major 7 | Parole zero, `next=start+1`, forma `:break` |
| F8 seguito da un valore sotto 32 | `corruption-detected :cbor-simple`, offset `start+1` |
| Altre testate complete | Forma `:argument`, parole e AI conservati |

Range, disponibilità del lead e AI riservati precedono i byte dell'argomento.
Si verifica l'intera larghezza prima di leggerla: un suffisso fisico oltre
`end` non completa una testata troncata. Il controllo F8 segue la disponibilità
del suo secondo byte. Gli offset sono assoluti nel buffer.

Questa API conserva gli argomenti non minimi, tag e bit float, compresi NaN
ed infinity; non materializza un float o un intero u64. Non interpreta il
payload, valida il contesto del break o attraversa contenitori/testo. Il
profilo deterministico e i budget documentali (16 MiB e profondità 100)
rimangono compiti del parser previsto da ADR-0014/0048. Un ritorno riuscito
non attesta che l'intero item sia valido.

Il chiamante mantiene il buffer immutabile fino al ritorno. Cursori e parole
sono locali: worker diversi possono leggere header in parallelo prima della
coda del writer della Serie. Il modulo non crea thread, non attende e non
esegue I/O. Supporta REQ-AFF-004/008 e un passaggio iniziale di REQ-LIM-002,
senza promuovere il requisito del decoder completo.

Il [metodo](cbor-header-metodo.md) registra oracoli, mutazioni e misure prima
delle campagne. La [tabella delle decisioni](cbor-header-decisioni.md)
distingue i rifiuti di input dalle guardie interne.

## Verifica locale del 9 ottobre 2026

La prima build rigorosa, sulla base `92d8b0e`, passa con 237 test complessivi,
inclusi 17 nominali CBOR.
Il corpus verifica tutti i 256 lead completi e di un byte, i 256 secondi byte
F8, 65.536 argomenti a due byte e 152 troncature. Il fuzz `8949A11F`
confronta 4096 span: 3437 accettati e 659 rifiutati con motivi/offset esatti.
Gli expected sono stati congelati prima della lettura del prodotto.

Due thread leggono buffer privati: 2.097.152 header e 18.874.368 byte,
sink 2.401.919.800.705.024 e 2.231.683.637.051.392. Il primo run registra
34.732 tick di sovrapposizione dei soli intervalli di lavoro, a 1.000.000
tick/s. I buffer restano invariati e i worker terminano. Questa è una prova
di uso concorrente; non attesta throughput o scaling del futuro pool.

La copertura grezza dei due sorgenti è 222/265 espressioni e 32/40 esiti
di ramo. Package, dichiarazioni e guardie interne restano nel denominatore.
I 43 elementi e gli otto esiti non marcati impediscono di dichiarare copertura
integrale o MC/DC; nessuna eccezione è stata approvata.

La baseline invariata delle mutazioni completa tutti i test. Tutti i nove
mutanti compilano e vengono rilevati dopo lo smoke su riga esatta; ogni log
è conservato. Le nove fixture heap, ciascuna con cinque repliche di 4096
chiamate e warmup 128, registrano zero byte allocati nei 45 campioni.
Tutti i sei valori alimentano il sink verificato. Il sensore ha baseline
zero e controllo positivo di 16.777.472 byte; GC, fixture e report sono fuori
dalla misura. Le prove non danno una garanzia assoluta di assenza di allocazioni.

Il [catalogo completo](../../spikes/results/2026-10-09-cbor-header/catalogo.lisp)
conserva wrapper, stdout/stderr, stato e HTML di copertura, baseline e dieci
log delle mutazioni, due letture C1 e audit C4. Conserva anche il primo
tentativo del collector, invalido per un errore di compilazione in un ramo
non esercitato: il referto 10/10 non è accettato. Dopo correzione e aggiunta
della prova di raccolta della copertura, il self-test passa 11/11 senza avvisi.
Il parser completo e il collegamento al runtime restano sviluppi successivi.

## Integrazione del manifest di recovery

La base `fd96fb3` incorpora il manifest durante lo sviluppo di questo blocco.
L'allineamento mantiene identici i cinque blob CBOR del prodotto e dei test
riportati nella [seconda lettura](cbor-header-revisione.md). ASDF e l'indice
conservano entrambi i moduli. I risultati precedenti restano attribuiti alla
loro base originale; il catalogo raccoglie separatamente la verifica completa
dell'integrazione. Nessuna prova di heap o mutazione viene reinterpretata
come misura dell'intero recovery o del motore.
