# Archivio storico esterno

> **Deciso — [ADR-0061](../../docs/adr/0061-conservazione-esterna-delle-prove.md),
> successiva riduzione Git in [ADR-0062](../../docs/adr/0062-cronologia-git-due-commit.md).**

Lo snapshot alla revisione `fea3c113514c804a0daf13251a146c687cc3953c` conserva
**52.277 file originali**, inclusi i sottoprodotti inclusi negli inventari chiusi.
I byte non sono stati riscritti. Nel checkout corrente restano le sintesi recenti;
le citazioni storiche puntano all'identico albero conservato nel nuovo commit radice
`13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78`. La prima migrazione non ha riscritto
la storia; la successiva manutenzione autorizzata mantiene due commit e un backup esterno.

[Release con archivio e inventario SHA-256](https://github.com/gpicchiarelli/ArcDocDB/releases/tag/evidence-2026-10-23-fea3c113).
Il [manifesto locale](snapshot.lisp) registra identità, dimensioni e hash.

| Oggetto | SHA-256 |
|---|---|
| `results-fea3c113.tar.zst` | `aa1ac178eb931e97cdf45e596d7ff85c5f3114ef94635fbe857bcdf55a36f182` |
| `inventory.sha256` | `61514c583a88afe90890bbb4483f1db539e36aaac86c1f118c8b2d7e9aaba071` |
| TAR decompresso | `5a2df702ef3f0864e88ed21d800f7af321ea67f8b774bd8f1a6d9d26738a9a40` |

## Recupero e verifica

Servono `gh`, `zstd`, `tar`, `shasum` e SBCL. Usare una directory separata dal
checkout: l'estrazione completa ricrea circa 1,4 GiB e oltre 52.000 file.
Il download e l'estrazione non avvengono durante `make evidence`.

```sh
mkdir -p /tmp/arcdocdb-evidence-download /tmp/arcdocdb-evidence-restored
gh release download evidence-2026-10-23-fea3c113 --repo gpicchiarelli/ArcDocDB --pattern results-fea3c113.tar.zst --pattern inventory.sha256 --dir /tmp/arcdocdb-evidence-download
cd /tmp/arcdocdb-evidence-download
shasum -a 256 results-fea3c113.tar.zst inventory.sha256
```

Confrontare entrambi gli hash con la tabella **prima di estrarre**. Quindi:

```sh
zstd -dc results-fea3c113.tar.zst | tar -xf - -C /tmp/arcdocdb-evidence-restored
cd /tmp/arcdocdb-evidence-restored
shasum -a 256 --strict --status -c /tmp/arcdocdb-evidence-download/inventory.sha256
```

L'uscita zero verifica tutti i file rispetto all'inventario. Si può poi eseguire,
dalla propria copia di ArcDocDB, il verificatore storico sulla directory estratta:

```sh
sbcl --script tools/check-evidence.lisp --root /tmp/arcdocdb-evidence-restored/spikes/results/
```

I registri Lisp sono **dati**, mai argomenti di `load`. Il lettore
`tools/read-evidence.lisp` gestisce i descriptor gzip originali.
L'asset è stato riletto da GitHub e i suoi hash sono stati confrontati con la copia
locale verificata. Questo protegge l'integrità; non garantisce la disponibilità
perpetua del servizio esterno. Per lavoro offline conservarne una copia separata.

## Nuove pubblicazioni

Conservare nel repository sintesi, parametri, identità sorgenti e SHA-256 dei raw.
Pubblicare e rileggere l'asset prima di eliminare la copia locale. Non forzare in Git
`.fasl`, `.tmp`, `.bytes`, cache ASDF o copie complete delle directory di lavoro.
La raccolta C4 esistente continua a creare archivi locali chiusi: la selezione
per la pubblicazione avviene dopo la verifica, senza cambiarne gli originali.

## Cronologia Git precedente

Il [manifesto della manutenzione](history.lisp) registra il collegamento fra
vecchia e nuova radice. L'albero della radice è identico; i metadati delle prove
conservano le SHA delle esecuzioni originali. Il tag della release punta alla
nuova radice e i nomi degli asset continuano a identificare lo snapshot originario.

La cronologia precedente completa è nell'asset `history-before-e97b823d.bundle`,
225.295.869 byte, SHA-256
`94b1a368a35ffef76b64ca4474a0c63b388ae57bd2e16b0bc7372a96e6c6d1dd`.
Bundle e hash sono stati riletti da GitHub prima della sostituzione delle ref.
Per ripristinarli in una nuova directory:

```sh
mkdir -p /tmp/arcdocdb-git-history
gh release download evidence-2026-10-23-fea3c113 --repo gpicchiarelli/ArcDocDB --pattern 'history-before-e97b823d.bundle*' --dir /tmp/arcdocdb-git-history
cd /tmp/arcdocdb-git-history
shasum -a 256 -c history-before-e97b823d.bundle.sha256
git clone --branch main history-before-e97b823d.bundle restored
```

Il backup esterno permette il recupero; non mantiene i vecchi commit raggiungibili
nelle ref correnti del repository. Il primo dei due stati conservati contiene
ancora i raw storici, quindi la sola riduzione della cronologia non li elimina dagli oggetti Git.
