# Verifica del recovery CLOSED

## Metodo prima delle esecuzioni

La suite `tests/recovery-closed/` verifica il nuovo legame fra CONTROL,
prefisso CLOSED e capacità readonly, nei formati v1/v2 e nelle origini
writer/compaction. La specifica resta quella di ADR-0040/0041. Le prove
non cambiano il formato o i limiti del database.

Le fixture riusano packing bytewise e CRC bitwise degli oracoli CONTROL,
recovery e ACTIVE. Ogni input e ogni scratch appartengono alla fixture;
CONTROL è letto con l'API pubblica prima della chiamata CLOSED. Nessuna
tabella o risultato di prodotto viene fabbricato nel percorso positivo.
I costruttori privati possono essere usati solo in FI esplicitamente
separate, per verificare guardie difensive altrimenti irraggiungibili.

Il backend iniettato registra le richieste di I/O: massimo 32768 eventi,
4096 byte per file e otto capacità complessive. Header letto una volta,
poi chunk fino a P. Un suffisso arbitrario oltre P resta intatto e non
letto; EOF prima di P è un errore I/O. Capacità, range, budget e backend
sono verificati prima di leggere. ID zero, bit alti e massimo u64 hanno
fixture dichiarative; per il massimo ID il CONTROL usa una transizione
delta legale che esaurisce lo spazio senza wrap.

La matrice semantica distingue ordinario/prepared, OUTCOME locale ed EDIT:
assenza di entrambe le prove, una sola prova, entrambe coerenti, conflitto.
Duplicati e limiti fisici precedono la coalescenza. CSN zero presente resta
distinto dall'assenza; il TXID non contribuisce come CSN. SEAL writer,
OUTCOME orfani ed esiti EDIT contribuiscono come stabilito dal contratto.
Le prove omonime discordanti sono rifiutate anche senza prepared: R1 della
revisione ha motivato il controllo preliminare su tutti gli OUTCOME.
R2 ha motivato i controlli u64 e di cardinalità del fold EDIT.
Compaction contiene soltanto record ordinari, senza SEAL o prepared.

Il gate dell'insieme controlla tutti e soli i CLOSED del medesimo token
CONTROL, ID unici, P esatto, budget e capacità vive. La query CSN della
Serie usa ACTIVE e l'intero insieme verificato. Questa campagna non
qualifica l'aggregazione globale di tutte le Serie e del decision log,
la creazione del registro o l'ammissione del traffico.

Le prove native riusano il namespace 0700 e i registri CONTROL esistenti,
temporanei esclusivi e deadline seriale di 30 secondi. Leggono i segmenti
reali e attraversano il gate CLOSED prima della pubblicazione CONTROL.
Confrontano byte, nomi e capacità; i rifiuti precedono il claim. Eventuali
guasti di pubblicazione conservano il protocollo e le condizioni originali.
Non sono prove di power loss o scritture esterne concorrenti.

## Coordinamento e risultati

Gli agenti scrivono file disgiunti senza esecuzioni. Prima delle prove si
chiudono tutti gli scrittori, si congelano sorgenti e documenti e si salva
la revisione. Ogni tentativo passa dal recorder strutturato esistente,
compresi compilazioni fallite, FI e verifiche degli strumenti. Correzioni
successive producono revisioni e run distinti.

La copertura `recovery-closed` seleziona esattamente gli otto file di
prodotto `types`, `read`, `verify`, `resolve`, `build`, `csn`, `csn-serie`,
`publication`. Package e fixture sono esclusi. I contatori vengono azzerati
dopo il caricamento, prima della sola suite CLOSED. Self-test positivi e
negativi controllano il selettore e il rilevamento di un ramo mancante.
Forme/rami SBCL non misurano MC/DC. Eventuali residui restano nel
denominatore, senza eccezioni approvate implicitamente. Le FI seriali
di `guards.lisp` sostituiscono ritorni delle dipendenze entro la sola
chiamata, con `unwind-protect`, poi ripetono il percorso positivo. Le FI
dei costruttori e della tabella EDIT sono separate dalle fixture valide.
Non simulano power loss o accesso concorrente a una hash table congelata.

La [revisione indipendente](closed-recuperato-revisione.md) conserva due
letture dello stesso revisore, distinte dalla rilettura del coordinatore
e dai risultati runtime. I risultati sono conservati in un archivio nuovo
tramite il [collector comune](raccolta-comandi.md): manifest esplicito,
quattro worker per le copie, hash e inventario chiuso. I testi storici
sono dati; le cache FASL sono escluse e ricostruibili. Il produttore della
raccolta resta separato dall'archivio che ha appena verificato.

Nessun nuovo benchmark previsto. Il tempo del recorder comprende bootstrap,
oracoli e fixture; il carico esterno è incontrollato. Non si deducono
throughput DB, heap zero, scalabilità o copertura C1 completa dal solo
successo locale. Fonti fisiche, catalogo e namespace restano precondizioni
del controller fino alla pubblicazione e al successivo gate di ammissione.

## Esiti conservati

La [campagna del 2026-10-16](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-16-closed-verifica/report.md)
conserva 69 test superati, i tentativi falliti, le varianti e i controlli
d'integrazione. Copertura grezza: 739/814 forme e 87/94 rami; tre rami
applicativi di conteggio e quattro generati restano non raggiunti.
Il report mantiene denominatori, oracoli e limiti; C1/MC/DC restano aperte.
