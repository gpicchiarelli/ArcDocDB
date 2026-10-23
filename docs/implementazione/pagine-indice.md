# Pagine persistenti dell'indice primario — I2

> **Deciso (implementazione incrementale autorizzata → ADR-0058)** — Codec C1
> locale, REQ-IDX-009, INV-I8, INV-A2, INV-A8 e INV-P6. Backend, cache e
> pubblicazione nel motore restano da integrare; l'indice corrente resta residente.

[ADR-0058](../adr/0058-pagine-indice-primario.md) definisce la rappresentazione
binaria senza cambiare segmenti, WAL, control log, SEAL, EDIT o DECISION.
Il [selettore automatico](indice-automatico.md) rimane un componente distinto.

## Identita' e PageRef

Una pagina appartiene a (UUID Serie di 16 byte, immagine, offset, generazione,
dimensione). Immagine, offset e generazione sono positivi e minori di 2^60.
Offset allineato alla dimensione, zero riservato; un'immagine usa una sola taglia.
L'offset e' un indirizzo in un futuro file immagine, non una location nei segmenti
dei documenti. Header del container e sua pubblicazione non sono implementati.

PageRef contiene offset u64 e generazione u64; Serie, immagine e taglia sono
ereditate dal contesto. Zero/zero significa assenza, una coppia parziale e'
corrotta. Un figlio ha offset strettamente minore del genitore e generazione
non maggiore, entrambi verificati anche con CRC validi. Il writer costruira'
prima figli e code, poi genitori e teste. Non si riutilizzano offset/immagini
e non si riavvolgono generazioni. Il lettore verifica l'identita' attesa ad
ogni caricamento; lo stesso offset in un'altra immagine non e' la stessa pagina.

Queste regole impediscono cicli nei riferimenti locali ma non certificano
presenza, frontiera durevole o copertura del grafo. Il futuro file allocator
verifichera' anche limiti del filesystem, quote e riserve prima dell'append.

## Header comune, little-endian

| Offset | Byte | Campo e vincolo |
|---:|---:|---|
| 0 | 8 | Magic ASCII `ARCIPG01` |
| 8 | 2 | Versione 1 |
| 10 | 1 | Tipo: 1 bucket, 2 directory, 3 frammento di chiave |
| 11 | 1 | Log2 della dimensione: 12, 14, 16 |
| 12 | 4 | Flags zero |
| 16 | 16 | UUID Serie esatto |
| 32 | 8 | Identita' dell'immagine |
| 40 | 8 | Offset di questa pagina |
| 48 | 8 | Generazione di questa pagina |
| 56 | 4 | Byte usati del corpo, esclusi header e padding |
| 60 | 4 | Count, con significato specifico del tipo |
| 64 | 8 | Offset NEXT (overflow bucket o prossimo frammento), zero nella directory |
| 72 | 8 | Generazione NEXT |
| 80 | 4 | Parametro specifico del tipo |
| 84 | 4 | Riservato zero |
| 88 | 4 | CRC32C dei byte [0,88) |
| 92 | 4 | CRC32C di tutto il corpo [96,dimensione), incluso padding |

Il CRC header viene controllato prima dei campi. Versioni e tipi ignoti con
header integro producono `unsupported-format`. Corpo incompleto, CRC errato,
identita', geometria o riferimenti incoerenti producono `corruption-detected`.
Il padding non utilizzato deve essere zero anche dopo la verifica del CRC.
Checksum valido non equivale a semantica valida o a dato committed.

```text
pagina = header96 | corpo usato | padding zero
bucket = controlli[C] | entry[C * 64] | arena chiavi inline
directory = PageRef[2^bits]
chiave = frammento contiguo di byte della chiave completa
```

## Bucket flat

| Dimensione | Slot C | Massimo vivi (7/8 C) | Arena massima inline | Corpo massimo |
|---:|---:|---:|---:|---:|
| 4096 | 32 | 28 | 1920 | 4000 |
| 16384 | 128 | 112 | 7968 | 16288 |
| 65536 | 512 | 448 | 32160 | 65440 |

Calcoli di layout, non misure di prestazione o RSS. Parametro = C, count =
slot vivi. Un controllo e' EMPTY 255 oppure fingerprint 0..127, i sette bit
bassi del digest. DELETED e altri valori non sono persistiti: pagine nuove
sono copie compatte, non aggiornamenti in-place.

