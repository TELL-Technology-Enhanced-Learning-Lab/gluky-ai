# 📘 HOWTO — Glucko: Guida Tecnica all'Uso

> **Progetto:** Glucko — Videogioco educativo sulla gestione del diabete
> **Motore:** Godot Engine 4.6
> **Piattaforme:** Windows (PC) · Android
> **Repository:** [TELL-Technology-Enhanced-Learning-Lab/gluky-ai](https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai)

---

## 👤 Autore

- Michele Domenico Petruzzelli — Tesista @ [TELL Laboratory](...)
- Vincenzo Pio Eraclea — Tesista @ [TELL Laboratory](...)

---

## 📋 Indice

1. [Panoramica del Repository e dei Branch](#-1-panoramica-del-repository-e-dei-branch)
2. [Opzione A — Codice Sorgente (branch GluckoRun-base)](#-opzione-a--codice-sorgente-branch-gluckorun-base)
3. [Opzione B — Repository Completo (branch main)](#-opzione-b--repository-completo-branch-main)
4. [Opzione C — APK Android (installazione rapida)](#-opzione-c--apk-android-installazione-rapida)
5. [Eseguire il gioco su PC](#-eseguire-il-gioco-su-pc-windows)
6. [Eseguire il gioco su Android](#-eseguire-il-gioco-su-android)
7. [Aprire il progetto in Godot](#-aprire-il-progetto-in-godot)
8. [Struttura del codice sorgente](#-struttura-del-codice-sorgente)
9. [Requisiti tecnici](#-requisiti-tecnici)
10. [Limitazioni note](#-limitazioni-note)
11. [Errori noti e soluzioni](#-errori-noti-e-soluzioni)

---

## 🧭 1. Panoramica del Repository e dei Branch

Il repository è organizzato in **due branch principali**, ciascuno pensato per uno scopo diverso:

| Branch | Contenuto | A chi è rivolto |
|--------|-----------|-----------------|
| `main` | Codice sorgente + eseguibili PC + APK Android | Utenti finali, valutatori, ricercatori |
| `GluckoRun-base` | Solo codice sorgente Godot | Sviluppatori, collaboratori, tesisti |

### Riepilogo visivo

```
GitHub Repository: gluky-ai
│
├── branch: main ──────────────────────────────────────────────┐
│   ├── src/glucko/         → Progetto Godot (codice sorgente)  │
│   ├── file exe pc/        → Eseguibile Windows (.exe + .pck)  │
│   ├── file eseguibile android/ → APK Android (.apk)           │
│   └── docs/               → Documentazione tecnica            │
│                                                               │
└── branch: GluckoRun-base ─────────────────────────────────────┘
    └── src/glucko/         → Solo codice sorgente Godot
```

---

## 🅰️ Opzione A — Codice Sorgente (branch `GluckoRun-base`)

Scegli questa opzione se vuoi **studiare, modificare o contribuire** al codice del gioco.

### Prerequisiti
- [Git](https://git-scm.com/downloads) installato sul tuo sistema
- [Godot Engine 4.6](https://godotengine.org/download) installato

### Procedura

**1. Clona il branch specifico:**

```bash
git clone -b GluckoRun-base https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai.git
```

**2. Entra nella directory del progetto:**

```bash
cd gluky-ai/src/glucko
```

**3. Apri Godot e importa il progetto:**
- Avvia **Godot Engine 4.6**
- Clicca su **"Import"** nella schermata iniziale
- Naviga fino alla cartella `src/glucko/`
- Seleziona il file `project.godot`
- Clicca **"Import & Edit"**

**4. Avvia il gioco dall'editor:**
- Premi **F5** oppure clicca il pulsante ▶ in alto a destra nell'editor

> ℹ️ **Nota:** Questo branch non include gli eseguibili compilati. Per ottenere anche quelli, usa l'Opzione B.

---

## 🅱️ Opzione B — Repository Completo (branch `main`)

Scegli questa opzione per avere **tutto in un colpo solo**: codice sorgente, eseguibile Windows e APK Android.

### Metodo 1 — Tramite Git (consigliato)

```bash
git clone https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai.git
```

### Metodo 2 — Scarica come ZIP

1. Vai alla pagina principale del repository su GitHub
2. Clicca sul pulsante verde **`<> Code`**
3. Seleziona **`Download ZIP`**
4. Estrai l'archivio in una cartella a tua scelta

### Cosa troverai dopo il download

```
gluky-ai/
├── src/glucko/                 → Apri questo in Godot per editare
├── file exe pc/
│   ├── Glucko.exe              → Doppio clic per avviare su Windows
│   └── Glucko.pck              → File dati del gioco (NON spostare)
├── file eseguibile android/
│   └── Glucko.apk              → Installa su Android
└── docs/
    └── HOWTO.md                → Questa guida
```

---

## 🅲 Opzione C — APK Android (installazione rapida)

Scegli questa opzione se vuoi **installare subito il gioco sul tuo dispositivo Android** senza scaricare l'intero repository.

### Procedura passo-passo

**Passo 1 — Scarica l'APK**

- Vai alla pagina del repository: [gluky-ai su GitHub](https://github.com/TELL-Technology-Enhanced-Learning-Lab/gluky-ai)
- Entra nella cartella **`file eseguibile android/`**
- Clicca sul file **`Glucko.apk`**
- Clicca su **`Download raw file`** (icona di download) per scaricarlo

**Passo 2 — Abilita le origini sconosciute su Android**

Poiché l'APK non è distribuito tramite il Google Play Store, è necessario abilitare l'installazione da fonti esterne:

- Vai in **Impostazioni → Sicurezza**
- Attiva **"Origini sconosciute"** o **"Installa app sconosciute"**
- Su Android 8+: vai in **Impostazioni → App → Browser/File Manager** e attiva l'opzione per quella specifica app

**Passo 3 — Installa il gioco**

- Apri il file manager del tuo dispositivo
- Naviga fino alla cartella `Download/`
- Tocca **`Glucko.apk`**
- Segui le istruzioni a schermo e clicca **"Installa"**

**Passo 4 — Avvia Glucko**

- Trova l'icona di **Glucko** nella schermata home o nel menu app
- Tocca per avviare!

---

## 💻 Eseguire il Gioco su PC (Windows)

Dopo aver scaricato il repository completo (Opzione B):

1. Naviga nella cartella **`file exe pc/`**
2. Assicurati che **entrambi i file** siano presenti nella stessa cartella:
   - `Glucko.exe`
   - `Glucko.pck`
3. Fai **doppio clic** su `Glucko.exe`

> ⚠️ **Importante:** `Glucko.exe` e `Glucko.pck` **devono trovarsi nella stessa cartella**. Se sposti solo l'eseguibile senza il file `.pck`, il gioco non si avvierà.

### Controlli da tastiera (PC)

| Tasto | Azione |
|-------|--------|
| `W` / `↑` | Muovi avanti |
| `S` / `↓` | Muovi indietro |
| `A` / `←` | Muovi a sinistra |
| `D` / `→` | Muovi a destra |
| `Spazio` | Salta |
| `Shift` | Corri / Sprint |
| `E` | Interagisci / Inietta insulina |

---

## 📱 Eseguire il Gioco su Android

Dopo l'installazione dell'APK (Opzione C):

1. Cerca l'icona **Glucko** nella lista delle app
2. Tocca per avviare
3. Concedi i permessi richiesti (microfono per lo Speech-to-Text, se richiesto)

### Orientamento schermo
Il gioco è ottimizzato per orientamento **orizzontale (landscape)**. Il dispositivo ruoterà automaticamente all'avvio.

### Controlli touch
Su Android i controlli sono adattati per il touch screen con joystick virtuali e pulsanti a schermo.

---

## 🛠️ Aprire il Progetto in Godot

### Requisiti
- **Godot Engine 4.6** — [Scarica qui](https://godotengine.org/download/archive/)
- Il renderer usato è **Forward Mobile** (ottimizzato per dispositivi mobili)

### Procedura di importazione

1. **Avvia Godot 4.6**
2. Nella schermata del Project Manager, clicca **"Import"**
3. Naviga fino a `src/glucko/`
4. Seleziona il file `project.godot`
5. Clicca **"Import & Edit"**
6. Attendi che Godot importi e compili le risorse del progetto (può richiedere qualche minuto al primo avvio)

### Prima esecuzione

- Premi **F5** o il pulsante ▶ per avviare il gioco dall'editor
- La scena principale si aprirà automaticamente

### Esportare il progetto

Per compilare nuovi eseguibili:

- Vai su **Project → Export**
- Seleziona il preset **Windows Desktop** o **Android**
- Per Android: è necessario configurare l'Android SDK e un keystore

> ℹ️ I template di esportazione devono essere scaricati da: **Editor → Manage Export Templates**

---

## 📂 Struttura del Codice Sorgente

```
src/glucko/
│
├── 📁 scenes/              # Scene Godot (.tscn)
│   ├── main/               # Scena principale e menu
│   ├── glucorun/           # Modalità di gioco principale
│   └── ui/                 # Interfaccia utente
│
├── 📁 scripts/             # Script GDScript (.gd)
│   ├── general/            # Script globali e autoload
│   │   ├── resolution_manager.gd
│   │   ├── auto_orientation_manager.gd
│   │   └── GlucolifeDataManager.gd
│   └── glucorun/           # Logica di gioco
│       └── game logic/
│           └── food_database.gd
│
├── 📁 art/                 # Asset grafici e texture
├── 📁 models/              # Modelli 3D (.glb, .gltf)
├── 📁 sounds and music/    # Audio e colonna sonora
├── 📁 resources/           # Risorse Godot (.tres, .res)
├── 📁 shader/              # Shader GLSL personalizzati
├── 📁 Json_files/          # Database alimenti e configurazioni JSON
├── 📁 addons/              # Plugin Godot di terze parti
├── 📁 animationsaved/      # Animazioni salvate
├── 📁 special items/       # Asset per oggetti speciali di gioco
├── 📁 system_prompts/      # Prompt per il sistema AI (GlukyBot)
│
├── project.godot           # File di configurazione del progetto
├── export_presets.cfg      # Configurazione esportazione (Windows/Android)
└── icon.svg                # Icona del gioco
```

### Autoload (Singleton globali)

Il progetto usa i seguenti autoload, accessibili globalmente da qualsiasi script:

| Nome | File | Scopo |
|------|------|-------|
| `ResolutionManager` | `scripts/general/resolution_manager.gd` | Gestione risoluzione dinamica |
| `OrientationManager` | `scripts/general/auto_orientation_manager.gd` | Orientamento automatico schermo |
| `GlucolifeDataManager` | `scripts/general/GlucolifeDataManager.gd` | Dati e progressi del giocatore |
| `FoodDatabase` | `scripts/glucorun/game logic/food_database.gd` | Database alimenti e valori glicemici |
| `GameState` | *(uid)* | Stato globale del gioco |
| `MusicManager` | *(uid)* | Gestione audio e musica |
| `Glukybot` | *(uid)* | Assistente AI integrato |
| `STT` | *(uid)* | Speech-to-Text |

---

## ⚙️ Requisiti Tecnici

### PC — Windows

| Requisito | Minimo | Consigliato |
|-----------|--------|-------------|
| Sistema Operativo | Windows 10 (64-bit) | Windows 11 (64-bit) |
| RAM | 4 GB | 8 GB |
| Spazio su disco | 450 MB | 500 MB |
| GPU | OpenGL 3.3 / Vulkan | GPU dedicata con Vulkan |
| CPU | Dual-core 2 GHz | Quad-core 3 GHz |

### Android

| Requisito | Valore |
|-----------|--------|
| Versione Android | 6.0 (API 23) o superiore |
| RAM | Minimo 3 GB |
| Spazio libero | ~460 MB |
| Architettura | ARM64-v8a |
| Permessi | Microfono (opzionale, per STT) |

### Per lo sviluppo (Godot)

| Tool | Versione |
|------|---------|
| Godot Engine | 4.6 o superiore |
| Android SDK | API 23+ (per esportazione Android) |
| Java JDK | 17+ (per esportazione Android) |

---

## ⚠️ Limitazioni Note

- **Speech-to-Text**: richiede connessione internet e microfono funzionante. Su alcuni dispositivi Android potrebbe non essere disponibile in base alle impostazioni locali.
- **GlukyBot (AI)**: l'assistente virtuale basato su LLM richiede accesso a un endpoint API configurato. Senza configurazione, il bot opera in modalità limitata.
- **Orientamento**: il gioco è progettato per schermi in modalità **landscape** (orizzontale). Su tablet con aspect ratio non standard l'UI potrebbe subire adattamenti.
- **Prestazioni Android**: su dispositivi con meno di 4 GB di RAM o GPU datate potrebbero verificarsi rallentamenti nelle scene con molti asset 3D.
- **Esportazione iOS**: non inclusa nella versione attuale del progetto.
- **Multiplayer**: il gioco è esclusivamente single-player nella versione corrente.

---

## 🐛 Errori Noti e Soluzioni

### ❌ Il gioco non si avvia su Windows

**Problema:** Doppio clic su `Glucko.exe` ma non succede nulla.

**Soluzione:**
1. Verifica che `Glucko.pck` sia **nella stessa cartella** di `Glucko.exe`
2. Prova a eseguire come amministratore (tasto destro → "Esegui come amministratore")
3. Controlla che i driver GPU siano aggiornati

---

### ❌ L'APK non si installa su Android

**Problema:** Messaggio "App non installata" o "Bloccata da Play Protect".

**Soluzione:**
1. Vai in **Impostazioni → Sicurezza → Origini sconosciute** e abilitale
2. Se Play Protect blocca l'installazione: clicca **"Installa comunque"**
3. Verifica di avere almeno **460 MB di spazio libero**

---

### ❌ Crash all'avvio su Android

**Problema:** Il gioco si apre e si chiude immediatamente.

**Soluzione:**
1. Verifica che il tuo Android sia versione **6.0 o superiore**
2. Libera RAM chiudendo altre app in background
3. Riavvia il dispositivo e riprova

---

### ❌ Errori di importazione in Godot

**Problema:** Godot mostra errori di import o risorse mancanti all'apertura del progetto.

**Soluzione:**
1. Assicurati di usare **Godot 4.6** (non versioni precedenti o 3.x)
2. Cancella la cartella `.godot/` nella directory del progetto e reimporta
3. Vai su **Project → Reimport All** dall'editor

---

### ❌ GlukyBot non risponde

**Problema:** L'assistente AI non genera risposte.

**Soluzione:**
1. Verifica la connessione internet
2. Controlla la configurazione dell'API key nei file di sistema del progetto
3. Il bot potrebbe operare in modalità offline limitata senza API key valida

---

## 📚 Risorse Utili

- 📖 [Documentazione ufficiale Godot 4](https://docs.godotengine.org/en/stable/)
- 📖 [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
- 🎓 [TELL Laboratory GitHub](https://github.com/TELL-Technology-Enhanced-Learning-Lab)
- 🤝 [Godot Community](https://godotforums.org/)

---

<div align="center">

*Guida tecnica redatta nell'ambito del progetto di tesi Glucko · Laboratorio TELL · 2025–2026*

</div>
