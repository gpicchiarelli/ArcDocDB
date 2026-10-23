# Rinomina atomica nella directory posseduta

`io:rinomina-nella-directory(directory, source, destination)` realizza il
confine POSIX necessario ad [ADR-0040](../adr/0040-manifest-a-record-unico.md).
La capacità parent è già aperta; entrambi i nomi sono relativi allo stesso FD,
senza rileggere il percorso del parent o cambiare la directory corrente.

## Contratto

Il compito del pool I/O possiede la directory e il controller riserva i due
nomi. Il caller garantisce la decisione autorevole, l'identità e il contenuto
dei file e impedisce mutazioni/close concorrenti. I nomi Lisp sono presi in
prestito e stabili fino al ritorno. Dopo la validazione, il modulo ne crea
due copie simple-base-string private prima dell'effetto: anche stringhe
displaced, adjustable o con fill pointer rispettano il contratto della FFI.
Nessun lock o contatore tra Serie.

> **Proposta** — Questa API accetta i componenti ASCII dei nomi storage
> canonici, da 1 a 255 byte: nessun NUL, slash, `.` o `..`; source e destination
> sono diversi per contenuto. Non è un'interfaccia per percorsi arbitrari o
> nomi Unicode. Il filesystem può imporre ulteriori restrizioni, segnalate da I/O.

Una `renameat(parent, source, parent, destination)` riuscita è il punto
atomico del cambiamento dei nomi. Il valore NIL restituito certifica solo
l'esito POSIX zero e la capacità ancora aperta; il fsync del parent resta una
chiamata separata a `durable-flush(directory)`. Le frontiere byte non avanzano.
Per il recovery della Serie la rinomina del control log sarà il punto di
atomicità previsto da ADR-0040; l'esecutore deve ancora collegare decisione,
checkpoint verificato, namespace e completamento durevole.

La primitiva non verifica l'inode associato ai nomi, il tipo/contenuto del
file o l'assenza di hardlink. La semantica è quella POSIX: due nomi che già
individuano lo stesso inode possono dare successo senza spostamento. I FD
già aperti conservano la propria identità anche quando viene sostituito un
nome. Non si deduce una decisione EDIT dal nome `.tmp`, né si offre unlink.

La sostituzione verificata `sostituisci-temporaneo` mantiene i propri controlli
di identità, `.tmp`/definitivo e assenza di alias. Normalizza le due foglie
private e delega allo stesso effetto protetto, includendo la verifica del
nome installato nella postcondizione. La rinomina ordinaria mantiene
il wrapper nativo `native-replace`. La [pubblicazione esclusiva](io-pubblicazione.md)
seleziona invece la primitiva nativa che rifiuta target esistenti,
riusando lo stesso helper di effetto, postcondizione e fail-stop.
Il default ordinario resta invariato.

## Guasti e backend

Preflight di capacità, nomi e callback prima della prima operazione. Rifiuti
ordinari non mutano stato o namespace. Il backend aggiunge `:rename`, una
funzione immutabile che riceve fd/source/destination e restituisce zero;
callback assente significa `unsupported-format`, mai fallback nativo.
Il backend e i callback sono fidati e non modificano capacità o nomi in uso.

Syscall fallita (compreso EINTR) o risultato diverso da zero portano la
directory in FAULTED prima di `io-fault`. L'effetto incompleto, inclusa uscita
non locale, guasta una capacità ancora aperta senza sostituire la causa
originale. Le brevi transizioni di stato sono protette dalle interruzioni:
nessuna syscall o attesa è dentro la sezione protetta. Il cleanup e gli errori
POSIX/ritorno conservano una capacità già chiusa. Nessun retry,
rollback, close, unlink o flush implicito. Il caller propaga il guasto a
Serie/Archivio e riconcilia dal manifest prima di riaprire una capacità.

| Rifiuto/guasto | Reason |
|---|---|
| Nome fuori contratto | `:io-rename-name` |
| Nomi uguali | `:io-rename-same-name` |
| Backend senza callback | `:io-rename-unavailable` |
| Modo/capacità non valida | `:io-mode` / `:io-unavailable` / `:io-descriptor` |
| Ritorno callback diverso da zero | `:io-rename-result` |
| Errore POSIX | `:io-syscall`, operation `:rename`, errno conservato |

## Decisioni e prove previste

| ID | Decisione | Casi |
|---|---|---|
| RIO-D01 | Lunghezza fra 1 e 255 | Vuoto, 1, 255, 256, ogni nome separato |
| RIO-D02 | Nome diverso da dot/dotdot | Ciascun rifiuto e componente ordinario |
| RIO-D03 | ASCII non NUL e non slash | NUL, non ASCII e slash isolati; byte ammessi ai limiti |
| RIO-D04 | Source diverso da destination | Stringhe distinte uguali, nomi diversi |
| RIO-D05 | Backend presente e callback assente | Backend mancante, callback mancante, callback presente |
| RIO-D06 | Risultato zero | Zero, NIL, -1, +1, errore POSIX |
| RIO-D07 | Effetto incompleto e capacità ancora aperta | Successo, errore tipizzato, uscita non locale, capacità già guasta/chiusa |
| RIO-D08 | FD valido dopo il callback | Valido; invalidazione iniettata fuori contratto per il cleanup |
| RIO-D09 | Postcondizione facoltativa presente e ritorno NIL | Assente, presente con successo, errore e ritorno impossibile iniettati |

Ciclo massimo di 255 caratteri per ciascun nome; una sola rinomina per
chiamata e nessuna attesa aggiunta. È un percorso dei metadati, può allocare
per la conversione delle stringhe nella FFI. Qualifica C1, test, mutazioni e
benchmark locale sono registrati separatamente; questa primitiva non
qualifica l'apertura/recovery completo del database o la resistenza a power loss.