Il gruppo iniziale e' `(digest-low32 >> 7) & (C-16)`; i gruppi da 16 avanzano
circolarmente di 16, come nel primario residente. Si esaminano tutti i
candidati di un gruppo prima di concludere assenza su EMPTY. Il verificatore
rifiuta uno slot collocato dopo un precedente gruppo con EMPTY: il checksum
da solo non impedirebbe un falso miss. Nessuna sonda supera C/16 gruppi.

Ogni entry di 64 byte contiene:

| Offset entry | Byte | Campo |
|---:|---:|---|
| 0 | 8 | Digest completo, stesso hash/seme della Serie da integrare nel builder |
| 8 | 8 | CSN nonzero, con tutti i 64 bit disponibili |
| 16 | 8 | Location del record v2 |
| 24 | 4 | Lunghezza del record v2 |
| 28 | 2 | Lunghezza della chiave 1..65535 |
| 30 | 2 | 0 inline, 1 esterna |
| 32 | 4 | Offset chiave relativo al corpo, oppure zero per esterna |
| 36 | 4 | Riservato zero |
| 40 | 8 | Offset prima pagina chiave, oppure zero per inline |
| 48 | 8 | Generazione prima pagina chiave, oppure zero per inline |
| 56 | 8 | Riservato zero |

Gli slot EMPTY hanno tutti i 64 byte zero. Le chiavi inline sono impacchettate
in ordine fisico degli slot, a partire da C*65, senza buchi o sovrapposizioni;
la fine deve coincidere con USED. Le esterne non consumano arena e richiedono
un PageRef non nullo. La chiave completa decide l'uguaglianza, mai il solo hash.
CSN/location/lunghezza rispettano i limiti del payload primario v2; non si
serializza il seqlock. Il codec non verifica che il digest derivi dalla chiave,
non rileva tutti i duplicati e non certifica visibilita' o CRC del documento.
Questi sono obblighi del builder/lookup integrato con il seme e lo snapshot.

NEXT permette overflow per collisioni o bucket pieni. La futura politica
split/overflow deve avere budget di lavoro e I/O e distinguere ogni esito;
non si accettano catene arbitrarie come lookup lock-free completo.
Un miss locale sul gruppo EMPTY non conclude la ricerca nella catena:
quando NEXT e' presente il backend deve proseguire anche se il bucket ha
slot liberi, fino all'ultima pagina verificata. Il codec non esegue tale visita.
La validazione fredda puo' sondare fino a C/16 gruppi per ciascuna entry:
il limite conservativo e' O(C^2), con C <=512, da misurare nel caricamento.

## Directory paginata

Parametro = `bits | (shift << 8)`, bit alti zero; bits in 1..7/9/11 per
4/16/64 KiB, shift in 0..63 e bits+shift <=64. L'indice del figlio usa il
corrispondente intervallo del digest. Corpo esatto di `2^bits * 16` byte,
count uguale ai PageRef non nulli, NEXT nullo. Riferimenti ripetuti sono leciti
per bucket che coprono piu' posizioni. Il nodo radice e i livelli successivi
saranno collegati dal backend con controllo di prefissi e copertura; il
codec locale non conosce il padre o l'intero dataset.

Massimo fanout calcolato: 128/512/2048. I nodi possono essere caricati dalla
stessa futura cache: nessun requisito di directory completa residente.
I test costruiscono una directory da split con due bucket separati; questo
non implementa ancora l'algoritmo di split concorrente o la sua pubblicazione.

## Frammenti di chiave

Count = lunghezza totale della chiave, parametro = posizione del frammento.
USED = min(spazio corpo, totale-posizione). Ogni frammento non finale e' pieno;
NEXT non nullo se e solo se resta contenuto. Per 65535 byte servono 17/5/2
pagine nelle tre taglie, costruibili dalla coda alla testa con offset decrescenti
nell'ordine di lettura. Il lookup futuro verifichera' totale uguale alla entry,
posizioni contigue, generazioni e confronto dei byte, senza buffer completo
obbligatorio. Le sole pagine corrette non dimostrano una catena completa.

## API e proprieta'

Package `arcdocdb.index.page`:

