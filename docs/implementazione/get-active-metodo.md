# Metodo di verifica funzionale: GET ACTIVE ordinario

Questa campagna aggiunge una prima suite dedicata in
[`tests/get-active/`](../../tests/get-active/). Il perimetro è la sorgente
ACTIVE di una Serie, preflight OPEN, costruzione delle pagine immutabili,
acquisizione della radice effettivamente pubblicata e lettura ordinaria.
L'antenato di integrazione è `105ae0dd28a6ae3e7ee60ab1477815a49b1b350b`.
Il metodo precede le esecuzioni; freeze ed esiti saranno registrati nelle
prove native. Non si modifica il codice di prodotto.
Prima del freeze si integra anche `c4bbb037b779d33ee9e8c01b4a33aac875ccf96f`,
che comprende le prove del writer float aggiunte da un'altra campagna.

## Oracoli e casi fissati

Si fissano 28 test nominati: 12 costruzione/preflight, quattro geometria
della directory e 12 lettura. Iterazioni sui formati o sui confini non
aumentano il numero dei test nominati. Gli accessi interni verificano
contratti locali dichiarati; gli ingressi pubblici rimangono distinti.

La fixture autonoma possiede un file reale con capacità append e readonly
associate, header letterale e controller iniziale con radice NIL e offset
64. Usa il protocollo pubblico preflight, sigillatura CSN, adozione, WAL
e pubblicazione; controller e worker non sono oggetto di nuovi test.
Header, cornici e CRC bitwise attesi sono indipendenti dagli encoder del
prodotto. Offset e frontiere provengono dal piano: header 64, record
`24 + K + V`, SEAL 56. Il CSN atteso proviene dal valore iniziale noto del
registro, senza leggere la mappa costruita per ricavare l'oracolo.

I casi di costruzione comprendono v1/v2, PUT e tombstone, pagina senza PUT,
identità e capacità del file, preflight senza assegnazione CSN o I/O,
budget di pagine, PUT, record, byte e payload. Un primo PUT richiede 536
byte di payload al picco; il secondo append richiede 1072 al picco e
mantiene 560 byte nella radice risultante. Si provano limite esatto e uno
sotto. PREPARED e OUTCOME validi sono rifiutati prima del CSN; lotto,
radice e registro rimangono invariati. Il riuso legittimo del lotto non
altera una radice precedente. Un CRC corrotto nel lotto SEALED provoca
il guasto di Archivio previsto, con causa originale preservata.

La geometria attraversa i rank 15/16, 255/256 e 4095/4096 e la vista
sintetica massima di 65.536 pagine. Quest'ultima è un contratto locale di
ricerca e convergenza, costruito con un oracolo diretto indipendente;
non rappresenta 65.536 lotti nativi. Nodo assente, larghezza o foglia
errata e append su foglia occupata verificano i guard e la persistenza
del grafo precedente, rispettando i tipi dichiarati.

Le letture entrano tramite AVVIA-GET con snapshot ed EBR reali e chiamano
le tre API ACTIVE. Si confrontano byte, sentinelle e tutti i cinque esiti
di lettura, cache fredda/calda, formati v1/v2, flag ordinari 0/4 e CSN oltre
la word bassa. La radice soltanto pianificata non autorizza il candidato;
un PUT precedente conserva la propria frontiera di pagina dopo append.
Location in header, SEAL, tombstone, fuori frontiera o senza riga, CSN
discordante nelle due word, dimensione errata e FD chiuso sono guasti.
Si verificano proprietario errato, buffer piccolo e nuovo ingresso GET,
scadenza dopo copia provvisoria e uscita non locale durante pread.
L'osservatore registra FD, offset e quantità; resolve/probe non leggono.
Cleanup GET/EBR deve essere verificato prima del cleanup esterno.

## Esecuzione e conservazione

Prima dei gruppi si committano sorgenti, test, strumenti e metodo. Nessuno
di questi cambia durante l'esecuzione. `tools/record-command.lisp`
conserva argv, ambiente, commit, working tree, inventari/hash prima e dopo,
stdout, stderr ed exit code anche in caso di errore. Correzioni richiedono
un nuovo freeze; le prove precedenti rimangono attribuite al loro commit.

