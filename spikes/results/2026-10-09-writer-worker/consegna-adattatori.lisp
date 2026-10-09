(:SCHEMA-VERSION 1 :KIND :FINAL-INTEGRATION-ADAPTERS :PART 1 :PARTS 1 :SOURCES
 ((:PATH
   #A((135) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-publish-resume.lisp")
   :BYTES 5971 :SHA256 "2a2bdba759a153bacbc841b4484f7de27962b760d4f402cef674028bdb1261bd" :GIT-BLOB
   "26dd5476da1dd570eb8ec99cfbea17cc22e0ad0c" :TEXT
   "(load \"spikes/out/worker-final-integrate-publication.lisp\")
(defun worker-publication-target (leaf)
 (unless (worker-leaf-p leaf) (error \"Non-flat target: ~S\" leaf))
 (merge-pathnames leaf *worker-publication-directory*))
(defun worker-copy-process-resume (record stem)
 (dolist (part '(\"report\" \"conservazione\"))
  (worker-copy-evidence-resume
   (format nil \"spikes/out/~A/~A.lisp\" record part)
   (worker-publication-target
    (format nil \"~A~A.lisp\" stem (if (string= part \"report\") \"\" \"-conservazione\"))))))

(worker-copy-process-resume \"4000550386-command-90070-0\" \"check-consegna-processo\")
(worker-copy-process-resume \"4000550586-command-9874-0\" \"consegna-summary-fallito-processo\")
(worker-copy-process-resume \"4000550696-command-14941-0\" \"consegna-summary-processo\")
(worker-copy-process-resume \"4000550907-command-25363-0\" \"consegna-c1-reader-processo\")
(worker-copy-process-resume \"4000550739-command-16126-0\" \"consegna-c1-reader-fallito-1-processo\")
(worker-copy-process-resume \"4000550806-command-19882-0\" \"consegna-c1-reader-fallito-2-processo\")
(worker-copy-process-resume \"4000550861-command-22217-0\" \"consegna-c1-reader-fallito-3-processo\")
(worker-copy-process-resume \"4000551045-command-31231-0\" \"consegna-pubblicazione-fallita-processo\")
(worker-copy-external-process \"/Users/gpicchiarelli/Documents/ArcDocDB\" \"4000550278-command-82709-0\" \"consegna-preparazione-processo\")
(worker-copy-evidence \"spikes/out/worker-final-integration-summary-data.lisp\" (worker-publication-target \"consegna-summary-dati.lisp\"))
(worker-copy-evidence \"spikes/out/worker-c1-final-integration-addendum.lisp\" (worker-publication-target \"consegna-c1-addendum.lisp\"))
(worker-conserve-final-master \"4000550501-check-1579-0\")
(let ((plans (worker-plan-source-bundles '(\"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-publish-resume.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integrate-publication.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-publish.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-v3-copy-receipt.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-precommit-evidence.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-owned-comparison.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-v2.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-manifest.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-2-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-3-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-2-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-3-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-1-diagnostic.txt\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stderr.log\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stdout.log\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-final-copy-receipt.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-publication-attach-own.lisp\") \"consegna-adattatori\" :final-integration-adapters))) (dolist (plan plans) (worker-save-data (getf plan :data) (worker-publication-target (getf plan :leaf)))))
(sb-ext:gc :full t)
(worker-refresh-final-main-catalog)
(format t \"FINAL QUALIFIED E07 DELIVERY CONSERVED; all attempts and original bytes retained.~%\")
")
  (:PATH
   #A((142) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integrate-publication.lisp")
   :BYTES 1349 :SHA256 "ddc03ac8c465d831bf491a1113f9c70805737534f90ba97b77a6b7b9ee7c30bc" :GIT-BLOB
   "d4cb8730b451e6f5f9b3f6ad2080b272efcfffb8" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(defparameter *worker-final-spike-directory*
 #p\"spikes/results/2026-10-09-writer-worker-final-integration/\")
(defun worker-conserve-final-master (record)
 (let ((*worker-publication-directory* *worker-final-spike-directory*))
  (ensure-directories-exist (worker-publication-target \"catalogo.lisp\"))
  (dolist (part '(\"report\" \"conservazione\"))
   (worker-copy-evidence
    (format nil \"spikes/out/~A/~A.lisp\" record part)
    (worker-publication-target
     (format nil \"spikes-finali~A.lisp\" (if (string= part \"report\") \"\" \"-conservazione\")))))
  (worker-refresh-catalog \"e07d77271758f3134b1977caf394fe38532b54ed\"
   :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"))))
(defun worker-copy-external-process (root record stem)
 (dolist (part '(\"report\" \"conservazione\"))
  (worker-copy-evidence
   (format nil \"~A/spikes/out/~A/~A.lisp\" root record part)
   (worker-publication-target
    (format nil \"~A~A.lisp\" stem (if (string= part \"report\") \"\" \"-conservazione\"))))))
(defun worker-refresh-final-main-catalog ()
 (worker-refresh-catalog \"e07d77271758f3134b1977caf394fe38532b54ed\"
  :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                     \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\")))
")
  (:PATH
   #A((128) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-publish.lisp")
   :BYTES 5229 :SHA256 "7569b8d77c933d6eeb18397575f6e8368aefbeba8ddc81d14e682d2ae780e642" :GIT-BLOB
   "29738e41c73a80de0ccfdccd9bc85f38fa6291a9" :TEXT
   "(load \"spikes/out/worker-final-integrate-publication.lisp\")
(worker-copy-process \"4000550386-command-90070-0\" \"check-consegna-processo\")
(worker-copy-process \"4000550586-command-9874-0\" \"consegna-summary-fallito-processo\")
(worker-copy-process \"4000550696-command-14941-0\" \"consegna-summary-processo\")
(worker-copy-process \"4000550907-command-25363-0\" \"consegna-c1-reader-processo\")
(worker-copy-process \"4000550739-command-16126-0\" \"consegna-c1-reader-fallito-1-processo\")
(worker-copy-process \"4000550806-command-19882-0\" \"consegna-c1-reader-fallito-2-processo\")
(worker-copy-process \"4000550861-command-22217-0\" \"consegna-c1-reader-fallito-3-processo\")
(worker-copy-external-process \"/Users/gpicchiarelli/Documents/ArcDocDB\" \"4000550278-command-82709-0\" \"consegna-preparazione-processo\")
(worker-copy-evidence \"spikes/out/worker-final-integration-summary-data.lisp\" (worker-publication-target \"consegna-summary-dati.lisp\"))
(worker-copy-evidence \"spikes/out/worker-c1-final-integration-addendum.lisp\" (worker-publication-target \"consegna-c1-addendum.lisp\"))
(worker-conserve-final-master \"4000550501-check-1579-0\")
(let ((plans (worker-plan-source-bundles '(\"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integrate-publication.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-publish.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-v3-copy-receipt.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-precommit-evidence.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-owned-comparison.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-v2.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-manifest.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-2-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-3-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-failed.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum.lisp\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-2-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-3-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-failed.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit.py\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-1-diagnostic.txt\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stderr.log\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stdout.log\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-final-copy-receipt.json\" \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-publication-attach-own.lisp\") \"consegna-adattatori\" :final-integration-adapters))) (dolist (plan plans) (worker-save-data (getf plan :data) (worker-publication-target (getf plan :leaf)))))
(sb-ext:gc :full t)
(worker-refresh-final-main-catalog)
(format t \"FINAL QUALIFIED E07 DELIVERY CONSERVED; all attempts and original bytes retained.~%\")
")
  (:PATH
   #A((142) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.py")
   :BYTES 6425 :SHA256 "3649eddedd62516aadbadc7cf7718228b06092f73a1ec6f994fdb0ed2db06ffc" :GIT-BLOB
   "3173ff7e159f52d7354e24d7947f5814280125fd" :TEXT "from pathlib import Path
import subprocess, json, hashlib, tempfile, shutil, os
PRIMARY=Path('/Users/gpicchiarelli/Documents/ArcDocDB')
WT=Path('/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB')
V1=Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6')
V2=Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc')
BASE='cf6091367853ec311fed7b05961a2812fd05a8f1'
UPSTREAM='e07d77271758f3134b1977caf394fe38532b54ed'
OWNED=json.loads(Path('/tmp/arcdocdb-worker-state.json').read_text())['owned_files']
MERGE=['arcdocdb.asd','docs/implementazione/README.md']
STATE=Path('/tmp/arcdocdb-worker-final-integration-state.json')
assert not STATE.exists(), STATE

def cmd(args,cwd=PRIMARY,check=True):
 p=subprocess.run(args,cwd=cwd,capture_output=True)
 if check: assert p.returncode==0,(args,p.returncode,p.stderr.decode())
 return p

def blob(data):return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()}
def file_record(p):return {'path':str(p),**blob(p.read_bytes())}
def save_new(p,data):
 with p.open('xb') as f:f.write(data)

primary_before=cmd(['git','status','--porcelain']).stdout
assert not primary_before, primary_before
assert cmd(['git','rev-parse','HEAD']).stdout.decode().strip()==UPSTREAM
v3=Path(tempfile.mkdtemp(prefix='arcdocdb-worker-final-integration-'));v3.rmdir()
receipt={'schema_version':1,'kind':'worker-final-integration-preparation','primary':str(PRIMARY),'source':str(WT),'v1':str(V1),'v2':str(V2),'v3':str(v3),'baseline':BASE,'upstream':UPSTREAM,'owned_files':OWNED,'merges':[],'copies':[],'identity':[],'commands':[],'status':'preparing'}
STATE.write_text(json.dumps({'final_integration':str(v3),'upstream':UPSTREAM,'baseline':BASE,'status':'preparing'},indent=2)+'\\n')
print('V3-PATH',v3,flush=True)
for args,cwd in [(['git','clone','--no-hardlinks',str(PRIMARY),str(v3)],PRIMARY),(['git','checkout','--detach',UPSTREAM],v3)]:
 p=cmd(args,cwd);receipt['commands'].append({'argv':args,'cwd':str(cwd),'exit_code':p.returncode,'stdout':p.stdout.decode(),'stderr':p.stderr.decode()})
out=v3/'spikes/out';out.mkdir(parents=True,exist_ok=True)
merge_dir=out/'worker-final-integration-merge-inputs';merge_dir.mkdir()
for rel in OWNED:
 source=WT/rel; before=file_record(source);data=source.read_bytes();assert before==file_record(source)
 target=v3/rel;upstream_bytes=target.read_bytes() if target.exists() else None
 if rel in MERGE:
  folder=merge_dir/('asd' if rel=='arcdocdb.asd' else 'readme');folder.mkdir()
  ours,base,theirs=folder/'ours',folder/'base',folder/'theirs'
  save_new(ours,data);save_new(base,cmd(['git','show',BASE+':'+rel]).stdout);save_new(theirs,cmd(['git','show',UPSTREAM+':'+rel]).stdout)
  assert upstream_bytes==theirs.read_bytes()
  args=['git','merge-file','-p',str(ours),str(base),str(theirs)]
  p=cmd(args,v3);data=p.stdout
  receipt['merges'].append({'file':rel,'argv':args,'exit_code':p.returncode,'stdout':p.stdout.decode(),'stderr':p.stderr.decode(),'ours':file_record(ours),'base':file_record(base),'theirs':file_record(theirs),'result':blob(data)})
 target.parent.mkdir(parents=True,exist_ok=True)
 if upstream_bytes is None:save_new(target,data)
 else:
  assert target.read_bytes()==upstream_bytes
  with target.open('wb') as f:f.write(data)
 assert target.read_bytes()==data
 receipt['copies'].append({'file':rel,'source_before':before,'source_after':file_record(source),'upstream':blob(upstream_bytes) if upstream_bytes is not None else None,'target':file_record(target),'three_way_merge':rel in MERGE})
paths=sorted(p.relative_to(WT).as_posix() for p in (WT/'src/execution').glob('*.lisp'))+sorted(p.relative_to(WT).as_posix() for p in (WT/'tests/execution').glob('*.lisp'))+['tools/writer-worker-bench.lisp','tools/writer-worker-mutation.lisp']
assert len(paths)==20, paths
for rel in paths:
 records=[file_record(root/rel) for root in [WT,V1,V2,v3]]
 assert len({(r['bytes'],r['sha256']) for r in records})==1,(rel,records)
 receipt['identity'].append({'file':rel,'equal':True,'records':records})
for rel in MERGE:
 assert (WT/rel).read_bytes()==(V1/rel).read_bytes(),rel
 old_expected=next(m for m in json.loads((V2/'spikes/out/worker-integration-preparation.json').read_text())['merges'] if m['file']==rel)['stdout'].encode()
 assert (V2/rel).read_bytes()==old_expected,rel
receipt['prior_integration_asd_readme_match_saved_three_way_merge']=True
upstream_changed=cmd(['git','diff','--name-status',BASE,UPSTREAM,'--','src/execution','tests/execution']).stdout
assert not upstream_changed,upstream_changed
receipt['execution_baseline_unchanged_cf609_to_e07']=True
changed=cmd(['git','diff','--name-status','e2f7a75f3c7a45dffd91343b91d3a889fc3ee056',UPSTREAM,'--','src','tests','tools','arcdocdb.asd','docs']).stdout.decode()
receipt['e2f_to_e07_non_evidence_changes']=changed
assert cmd(['git','status','--porcelain']).stdout==primary_before
assert cmd(['git','rev-parse','HEAD']).stdout.decode().strip()==UPSTREAM
receipt['primary_clean_unchanged']=True
receipt['source_head']=cmd(['git','rev-parse','HEAD'],WT).stdout.decode().strip()
receipt['source_status']=cmd(['git','status','--porcelain'],WT).stdout.decode()
receipt['v3_head']=cmd(['git','rev-parse','HEAD'],v3).stdout.decode().strip()
receipt['status']='prepared'
receipt['checks_run']='none; root will copy canonical evidence and authorize one full make check'
adapter_copy=out/'worker-final-integration-preparation.py';save_new(adapter_copy,Path(__file__).read_bytes())
receipt['adapter']=file_record(adapter_copy)
receipt_path=out/'worker-final-integration-preparation.json';save_new(receipt_path,(json.dumps(receipt,indent=2)+'\\n').encode())
STATE.write_text(json.dumps({'final_integration':str(v3),'upstream':UPSTREAM,'baseline':BASE,'status':'prepared','preparation_receipt':str(receipt_path),'preparation_sha256':hashlib.sha256(receipt_path.read_bytes()).hexdigest(),'adapter':str(adapter_copy),'owned_files':OWNED,'identity_count':20,'execution_baseline_unchanged':True,'primary_clean_unchanged':True,'check_process':None,'canonical_evidence_pending':True,'final_editorial_doc_pending':True},indent=2)+'\\n')
print('FINAL-INTEGRATION-PREPARATION-PASS 16 owned files, 2 clean three-way merges, 20 WT/v1/v2/v3 byte identities; execution baseline unchanged; primary clean. No check run.',flush=True)
print('RECEIPT',receipt_path,'SHA256',hashlib.sha256(receipt_path.read_bytes()).hexdigest(),flush=True)
")
  (:PATH
   #A((144) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.json")
   :BYTES 56662 :SHA256 "fb334af1b40f16290d9bda5c3ff99597f511e18e0f7bebc7a7a27dd394623ffa"
   :GIT-BLOB "6ac73a9b9214c8f61cd61813a716dabfb4812090" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"worker-final-integration-preparation\",
  \"primary\": \"/Users/gpicchiarelli/Documents/ArcDocDB\",
  \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB\",
  \"v1\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6\",
  \"v2\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc\",
  \"v3\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn\",
  \"baseline\": \"cf6091367853ec311fed7b05961a2812fd05a8f1\",
  \"upstream\": \"e07d77271758f3134b1977caf394fe38532b54ed\",
  \"owned_files\": [
    \"arcdocdb.asd\",
    \"src/execution/package.lisp\",
    \"src/execution/worker-types.lisp\",
    \"src/execution/worker-boundary.lisp\",
    \"src/execution/worker-claim.lisp\",
    \"src/execution/worker-run.lisp\",
    \"tests/execution/worker.lisp\",
    \"tools/writer-worker-bench.lisp\",
    \"tools/writer-worker-mutation.lisp\",
    \"docs/implementazione/writer-worker-metodo.md\",
    \"docs/implementazione/writer-worker.md\",
    \"docs/implementazione/writer-worker-decisioni.md\",
    \"docs/implementazione/writer-worker-risultati.md\",
    \"docs/implementazione/writer-worker-revisione.md\",
    \"docs/implementazione/README.md\",
    \"docs/affidabilita/copertura-eccezioni.md\"
  ],
  \"merges\": [
    {
      \"file\": \"arcdocdb.asd\",
      \"argv\": [
        \"git\",
        \"merge-file\",
        \"-p\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/ours\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/base\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/theirs\"
      ],
      \"exit_code\": 0,
      \"stdout\": \";;;; arcdocdb.asd \\u2014 definizione di sistema ASDF.\\n;;;;\\n;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.\\n\\n(in-package #:asdf-user)\\n\\n(defsystem \\\"arcdocdb\\\"\\n  :description \\\"Database server documentale general-purpose, append-only, in Common Lisp (SBCL).\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :version \\\"0.0.0\\\"\\n  :pathname \\\"src/\\\"\\n  :serial t\\n  :depends-on (\\\"sb-posix\\\")\\n  :components ((:file \\\"package\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"conditions\\\")\\n                             (:file \\\"binary\\\") (:file \\\"crc32c\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"utf8\\\")\\n                             (:file \\\"cbor-package\\\") (:file \\\"cbor-header\\\")\\n                             (:file \\\"cbor-float-minimal\\\") (:file \\\"cbor-minimal\\\")\\n                             (:file \\\"cbor-space\\\") (:file \\\"cbor-scan-input\\\")\\n                             (:file \\\"cbor-scan-stack\\\") (:file \\\"cbor-scan-items\\\")\\n                             (:file \\\"cbor-scan\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"registry\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"queue\\\") (:file \\\"writer\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready-types\\\") (:file \\\"ready\\\")\\n                             (:file \\\"ready-recycle\\\")\\n                             (:file \\\"worker-types\\\") (:file \\\"worker-boundary\\\") (:file \\\"worker-claim\\\") (:file \\\"worker-run\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"formats\\\") (:file \\\"segment-header\\\")\\n                             (:file \\\"log-header\\\") (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\") (:file \\\"payload-record\\\")\\n                             (:file \\\"payload-write\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"native\\\")\\n                             (:file \\\"lifecycle\\\") (:file \\\"transfer\\\") (:file \\\"flush\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"types\\\") (:file \\\"builder\\\")\\n                             (:file \\\"group\\\") (:file \\\"executor\\\") (:file \\\"csn\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"package\\\") (:file \\\"scan\\\")\\n                             (:file \\\"decisions-package\\\") (:file \\\"decisions-types\\\")\\n                             (:file \\\"decisions-sort\\\") (:file \\\"decisions-radix\\\") (:file \\\"decisions-build\\\")\\n                             (:file \\\"decisions-query\\\")\\n                             (:file \\\"manifest-package\\\") (:file \\\"manifest-types\\\")\\n                             (:file \\\"manifest-decode\\\") (:file \\\"manifest-fold\\\")\\n                             (:file \\\"manifest-build\\\") (:file \\\"manifest-query\\\")\\n                             (:file \\\"inventory-types\\\") (:file \\\"inventory-build\\\")\\n                             (:file \\\"inventory-query\\\"))))\\n  :in-order-to ((test-op (test-op \\\"arcdocdb/tests\\\"))))\\n\\n(defsystem \\\"arcdocdb/tests\\\"\\n  :description \\\"Test di ArcDocDB.\\\"\\n  :author \\\"Giacomo Picchiarelli\\\"\\n  :license \\\"BSD-2-Clause\\\"\\n  :depends-on (\\\"arcdocdb\\\")\\n  :pathname \\\"tests/\\\"\\n  :serial t\\n  :components ((:file \\\"smoke\\\")\\n               (:module \\\"foundation\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"binary\\\")\\n                             (:file \\\"record\\\") (:file \\\"batch\\\")))\\n               (:module \\\"codec\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"utf8\\\") (:file \\\"threads\\\")\\n                             (:file \\\"cbor-support\\\") (:file \\\"cbor-header\\\") (:file \\\"cbor-threads\\\")\\n                             (:file \\\"cbor-minimal-support\\\") (:file \\\"cbor-minimal\\\")\\n                             (:file \\\"cbor-minimal-threads\\\") (:file \\\"cbor-minimal-edges\\\")\\n                             (:file \\\"cbor-structure-support\\\") (:file \\\"cbor-structure\\\")\\n                             (:file \\\"cbor-structure-threads\\\")))\\n               (:module \\\"csn\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"registry\\\") (:file \\\"threads\\\")))\\n               (:module \\\"execution\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"queue\\\") (:file \\\"threads\\\")\\n                             (:file \\\"handoff\\\") (:file \\\"ready\\\") (:file \\\"ready-recycle\\\") (:file \\\"worker\\\")))\\n               (:module \\\"storage\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"segment-header\\\") (:file \\\"log-header\\\")\\n                             (:file \\\"compaction-scan\\\")\\n                             (:file \\\"control-payload\\\")))\\n               (:module \\\"io\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"transfer\\\") (:file \\\"native\\\")))\\n               (:module \\\"recovery\\\"\\n                :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"scan\\\") (:file \\\"corruption\\\")\\n                             (:file \\\"decisions-support\\\") (:file \\\"decisions\\\")\\n                             (:file \\\"decisions-audit\\\") (:file \\\"decisions-radix\\\") (:file \\\"manifest-support\\\")\\n                             (:file \\\"manifest\\\") (:file \\\"manifest-audit\\\")\\n                             (:file \\\"inventory-support\\\") (:file \\\"inventory\\\")))\\n               (:module \\\"wal\\\" :serial t\\n                :components ((:file \\\"support\\\") (:file \\\"builder\\\") (:file \\\"group\\\") (:file \\\"fault\\\")\\n                             (:file \\\"native\\\") (:file \\\"csn\\\") (:file \\\"csn-threads\\\"))))\\n  :perform (test-op (o c)\\n             (uiop:symbol-call '#:arcdocdb.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.minimal.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.cbor.structure.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)\\n             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))\\n\",
      \"stderr\": \"\",
      \"ours\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/ours\",
        \"bytes\": 5891,
        \"sha256\": \"bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153\"
      },
      \"base\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/base\",
        \"bytes\": 5752,
        \"sha256\": \"1f194a585165cf8aef43779b6f9e14cf5431550014884381b2b668f6b6b7aea5\"
      },
      \"theirs\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/asd/theirs\",
        \"bytes\": 6288,
        \"sha256\": \"e3e0f7fed35483608da8a9b36ac8306004fd94d39e2293d6eaa5700590c3046e\"
      },
      \"result\": {
        \"bytes\": 6427,
        \"sha256\": \"2a164afdd524e601320b8094e5d25aeb5c3dba081da8157f5849802cd9d28185\"
      }
    },
    {
      \"file\": \"docs/implementazione/README.md\",
      \"argv\": [
        \"git\",
        \"merge-file\",
        \"-p\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/ours\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/base\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/theirs\"
      ],
      \"exit_code\": 0,
      \"stdout\": \"# Implementazione\\n\\nFondazioni introdotte dopo la richiesta dell'autore del 2026-10-08 di iniziare la scrittura\\ndel codice. L'autorizzazione non equivale alla chiusura dei criteri della Fase 0 o alla\\nqualifica del motore completo.\\n\\n| Modulo | Contratto e verifica | Codice |\\n|---|---|---|\\n| Fondazioni binarie | [Record v1/v2, CRC32C e lotti SEAL](fondazioni-binarie.md) | [`src/foundation/`](../../src/foundation/) |\\n| Testo UTF-8 | [Validazione limitata, pura e parallela](utf8.md) | [`src/codec/utf8.lisp`](../../src/codec/utf8.lisp) |\\n| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |\\n| Testate CBOR minime | [Larghezze di argomenti e float, senza decodifica](cbor-minimo.md) | [`src/codec/cbor-minimal.lisp`](../../src/codec/cbor-minimal.lisp) |\\n| Struttura CBOR | [Item completo, UTF-8 e budget con scratch per worker](cbor-struttura.md) | [`src/codec/cbor-scan.lisp`](../../src/codec/cbor-scan.lisp) |\\n| CSN di Archivio | [Registro dei commit in corso e orizzonte](csn.md) | [`src/csn/`](../../src/csn/) |\\n| Metadati storage | [Header dei segmenti, EDIT e DECISION](metadati-storage.md) | [`src/storage/`](../../src/storage/) |\\n| Header dei log | [Identit\\u00e0 e integrit\\u00e0 di control e multiserie](header-log.md) | [`src/storage/log-header.lisp`](../../src/storage/log-header.lisp) |\\n| Segmenti compattati | [Prefisso CLOSED e record ordinari](segmenti-compattati.md) | [`src/storage/compaction-scan.lisp`](../../src/storage/compaction-scan.lisp) |\\n| Code dei writer | [MPSC locale, gettone e tratti limitati](code-writer.md) | [`src/execution/`](../../src/execution/) |\\n| Consegna dei writer | [Idle, pronto, in esecuzione e obbligo di scheduling](writer-handoff.md) | [`src/execution/handoff.lisp`](../../src/execution/handoff.lisp) |\\n| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |\\n| Ricircolo dei writer pronti | [Scambio FIFO atomico a ring pieno](writer-recycle.md) | [`src/execution/ready-recycle.lisp`](../../src/execution/ready-recycle.lisp) |\\n| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n| Confine I/O | [Append, pread e flush durevole](io.md) | [`src/io/`](../../src/io/) |\\n| Lotti WAL | [Formazione, SEAL e group commit](wal.md) | [`src/wal/`](../../src/wal/) |\\n| CSN dei lotti WAL | [Chiusura, token e risoluzione](wal-csn.md) | [`src/wal/csn.lisp`](../../src/wal/csn.lisp) |\\n| Scansione recovery | [Prefisso dei log e testimonianze SEAL](scansione-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Decisioni multiserie | [Tabella TXID, CSN e partecipanti](decisioni-multiserie.md) | [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) |\\n| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |\\n| Inventario recovery | [Piano di riconciliazione dei nomi dei segmenti](inventario.md) | [`src/recovery/inventory-build.lisp`](../../src/recovery/inventory-build.lisp) |\\n| Ordinamento delle decisioni | [Radix misurato e query concorrenti](decisioni-radix-risultati.md) | [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) |\\n\\nLe evidenze hanno un ambito esplicito: un test del codec non verifica transazioni,\\ndurability, recovery o prestazioni del database.\\n\",
      \"stderr\": \"\",
      \"ours\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/ours\",
        \"bytes\": 3201,
        \"sha256\": \"e5fa537d4e6b15662597fbdff94b54407cc466a8d28bdab31511ccc2709a01f7\"
      },
      \"base\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/base\",
        \"bytes\": 3036,
        \"sha256\": \"ca349da2b7d546a1959db6704b4cd8554c07491a9e567823093a84011a04d4ef\"
      },
      \"theirs\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-merge-inputs/readme/theirs\",
        \"bytes\": 3369,
        \"sha256\": \"aa0b64d890a414d5aae2fdd06d609fad9adf004978db769a8763920300f19d53\"
      },
      \"result\": {
        \"bytes\": 3534,
        \"sha256\": \"cfde5ccb1980c15f27f13e0f81db9a574168505cee411c4d93a213d55285eb77\"
      }
    }
  ],
  \"copies\": [
    {
      \"file\": \"arcdocdb.asd\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/arcdocdb.asd\",
        \"bytes\": 5891,
        \"sha256\": \"bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/arcdocdb.asd\",
        \"bytes\": 5891,
        \"sha256\": \"bbc7260fe3d7b63d32c6b5ee05aa7f6ffed42274cf62812e652642a4a7439153\"
      },
      \"upstream\": {
        \"bytes\": 6288,
        \"sha256\": \"e3e0f7fed35483608da8a9b36ac8306004fd94d39e2293d6eaa5700590c3046e\"
      },
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/arcdocdb.asd\",
        \"bytes\": 6427,
        \"sha256\": \"2a164afdd524e601320b8094e5d25aeb5c3dba081da8157f5849802cd9d28185\"
      },
      \"three_way_merge\": true
    },
    {
      \"file\": \"src/execution/package.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/package.lisp\",
        \"bytes\": 1157,
        \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/package.lisp\",
        \"bytes\": 1157,
        \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
      },
      \"upstream\": {
        \"bytes\": 797,
        \"sha256\": \"86c371c1d18b2cfb2972d7a3d9959a33e34debe68839e6025d1188f1d5df58bb\"
      },
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/package.lisp\",
        \"bytes\": 1157,
        \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"src/execution/worker-types.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-types.lisp\",
        \"bytes\": 8461,
        \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-types.lisp\",
        \"bytes\": 8461,
        \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-types.lisp\",
        \"bytes\": 8461,
        \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"src/execution/worker-boundary.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-boundary.lisp\",
        \"bytes\": 2309,
        \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-boundary.lisp\",
        \"bytes\": 2309,
        \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-boundary.lisp\",
        \"bytes\": 2309,
        \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"src/execution/worker-claim.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-claim.lisp\",
        \"bytes\": 6401,
        \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-claim.lisp\",
        \"bytes\": 6401,
        \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-claim.lisp\",
        \"bytes\": 6401,
        \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"src/execution/worker-run.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-run.lisp\",
        \"bytes\": 5125,
        \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-run.lisp\",
        \"bytes\": 5125,
        \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-run.lisp\",
        \"bytes\": 5125,
        \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"tests/execution/worker.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/worker.lisp\",
        \"bytes\": 59783,
        \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/worker.lisp\",
        \"bytes\": 59783,
        \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/worker.lisp\",
        \"bytes\": 59783,
        \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"tools/writer-worker-bench.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-bench.lisp\",
        \"bytes\": 26228,
        \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-bench.lisp\",
        \"bytes\": 26228,
        \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tools/writer-worker-bench.lisp\",
        \"bytes\": 26228,
        \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"tools/writer-worker-mutation.lisp\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-mutation.lisp\",
        \"bytes\": 27110,
        \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-mutation.lisp\",
        \"bytes\": 27110,
        \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tools/writer-worker-mutation.lisp\",
        \"bytes\": 27110,
        \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/writer-worker-metodo.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md\",
        \"bytes\": 7583,
        \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md\",
        \"bytes\": 7583,
        \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-metodo.md\",
        \"bytes\": 7583,
        \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/writer-worker.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md\",
        \"bytes\": 5461,
        \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md\",
        \"bytes\": 5461,
        \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker.md\",
        \"bytes\": 5461,
        \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/writer-worker-decisioni.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md\",
        \"bytes\": 32528,
        \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md\",
        \"bytes\": 32528,
        \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-decisioni.md\",
        \"bytes\": 32528,
        \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/writer-worker-risultati.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md\",
        \"bytes\": 8299,
        \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md\",
        \"bytes\": 8299,
        \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-risultati.md\",
        \"bytes\": 8299,
        \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/writer-worker-revisione.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md\",
        \"bytes\": 4661,
        \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md\",
        \"bytes\": 4661,
        \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
      },
      \"upstream\": null,
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-revisione.md\",
        \"bytes\": 4661,
        \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
      },
      \"three_way_merge\": false
    },
    {
      \"file\": \"docs/implementazione/README.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/README.md\",
        \"bytes\": 3201,
        \"sha256\": \"e5fa537d4e6b15662597fbdff94b54407cc466a8d28bdab31511ccc2709a01f7\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/README.md\",
        \"bytes\": 3201,
        \"sha256\": \"e5fa537d4e6b15662597fbdff94b54407cc466a8d28bdab31511ccc2709a01f7\"
      },
      \"upstream\": {
        \"bytes\": 3369,
        \"sha256\": \"aa0b64d890a414d5aae2fdd06d609fad9adf004978db769a8763920300f19d53\"
      },
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/README.md\",
        \"bytes\": 3534,
        \"sha256\": \"cfde5ccb1980c15f27f13e0f81db9a574168505cee411c4d93a213d55285eb77\"
      },
      \"three_way_merge\": true
    },
    {
      \"file\": \"docs/affidabilita/copertura-eccezioni.md\",
      \"source_before\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md\",
        \"bytes\": 19300,
        \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
      },
      \"source_after\": {
        \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md\",
        \"bytes\": 19300,
        \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
      },
      \"upstream\": {
        \"bytes\": 18550,
        \"sha256\": \"2795f5f57edb2c0806885f249d5b4e7ca7e6f87d905497488078fc1aaf445a76\"
      },
      \"target\": {
        \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/affidabilita/copertura-eccezioni.md\",
        \"bytes\": 19300,
        \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
      },
      \"three_way_merge\": false
    }
  ],
  \"identity\": [
    {
      \"file\": \"src/execution/handoff.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/handoff.lisp\",
          \"bytes\": 7394,
          \"sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/handoff.lisp\",
          \"bytes\": 7394,
          \"sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/handoff.lisp\",
          \"bytes\": 7394,
          \"sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/handoff.lisp\",
          \"bytes\": 7394,
          \"sha256\": \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
        }
      ]
    },
    {
      \"file\": \"src/execution/package.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/package.lisp\",
          \"bytes\": 1157,
          \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/package.lisp\",
          \"bytes\": 1157,
          \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/package.lisp\",
          \"bytes\": 1157,
          \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/package.lisp\",
          \"bytes\": 1157,
          \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
        }
      ]
    },
    {
      \"file\": \"src/execution/queue.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/queue.lisp\",
          \"bytes\": 5374,
          \"sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/queue.lisp\",
          \"bytes\": 5374,
          \"sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/queue.lisp\",
          \"bytes\": 5374,
          \"sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/queue.lisp\",
          \"bytes\": 5374,
          \"sha256\": \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
        }
      ]
    },
    {
      \"file\": \"src/execution/ready-recycle.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/ready-recycle.lisp\",
          \"bytes\": 3387,
          \"sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/ready-recycle.lisp\",
          \"bytes\": 3387,
          \"sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/ready-recycle.lisp\",
          \"bytes\": 3387,
          \"sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/ready-recycle.lisp\",
          \"bytes\": 3387,
          \"sha256\": \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
        }
      ]
    },
    {
      \"file\": \"src/execution/ready-types.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/ready-types.lisp\",
          \"bytes\": 5248,
          \"sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/ready-types.lisp\",
          \"bytes\": 5248,
          \"sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/ready-types.lisp\",
          \"bytes\": 5248,
          \"sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/ready-types.lisp\",
          \"bytes\": 5248,
          \"sha256\": \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
        }
      ]
    },
    {
      \"file\": \"src/execution/ready.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/ready.lisp\",
          \"bytes\": 6635,
          \"sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/ready.lisp\",
          \"bytes\": 6635,
          \"sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/ready.lisp\",
          \"bytes\": 6635,
          \"sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/ready.lisp\",
          \"bytes\": 6635,
          \"sha256\": \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
        }
      ]
    },
    {
      \"file\": \"src/execution/worker-boundary.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-boundary.lisp\",
          \"bytes\": 2309,
          \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/worker-boundary.lisp\",
          \"bytes\": 2309,
          \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/worker-boundary.lisp\",
          \"bytes\": 2309,
          \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-boundary.lisp\",
          \"bytes\": 2309,
          \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
        }
      ]
    },
    {
      \"file\": \"src/execution/worker-claim.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-claim.lisp\",
          \"bytes\": 6401,
          \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/worker-claim.lisp\",
          \"bytes\": 6401,
          \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/worker-claim.lisp\",
          \"bytes\": 6401,
          \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-claim.lisp\",
          \"bytes\": 6401,
          \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
        }
      ]
    },
    {
      \"file\": \"src/execution/worker-run.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-run.lisp\",
          \"bytes\": 5125,
          \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/worker-run.lisp\",
          \"bytes\": 5125,
          \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/worker-run.lisp\",
          \"bytes\": 5125,
          \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-run.lisp\",
          \"bytes\": 5125,
          \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
        }
      ]
    },
    {
      \"file\": \"src/execution/worker-types.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/worker-types.lisp\",
          \"bytes\": 8461,
          \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/worker-types.lisp\",
          \"bytes\": 8461,
          \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/worker-types.lisp\",
          \"bytes\": 8461,
          \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-types.lisp\",
          \"bytes\": 8461,
          \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
        }
      ]
    },
    {
      \"file\": \"src/execution/writer.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/src/execution/writer.lisp\",
          \"bytes\": 6484,
          \"sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/src/execution/writer.lisp\",
          \"bytes\": 6484,
          \"sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/src/execution/writer.lisp\",
          \"bytes\": 6484,
          \"sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/writer.lisp\",
          \"bytes\": 6484,
          \"sha256\": \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/handoff.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/handoff.lisp\",
          \"bytes\": 33278,
          \"sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/handoff.lisp\",
          \"bytes\": 33278,
          \"sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/handoff.lisp\",
          \"bytes\": 33278,
          \"sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/handoff.lisp\",
          \"bytes\": 33278,
          \"sha256\": \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/queue.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/queue.lisp\",
          \"bytes\": 12894,
          \"sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/queue.lisp\",
          \"bytes\": 12894,
          \"sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/queue.lisp\",
          \"bytes\": 12894,
          \"sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/queue.lisp\",
          \"bytes\": 12894,
          \"sha256\": \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/ready-recycle.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/ready-recycle.lisp\",
          \"bytes\": 30075,
          \"sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/ready-recycle.lisp\",
          \"bytes\": 30075,
          \"sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/ready-recycle.lisp\",
          \"bytes\": 30075,
          \"sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/ready-recycle.lisp\",
          \"bytes\": 30075,
          \"sha256\": \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/ready.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/ready.lisp\",
          \"bytes\": 33555,
          \"sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/ready.lisp\",
          \"bytes\": 33555,
          \"sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/ready.lisp\",
          \"bytes\": 33555,
          \"sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/ready.lisp\",
          \"bytes\": 33555,
          \"sha256\": \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/support.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/support.lisp\",
          \"bytes\": 4469,
          \"sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/support.lisp\",
          \"bytes\": 4469,
          \"sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/support.lisp\",
          \"bytes\": 4469,
          \"sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/support.lisp\",
          \"bytes\": 4469,
          \"sha256\": \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/threads.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/threads.lisp\",
          \"bytes\": 14622,
          \"sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/threads.lisp\",
          \"bytes\": 14622,
          \"sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/threads.lisp\",
          \"bytes\": 14622,
          \"sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/threads.lisp\",
          \"bytes\": 14622,
          \"sha256\": \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
        }
      ]
    },
    {
      \"file\": \"tests/execution/worker.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tests/execution/worker.lisp\",
          \"bytes\": 59783,
          \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tests/execution/worker.lisp\",
          \"bytes\": 59783,
          \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tests/execution/worker.lisp\",
          \"bytes\": 59783,
          \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tests/execution/worker.lisp\",
          \"bytes\": 59783,
          \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
        }
      ]
    },
    {
      \"file\": \"tools/writer-worker-bench.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-bench.lisp\",
          \"bytes\": 26228,
          \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tools/writer-worker-bench.lisp\",
          \"bytes\": 26228,
          \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tools/writer-worker-bench.lisp\",
          \"bytes\": 26228,
          \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tools/writer-worker-bench.lisp\",
          \"bytes\": 26228,
          \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
        }
      ]
    },
    {
      \"file\": \"tools/writer-worker-mutation.lisp\",
      \"equal\": true,
      \"records\": [
        {
          \"path\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/tools/writer-worker-mutation.lisp\",
          \"bytes\": 27110,
          \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tools/writer-worker-mutation.lisp\",
          \"bytes\": 27110,
          \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tools/writer-worker-mutation.lisp\",
          \"bytes\": 27110,
          \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
        },
        {
          \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tools/writer-worker-mutation.lisp\",
          \"bytes\": 27110,
          \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
        }
      ]
    }
  ],
  \"commands\": [
    {
      \"argv\": [
        \"git\",
        \"clone\",
        \"--no-hardlinks\",
        \"/Users/gpicchiarelli/Documents/ArcDocDB\",
        \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn\"
      ],
      \"cwd\": \"/Users/gpicchiarelli/Documents/ArcDocDB\",
      \"exit_code\": 0,
      \"stdout\": \"\",
      \"stderr\": \"Cloning into '/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn'...\\ndone.\\n\"
    },
    {
      \"argv\": [
        \"git\",
        \"checkout\",
        \"--detach\",
        \"e07d77271758f3134b1977caf394fe38532b54ed\"
      ],
      \"cwd\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn\",
      \"exit_code\": 0,
      \"stdout\": \"\",
      \"stderr\": \"HEAD is now at e07d772 Conserva la verifica integrata e gli audit del codec CBOR\\n\"
    }
  ],
  \"status\": \"prepared\",
  \"prior_integration_asd_readme_match_saved_three_way_merge\": true,
  \"execution_baseline_unchanged_cf609_to_e07\": true,
  \"e2f_to_e07_non_evidence_changes\": \"M\\tarcdocdb.asd\\nM\\tdocs/implementazione/README.md\\nA\\tdocs/implementazione/cbor-minimo-decisioni.md\\nA\\tdocs/implementazione/cbor-minimo-driver-review.md\\nA\\tdocs/implementazione/cbor-minimo-lettura.md\\nA\\tdocs/implementazione/cbor-minimo-metodo.md\\nA\\tdocs/implementazione/cbor-minimo-revisione.md\\nA\\tdocs/implementazione/cbor-minimo-risultati.md\\nA\\tdocs/implementazione/cbor-minimo-strumenti-review.md\\nA\\tdocs/implementazione/cbor-minimo.md\\nA\\tsrc/codec/cbor-float-minimal.lisp\\nA\\tsrc/codec/cbor-minimal.lisp\\nM\\tsrc/codec/cbor-package.lisp\\nA\\ttests/codec/cbor-minimal-edges.lisp\\nA\\ttests/codec/cbor-minimal-support.lisp\\nA\\ttests/codec/cbor-minimal-threads.lisp\\nA\\ttests/codec/cbor-minimal.lisp\\nA\\ttools/cbor-minimal-bench.lisp\\nA\\ttools/cbor-minimal-mutation.lisp\\nM\\ttools/foundation-coverage.lisp\\n\",
  \"primary_clean_unchanged\": true,
  \"source_head\": \"cf6091367853ec311fed7b05961a2812fd05a8f1\",
  \"source_status\": \" M arcdocdb.asd\\n M docs/affidabilita/copertura-eccezioni.md\\n M docs/implementazione/README.md\\n M src/execution/package.lisp\\n?? docs/implementazione/writer-worker-decisioni.md\\n?? docs/implementazione/writer-worker-metodo.md\\n?? docs/implementazione/writer-worker-revisione.md\\n?? docs/implementazione/writer-worker-risultati.md\\n?? docs/implementazione/writer-worker.md\\n?? src/execution/worker-boundary.lisp\\n?? src/execution/worker-claim.lisp\\n?? src/execution/worker-run.lisp\\n?? src/execution/worker-types.lisp\\n?? tests/execution/worker.lisp\\n?? tools/writer-worker-bench.lisp\\n?? tools/writer-worker-mutation.lisp\\n\",
  \"v3_head\": \"e07d77271758f3134b1977caf394fe38532b54ed\",
  \"checks_run\": \"none; root will copy canonical evidence and authorize one full make check\",
  \"adapter\": {
    \"path\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-preparation.py\",
    \"bytes\": 6425,
    \"sha256\": \"3649eddedd62516aadbadc7cf7718228b06092f73a1ec6f994fdb0ed2db06ffc\"
  }
}
")
  (:PATH
   #A((136) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-v3-copy-receipt.json")
   :BYTES 46658 :SHA256 "0d30128b2f5384e2a765c0c6b3894fc22aedbfdec5c0554846a1cdc357b3f92b"
   :GIT-BLOB "3ffe36fdf6e0feea30488de4eaebb6f7cd4cad47" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"verified-final-integration-copy\",
  \"files\": [
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-metodo.md\",
      \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker.md\",
      \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-decisioni.md\",
      \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-risultati.md\",
      \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/implementazione/writer-worker-revisione.md\",
      \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/docs/affidabilita/copertura-eccezioni.md\",
      \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp\",
      \"sha256\": \"4232bc88eeb7cc9f1e72e8cb6ca8ba2696bb0f3fda34770f5f07f752423098a6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/allocazioni-processo-conservazione.lisp\",
      \"sha256\": \"3ebfebe658f973ae850eeba1997c124d8eced4b8ff7f8416a6ae64043586e642\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/allocazioni-processo.lisp\",
      \"sha256\": \"15fc3a6330fb864f5dc7db2c44441dec1a9966d557914632b74180518d463094\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/bench-self-test-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/bench-self-test-processo-conservazione.lisp\",
      \"sha256\": \"a0c37d16217c4e89397c9d37423a0001f80890b4e6e12b472707e35719677375\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/bench-self-test-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/bench-self-test-processo.lisp\",
      \"sha256\": \"ec9d32a97987f2042be25a0e7ab4e68f822ea43da6739af70da4bb5cb3f3e56c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/catalogo.lisp\",
      \"sha256\": \"56574cfbcffb69f61ff7b75e4d6f439342a39361c7ce92ba35e267c2b08e13aa\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-finale-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/check-finale-processo-conservazione.lisp\",
      \"sha256\": \"75110bd290cf658ac52deee29a8b50d15910a85a09088587b30049bf6dfaa2f2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp\",
      \"sha256\": \"171017fb3a43f10b0ea2feef9edb49b099c188a8d54449dfd69ff390b56d09b3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/check-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp\",
      \"sha256\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/chiusura-copia-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/chiusura-copia-adattatori.lisp\",
      \"sha256\": \"443440414aa2f1ef5aff571b4c405276defa0380a51cd49deea9b04e5292a945\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-export-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-export-processo-conservazione.lisp\",
      \"sha256\": \"3b684c3ee1b34972c11115dd87d8d2403449695949a423fc42239d16ac4c356f\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-export-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-export-processo.lisp\",
      \"sha256\": \"914ded890553fe32d461eadedd27a12db494cba057697069346bf75307bcbb9e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-grezza.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-grezza.lisp\",
      \"sha256\": \"787b1ad0604b98c46690dd4655638d7ff7de4d4cf5f71864235fdc4c5244f09b\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-html.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-html.lisp\",
      \"sha256\": \"0f5f772f71838a44c612cd1110a8f956a69488fa2b59cb8b433128e95efc3c49\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-native.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-native.lisp\",
      \"sha256\": \"6556c89d470b443591607229ad043a023d03c8f346258e048fc1a860e8a3a973\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-processo-conservazione.lisp\",
      \"sha256\": \"21ea48fc083f80c4f3a4f3f17d634eb2e1c0115fdbc8d06df9f395e1c9135ce6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/copertura-processo.lisp\",
      \"sha256\": \"af3dfba084cbe52e87a3e1c59bc52daa95c50e021d2bc7a08544bfb64ee51306\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo-conservazione.lisp\",
      \"sha256\": \"34251a0b7c759c97409320374a8d558c8d99bebc630a9bc6213d893a4cd4d290\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo.lisp\",
      \"sha256\": \"1c1efacd5ee4fd3b80be229bb90ad781d3d9761b6fa40481b2182d87f65f14ab\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo-conservazione.lisp\",
      \"sha256\": \"f7e13451481888b732167d82b4a7d2f989bbb3dc9a495b5c993fe43fd1c6de65\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo.lisp\",
      \"sha256\": \"a609160ec3b296beb8a16b4905644912372dc5d05e8ac7dff2bd29cea0d725f6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo-conservazione.lisp\",
      \"sha256\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo.lisp\",
      \"sha256\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp\",
      \"sha256\": \"70fc8171b55f0e717eea23f9bad6033941739d40e715c45051df0d103bff8fd5\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-log.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-log.lisp\",
      \"sha256\": \"855afe77a12531115f864fc3b36d609ae608e5106bc8475f1131b701e173d91c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-processo-conservazione.lisp\",
      \"sha256\": \"74708fdcf432c4c5e3f329c58a4d3f94ab170fd5c85717cb97fceba845f3f6a5\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-processo.lisp\",
      \"sha256\": \"4aaa70d59881a6be3289a642bb7fbd9d7c3764b69c24807e7ff2c7133980a5b2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo-conservazione.lisp\",
      \"sha256\": \"e9e1c34b2ec99f350e3b505257d53b62b5675ccbac94114e2cb3282e5f758d54\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo.lisp\",
      \"sha256\": \"70ff3ff6ba4ba4d06772d66586c900297725ebf102c6ce1b71fa34c1fb68502a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/probe-root-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/probe-root-processo-conservazione.lisp\",
      \"sha256\": \"fc39b4e3a1384e449b472e2f43b4dbf1f2edd50abb3f8b704f19b9c42d0cd98e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/probe-root-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/probe-root-processo.lisp\",
      \"sha256\": \"c58a825e04c175e4f73215ea55d972b3301e86d88ca73f66c81d111ff20ef5d2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-adattatori.lisp\",
      \"sha256\": \"f1895fcbeda3e687c47296bde314583a88f5cb2f8f9dadc2f946bb9aed7321a1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo-conservazione.lisp\",
      \"sha256\": \"876221f31ebd21e0054304106ba012b121e82f685e6614f474473faa3b3944e3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo.lisp\",
      \"sha256\": \"c90cdc6d99e6af765b517e7b4944bf6eb6719e6cea5cb7de81b929262d7fe6aa\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo-conservazione.lisp\",
      \"sha256\": \"413e9c390289e5741ffdab6fe37f32102fe5671471ac9955756687fd2a76539d\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo.lisp\",
      \"sha256\": \"07c0940cefd02b9efad91db323a6236c83e580b37c48c0ec2ed573567d0593c9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo-conservazione.lisp\",
      \"sha256\": \"1b6df4d427a5677d6e189d996d3cdd525db0c5d6fb8924c1e307186925bf41af\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo.lisp\",
      \"sha256\": \"be18d788d301be3a946461ed58d60e02f6bc96b570f18d6aeb73878953eed0ba\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-dati.lisp\",
      \"sha256\": \"37cd88ea5c80df5a2fba6e2142fcce971f8168ec0d0f8c97864929eaf92c4354\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo-conservazione.lisp\",
      \"sha256\": \"b5e29180721602708cad16c95c734d85a2aaad033557ef9f725be3f005a05ad3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo.lisp\",
      \"sha256\": \"aeed0ef5c8c2ce6664bb0a6dc264c33b7f09ab765246152df52b65f849c6a905\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo-conservazione.lisp\",
      \"sha256\": \"52576b5d72b100679eeb7a5d6efeb44e5f4b8da16947ee6477d0e07691d95496\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo.lisp\",
      \"sha256\": \"ea1d081db0e8a93c8d6a651f18b7a8f83c452fca1b1e64d28cb96e06e1e92fc8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo-conservazione.lisp\",
      \"sha256\": \"4b9dd954673af056b7cd98ecedcadd3851310775cd83113b3f9c2f29dfeb0c5c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo.lisp\",
      \"sha256\": \"5f5e2439bdae533ca3d24e6a5f4c59a66b1b630aca4ad6bd5c781f17ff456366\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo-conservazione.lisp\",
      \"sha256\": \"ac8d88a1b9c02e4f223d64991b16308e4aa60ec0793a905b1307faeccaa76f99\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo.lisp\",
      \"sha256\": \"c05ffe3e4724ac39908ad1b107bc2384e439ffc4822781765e60704c3c32a42a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-tentativo-non-registrato.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-tentativo-non-registrato.lisp\",
      \"sha256\": \"5f029a76a814cc6f03819376e260b6774c659502dbe0370194d769987b64e4c0\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo-conservazione.lisp\",
      \"sha256\": \"a8823abc6d3a690b517f815b3d15136ffdef2e677ea049658206ee94b7439556\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo.lisp\",
      \"sha256\": \"36e47daedd1744fe6eea0a9bb4f8a1b8e633124dcb4c16efc900c2630938fa32\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo-conservazione.lisp\",
      \"sha256\": \"9e1286ac4e613f095e7f8df804853fb745600736e2a1659e0b273e37fd0a2df9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo.lisp\",
      \"sha256\": \"6a273caa381d83107588a05b1850629a3406112aa29652b2248a428d116cbe7a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/report.lisp.gz\",
      \"sha256\": \"aaba2220d5294a6e0cd801d5febfd87ca78befaf2f131c1a52a690db827e8392\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-autore-processo-conservazione.lisp\",
      \"sha256\": \"57d993040da7e9870dc886fa345f47d43224f94f8aca622bf3153efefd1d65c8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-autore-processo.lisp\",
      \"sha256\": \"8bd7ad9527dc49385528733db0b99f1bb80aa41130aac71fd9c764cfa08de4da\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-autore.lisp\",
      \"sha256\": \"d4bdbc05a589cb7507cc6ee4b72d40130be85a99648ae57b3bb2d74391231ce9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-copertura-dati.lisp\",
      \"sha256\": \"4c65d6987f0fc2ce2518540376a1734a1f7b1f310c612337e0de4d424381de75\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo-conservazione.lisp\",
      \"sha256\": \"ec88d0bf3a3f89460f9ba66d506b41ae23839058605b997298ac05c79530573a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo.lisp\",
      \"sha256\": \"631ac966196a07fd161c28b9c6d79ecc803acb8bf1b4bbf6c3f9993f411ca612\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\",
      \"sha256\": \"2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\",
      \"sha256\": \"bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\",
      \"sha256\": \"a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"2c3991f87d5c390ef83210d309045939b21281257251dfac201b1fe40e9ed531\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo.lisp\",
      \"sha256\": \"3a36b8111e8b40860c50338b0990c9f871530f18ab53ac1dc68abf6432b2e616\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\",
      \"sha256\": \"2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-dati.lisp\",
      \"sha256\": \"e10ee76a04038205aa6ca09d24e1b216fdd06639d36567ac9104ea73cd95beca\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo-conservazione.lisp\",
      \"sha256\": \"ccb6692a8c146addab2cfa455aa7e96dfbf101ef4b23ded279d42bf7a1ca508c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo.lisp\",
      \"sha256\": \"b81a0041f825264331c676356dee01eb8a37ebd639543afb64aa1ede04cde1d4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-risultati-integrale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-risultati-integrale.lisp\",
      \"sha256\": \"c88c40d199f36ca86f70202121832d595f5cb4024b43a9456593a2b227272f64\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-risultati-sommario.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-risultati-sommario.lisp\",
      \"sha256\": \"d5ca85c807ddf39a56e5ddfe39bfac690ebd1eb3e8a8730bd500859e903d0dd1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo-conservazione.lisp\",
      \"sha256\": \"90b5c57beb3d2e3c9dfc281446efeed1a12c4cd50c0f3a72b96d4c7e4eb6c76e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo.lisp\",
      \"sha256\": \"a6d184a6685a97f91f92c3b3689c402ad3bc923ce5ccdc74df4f7df6fc8126dc\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-summary-processo-conservazione.lisp\",
      \"sha256\": \"6192429edcf100b72c1423379f581ff31ae6a0bfdf3ad723343f370ce6215054\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/revisione-summary-processo.lisp\",
      \"sha256\": \"bc247fa56e69336cb1e081a050b000df740a263892df2d44d803f1f9f40ffa15\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo.lisp\",
      \"sha256\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/segnale-os-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/segnale-os-dati.lisp\",
      \"sha256\": \"da3fcae536b154fb44927130fa3575cadaddeb05596e2d1e6e3e25acceef5fb0\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/segnale-os-originali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/segnale-os-originali.lisp\",
      \"sha256\": \"6e05e3647c77f5dc332dd3f2759880cd6ee5f96881085c5009d7cfa4db1396ae\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/sorgenti-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/sorgenti-adattatori.lisp\",
      \"sha256\": \"69b783d43230d6355c160dcdcc8ea9bc999ec8a1e1fb471fd22fb727d3d88972\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/spikes-finali-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/spikes-finali-conservazione.lisp\",
      \"sha256\": \"90216eae4885f944b80c3e08a5be9d86474d269e18de1a0cfd7c9edf84dad8ed\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/spikes-finali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/spikes-finali.lisp\",
      \"sha256\": \"90842512f964d56cb118a615e40351f4a2769f5c8f21005e8af4717f45f5c431\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo-conservazione.lisp\",
      \"sha256\": \"d0a9dcb743cc57645c1397e81d1be584e9b2795fd39d10f99b57094c9c709918\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo.lisp\",
      \"sha256\": \"b3e80eb7f7aa53c19746f67a3543fd9a150ee21a6bd9608dda89b32b371859cb\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/worker-review-results-data.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker/worker-review-results-data.lisp.gz\",
      \"sha256\": \"40a2992e077e06d6ad8e5d73d1cf2dc3313e9d7c25cb1cd7ffe5ca70af83b25a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp\",
      \"sha256\": \"3be41dc908bfa081b17c20fb87816fb0cdef675a112bbde61458690b34e00728\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-integration/report.lisp.gz\",
      \"sha256\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/spikes-finali-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-integration/spikes-finali-conservazione.lisp\",
      \"sha256\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/spikes-finali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-integration/spikes-finali.lisp\",
      \"sha256\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-review/catalogo.lisp\",
      \"sha256\": \"0e418772c1493fff9e00ac82ab5fcf5e5874697a68e6b5f797871a9eb691f7e1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-review/report.lisp.gz\",
      \"sha256\": \"a21a27d791a0820baf6729e6860882d85831a6f37daedc159ebb3bb2d104d92c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo-conservazione.lisp\",
      \"sha256\": \"03fa19348d2b9a67c5fb88e881a49a72a1c07f790048014c5f50c86a6989ed8e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo.lisp\",
      \"sha256\": \"ce27e18256fb99a2529cc11db06ea33938cb6ba98da1fb08ce1949500695180f\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-publication-functions.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-publication-functions.lisp\",
      \"sha256\": \"01ce7104faa1905afa2f6b48a03bee04c176ee4c9f68e16ddb1ff435d70a028b\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-refresh-catalog.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-refresh-catalog.lisp\",
      \"sha256\": \"836fd4b47889108a40bde0f478ad5fdc6534d59c9092fa9234f9a363414e23e3\"
    }
  ]
}
")
  (:PATH
   #A((139) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-precommit-evidence.json")
   :BYTES 20614 :SHA256 "72a621ecc12a23026f0b9630ff0546503c26de7a91e7ab7afc7e54a45a5e0d15"
   :GIT-BLOB "012efba650cb4f14fc55dc6e2bd1253222442a61" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"precommit-flat-evidence-files\",
  \"base\": \"e07d77271758f3134b1977caf394fe38532b54ed\",
  \"files\": [
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"ccb6692a8c146addab2cfa455aa7e96dfbf101ef4b23ded279d42bf7a1ca508c\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/worker-review-results-data.lisp.gz\",
      \"bytes\": 478571,
      \"sha256\": \"40a2992e077e06d6ad8e5d73d1cf2dc3313e9d7c25cb1cd7ffe5ca70af83b25a\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-dati.lisp\",
      \"bytes\": 75767,
      \"sha256\": \"37cd88ea5c80df5a2fba6e2142fcce971f8168ec0d0f8c97864929eaf92c4354\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/sorgenti-adattatori.lisp\",
      \"bytes\": 543414,
      \"sha256\": \"69b783d43230d6355c160dcdcc8ea9bc999ec8a1e1fb471fd22fb727d3d88972\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/bench-self-test-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"a0c37d16217c4e89397c9d37423a0001f80890b4e6e12b472707e35719677375\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-piano-tentativo-non-registrato.lisp\",
      \"bytes\": 778,
      \"sha256\": \"5f029a76a814cc6f03819376e260b6774c659502dbe0370194d769987b64e4c0\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/scope-integrazione-processo-conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/scope-integrazione-processo.lisp\",
      \"bytes\": 132676,
      \"sha256\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-summary-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"6192429edcf100b72c1423379f581ff31ae6a0bfdf3ad723343f370ce6215054\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-processo.lisp\",
      \"bytes\": 93747,
      \"sha256\": \"4aaa70d59881a6be3289a642bb7fbd9d7c3764b69c24807e7ff2c7133980a5b2\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"9e1286ac4e613f095e7f8df804853fb745600736e2a1659e0b273e37fd0a2df9\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-dati.lisp\",
      \"bytes\": 15220,
      \"sha256\": \"e10ee76a04038205aa6ca09d24e1b216fdd06639d36567ac9104ea73cd95beca\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo.lisp\",
      \"bytes\": 93810,
      \"sha256\": \"c05ffe3e4724ac39908ad1b107bc2384e439ffc4822781765e60704c3c32a42a\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo.lisp\",
      \"bytes\": 108704,
      \"sha256\": \"b81a0041f825264331c676356dee01eb8a37ebd639543afb64aa1ede04cde1d4\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-risultati-sommario.lisp\",
      \"bytes\": 16398,
      \"sha256\": \"d5ca85c807ddf39a56e5ddfe39bfac690ebd1eb3e8a8730bd500859e903d0dd1\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo-conservazione.lisp\",
      \"bytes\": 1142,
      \"sha256\": \"d0a9dcb743cc57645c1397e81d1be584e9b2795fd39d10f99b57094c9c709918\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-risultati-integrale.lisp\",
      \"bytes\": 337,
      \"sha256\": \"c88c40d199f36ca86f70202121832d595f5cb4024b43a9456593a2b227272f64\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/allocazioni-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"3ebfebe658f973ae850eeba1997c124d8eced4b8ff7f8416a6ae64043586e642\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/allocazioni-processo.lisp\",
      \"bytes\": 122747,
      \"sha256\": \"15fc3a6330fb864f5dc7db2c44441dec1a9966d557914632b74180518d463094\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"74708fdcf432c4c5e3f329c58a4d3f94ab170fd5c85717cb97fceba845f3f6a5\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-autore-processo.lisp\",
      \"bytes\": 93644,
      \"sha256\": \"8bd7ad9527dc49385528733db0b99f1bb80aa41130aac71fd9c764cfa08de4da\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"413e9c390289e5741ffdab6fe37f32102fe5671471ac9955756687fd2a76539d\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-html.lisp\",
      \"bytes\": 335805,
      \"sha256\": \"0f5f772f71838a44c612cd1110a8f956a69488fa2b59cb8b433128e95efc3c49\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp\",
      \"bytes\": 28613,
      \"sha256\": \"4232bc88eeb7cc9f1e72e8cb6ca8ba2696bb0f3fda34770f5f07f752423098a6\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp\",
      \"bytes\": 31936,
      \"sha256\": \"70fc8171b55f0e717eea23f9bad6033941739d40e715c45051df0d103bff8fd5\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo.lisp\",
      \"bytes\": 101741,
      \"sha256\": \"a6d184a6685a97f91f92c3b3689c402ad3bc923ce5ccdc74df4f7df6fc8126dc\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/chiusura-copia-adattatori.lisp\",
      \"bytes\": 2538,
      \"sha256\": \"443440414aa2f1ef5aff571b4c405276defa0380a51cd49deea9b04e5292a945\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/bench-self-test-processo.lisp\",
      \"bytes\": 111745,
      \"sha256\": \"ec9d32a97987f2042be25a0e7ab4e68f822ea43da6739af70da4bb5cb3f3e56c\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-autore-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"57d993040da7e9870dc886fa345f47d43224f94f8aca622bf3153efefd1d65c8\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/check-integrazione-processo-conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-grezza.lisp\",
      \"bytes\": 888355,
      \"sha256\": \"787b1ad0604b98c46690dd4655638d7ff7de4d4cf5f71864235fdc4c5244f09b\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo.lisp\",
      \"bytes\": 107397,
      \"sha256\": \"36e47daedd1744fe6eea0a9bb4f8a1b8e633124dcb4c16efc900c2630938fa32\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-export-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"3b684c3ee1b34972c11115dd87d8d2403449695949a423fc42239d16ac4c356f\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"90b5c57beb3d2e3c9dfc281446efeed1a12c4cd50c0f3a72b96d4c7e4eb6c76e\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/segnale-os-dati.lisp\",
      \"bytes\": 25617,
      \"sha256\": \"da3fcae536b154fb44927130fa3575cadaddeb05596e2d1e6e3e25acceef5fb0\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/report.lisp.gz\",
      \"bytes\": 467202,
      \"sha256\": \"aaba2220d5294a6e0cd801d5febfd87ca78befaf2f131c1a52a690db827e8392\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-copertura-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"ec88d0bf3a3f89460f9ba66d506b41ae23839058605b997298ac05c79530573a\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\",
      \"bytes\": 3766,
      \"sha256\": \"a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-copia-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"f7e13451481888b732167d82b4a7d2f989bbb3dc9a495b5c993fe43fd1c6de65\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"34251a0b7c759c97409320374a8d558c8d99bebc630a9bc6213d893a4cd4d290\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-copertura-dati.lisp\",
      \"bytes\": 11735,
      \"sha256\": \"4c65d6987f0fc2ce2518540376a1734a1f7b1f310c612337e0de4d424381de75\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-summary-processo.lisp\",
      \"bytes\": 109645,
      \"sha256\": \"bc247fa56e69336cb1e081a050b000df740a263892df2d44d803f1f9f40ffa15\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-copertura-processo.lisp\",
      \"bytes\": 104557,
      \"sha256\": \"631ac966196a07fd161c28b9c6d79ecc803acb8bf1b4bbf6c3f9993f411ca612\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-autore.lisp\",
      \"bytes\": 31409,
      \"sha256\": \"d4bdbc05a589cb7507cc6ee4b72d40130be85a99648ae57b3bb2d74391231ce9\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo.lisp\",
      \"bytes\": 102787,
      \"sha256\": \"be18d788d301be3a946461ed58d60e02f6bc96b570f18d6aeb73878953eed0ba\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-processo.lisp\",
      \"bytes\": 100730,
      \"sha256\": \"af3dfba084cbe52e87a3e1c59bc52daa95c50e021d2bc7a08544bfb64ee51306\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo.lisp\",
      \"bytes\": 95098,
      \"sha256\": \"ea1d081db0e8a93c8d6a651f18b7a8f83c452fca1b1e64d28cb96e06e1e92fc8\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\",
      \"bytes\": 2301,
      \"sha256\": \"2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"1b6df4d427a5677d6e189d996d3cdd525db0c5d6fb8924c1e307186925bf41af\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-summary-processo-conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"876221f31ebd21e0054304106ba012b121e82f685e6614f474473faa3b3944e3\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo.lisp\",
      \"bytes\": 94031,
      \"sha256\": \"70ff3ff6ba4ba4d06772d66586c900297725ebf102c6ce1b71fa34c1fb68502a\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\",
      \"bytes\": 4838,
      \"sha256\": \"bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo.lisp\",
      \"bytes\": 93908,
      \"sha256\": \"6a273caa381d83107588a05b1850629a3406112aa29652b2248a428d116cbe7a\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/catalogo.lisp\",
      \"bytes\": 34316,
      \"sha256\": \"56574cfbcffb69f61ff7b75e4d6f439342a39361c7ce92ba35e267c2b08e13aa\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/probe-root-processo.lisp\",
      \"bytes\": 94593,
      \"sha256\": \"c58a825e04c175e4f73215ea55d972b3301e86d88ca73f66c81d111ff20ef5d2\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo.lisp\",
      \"bytes\": 121552,
      \"sha256\": \"aeed0ef5c8c2ce6664bb0a6dc264c33b7f09ab765246152df52b65f849c6a905\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"4b9dd954673af056b7cd98ecedcadd3851310775cd83113b3f9c2f29dfeb0c5c\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"ac8d88a1b9c02e4f223d64991b16308e4aa60ec0793a905b1307faeccaa76f99\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/segnale-os-originali.lisp\",
      \"bytes\": 794,
      \"sha256\": \"6e05e3647c77f5dc332dd3f2759880cd6ee5f96881085c5009d7cfa4db1396ae\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-adattatori.lisp\",
      \"bytes\": 1435,
      \"sha256\": \"f1895fcbeda3e687c47296bde314583a88f5cb2f8f9dadc2f946bb9aed7321a1\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"a8823abc6d3a690b517f815b3d15136ffdef2e677ea049658206ee94b7439556\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp\",
      \"bytes\": 217829,
      \"sha256\": \"171017fb3a43f10b0ea2feef9edb49b099c188a8d54449dfd69ff390b56d09b3\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-native.lisp\",
      \"bytes\": 873213,
      \"sha256\": \"6556c89d470b443591607229ad043a023d03c8f346258e048fc1a860e8a3a973\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"21ea48fc083f80c4f3a4f3f17d634eb2e1c0115fdbc8d06df9f395e1c9135ce6\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo.lisp\",
      \"bytes\": 93788,
      \"sha256\": \"07c0940cefd02b9efad91db323a6236c83e580b37c48c0ec2ed573567d0593c9\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/spikes-finali.lisp\",
      \"bytes\": 318,
      \"sha256\": \"90842512f964d56cb118a615e40351f4a2769f5c8f21005e8af4717f45f5c431\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"e9e1c34b2ec99f350e3b505257d53b62b5675ccbac94114e2cb3282e5f758d54\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\",
      \"bytes\": 9205,
      \"sha256\": \"2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/copertura-export-processo.lisp\",
      \"bytes\": 94079,
      \"sha256\": \"914ded890553fe32d461eadedd27a12db494cba057697069346bf75307bcbb9e\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"52576b5d72b100679eeb7a5d6efeb44e5f4b8da16947ee6477d0e07691d95496\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-summary-processo.lisp\",
      \"bytes\": 97258,
      \"sha256\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo-conservazione.lisp\",
      \"bytes\": 1244,
      \"sha256\": \"2c3991f87d5c390ef83210d309045939b21281257251dfac201b1fe40e9ed531\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/probe-root-processo-conservazione.lisp\",
      \"bytes\": 1223,
      \"sha256\": \"fc39b4e3a1384e449b472e2f43b4dbf1f2edd50abb3f8b704f19b9c42d0cd98e\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-copia-processo.lisp\",
      \"bytes\": 113480,
      \"sha256\": \"a609160ec3b296beb8a16b4905644912372dc5d05e8ac7dff2bd29cea0d725f6\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo.lisp\",
      \"bytes\": 91090,
      \"sha256\": \"b3e80eb7f7aa53c19746f67a3543fd9a150ee21a6bd9608dda89b32b371859cb\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo.lisp\",
      \"bytes\": 93584,
      \"sha256\": \"1c1efacd5ee4fd3b80be229bb90ad781d3d9761b6fa40481b2182d87f65f14ab\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/mutazioni-log.lisp\",
      \"bytes\": 274377,
      \"sha256\": \"855afe77a12531115f864fc3b36d609ae608e5106bc8475f1131b701e173d91c\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo.lisp\",
      \"bytes\": 94158,
      \"sha256\": \"c90cdc6d99e6af765b517e7b4944bf6eb6719e6cea5cb7de81b929262d7fe6aa\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/check-finale-processo-conservazione.lisp\",
      \"bytes\": 1229,
      \"sha256\": \"75110bd290cf658ac52deee29a8b50d15910a85a09088587b30049bf6dfaa2f2\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo-conservazione.lisp\",
      \"bytes\": 1226,
      \"sha256\": \"b5e29180721602708cad16c95c734d85a2aaad033557ef9f725be3f005a05ad3\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo.lisp\",
      \"bytes\": 93943,
      \"sha256\": \"5f5e2439bdae533ca3d24e6a5f4c59a66b1b630aca4ad6bd5c781f17ff456366\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp\",
      \"bytes\": 232551,
      \"sha256\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/spikes-finali-conservazione.lisp\",
      \"bytes\": 2426,
      \"sha256\": \"90216eae4885f944b80c3e08a5be9d86474d269e18de1a0cfd7c9edf84dad8ed\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo.lisp\",
      \"bytes\": 97513,
      \"sha256\": \"3a36b8111e8b40860c50338b0990c9f871530f18ab53ac1dc68abf6432b2e616\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-integration/report.lisp.gz\",
      \"bytes\": 467437,
      \"sha256\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp\",
      \"bytes\": 1272,
      \"sha256\": \"3be41dc908bfa081b17c20fb87816fb0cdef675a112bbde61458690b34e00728\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-integration/spikes-finali.lisp\",
      \"bytes\": 318,
      \"sha256\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-integration/spikes-finali-conservazione.lisp\",
      \"bytes\": 2452,
      \"sha256\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-review/report.lisp.gz\",
      \"bytes\": 484897,
      \"sha256\": \"a21a27d791a0820baf6729e6860882d85831a6f37daedc159ebb3bb2d104d92c\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo-conservazione.lisp\",
      \"bytes\": 1839,
      \"sha256\": \"03fa19348d2b9a67c5fb88e881a49a72a1c07f790048014c5f50c86a6989ed8e\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-review/catalogo.lisp\",
      \"bytes\": 1317,
      \"sha256\": \"0e418772c1493fff9e00ac82ab5fcf5e5874697a68e6b5f797871a9eb691f7e1\"
    },
    {
      \"path\": \"spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo.lisp\",
      \"bytes\": 318,
      \"sha256\": \"ce27e18256fb99a2529cc11db06ea33938cb6ba98da1fb08ce1949500695180f\"
    }
  ],
  \"owned_files\": [
    \"arcdocdb.asd\",
    \"src/execution/package.lisp\",
    \"src/execution/worker-types.lisp\",
    \"src/execution/worker-boundary.lisp\",
    \"src/execution/worker-claim.lisp\",
    \"src/execution/worker-run.lisp\",
    \"tests/execution/worker.lisp\",
    \"tools/writer-worker-bench.lisp\",
    \"tools/writer-worker-mutation.lisp\",
    \"docs/implementazione/writer-worker-metodo.md\",
    \"docs/implementazione/writer-worker.md\",
    \"docs/implementazione/writer-worker-decisioni.md\",
    \"docs/implementazione/writer-worker-risultati.md\",
    \"docs/implementazione/writer-worker-revisione.md\",
    \"docs/implementazione/README.md\",
    \"docs/affidabilita/copertura-eccezioni.md\"
  ]
}
")
  (:PATH
   #A((137) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-owned-comparison.json")
   :BYTES 2398 :SHA256 "eec3c07e8c2aeeaecd8bfef733711e6e45af84faf8e1c8094d2700ecd22d3d62" :GIT-BLOB
   "675923644a612549a60340b86d463a0491074665" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"owned-source-doc-byte-comparison\",
  \"status\": \"passed\",
  \"integration_base\": \"e07d77271758f3134b1977caf394fe38532b54ed\",
  \"files\": [
    {
      \"path\": \"src/execution/package.lisp\",
      \"sha256\": \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
    },
    {
      \"path\": \"src/execution/worker-types.lisp\",
      \"sha256\": \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
    },
    {
      \"path\": \"src/execution/worker-boundary.lisp\",
      \"sha256\": \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
    },
    {
      \"path\": \"src/execution/worker-claim.lisp\",
      \"sha256\": \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
    },
    {
      \"path\": \"src/execution/worker-run.lisp\",
      \"sha256\": \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
    },
    {
      \"path\": \"tests/execution/worker.lisp\",
      \"sha256\": \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
    },
    {
      \"path\": \"tools/writer-worker-bench.lisp\",
      \"sha256\": \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
    },
    {
      \"path\": \"tools/writer-worker-mutation.lisp\",
      \"sha256\": \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
    },
    {
      \"path\": \"docs/implementazione/writer-worker-metodo.md\",
      \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    },
    {
      \"path\": \"docs/implementazione/writer-worker.md\",
      \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    },
    {
      \"path\": \"docs/implementazione/writer-worker-decisioni.md\",
      \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
    },
    {
      \"path\": \"docs/implementazione/writer-worker-risultati.md\",
      \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
    },
    {
      \"path\": \"docs/implementazione/writer-worker-revisione.md\",
      \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
    },
    {
      \"path\": \"docs/affidabilita/copertura-eccezioni.md\",
      \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    }
  ],
  \"merged_files\": [
    \"arcdocdb.asd\",
    \"docs/implementazione/README.md\"
  ],
  \"execution_unchanged_upstream\": true
}
")
  (:PATH
   #A((140) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary.lisp")
   :BYTES 6521 :SHA256 "e2785bed1785cf30a8e3ed71f9e1d38efe2a3e2da027a5a3e734ed4656cd1637" :GIT-BLOB
   "f0d36cc37538afcbb5db7abd7b6638c474bb070e" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")

(defun final-leading-number (line)
  (when (and (plusp (length line)) (digit-char-p (char line 0)))
    (multiple-value-bind (number end) (parse-integer line :junk-allowed t)
      (when (and number (< end (length line)) (char= #\\Space (char line end))) number))))
(defun final-numbers (line)
  (loop with position = 0 while (< position (length line))
        if (digit-char-p (char line position))
          collect (multiple-value-bind (number end) (parse-integer line :start position :junk-allowed t)
                    (setf position end) number)
        else do (incf position)))
(defun final-only-line (predicate lines label)
  (let ((matching (remove-if-not predicate lines)))
    (unless (= 1 (length matching))
      (error \"Expected one actual ~A summary line, found ~D.\" label (length matching)))
    (first matching)))
(defun final-main ()
  (let ((args (uiop:command-line-arguments)))
    (unless (= 2 (length args))
      (error \"Use final-summary CHECK-REPORT OUTPUT-DATA; rereads records only.\"))
    (let* ((check-path (first args)) (output-path (second args))
           (check (arcdocdb.evidence:read-evidence check-path))
           (stdout (getf check :stdout))
           (lines (uiop:split-string stdout :separator '(#\\Newline)))
           (modules (loop for line in lines for count = (final-leading-number line)
                          when (and count (search \" test\" line) (search \"superati.\" line))
                            collect (list :count count :raw-line line)))
           (lint (final-only-line
                  (lambda (line) (and (final-leading-number line)
                                      (search \"file, 0 violazioni\" line))) lines :lint))
           (links (final-only-line
                   (lambda (line) (and (final-leading-number line)
                                       (search \"link controllati, 0 rotti\" line))) lines :links))
           (trace (final-only-line
                   (lambda (line) (and (final-leading-number line) (search \"requisiti,\" line)
                                       (search \"invarianti,\" line) (search \"scenari FI,\" line)
                                       (search \"ADR: 0 errori\" line))) lines :trace))
           (spikes-line (final-only-line
                         (lambda (line) (and (final-leading-number line)
                                             (search \"spike completati; risultati:\" line)))
                         lines :spikes))
           (marker \"spike completati; risultati:\")
           (spikes-directory
             (string-trim '(#\\Space #\\Tab #\\Return)
                          (subseq spikes-line (+ (search marker spikes-line) (length marker)))))
           (spikes-path (namestring (merge-pathnames \"report.lisp\" (pathname spikes-directory))))
           (spikes (arcdocdb.evidence:read-evidence spikes-path))
           (runs (getf spikes :runs))
           (sum (reduce #'+ modules :key (lambda (entry) (getf entry :count)) :initial-value 0)))
      (assert (and (eq :ok (getf check :status)) (eq :stable (getf check :source-consistency))
                   (eql 0 (getf check :exit-code))
                   (equal (getf check :source-blobs-before) (getf check :source-blobs-after))
                   (string= \"e07d77271758f3134b1977caf394fe38532b54ed\"
                            (getf (getf check :environment) :commit))))
      ;; Suite cardinality comes from final ASDF integration; test counts and all
      ;; lint/links/trace totals come exclusively from completed raw stdout.
      (assert (= 11 (length modules)))
      (assert (= (length modules) (length (remove-duplicates modules :test #'equal))))
      (assert (find-if (lambda (entry) (search \"test delle testate CBOR minime superati.\"
                                             (getf entry :raw-line))) modules))
      (assert (and (plusp sum)
                   (search \"build e test: nessun avviso, tutti i controlli superati\" stdout)
                   (search \"ok    package ARCDOCDB presente\" stdout)
                   (search \"ok    ARCDOCDB:*VERSION* è una stringa\" stdout)))
      (assert (and (eq :complete (getf spikes :status))
                   (= (final-leading-number spikes-line) (length runs))
                   (every (lambda (run) (and (eq :ok (getf run :status))
                                             (eql 0 (getf run :exit-code))
                                             (eq :stable (getf run :source-consistency)))) runs)))
      (let ((report
              (list :schema-version 1 :kind :writer-worker-final-integration-summary :status :passed
                    :integration-head \"e07d77271758f3134b1977caf394fe38532b54ed\"
                    :historical-integrated-head \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
                    :worker-baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                    :check-path check-path :check-sha256 (arcdocdb.evidence:file-sha256 check-path)
                    :check-command (getf check :command) :source-consistency :stable
                    :test-sum sum :suite-count (length modules) :test-modules modules
                    :smoke :passed :compile :no-warnings
                    :lint-raw lint :lint-numbers (final-numbers lint)
                    :links-raw links :links-numbers (final-numbers links)
                    :trace-raw trace :trace-numbers (final-numbers trace)
                    :spikes-path spikes-path :spikes-sha256 (arcdocdb.evidence:file-sha256 spikes-path)
                    :spikes-raw spikes-line
                    :spikes (mapcar (lambda (run) (list :id (getf run :id) :status (getf run :status)
                                                        :exit-code (getf run :exit-code)
                                                        :source-consistency (getf run :source-consistency))) runs)
                    :limits '(:readonly-projection :one-final-make-check-core
                              :private-xdg-cache :sbcl-dynamic-space-4096-mib
                              :no-repeat-of-worker-mutation-benchmark-or-coverage))))
        (with-open-file (stream output-path :direction :output :if-exists :error)
          (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
        (format t \"FINAL-INTEGRATION-SUMMARY-PASS ~D tests across ~D suites plus smoke; ~A; ~A; ~A; ~A~%Data: ~A~%\"
                sum (length modules) lint trace links spikes-line output-path)))))
(final-main)
")
  (:PATH
   #A((147) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-failed.lisp")
   :BYTES 6521 :SHA256 "e2785bed1785cf30a8e3ed71f9e1d38efe2a3e2da027a5a3e734ed4656cd1637" :GIT-BLOB
   "f0d36cc37538afcbb5db7abd7b6638c474bb070e" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")

(defun final-leading-number (line)
  (when (and (plusp (length line)) (digit-char-p (char line 0)))
    (multiple-value-bind (number end) (parse-integer line :junk-allowed t)
      (when (and number (< end (length line)) (char= #\\Space (char line end))) number))))
(defun final-numbers (line)
  (loop with position = 0 while (< position (length line))
        if (digit-char-p (char line position))
          collect (multiple-value-bind (number end) (parse-integer line :start position :junk-allowed t)
                    (setf position end) number)
        else do (incf position)))
(defun final-only-line (predicate lines label)
  (let ((matching (remove-if-not predicate lines)))
    (unless (= 1 (length matching))
      (error \"Expected one actual ~A summary line, found ~D.\" label (length matching)))
    (first matching)))
(defun final-main ()
  (let ((args (uiop:command-line-arguments)))
    (unless (= 2 (length args))
      (error \"Use final-summary CHECK-REPORT OUTPUT-DATA; rereads records only.\"))
    (let* ((check-path (first args)) (output-path (second args))
           (check (arcdocdb.evidence:read-evidence check-path))
           (stdout (getf check :stdout))
           (lines (uiop:split-string stdout :separator '(#\\Newline)))
           (modules (loop for line in lines for count = (final-leading-number line)
                          when (and count (search \" test\" line) (search \"superati.\" line))
                            collect (list :count count :raw-line line)))
           (lint (final-only-line
                  (lambda (line) (and (final-leading-number line)
                                      (search \"file, 0 violazioni\" line))) lines :lint))
           (links (final-only-line
                   (lambda (line) (and (final-leading-number line)
                                       (search \"link controllati, 0 rotti\" line))) lines :links))
           (trace (final-only-line
                   (lambda (line) (and (final-leading-number line) (search \"requisiti,\" line)
                                       (search \"invarianti,\" line) (search \"scenari FI,\" line)
                                       (search \"ADR: 0 errori\" line))) lines :trace))
           (spikes-line (final-only-line
                         (lambda (line) (and (final-leading-number line)
                                             (search \"spike completati; risultati:\" line)))
                         lines :spikes))
           (marker \"spike completati; risultati:\")
           (spikes-directory
             (string-trim '(#\\Space #\\Tab #\\Return)
                          (subseq spikes-line (+ (search marker spikes-line) (length marker)))))
           (spikes-path (namestring (merge-pathnames \"report.lisp\" (pathname spikes-directory))))
           (spikes (arcdocdb.evidence:read-evidence spikes-path))
           (runs (getf spikes :runs))
           (sum (reduce #'+ modules :key (lambda (entry) (getf entry :count)) :initial-value 0)))
      (assert (and (eq :ok (getf check :status)) (eq :stable (getf check :source-consistency))
                   (eql 0 (getf check :exit-code))
                   (equal (getf check :source-blobs-before) (getf check :source-blobs-after))
                   (string= \"e07d77271758f3134b1977caf394fe38532b54ed\"
                            (getf (getf check :environment) :commit))))
      ;; Suite cardinality comes from final ASDF integration; test counts and all
      ;; lint/links/trace totals come exclusively from completed raw stdout.
      (assert (= 11 (length modules)))
      (assert (= (length modules) (length (remove-duplicates modules :test #'equal))))
      (assert (find-if (lambda (entry) (search \"test delle testate CBOR minime superati.\"
                                             (getf entry :raw-line))) modules))
      (assert (and (plusp sum)
                   (search \"build e test: nessun avviso, tutti i controlli superati\" stdout)
                   (search \"ok    package ARCDOCDB presente\" stdout)
                   (search \"ok    ARCDOCDB:*VERSION* è una stringa\" stdout)))
      (assert (and (eq :complete (getf spikes :status))
                   (= (final-leading-number spikes-line) (length runs))
                   (every (lambda (run) (and (eq :ok (getf run :status))
                                             (eql 0 (getf run :exit-code))
                                             (eq :stable (getf run :source-consistency)))) runs)))
      (let ((report
              (list :schema-version 1 :kind :writer-worker-final-integration-summary :status :passed
                    :integration-head \"e07d77271758f3134b1977caf394fe38532b54ed\"
                    :historical-integrated-head \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
                    :worker-baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                    :check-path check-path :check-sha256 (arcdocdb.evidence:file-sha256 check-path)
                    :check-command (getf check :command) :source-consistency :stable
                    :test-sum sum :suite-count (length modules) :test-modules modules
                    :smoke :passed :compile :no-warnings
                    :lint-raw lint :lint-numbers (final-numbers lint)
                    :links-raw links :links-numbers (final-numbers links)
                    :trace-raw trace :trace-numbers (final-numbers trace)
                    :spikes-path spikes-path :spikes-sha256 (arcdocdb.evidence:file-sha256 spikes-path)
                    :spikes-raw spikes-line
                    :spikes (mapcar (lambda (run) (list :id (getf run :id) :status (getf run :status)
                                                        :exit-code (getf run :exit-code)
                                                        :source-consistency (getf run :source-consistency))) runs)
                    :limits '(:readonly-projection :one-final-make-check-core
                              :private-xdg-cache :sbcl-dynamic-space-4096-mib
                              :no-repeat-of-worker-mutation-benchmark-or-coverage))))
        (with-open-file (stream output-path :direction :output :if-exists :error)
          (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
        (format t \"FINAL-INTEGRATION-SUMMARY-PASS ~D tests across ~D suites plus smoke; ~A; ~A; ~A; ~A~%Data: ~A~%\"
                sum (length modules) lint trace links spikes-line output-path)))))
(final-main)
")
  (:PATH
   #A((143) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-summary-v2.lisp")
   :BYTES 6534 :SHA256 "e1f0d2df2109484e5ecaccdb19a54b65509e6fe455cf85fcaaadfe4e7f8726a4" :GIT-BLOB
   "12ee65cfb0ebdf5d8fff9958482ccb12ea5f1e79" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")

(defun final-leading-number (line)
  (when (and (plusp (length line)) (digit-char-p (char line 0)))
    (multiple-value-bind (number end) (parse-integer line :junk-allowed t)
      (when (and number (< end (length line)) (char= #\\Space (char line end))) number))))
(defun final-numbers (line)
  (loop with position = 0 while (< position (length line))
        if (digit-char-p (char line position))
          collect (multiple-value-bind (number end) (parse-integer line :start position :junk-allowed t)
                    (setf position end) number)
        else do (incf position)))
(defun final-only-line (predicate lines label)
  (let ((matching (remove-if-not predicate lines)))
    (unless (= 1 (length matching))
      (error \"Expected one actual ~A summary line, found ~D.\" label (length matching)))
    (first matching)))
(defun final-main ()
  (let ((args (uiop:command-line-arguments)))
    (unless (= 2 (length args))
      (error \"Use final-summary CHECK-REPORT OUTPUT-DATA; rereads records only.\"))
    (let* ((check-path (first args)) (output-path (second args))
           (check (arcdocdb.evidence:read-evidence check-path))
           (stdout (getf check :stdout))
           (lines (uiop:split-string stdout :separator '(#\\Newline)))
           (modules (loop for line in lines for count = (final-leading-number line)
                          when (and count (search \" test\" line) (search \"superati.\" line))
                            collect (list :count count :raw-line line)))
           (lint (final-only-line
                  (lambda (line) (and (final-leading-number line)
                                      (search \"file, 0 violazioni\" line))) lines :lint))
           (links (final-only-line
                   (lambda (line) (and (final-leading-number line)
                                       (search \"link controllati, 0 rotti\" line))) lines :links))
           (trace (final-only-line
                   (lambda (line) (and (final-leading-number line) (search \"requisiti,\" line)
                                       (search \"invarianti,\" line) (search \"scenari FI,\" line)
                                       (search \"ADR: 0 errori\" line))) lines :trace))
           (spikes-line (final-only-line
                         (lambda (line) (and (final-leading-number line)
                                             (search \"spike completati; risultati:\" line)))
                         lines :spikes))
           (marker \"spike completati; risultati:\")
           (spikes-directory
             (string-trim '(#\\Space #\\Tab #\\Return)
                          (subseq spikes-line (+ (search marker spikes-line) (length marker)))))
           (spikes-path (namestring (merge-pathnames \"report.lisp\" (pathname spikes-directory))))
           (spikes (arcdocdb.evidence:read-evidence spikes-path))
           (runs (getf spikes :runs))
           (sum (reduce #'+ modules :key (lambda (entry) (getf entry :count)) :initial-value 0)))
      (assert (and (eq :ok (getf check :status)) (eq :stable (getf check :source-consistency))
                   (eql 0 (getf check :exit-code))
                   (equal (getf check :source-blobs-before) (getf check :source-blobs-after))
                   (string= \"e07d77271758f3134b1977caf394fe38532b54ed\"
                            (getf (getf check :environment) :commit))))
      ;; Suite cardinality comes from final ASDF integration; test counts and all
      ;; lint/links/trace totals come exclusively from completed raw stdout.
      (assert (= 11 (length modules)))
      (assert (= (length modules) (length (remove-duplicates modules :test #'equal))))
      (assert (find-if (lambda (entry) (search \"test delle testate CBOR minime superati.\"
                                             (getf entry :raw-line))) modules))
      (assert (and (plusp sum)
                   (search \"build e test: nessun avviso, tutti i controlli superati\" stdout)
                   (search \"ok    package ARCDOCDB presente\" stdout)
                   (search \"ok    ARCDOCDB:*VERSION* è una stringa\" stdout)))
      (assert (and (eq :complete (getf spikes :status))
                   (= (final-leading-number spikes-line) (length runs))
                   (every (lambda (run) (and (member (getf run :status) '(:ok :pass))
                                             (eql 0 (getf run :exit-code))
                                             (eq :stable (getf run :source-consistency)))) runs)))
      (let ((report
              (list :schema-version 1 :kind :writer-worker-final-integration-summary :status :passed
                    :integration-head \"e07d77271758f3134b1977caf394fe38532b54ed\"
                    :historical-integrated-head \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
                    :worker-baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                    :check-path check-path :check-sha256 (arcdocdb.evidence:file-sha256 check-path)
                    :check-command (getf check :command) :source-consistency :stable
                    :test-sum sum :suite-count (length modules) :test-modules modules
                    :smoke :passed :compile :no-warnings
                    :lint-raw lint :lint-numbers (final-numbers lint)
                    :links-raw links :links-numbers (final-numbers links)
                    :trace-raw trace :trace-numbers (final-numbers trace)
                    :spikes-path spikes-path :spikes-sha256 (arcdocdb.evidence:file-sha256 spikes-path)
                    :spikes-raw spikes-line
                    :spikes (mapcar (lambda (run) (list :id (getf run :id) :status (getf run :status)
                                                        :exit-code (getf run :exit-code)
                                                        :source-consistency (getf run :source-consistency))) runs)
                    :limits '(:readonly-projection :one-final-make-check-core
                              :private-xdg-cache :sbcl-dynamic-space-4096-mib
                              :no-repeat-of-worker-mutation-benchmark-or-coverage))))
        (with-open-file (stream output-path :direction :output :if-exists :error)
          (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
        (format t \"FINAL-INTEGRATION-SUMMARY-PASS ~D tests across ~D suites plus smoke; ~A; ~A; ~A; ~A~%Data: ~A~%\"
                sum (length modules) lint trace links spikes-line output-path)))))
(final-main)
")
  (:PATH
   #A((151) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-manifest.json")
   :BYTES 2619 :SHA256 "0589547661ceb7a8bd7bda6d42764a6bb5952afe1bd13652ad2370db11e95ec0" :GIT-BLOB
   "ff992eb0b83cc3cda47b4705ed77ccdf1cda60f1" :TEXT "{
  \"schema_version\": 1,
  \"reader_process\": \"4000550907-command-25363-0\",
  \"failed_reader_processes\": [
    \"4000550739-command-16126-0\",
    \"4000550806-command-19882-0\",
    \"4000550861-command-22217-0\"
  ],
  \"files\": [
    {
      \"path\": \"spikes/out/worker-c1-final-integration-addendum-read-attempt-2-failed.lisp\",
      \"sha256\": \"99119af9ade9d7f1853c33f5d4995e3183fba358a24788f19a32374b9d7d22e1\",
      \"bytes\": 3454
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-addendum-read-attempt-3-failed.lisp\",
      \"sha256\": \"99119af9ade9d7f1853c33f5d4995e3183fba358a24788f19a32374b9d7d22e1\",
      \"bytes\": 3454
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-addendum-read-failed.lisp\",
      \"sha256\": \"eae0cac8767cc9d938dc76e013f3b1c38db66646148c8dc5eeca262d85512294\",
      \"bytes\": 3454
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-addendum-read.lisp\",
      \"sha256\": \"899f6c5683045a374292d8c999b8cd5830a00be6583bc415445986389b35133a\",
      \"bytes\": 3947
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-addendum.lisp\",
      \"sha256\": \"2b26eb2b1d95ba7267232bf710b896d2c22b72a395f3eadf1a76d7d5ceb2697c\",
      \"bytes\": 13245
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-audit-attempt-2-failed.py\",
      \"sha256\": \"7cb25f61c01ff9650a2c5ad7a522eb01ffb9d45cae032066f85f8c4519050a00\",
      \"bytes\": 6692
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-audit-attempt-3-failed.py\",
      \"sha256\": \"95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a\",
      \"bytes\": 7148
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-audit-failed.py\",
      \"sha256\": \"432d3a4c29b827f7c99a1d01a00794fa95302e582fe40c90112bbbf89e73f992\",
      \"bytes\": 6682
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-audit.py\",
      \"sha256\": \"95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a\",
      \"bytes\": 7148
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-reader-attempt-1-diagnostic.txt\",
      \"sha256\": \"215634bf64c6359ec2860131f9766eb10a216db486fda17c1616ac644156d7fc\",
      \"bytes\": 431
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stderr.log\",
      \"sha256\": \"e46c940049af3038a33b87915231ce3604881b7ea479163bde0ed67d2f235239\",
      \"bytes\": 459
    },
    {
      \"path\": \"spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stdout.log\",
      \"sha256\": \"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\",
      \"bytes\": 0
    }
  ]
}")
  (:PATH
   #A((166) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-2-failed.lisp")
   :BYTES 3454 :SHA256 "99119af9ade9d7f1853c33f5d4995e3183fba358a24788f19a32374b9d7d22e1" :GIT-BLOB
   "09365d3810625f61a14447188d1a45b686e2e263" :TEXT
   ";;;; Lettura indipendente V3: dati e blob esistenti; nessun gate prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((audit-output (uiop:run-program
                      '(\"python3\" \"spikes/out/worker-c1-final-integration-audit.py\")
                      :output :string :error-output :output))
       (audit (read-from-string audit-output))
       (id \"4000550386-command-90070-0\")
       (path (format nil \"spikes/out/~A/report.lisp\" id))
       (record (arcdocdb.evidence:read-evidence path))
       (lines (remove-if-not
                (lambda (line)
                  (and (< (length line) 400)
                       (not (uiop:string-prefix-p \"ok    \" line))
                       (some (lambda (word) (search word line))
                             '(\"test superati\" \"file, \" \" REQ,\" \"link\" \"nessun avviso\"))))
                (uiop:split-string (getf record :stdout) :separator '(#\\Newline)))))
  (assert (eq (getf record :status) :ok))
  (assert (eq (getf record :source-consistency) :stable))
  (assert (= (getf record :exit-code) 0))
  (assert (equal (getf record :command) '(\"make\" \"check\")))
  (dolist (entry (getf audit :worker-identity))
    (dolist (side '(:source-blobs-before :source-blobs-after))
      (let ((snapshot (find (getf entry :path) (getf record side)
                            :test #'string= :key (lambda (v) (getf v :path)))))
        (assert snapshot)
        (assert (string= (getf snapshot :git-blob) (getf entry :git-blob))))))
  (let ((report (list :schema-version 1 :kind :independent-c1-final-integration-addendum
                      :scope :v3-source-and-existing-record-reading
                      :baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      :upstream \"e07d77271758f3134b1977caf394fe38532b54ed\"
                      :previous-reports-preserved t :audit audit
                      :reader-python-sha256
                      (arcdocdb.evidence:file-sha256 \"spikes/out/worker-c1-final-integration-audit.py\")
                      :full-check (list :process id :path path
                                        :sha256 (arcdocdb.evidence:file-sha256 path)
                                        :status (getf record :status)
                                        :source-consistency (getf record :source-consistency)
                                        :exit-code (getf record :exit-code)
                                        :wall-seconds (getf record :wall-seconds)
                                        :stdout-summary lines)
                      :limits '(:no-source-or-document-edit :no-product-test-rerun
                                :scoped-worker-campaigns-retain-cf60913
                                :prior-doc-snapshots-retain-their-own-records
                                :no-new-coverage-or-mcdc-qualification
                                :no-whole-pool-or-series-controller-qualification))))
    (with-open-file (output \"spikes/out/worker-c1-final-integration-addendum.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&WORKER-C1-V3-READ-PASS: 20 unchanged execution/test/tool files; ~D upstream blobs; 101 exact originals.~%\"
            (getf audit :upstream-preserved-file-count))
    (format t \"~&~S~%\" (getf report :full-check))))
")
  (:PATH
   #A((166) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-attempt-3-failed.lisp")
   :BYTES 3454 :SHA256 "99119af9ade9d7f1853c33f5d4995e3183fba358a24788f19a32374b9d7d22e1" :GIT-BLOB
   "09365d3810625f61a14447188d1a45b686e2e263" :TEXT
   ";;;; Lettura indipendente V3: dati e blob esistenti; nessun gate prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((audit-output (uiop:run-program
                      '(\"python3\" \"spikes/out/worker-c1-final-integration-audit.py\")
                      :output :string :error-output :output))
       (audit (read-from-string audit-output))
       (id \"4000550386-command-90070-0\")
       (path (format nil \"spikes/out/~A/report.lisp\" id))
       (record (arcdocdb.evidence:read-evidence path))
       (lines (remove-if-not
                (lambda (line)
                  (and (< (length line) 400)
                       (not (uiop:string-prefix-p \"ok    \" line))
                       (some (lambda (word) (search word line))
                             '(\"test superati\" \"file, \" \" REQ,\" \"link\" \"nessun avviso\"))))
                (uiop:split-string (getf record :stdout) :separator '(#\\Newline)))))
  (assert (eq (getf record :status) :ok))
  (assert (eq (getf record :source-consistency) :stable))
  (assert (= (getf record :exit-code) 0))
  (assert (equal (getf record :command) '(\"make\" \"check\")))
  (dolist (entry (getf audit :worker-identity))
    (dolist (side '(:source-blobs-before :source-blobs-after))
      (let ((snapshot (find (getf entry :path) (getf record side)
                            :test #'string= :key (lambda (v) (getf v :path)))))
        (assert snapshot)
        (assert (string= (getf snapshot :git-blob) (getf entry :git-blob))))))
  (let ((report (list :schema-version 1 :kind :independent-c1-final-integration-addendum
                      :scope :v3-source-and-existing-record-reading
                      :baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      :upstream \"e07d77271758f3134b1977caf394fe38532b54ed\"
                      :previous-reports-preserved t :audit audit
                      :reader-python-sha256
                      (arcdocdb.evidence:file-sha256 \"spikes/out/worker-c1-final-integration-audit.py\")
                      :full-check (list :process id :path path
                                        :sha256 (arcdocdb.evidence:file-sha256 path)
                                        :status (getf record :status)
                                        :source-consistency (getf record :source-consistency)
                                        :exit-code (getf record :exit-code)
                                        :wall-seconds (getf record :wall-seconds)
                                        :stdout-summary lines)
                      :limits '(:no-source-or-document-edit :no-product-test-rerun
                                :scoped-worker-campaigns-retain-cf60913
                                :prior-doc-snapshots-retain-their-own-records
                                :no-new-coverage-or-mcdc-qualification
                                :no-whole-pool-or-series-controller-qualification))))
    (with-open-file (output \"spikes/out/worker-c1-final-integration-addendum.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&WORKER-C1-V3-READ-PASS: 20 unchanged execution/test/tool files; ~D upstream blobs; 101 exact originals.~%\"
            (getf audit :upstream-preserved-file-count))
    (format t \"~&~S~%\" (getf report :full-check))))
")
  (:PATH
   #A((156) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read-failed.lisp")
   :BYTES 3454 :SHA256 "eae0cac8767cc9d938dc76e013f3b1c38db66646148c8dc5eeca262d85512294" :GIT-BLOB
   "6c61539d8511d7ce8c6c5f9ca84968daa6ed15bd" :TEXT
   ";;;; Lettura indipendente V3: dati e blob esistenti; nessun gate prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((audit-output (uiop:run-program
                      '(\"python3\" \"spikes/out/worker-c1-final-integration-audit.py\")
                      :output :string :error-output :string))
       (audit (read-from-string audit-output))
       (id \"4000550386-command-90070-0\")
       (path (format nil \"spikes/out/~A/report.lisp\" id))
       (record (arcdocdb.evidence:read-evidence path))
       (lines (remove-if-not
                (lambda (line)
                  (and (< (length line) 400)
                       (not (uiop:string-prefix-p \"ok    \" line))
                       (some (lambda (word) (search word line))
                             '(\"test superati\" \"file, \" \" REQ,\" \"link\" \"nessun avviso\"))))
                (uiop:split-string (getf record :stdout) :separator '(#\\Newline)))))
  (assert (eq (getf record :status) :ok))
  (assert (eq (getf record :source-consistency) :stable))
  (assert (= (getf record :exit-code) 0))
  (assert (equal (getf record :command) '(\"make\" \"check\")))
  (dolist (entry (getf audit :worker-identity))
    (dolist (side '(:source-blobs-before :source-blobs-after))
      (let ((snapshot (find (getf entry :path) (getf record side)
                            :test #'string= :key (lambda (v) (getf v :path)))))
        (assert snapshot)
        (assert (string= (getf snapshot :git-blob) (getf entry :git-blob))))))
  (let ((report (list :schema-version 1 :kind :independent-c1-final-integration-addendum
                      :scope :v3-source-and-existing-record-reading
                      :baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      :upstream \"e07d77271758f3134b1977caf394fe38532b54ed\"
                      :previous-reports-preserved t :audit audit
                      :reader-python-sha256
                      (arcdocdb.evidence:file-sha256 \"spikes/out/worker-c1-final-integration-audit.py\")
                      :full-check (list :process id :path path
                                        :sha256 (arcdocdb.evidence:file-sha256 path)
                                        :status (getf record :status)
                                        :source-consistency (getf record :source-consistency)
                                        :exit-code (getf record :exit-code)
                                        :wall-seconds (getf record :wall-seconds)
                                        :stdout-summary lines)
                      :limits '(:no-source-or-document-edit :no-product-test-rerun
                                :scoped-worker-campaigns-retain-cf60913
                                :prior-doc-snapshots-retain-their-own-records
                                :no-new-coverage-or-mcdc-qualification
                                :no-whole-pool-or-series-controller-qualification))))
    (with-open-file (output \"spikes/out/worker-c1-final-integration-addendum.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&WORKER-C1-V3-READ-PASS: 20 unchanged execution/test/tool files; ~D upstream blobs; 101 exact originals.~%\"
            (getf audit :upstream-preserved-file-count))
    (format t \"~&~S~%\" (getf report :full-check))))
")
  (:PATH
   #A((149) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum-read.lisp")
   :BYTES 3947 :SHA256 "899f6c5683045a374292d8c999b8cd5830a00be6583bc415445986389b35133a" :GIT-BLOB
   "9941c25e995485782b0ca947c369b43365c0be93" :TEXT
   ";;;; Lettura indipendente V3: dati e blob esistenti; nessun gate prodotto.
(require :asdf)
(load \"tools/evidence-storage.lisp\")
(setf *read-eval* nil)
(let* ((audit-output (uiop:run-program
                      '(\"python3\" \"spikes/out/worker-c1-final-integration-audit.py\")
                      :output :string :error-output :output))
       (audit (read-from-string audit-output))
       (id \"4000550386-command-90070-0\")
       (path (format nil \"spikes/out/~A/report.lisp\" id))
       (record (arcdocdb.evidence:read-evidence path))
       (lines (remove-if-not
                (lambda (line)
                  (and (< (length line) 400)
                       (not (uiop:string-prefix-p \"ok    \" line))
                       (some (lambda (word) (search word line))
                             '(\"test superati\" \"file, \" \" REQ,\" \"link\" \"nessun avviso\"))))
                (uiop:split-string (getf record :stdout) :separator '(#\\Newline)))))
  (assert (eq (getf record :status) :ok))
  (assert (eq (getf record :source-consistency) :stable))
  (assert (= (getf record :exit-code) 0))
  (assert (equal (last (getf record :command) 2) '(\"make\" \"check-core\")))
  (assert (string= (first (getf record :command)) \"env\"))
  (dolist (entry (getf audit :worker-identity))
    (dolist (side '(:source-blobs-before :source-blobs-after))
      (let ((snapshot (find (getf entry :path) (getf record side)
                            :test #'string= :key (lambda (v) (getf v :path)))))
        (assert snapshot)
        (assert (string= (getf snapshot :git-blob) (getf entry :git-blob))))))
  (let ((report (list :schema-version 1 :kind :independent-c1-final-integration-addendum
                      :scope :v3-source-and-existing-record-reading
                      :baseline \"cf6091367853ec311fed7b05961a2812fd05a8f1\"
                      :upstream \"e07d77271758f3134b1977caf394fe38532b54ed\"
                      :previous-reports-preserved t :audit audit
                      :reader-attempts-preserved
                      '((\"4000550739-command-16126-0\" :failed :stable :path-alias-normalization)
                        (\"4000550806-command-19882-0\" :failed :stable :mutable-wt-document-assumption)
                        (\"4000550861-command-22217-0\" :failed :stable :command-wrapper-assumption))
                      :reader-python-sha256
                      (arcdocdb.evidence:file-sha256 \"spikes/out/worker-c1-final-integration-audit.py\")
                      :full-check (list :process id :path path
                                        :sha256 (arcdocdb.evidence:file-sha256 path)
                                        :command (getf record :command)
                                        :status (getf record :status)
                                        :source-consistency (getf record :source-consistency)
                                        :exit-code (getf record :exit-code)
                                        :wall-seconds (getf record :wall-seconds)
                                        :stdout-summary lines)
                      :limits '(:no-source-or-document-edit :no-product-test-rerun
                                :scoped-worker-campaigns-retain-cf60913
                                :prior-doc-snapshots-retain-their-own-records
                                :no-new-coverage-or-mcdc-qualification
                                :no-whole-pool-or-series-controller-qualification))))
    (with-open-file (output \"spikes/out/worker-c1-final-integration-addendum.lisp\"
                            :direction :output :if-exists :error :external-format :utf-8)
      (let ((*print-readably* t)) (write report :stream output :pretty t) (terpri output)))
    (format t \"~&WORKER-C1-V3-READ-PASS: 20 unchanged execution/test/tool files; ~D upstream blobs; 101 exact originals.~%\"
            (getf audit :upstream-preserved-file-count))
    (format t \"~&~S~%\" (getf report :full-check))))
")
  (:PATH
   #A((144) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-addendum.lisp")
   :BYTES 13245 :SHA256 "2b26eb2b1d95ba7267232bf710b896d2c22b72a395f3eadf1a76d7d5ceb2697c"
   :GIT-BLOB "755279c173ec4c117eb65e0c5b46e0bb9d2f9966" :TEXT
   "(:SCHEMA-VERSION 1 :KIND :INDEPENDENT-C1-FINAL-INTEGRATION-ADDENDUM :SCOPE
 :V3-SOURCE-AND-EXISTING-RECORD-READING :BASELINE
 \"cf6091367853ec311fed7b05961a2812fd05a8f1\" :UPSTREAM
 \"e07d77271758f3134b1977caf394fe38532b54ed\" :PREVIOUS-REPORTS-PRESERVED T
 :AUDIT
 (:SCHEMA-VERSION 1 :KIND \"independent-worker-v3-byte-audit\" :BASELINE
  \"cf6091367853ec311fed7b05961a2812fd05a8f1\" :UPSTREAM
  \"e07d77271758f3134b1977caf394fe38532b54ed\" :WORKER-IDENTITY
  ((:PATH \"src/execution/handoff.lisp\" :SHA256
    \"ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607\"
    :GIT-BLOB \"a030e7af1afd6db760088f74615fe2396d928b64\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/package.lisp\" :SHA256
    \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
    :GIT-BLOB \"cdc776ff97c2b500b3b8a802a3b1e0e69fc19cee\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/queue.lisp\" :SHA256
    \"244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90\"
    :GIT-BLOB \"bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/ready-recycle.lisp\" :SHA256
    \"2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b\"
    :GIT-BLOB \"58981c7e41ce2694dbfcaed99010a3a53e3c1dea\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/ready-types.lisp\" :SHA256
    \"0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f\"
    :GIT-BLOB \"5b3c26f78d5c4aa53ca200abdd3e0f753f926b54\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/ready.lisp\" :SHA256
    \"a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327\"
    :GIT-BLOB \"4119f86231b7d8698fc3558868ff8a5bcbdf3090\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/worker-boundary.lisp\" :SHA256
    \"4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a\"
    :GIT-BLOB \"720f16e96203f00e308727b430b66b28689dc7bb\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/worker-claim.lisp\" :SHA256
    \"62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e\"
    :GIT-BLOB \"4f34d18152d77fbf63bf708ebd0aabac178c3ac1\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/worker-run.lisp\" :SHA256
    \"60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847\"
    :GIT-BLOB \"b1137f303cb707f8bf322f9deea764f716424d77\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/worker-types.lisp\" :SHA256
    \"62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317\"
    :GIT-BLOB \"6d36e1f64d79f24c95209fd70551953e40c62335\" :EQUAL-TO-V1 T)
   (:PATH \"src/execution/writer.lisp\" :SHA256
    \"8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105\"
    :GIT-BLOB \"8e5102497f628796fa8faffa2085a165496af230\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/handoff.lisp\" :SHA256
    \"7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e\"
    :GIT-BLOB \"ba702352ee63241b9ac993b0aca8f162c3deef1b\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/queue.lisp\" :SHA256
    \"fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722\"
    :GIT-BLOB \"546d4215f9f63007f632c522f0f8c1e75ac4bbeb\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/ready-recycle.lisp\" :SHA256
    \"c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae\"
    :GIT-BLOB \"1dff8707436ca52f20f62e9946621ca1037f33d2\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/ready.lisp\" :SHA256
    \"4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e\"
    :GIT-BLOB \"9f81552333f86fe0b20f2d5e8ba48b20634f5a09\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/support.lisp\" :SHA256
    \"2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43\"
    :GIT-BLOB \"b8bac07926727a644f0246f6b57d600332288310\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/threads.lisp\" :SHA256
    \"e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359\"
    :GIT-BLOB \"4212f8cc4be686e923cdbec9ded24f42f1da74ba\" :EQUAL-TO-V1 T)
   (:PATH \"tests/execution/worker.lisp\" :SHA256
    \"ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06\"
    :GIT-BLOB \"2a14573906b94b254712a1e9322058ec1081f6f8\" :EQUAL-TO-V1 T)
   (:PATH \"tools/writer-worker-bench.lisp\" :SHA256
    \"aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1\"
    :GIT-BLOB \"1208ddc9971179fc3fcb9300a9ba3c22fcd4a8b9\" :EQUAL-TO-V1 T)
   (:PATH \"tools/writer-worker-mutation.lisp\" :SHA256
    \"5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c\"
    :GIT-BLOB \"568bccdb1229b124e43e5c1b756cf726ead6fcbc\" :EQUAL-TO-V1 T))
  :EXECUTION-FOUNDATION-CSN-UPSTREAM-UNCHANGED T
  :MERGED-ASD-UPSTREAM-PLUS-WORKERS-ONLY T
  :MERGED-README-UPSTREAM-PLUS-WORKER-ROW-ONLY T :MERGED-FILES
  ((:PATH \"arcdocdb.asd\" :SHA256
    \"2a164afdd524e601320b8094e5d25aeb5c3dba081da8157f5849802cd9d28185\"
    :GIT-BLOB \"e3a6fbb33dfa82eb0022d444fa1a37f63442e938\")
   (:PATH \"docs/affidabilita/copertura-eccezioni.md\" :SHA256
    \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    :GIT-BLOB \"fdb928d6caf051a0341c162d537ca5d6351acfd9\")
   (:PATH \"docs/implementazione/README.md\" :SHA256
    \"cfde5ccb1980c15f27f13e0f81db9a574168505cee411c4d93a213d55285eb77\"
    :GIT-BLOB \"c8380f6b19b90d349f21d0a6ff8c880317ce08c1\")
   (:PATH \"src/execution/package.lisp\" :SHA256
    \"bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643\"
    :GIT-BLOB \"cdc776ff97c2b500b3b8a802a3b1e0e69fc19cee\"))
  :UPSTREAM-PRESERVED-FILE-COUNT 3517 :UPSTREAM-GIT-BLOB-MANIFEST-SHA256
  \"7f34c5d424f7a2612befdbfb4697096a1afcf9e79ceeb2dc4805a8bec205e483\"
  :UPSTREAM-CONTRACT-DEPENDENCY-CHANGES
  ((:PATH \"src/codec/cbor-float-minimal.lisp\" :SHA256
    \"d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db\"
    :GIT-BLOB \"ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f\")
   (:PATH \"src/codec/cbor-minimal.lisp\" :SHA256
    \"33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449\"
    :GIT-BLOB \"761302dad1073c841397f6c88d595b114af8d9ef\")
   (:PATH \"src/codec/cbor-package.lisp\" :SHA256
    \"e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b\"
    :GIT-BLOB \"0d014e499f0862f13674bd934070c166c286f256\")
   (:PATH \"src/recovery/inventory-build.lisp\" :SHA256
    \"cc486c3dcb7e83656301a0bea59442f8e654543740b0d6950290450f5e2f415e\"
    :GIT-BLOB \"60057f6a50c657f016bee3c21c21911b582f86fe\")
   (:PATH \"src/recovery/inventory-query.lisp\" :SHA256
    \"8b151ca6e8cee66a4e9035398349e21f0f3b4d1fdb564557ed60d3cf52fe7bfb\"
    :GIT-BLOB \"47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4\")
   (:PATH \"src/recovery/inventory-types.lisp\" :SHA256
    \"df84220d8e679322bc1a68d9e279e25985e6a07d64c95782191d9085987624e9\"
    :GIT-BLOB \"68c357d2d522fcabe79284c540c2631e5fa87780\")
   (:PATH \"src/recovery/manifest-package.lisp\" :SHA256
    \"0575efe36245b73db5c99f53577f3ed17039b8b796fa1e9095bdb8a0c6cdc5dc\"
    :GIT-BLOB \"5405bd515df8b26b792bd0430c9ec3dbadce63e7\")
   (:PATH \"tests/codec/cbor-minimal-edges.lisp\" :SHA256
    \"67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70\"
    :GIT-BLOB \"c6f891dff335a37689ddbfabccf793d2e9f2f143\")
   (:PATH \"tests/codec/cbor-minimal-support.lisp\" :SHA256
    \"96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a\"
    :GIT-BLOB \"774e6cd0bec4a9d2242ad4dede878ffa2afca90c\")
   (:PATH \"tests/codec/cbor-minimal-threads.lisp\" :SHA256
    \"e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2\"
    :GIT-BLOB \"e613ea025c2a886cdae7fd5e119cf80593c6b72e\")
   (:PATH \"tests/codec/cbor-minimal.lisp\" :SHA256
    \"d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3\"
    :GIT-BLOB \"b863ace9a22e8b7508b7c9d8f91465ebfbcd4e98\")
   (:PATH \"tests/recovery/inventory-support.lisp\" :SHA256
    \"2c6e1e6fb7a641c17f08b9dc4f425c86b6feb03f871496d918a08215957bcb27\"
    :GIT-BLOB \"06eeff2101a97f9abdec6b6f14aa621c2fec29fd\")
   (:PATH \"tests/recovery/inventory.lisp\" :SHA256
    \"e6342511c85b67ba9f1bef190bbf141e7e2fbcb92005ea3e43851488988c7fb9\"
    :GIT-BLOB \"0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9\")
   (:PATH \"tools/cbor-minimal-bench.lisp\" :SHA256
    \"8dfc9320885be47cf7bc1a05ecbdc9c9c7796539ea5604560fdc5ea52bcdd123\"
    :GIT-BLOB \"fd85474e6bbc781a0e5df7c6df3a4891b4da29f7\")
   (:PATH \"tools/cbor-minimal-mutation.lisp\" :SHA256
    \"0e23b19b5665983b9b4e0943810245f6ce593051f73aeee0b08e4e0124c8ec41\"
    :GIT-BLOB \"f9400b3b12b5f31189c28b64782e29cf16e8b6e4\")
   (:PATH \"tools/foundation-coverage.lisp\" :SHA256
    \"6d5024519fc90c9e0a6ddc4bf7d59f6da4d558ae582a8fc8261837a943b619d2\"
    :GIT-BLOB \"554b840090373179043aa39dd6491cd35433552a\")
   (:PATH \"tools/foundation-mutation.lisp\" :SHA256
    \"88ce773e9c0f1c3c64cddb6a84f21df178228792d43a867df05f43609bdd1a1d\"
    :GIT-BLOB \"fd285d0ae73d312d7234a2a142d16897c9adbcf7\"))
  :COPY-RECEIPT-SHA256
  \"0d30128b2f5384e2a765c0c6b3894fc22aedbfdec5c0554846a1cdc357b3f92b\"
  :HISTORICAL-COPY-TARGETS-CHECKED 101 :MUTABLE-DOCUMENT-SNAPSHOTS
  ((:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md\"
    :HISTORICAL-SHA256
    \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    :CURRENT-SHA256
    \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    :UNCHANGED T)
   (:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md\"
    :HISTORICAL-SHA256
    \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    :CURRENT-SHA256
    \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    :UNCHANGED T)
   (:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md\"
    :HISTORICAL-SHA256
    \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
    :CURRENT-SHA256
    \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
    :UNCHANGED T)
   (:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md\"
    :HISTORICAL-SHA256
    \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
    :CURRENT-SHA256
    \"db82651f35f5a43b6fb96a4e3d8d79a3c06db4d936751f9a6ac0be629afabda1\"
    :UNCHANGED NIL)
   (:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md\"
    :HISTORICAL-SHA256
    \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
    :CURRENT-SHA256
    \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
    :UNCHANGED T)
   (:PATH
    \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md\"
    :HISTORICAL-SHA256
    \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    :CURRENT-SHA256
    \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    :UNCHANGED T))
  :PRIOR-REPORTS
  ((:PATH
    \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\"
    :SHA256 \"a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562\"
    :PRESERVED T)
   (:PATH
    \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\"
    :SHA256 \"bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df\"
    :PRESERVED T)
   (:PATH
    \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\"
    :SHA256 \"2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1\"
    :PRESERVED T)
   (:PATH
    \"spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\"
    :SHA256 \"2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed\"
    :PRESERVED T))
  :PREPARATION-SHA256
  \"fb334af1b40f16290d9bda5c3ff99597f511e18e0f7bebc7a7a27dd394623ffa\" :JUDGEMENT
  \"CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged.\"
  :LIMITS
  (\"byte and namespace/dependency review, not a second CBOR qualification\"
   \"no worker campaign rerun or new coverage/MC-DC inference\"
   \"no whole-pool liveness, wait/park, Series-fault or durability claim\"))
 :READER-ATTEMPTS-PRESERVED
 ((\"4000550739-command-16126-0\" :FAILED :STABLE :PATH-ALIAS-NORMALIZATION)
  (\"4000550806-command-19882-0\" :FAILED :STABLE
   :MUTABLE-WT-DOCUMENT-ASSUMPTION)
  (\"4000550861-command-22217-0\" :FAILED :STABLE :COMMAND-WRAPPER-ASSUMPTION))
 :READER-PYTHON-SHA256
 \"95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a\" :FULL-CHECK
 (:PROCESS \"4000550386-command-90070-0\" :PATH
  \"spikes/out/4000550386-command-90070-0/report.lisp\" :SHA256
  \"575d62253b6387a4bb9572465aafbfe4e800d018a69b0cc62c9e5f4450955d28\" :COMMAND
  (#A((3) BASE-CHAR . \"env\")
   #A((148) BASE-CHAR
      . \"XDG_CACHE_HOME=/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-cache\")
   #A((35) BASE-CHAR . \"SBCL=sbcl --dynamic-space-size 4096\")
   #A((4) BASE-CHAR . \"make\") #A((10) BASE-CHAR . \"check-core\"))
  :STATUS :OK :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :WALL-SECONDS
  164.552415d0 :STDOUT-SUMMARY
  (\"build e test: nessun avviso, tutti i controlli superati\"
   \"68 file, 0 violazioni\"
   \"sbcl --dynamic-space-size 4096 --script tools/check-links.lisp .\"
   \"232 file, 2044 link controllati, 0 rotti\"))
 :LIMITS
 (:NO-SOURCE-OR-DOCUMENT-EDIT :NO-PRODUCT-TEST-RERUN
  :SCOPED-WORKER-CAMPAIGNS-RETAIN-CF60913
  :PRIOR-DOC-SNAPSHOTS-RETAIN-THEIR-OWN-RECORDS
  :NO-NEW-COVERAGE-OR-MCDC-QUALIFICATION
  :NO-WHOLE-POOL-OR-SERIES-CONTROLLER-QUALIFICATION))
")
  (:PATH
   #A((156) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-2-failed.py")
   :BYTES 6692 :SHA256 "7cb25f61c01ff9650a2c5ad7a522eb01ffb9d45cae032066f85f8c4519050a00" :GIT-BLOB
   "2c7a93ff7c1579ccf6c2e3657ed6a20b73a34cb8" :TEXT
   "\"\"\"Independent, read-only V3 byte audit; no product import or execution.\"\"\"
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path.cwd().resolve()
V1 = Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6')
CF = 'cf6091367853ec311fed7b05961a2812fd05a8f1'
UPSTREAM = 'e07d77271758f3134b1977caf394fe38532b54ed'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def blob(path):
    return git('hash-object', '--', str(path)).decode().strip()

def sexp(value):
    if value is None or value is False:
        return 'NIL'
    if value is True:
        return 'T'
    if isinstance(value, str):
        assert '\\n' not in value and '\\r' not in value
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '(' + ' '.join(map(sexp, value)) + ')'
    if isinstance(value, dict):
        return '(' + ' '.join(':' + k.replace('_', '-').upper() + ' ' + sexp(v)
                              for k, v in value.items()) + ')'
    raise TypeError(type(value))

assert git('rev-parse', 'HEAD').decode().strip() == UPSTREAM
paths = sorted(p.relative_to(V1).as_posix() for d in ('src/execution', 'tests/execution')
               for p in (V1 / d).glob('*.lisp'))
paths += ['tools/writer-worker-bench.lisp', 'tools/writer-worker-mutation.lisp']
assert len(paths) == 20
identity = []
for p in paths:
    expected = sha(V1 / p)
    assert sha(ROOT / p) == expected, p
    identity.append(dict(path=p, sha256=expected, git_blob=blob(ROOT / p), equal_to_v1=True))
assert not git('diff', '--name-only', CF, UPSTREAM, '--', 'src/execution',
               'tests/execution', 'src/foundation', 'src/csn', 'src/package.lisp')

# The merged files are exactly upstream plus the previously reviewed worker entries.
asd = (ROOT / 'arcdocdb.asd').read_bytes()
worker_asd = b'(:file \"ready-recycle\")\\n                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))'
assert asd.count(worker_asd) == 1
restored = asd.replace(worker_asd, b'(:file \"ready-recycle\")))')
worker_test = b'(:file \"ready-recycle\") (:file \"worker\")))'
assert restored.count(worker_test) == 1
restored = restored.replace(worker_test, b'(:file \"ready-recycle\")))')
assert restored == git('show', UPSTREAM + ':arcdocdb.asd')
readme = (ROOT / 'docs/implementazione/README.md').read_bytes()
worker_row = b'| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n'
assert readme.count(worker_row) == 1
assert readme.replace(worker_row, b'') == git('show', UPSTREAM + ':docs/implementazione/README.md')

# Every upstream tracked file, including upstream evidence, is retained byte for byte;
# the four intentional worker-owned replacements are checked separately or recorded.
exceptions = {'arcdocdb.asd', 'docs/implementazione/README.md',
              'src/execution/package.lisp', 'docs/affidabilita/copertura-eccezioni.md'}
tree = git('ls-tree', '-r', '-z', UPSTREAM).split(b'\\0')
upstream = []
for entry in tree:
    if not entry:
        continue
    metadata, raw_path = entry.split(b'\\t', 1)
    mode, kind, expected = metadata.decode().split()
    assert kind == 'blob'
    p = raw_path.decode()
    if p not in exceptions:
        upstream.append((p, expected))
names = ''.join(p + '\\n' for p, _ in upstream).encode()
actual = subprocess.check_output(['git', 'hash-object', '--stdin-paths'], input=names,
                                 cwd=ROOT).decode().splitlines()
assert len(actual) == len(upstream)
for (p, expected), got in zip(upstream, actual):
    assert expected == got, p
manifest = ''.join(p + '\\t' + h + '\\n' for p, h in upstream).encode()
changed = git('diff', '--name-only', CF, UPSTREAM, '--', 'src', 'tests', 'tools').decode().splitlines()
upstream_changes = [dict(path=p, sha256=sha(ROOT / p), git_blob=blob(ROOT / p)) for p in changed]

receipt_path = ROOT / 'spikes/out/worker-final-v3-copy-receipt.json'
receipt = json.loads(receipt_path.read_text())
assert len(receipt['files']) == 101
targets = set()
for entry in receipt['files']:
    target = Path(entry['target']).resolve()
    assert target.is_relative_to(ROOT)
    assert str(target) not in targets
    targets.add(str(target))
    assert sha(target) == entry['sha256'], str(target)
    assert sha(entry['source']) == entry['sha256'], entry['source']
prior_reports = []
for basename, expected in [
    ('revisione-indipendente-iniziale.lisp', 'a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562'),
    ('revisione-indipendente-iniziale-chiusa.lisp', 'bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df'),
    ('revisione-indipendente-finale.lisp', '2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1'),
    ('revisione-indipendente-integrazione.lisp', '2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed')]:
    p = ROOT / 'spikes/results/2026-10-09-writer-worker' / basename
    assert sha(p) == expected, basename
    prior_reports.append(dict(path=p.relative_to(ROOT).as_posix(), sha256=expected, preserved=True))

report = dict(schema_version=1, kind='independent-worker-v3-byte-audit',
              baseline=CF, upstream=UPSTREAM, worker_identity=identity,
              execution_foundation_csn_upstream_unchanged=True,
              merged_asd_upstream_plus_workers_only=True,
              merged_readme_upstream_plus_worker_row_only=True,
              merged_files=[dict(path=p, sha256=sha(ROOT/p), git_blob=blob(ROOT/p))
                            for p in sorted(exceptions)],
              upstream_preserved_file_count=len(upstream),
              upstream_git_blob_manifest_sha256=hashlib.sha256(manifest).hexdigest(),
              upstream_contract_dependency_changes=upstream_changes,
              copy_receipt_sha256=sha(receipt_path), copied_originals_checked=101,
              prior_reports=prior_reports,
              preparation_sha256=sha(ROOT/'spikes/out/worker-final-integration-preparation.json'),
              judgement='CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged.',
              limits=['byte and namespace/dependency review, not a second CBOR qualification',
                      'no worker campaign rerun or new coverage/MC-DC inference',
                      'no whole-pool liveness, wait/park, Series-fault or durability claim'])
print(sexp(report))
")
  (:PATH
   #A((156) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-attempt-3-failed.py")
   :BYTES 7148 :SHA256 "95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a" :GIT-BLOB
   "cb196ccbf43f31930d0195cbbd2350bc5a245aff" :TEXT
   "\"\"\"Independent, read-only V3 byte audit; no product import or execution.\"\"\"
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path.cwd().resolve()
V1 = Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6')
CF = 'cf6091367853ec311fed7b05961a2812fd05a8f1'
UPSTREAM = 'e07d77271758f3134b1977caf394fe38532b54ed'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def blob(path):
    return git('hash-object', '--', str(path)).decode().strip()

def sexp(value):
    if value is None or value is False:
        return 'NIL'
    if value is True:
        return 'T'
    if isinstance(value, str):
        assert '\\n' not in value and '\\r' not in value
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '(' + ' '.join(map(sexp, value)) + ')'
    if isinstance(value, dict):
        return '(' + ' '.join(':' + k.replace('_', '-').upper() + ' ' + sexp(v)
                              for k, v in value.items()) + ')'
    raise TypeError(type(value))

assert git('rev-parse', 'HEAD').decode().strip() == UPSTREAM
paths = sorted(p.relative_to(V1).as_posix() for d in ('src/execution', 'tests/execution')
               for p in (V1 / d).glob('*.lisp'))
paths += ['tools/writer-worker-bench.lisp', 'tools/writer-worker-mutation.lisp']
assert len(paths) == 20
identity = []
for p in paths:
    expected = sha(V1 / p)
    assert sha(ROOT / p) == expected, p
    identity.append(dict(path=p, sha256=expected, git_blob=blob(ROOT / p), equal_to_v1=True))
assert not git('diff', '--name-only', CF, UPSTREAM, '--', 'src/execution',
               'tests/execution', 'src/foundation', 'src/csn', 'src/package.lisp')

# The merged files are exactly upstream plus the previously reviewed worker entries.
asd = (ROOT / 'arcdocdb.asd').read_bytes()
worker_asd = b'(:file \"ready-recycle\")\\n                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))'
assert asd.count(worker_asd) == 1
restored = asd.replace(worker_asd, b'(:file \"ready-recycle\")))')
worker_test = b'(:file \"ready-recycle\") (:file \"worker\")))'
assert restored.count(worker_test) == 1
restored = restored.replace(worker_test, b'(:file \"ready-recycle\")))')
assert restored == git('show', UPSTREAM + ':arcdocdb.asd')
readme = (ROOT / 'docs/implementazione/README.md').read_bytes()
worker_row = b'| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n'
assert readme.count(worker_row) == 1
assert readme.replace(worker_row, b'') == git('show', UPSTREAM + ':docs/implementazione/README.md')

# Every upstream tracked file, including upstream evidence, is retained byte for byte;
# the four intentional worker-owned replacements are checked separately or recorded.
exceptions = {'arcdocdb.asd', 'docs/implementazione/README.md',
              'src/execution/package.lisp', 'docs/affidabilita/copertura-eccezioni.md'}
tree = git('ls-tree', '-r', '-z', UPSTREAM).split(b'\\0')
upstream = []
for entry in tree:
    if not entry:
        continue
    metadata, raw_path = entry.split(b'\\t', 1)
    mode, kind, expected = metadata.decode().split()
    assert kind == 'blob'
    p = raw_path.decode()
    if p not in exceptions:
        upstream.append((p, expected))
names = ''.join(p + '\\n' for p, _ in upstream).encode()
actual = subprocess.check_output(['git', 'hash-object', '--stdin-paths'], input=names,
                                 cwd=ROOT).decode().splitlines()
assert len(actual) == len(upstream)
for (p, expected), got in zip(upstream, actual):
    assert expected == got, p
manifest = ''.join(p + '\\t' + h + '\\n' for p, h in upstream).encode()
changed = git('diff', '--name-only', CF, UPSTREAM, '--', 'src', 'tests', 'tools').decode().splitlines()
upstream_changes = [dict(path=p, sha256=sha(ROOT / p), git_blob=blob(ROOT / p)) for p in changed]

receipt_path = ROOT / 'spikes/out/worker-final-v3-copy-receipt.json'
receipt = json.loads(receipt_path.read_text())
assert len(receipt['files']) == 101
targets = set()
mutable_document_snapshots = []
for entry in receipt['files']:
    target = Path(entry['target']).resolve()
    assert target.is_relative_to(ROOT)
    assert str(target) not in targets
    targets.add(str(target))
    assert sha(target) == entry['sha256'], str(target)
    source = Path(entry['source'])
    current = sha(source)
    mutable_wt_doc = source.suffix == '.md' and 'writer-worker/ArcDocDB/docs/' in source.as_posix()
    if mutable_wt_doc:
        mutable_document_snapshots.append(dict(path=str(source), historical_sha256=entry['sha256'], current_sha256=current, unchanged=current == entry['sha256']))
    else:
        assert current == entry['sha256'], entry['source']
prior_reports = []
for basename, expected in [
    ('revisione-indipendente-iniziale.lisp', 'a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562'),
    ('revisione-indipendente-iniziale-chiusa.lisp', 'bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df'),
    ('revisione-indipendente-finale.lisp', '2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1'),
    ('revisione-indipendente-integrazione.lisp', '2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed')]:
    p = ROOT / 'spikes/results/2026-10-09-writer-worker' / basename
    assert sha(p) == expected, basename
    prior_reports.append(dict(path=p.relative_to(ROOT).as_posix(), sha256=expected, preserved=True))

report = dict(schema_version=1, kind='independent-worker-v3-byte-audit',
              baseline=CF, upstream=UPSTREAM, worker_identity=identity,
              execution_foundation_csn_upstream_unchanged=True,
              merged_asd_upstream_plus_workers_only=True,
              merged_readme_upstream_plus_worker_row_only=True,
              merged_files=[dict(path=p, sha256=sha(ROOT/p), git_blob=blob(ROOT/p))
                            for p in sorted(exceptions)],
              upstream_preserved_file_count=len(upstream),
              upstream_git_blob_manifest_sha256=hashlib.sha256(manifest).hexdigest(),
              upstream_contract_dependency_changes=upstream_changes,
              copy_receipt_sha256=sha(receipt_path), historical_copy_targets_checked=101,
              mutable_document_snapshots=mutable_document_snapshots,
              prior_reports=prior_reports,
              preparation_sha256=sha(ROOT/'spikes/out/worker-final-integration-preparation.json'),
              judgement='CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged.',
              limits=['byte and namespace/dependency review, not a second CBOR qualification',
                      'no worker campaign rerun or new coverage/MC-DC inference',
                      'no whole-pool liveness, wait/park, Series-fault or durability claim'])
print(sexp(report))
")
  (:PATH
   #A((146) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit-failed.py")
   :BYTES 6682 :SHA256 "432d3a4c29b827f7c99a1d01a00794fa95302e582fe40c90112bbbf89e73f992" :GIT-BLOB
   "132fe7aafccc791c78c10ac92cf1845798782fe4" :TEXT
   "\"\"\"Independent, read-only V3 byte audit; no product import or execution.\"\"\"
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path.cwd().resolve()
V1 = Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6')
CF = 'cf6091367853ec311fed7b05961a2812fd05a8f1'
UPSTREAM = 'e07d77271758f3134b1977caf394fe38532b54ed'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def blob(path):
    return git('hash-object', '--', str(path)).decode().strip()

def sexp(value):
    if value is None or value is False:
        return 'NIL'
    if value is True:
        return 'T'
    if isinstance(value, str):
        assert '\\n' not in value and '\\r' not in value
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '(' + ' '.join(map(sexp, value)) + ')'
    if isinstance(value, dict):
        return '(' + ' '.join(':' + k.replace('_', '-').upper() + ' ' + sexp(v)
                              for k, v in value.items()) + ')'
    raise TypeError(type(value))

assert git('rev-parse', 'HEAD').decode().strip() == UPSTREAM
paths = sorted(p.relative_to(V1).as_posix() for d in ('src/execution', 'tests/execution')
               for p in (V1 / d).glob('*.lisp'))
paths += ['tools/writer-worker-bench.lisp', 'tools/writer-worker-mutation.lisp']
assert len(paths) == 20
identity = []
for p in paths:
    expected = sha(V1 / p)
    assert sha(ROOT / p) == expected, p
    identity.append(dict(path=p, sha256=expected, git_blob=blob(ROOT / p), equal_to_v1=True))
assert not git('diff', '--name-only', CF, UPSTREAM, '--', 'src/execution',
               'tests/execution', 'src/foundation', 'src/csn', 'src/package.lisp')

# The merged files are exactly upstream plus the previously reviewed worker entries.
asd = (ROOT / 'arcdocdb.asd').read_bytes()
worker_asd = b'(:file \"ready-recycle\")\\n                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))'
assert asd.count(worker_asd) == 1
restored = asd.replace(worker_asd, b'(:file \"ready-recycle\")))')
worker_test = b'(:file \"ready-recycle\") (:file \"worker\")))'
assert restored.count(worker_test) == 1
restored = restored.replace(worker_test, b'(:file \"ready-recycle\")))')
assert restored == git('show', UPSTREAM + ':arcdocdb.asd')
readme = (ROOT / 'docs/implementazione/README.md').read_bytes()
worker_row = b'| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n'
assert readme.count(worker_row) == 1
assert readme.replace(worker_row, b'') == git('show', UPSTREAM + ':docs/implementazione/README.md')

# Every upstream tracked file, including upstream evidence, is retained byte for byte;
# the four intentional worker-owned replacements are checked separately or recorded.
exceptions = {'arcdocdb.asd', 'docs/implementazione/README.md',
              'src/execution/package.lisp', 'docs/affidabilita/copertura-eccezioni.md'}
tree = git('ls-tree', '-r', '-z', UPSTREAM).split(b'\\0')
upstream = []
for entry in tree:
    if not entry:
        continue
    metadata, raw_path = entry.split(b'\\t', 1)
    mode, kind, expected = metadata.decode().split()
    assert kind == 'blob'
    p = raw_path.decode()
    if p not in exceptions:
        upstream.append((p, expected))
names = ''.join(p + '\\n' for p, _ in upstream).encode()
actual = subprocess.check_output(['git', 'hash-object', '--stdin-paths'], input=names,
                                 cwd=ROOT).decode().splitlines()
assert len(actual) == len(upstream)
for (p, expected), got in zip(upstream, actual):
    assert expected == got, p
manifest = ''.join(p + '\\t' + h + '\\n' for p, h in upstream).encode()
changed = git('diff', '--name-only', CF, UPSTREAM, '--', 'src', 'tests', 'tools').decode().splitlines()
upstream_changes = [dict(path=p, sha256=sha(ROOT / p), git_blob=blob(ROOT / p)) for p in changed]

receipt_path = ROOT / 'spikes/out/worker-final-v3-copy-receipt.json'
receipt = json.loads(receipt_path.read_text())
assert len(receipt['files']) == 101
targets = set()
for entry in receipt['files']:
    target = Path(entry['target'])
    assert target.is_relative_to(ROOT)
    assert str(target) not in targets
    targets.add(str(target))
    assert sha(target) == entry['sha256'], str(target)
    assert sha(entry['source']) == entry['sha256'], entry['source']
prior_reports = []
for basename, expected in [
    ('revisione-indipendente-iniziale.lisp', 'a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562'),
    ('revisione-indipendente-iniziale-chiusa.lisp', 'bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df'),
    ('revisione-indipendente-finale.lisp', '2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1'),
    ('revisione-indipendente-integrazione.lisp', '2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed')]:
    p = ROOT / 'spikes/results/2026-10-09-writer-worker' / basename
    assert sha(p) == expected, basename
    prior_reports.append(dict(path=p.relative_to(ROOT).as_posix(), sha256=expected, preserved=True))

report = dict(schema_version=1, kind='independent-worker-v3-byte-audit',
              baseline=CF, upstream=UPSTREAM, worker_identity=identity,
              execution_foundation_csn_upstream_unchanged=True,
              merged_asd_upstream_plus_workers_only=True,
              merged_readme_upstream_plus_worker_row_only=True,
              merged_files=[dict(path=p, sha256=sha(ROOT/p), git_blob=blob(ROOT/p))
                            for p in sorted(exceptions)],
              upstream_preserved_file_count=len(upstream),
              upstream_git_blob_manifest_sha256=hashlib.sha256(manifest).hexdigest(),
              upstream_contract_dependency_changes=upstream_changes,
              copy_receipt_sha256=sha(receipt_path), copied_originals_checked=101,
              prior_reports=prior_reports,
              preparation_sha256=sha(ROOT/'spikes/out/worker-final-integration-preparation.json'),
              judgement='CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged.',
              limits=['byte and namespace/dependency review, not a second CBOR qualification',
                      'no worker campaign rerun or new coverage/MC-DC inference',
                      'no whole-pool liveness, wait/park, Series-fault or durability claim'])
print(sexp(report))
")
  (:PATH
   #A((139) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit.py")
   :BYTES 7148 :SHA256 "95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a" :GIT-BLOB
   "cb196ccbf43f31930d0195cbbd2350bc5a245aff" :TEXT
   "\"\"\"Independent, read-only V3 byte audit; no product import or execution.\"\"\"
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path.cwd().resolve()
V1 = Path('/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6')
CF = 'cf6091367853ec311fed7b05961a2812fd05a8f1'
UPSTREAM = 'e07d77271758f3134b1977caf394fe38532b54ed'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def blob(path):
    return git('hash-object', '--', str(path)).decode().strip()

def sexp(value):
    if value is None or value is False:
        return 'NIL'
    if value is True:
        return 'T'
    if isinstance(value, str):
        assert '\\n' not in value and '\\r' not in value
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, list):
        return '(' + ' '.join(map(sexp, value)) + ')'
    if isinstance(value, dict):
        return '(' + ' '.join(':' + k.replace('_', '-').upper() + ' ' + sexp(v)
                              for k, v in value.items()) + ')'
    raise TypeError(type(value))

assert git('rev-parse', 'HEAD').decode().strip() == UPSTREAM
paths = sorted(p.relative_to(V1).as_posix() for d in ('src/execution', 'tests/execution')
               for p in (V1 / d).glob('*.lisp'))
paths += ['tools/writer-worker-bench.lisp', 'tools/writer-worker-mutation.lisp']
assert len(paths) == 20
identity = []
for p in paths:
    expected = sha(V1 / p)
    assert sha(ROOT / p) == expected, p
    identity.append(dict(path=p, sha256=expected, git_blob=blob(ROOT / p), equal_to_v1=True))
assert not git('diff', '--name-only', CF, UPSTREAM, '--', 'src/execution',
               'tests/execution', 'src/foundation', 'src/csn', 'src/package.lisp')

# The merged files are exactly upstream plus the previously reviewed worker entries.
asd = (ROOT / 'arcdocdb.asd').read_bytes()
worker_asd = b'(:file \"ready-recycle\")\\n                             (:file \"worker-types\") (:file \"worker-boundary\") (:file \"worker-claim\") (:file \"worker-run\")))'
assert asd.count(worker_asd) == 1
restored = asd.replace(worker_asd, b'(:file \"ready-recycle\")))')
worker_test = b'(:file \"ready-recycle\") (:file \"worker\")))'
assert restored.count(worker_test) == 1
restored = restored.replace(worker_test, b'(:file \"ready-recycle\")))')
assert restored == git('show', UPSTREAM + ':arcdocdb.asd')
readme = (ROOT / 'docs/implementazione/README.md').read_bytes()
worker_row = b'| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |\\n'
assert readme.count(worker_row) == 1
assert readme.replace(worker_row, b'') == git('show', UPSTREAM + ':docs/implementazione/README.md')

# Every upstream tracked file, including upstream evidence, is retained byte for byte;
# the four intentional worker-owned replacements are checked separately or recorded.
exceptions = {'arcdocdb.asd', 'docs/implementazione/README.md',
              'src/execution/package.lisp', 'docs/affidabilita/copertura-eccezioni.md'}
tree = git('ls-tree', '-r', '-z', UPSTREAM).split(b'\\0')
upstream = []
for entry in tree:
    if not entry:
        continue
    metadata, raw_path = entry.split(b'\\t', 1)
    mode, kind, expected = metadata.decode().split()
    assert kind == 'blob'
    p = raw_path.decode()
    if p not in exceptions:
        upstream.append((p, expected))
names = ''.join(p + '\\n' for p, _ in upstream).encode()
actual = subprocess.check_output(['git', 'hash-object', '--stdin-paths'], input=names,
                                 cwd=ROOT).decode().splitlines()
assert len(actual) == len(upstream)
for (p, expected), got in zip(upstream, actual):
    assert expected == got, p
manifest = ''.join(p + '\\t' + h + '\\n' for p, h in upstream).encode()
changed = git('diff', '--name-only', CF, UPSTREAM, '--', 'src', 'tests', 'tools').decode().splitlines()
upstream_changes = [dict(path=p, sha256=sha(ROOT / p), git_blob=blob(ROOT / p)) for p in changed]

receipt_path = ROOT / 'spikes/out/worker-final-v3-copy-receipt.json'
receipt = json.loads(receipt_path.read_text())
assert len(receipt['files']) == 101
targets = set()
mutable_document_snapshots = []
for entry in receipt['files']:
    target = Path(entry['target']).resolve()
    assert target.is_relative_to(ROOT)
    assert str(target) not in targets
    targets.add(str(target))
    assert sha(target) == entry['sha256'], str(target)
    source = Path(entry['source'])
    current = sha(source)
    mutable_wt_doc = source.suffix == '.md' and 'writer-worker/ArcDocDB/docs/' in source.as_posix()
    if mutable_wt_doc:
        mutable_document_snapshots.append(dict(path=str(source), historical_sha256=entry['sha256'], current_sha256=current, unchanged=current == entry['sha256']))
    else:
        assert current == entry['sha256'], entry['source']
prior_reports = []
for basename, expected in [
    ('revisione-indipendente-iniziale.lisp', 'a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562'),
    ('revisione-indipendente-iniziale-chiusa.lisp', 'bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df'),
    ('revisione-indipendente-finale.lisp', '2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1'),
    ('revisione-indipendente-integrazione.lisp', '2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed')]:
    p = ROOT / 'spikes/results/2026-10-09-writer-worker' / basename
    assert sha(p) == expected, basename
    prior_reports.append(dict(path=p.relative_to(ROOT).as_posix(), sha256=expected, preserved=True))

report = dict(schema_version=1, kind='independent-worker-v3-byte-audit',
              baseline=CF, upstream=UPSTREAM, worker_identity=identity,
              execution_foundation_csn_upstream_unchanged=True,
              merged_asd_upstream_plus_workers_only=True,
              merged_readme_upstream_plus_worker_row_only=True,
              merged_files=[dict(path=p, sha256=sha(ROOT/p), git_blob=blob(ROOT/p))
                            for p in sorted(exceptions)],
              upstream_preserved_file_count=len(upstream),
              upstream_git_blob_manifest_sha256=hashlib.sha256(manifest).hexdigest(),
              upstream_contract_dependency_changes=upstream_changes,
              copy_receipt_sha256=sha(receipt_path), historical_copy_targets_checked=101,
              mutable_document_snapshots=mutable_document_snapshots,
              prior_reports=prior_reports,
              preparation_sha256=sha(ROOT/'spikes/out/worker-final-integration-preparation.json'),
              judgement='CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged.',
              limits=['byte and namespace/dependency review, not a second CBOR qualification',
                      'no worker campaign rerun or new coverage/MC-DC inference',
                      'no whole-pool liveness, wait/park, Series-fault or durability claim'])
print(sexp(report))
")
  (:PATH
   #A((162) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-1-diagnostic.txt")
   :BYTES 431 :SHA256 "215634bf64c6359ec2860131f9766eb10a216db486fda17c1616ac644156d7fc" :GIT-BLOB
   "27b9180dfa4bac8340d821413109b9cf9194f6f9" :TEXT
   "Reader record 4000550739-command-16126-0 failed/STABLE/exit1. Independent direct diagnostic rerun exited1 at Python line96: assert target.is_relative_to(ROOT). ROOT resolved /var to /private/var; receipt target retained /var. This is a reader path-normalization defect, with no product execution or product defect. Both initial adapters preserved with -failed basename. Correction resolves receipt target before containment check.
")
  (:PATH
   #A((169) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stderr.log")
   :BYTES 459 :SHA256 "e46c940049af3038a33b87915231ce3604881b7ea479163bde0ed67d2f235239" :GIT-BLOB
   "495c5a48b0e8ac6bfebd69d562ffadc17e3ce47c" :TEXT "Traceback (most recent call last):
  File \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-audit.py\", line 100, in <module>
    assert sha(entry['source']) == entry['sha256'], entry['source']
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: /Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md
")
  (:PATH
   #A((169) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-c1-final-integration-reader-attempt-2-diagnostic.stdout.log")
   :BYTES 0 :SHA256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855" :GIT-BLOB
   "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :TEXT "")
  (:PATH
   #A((127) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-final-copy-receipt.json")
   :BYTES 45570 :SHA256 "5b51decda41c11af5d3b32107eecb56da4c2d54be324a7f9d5accb4e2735c345"
   :GIT-BLOB "fefc21c206b19f74e869998582fad3c0b703c936" :TEXT "{
  \"schema_version\": 1,
  \"kind\": \"verified-final-file-copy\",
  \"files\": [
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-metodo.md\",
      \"sha256\": \"e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker.md\",
      \"sha256\": \"404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-decisioni.md\",
      \"sha256\": \"d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-risultati.md\",
      \"sha256\": \"e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/implementazione/writer-worker-revisione.md\",
      \"sha256\": \"c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c\"
    },
    {
      \"source\": \"/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/docs/affidabilita/copertura-eccezioni.md\",
      \"sha256\": \"8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-dati.lisp\",
      \"sha256\": \"4232bc88eeb7cc9f1e72e8cb6ca8ba2696bb0f3fda34770f5f07f752423098a6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/allocazioni-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-processo-conservazione.lisp\",
      \"sha256\": \"3ebfebe658f973ae850eeba1997c124d8eced4b8ff7f8416a6ae64043586e642\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/allocazioni-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/allocazioni-processo.lisp\",
      \"sha256\": \"15fc3a6330fb864f5dc7db2c44441dec1a9966d557914632b74180518d463094\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/bench-self-test-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/bench-self-test-processo-conservazione.lisp\",
      \"sha256\": \"a0c37d16217c4e89397c9d37423a0001f80890b4e6e12b472707e35719677375\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/bench-self-test-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/bench-self-test-processo.lisp\",
      \"sha256\": \"ec9d32a97987f2042be25a0e7ab4e68f822ea43da6739af70da4bb5cb3f3e56c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/catalogo.lisp\",
      \"sha256\": \"56574cfbcffb69f61ff7b75e4d6f439342a39361c7ce92ba35e267c2b08e13aa\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/check-finale-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-finale-processo-conservazione.lisp\",
      \"sha256\": \"75110bd290cf658ac52deee29a8b50d15910a85a09088587b30049bf6dfaa2f2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-finale-processo.lisp\",
      \"sha256\": \"171017fb3a43f10b0ea2feef9edb49b099c188a8d54449dfd69ff390b56d09b3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/check-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"5485a142621e2c1bfc9f1defa6fd7f87215c3ee1f6617c5c4f6192eccc67bf25\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/check-integrazione-processo.lisp\",
      \"sha256\": \"4e4e60a07c35a3e4d95b1fd6db959bf2b836d2306e42bc6cd9c2341331c7d4d4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/chiusura-copia-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/chiusura-copia-adattatori.lisp\",
      \"sha256\": \"443440414aa2f1ef5aff571b4c405276defa0380a51cd49deea9b04e5292a945\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-export-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-export-processo-conservazione.lisp\",
      \"sha256\": \"3b684c3ee1b34972c11115dd87d8d2403449695949a423fc42239d16ac4c356f\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-export-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-export-processo.lisp\",
      \"sha256\": \"914ded890553fe32d461eadedd27a12db494cba057697069346bf75307bcbb9e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-grezza.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-grezza.lisp\",
      \"sha256\": \"787b1ad0604b98c46690dd4655638d7ff7de4d4cf5f71864235fdc4c5244f09b\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-html.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-html.lisp\",
      \"sha256\": \"0f5f772f71838a44c612cd1110a8f956a69488fa2b59cb8b433128e95efc3c49\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-native.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-native.lisp\",
      \"sha256\": \"6556c89d470b443591607229ad043a023d03c8f346258e048fc1a860e8a3a973\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-processo-conservazione.lisp\",
      \"sha256\": \"21ea48fc083f80c4f3a4f3f17d634eb2e1c0115fdbc8d06df9f395e1c9135ce6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/copertura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/copertura-processo.lisp\",
      \"sha256\": \"af3dfba084cbe52e87a3e1c59bc52daa95c50e021d2bc7a08544bfb64ee51306\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo-conservazione.lisp\",
      \"sha256\": \"34251a0b7c759c97409320374a8d558c8d99bebc630a9bc6213d893a4cd4d290\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-addendum-copia-processo.lisp\",
      \"sha256\": \"1c1efacd5ee4fd3b80be229bb90ad781d3d9761b6fa40481b2182d87f65f14ab\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo-conservazione.lisp\",
      \"sha256\": \"f7e13451481888b732167d82b4a7d2f989bbb3dc9a495b5c993fe43fd1c6de65\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-copia-processo.lisp\",
      \"sha256\": \"a609160ec3b296beb8a16b4905644912372dc5d05e8ac7dff2bd29cea0d725f6\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo-conservazione.lisp\",
      \"sha256\": \"7eac446c2490959543e638f0e4efeddcc6f37179ee86326b64b7905d6b435be4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/integrazione-summary-processo.lisp\",
      \"sha256\": \"22f4855e277788ab81000698a5d3aa496b3f8bb6d5a4f21bf4aea9f104ce1f00\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-dati.lisp\",
      \"sha256\": \"70fc8171b55f0e717eea23f9bad6033941739d40e715c45051df0d103bff8fd5\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-log.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-log.lisp\",
      \"sha256\": \"855afe77a12531115f864fc3b36d609ae608e5106bc8475f1131b701e173d91c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-processo-conservazione.lisp\",
      \"sha256\": \"74708fdcf432c4c5e3f329c58a4d3f94ab170fd5c85717cb97fceba845f3f6a5\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-processo.lisp\",
      \"sha256\": \"4aaa70d59881a6be3289a642bb7fbd9d7c3764b69c24807e7ff2c7133980a5b2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo-conservazione.lisp\",
      \"sha256\": \"e9e1c34b2ec99f350e3b505257d53b62b5675ccbac94114e2cb3282e5f758d54\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/mutazioni-self-test-processo.lisp\",
      \"sha256\": \"70ff3ff6ba4ba4d06772d66586c900297725ebf102c6ce1b71fa34c1fb68502a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/probe-root-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/probe-root-processo-conservazione.lisp\",
      \"sha256\": \"fc39b4e3a1384e449b472e2f43b4dbf1f2edd50abb3f8b704f19b9c42d0cd98e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/probe-root-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/probe-root-processo.lisp\",
      \"sha256\": \"c58a825e04c175e4f73215ea55d972b3301e86d88ca73f66c81d111ff20ef5d2\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-adattatori.lisp\",
      \"sha256\": \"f1895fcbeda3e687c47296bde314583a88f5cb2f8f9dadc2f946bb9aed7321a1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo-conservazione.lisp\",
      \"sha256\": \"876221f31ebd21e0054304106ba012b121e82f685e6614f474473faa3b3944e3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-processo.lisp\",
      \"sha256\": \"c90cdc6d99e6af765b517e7b4944bf6eb6719e6cea5cb7de81b929262d7fe6aa\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo-conservazione.lisp\",
      \"sha256\": \"413e9c390289e5741ffdab6fe37f32102fe5671471ac9955756687fd2a76539d\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-chiusura-registrazione-processo.lisp\",
      \"sha256\": \"07c0940cefd02b9efad91db323a6236c83e580b37c48c0ec2ed573567d0593c9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo-conservazione.lisp\",
      \"sha256\": \"1b6df4d427a5677d6e189d996d3cdd525db0c5d6fb8924c1e307186925bf41af\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fallita-processo.lisp\",
      \"sha256\": \"be18d788d301be3a946461ed58d60e02f6bc96b570f18d6aeb73878953eed0ba\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-dati.lisp\",
      \"sha256\": \"37cd88ea5c80df5a2fba6e2142fcce971f8168ec0d0f8c97864929eaf92c4354\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo-conservazione.lisp\",
      \"sha256\": \"b5e29180721602708cad16c95c734d85a2aaad033557ef9f725be3f005a05ad3\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-fallito-processo.lisp\",
      \"sha256\": \"aeed0ef5c8c2ce6664bb0a6dc264c33b7f09ab765246152df52b65f849c6a905\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo-conservazione.lisp\",
      \"sha256\": \"52576b5d72b100679eeb7a5d6efeb44e5f4b8da16947ee6477d0e07691d95496\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-processo.lisp\",
      \"sha256\": \"ea1d081db0e8a93c8d6a651f18b7a8f83c452fca1b1e64d28cb96e06e1e92fc8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo-conservazione.lisp\",
      \"sha256\": \"4b9dd954673af056b7cd98ecedcadd3851310775cd83113b3f9c2f29dfeb0c5c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-fix-audit-summary-processo.lisp\",
      \"sha256\": \"5f5e2439bdae533ca3d24e6a5f4c59a66b1b630aca4ad6bd5c781f17ff456366\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo-conservazione.lisp\",
      \"sha256\": \"ac8d88a1b9c02e4f223d64991b16308e4aa60ec0793a905b1307faeccaa76f99\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-processo.lisp\",
      \"sha256\": \"c05ffe3e4724ac39908ad1b107bc2384e439ffc4822781765e60704c3c32a42a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-tentativo-non-registrato.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-piano-tentativo-non-registrato.lisp\",
      \"sha256\": \"5f029a76a814cc6f03819376e260b6774c659502dbe0370194d769987b64e4c0\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo-conservazione.lisp\",
      \"sha256\": \"a8823abc6d3a690b517f815b3d15136ffdef2e677ea049658206ee94b7439556\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-heap-fallita-processo.lisp\",
      \"sha256\": \"36e47daedd1744fe6eea0a9bb4f8a1b8e633124dcb4c16efc900c2630938fa32\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo-conservazione.lisp\",
      \"sha256\": \"9e1286ac4e613f095e7f8df804853fb745600736e2a1659e0b273e37fd0a2df9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/pubblicazione-ripresa-load-processo.lisp\",
      \"sha256\": \"6a273caa381d83107588a05b1850629a3406112aa29652b2248a428d116cbe7a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/report.lisp.gz\",
      \"sha256\": \"aaba2220d5294a6e0cd801d5febfd87ca78befaf2f131c1a52a690db827e8392\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-autore-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore-processo-conservazione.lisp\",
      \"sha256\": \"57d993040da7e9870dc886fa345f47d43224f94f8aca622bf3153efefd1d65c8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-autore-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore-processo.lisp\",
      \"sha256\": \"8bd7ad9527dc49385528733db0b99f1bb80aa41130aac71fd9c764cfa08de4da\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-autore.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-autore.lisp\",
      \"sha256\": \"d4bdbc05a589cb7507cc6ee4b72d40130be85a99648ae57b3bb2d74391231ce9\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-copertura-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-dati.lisp\",
      \"sha256\": \"4c65d6987f0fc2ce2518540376a1734a1f7b1f310c612337e0de4d424381de75\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo-conservazione.lisp\",
      \"sha256\": \"ec88d0bf3a3f89460f9ba66d506b41ae23839058605b997298ac05c79530573a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-copertura-processo.lisp\",
      \"sha256\": \"631ac966196a07fd161c28b9c6d79ecc803acb8bf1b4bbf6c3f9993f411ca612\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp\",
      \"sha256\": \"2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp\",
      \"sha256\": \"bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp\",
      \"sha256\": \"a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"2c3991f87d5c390ef83210d309045939b21281257251dfac201b1fe40e9ed531\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione-processo.lisp\",
      \"sha256\": \"3a36b8111e8b40860c50338b0990c9f871530f18ab53ac1dc68abf6432b2e616\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp\",
      \"sha256\": \"2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-dati.lisp\",
      \"sha256\": \"e10ee76a04038205aa6ca09d24e1b216fdd06639d36567ac9104ea73cd95beca\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo-conservazione.lisp\",
      \"sha256\": \"ccb6692a8c146addab2cfa455aa7e96dfbf101ef4b23ded279d42bf7a1ca508c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-mappa-sorgenti-processo.lisp\",
      \"sha256\": \"b81a0041f825264331c676356dee01eb8a37ebd639543afb64aa1ede04cde1d4\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-risultati-integrale.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-risultati-integrale.lisp\",
      \"sha256\": \"c88c40d199f36ca86f70202121832d595f5cb4024b43a9456593a2b227272f64\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-risultati-sommario.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-risultati-sommario.lisp\",
      \"sha256\": \"d5ca85c807ddf39a56e5ddfe39bfac690ebd1eb3e8a8730bd500859e903d0dd1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo-conservazione.lisp\",
      \"sha256\": \"90b5c57beb3d2e3c9dfc281446efeed1a12c4cd50c0f3a72b96d4c7e4eb6c76e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-fallito-processo.lisp\",
      \"sha256\": \"a6d184a6685a97f91f92c3b3689c402ad3bc923ce5ccdc74df4f7df6fc8126dc\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-summary-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-processo-conservazione.lisp\",
      \"sha256\": \"6192429edcf100b72c1423379f581ff31ae6a0bfdf3ad723343f370ce6215054\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/revisione-summary-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/revisione-summary-processo.lisp\",
      \"sha256\": \"bc247fa56e69336cb1e081a050b000df740a263892df2d44d803f1f9f40ffa15\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo-conservazione.lisp\",
      \"sha256\": \"d3b5f9fab296f7a54c07465d09dc5462327c55d8ab56bd9f623683700585c690\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/scope-integrazione-processo.lisp\",
      \"sha256\": \"ffcd3fd9830e3be2bc340da7a1169f528f89df91781b33b6b1a2ad261aaad7a8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/segnale-os-dati.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/segnale-os-dati.lisp\",
      \"sha256\": \"da3fcae536b154fb44927130fa3575cadaddeb05596e2d1e6e3e25acceef5fb0\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/segnale-os-originali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/segnale-os-originali.lisp\",
      \"sha256\": \"6e05e3647c77f5dc332dd3f2759880cd6ee5f96881085c5009d7cfa4db1396ae\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/sorgenti-adattatori.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/sorgenti-adattatori.lisp\",
      \"sha256\": \"69b783d43230d6355c160dcdcc8ea9bc999ec8a1e1fb471fd22fb727d3d88972\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/spikes-finali-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/spikes-finali-conservazione.lisp\",
      \"sha256\": \"90216eae4885f944b80c3e08a5be9d86474d269e18de1a0cfd7c9edf84dad8ed\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/spikes-finali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/spikes-finali.lisp\",
      \"sha256\": \"90842512f964d56cb118a615e40351f4a2769f5c8f21005e8af4717f45f5c431\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo-conservazione.lisp\",
      \"sha256\": \"d0a9dcb743cc57645c1397e81d1be584e9b2795fd39d10f99b57094c9c709918\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/strict-iniziale-storico-processo.lisp\",
      \"sha256\": \"b3e80eb7f7aa53c19746f67a3543fd9a150ee21a6bd9608dda89b32b371859cb\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker/worker-review-results-data.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker/worker-review-results-data.lisp.gz\",
      \"sha256\": \"40a2992e077e06d6ad8e5d73d1cf2dc3313e9d7c25cb1cd7ffe5ca70af83b25a\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/catalogo.lisp\",
      \"sha256\": \"3be41dc908bfa081b17c20fb87816fb0cdef675a112bbde61458690b34e00728\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-integration/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/report.lisp.gz\",
      \"sha256\": \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-integration/spikes-finali-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/spikes-finali-conservazione.lisp\",
      \"sha256\": \"a63c64bb6adb8ac9cf45aedb65410c501c5f7e02ad0de2c47a23eb6755826472\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-integration/spikes-finali.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-integration/spikes-finali.lisp\",
      \"sha256\": \"ff0d10e261cd1190966bf642982e655d31d37bc53a4bcf387f673223eec764b8\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-review/catalogo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/catalogo.lisp\",
      \"sha256\": \"0e418772c1493fff9e00ac82ab5fcf5e5874697a68e6b5f797871a9eb691f7e1\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-review/report.lisp.gz\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/report.lisp.gz\",
      \"sha256\": \"a21a27d791a0820baf6729e6860882d85831a6f37daedc159ebb3bb2d104d92c\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo-conservazione.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo-conservazione.lisp\",
      \"sha256\": \"03fa19348d2b9a67c5fb88e881a49a72a1c07f790048014c5f50c86a6989ed8e\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/results/2026-10-09-writer-worker-review/revisione-risultati-processo.lisp\",
      \"sha256\": \"ce27e18256fb99a2529cc11db06ea33938cb6ba98da1fb08ce1949500695180f\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-publication-functions.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-publication-functions.lisp\",
      \"sha256\": \"01ce7104faa1905afa2f6b48a03bee04c176ee4c9f68e16ddb1ff435d70a028b\"
    },
    {
      \"source\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-refresh-catalog.lisp\",
      \"target\": \"/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/worker-refresh-catalog.lisp\",
      \"sha256\": \"836fd4b47889108a40bde0f478ad5fdc6534d59c9092fa9234f9a363414e23e3\"
    }
  ]
}
")
  (:PATH
   #A((126) BASE-CHAR
      . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/worker-publication-attach-own.lisp")
   :BYTES 370 :SHA256 "d4d3490429116d0713f4775e5c53957634ea6b38801ef61063e8d352ae4b2bd1" :GIT-BLOB
   "556fff3048ff1528e7fc304915575d750f4ba710" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(worker-copy-process \"4000550214-command-77908-0\" \"pubblicazione-chiusura-registrazione-processo\")
(worker-refresh-catalog \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
 :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"))
(format t \"SELF RECORD CONSERVED; canonical ready for final frozen integration.~%\")
")))