- `crea-identita-pagina(serie, immagine, offset, generazione)` copia i 16 byte
  della Serie in un descrittore immutabile. Numeri e lunghezza invalidi sono
  rifiutati prima della copia; allineamento verificato quando e' nota la taglia.
- `crea-descrittore-pagina(identita, tipo, count, parametro, :next, :next-generation)`
  prepara metadati immutabili. Non prenota memoria del motore o scrive file.
- `scrivi-pagina-indice(buffer, start, end, descrittore, body, from, to)` verifica
  il corpo canonico preparato dal chiamante, poi scrive la pagina e CRC.
  Range, alias, limiti e struttura sono controllati prima di modificare la
  destinazione. Restituisce END; guardie e sorgente sono preservati.
- `verifica-pagina-indice(buffer, start, end, identita)` restituisce tipo,
  count, parametro, used, next e next-generation soltanto dopo tutte le verifiche.
  Non modifica il buffer, non alloca un oggetto per entry e non conserva riferimenti.

Le operazioni sono del percorso di preparazione/caricamento, fuori dal lookup
residente caldo. La lettura di valori u64 puo' produrre bignum SBCL; non si
dichiara allocazione zero, lock-freedom o immunita' alle pause GC per questo
codec. Buffer e descrittori devono rimanere stabili durante la chiamata;
la futura cache fornira' il protocollo di lifetime separato (I3). Nessun lock,
contatore o scrittura condivisa per Serie viene aggiunto.

## Metodo preregistrato e decisioni C1

Prima della prima esecuzione: fixture manuali little-endian e CRC bit per bit
senza helper del prodotto; encoder confrontato byte per byte con esse e decoder
verificato su fixture indipendenti. Guardie nonzero e sorgenti copiate per
individuare scritture esterne o effetti sui rifiuti. Esecuzioni registrate con
blob prima/dopo e tutti i fallimenti, quindi verifica globale `make check`.

| Decisione composta (COD-54) | Condizioni e casi indipendenti previsti |
|---|---|
| Costruttori | UUID 15/16 byte; ciascun numero nullo/negativo/frazione/oltre 2^60; count/parametro/next/generazione errati separatamente |
| Riferimento | null/null; coppie parziali; pagina valida/unaligned/self/forward; generazione positiva, precedente, futura; numeri oltre dominio |
| Corpo | USED entro pagina e buffer; arena esatta e superamento di un byte; offset del buffer diverso da zero |
| Record | CSN nonzero; chiave positiva; minimo/massimo record; documento massimo; fine location entro u32; riservati separati |
| Inline | offset uguale al cursore; lunghezza entro USED; PageRef nullo; packing senza byte extra |
| Esterna | offset zero e riferimento nonzero; riferimenti fuori dominio o futuri |
| Bucket | C corrispondente alla taglia; USED minimo; 7/8 C e slot successivo; live=count e arena finale=USED |
| Directory | bit alti zero; bits minimo/massimo; shift e somma; corpo esatto; count <= fanout e uguale ai non nulli |
| Frammento | totale positivo entro u16; posizione prima della fine; lunghezza esatta; NEXT coerente con finale/non finale |
| Header | magic in due parole; size code; flags e riservato; ciascuna componente identita'; USED/count/PageRef entro dominio |
| Scrittura | postcondizioni su CRC header e USED; preflight prima di qualunque effetto |
| Contratti privati | geometria nota, capacita'/slot e cursori nei buffer; pre/postcondizioni dell'header. Ingressi derivati dal preflight pubblico, senza allargare il dominio ammesso |

Le condizioni aritmeticamente dipendenti e i controlli privati gia' garantiti
dal preflight non implicano coppie MC/DC indipendenti raggiungibili. Questa
campagna funzionale non e' una qualifica C1/MC/DC o una prova del grafo completo.
Corruzioni raw di ogni byte della pagina 4 KiB e alterazioni con CRC ricalcolato
distinguono integrita' fisica e validazione della struttura. Test delle tre
taglie, chiavi massime, collisioni e immagine da split restano separati da
misure di write amplification, latenza e capacità oltre RAM, ancora da produrre.

I [risultati iniziali](pagine-indice-risultati.md) conservano anche i tentativi
falliti e le correzioni delle fixture, distinguendo verifiche mirate e globali.
