# Scrittura dei float CBOR — prima lettura C1

Lettura statica del 2026-10-13, prima della compilazione dei nuovi sorgenti
e delle campagne. Il corpus è stato congelato prima della loro scrittura.
Riferimenti: [metodo preregistrato](cbor-float-scrittura-metodo.md),
[contratto](cbor-float-scrittura.md),
[standard di codifica](../affidabilita/standard-di-codifica.md),
ADR-0014/0024/0033/0035/0048. Questa lettura non è una prova runtime,
di allocazione, copertura o MC/DC.

## Sorgenti letti e rilievo risolto

| Sorgente | Git blob letto |
|---|---|
| `src/codec/cbor-float-narrow.lisp` | `cd5749edc0a757ee3a5b470eda566a6685d32fd8` |
| `src/codec/cbor-float-write.lisp` | `03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c` |
| Metodo | `755b13a91ab72f54383d96faee5780da36e750d6` |

Letti anche gli helper esistenti `cbor-float-minimal.lisp` e
`scrivi-parola-header-cbor`, export, ordine ASDF, ambito del driver di
coverage, requisito e matrice, oltre al corpus freddo e ai worker.

La prima versione di `riduci-significando64-cbor`, blob
`31a61d565e17607fd9498b0a423923a28b6e0159`, aveva una post-guardia
`RESULT <= #x7fffff` dopo la dichiarazione `RESULT u23`: non controllava
una proprietà distinta dal tipo. Il rilievo COD-24 è stato corretto prima
di compilare o misurare. Le righe 49–54 della versione letta verificano
la ricostruzione separata delle due parole di ingresso, senza unirle in
u64. L'originale e la revisione restano conservati nelle prove preparatorie.

## Dimensioni e percorsi

Conteggio dalla `defun` alla sua chiusura, incluse docstring e dichiarazioni.
Percorsi conservativi: base uno, un incremento per scelta, guardia e
ramo corto addizionale di AND/OR; `case` a quattro esiti vale tre scelte.
I confronti concatenati sono predicati Lisp, non cicli aggiunti dal modulo.

| Funzione | File | Righe | Percorsi |
|---|---|---:|---:|
| `riduci-binary32-cbor` | narrow | 10–31: 22 | 7 |
| `riduci-significando64-cbor` | narrow | 37–55: 19 | 7 |
| `riduci-binary64-cbor` | narrow | 59–81: 23 | 7 |
| `check-float-cbor-range` | write | 9–22: 14 | 7 |
| `check-float-cbor-words` | write | 27–41: 15 | 8 |
| `seleziona-float-cbor` | write | 47–61: 15 | 9 |
| `scrivi-float-cbor-minimo` | write | 65–90: 26 | 6 |

Tutte restano entro COD-12/COD-13. Ogni funzione ha FTYPE completo,
docstring con pre/post/errori e riferimenti REQ. `safety 3` è esplicito.
I due `cond` numerici terminano in `t` con `invariant-violation`;
il `case` delle parole termina in `otherwise` con la stessa condizione.

## Inventario delle decisioni composte

Sono sei AND/OR nuovi. Le post-guardie del quoziente corrette usano due
confronti distinti e un IF, senza aggiungere un AND/OR. La tabella elenca
le condizioni; non afferma che ciascuna sia già stata mostrata decisiva
indipendentemente. I rami delle guardie interne restano nel denominatore
della futura coverage.

| Posizione nel file write | Forma e condizioni | Verifica da eseguire |
|---|---|---|
| 13–14, range | AND: buffer octets; START index; END index; `START <= END <= LENGTH` | Destinazioni non simple/displaced, tipi/range e precedenza; guardie interne separate |
| 36, parole AI25 | AND: HIGH zero; LOW <= u16 massimo | Parole incoerenti e precedenza LOW/coerenza/capacità |
| 51, selezione ingresso | OR: AI27; HIGH zero | Ingressi pubblici validati; guardia interna inventariata |
| 55, riduzione64 | AND: AI27; esattamente accorciabile in32 | 64 mantenuto/ridotto, soglie e payload NaN |
| 57, riduzione32 | AND: AI26; esattamente accorciabile in16 | 32 mantenuto/ridotto, espansioni half e subnormali |
| 59, selezione uscita | OR: AI27 scelto; HIGH zero | Forme scelte e guardia interna inventariata |

## Controlli e ragionamento aritmetico

Per binary32, esponenti 113–142 producono i normali half con bias
sottratto 112; esponenti 103–112 producono subnormali tramite significando
implicito e shift `126 - exponent`. Il predicato esistente richiede
allineamento esatto prima della riduzione. Zero e speciali hanno rami
separati; la frazione NaN viene spostata di 13 bit e il segno viene
confrontato con quello di ingresso.

