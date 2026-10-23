# Metodo di verifica della validazione UTF-8

Metodo registrato prima delle campagne. Il blocco controlla uno span di byte
senza decodificarlo in una stringa, con budget massimo di 16 MiB. Supporta i
limiti del futuro decoder CBOR; non implementa il parser, la profondità,
la normalizzazione o la validazione di uno schema.

## Contratto e oracoli

Buffer semplice specializzato a byte, span `[start,end)` e budget intero
non negativo entro 16 MiB. Il controllo dello span precede quello del budget;
il superamento del budget precede l'ispezione dei byte. Anche lo span vuoto
è valido. Il risultato è il numero di valori scalari Unicode, con NUL, BOM
e noncaratteri ammessi. Nessuna sostituzione o normalizzazione.

La grammatica è quella di [RFC 3629, §4](https://www.rfc-editor.org/rfc/rfc3629#section-4);
[RFC 8949, §3.1](https://www.rfc-editor.org/rfc/rfc8949#section-3.1) richiede UTF-8 valido
per il testo CBOR. Dopo il riconoscimento del byte iniziale, l'intera sequenza
deve stare nello span prima di leggere le continuazioni. Si controllano poi
le continuazioni da sinistra, infine overlong, surrogate e limite U+10FFFF.
Gli errori riportano motivo tipizzato e offset assoluto: byte iniziale,
fine dello span per troncatura, prima continuazione invalida, secondo byte
per un valore scalare escluso. Gli errori di argomento non hanno offset.

Test congelati prima di leggere il prodotto: tutti i 256 input di un byte e
i 65.536 input di due byte confrontati con il decoder strict SBCL, dopo un
self-check su fixture manuali. Il decoder è oracolo per accettazione e
conteggio; la priorità e gli offset degli errori hanno oracoli manuali.
Vettori indipendenti per confini a tre/quattro byte, tutte le troncature,
continuazioni invalide, span con sentinelle, budget e input invalidi.
Fuzz differenziale: 4096 input di 3..8 byte con seme `3629A11F`, piu una
sequenza di 521 scalari codificati dall'oracolo con seme `3629` e slice ai
confini dei caratteri. Nessun risultato atteso viene ricavato dal prodotto.

## Parallelismo e campagne

Il chiamante mantiene immutabile lo span fino al ritorno. La funzione non
scrive il buffer né altri oggetti e non usa stato mutabile globale. Due thread
eseguono validazioni su buffer distinti preallocati; si verificano conteggi,
contenuto e intervalli di calcolo sovrapposti fuori dalla barriera iniziale.
Due buffer da 655.360 byte, 64 chiamate ciascuno; semafori entro 15 secondi
e join entro 20, con cessazione dei worker verificata anche nel cleanup.
Questa prova non misura lo scaling del pool o del motore.

Build senza avvisi, lint, tracciabilità e due letture C1. Tabella delle
decisioni con condizioni composte esplicite. Copertura SBCL separata con
self-test, stato grezzo e denominatore intero; nessun dato viene escluso
per ottenere una percentuale artificiale. Mutanti mirati in copie nuove,
baseline obbligatoria, compilazione fallita sempre invalida e smoke su riga
esatta. Sono conservati anche i tentativi falliti.

Allocazioni su successi: buffer preallocati ASCII, a due/tre/quattro byte e
misti, cinque repliche per cella, warmup 128, GC fuori dalla misura. Ogni
cella usa uno span entro 16 MiB, con conteggio atteso indipendente e sink
osservabile. Il sensore ha baseline e controllo positivo 16 × 1 MiB.
Zero heap osservato è il criterio; nessuna soglia temporale. Le misure sono
seriali, separate dalla copertura e dalla campagna di mutazione.

Il kernel è trattato conservativamente come C1. Le letture automatizzate
non costituiscono approvazione umana; non chiudono MC/DC, requisiti completi
del decoder, controller FAULTED o gate di rilascio del motore.
