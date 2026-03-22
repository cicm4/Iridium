# Iridium — Technical Architecture

## Overview

Iridium is a native macOS application built with SwiftUI. It operates as a persistent menu bar agent (LSUIElement) with no main window or Dock presence. Its two core responsibilities are:

1. **Window Layout Engine** — manages the position and size of application windows on the active display.
2. **Prediction Engine** — observes system events, evaluates behavior pack policies, and surfaces a contextual app suggestion panel.

---

## High-Level Component Map

```
┌─────────────────────────────────────────────────────┐
│                    Menu Bar UI                       │
│          (SwiftUI, NSStatusItem, NSMenu)              │
└────────────────────────┬────────────────────────────┘
                         │
          ┌──────────────▼──────────────┐
          │       App Coordinator        │
          │   (AppDelegate / lifecycle)  │
          └──┬──────────────────────┬───┘
             │                      │
   ┌──────────▼────────┐   ┌────────▼──────────────┐
   │  Window Manager   │   │   Prediction Engine    │
   │                   │   │                        │
   │  • Layout solver  │   │  • Signal collector    │
   │  • Space tracker  │   │  • Pack evaluator      │
   │  • Hotkey binding │   │  • Suggestion panel    │
   └───────────────────┘   └────────────────────────┘
                                    │
                        ┌───────────▼────────────┐
                        │    Behavior Pack Host   │
                        │                        │
                        │  • Pack registry        │
                        │  • Manifest validator   │
                        │  • Sandboxed evaluator  │
                        └────────────────────────┘
```

---

## Window Manager

The Window Manager uses the **Accessibility API** (`AXUIElement`) to read and write window frames. It maintains a model of:

- Active spaces and their windows
- Per-display layout grids
- User-defined layout presets

### Key Design Decisions

- **No persistent window state.** Window positions are read on demand and never cached beyond the current layout operation.
- **Accessibility permission is user-granted** and can be revoked in System Settings at any time. Iridium degrades gracefully — window management features disable themselves; prediction features continue working.

---

## Prediction Engine

The Prediction Engine is event-driven. It subscribes to:

| Signal Source | API Used | Scope |
|---|---|---|
| Clipboard changes | `NSPasteboard.changeCount` polling | UTI type only (content is an opt-in signal) |
| Active app changes | `NSWorkspace.didActivateApplicationNotification` | Bundle ID only |
| System time | `Date()` | Hour of day (no PII) |

### Signal Lifecycle

```
Event fires
    │
    ▼
Signal captured as Swift value type (struct, no heap retention)
    │
    ▼
Pack evaluator receives typed signal
    │
    ▼
Suggestion panel displayed (or skipped if no high-confidence match)
    │
    ▼
User acts or dismisses
    │
    ▼
Signal struct goes out of scope → ARC frees memory immediately
```

No signal data crosses this boundary. There is no logger, no persistence layer, and no network client in this path.

---

## Behavior Pack Host

Behavior packs are loaded at startup and on-demand when the user installs a new pack. The host:

1. **Validates** the pack manifest schema and verifies the checksum.
2. **Registers** the pack's trigger patterns in an in-memory registry.
3. **Evaluates** matching packs synchronously when a signal fires, with a hard timeout.

Packs receive a `ContextSignal` value (a typed enum, not raw data) and return an ordered list of app bundle IDs. The host merges results from all matching packs and deduplicates them.

### Pack Evaluation Sandbox

Swift-based pack extensions run in the same process but are restricted by protocol contracts — they cannot call file system or network APIs because those are not part of the `BehaviorPack` protocol surface. JSON-only packs have no code execution at all.

---

## Menu Bar UI

The settings panel is rendered as an `NSMenu` + SwiftUI popover anchored to the `NSStatusItem`. It follows Apple HIG for menu bar extras:

- Single-click opens the panel.
- The panel is non-modal and auto-dismisses on click-outside.
- Settings are stored in `UserDefaults` (layout preferences, enabled packs) — **never** context signal data.

---

## Data Flow Summary

| Data Type | Stored? | Transmitted? | Lifetime |
|---|---|---|---|
| Clipboard UTI type | No | No | Single prediction cycle |
| Clipboard content | No | No | Single prediction cycle (if read at all) |
| Active app bundle ID | No | No | Single prediction cycle |
| Window frame | No | No | Single layout operation |
| Layout preferences | Yes (`UserDefaults`) | No | Persistent (user config only) |
| Installed pack list | Yes (`UserDefaults`) | No | Persistent (user config only) |

---

## Testing Strategy

| Layer | Framework | What's Tested |
|---|---|---|
| Unit | Swift Testing | Signal classification, pack evaluation logic, manifest parsing |
| Integration | XCTest | Window manager with mock AX API, end-to-end prediction cycle |
| UI | XCTest / XCUITest | Menu bar panel, suggestion overlay rendering |

Tests must not access real clipboard data. Use `MockPasteboard` fixtures defined in `IridiumTests/Fixtures/`.