Per binary64, esponenti 897–1150 producono normali binary32 con bias
sottratto 896 e frazione ricavata dalle parole separate; esponenti
874–896 producono subnormali con shift `926 - exponent`, compreso 32.
Il quoziente usa al massimo HIGH21 e LOW32. La ricostruzione verifica
HIGH tramite `ASH RESULT (SHIFT - 32)`; sotto 32 ricava LOW dai soli
uno/due bit bassi, altrimenti richiede LOW zero. Gli shift intermedi
ricostruiscono parole u32, senza materializzare l'intero binary64.
Infiniti e NaN mantengono segno e significando zero-padded, incluso il
bit signaling/quiet. La selezione tenta 64→32 e poi 32→16.

Il writer esegue range/AI, tipi HIGH/LOW e coerenza prima della selezione;
poi verifica la capacità della forma scelta, usando END. Solo dopo
costruisce NEXT e scrive il lead. Il percorso a nove byte scrive HIGH4
e LOW4; le altre forme scrivono LOW2 o LOW4. La guardia finale confronta
il cursore con NEXT; il ritorno è `(values next)`.

COD-24: riduzioni32/64 verificano accorciabilità in ingresso e segno in
uscita; il quoziente verifica larghezza/allineamento e ricostruzione delle
parole; il range verifica input e identità dello span; le parole verificano
i tipi esterni e la coerenza della forma restituita; la selezione verifica
la relazione AI/HIGH prima e dopo; il writer verifica span e progresso.
Le guardie non modificano dati. Gli errori interni sono `invariant-violation`
e devono raggiungere il confine fail-stop del proprietario.

## Checklist C1 a dodici punti

1. **Requisiti e ADR.** REQ-CBR-004 realizza la scrittura raw minima locale;
   REQ-AFF-004/008 coprono invarianti e limiti. ADR-0014 è coerente;
   il budget documentale ADR-0048 resta superiore.
2. **Invarianti.** INV-F1 riguarda byte/formato verificati prima di restituire
   NEXT; INV-P6 riguarda buffer esclusivi e assenza di scritture condivise.
   Il corpus contiene confronti freddi dell'intero array, errori senza
   mutazione, arità, sentinelle e worker su destinazioni private.
3. **Errori.** INVALID-ARGUMENT distingue range, AI, HIGH, LOW e parole;
   RESOURCE-EXHAUSTED distingue la capacità. Ordine, offset NIL e array
   intatto sono verificati dal corpus. Le guardie interne hanno motivi
   distinti per input/campi, esponente, segno, allineamento, ricostruzione,
   AI, selezione, span e progresso; il writer non intercetta gli errori.
4. **Limiti.** Nessun nuovo ciclo o ricorsione. L'helper BE esistente fa
   al massimo quattro passi; al massimo due parole e nove byte per chiamata.
   Nessuna attesa nel prodotto; i worker di prova hanno timeout e cleanup.
5. **Allocazioni.** Nessuna misura ancora eseguita: COD-30 rimane da
   verificare con benchmark, baseline e controllo positivo preregistrati.
   La sola forma statica non costituisce prova di heap zero.
6. **Confine del modulo.** Le parole esterne vengono validate prima delle
   dichiarazioni restrittive e della scrittura. Il risultato pubblico è
   NEXT; non escono float nativi, AST o riferimenti condivisi.
7. **Decisioni composte.** Inventario completo sopra; coverage grezza e
   dimostrazioni condizione per condizione restano da produrre. Nessuna
   attestazione MC/DC o esclusione automatica di guardie.
8. **Proprietà.** OWNER/SHARED dichiarano destinazione esclusiva e parole
   locali. Nessun globale mutabile, arena, lock o scratch nuovo nel prodotto.
9. **Tracciabilità e check.** Requisito e matrice sono aggiornati staticamente;
   export, ASDF e ambito esatto dei due file nel driver coverage sono coerenti.
   `make check` e i self-test degli strumenti devono ancora essere eseguiti.
10. **Regole e deviazioni.** Nessuna deviazione statica richiesta per la
    versione letta; il rilievo COD-24 precedente è risolto. Compilazione
    senza avvisi, misure e coverage non sono anticipate da questa lettura.
11. **Parallelismo.** Nessuna chiamata su buffer privato tocca uno stato di
    altra Serie o introduce lock/attesa/scrittura condivisa. Il prodotto
    consente chiamate indipendenti; le prove future non implicano scaling.
12. **Durabilità.** Nessun cambiamento durevole, punto di pubblicazione,
    rimozione o rollback introdotto. Docstring e contratto dichiarano
    esplicitamente questo confine e il fail-stop su errori interni.

Esito: nessun ulteriore difetto statico rilevato nella versione identificata.
La seconda lettura indipendente, le campagne e il gate C1 restano necessari.
