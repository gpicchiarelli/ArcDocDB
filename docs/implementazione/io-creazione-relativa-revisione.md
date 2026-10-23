# Creazione relativa: letture C1

Root e revisore distinto hanno letto i sei sorgenti finali, il collegamento
ASDF e la fixture verticale prima della compilazione. L'autore dei test e
root hanno letto i tre file di prove; il revisore distinto ha controllato
anche gli oracoli. Il [metodo preregistrato](io-creazione-relativa-metodo.md)
elenca CTR-D01…D17. Le letture statiche non attestano un esito dinamico.

| Punto della checklist C1 | Lettura statica |
|---|---|
| 1. Requisiti e ADR | REQ-STO-003, REQ-REC-001, REQ-AFF-001/004/008/018, REQ-FOR-001; ADR-0017/0033/0035/0040 coerenti |
| 2. Invarianti | INV-A7/A9/A10/A11, INV-P6/X3; nuovo file esclusivo, nessuna modifica ai file esistenti, nessuna eliminazione |
| 3. Errori | Rifiuti prima degli effetti; FD invalido/alias; tuple e file non vuoto; causa EQ o doppio guasto con provenienza |
| 4. Cicli e attese | Nessun ciclo nuovo di prodotto, foglia limitata a 255 byte; syscall nel pool I/O, nessuna deadline wall |
| 5. Heap | Apertura con allocazioni ammesse, copia e capacità prima della syscall; nessuna misura del percorso caldo dichiarata |
| 6. Confini | FD zero valido; metadata completi prima del restringimento, regolare vuoto e stessa identità nofollow prima del ritorno |
| 7. Decisioni | CTR-D01…D17; guardie sul child privato lette staticamente, senza dichiarare MC/DC |
| 8. Ownership | Parent borrowed, child posseduto dall'handoff; una close del child non pubblicato anche con parent invalidato |
| 9. Tracciabilità e check | Riferimenti presenti, `trace-write` e `make check` previsti sul freeze; esiti da conservare separatamente |
| 10. Regole | ftype, safety 3, docstring, funzioni brevi, nessun handler generico di prodotto o dipendenza nuova |
| 11. Parallelismo | Nessun lock, attesa o scrittura condivisa tra Serie; namespace e capacità sotto proprietario unico |
| 12. Durability | Preparazione prima dell'EDIT, nessun flush/rename/unlink implicito; orphan possibile dopo il fallimento |

Fonti finali in `src/io/`, SHA-256:

| File | SHA-256 |
|---|---|
| `create-relative.lisp` | `444a479156881ad66fd2a63460f42116f25f9f5a749442ce911d6bca2540c86f` |
| `native-create-relative.lisp` | `56b824eb7c4ad9ee1a3e3b8bf3690e117d28d1fa4cb2e8e3a282ba252f14b121` |
| `types.lisp` | `aab5bc1d17bbb848785222385686bc21443fc824cfae1569355e67fba646d70d` |
| `package.lisp` | `3654b5eb7f060615debfc9b36aa5bc43d8be3e049cfafec879efca41c21faab5` |
| `native-open-relative.lisp` | `5d3b7f128061a7b5fbae7ff611c1fe4b1e6e7e83e4909789dc1cbb5efeae0242` |
| `open-relative.lisp` | `78faa5443804b61daca3bb58433064ce680a4ef50066541869c3affe2f01922c` |

Il riuso di due helper privati aggiunge argomenti opzionali espliciti per
modo, ragione del mismatch e operazione del doppio guasto. I default
readonly restano `:input`, `:io-open-relative-identity`, `:open-relative`;
il percorso preesistente e i suoi test restano parte del controllo completo.
`native-file-metadata` mantiene il comportamento e documenta anche il FD append.

L'ABI è stata letta nel SDK locale (`sys/fcntl.h`, dichiarazione variadica
di `openat`; `sys/_types.h`, `mode_t` Darwin a 16 bit) e nei sorgenti
SBCL 2.6.9: `target-alieneval.lisp` interpreta `&optional`, `alieneval.lisp`
ne conserva l'indice e `compiler/arm64/c-call.lisp` passa su stack i vararg
Darwin. Anche `unix.lisp` e il contrib `sb-posix` usano il modo promosso
variadico per `open`. Il nuovo binding passa sempre 0600 come `int`.

La fixture nativa esige 0600: la propria mkdir 0700 già attestata dimostra
che la umask mantiene i bit owner, e nessun test la modifica. La prova
rileva così anche un modo errato 000/0400 con un runner privilegiato.
Non modifica la umask globale. Scrive dopo un riposizionamento del
cursore per attestare append, verifica collisioni intatte e parent spostato.
Il caso orphan combina creazione/close reali e guasto iniettato del callback
di validazione: non viene presentato come guasto nativo di `fstat`.

Restano le precondizioni di namespace esclusivo, callback fidate e assenza
di cancellazione asincrona. Nessun rilievo di flusso resta aperto nella
lettura; qualifica completa C1, MC/DC, mutazioni mirate e prestazioni restano
distinte dalle verifiche locali e dalla CI.

## Raccordo del 2026-10-22

La tabella SHA sopra identifica i sorgenti del freeze S1 `b5ad739b`.
L'integrazione con main `56fc1c1a` conserva i cinque file di implementazione
e i tre test senza variazioni; package e ASD aggiungono anche l'export
e i moduli della stabilizzazione dei nomi. L'ordine resta: native create
dopo native open, wrapper create dopo wrapper open, stabilizzazione dopo
transfer/flush. Root e revisore distinto hanno riletto il raccordo prima
del controllo d'integrazione, senza rilievi aperti.

Il secondo raccordo del 2026-10-22 integra main `e75f9794`: il selettore
aggiunto opera soltanto su buffer privati, senza dipendere dall'API I/O.
Root e revisore distinto hanno riletto i raccordi ASD e documentali
prima di R4, senza rilievi; i sei sorgenti I/O e i test non cambiano rispetto a `28b7fae0`.

Il raccordo C4 con main `c46bc4c1` conserva vocabolario, producer e
boundary test upstream. La differenza C4 rispetto a main è la regressione
con i sei moduli del consumer coverage reale in un processo fresco:
il producer resta assente nel figlio, e identità errata o test saltati
non costituiscono una prova normale valida. Root e revisore distinto
hanno riletto correzione minima e raccordo; parser, limiti e schemi
non sono ampliati dall'input. I sorgenti I/O restano identici a R4.
