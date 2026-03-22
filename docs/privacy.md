# Privacy Policy

**Effective date:** 2026-03-22

Iridium is designed to be useful without knowing anything about you. This document explains precisely what data is accessed, how it is used, and why none of it leaves your device — or your RAM.

---

## What Iridium Accesses

### Clipboard (Pasteboard)

Iridium monitors the system pasteboard's **change count** — a monotonically incrementing integer that indicates the pasteboard was updated. When the count changes, Iridium may read:

- **The UTI (Uniform Type Identifier)** of the clipboard content — e.g., `public.source-code`, `public.plain-text`, `public.url`. This is a type label, not the content itself.
- **A small content sample** (limited to the first 512 bytes) when a behavior pack's trigger requires semantic content classification (e.g., distinguishing Swift code from Python code). This sample is read into a local variable, classified, and immediately released.

Iridium **does not**:
- Read or retain the full clipboard contents.
- Read images, files, or binary data from the clipboard.
- Store any clipboard data in memory beyond the scope of a single prediction function call.

### Active Application

Iridium observes `NSWorkspace.didActivateApplicationNotification` to receive the **bundle ID** of the frontmost application (e.g., `com.apple.Safari`). Bundle IDs are non-personal identifiers — they identify an app, not a user or document.

This information is used as a context signal for behavior pack evaluation and is discarded after the evaluation completes.

### System Clock

Iridium reads `Date()` to determine the current hour of day. This is used by time-aware behavior packs (e.g., suggest creative apps in the evening). No timestamp is stored.

### Display Configuration

Iridium reads the number and resolution of connected displays via `NSScreen`. This is used by the window layout engine to calculate layout grids. No display serial numbers or hardware identifiers are read.

---

## What Iridium Does NOT Access

| Data Type | Accessed? |
|---|---|
| Clipboard content (beyond type/sample) | No |
| Browser history | No |
| File system contents | No |
| Keystrokes | No |
| Screen content / screenshots | No |
| Location | No |
| Contacts, calendar, messages | No |
| Camera / microphone | No |
| iCloud or Apple ID | No |
| Any network resource | No |

---

## Data Storage

Iridium stores only:

| What | Where | Why |
|---|---|---|
| Enabled behavior packs | `UserDefaults` | To restore your pack configuration on next launch |
| Window layout presets | `UserDefaults` | To restore your saved layouts |
| Menu bar appearance preferences | `UserDefaults` | To restore your UI preferences |

No context signal data is ever written to `UserDefaults` or any other storage.

---

## Data Transmission

Iridium has **no networking code and no network entitlements**. It is architecturally incapable of transmitting data off-device. There is no:

- Analytics SDK
- Crash reporting service
- Auto-update client (updates are delivered via the App Store or manual download)
- Telemetry of any kind

---

## Third-Party Behavior Packs

Packs you install from outside the built-in registry are JSON files with no executable code. They cannot access clipboard data, the file system, or the network — their only capability is to match against typed signals and return a list of app bundle IDs.

Future Swift-based packs will be sandboxed to the same constraints via protocol design.

---

## Permissions You Grant

| Permission | How to Grant | What It Enables | How to Revoke |
|---|---|---|---|
| Accessibility | System Settings → Privacy & Security → Accessibility | Window layout features | Remove Iridium from the list |

Iridium works without Accessibility permission — window management features are disabled, but the prediction engine and menu bar UI continue to function.

---

## Children's Privacy

Iridium does not knowingly collect any information from anyone, including children. There is nothing to collect.

---

## Changes to This Policy

If the privacy model changes in any meaningful way, the change will be documented in the release notes and reflected in this file with an updated effective date.

---

## Contact

Questions about this policy: **camilocorreall44@gmail.com**
