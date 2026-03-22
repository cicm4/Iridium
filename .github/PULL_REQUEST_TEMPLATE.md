## Summary

<!-- What does this PR do? One paragraph. -->

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Behavior pack (new or updated)
- [ ] Documentation
- [ ] Refactor / cleanup
- [ ] CI / tooling

## Related Issues

Closes #<!-- issue number -->

## Privacy Checklist

All PRs touching the prediction engine or clipboard handling must confirm:

- [ ] No context signal data is written to disk (UserDefaults, FileManager, CoreData, etc.)
- [ ] No context signal data is transmitted over a network
- [ ] Clipboard content (if read) is held only as a local `let` binding and released within the prediction function scope
- [ ] No analytics, telemetry, or tracking code was added

## Testing

<!-- Describe what you tested and how. -->

- [ ] Unit tests pass (`⌘U`)
- [ ] UI tests pass
- [ ] Manually tested on macOS 14+

## Screenshots (if UI change)

<!-- Before / after screenshots or a short screen recording -->
