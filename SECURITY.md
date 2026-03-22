# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| main (pre-release) | Yes |

Once stable releases ship, only the latest minor version will receive security updates.

---

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub Issues.**

Email **camilocorreall44@gmail.com** with:

- A description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested mitigations

You will receive an acknowledgement within **48 hours** and a resolution timeline within **7 days**.

We follow [Coordinated Vulnerability Disclosure](https://en.wikipedia.org/wiki/Coordinated_vulnerability_disclosure). We will not take legal action against good-faith security researchers.

---

## Privacy & Data Handling Architecture

Iridium's security model is grounded in **data minimization**: the app can only protect data it never holds.

### Context Signals

Iridium reads context signals (clipboard content type, frontmost application bundle ID, system-level metadata) to power its predictive engine. These signals are:

1. **Read into memory** as value types with no persistent backing.
2. **Evaluated synchronously** within the behavior engine's prediction cycle.
3. **Discarded immediately** after the suggestion panel is either acted upon or dismissed.

No signal value (clipboard content, file paths, window titles) is ever:

- Written to disk (`UserDefaults`, file system, SQLite, CoreData)
- Transmitted over a network
- Passed to a third-party SDK or framework
- Included in crash reports or diagnostics

### Clipboard Access

Iridium requests clipboard access only when a user-initiated action (e.g., ⌘C) triggers the prediction cycle. The access is:

- **Type-only by default**: Iridium reads the UTI (Uniform Type Identifier) of clipboard content, not the content itself, where sufficient for prediction.
- **Content-scoped when required**: When a behavior pack requires content inspection (e.g., to distinguish code from prose), only the minimum required bytes are read and the reference is released immediately after classification.
- **Never cached**: Pasteboard observers are torn down after each prediction cycle.

### Behavior Packs

Third-party behavior packs run in a **restricted evaluation environment**:

- No file system access
- No network access
- No access to raw clipboard content (packs receive a typed signal, not raw data)
- Evaluated with a strict timeout; non-responsive packs are skipped

Pack manifests are verified against a checksum before loading. Packs distributed via the built-in registry are code-signed.

### Permissions

Iridium requests the minimum macOS entitlements required:

| Entitlement | Reason |
|---|---|
| `com.apple.security.automation.apple-events` | Needed to bring target apps to the foreground |
| Accessibility API (optional) | Window layout features only; no keylogging |

Iridium does **not** request:

- Full disk access
- Network access (no entitlement, no usage)
- Camera / microphone / location

### Threat Model

| Threat | Mitigation |
|---|---|
| Malicious behavior pack exfiltrating clipboard data | Packs receive typed signals only; no raw data access |
| Clipboard data persisted to disk | In-memory-only architecture; no write path exists |
| Unauthorized window manipulation | Accessibility permission is user-granted and scoped |
| Supply chain compromise via pack registry | Packs are code-signed and checksum-verified |

---

## Acknowledgements

We thank the security research community and commit to crediting all responsibly-disclosed findings in release notes.
