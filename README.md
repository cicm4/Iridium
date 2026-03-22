# Iridium

> A privacy-first, predictive window manager for macOS — context-aware, fully extensible, and beautifully minimal.

---

## What is Iridium?

Iridium is a smart macOS window manager that sits quietly in your menu bar and surfaces the right apps at the right time. It combines two philosophies:

1. **Responsive window management** — transparent, fast, keyboard-driven layout control modeled after the best tiling and floating window managers.
2. **Predictive app surfacing** — when you take an action (copy text, copy code, open a file), Iridium reads that context *ephemerally* and presents a focused selection of the apps most likely to be useful right now.

The result is a workflow where switching context feels native — not like fighting your OS.

---

## Key Features

| Feature | Description |
|---|---|
| **Predictive Surface** | Clipboard actions trigger smart app suggestions (copy code → IDEs, copy URL → browsers, copy prose → writing apps) |
| **Transparent Window Management** | Overlay-style layout engine that never obscures your work |
| **Behavior Packs** | Community-authored rule sets that extend Iridium's prediction logic — zero code required |
| **Menu Bar UI** | Apple-HIG-aligned settings panel lives in the top bar, never in your Dock |
| **Privacy by Design** | All context signals are processed in memory and discarded immediately — nothing is persisted or transmitted |
| **Fully Extensible** | Public protocol surface lets developers and power users craft their own behavior packs |

---

## How It Works

```
User Action (e.g. ⌘C)
        │
        ▼
  Context Signal
  (clipboard type,
   active app,
   time of day)
        │
        ▼
  Behavior Engine          ◄── Behavior Packs (user / community)
  (matches signals
   against policies)
        │
        ▼
  App Suggestion Panel
  (ephemeral overlay)
        │
        ▼
  User selects or dismisses
        │
        ▼
  Context data discarded ✓
```

Iridium **never** stores clipboard content, file paths, or behavioral telemetry. Every signal lives in memory for the duration of a single prediction cycle and is immediately released.

---

## Privacy & Security

Iridium was designed with a strict data minimization principle:

- **No clipboard data is ever written to disk.**
- **No telemetry, analytics, or crash reporting is transmitted off-device.**
- **No behavior history is retained** between sessions or within a session.
- Context signals are read, evaluated in-memory, and immediately discarded.
- Behavior packs run in a sandboxed evaluation context with no I/O access.

See [SECURITY.md](SECURITY.md) and [docs/privacy.md](docs/privacy.md) for the full security model.

---

## Behavior Packs

Behavior packs are the heart of Iridium's extensibility. They are declarative rule files (JSON + optional Swift) that map *context signals* to *app suggestions*.

**Example: Code Snippet Pack**

```json
{
  "id": "com.example.code-snippets",
  "name": "Code Snippets",
  "version": "1.0.0",
  "triggers": [
    {
      "signal": "clipboard.contentType",
      "matches": "code",
      "suggest": ["com.apple.dt.Xcode", "com.microsoft.VSCode", "com.jetbrains.intellij"]
    }
  ]
}
```

Anyone can author and distribute behavior packs. See [docs/behavior-packs.md](docs/behavior-packs.md) for the full authoring guide.

---

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15 or later (for building from source)

---

## Installation

### From Source

```bash
git clone https://github.com/cicm/Iridium.git
cd Iridium
open Iridium.xcodeproj
```

Build and run the `Iridium` scheme in Xcode. The app will appear in your menu bar.

### Releases

Pre-built `.dmg` releases are available on the [Releases](../../releases) page once v1.0 ships.

---

## Project Structure

```
Iridium/
├── Iridium/                  # Application source
│   ├── IridiumApp.swift      # App entry point
│   ├── ContentView.swift     # Root UI
│   └── Assets.xcassets/      # Icons and colors
├── IridiumTests/             # Unit tests
├── IridiumUITests/           # UI / integration tests
├── docs/                     # Extended documentation
│   ├── architecture.md       # Technical design
│   ├── behavior-packs.md     # Behavior pack authoring guide
│   └── privacy.md            # Privacy model details
├── .github/                  # GitHub config (CI, templates)
├── CONTRIBUTING.md
├── SECURITY.md
└── CODE_OF_CONDUCT.md
```

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

The most impactful contribution right now is authoring behavior packs — you don't need to touch a line of Swift to extend Iridium's capabilities.

---

## License

MIT — see [LICENSE](LICENSE) for details.
