//
//  HotkeyManager.swift
//  Iridium
//

import Carbon
import AppKit
import OSLog

@MainActor
final class HotkeyManager {
    private var eventHandler: EventHandlerRef?
    private var registeredHotkeys: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1

    func registerHotkey(keyCode: UInt32, modifiers: UInt32, action: @escaping () -> Void) -> UInt32 {
        let id = nextID
        nextID += 1
        registeredHotkeys[id] = action

        var hotKeyID = EventHotKeyID(signature: OSType(0x4952_444D), id: id) // "IRDM"
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            Logger.windowManager.error("Failed to register hotkey (id: \(id)): \(status)")
            registeredHotkeys.removeValue(forKey: id)
        }

        return id
    }

    func unregisterAll() {
        registeredHotkeys.removeAll()
    }

    func handleHotkey(id: UInt32) {
        registeredHotkeys[id]?()
    }
}
