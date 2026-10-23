# Metodo del contesto worker dei writer

Preregistrazione del 2026-10-09 sulla base `cf60913`, prima delle campagne
congelate di correttezza, mutazione e allocazione. Il primo probe di sviluppo
`4000545928-command-51771-0` compila i primi tre sorgenti, prima dell'aggiunta
delle API di adozione/cessione: non viene attribuito al codice finale.
REQ-CON-001/002/004/005 e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4;
ADR-0005 e ADR-0045 §§6/8. Codice C1, strumenti C4.

## Contratto e stati

Contesto preallocato una volta sul thread worker che ne rimane proprietario,
non rientrante. Ready/owner read-only; cursor/home/ref/lease/pending e
batch-generation locali, nessun contatore globale. Sei fasi operative e una terminale:

- idle: nessun riferimento, lease o batch; take bounded aggiorna cursor anche
  dopo empty/busy. Una testa restituita diventa claimed, home è il predecessore
  modulo K del cursore restituito da ready, senza ricercare il writer.
- claimed: riferimento posseduto, begin separato acquisisce lease e passa running.
  Busy conserva il riferimento. Not-ready e generation esaurita non sono retry ciechi.
- running: pop con target/span/alias verificati prima dell'overflow locale.
  Messaggi creano batch con count positivo e token locale nuovo; empty/yield
  mantengono running con token0 e non incrementano generation. Busy non muta il contesto.
- batch: debito esplicito; vietati nuovo pop e termine. Ack valido attesta che
  il caller ha elaborato tutto il batch, elimina pending e torna running.
  Token monotono legato alla coppia contesto/token, non unico tra contesti.
- finishing: end viene latched prima della chiamata handoff; busy conserva
  lease e riferimento e consente solo il retry del termine. Nessuna rielaborazione.
- reschedule: end ha già rilasciato lease, riferimento conserva un obbligo.
  Recycle room pubblica e libera idle; full trasferisce la testa al contesto
  claimed conservando home e count. Busy conserva l'obbligo, senza ripetere end.

Adotta da idle un obbligo unico non nel ring; cede da claimed/reschedule al
caller la coppia writer/home e libera idle, senza azzerare batch-generation.
Nessuna cessione di lease/batch attivi. Permette restituzione esplicita degli
obblighi prima del ritiro o esaurimento del contesto, senza promettere un pool.
A overflow batch-generation, pop rifiuta anche se sarebbe empty/yield; end
rimane disponibile, seguito da cessione e adozione in altro contesto.

## Confini

Fase errata è resource-exhausted :worker-state, owner/ack/adozione invalidi
sono invalid-argument; overflow è resource-exhausted :worker-generation.
Busy di begin/pop/recycle conserva tutti i campi. Il primo end busy cambia
solo running→finishing, latch intenzionale; retry successivi conservano tutto.
Il confine di ciascun passo registra la condizione originale e passa a faulted
su errori inattesi/permanenti (not-ready, writer generation, lease privata,
invarianti o errori runtime); propaga la stessa condizione, conserva i campi e
blocca tutti i passi successivi, inclusa cessione. Solo ragioni recuperabili
esplicite per tipo/operazione conservano la fase. Wrong-thread e contesto già
faulted sono rifiutati fuori dal handler, senza alterare la diagnosi originale.
Nessun reset o rollback dopo mutazione; handler interno dynamic-extent.
Getter owner-only consentono diagnosi del riferimento e condizione anche a fault; non
trasferiscono proprietà o autorizzano doppia pubblicazione.

Non vi sono thread, callback, I/O, timer, retry o attese nel prodotto.
Take usa la scansione esistente ≤64 shard/128 CAS; gli altri passaggi sono
O(1), oltre alla copia batch già bounded dal writer. Work e ack fuori dalle
guard ready. Empty non autorizza park/shutdown. Catene full locali, quote,
admission, wake/park, controller FAULTED, adattamento del pool e applicazione
WAL restano da integrare. Ack non verifica effetti esterni del caller.

## Verifiche preregistrate

