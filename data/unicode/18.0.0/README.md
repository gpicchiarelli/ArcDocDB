# Unicode 18.0.0 — provenienza

Dati originali Unicode, acquisiti il 16 ottobre 2026 dall'archivio ufficiale
[UCD.zip](https://www.unicode.org/Public/18.0.0/ucd/UCD.zip).
I percorsi nella tabella sono relativi a
[`https://www.unicode.org/Public/18.0.0/ucd/`](https://www.unicode.org/Public/18.0.0/ucd/).
`LICENSE.txt` proviene da [Unicode License V3](https://www.unicode.org/license.txt).
I file originali mantengono contenuto e avvisi di copyright; non sono dati applicativi.

| File | SHA256 |
|---|---|
| `UnicodeData.txt` | `0736451de439ae7baf1425136617da495e09ee5afbe6e394374db7009ea08950` |
| `CaseFolding.txt` | `a004797658a457bec4dc11683e39f69249ea3b595b752dbea6721c4c9f587b0d` |
| `DerivedNormalizationProps.txt` | `98ac7f67d985fe781e317f6182e885e94cabb0c314769e6dd73e48b226931ccd` |
| `NormalizationTest.txt` | `25a50d816764b04abfb4a646d3eb2b2a803284c3873d9a06757b94fe4513dde3` |
| `ReadMe.txt` | `b0ea442f29dee90584aacd3665a6e1ce87ffc917a4d31f34e1916d2d6f7f9205` |
| `auxiliary/WordBreakProperty.txt` | `8dbfa17063e11084201f33c3e76d485d3b9166930c71db8e39ed1c9234171aec` |
| `auxiliary/WordBreakTest.txt` | `3dd70c071781276067c680d87303f60434adce7b067bd063194af374edad86a5` |
| `emoji/emoji-data.txt` | `80d00f8e616a0ef27fd6b8de3b758c06383b5d917e2977709578e68baf733bf1` |
| `LICENSE.txt` | `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96` |

Il generatore Common Lisp [fulltext-unicode-tables.lisp](../../../tools/fulltext-unicode-tables.lisp)
produce [unicode-tables.lisp](../../../src/fulltext/unicode-tables.lisp), SHA256
`334d8f05af5ebdd5bbcfddc96af61af95e02208b23eeebf381269a9e4cbe14a9`.
Il comando seguente verifica la riproducibilita senza cambiare il sorgente:

```sh
sbcl --script tools/fulltext-unicode-tables.lisp --check data/unicode/18.0.0/ src/fulltext/unicode-tables.lisp
```

Le tabelle includono categorie L/N, classi combinanti, decomposizioni canoniche,
esclusioni di composizione, case folding C/F, Word_Break ed Extended_Pictographic.
Hangul usa l'algoritmo della norma. I corpus di normalizzazione e Word_Break sono
letti dai test ASDF; non occorre scaricare dati o accedere alla rete per eseguirli.
