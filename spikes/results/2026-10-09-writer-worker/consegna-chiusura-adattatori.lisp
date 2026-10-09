(:SCHEMA-VERSION 1 :KIND :FINAL-CONSERVATION-ADAPTER-AND-HISTORICAL-DOC :SOURCES
 ((:PATH #A((33) BASE-CHAR . "spikes/out/worker-final-seal.lisp") :BYTES 2055 :SHA256
   "d5968cb2ea0ee2a2c1a8b103788794ff1cece9aacb794efbaa1284567fb7b1c0" :GIT-BLOB
   "e476b3ebcf35403be728d27871c4e336a6445034" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(defun worker-final-seal (publication-process gate-process)
 \"Conserva i record conclusi; costruzione finale senza qualificazione ricorsiva.\"
 (dolist (id (list publication-process gate-process))
  (let ((r (arcdocdb.evidence:read-evidence (format nil \"spikes/out/~A/report.lisp\" id))))
   (assert (and (eq (getf r :status) :ok) (eq (getf r :source-consistency) :stable)
                (eql (getf r :exit-code) 0)
                (equal (getf r :source-blobs-before) (getf r :source-blobs-after))))))
 (worker-copy-process publication-process \"consegna-conservazione-processo\")
 (worker-copy-process gate-process \"consegna-link-evidenze-processo\")
 (worker-save-source-bundle
  '(\"spikes/out/worker-final-seal.lisp\"
    \"/tmp/arcdocdb-worker-commit-copy.py\"
    \"/tmp/arcdocdb-worker-validate-commit.py\"
    \"/tmp/arcdocdb-worker-commit-message.txt\"
    \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-risultati.md\")
  (merge-pathnames \"consegna-chiusura-adattatori.lisp\" *worker-publication-directory*)
  :final-conservation-adapter-and-historical-doc)
 (worker-save-data (list :schema-version 1 :kind :final-conservation
                        :publication-process publication-process :editorial-gate-process gate-process
                        :base \"e07d77271758f3134b1977caf394fe38532b54ed\"
                        :branch \"codex/writer-worker\"
                        :limits '(:construction-after-successful-gate :no-recursive-gate-claim
                                  :byte-validated-original-process-records :no-product-change))
  (merge-pathnames \"consegna-chiusura-dati.lisp\" *worker-publication-directory*))
 (worker-refresh-catalog \"e07d77271758f3134b1977caf394fe38532b54ed\"
  :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                     \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"))
 (format t \"FINAL SEAL COMPLETE; all qualified process records preserved and flat catalog built.~%\"))
")
  (:PATH #A((35) BASE-CHAR . "/tmp/arcdocdb-worker-commit-copy.py") :BYTES 1077 :SHA256
   "2e14ebff96987fdb9fd2dbac0756aa948fb58598ae977c4e42bb92c3a2f67eb9" :GIT-BLOB
   "b5370a0571aa0e2ccb3ecfdfa2c56585f326e9dd" :TEXT "from pathlib import Path
import json, hashlib, shutil
s=json.loads(Path('/tmp/arcdocdb-worker-state.json').read_text())
t=json.loads(Path('/tmp/arcdocdb-worker-final-integration-state.json').read_text())
v=Path(t['final_integration']);w=Path(s['source']);records=[]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
for rel in s['owned_files']:
 if rel not in ['arcdocdb.asd','docs/implementazione/README.md']:
  assert sha(w/rel)==sha(v/rel),rel
for rel in s['evidence_dirs']:
 a=v/rel;b=w/rel;assert a.is_dir() and not b.exists(),str(b)
 shutil.copytree(a,b)
 for f in sorted(a.iterdir()):
  assert f.is_file() and not f.is_symlink();h=sha(f)
  assert h==sha(f)==sha(b/f.name)
  records.append({'path':str((b/f.name).relative_to(w)),'sha256':h})
f=Path('/tmp/arcdocdb-worker-precommit-copy-receipt.json');assert not f.exists()
f.write_text(json.dumps({'schema_version':1,'kind':'final-canonical-copy-to-owned-worktree','files':records},indent=2)+'\\n')
print('Copied and compared',len(records),'canonical evidence files; 14 source/tool/docs match frozen delivery')
")
  (:PATH #A((39) BASE-CHAR . "/tmp/arcdocdb-worker-validate-commit.py") :BYTES 1467 :SHA256
   "b33a7ac04fbe9af797f33985f0055690e1db1a18debf37809a00677fb636b19b" :GIT-BLOB
   "504a840f6d95db738235eeb5ecdf2dd46be5bb6a" :TEXT "from pathlib import Path
import json,hashlib,subprocess
s=json.loads(Path('/tmp/arcdocdb-worker-state.json').read_text());t=json.loads(Path('/tmp/arcdocdb-worker-final-integration-state.json').read_text())
w=Path(s['source']);v=Path(t['final_integration'])
def git(*a):return subprocess.check_output(['git',*a],cwd=w,text=True).strip()
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert git('status','--porcelain')==''
assert git('rev-parse','HEAD^')==t['upstream']
assert git('branch','--show-current')==s['publication_branch']
files=[]
for rel in s['owned_files']:
 assert sha(w/rel)==sha(v/rel),rel
 files.append({'path':rel,'sha256':sha(w/rel)})
for rel in s['evidence_dirs']:
 a=v/rel;b=w/rel
 assert sorted(x.name for x in a.iterdir())==sorted(x.name for x in b.iterdir()),rel
 for f in sorted(a.iterdir()):
  assert sha(f)==sha(b/f.name),str(f)
  files.append({'path':rel+'/'+f.name,'sha256':sha(f)})
changed=git('diff','--name-only',t['upstream'],'HEAD').splitlines()
assert set(changed)==set(x['path'] for x in files),(changed,files)
f=Path('/tmp/arcdocdb-worker-final-commit-verification.json');assert not f.exists()
f.write_text(json.dumps({'schema_version':1,'kind':'qualified-commit-byte-scope','commit':git('rev-parse','HEAD'),'base':t['upstream'],'branch':s['publication_branch'],'status':'passed','files':files},indent=2)+'\\n')
print('Verified exact commit scope and frozen bytes:',len(files),'files; commit',git('rev-parse','HEAD'))
")
  (:PATH #A((39) BASE-CHAR . "/tmp/arcdocdb-worker-commit-message.txt") :BYTES 454 :SHA256
   "9e5839b7dc3cebd145b0fa54748b0f273ec1418b2ae4fdc00c15bfdafb28609b" :GIT-BLOB
   "006ff892a99be9163c644ec3ffd2f05b20eaf502" :TEXT
   "Integra i contesti worker preallocati dei writer

Conserva claim, lease e ricircolo nel contesto proprietario; impone ack dei batch,
retry finishing e fault persistenti. Include 23 test worker, oracoli indipendenti,
prove concorrenti e campagne con evidenze originali, revisioni e limiti espliciti.

Verifica integrata sulla base e07d772: 415 test più smoke senza avvisi;
12/12 mutanti rilevati e 20 campioni locali con zero heap nel percorso misurato.
")
  (:PATH
   #A((133) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-risultati.md")
   :BYTES 8299 :SHA256 "e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55" :GIT-BLOB
   "0ccef3a7845d50a2d0ed66ea8a8f486a80a77f26" :TEXT "# Risultati del contesto worker dei writer

Campagne del 2026-10-09 sulla base `cf60913`, con sorgenti congelati dopo
la prima lettura C1. Contratto in [writer-worker](writer-worker.md),
[metodo preregistrato](writer-worker-metodo.md),
[inventario completo](writer-worker-decisioni.md) e
[catalogo dei dati conservati](../../spikes/results/2026-10-09-writer-worker/catalogo.lisp).
Le qualificazioni riguardano questa composizione locale, non il pool completo.

## Correttezza e integrazione

Il processo `4000547204-command-93189-0` termina OK/STABLE/exit0:
387 test più smoke, compilazione senza warning o style-warning, lint su
63 file con zero violazioni, tracciabilità di 114 requisiti/65 invarianti/
13 scenari FI/52 ADR senza errori, 221 documenti e 2007 link senza rotture,
self-test della conservazione, verifica delle evidenze e dieci spike.
Il [record completo](../../spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp)
conserva anche i rifiuti intenzionali delle fixture negative dei tool.

I test execution sono 89, di cui 23 nuovi. L'oracolo a liste indipendenti
esegue 8000 passi su otto combinazioni K1/4, capacità ready1/2 e quantum1/2,
13 writer, drain finale e uguaglianza payload accettati/consegnati.
Le fixture verificano quote cumulative, FIFO, buffer/sentinelle, home/cursor,
ack stale, busy con snapshot, latch finishing, ricircolo room/full,
adozione/cessione senza lease attive, overflow senza wrap e fault persistenti.
La regressione not-ready conserva la condizione originale e impedisce al
vecchio contesto di consumare una nuova ondata.

Una prova riusa quattro thread su sei ondate, con produttori vivi e 36
payload controllati mediante CRC, verificando progresso su uno shard mentre
un altro è occupato. Un'altra riusa due contesti proprietari concorrenti
su otto ondate, con un solo vincitore per obbligo. Queste prove non attestano
fairness, wake/park, shutdown o migrazione delle lease tra thread.

## Integrazione della base aggiornata

Dopo queste campagne la primaria integra l’inventario recovery in `e2f7a75`.
Il controllo distinto `4000548048-command-40192-0` è OK/STABLE/exit0:
400 test più smoke (execution89, recovery95), lint66/zero, tracciabilità
114/65/13/52 senza errori, 224 documenti/2017 link senza rotture e dieci spike.
Il [record integrato](../../spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp)
e il [catalogo dei suoi spike](../../spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp)
conservano il nuovo gate. Lo scope `4000548017-command-37007-0` confronta
i byte execution, test e tool worker con la copia qualificata: invariati;
ASDF e indice incorporano anche l’inventario. Le campagne worker già concluse
non sono rieseguite per cambiamenti della recovery indipendente. I due
master conservano i rispettivi descriptor/payload originali in directory
distinte, evitando collisioni dei nomi gzip. I documenti conclusivi sono
controllati separatamente dalla compilazione dei sorgenti congelati.

## Mutazioni e qualità degli strumenti

I due C4 sono compilati integralmente con COMPILE-FILE e self-test eseguiti
dai FASL, con avvisi fatali: `4000547221-command-94073-0` e
`4000547221-command-94074-0`, entrambi OK/STABLE/exit0. L'adapter conservato
ha un marker finale editoriale ereditato `RECYCLE-TOOL-STRICT-SELF-TEST-PASS`;
argv, sorgente compilata e risultati identificano esplicitamente worker.

La [campagna di mutazione](../../spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp)
`4000547268-command-97067-0` completa la baseline di 89 test e rileva
12/12 mutanti preregistrati. Ogni mutante ha exit1, segnale NIL e un vero
marker di avvio dei test; zero survived, compilation-failure, before-tests
o worker-error. Tutti i tredici log sono conservati con i bersagli esatti.

Il [catalogo del probe di revisione](../../spikes/results/2026-10-09-writer-worker-review/catalogo.lisp)
conserva separatamente il grande record processuale originale, con il
payload gzip originale. L’audit integrale e la sua proiezione compatta
sono entrambi conservati; il fallimento iniziale dell’adapter di proiezione
è dichiarato nell’inventario e non attribuito al prodotto.

La fixture OS separata usa SIGKILL reale: segnale9/exit137, classificazione
worker-error e detected0. Completamento autentico seguito da exit nonzero,
marker citati, warning/compilation failure, report parziali e destinazioni
preesistenti sono controllati dai self-test e non promossi a detection.

## Allocazione del percorso composto

La [campagna di allocazione](../../spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp)
`4000547268-command-97066-0` è OK/STABLE/exit0. Un contesto creato sul thread
proprietario, writer, ready ring e buffer sono preallocati. Ogni ciclo
compone enqueue, publish, claim, begin, pop/ack, end e recycle full/room;
identità dei writer, count/status/cursor e generazioni persistenti sono
verificati. Ruota il ruolo iniziale fra C+1 writer distinti per shard.

| Shard K | Capacità C | Chiamate/ciclo | Token | Sink per replica | Campioni completi | Heap osservato |
|---|---|---|---|---|---|---|
| 1 | 1 | 35 | 578 | 10754048 | 5 × 4096 cicli | 0 byte |
| 1 | 3 | 49 | 858 | 11900928 | 5 × 4096 cicli | 0 byte |
| 4 | 1 | 137 | 2520 | 18708480 | 5 × 4096 cicli | 0 byte |
| 4 | 3 | 193 | 4084 | 25114624 | 5 × 4096 cicli | 0 byte |

Warmup128 e GC fuori misura; controllo positivo 16777472 byte allocati,
baseline contatore zero, sink errato respinto e clockzero distinto da una
durata valida. La formula del metodo è ricalcolata rispetto alle operazioni
del driver. Tutti i tempi e campioni raw restano nei dati; carico esterno
non controllato, nessuna promessa di speedup, throughput, P99 o heapzero
universale. Startup ed errori sono fuori dal percorso normale misurato.
Il benchmark composto usa un worker; il parallelismo funzionale è verificato
dalle fixture con thread reali, non da una misura di scalabilità.

## Copertura e limiti

Copertura `4000547204-command-93188-0`, export
`4000547249-command-95826-0`, audit indipendente native/HTML/export
`4000547296-command-98426-0`: 1427/1660 espressioni e 199/230 esiti
su tutti gli undici file execution. I quattro nuovi file hanno 498/600
espressioni e 65/76 esiti. Le 233 espressioni e 31 alternative non marcate,
comprese quelle legacy, restano nel denominatore e nell'inventario.
Nessuna esclusione approvata o MC/DC dedotta da sb-cover; il gate C1 del
motore rimane aperto.

Il confine locale faulted è terminale e diagnostico: non realizza ancora
il controller FAULTED della Serie o il rilascio delle risorse dopo un fault.
Ack attesta il caller, senza verificare effetti WAL esterni. Catene full
rimangono sullo stesso shard; quote globali, admission, pool adattivo,
wakeup/park/shutdown e integrazione durevole restano lavoro successivo.
Empty è soltanto un'osservazione locale. Il probe iniziale
`4000545928-command-51771-0` è conservato come sviluppo precedente al codice
finale e non viene usato per qualificarlo.

## Conservazione finale delle evidenze

Il primo adapter di pubblicazione (`4000548817-command-74667-0`) ha respinto
una copia identica: confrontava con EQUALP oggetti riletti che contengono
simboli non internati. Il confronto corretto verifica byte originali e
decompressi, SHA256 e Git blob, con lettura validata e senza overwrite.
L’audit distinto `4000549512-command-14958-0` conserva quattordici fixture
positive/negative e il confronto di 46 copie canoniche, tutti passati.
Il marker finale dell’audit stampa un conteggio cosmetico errato; il report
contiene quindici risultati, verificati da `4000549715-command-34672-0`.
È conservato anche il tentativo iniziale dell’audit
`4000549424-command-9085-0`, fermato dal percorso relativo del payload
nella preparazione della fixture, senza coinvolgere il codice worker.

La ripresa `4000549781-command-39344-0` completa 69 coppie e cinque bundle,
poi esaurisce il limite heap predefinito del reader durante il catalogo
integrato. Le copie già valide rimangono originali. La sola chiusura usa
un limite heap di 4096 MiB e verifica nuovamente i file esistenti.
Questi tentativi riguardano la conservazione; i loro report e adapter
restano nei cataloghi e non qualificano la correttezza del prodotto.
")))
