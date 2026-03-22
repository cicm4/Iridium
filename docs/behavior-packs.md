# Behavior Packs — Authoring Guide

Behavior packs are the primary extension point for Iridium. They let anyone add new prediction rules without writing or compiling Swift code.

---

## What a Behavior Pack Does

A behavior pack maps **context signals** to **app suggestions**. When Iridium detects a signal (e.g., the user copied something that looks like code), it evaluates all loaded packs and surfaces the union of suggested apps, ranked by confidence.

---

## Pack Format

A pack is a single `.iridiumpack` file — a JSON document with the following structure:

```json
{
  "id": "com.example.my-pack",
  "name": "My Behavior Pack",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "Short description of what this pack does.",
  "minimumIridiumVersion": "1.0",
  "triggers": [
    {
      "signal": "clipboard.contentType",
      "matches": "code",
      "confidence": 0.9,
      "suggest": [
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode"
      ]
    }
  ]
}
```

### Top-Level Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | String (reverse-DNS) | Yes | Unique identifier for your pack |
| `name` | String | Yes | Human-readable name shown in Iridium's UI |
| `version` | String (semver) | Yes | Pack version |
| `author` | String | No | Your name or handle |
| `description` | String | No | Shown in the pack browser |
| `minimumIridiumVersion` | String (semver) | No | Minimum app version required |
| `triggers` | Array | Yes | One or more trigger rules |

---

## Triggers

Each trigger defines:
- A **signal** to match
- A **condition** that must be met
- A **confidence** score (0.0–1.0) — affects ranking when multiple packs match
- A list of **suggested apps** (bundle IDs)

### Signal Types

| Signal | Description | Example Values |
|---|---|---|
| `clipboard.contentType` | Semantic type of clipboard content | `code`, `url`, `email`, `prose`, `image`, `file`, `unknown` |
| `clipboard.language` | Detected programming language (when `contentType` is `code`) | `swift`, `python`, `javascript`, `typescript`, `go`, `rust`, `unknown` |
| `app.frontmost` | Bundle ID of the currently active app | `"com.apple.Safari"` |
| `time.hourOfDay` | Current hour (24h, local time) | `9`, `14`, `22` |
| `display.count` | Number of connected displays | `1`, `2` |

> **Privacy note:** Iridium reads the *semantic type* of clipboard content (a UTI classification), not the raw content. Packs never receive clipboard text, images, or file paths.

### Match Expressions

The `matches` field supports:

| Expression | Example | Description |
|---|---|---|
| Exact string | `"code"` | Signal value must equal this string |
| Glob | `"code.*"` | Wildcard matching |
| Array | `["code", "url"]` | Signal must match any value in the array |
| Range (numeric signals) | `{"gte": 9, "lte": 17}` | Numeric range (used for `time.hourOfDay`, `display.count`) |

### Multiple Triggers

A trigger can require **all** conditions to be met using a `conditions` array:

```json
{
  "conditions": [
    { "signal": "clipboard.contentType", "matches": "code" },
    { "signal": "clipboard.language",    "matches": "python" }
  ],
  "confidence": 0.95,
  "suggest": ["com.jetbrains.pycharm", "com.microsoft.VSCode"]
}
```

---

## Finding App Bundle IDs

To find a macOS app's bundle ID from Terminal:

```bash
mdls -name kMDItemCFBundleIdentifier /Applications/Xcode.app
```

Or in Swift: `Bundle.main.bundleIdentifier`.

---

## Example Packs

### Research / Academic Pack

```json
{
  "id": "com.iridium.community.research",
  "name": "Research",
  "version": "1.0.0",
  "triggers": [
    {
      "signal": "clipboard.contentType",
      "matches": "url",
      "confidence": 0.7,
      "suggest": [
        "com.apple.Safari",
        "org.mozilla.firefox",
        "com.google.Chrome"
      ]
    },
    {
      "conditions": [
        { "signal": "clipboard.contentType", "matches": "prose" },
        { "signal": "time.hourOfDay",        "matches": { "gte": 8, "lte": 18 } }
      ],
      "confidence": 0.6,
      "suggest": [
        "com.apple.Pages",
        "com.microsoft.Word",
        "md.obsidian"
      ]
    }
  ]
}
```

### After-Hours Creative Pack

```json
{
  "id": "com.iridium.community.creative-evening",
  "name": "Evening Creative",
  "version": "1.0.0",
  "triggers": [
    {
      "conditions": [
        { "signal": "clipboard.contentType", "matches": "image" },
        { "signal": "time.hourOfDay",        "matches": { "gte": 18, "lte": 23 } }
      ],
      "confidence": 0.8,
      "suggest": [
        "com.bohemiancoding.sketch3",
        "com.figma.Desktop",
        "com.adobe.Photoshop"
      ]
    }
  ]
}
```

---

## Installing a Pack

**From the menu bar:**

1. Click the Iridium icon in the menu bar.
2. Go to **Behavior Packs → Install Pack…**
3. Select your `.iridiumpack` file.

**Manually:**

Drop the `.iridiumpack` file into:

```
~/Library/Application Support/Iridium/Packs/
```

Iridium will detect and load it on next launch.

---

## Submitting a Pack to the Community Registry

Open a pull request on this repository with your `.iridiumpack` file added to the `Packs/` directory. Include in the PR description:

- What signals the pack uses
- Which apps it suggests and why
- Any edge cases or known conflicts with other packs

All submitted packs are reviewed for:
1. Valid JSON schema
2. No use of undocumented or private signal names
3. Reasonable confidence scores
4. Accurate app bundle IDs
5. No misleading names that could impersonate system packs

---

## Versioning & Compatibility

Pack files are versioned independently from Iridium. If a future version of Iridium adds new signal types, older packs remain valid — new fields are simply ignored by older app versions. Packs can set `minimumIridiumVersion` to require newer app features.

---

## Future: Swift-Based Packs

A future version of Iridium will support Swift-based packs for advanced use cases (e.g., ML-based classification). These will implement the `BehaviorPack` protocol and compile as Swift packages. The same privacy constraints apply: no I/O, no networking, no retention of signal data.
