# Scrittura delle testate CBOR — seconda lettura C1

Lettura indipendente del responsabile dei test, il 2026-10-11, dopo il
congelamento del corpus cieco e prima delle campagne. Il prodotto esaminato
è `src/codec/cbor-write.lisp`, blob Git
`61f0d6e2783e4790ed7e19a45bba6407d6e5b3de`. Il contratto di riferimento è
quello preregistrato nel [metodo](cbor-scrittura-metodo.md); l'inventario
delle decisioni viene mantenuto separatamente dal coordinatore.

| Punto della checklist | Riscontro statico e limite |
|---|---|
| 1. Requisiti e ADR | REQ-CBR-001 da ADR-0014, AFF-004/008; la funzione realizza una testata locale MT0..6, senza interpretare payload, tag, mappe o il profilo documentale completo. REQ-LIM-002 è richiamato dal test che distingue l'argomento locale dal budget documento. |
| 2. Invarianti | Destinazione simple u8 posseduta in esclusiva; ai/size, spazio e progresso hanno guardie attive. Nessun u64 ricomposto nel prodotto. Ogni scrittura è entro il NEXT già calcolato e verificato, con un massimo di nove byte. |
| 3. Errori | Il preflight corto circuito controlla range → major → high → low; il controllo della capacità viene dopo la selezione e prima della prima mutazione. Gli errori pubblici sono tipizzati, con offset NIL per initform della condizione. Le guardie interne propagano invariant-violation senza rollback; la transizione fail-stop appartiene al proprietario. |
| 4. Limiti | La selezione ha cinque esiti 1/2/3/5/9; il solo ciclo scrive WIDTH 1/2/4, invocato al massimo due volte. Nessuna ricorsione, attesa, retry o lettura del payload. La sottrazione END−START valida precede ogni NEXT; capacità sufficiente implica NEXT≤END e impedisce overflow di index. |
| 5. Heap | Il percorso usa scalari, valori multipli e chiamate dirette; su SBCL 64 bit le parole u32 sono immediate. Non crea buffer, liste, closure o oggetti u64. Questa lettura non attesta zero allocazioni: misure locali, baseline nulla e sensore positivo restano necessari. |
| 6. Uscita | La funzione termina con NEXT come singolo valore. Per size1 il cursore iniziale è già NEXT; per 2/3/5 scrive solo LOW; per 9 scrive HIGH poi LOW, entrambi BE. La postcondizione cursor=NEXT precede il ritorno. I test confrontano arity esatta e l'intera destinazione. |
| 7. Decisioni | Tre decisioni logiche esterne (righe 35–36, 42, 53–54), espresse da quattro forme AND/OR contando l'OR annidato. Due relazioni concatenate autonome (righe 33 e 84) portano a cinque le decisioni composte esaminate; il `<=` della riga 54 è già interno all'AND del range. Le guardie interne e i rami negativi restano nel denominatore; nessuna attestazione MC/DC o esclusione. La selezione IF/COND mantiene la precedenza HIGH prima delle soglie LOW. |
| 8. Proprietà | Il buffer resta del chiamante e non viene trattenuto. OWNER/SHARED documentano l'esclusività fino al ritorno; nessuno stato globale mutabile, alias interno, callback o pubblicazione del buffer. Una destinazione condivisa da worker attivi violerebbe la precondizione. |
| 9. Integrazione | Export nella package CBOR e componenti ASDF esaminati: prodotto, supporto, seriali, thread e round-trip supplementare. Nessuna dipendenza da storage o I/O. La compilazione rigorosa e i controlli del coordinatore restano da registrare. |
| 10. Standard | safety3, FTYPE completi, docstring Pre/Post/errori e riferimenti REQ presenti. Le quattro funzioni hanno 14/16/14/28 righe inclusive; tutte entro 60 e con almeno due controlli attivi. Non sono proposte deroghe. |
| 11. Parallelismo | La funzione non crea thread, lock o attese, né scrive fra Serie. Il corpus prepara due destinazioni distinte prima dell'avvio dei worker, con barriera, timeout, join e cleanup limitati. La sovrapposizione degli intervalli reali prova soltanto concorrenza funzionale osservata, senza inferenze su core o scaling. |
| 12. Durabilità | La mutazione è locale a memoria esclusiva; nessuna scrittura durevole, eliminazione o pubblicazione. Non è una primitiva atomica e non promette rollback delle guardie interne. Nessun punto di commit del motore viene introdotto. |

## Provenienza e indipendenza del corpus

I tre file seguenti sono stati scritti dal contratto senza leggere
`cbor-write.lisp`, poi congelati e controllati con un lettore Common Lisp
isolato. Solo dopo il congelamento è iniziata la lettura del prodotto.
Nessuna build o campagna è stata eseguita dal responsabile di questa lettura.

| File cieco | Blob Git | SHA-256 |
|---|---|---|
| `tests/codec/cbor-write-support.lisp` | `92327e4b840b8586c50c32a7732e718ee6e9db98` | `e5290bd835e4b111b4d0fc0d307ca397e5220b96af4281f6153d468213421cc6` |
| `tests/codec/cbor-write.lisp` | `903a213c810d99fdefc2af2afa93445574a13be7` | `0a8ac6cb0a8b1db23c306349a658601745fb39a80b28293f55672071a12610e3` |
| `tests/codec/cbor-write-threads.lisp` | `878f0fa10825ae3d49e9cac2f94d9992c06f2d20` | `7ab3075c75d53ea5285bd68912513010ec767bcb9f99af725a7727239c472dcb` |

Il modello freddo calcola aritmeticamente HIGH×2^32+LOW e i byte con
divisione/modulo; i bignum sono confinati all'oracle. I vettori letterali
indipendenti controllano anche il modello, includendo gli estremi e le
parole asimmetriche `01234567/89abcdef`. Nessun expected proviene da un
encoder o decoder di prodotto.

I 15 test seriali coprono i sette major, tutti gli argomenti LOW0..65535
(458.752 confronti), le soglie e gli adiacenti, HIGH nonzero con LOW piccolo,
4.096 casi con seed `57524342`, ogni capacità insufficiente per le cinque
larghezze (140 casi), range e destinazioni invalidi, errori concorrenti,
span vuoti validi, sentinelle fisiche, disallineamento, riuso e concatenazione.
Gli helper controllano un solo NEXT fixnum sul successo e zero mutazioni
fisiche su ogni rifiuto, compresa la capacità esclusa da END.

Il sedicesimo test usa due worker reali, ciascuno con buffer proprio,
16.384 ripetizioni di sette header: 229.376 chiamate complessive. Piano,
byte finali e sink per iterazione sono calcolati prima dei worker; arity,
NEXT e cursore finale vengono verificati nei worker, sink e destinazioni
complete dopo il join. Le attese e la terminazione hanno timeout.

Il coordinatore ha aggiunto separatamente
`tests/codec/cbor-write-roundtrip.lisp`: il diciassettesimo test controlla
77 coppie con il lettore minimo, dopo il confronto con l'expected freddo.
È una prova supplementare di compatibilità, senza cambiare i tre blob ciechi.

Non risultano rilievi statici aperti sul prodotto o sul corpus. Build,
regressioni, risultati dei test, heap, copertura grezza e mutazioni devono
ancora confermare il comportamento. Questa lettura non chiude un gate
di fase, non attesta il motore completo e non costituisce approvazione umana.
