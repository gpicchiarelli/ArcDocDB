# Preparazione full text dai documenti CBOR

`arcdocdb.fulltext.document` collega i [documenti CBOR](../adr/0014-formato-record-documento-id.md)
all'[analizzatore](full-text.md) e al [codec degli indici](full-text-codec.md).
Esegue la preparazione nel worker, prima dell'ammissione del writer secondo
[ADR-0054](../adr/0054-contratto-e-formato-full-text.md). Produce un run sigillato
e il limite superiore da riservare per il futuro file. Non assegna CSN o ID,
non scrive WAL, non prenota il delta della Serie e non pubblica commit o READY.

Il primo impiego rimane un server NNTP Usenet in Common Lisp: `subject`, `body`
o `headers.subject` sono percorsi configurabili. L'applicazione interpreta NNTP/MIME
e fornisce testo UTF-8 decodificato; puo conservare l'articolo originale in un campo
binario non indicizzato. Message-ID, chiavi e documento originale non vengono modificati.

## Configurazione posseduta

`crea-configurazione-full-text(fields, index-id, generation-id, contract-version)`
riceve ID u64 positivi gia assegnati dal chiamante. Non e l'allocatore del catalogo.
Il formato dei dati Lisp dell'API, senza lettura o valutazione di codice, e:

```lisp
;; Ogni testo e un simple-array u8 UTF-8; i vettori esterni sono simple-vector.
(vector (vector 1 subject-alias (vector headers-key subject-key))
        (vector 7 body-alias    (vector body-key)))
```

Le variabili dell'esempio contengono gia gli array di byte UTF-8.
Sono ammessi 1…16 campi ordinati per ID u16 positivo, alias di 1…64 byte e percorsi
di 1…100 chiavi UTF-8, anche vuote. Alias e percorsi devono essere unici byte per byte;
non viene normalizzato il nome di un campo. Ogni buffer e vettore viene copiato.
Il solo profilo ammesso e `unicode-word-18.0.0-v1`.

`:limits` e un simple-vector di cinque u64 positivi nello stesso ordine del META:
input testuale complessivo, byte per termine, token complessivi, payload preparato,
lavoro. Default: 16 MiB, 1024, 1048576, 64 MiB, 268435456.
Il limite token e comunque entro u32. I valori dichiarati sono conservati integralmente;
il percorso caldo usa limiti effettivi entro fixnum. Gli ID sono codificati una volta
in 24 byte, senza letture di slot raw u64 durante la preparazione.

Prima delle copie il costruttore controlla memoria e limite META di 64 KiB.
Usa il bound conservativo `256 + 32*campi + 9*chiavi + byte(alias e chiavi)`:
copre le testate CBOR e i valori massimi dei metadati fisici ancora sconosciuti.
Una dichiarazione che non entra viene rifiutata prima del build o del commit.
Il budget di memoria fredda include copie, vettori, oggetti e overhead conservativo;
non misura RSS o tabelle Unicode condivise.

## Scansione ed esecuzione

`crea-preparazione-full-text(config)` prealloca un contesto privato con scanner CBOR,
maschere di percorso, analisi Unicode e run. Default: 65536 scalari, 65536 token,
4194304 byte per ciascuno dei due buffer analisi/run, 64 MiB di memoria complessiva.
Le capacita si configurano con `:max-scalars`, `:max-tokens`, `:token-bytes`, `:max-memory`.
Un documento valido puo richiedere piu scratch: il rifiuto e di risorse.

`inizia-preparazione-full-text(task, input, start, end, row)` prende in prestito
il documento immutabile, lungo al massimo 16 MiB. ROW e l'ordinale u32 proposto,
non una prova di appartenenza a un hint o di commit. I controlli su argomenti,
stato e alias precedono l'invalidazione del risultato precedente.

`passo-preparazione-full-text(task, quantum)` restituisce `:running` o `:done`:

1. Scansione completa con il kernel CBOR minimo esistente, senza AST o copie del documento.
   Una maschera fino a 16 percorsi accompagna ogni frame; le sotto-mappe non vengono
   rianalizzate separatamente per ciascun campo. Si verifica anche l'UTF-8 non indicizzato.
2. Analisi dei campi presenti in ordine di field-id, con NFC/folding/NFC e Word_Break
   gia implementati; copia nel run privato. Assenti e presenti vuoti restano distinti.
3. Ordinamento riprendibile del run, conteggio dei termini distinti e misura finale.
   Nessun risultato parziale viene restituito prima di tutti i controlli.

Il documento radice deve essere una mappa. I percorsi attraversano sole mappe e
selezionano chiavi testuali semplici: tag e chiavi complesse non sono alias delle
stesse chiavi testuali. Un antenato presente non mappa o una foglia presente non
stringa sono errori; `null` e array non vengono saltati silenziosamente. Le chiavi
selezionate duplicate, anche negli antenati, sono rifiutate.

