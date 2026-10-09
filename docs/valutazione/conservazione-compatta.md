# Conservazione compatta delle prove

## Metodo registrato prima dell'esecuzione — 2026-10-09

La campagna riduce lo spazio dei registri senza modificarne i byte originali.
Non misura prestazioni del database. Non riscrive la cronologia Git.

1. Seleziona i file `.lisp` superiori a 1 MiB in `spikes/results/`.
2. Esegue `gzip -n -9 -c` senza shell, con quattro worker indipendenti. Il
   nome e il timestamp originali non entrano nell'header gzip.
3. Conserva nello stesso percorso un descriptor schema 1, di tipo
   `:compressed-evidence`, e accanto il payload `.lisp.gz`.
4. Registra dimensioni e SHA-256 dei byte compressi e originali. Ricostruisce
   il contenuto con un limite di 128 MiB, verifica gli hash, ricontrolla che
   l'originale non sia cambiato e pubblica il descriptor con rename nella
   stessa directory. Su errore conserva l'originale e rimuove solo i file
   temporanei creati dal tentativo.
5. Verifica che ogni riferimento dei cataloghi restituisca ancora una sola
   plist, letta con `*read-eval* nil`. Verifica link, struttura, integrità e
   dimensioni. Conserva anche ogni tentativo fallito.

L'originale deve essere immutabile durante la compattazione. Il lock coordina
solo i compattatori; non blocca altri programmi che scrivono nel registro.
La pubblicazione per rename non promette persistenza dopo perdita di corrente.
Il limite di espansione limita i byte, non il costo del lettore Lisp. Un file
con sintassi malformata viene rifiutato. I record sono dati del repository,
non un formato di importazione per input arbitrario.

## Controlli preregistrati

I controlli includono equivalenza dei dati plain/gzip, byte UTF-8, hash e
dimensioni errati, payload mancante, archivi troncati, espansione oltre budget,
path fuori directory, valutazione del lettore, più forme e descriptor annidati.
Il lettore verifica il payload prima di interpretarne i dati. Rimuove i file
temporanei anche quando la callback fallisce.

`make evidence` rifiuta qualsiasi file pubblicato non gzip oltre 1 MiB e
qualsiasi payload gzip oltre 8 MiB, inclusi quelli non catalogati. Il catalogo
mantiene i percorsi precedenti, così i link rimangono validi. Un descriptor
non è il risultato della prova: occorre risolverlo con il lettore.

## Comandi e consultazione

```sh
make compact-evidence
make evidence-selftest evidence links
sbcl --script tools/read-evidence.lisp spikes/results/2026-10-08-lettura/spikes-verifica.lisp
```

Il lettore richiede SBCL, `gzip` e `shasum`. Per ottenere i byte originali
senza interpretarli si può decomprimere il payload con `gzip -dc`, verificando
poi dimensione e SHA-256 dichiarati nel descriptor. La funzione
`arcdocdb.evidence:call-with-evidence-bytes` automatizza queste verifiche.

`record-command.lisp` e `run-spikes.lisp` compattano automaticamente la
propria directory al termine del run, dopo l'ultima scrittura e fuori dalle
finestre misurate. Il registro `conservazione.lisp` conserva argv, esito e
stdout/stderr del compattatore. Su errore la verifica termina con esito
negativo e conserva diagnostica e originali; non perde il risultato del comando.

Anche i risultati locali già terminati possono essere compattati. Prima si
verifica che nessun processo stia scrivendo nei file selezionati; il filtro
di età da solo non dimostra che una campagna sia terminata.
Il compattatore esclude anche le directory standard dei run il cui PID esiste
ancora. Solo il registratore proprietario può dichiarare finita la propria
directory prima di terminare; l'eccezione controlla il PID del processo padre.

```sh
sbcl --script tools/record-command.lisp -- sbcl --script tools/compact-evidence.lisp --root spikes/out/ --jobs 4 --minimum-age-seconds 3600
```

La compattazione locale conserva i byte anche quando il report storico contiene
simboli di package non caricati. L'interpretazione successiva di quei simboli
richiede lo stesso contesto del report precedente; nessun package viene
caricato automaticamente dal lettore delle prove.

## Dimensioni e cronologia

Il rapporto registra numero di file, byte originali, byte conservati incluso
il descriptor e tempo wall. Il wrapper conserva ambiente, argv, hash dei
sorgenti e stdout/stderr. Il tempo comprende compressione e verifiche ed è
influenzato dal carico esterno; non è un benchmark del motore.

