# SPK-08: confronto CRC32C a blocchi di 16 e 32 byte

Preregistrazione del 2026-10-23, prima delle nuove misure. Segue
[ADR-0059](../../docs/adr/0059-crc32c-arm64-sbcl.md) e
[ADR-0060](../../docs/adr/0060-crc32c-caricamento-portabile.md).
L'implementazione corrente da 16 B resta il riferimento di prodotto.
Il software slicing-by-8 e un oracolo bitwise indipendente restano distinti.

## Varianti e criterio

Confrontare software, kernel di prodotto 16 B, variante 32 B con coda byte,
variante 32 B con coda CRC32CW a 4 B e CRC32CB a 1 B. Una sola catena CRC;
niente PMULL, pinning, GC disabilitato o riduzione di safety 3. Le varianti
usano i VOP del prodotto per CX/CB; soltanto CW è nuovo e resta nello spike.
I load SIMD conservano bounds check. Non si deduce un tetto dell'M4 né si
attribuisce tutto il residuo al ciclo da una sola misura di throughput.

Preferire il kernel più semplice già sotto 1 µs sul corpo da 4112 B.
Valutare la promozione del 32 B soltanto se riduce di almeno il 15% la
mediana CRC a 4112 B, senza regressioni oltre il 5% a 64/256 B nei due
offset misurati, e rimane breve e verificabile. Prima della promozione,
il GET completo deve mostrare un vantaggio ripetibile: almeno il 5% nella
mediana del percorso senza oracolo, senza regressioni d'integrità/heap.
Se non passa, conservare i risultati e mantenere il prodotto corrente.

## Correttezza e disponibilità

Ogni variante deve dare `E3069283` per ASCII `123456789`, indipendentemente
dal software. Confrontare anche bitwise/software per lunghezze 0..128,
255/256/257, 4095/4096/4097, 4111/4112/4113, 65535/65536/65537;
offset 0..31, semi 0/massimo/arbitrario, tutti gli split piccoli e frontiere
4/16/32 sui grandi. Verificare immutabilità, corruzione, esclusione dei byte
fuori range e rifiuto degli intervalli invalidi. Il checksum pubblico conserva
seed e finalizzazione. Disassemblato conservato, nessun warning ammesso.

Eseguire soltanto se il backend di prodotto è effettivamente ARM64 CRC32C
qualificato e selezionato a runtime; altrimenti esito `:unsupported` senza
caricare il nuovo VOP né istruzioni native. Cortex/emulatori non qualificati
restano sul software. Nessuna estensione del supporto del motore o dell'ISA.

## Finestre CRC

Dimensioni 16/64/256/4096/4112/65536 B; offset 0 e 24, quest'ultimo come
il corpo nella cornice del record. Cinque repliche, ordine dei quattro metodi
ruotato per replica e invertito alle repliche dispari: 240 finestre.
Chiamate per finestra: 1.048.576 fino a 256 B, 262.144 fino a 4112 B,
65.536 a 65536 B; 1024 warmup. Un thread, niente campagne concorrenti.
Timer wall e CPU, contatore heap globale, completamenti e sink controllati;
oracolo calcolato prima del timing. GC completo e persistenza fuori finestra.
Sensore positivo da 4 MiB e baseline vuota; nessuna sottrazione o scarto.
Timeout 60 s/finestra, 900 s/processo, rapporto salvato anche sul fallimento.
Conservare cinque campioni e mediane delle medie di finestra, non P99.

## GET completo

Rieseguire il driver [GET A/B](../../tools/get-throughput-bench.lisp) invariato:
16/256/4096 B, cache hit/segmento caldo/assente, CSN 7/massimo u64,
cinque repliche e percorsi `:exact`/`:throughput`, software/selezionato.
L'oracolo resta nel timing `:exact`; nel throughput controlla tutte le chiavi
prima e dopo le finestre. Se un candidato supera il filtro CRC, misurarlo
come selezionato con binding privato C4 in una campagna separata, senza
modificare il prodotto. Il confronto di kernel usa lo stesso driver.

Fonti primarie per CW: [Arm ISA, CRC32C](https://documentation-service.arm.com/static/67e40f3398aa3c3b6eea6a85)
(CW: sf=0, sz=10; opcode base `#x1ac05800`). Nessuna stima di latenza
o banda dell'M4 viene assunta come misura della CPU locale.

## Precisazione prima della seconda campagna

La prima campagna completa resta conservata. La lettura del codice prima
di derivarne le mediane rileva che le varianti C4 hanno il controllo del
range, ma omettono le due asserzioni esplicite del prodotto (precondizione
e coda). La seconda campagna aggiunge quelle asserzioni alle varianti:
stessi criteri, matrice, ordine e contatori. È questa la base del confronto
per un'eventuale promozione; il primo sorgente e tutti i suoi numeri restano
distinti. Nessun controllo viene rimosso per ottenere un risultato migliore.
