# Inventario directory: letture C1

Due letture statiche precedono le esecuzioni: root sul confine I/O e sul
collegamento al planner; revisore distinto sul confine I/O, autore I/O
sul collegamento al planner. Il metodo e i casi sono in
[inventario-directory-metodo.md](inventario-directory-metodo.md).

Le fonti finali della lettura sono `native-directory.lisp` SHA-256
`781b3fcf6d422efa811e0c136c11735aa9f9123d1a42f45fc2d4c8d4e82ac08b`
e `inventory-directory.lisp`
`c3d45d7c41661865b9739fda5bf9762fc1e238ab213638285579cfe4d2c86fb4`.
Gli altri file sono identificati dai blob del commit delle esecuzioni.

| Controllo | Esito statico |
|---|---|
| Requisiti e ADR | REQ-REC-001/002, REQ-AFF-001/004/008/018; ADR-0040 §3, IO iniettabile ADR-0035 |
| Invarianti | INV-A7/A9/A10: raccolta readonly; nessun effetto del planner; INV-P6: workspace/cursore per Serie |
| Errori | EOF distinto da errore e da budget; condizioni tipizzate; doppio errore con motivo ed errno di cleanup |
| Cicli e attese | Parser 16 passi, raccolte per cardinalità, nativo al massimo N+3 read; syscall nel pool I/O |
| Heap | Percorso di apertura con allocazioni ammesse e payload limitato; nessuna attestazione RSS o hot path |
| Confini | Callback e nomi rivalidati, capacità aperte prima/dopo, nessun elenco parziale pubblicato |
| Decisioni | IND-D01…D10 nel metodo; qualificazione dinamica e copertura distinta dalla lettura |
| Ownership | Parent preso in prestito; openat indipendente; FD trasferito a DIR solo al successo; un cleanup |
| ABI | Linux/macOS 64 bit; layout dirent grovelled SB-POSIX, selettore inode64 coerente |
| Regole | ftype, safety3, funzioni sotto 60 righe; rami normali espliciti e condizioni originali propagate |
| Parallelismo | Nessun lock o scrittura condivisa fra Serie; binding Latin1 locale al thread |
| Durability | Nessun nuovo punto atomico: nomi, file e frontiere non vengono modificati |

La rilettura ha reso espliciti i rami normali dei `cond` e ristretto i
motivi del risultato nativo. Il binding della codifica è una variabile
speciale SB-EXT ereditata da SB-ALIEN: verificato nel runtime e nelle
fonti installate, senza introdurre un convertitore alternativo.
La prima compilazione ha inoltre rilevato un tipo troppo stretto per il
suffisso letterale: il suo argomento usa ora `simple-string`. Il secondo
tentativo ha raggiunto il caso Latin1 e rilevato che `base-char` non copre
il byte 255: le copie dei nomi usano ora array semplici di `character`,
e il parser accetta `simple-string`. La validazione resta limitata ai
codici 1…255. Entrambe le correzioni sono state rilette separatamente;
i tentativi falliti sono conservati.

## Limiti

Il controller deve impedire mutazioni del namespace e chiusure concorrenti;
le callback sono fidate. L'enumerazione non è uno snapshot atomico.
Le syscall possono bloccare e non hanno una deadline wall implicita.
Le finestre senza interrupt proteggono ownership e cleanup; la cancellazione
asincrona del compito non è un protocollo supportato. Su uscita non locale
estranea al contratto il cleanup viene tentato una volta, preservando la
causa primaria senza allegare l'eventuale errno secondario.

Il runtime crea il nome corrente prima del controllo dei budget di
accumulo. Questi budget non includono tutti gli oggetti Lisp o il costo
del runtime. Le prove pure della matrice dei motivi non simulano un guasto
reale di `closedir`. Restano aperte qualifica C1 completa, MC/DC, mutation
testing dei nuovi percorsi e misure. Nessun lettore verifica qui header,
CRC, contenuti dei segmenti o ammissione al traffico.
