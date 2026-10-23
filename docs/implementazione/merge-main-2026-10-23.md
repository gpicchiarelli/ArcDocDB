# Integrazione in main — metodo del 2026-10-23

Richiesta dell'autore: integrare tutti i branch in `main`, commit e push.
Inventario dopo fetch: `main` e `codex/production-engine-bootstrap`, con
le corrispondenti ref remote. Le modifiche locali completate agli indici
sono conservate nel commit `9ca79617`; il ramo di produzione termina a
`9bd23360`. I checkout detached non costituiscono branch.

## Metodo preregistrato

- Unione dei moduli ASDF, delle 57 suite e dei sette casi esclusi soltanto
  dalla strumentazione coverage; nessuna esclusione nella verifica normale.
- Due letture dell'integratore: conflitti e contenuti rispetto a entrambi
  i parent, poi dipendenze, registrazione dei test e stato documentale.
  Revisione indipendente prima della chiusura del merge.
- Commit del merge prima delle prove; tutti gli agenti chiusi prima
  di compilazione e diagnostica. Sorgenti e documenti invariati durante
  ogni comando registrato.
- Tutti i controlli di `make check-core` in tre gruppi indipendenti:
  compilazione rigorosa e catalogo completo del prodotto; lint, strumenti,
  link, tracciabilita', autoverifica CI e 11 spike; inventario delle evidenze
  con quattro worker. Cache ASDF private distinte, ereditate dai figli,
  e comandi tramite `tools/record-command.lisp`. Il catalogo conserva anche
  inventario ed eventi; i log originali dei processi Unix sono trattenuti
  per la raccolta verificata. Nessun benchmark o confronto prestazionale.
- Conservazione dei record originali, anche falliti, e degli output
  strutturati; compressione lossless dei file grandi. Nessuna modifica
  degli archivi storici chiusi. Annotazione finale separata dai run.
- Prima del push: assenza di conflitti e modifiche pendenti, ogni ref
  di branch inventariata antenata di `main`. Push senza riscrittura della
  storia e verifica dello SHA remoto. Eventuali commit automatici dei
  risultati CI sono trattati come avanzamenti concorrenti di `main`.

## Limiti

La verifica e' locale su macOS ARM64 e non qualifica Linux, power loss,
MC/DC o prestazioni. I risultati precedenti mantengono la propria revisione
e il proprio perimetro; il merge non chiude i gate funzionali ancora aperti.

## Revisione statica

La revisione indipendente ha confermato l'unione di ASDF, catalogo,
autoverifiche e limiti coverage, senza perdite del codice dei due parent.
Ha rilevato un riferimento obsoleto a listener e client nella roadmap:
corretto distinguendo il profilo M1 disponibile dal contratto M16 esteso.
Nessuna prova eseguita dagli agenti; revisore chiuso prima dei run.

## Esito dell'integrazione

Il merge `3cf27d3655cb9bf14b0f1cc9fbb371ef18eb2b3b` ha superato i tre
gruppi preregistrati con exit 0, sorgenti stabili e medesima revisione:
**2241/2241 test in 57 suite**, nessuna esclusione o prova non eseguita;
lint, tracciabilita', link, strumenti, autoverifica CI, 11 spike di
correttezza e inventario storico delle evidenze. La campagna Unix compresa
nella suite ha verificato 74 processi e quattro SIGKILL, nei formati v1/v2.

Le [evidenze dell'integrazione](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-merge-main/report.md)
conservano record, inventario ed eventi dei test, log e dati originali.
La raccolta comune ha verificato l'inventario chiuso; solo dopo il confronto
dei byte e degli hash sono stati rimossi fixture e cache private della sessione.
Gli archivi precedenti sono invariati. Ricevute della raccolta, controlli
finali e pulizia sono conservati separatamente, senza una catena infinita
di ricevute che contengano il proprio comando di creazione.

Questa annotazione e il README sono successivi ai run; il codice di
prodotto, i test, gli strumenti e ASDF sono invariati rispetto al merge
verificato. Link, trace e inclusione delle ref sono controllati di nuovo
prima del commit delle evidenze e del push.