Questo modulo verifica struttura minima, UTF-8 e percorsi interessati. Non verifica
l'ordine deterministico di tutte le mappe, l'unicita delle chiavi estranee ai percorsi,
la semantica dei tag o il contratto generale della Serie: questi controlli restano
al validatore documentale. Non sostituisce la verifica di record/hint o la rianalisi
indipendente dei dati di un segmento.

Il quantum vale 1…65536 passi. Normalizzazione, copia, sort e misura sono riprendibili.
Il kernel CBOR puo verificare una stringa intera in un passo, entro lo span di 16 MiB:
il quantum non e un limite di byte o una garanzia realtime. Il lavoro addebita nodi,
payload, confronti, analisi e operazioni sul run; `:max-work` puo abbassare il limite
della dichiarazione. `:max-nodes` limita il CBOR; `:max-file-bytes` il bound finale.
Il chiamante controlla la deadline ai confini e puo cancellare il task.

Input testuale, token e staging vengono sommati su tutti i campi dell'indice.
Il payload preparato usato e `20*token + byte(termini ripetuti) + 12*campi presenti`:
il limite e distinto dalla memoria fisica preallocata del worker, conteggiata dal
costruttore. Non si promette di raggiungere insieme tutti i massimi configurati.

## Risultato, riserva e ownership

`risultati-preparazione-full-text(task)` richiede DONE e restituisce cinque valori:
run SEALED, `U(documento)`, bound del file per quel solo documento, payload preparato
usato e byte di testo di input. Il run e preso in prestito fino al prossimo avvio:
prima di riusare il task il proprietario deve aver terminato l'uso o copiato i dati
nelle riserve possedute dal writer. La configurazione resta immutabile e condivisibile.

Il bound usa la [formula normativa](../formato-indice-full-text.md#limite-superiore-e-rotazione):

```
U = 16*campi-presenti + somma_distinti(32 + byte-termine + 16) + 4*token
file <= limite-fisso-indice-full-text(config) + somma_documenti U
```

Il costo fisso comprende header/directory, bound META della dichiarazione,
35 byte di padding e footer; si riserva una volta per segmento. Le versioni fisiche
committed contano anche se storiche. La misura non sottrae spazio sulla base della
visibilita di una query. Un budget file insufficiente impedisce DONE.

`annulla-preparazione-full-text` e idempotente sui task attivi/cancellati e rilascia
input e analisi. Gli errori di dominio propagati da `passo` rendono il task FAILED;
run parziali non sono accessibili. Un nuovo avvio puo riusare lo scratch. Gli errori
interni richiedono fail-stop al confine del worker; non diventano retry di un commit.
`stato-preparazione-full-text` espone solo IDLE/RUNNING/DONE/FAILED/CANCELLED.

Le [riserve del writer](full-text-riserve.md) possono ora prendere in prestito il run
DONE durante la copia posseduta. Il task resta DONE ma un nuovo avvio rifiuta con
`:fulltext-document-borrowed` fino alla fine della copia o alla cancellazione della riserva.
Il risultato preso in prestito dal caller non autorizza a bypassare questa ownership.

## Verifica e limiti

I 17 test documentali si aggiungono ai 39 precedenti. Una fixture CBOR di 25 byte
e attesi manuali fissano i due campi NNTP: U=145, staging=73, testo=9 byte.
Si verificano 32 prefissi, 25 troncamenti, tipi errati, duplicati dei percorsi,
budget cumulativi e rifiuto del file a bound meno uno. Cancellazione in sette fasi,
riuso, 100 livelli, 16 campi con ID fino a 65535 e ID/generazioni u64 massimi.

Su 128 documenti generati, la scansione di liste di parole costruite indipendentemente
confronta 115200 risposte su run e file, e verifica 128 bound contro i file serializzati.
Quattro worker hanno contesti distinti e un rendezvous limitato. Dopo warm-up,
1000 preparazioni con ricerca non allocano byte sullo heap misurato su SBCL 2.6.9 arm64,
anche con ID/limiti u64 massimi. Due nuovi mutanti semantici riguardano selezione
delle chiavi e deduplica del costo; la copertura strumentata esclude le allocazioni.

La [revisione delle decisioni](full-text-documenti-decisioni.md) esplicita il perimetro.
I [registri e tentativi originali](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-fulltext-document-dev-targeted/README.md)
conservano sorgenti, comandi, risultati e limiti.
Sono disponibili prenotazione locale e copie possedute nelle riserve del writer.
Il [ponte PUT/WAL](full-text-put.md) possiede gli stessi byte per analisi e append.
Restano il gate completo, il trasferimento nella vista pubblicata del delta,
la pubblicazione prima di H/ACK, il catalogo delle
generazioni, I/O durevole, MVCC e Query Engine. I requisiti complessivi restano progettati;
questa preparazione non rende il database pronto per il traffico NNTP.