- Oracolo indipendente a liste: 8 configurazioni K1/4, readycapacity1/2,
  quantum1/2, 13 writer e 1000 passi ciascuna, payload unici e drain finale.
- Tutte le fasi, quota cumulativa, buffer privati/sentinelle, alias/span,
  ack stale nel batch successivo, ordine preflight, overflow senza wrap,
  cessione/adozione e impossibilità di cedere un batch/lease attivi.
- Busy di begin/pop/finish/recycle con snapshot; home corretto su scansioni
  ruotate, regressione ring full per tutti i consumer, nuova ondata senza cleanup.
- Thread reali riusati e producer vivi, shard indipendente che progredisce
  durante guard occupata, wrong-thread rifiutato prima di mutare.
- Due letture C1 con dodici punti, inventario di ogni decisione e raw coverage
  di tutti gli undici file execution, senza esclusioni o MC/DC dedotta da sb-cover.
- Dodici mutanti semantici dei soli nuovi worker files, sostituzioni uniche
  preregistrate nel driver prima delle campagne. Baseline execution completa;
  segnali OS/late failure sono worker-error, non detection. Raw baseline+12log.
- Composizione handoff/ready/worker: K1/4 × C1/3, cinque campioni ×4096cicli,
  warmup128 e GC fuori misura. Full backlog→recycle→nuova testa e room→publish;
  idle, batch ack, identità/count/status/cursor, lease e token crescenti verificati.
  Writer C+1 per shard distinti; ruolo iniziale ruotato; generazioni reali non
  azzerate per rendere costante il sink. Derivazione indipendente in appendice.
- Heap positivo, sink errato, clockzero distinto, reporter parziali e directory
  preesistente, strict COMPILE-FILE completo e self-test FASL dei C4 con avvisi fatali.
- Make check completo una volta sul codice finale; altre chat integrate prima
  del congelamento. Si ripete solo se cambia codice/base rilevante o un gate fallisce.

Ogni tentativo è registrato con record-command; dati raw/output/argv/ambiente
conservati, source snapshot prima/dopo stabili. Cache/processi separati su copia
congelata; grandi dati compressi senza perdita. I risultati osservati non
qualificano zero heap universale, throughput, P99, fairness o l'intero motore.

## Oracolo composto e mutanti esatti

Il driver fissa dodici sostituzioni uniche: owner-check-ignored, claim-cursor-stays,
claim-home-is-next, start-keeps-claimed, batch-generation-stays,
ack-stale-token-accepted, ack-keeps-pending, end-skips-finishing-latch,
end-keeps-lease, schedule-goes-idle, recycle-room-keeps-writer,
recycle-full-keeps-old-writer. I bersagli before/after sono letterali in
[`writer-worker-mutation.lisp`](../../tools/writer-worker-mutation.lisp),
verificati prima di ogni copia; non si mutano queue, writer, handoff o ready.
I difetti di forma e quelli con forma ancora valida sono entrambi inclusi.

Benchmark: in ogni shard A ha due payload e produce backlog, altri C writer
riempiono il ring prima del ricircolo full; il caller completa la testa, i
riferimenti residui e A. Un secondo ciclo room sullo stesso A ricircola
sul ring vuoto e completa il residuo. Ruolo di A ruota tra C+1 identità.
Lo score esclude i contatori assoluti di lease/batch, che vengono verificati
separatamente e persistono tra warmup, cicli e repliche.

Per M=K(C+1), derivazione del token fissata prima dell'esecuzione:
`T=K[416+115C+3C(C+1)/2]+7(C+3)K(K−1)/2+5M(M+1)/2+29+7(1 mod K)`.
Per (K,C)=(1,1)/(1,3)/(4,1)/(4,3): 578/858/2520/4084.
Le chiamate per ciclo sono `K(7C+27)+1`: 35/49/137/193.
Sink dei4096cicli, inclusi gli indici i: 10754048/11900928/18708480/25114624.
Il ricalcolo dell'autore e la lettura indipendente controlleranno la
formula contro le operazioni effettive, prima della misura congelata.
