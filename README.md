# 📘 Istruzioni per i Progetti di tesi sviluppati dal laboratorio TELL

## 🎯 Finalità del repository

Questo repository è parte dell’organizzazione GitHub del laboratorio TELL e deve essere usato per documentare in modo completo e strutturato ogni progetto software sviluppato da collaboratori, tesisti o assegnisti.

Ogni sviluppatore responsabile **ha l’obbligo** di:
- caricare il codice sorgente;
- fornire una **pagina descrittiva** del progetto (`README.md`);
- scrivere una **guida tecnica all’uso** (`docs/HOWTO.md` o simile).

Questo approccio consente:
- la tracciabilità del lavoro;
- la collaborazione tra membri del laboratorio;
- la possibilità di riutilizzo o estensione dei progetti in futuro;
- una documentazione utile anche per la redazione della tesi o paper collegati.

---

## 💡 Perché usare Git e GitHub?

Conoscere **Git e GitHub** è oggi una competenza fondamentale per chi sviluppa software.  
Git permette di:
- tenere traccia delle modifiche nel tempo (versionamento);
- lavorare in team in modo controllato;
- gestire conflitti, rollback e rami di sviluppo.

Inoltre, l’uso di GitHub:
- aggiunge valore al tuo CV;
- semplifica la collaborazione;
- offre uno storico utile per la valutazione del tuo lavoro.

---

## 🧭 Struttura consigliata del repository

```
project-name/
│
├── src/                    # Codice sorgente
├── docs/                   # Documentazione (incluso HOWTO.md)
├── data/                   # (Opzionale) Dati di input/output
├── tests/                  # Test automatici
│
├── README.md               # Descrizione progetto (questa pagina)
├── LICENSE                 # Licenza
├── requirements.txt        # Dipendenze (Python) o altri file config
└── .gitignore              # File e cartelle da ignorare
```

📌 Ogni progetto, oltre al codice e al materiale necessario, deve contenere:
- **README.md** ben compilato: obiettivi, struttura, autori, tecnologie, contesto.
- **HOWTO.md** con guida tecnica all'installazione, all’uso e alle eventuali criticità.

---

## 📌 Regole e buone pratiche

- Effettua almeno **un push a settimana** (consigliato).
- Usa **branch** per nuove funzionalità o esperimenti, ma assicurati che il codice stabile sia sempre aggiornato su `main`.
- Usa il file `.gitignore` per evitare di salvare file locali o temporanei (es. `.idea/`, `__pycache__/`, `*.log`).
- Se carichi dati >10 MB, usa un **permalink o archivio esterno** (es. Google Drive, OneDrive, Mega, etc.).
- Specifica sempre **versioni delle librerie** o dipendenze necessarie.
