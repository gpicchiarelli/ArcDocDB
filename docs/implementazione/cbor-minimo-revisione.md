# Seconda lettura delle testate CBOR minime

Lettura C1 del 2026-10-09, conclusa dopo il freeze dei tre file dell'oracolo e
prima delle campagne. Il lettore ha scritto i nuovi test senza leggere
`cbor-minimal.lisp` o `cbor-float-minimal.lisp`; è autore storico delle
primitive header/struttura, ma non del nuovo filtro. Nessuna prova, build o
misura è stata eseguita durante questa lettura. Non è un'approvazione umana.

Nessun difetto statico aperto nel nuovo kernel. Le soglie MT0..6 coincidono
con le larghezze minime; i float sono trattati come campi IEEE e parole
separate, senza conversioni native. I confini normali/subnormali e gli
allineamenti rappresentano esattamente le unità binary16/binary32. Il segno
non cambia la possibilità di accorciare; NaN mantiene significando e posizione
quiet/signaling. La sintassi del lettore invariato precede ogni rifiuto
`:cbor-nonminimal`. Il divieto locale degli indefiniti è coerente con
[RFC 8949 §4.2.1](https://www.rfc-editor.org/rfc/rfc8949.html#section-4.2.1);
la sola preferenza di §4.1 non vieta ogni forma indefinita.

## Checklist C1

| Punto | Riscontro statico e limite |
|---|---|
| 1. Requisiti/ADR | AFF-004/008 e supporto parziale LIM-002; ADR-0014/0048 e contratto locale coerenti. Nessuna attestazione del profilo documentale completo. |
| 2. Invarianti | Campi, parole, allineamento e progresso controllati; corpus blind e supplemento indicati sotto. Le guardie interne restano nel denominatore. |
| 3. Errori | Range/reserved/truncated/indefinite/simple propagati; nonminimal al lead; difese tipizzate. Il kernel non possiede la Serie e non decide FAULTED. Runtime pendente. |
| 4. Limiti | Nessun nuovo ciclo o ricorsione; base limitata a nove byte, filtro a confronti/maschere. Nessuna attesa. |
| 5. Heap | Nessun costruttore o unione u64 nel nuovo successo; shift massimo 32, parole immediate sul target 64 bit. Misura heap e sensore positivo pendenti. |
| 6. Dati in uscita | Sei valori originali solo dopo sintassi e filtro; payload, tag e contenitori non vengono interpretati. |
| 7. Decisioni | D01…D10 della tabella corrispondono al codice. D03/D06 hanno il supplemento pubblico dichiarato; copertura e MC/DC non attestati. |
| 8. Proprietà | Buffer immutabile del chiamante, soltanto locali; nessuno scratch o globale mutabile. |
| 9. Integrazione | Export e ordine ASDF presenti; compilazione rigorosa, trace e `make check` dello snapshot ancora da acquisire. |
| 10. Standard | Sei funzioni con FTYPE/docstring e almeno due guardie, safety3, entro 60 righe/10 percorsi alla lettura. Nessuna deviazione statica rilevata; build/lint pendenti. |
| 11. Parallelismo | Nessun lock, attesa o scrittura condivisa per operazione. Due worker privati previsti; intervalli reali non provano core distinti o scaling. |
| 12. Durabilità | Nessuna scrittura, pubblicazione o eliminazione; punto di atomicità non applicabile. |

## Provenienza del corpus e supplemento

Il corpus blind comprende 14 test: tutti i 65536 half e 131072 espansioni,
vettori e adiacenze IEEE, lead/simple, soglie intere, 152 troncature,
precedenze, immutabilità, fuzz di 12288 casi seed `4D494E43` e due worker.
I tre blob congelati prima della lettura restano invariati:

| File | Git blob |
|---|---|
| `tests/codec/cbor-minimal-support.lisp` | `774e6cd0bec4a9d2242ad4dede878ffa2afca90c` |
| `tests/codec/cbor-minimal.lisp` | `b863ace9a22e8b7508b7c9d8f91465ebfbcd4e98` |
| `tests/codec/cbor-minimal-threads.lisp` | `e613ea025c2a886cdae7fd5e119cf80593c6b72e` |

Dopo la lettura è stato aggiunto, con autorizzazione del coordinatore, il
solo `tests/codec/cbor-minimal-edges.lisp`, blob
`c6f891dff335a37689ddbfabccf793d2e9f2f143`. Il test usa l'oracolo generale
su razionali, non helper del prodotto: coppie HIGH/LOW dei subnormali con
shift32/33/52 e il subnormal binary64 HIGH-only. Sono 13 valori con due segni,
26 chiamate pubbliche. Il supplemento è derivato dalla lettura D03/D06 e
non viene presentato come parte del corpus blind originale. Totale: 15 test.

Lo snapshot prodotto letto è `cbor-package` `0d014e499f0862f13674bd934070c166c286f256`,
`cbor-float-minimal` `ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f`,
`cbor-minimal` `761302dad1073c841397f6c88d595b114af8d9ef`.
Il dato schema 1 è conservato in `spikes/out/cbor-minimal-independent-review.lisp`.
