# SPK-08: CRC32C ARM64 con estensioni SBCL

Preregistrazione del 2026-10-23. Domanda: ottenere checksum compatibili con
il CRC32C slicing-by-8 del prodotto attraverso istruzioni ARM64 generate
da Common Lisp, mantenendo safety 3 e zero allocazioni osservate sul percorso
caldo. Nessuna libreria foreign, pinning, SAP conservato o GC disabilitato.
I sorgenti dello spike non vengono promossi nel prodotto.

## Protocollo

Prima si verificano assembler e backend SBCL installati e si conserva il
sorgente upstream usato come riferimento. L'istruzione Castagnoli usa CRC32C,
non CRC32 IEEE. L'accumulatore interno non è finalizzato; seme e risultato
pubblici devono mantenere la convenzione del prodotto (XOR con #xffffffff).
Il caricamento dei byte deve mantenere controlli attivi sui range e un
riferimento GC valido, anche per offset non allineati. Nessuna istruzione
nativa viene eseguita senza rilevamento della feature della CPU.

Correttezza: oracolo bitwise indipendente e implementazione software corrente;
vettore standard 123456789; dimensioni 0..128, 255/256/257, 4095/4096/4097,
65535/65536/65537, offset 0..15, semi 0/#xffffffff/#x12345678. Confronto
incrementale per ogni punto di split su buffer piccoli, più frontiere dei
blocchi sui grandi; input immutato, esclusione dei byte fuori range,
rifiuto degli intervalli invalidi. I controlli non sono sostituiti da misure.

Misure: 16/256/4096/65536 B, cinque repliche, 1024 warmup e 65.536 chiamate
per replica, un thread. Ordine dei due metodi alternato per replica, nessuna
calibrazione/scarto. GC esplicito fuori finestra, timer monotono, contatore
heap globale e sink verificato. Il risultato di ogni chiamata viene
confrontato con l'oracolo calcolato prima del timing. Sensore positivo e
baseline nulla. Conservare tick, allocazioni, disassemblato e fallimenti.
Timeout complessivo 900 s, finestra 60 s; esiti unsupported separati dai successi.

L'obiettivo 0,4–0,6 microsecondi su 4 KiB è un'ipotesi sperimentale.
Il GET completo va rimisurato: il solo miglioramento del CRC non ne prova
il costo. Per un'integrazione di prodotto servono ADR accettato prima del
codice C1, fallback software, test differenziali/di corruzione, controlli
di compilazione, due letture e verifica complessiva del repository.

Riferimenti primari: [ISA Arm CRC32C](https://support.arm.com/documentation/100069/0609/A64-General-Instructions/CRC32CB--CRC32CH--CRC32CW--CRC32CX?lang=en),
[backend ARM64 SBCL](https://github.com/sbcl/sbcl/tree/master/src/compiler/arm64).
