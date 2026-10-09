(:SCHEMA-VERSION 1 :KIND :FINAL-COPY-ADAPTERS :SOURCES
 ((:PATH #A((47) BASE-CHAR . "spikes/out/worker-publication-attach-close.lisp") :BYTES 568 :SHA256
   "f29c5f1bcb08d0dea38d64fa32f28d3b753679ac74d3f3b07886260a1b0156ec" :GIT-BLOB
   "8c6d61d3a1133f6912ba1cb019d147073f5d3d51" :TEXT
   "(load \"spikes/out/worker-publication-functions.lisp\")
(worker-copy-process \"4000550124-command-70928-0\" \"pubblicazione-chiusura-processo\")
(worker-save-source-bundle '(\"spikes/out/worker-publication-attach-close.lisp\" \"/tmp/arcdocdb-worker-copy-final.py\")
 (merge-pathnames \"chiusura-copia-adattatori.lisp\" *worker-publication-directory*) :final-copy-adapters)
(worker-refresh-catalog \"e2f7a75f3c7a45dffd91343b91d3a889fc3ee056\"
 :historical-bases '(\"cf6091367853ec311fed7b05961a2812fd05a8f1\"))
(format t \"CLOSURE RECORD ATTACHED; byte-validated catalog refreshed.~%\")
")
  (:PATH #A((34) BASE-CHAR . "/tmp/arcdocdb-worker-copy-final.py") :BYTES 1433 :SHA256
   "3b0d1c8467d8a5f2299f034e1a6356ad882e6d1508e0064455a929d80a8adcb3" :GIT-BLOB
   "8026053b4604e779573a7f307212362a7c46131d" :TEXT "from pathlib import Path
import json, hashlib, shutil
p=Path('/tmp/arcdocdb-worker-state.json'); s=json.loads(p.read_text())
v=Path(s['verification']); integ=Path(s['integration']); w=Path(s['source'])
records=[]
def digest(f): return hashlib.sha256(f.read_bytes()).hexdigest()
for rel in s['owned_files']:
 if rel.startswith('docs/') and rel!='docs/implementazione/README.md':
  src=w/rel; dst=integ/rel; before=digest(src);shutil.copy2(src,dst)
  assert before==digest(src)==digest(dst);records.append({'source':str(src),'target':str(dst),'sha256':before})
for rel in s['evidence_dirs']:
 src=v/rel;dst=integ/rel
 assert src.is_dir() and not dst.exists(), str(dst)
 shutil.copytree(src,dst)
 for a in sorted(src.iterdir()):
  b=dst/a.name;before=digest(a);assert before==digest(a)==digest(b)
  records.append({'source':str(a),'target':str(b),'sha256':before})
for name in ['worker-publication-functions.lisp','worker-refresh-catalog.lisp']:
 src=v/'spikes/out'/name;dst=integ/'spikes/out'/name
 assert not dst.exists();shutil.copy2(src,dst);assert digest(src)==digest(dst)
 records.append({'source':str(src),'target':str(dst),'sha256':digest(src)})
receipt=integ/'spikes/out/worker-final-copy-receipt.json'
assert not receipt.exists();receipt.write_text(json.dumps({'schema_version':1,'kind':'verified-final-file-copy','files':records},indent=2)+'\\n')
print('Copied and compared',len(records),'final files to integrated snapshot')
")))
