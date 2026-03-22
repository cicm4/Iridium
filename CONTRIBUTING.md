# Contributing to Iridium

Thank you for your interest in contributing. This document covers how to contribute code, behavior packs, documentation, and bug reports.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Development Setup](#development-setup)
- [Project Conventions](#project-conventions)
- [Pull Request Process](#pull-request-process)
- [Authoring Behavior Packs](#authoring-behavior-packs)
- [Reporting Bugs](#reporting-bugs)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

---

## Ways to Contribute

| Type | Description |
|---|---|
| **Behavior Packs** | The highest-impact contribution. No Swift required. See [docs/behavior-packs.md](docs/behavior-packs.md). |
| **Bug Reports** | Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.yml). |
| **Feature Requests** | Use the [feature request template](.github/ISSUE_TEMPLATE/feature_request.yml). |
| **Core Code** | Improvements to the window manager, behavior engine, or UI. |
| **Documentation** | Fixes, clarifications, and expansions to any doc in this repo. |

---

## Development Setup

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Git

### Getting Started

```bash
git clone https://github.com/cicm/Iridium.git
cd Iridium
open Iridium.xcodeproj
```

Run the `Iridium` scheme (`⌘R`) to build and launch the app locally.

Run tests with `⌘U` or from the terminal:

```bash
xcodebuild test \
  -scheme Iridium \
  -destination 'platform=macOS'
```

### Branching Strategy

| Branch | Purpose |
|---|---|
| `main` | Always deployable. Direct commits are not allowed. |
| `feat/<name>` | New features |
| `fix/<name>` | Bug fixes |
| `docs/<name>` | Documentation changes |
| `pack/<name>` | New or updated behavior packs |

---

## Project Conventions

### Swift Style

- Follow [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Use `swiftformat` with the project's `.swiftformat` config before committing.
- Prefer value types (`struct`, `enum`) over reference types where practical.
- Mark all types `private` or `internal` unless there is an explicit reason for wider visibility.

### Privacy Rules (Non-Negotiable)

All contributors must uphold the privacy architecture:

1. **Never write context signal data to disk.** This includes `UserDefaults`, `FileManager`, CoreData, or any persistence layer.
2. **Never transmit context data over a network.** There are no networking entitlements; don't add them.
3. **Clipboard content must be held only as a local `let` binding** within the scope of a single prediction function call.
4. **No analytics or tracking code** of any kind may be added.

Pull requests that violate these rules will not be merged regardless of other merits.

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add URL detection to clipboard signal classifier
fix: prevent overlay from appearing on full-screen spaces
docs: expand behavior pack authoring guide
pack: add 'research' behavior pack for academic workflows
```

---

## Pull Request Process

1. Fork the repo and create your branch from `main`.
2. Make your changes. Add tests for any new behavior.
3. Ensure all tests pass locally (`⌘U`).
4. Fill out the pull request template completely.
5. Request a review — at least one approval is required before merging.

For significant changes, open an Issue first to discuss the approach.

---

## Authoring Behavior Packs

Behavior packs are **the recommended way to extend Iridium** without touching the core codebase. They are declarative JSON manifests that map context signals to app suggestions.

See the full guide: [docs/behavior-packs.md](docs/behavior-packs.md).

To submit a pack to the built-in registry, open a PR with your `.iridiumpack` file added to the `Packs/` directory and fill out the pack submission template.

---

## Reporting Bugs

Use the [bug report issue template](.github/ISSUE_TEMPLATE/bug_report.yml).

**Important:** Do not include clipboard content, file paths, or any personal data in bug reports. If you believe you have found a security vulnerability, follow the [Security Policy](SECURITY.md) instead.