Gli oggetti dei commit precedenti rimangono nella cronologia. Git li conserva
già compressi: le dimensioni dei file estratti e quelle di `.git` sono diverse.
La compattazione riduce checkout e nuovi artefatti, mantenendo i commit già
pubblicati e i loro identificatori.

## Risultati locali — 2026-10-09

| Campagna | File | Byte originali | Byte conservati, descriptor incluso | Worker |
|---|---:|---:|---:|---:|
| [Registri pubblicati](../../spikes/results/2026-10-09-conservazione/compattazione-pubblicati.lisp) | 23 | 450.439.355 | 16.140.279 | 4 |
| [Run locali terminati](../../spikes/results/2026-10-09-conservazione/compattazione-locali.lisp) | 30 | 680.385.168 | 21.184.119 | 4 |

Sono stati rimossi 1.093.500.125 byte dalle rappresentazioni non compresse,
conservando tutti i byte originali nei payload verificati. I due registri da
58.455.285 e 58.455.167 byte hanno payload gzip da 935.253 e 935.119 byte;
con descriptor di 327 e 335 byte rispettivamente. Non sono dimensioni della
cronologia Git. I nuovi record di questa campagna occupano spazio aggiuntivo.

La [verifica finale completa](../../spikes/results/2026-10-09-conservazione/verifica-finale.lisp)
ha sorgenti stabili ed esito `:ok`: 151 test del motore, 40 casi e 123
asserzioni del lettore, due controlli negativi sui limiti di pubblicazione,
linter, tracciabilità, link e cataloghi. La
[campagna dei dieci spike](../../spikes/results/2026-10-09-conservazione/spikes-verifica-finale.lisp)
conserva argv, sorgenti, output ed esiti dei processi. La sua
[conservazione automatica](../../spikes/results/2026-10-09-conservazione/conservazione-spikes-finale.lisp)
è registrata separatamente; il master conserva i risultati di tutti i figli
senza un ulteriore composito che ne duplichi i report.

I tentativi falliti rimangono nel
[catalogo](../../spikes/results/2026-10-09-conservazione/catalogo.lisp): errore
di sintassi nel primo harness di controllo, esaurimento dell'heap nel lettore
che duplicava tutto il testo e due errori negli strumenti temporanei di
pubblicazione. Il lettore corretto interpreta i report direttamente dal file;
non crea più una stringa integrale UTF-8 prima del parsing. I controlli
aggiunti verificano anche record di sei byte, il budget esatto e un file plain
con token che imitano il marker di un descriptor. Le diagnostiche originali
non sono abbreviate nei record conservati.

L'importatore `normalize-spike-report.lisp` usa lo stesso lettore per gli input
plain e compressi. Il controllo di compatibilità verifica anche che `RESULT`
e `STATUS`, aggiunti durante l'importazione, rimangano nelle plist pubblicate;
la precedente iterazione perdeva la nuova testa della plist. Sei asserzioni
aggiuntive confrontano risultati e metadata dei due percorsi. Sono incluse
in `make evidence-selftest` e nel controllo completo.

La [verifica dopo l'integrazione delle code writer](../../spikes/results/2026-10-09-conservazione/verifica-integrazione.lisp)
è eseguita sul commit `4362110`, con sorgenti stabili: 168 test del motore,
123 asserzioni del lettore, sei dell'importatore, due controlli sui limiti,
tutti i controlli del repository e la
[campagna integrata dei dieci spike](../../spikes/results/2026-10-09-conservazione/spikes-integrazione.lisp).
L'[importazione inizialmente fallita](../../spikes/results/2026-10-09-conservazione/importazione-fallita.lisp)
e il [controllo dopo la correzione](../../spikes/results/2026-10-09-conservazione/importazione-verificata.lisp)
conservano anche la regressione della testa della plist.

La [verifica del merge finale con il recovery radix](../../spikes/results/2026-10-09-conservazione/verifica-main.lisp)
passa sul commit `4fa8df2`, con sorgenti stabili: 186 test del motore e tutti
i controlli precedenti, inclusa la
[campagna finale](../../spikes/results/2026-10-09-conservazione/spikes-main.lisp).
Sono compattati anche i nuovi registri del radix e i run locali terminati
durante lo sviluppo parallelo; i rispettivi rapporti sono nel catalogo.