La verifica locale completa è `make check`. La copertura isolata usa
[`get-resolver-coverage.lisp`](../../tools/get-resolver-coverage.lisp)
con `--suite active`: carica i test senza invocare test-op, azzera SB-COVER
ed esegue soltanto la nuova suite. Il perimetro comprende package, types,
rows, read e i sei file active-* del resolver: dieci sorgenti, undici HTML
con l'indice. Lo stato grezzo viene salvato prima della validazione e i
conteggi sono confrontati con quelli usati dall'HTML. Il profilo CLOSED
preesistente conserva default, perimetro e comportamento.
Un processo positivo separato verifica il default CLOSED; tre fixture
negative verificano suite ignota, suite duplicata e report duplicato.
Devono uscire con errore di uso prima della creazione della directory.

### Ripetizione dopo l'integrazione delle fonti della Serie

Il primo freeze è `42dcad77530c09784f9d77fabb92ff4477927983`.
Prima della ripetizione si integra il main esatto
`64a5ef06987af61c36ce9818eb24ca8f0a0eb7f4`: aggiunge 27 test delle fonti
ACTIVE/CLOSED e modifica il wrapper ACTIVE perché deleghi al resolver
della radice catturata. Il totale atteso diventa 1.107 test di modulo in
29 suite, più due smoke check; il verificatore lo ricava comunque dai
sorgenti Git congelati. I nostri 28 test mantengono il perimetro ordinario;
non qualificano autonomamente la nuova API della radice catturata.

Si ripetono `make check`, copertura ACTIVE e compatibilità CLOSED sul
nuovo freeze, in processi e cache private separati. La fixture CLI
`--suite active --suite active`, con quattro argomenti e nessun `--report`,
deve raggiungere il guard specifico del duplicato. La precedente fixture
con sei argomenti raggiunge soltanto il guard di cardinalità; le sue prove
restano attribuite al primo freeze. La seconda copia di lavoro mantiene
immutati i gruppi originali mentre il loro audit finale procede in parallelo.

### Ultima integrazione prima della pull request

Si integra poi il main esatto
`061e638200f0d97fc2443c7dec38d4362ef274e1`, che aggiunge il lifecycle del
pool e la preparazione del checkpoint CONTROL. Le 18 nuove prove del
pool portano il totale atteso a 1.125 test in 29 suite, più due smoke
check; il conteggio finale viene ricavato dai sorgenti Git congelati.
Il codice e i test della nostra suite ACTIVE restano invariati.

Si committano integrazione e documenti e si esegue una verifica completa
in una terza copia separata, con cache FASL privata. Non si riscrivono
i gruppi di spike già congelati nelle prime due copie. Le coperture
rimangono attribuite ai loro due freeze; non si ripetono perché i dieci
file del loro perimetro sono invariati nell'ultima integrazione.
L'audit finale locale ricava inventario, nomi, ordine e conteggi dal nuovo
freeze, conservando tutti i gruppi e le fixture del controllo completo.

Prima della pull request passano compilazione senza avvisi, regressione,
controlli statici, tracciabilità, collegamenti e conservazione. La CI
ripete i controlli su Linux/macOS e i documenti separatamente. Le prove
sono lette come dati tramite `tools/evidence-storage.lisp`, mai caricate
come codice; si conservano gruppi completi, output grezzi, fallimenti e
FASL originali. Revisione indipendente di fixture, oracoli e risultati.

## Limiti delle conclusioni

Non si misurano prestazioni, RSS o allocazioni; i payload sono calcoli di
geometria. SB-COVER non dimostra MC/DC. Restano aperti qualifica C1,
decisioni non esercitate, requisiti e Fase 0. Sono esclusi prepared/OUTCOME
in ACTIVE come funzionalità, EDIT, indice concreto atomico, directory
mista, rotazione/reclaim, multiserie, stress, scheduler e server.
