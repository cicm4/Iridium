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
    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var nextID: UInt32 = 1

    init() {
        installCarbonEventHandler()
    }

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
            Logger.windowManager.error("Failed to register hotkey (id: \(id), keyCode: \(keyCode), mods: \(modifiers)): \(status)")
            registeredHotkeys.removeValue(forKey: id)
        } else {
            if let ref = hotKeyRef {
                hotKeyRefs[id] = ref
            }
            Logger.windowManager.info("Registered hotkey id=\(id), keyCode=\(keyCode), mods=\(modifiers)")
        }

        return id
    }

    func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        registeredHotkeys.removeAll()
    }

    func handleHotkey(id: UInt32) {
        registeredHotkeys[id]?()
    }

    // MARK: - Private

    /// Installs the Carbon event handler that dispatches hotkey events.
    /// Without this, RegisterEventHotKey registers the hotkey but no events are delivered.
    private func installCarbonEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // Store a reference to self for the C callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }

                var hotKeyID = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard result == noErr else { return result }

                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                // Dispatch on main actor
                DispatchQueue.main.async {
                    manager.handleHotkey(id: hotKeyID.id)
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        if status != noErr {
            Logger.windowManager.error("Failed to install Carbon event handler: \(status)")
        } else {
            Logger.windowManager.info("Carbon hotkey event handler installed")
        }
    }

    nonisolated deinit {
        // eventHandler is cleaned up by the system when the app terminates
    }
}
