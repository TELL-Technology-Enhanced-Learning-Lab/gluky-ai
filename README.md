<div align="center">

<img src="src/glucko/icon.svg" alt="Glucko Logo" width="120" height="120"/>

# 🎮 Glucko

### Un videogioco educativo sulla gestione del diabete

*Sviluppato nell'ambito del Laboratorio [TELL – Technology-Enhanced Learning Lab](https://github.com/TELL-Technology-Enhanced-Learning-Lab)*

---

[![Godot Engine](https://img.shields.io/badge/Godot-4.6-478CBF?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org/)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android-green?style=for-the-badge&logo=android&logoColor=white)](https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![Branch](https://img.shields.io/badge/Branch-main%20%7C%20GluckoRun--base-orange?style=for-the-badge&logo=git&logoColor=white)](https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai/branches)

</div>

---

## 🧭 Descrizione del Progetto

**Glucko** è un videogioco educativo 3D sviluppato con il motore **Godot 4.6**, concepito come strumento di apprendimento gamificato per sensibilizzare bambini e ragazzi con diabete di tipo 1 (e non) alla gestione della glicemia, dell'alimentazione e dell'uso dell'insulina.

Il gioco integra meccaniche di **serious game** in un ambiente visivamente coinvolgente, dove il giocatore veste i panni di un personaggio che deve raccogliere cibo sano, evitare zuccheri in eccesso e somministrare insulina al momento giusto — il tutto mentre affronta sfide e ostacoli ispirati alla vita reale di un paziente diabetico.

Il progetto è stato sviluppato come lavoro di tesi all'interno del laboratorio **TELL (Technology-Enhanced Learning Lab)** e rappresenta un caso concreto di applicazione dell'intelligenza artificiale e del machine learning in ambito educativo-sanitario.

---

## ✨ Caratteristiche Principali

| Feature | Descrizione |
|--------|-------------|
| 🎮 **Gameplay 3D** | Ambiente tridimensionale con meccaniche runner/action |
| 🍎 **Alimentazione simulata** | Database alimenti reali con impatto glicemico |
| 💉 **Gestione insulina** | Meccaniche di iniezione insulinica tempestiva |
| 🤖 **GlukyBot AI** | Assistente virtuale basato su LLM integrato nel gioco |
| 🎵 **Audio dinamico** | Colonna sonora adattiva e effetti sonori |
| 📱 **Multipiattaforma** | Disponibile su Windows (PC) e Android |
| 🔊 **Speech-to-Text** | Riconoscimento vocale integrato |
| 📊 **Tracciamento dati** | Salvataggio progressi e dati glicemici del giocatore |

---

## 📁 Struttura del Repository

```
gluky-ai/
│
├── 📂 src/glucko/              # Progetto Godot completo (codice sorgente)
│   ├── scenes/                 # Scene del gioco (.tscn)
│   ├── scripts/                # Script GDScript (.gd)
│   ├── art/                    # Asset grafici, texture, modelli
│   ├── sounds and music/       # Musica e effetti sonori
│   ├── resources/              # Risorse e materiali
│   ├── models/                 # Modelli 3D
│   ├── Json_files/             # Database alimenti e configurazioni
│   ├── addons/                 # Plugin aggiuntivi Godot
│   └── project.godot           # File di progetto Godot
│
├── 📂 file exe pc/             # Eseguibile per Windows
│   ├── Glucko.exe              # Avvia il gioco su PC
│   └── Glucko.pck              # Pacchetto risorse del gioco
│
├── 📂 file eseguibile android/ # Applicazione Android
│   └── Glucko.apk              # APK installabile su Android
│
├── 📂 docs/                    # Documentazione tecnica
│   ├── HOWTO.md                # Guida tecnica all'uso e installazione
│   └── README.md               # Note sulla documentazione
│
├── 📂 data/                    # Dati di input/output
├── 📂 source/                  # Librerie e risorse esterne
│
├── README.md                   # Questo file
└── .gitignore
```

---

## 🚀 Come Ottenere e Usare Glucko

> 📖 **Per la guida tecnica completa**, consulta [`docs/HOWTO.md`](docs/HOWTO.md)

Esistono **tre modalità** per accedere al progetto, a seconda delle tue esigenze:

---

### 🅰️ Opzione 1 — Solo il codice sorgente (branch `GluckoRun-base`)

Ideale per sviluppatori e collaboratori che vogliono aprire ed editare il progetto in Godot.

```bash
git clone -b GluckoRun-base https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai.git
```

- Contiene **esclusivamente il codice sorgente** del progetto Godot
- Apri il progetto con **Godot 4.6** o superiore
- Nessun file eseguibile incluso in questo branch

---

### 🅱️ Opzione 2 — Repository completo (branch `main`)

Ideale per chi vuole tutto: codice sorgente **+** eseguibili per PC e Android.

```bash
git clone https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai.git
```

Oppure scarica l'archivio ZIP direttamente da GitHub:

> **`Code` → `Download ZIP`** dalla pagina principale del repository

Dopo il download troverai:
- 📂 `src/glucko/` → progetto apribile in Godot
- 📂 `file exe pc/` → eseguibile Windows (`Glucko.exe`)
- 📂 `file eseguibile android/` → applicazione Android (`Glucko.apk`)

---

### 🅲 Opzione 3 — Solo l'APK Android (installazione rapida)

Ideale per chi vuole giocare subito su un dispositivo Android senza scaricare l'intero repository.

1. Vai alla cartella [`file eseguibile android/`](file%20eseguibile%20android/) nel repository
2. Scarica direttamente il file **`Glucko.apk`**
3. Trasferiscilo sul tuo dispositivo Android
4. Abilita **"Origini sconosciute"** nelle impostazioni del dispositivo
5. Tocca il file APK per avviare l'installazione

> ⚠️ Prima dell'installazione, assicurati che il tuo dispositivo Android esegua **Android 6.0 (API 23) o superiore**.

---

## 🛠️ Requisiti Tecnici

### Per eseguire il gioco su PC (Windows)
- **Sistema Operativo:** Windows 10 / 11 (64-bit)
- **RAM:** minimo 4 GB (consigliati 8 GB)
- **Spazio disco:** ~450 MB
- **GPU:** compatibile con Vulkan o OpenGL 3.3+

### Per eseguire il gioco su Android
- **Android:** 6.0 (Marshmallow, API 23) o superiore
- **RAM:** minimo 3 GB
- **Spazio di archiviazione:** ~450 MB liberi
- **Permessi richiesti:** microfono (per Speech-to-Text), archiviazione

### Per aprire il progetto in Godot
- **Godot Engine:** versione 4.6 o superiore
- **Tipo di progetto:** Mobile / Renderer: Forward Mobile
- **GDScript** (nessuna dipendenza esterna obbligatoria)

---

## 👨‍💻 Autori e Contatti

| Ruolo | Nome |
|-------|------|
| 🎓 Sviluppatore / Tesista | Michele Domenico Petruzzelli|
| 🎓 Sviluppatore / Tesista | Vincenzo Pio Eraclea|
| 🏛️ Laboratorio | [TELL – Technology-Enhanced Learning Lab](https://github.com/TELL-Technology-Enhanced-Learning-Lab) |

---

## 🏛️ Contesto Accademico

Questo progetto è stato sviluppato come parte di una **tesi di laurea** nell'ambito del laboratorio TELL. Il laboratorio si occupa di ricerca e sviluppo di tecnologie per l'apprendimento potenziato, con focus su:

- Serious Games e gamification in ambito educativo-sanitario
- Intelligenza artificiale applicata all'educazione
- Strumenti digitali per la formazione e la sensibilizzazione

---

## 📄 Licenza

Questo progetto è distribuito sotto licenza **MIT**. Consulta il file [LICENSE](LICENSE) per i dettagli.

---

<div align="center">

*Sviluppato con ❤️ dal laboratorio TELL · Godot Engine 4.6 · 2025–2026*

</div>
