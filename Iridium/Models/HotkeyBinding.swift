//
//  HotkeyBinding.swift
//  Iridium
//

import Carbon
import Foundation

struct HotkeyBinding: Codable, Equatable, Identifiable {
    let action: HotkeyAction
    var keyCode: UInt32
    var modifiers: UInt32

    var id: String { action.rawValue }

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("\u{2303}") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("\u{2325}") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("\u{21E7}") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("\u{2318}") }
        parts.append(Self.keyCodeName(keyCode))
        return parts.joined()
    }

    static func keyCodeName(_ keyCode: UInt32) -> String {
        switch keyCode {
        case 49: return "Space"
        case 36: return "\u{21A9}" // Return
        case 48: return "\u{21E5}" // Tab
        case 51: return "\u{232B}" // Delete
        case 53: return "\u{238B}" // Escape
        case 123: return "\u{2190}" // Left
        case 124: return "\u{2192}" // Right
        case 125: return "\u{2193}" // Down
        case 126: return "\u{2191}" // Up
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 41: return ";"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        default: return "Key\(keyCode)"
        }
    }
}

enum HotkeyAction: String, Codable, CaseIterable, Identifiable {
    case workspacePredict = "workspacePredict"
    case tileLeft = "tileLeft"
    case tileRight = "tileRight"
    case maximize = "maximize"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .workspacePredict: return "Activate Workspace"
        case .tileLeft: return "Tile Left Half"
        case .tileRight: return "Tile Right Half"
        case .maximize: return "Maximize Window"
        }
    }

    var defaultBinding: HotkeyBinding {
        switch self {
        case .workspacePredict:
            // Hyper+Space (Ctrl+Option+Shift+Cmd+Space)
            return HotkeyBinding(
                action: self,
                keyCode: 49,
                modifiers: UInt32(controlKey | optionKey | shiftKey | cmdKey)
            )
        case .tileLeft:
            // Ctrl+Option+Left
            return HotkeyBinding(
                action: self,
                keyCode: 123,
                modifiers: UInt32(controlKey | optionKey)
            )
        case .tileRight:
            // Ctrl+Option+Right
            return HotkeyBinding(
                action: self,
                keyCode: 124,
                modifiers: UInt32(controlKey | optionKey)
            )
        case .maximize:
            // Ctrl+Option+Return
            return HotkeyBinding(
                action: self,
                keyCode: 36,
                modifiers: UInt32(controlKey | optionKey)
            )
        }
    }
}
