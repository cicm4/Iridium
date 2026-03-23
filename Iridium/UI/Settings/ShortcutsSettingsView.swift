//
//  ShortcutsSettingsView.swift
//  Iridium
//

import Carbon
import SwiftUI

struct ShortcutsSettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var settings = coordinator.settings

        Form {
            Section("Keyboard Shortcuts") {
                Text("Click a shortcut to record a new key combination.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(HotkeyAction.allCases) { action in
                    HotkeyRecorderRow(
                        action: action,
                        binding: settings.binding(for: action),
                        onRecord: { keyCode, modifiers in
                            if let conflict = settings.conflictingAction(keyCode: keyCode, modifiers: modifiers, excluding: action) {
                                return .conflict(conflict)
                            }
                            settings.updateBinding(for: action, keyCode: keyCode, modifiers: modifiers)
                            return .success
                        },
                        onReset: {
                            settings.updateBinding(
                                for: action,
                                keyCode: action.defaultBinding.keyCode,
                                modifiers: action.defaultBinding.modifiers
                            )
                        }
                    )
                }
            }

            Section {
                Button("Reset All to Defaults") {
                    settings.hotkeyBindings = HotkeyAction.allCases.map(\.defaultBinding)
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Recorder Row

private struct HotkeyRecorderRow: View {
    let action: HotkeyAction
    let binding: HotkeyBinding
    let onRecord: (UInt32, UInt32) -> RecordResult
    let onReset: () -> Void

    @State private var isRecording = false
    @State private var conflictMessage: String?

    enum RecordResult {
        case success
        case conflict(HotkeyAction)
    }

    var body: some View {
        HStack {
            Text(action.displayName)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isRecording {
                Text("Press a key combo...")
                    .font(.callout)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                    .onKeyPress(phases: .down) { press in
                        handleKeyPress(press)
                        return .handled
                    }

                Button("Cancel") {
                    isRecording = false
                    conflictMessage = nil
                }
                .buttonStyle(.borderless)
                .font(.caption)
            } else {
                Button {
                    isRecording = true
                    conflictMessage = nil
                } label: {
                    Text(binding.displayString)
                        .font(.callout.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)

                if binding != action.defaultBinding {
                    Button("Reset") {
                        onReset()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }

        if let conflictMessage {
            Text(conflictMessage)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func handleKeyPress(_ press: KeyPress) {
        let keyCode = UInt32(keyCodeFromKeyEquivalent(press.key))
        var modifiers: UInt32 = 0
        if press.modifiers.contains(.control) { modifiers |= UInt32(controlKey) }
        if press.modifiers.contains(.option) { modifiers |= UInt32(optionKey) }
        if press.modifiers.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if press.modifiers.contains(.command) { modifiers |= UInt32(cmdKey) }

        // Require at least one modifier
        guard modifiers != 0 else {
            conflictMessage = "Shortcuts must include at least one modifier key."
            return
        }

        let result = onRecord(keyCode, modifiers)
        switch result {
        case .success:
            isRecording = false
            conflictMessage = nil
        case .conflict(let other):
            conflictMessage = "Conflicts with \"\(other.displayName)\". Choose a different combination."
        }
    }

    /// Best-effort conversion from KeyEquivalent character to Carbon keyCode.
    private func keyCodeFromKeyEquivalent(_ key: KeyEquivalent) -> Int {
        let char = key.character
        let mapping: [Character: Int] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7,
            "c": 8, "v": 9, "b": 11, "q": 12, "w": 13, "e": 14, "r": 15,
            "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21, "6": 22,
            "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29,
            "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37,
            "j": 38, "k": 40, ";": 41, ",": 43, "/": 44, "n": 45, "m": 46,
            ".": 47, " ": 49,
        ]
        return mapping[char] ?? 49
    }
}
