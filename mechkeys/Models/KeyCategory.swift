//
//  KeyCategory.swift
//  MechKeys
//

import Foundation
import Carbon.HIToolbox

enum KeyAction: String, CaseIterable {
    case keyDown
    case keyUp
}

enum KeyCategory: String, CaseIterable {
    case alphanumeric
    case modifier
    case space
    case enter
    case backspace
    case functional

    static func from(keyCode: Int64) -> KeyCategory {
        switch Int(keyCode) {
        // Space
        case kVK_Space:
            return .space

        // Enter
        case kVK_Return, kVK_ANSI_KeypadEnter:
            return .enter

        // Backspace
        case kVK_Delete, kVK_ForwardDelete:
            return .backspace

        // Modifiers
        case kVK_Shift, kVK_RightShift,
             kVK_Command, kVK_RightCommand,
             kVK_Control, kVK_RightControl,
             kVK_Option, kVK_RightOption,
             kVK_CapsLock, kVK_Function:
            return .modifier

        // Functional keys
        case kVK_F1, kVK_F2, kVK_F3, kVK_F4,
             kVK_F5, kVK_F6, kVK_F7, kVK_F8,
             kVK_F9, kVK_F10, kVK_F11, kVK_F12,
             kVK_F13, kVK_F14, kVK_F15, kVK_F16,
             kVK_F17, kVK_F18, kVK_F19, kVK_F20,
             kVK_Escape, kVK_Tab,
             kVK_UpArrow, kVK_DownArrow, kVK_LeftArrow, kVK_RightArrow,
             kVK_Home, kVK_End, kVK_PageUp, kVK_PageDown,
             kVK_Help, kVK_VolumeUp, kVK_VolumeDown, kVK_Mute:
            return .functional

        // Everything else is alphanumeric
        default:
            return .alphanumeric
        }
    }

    var folderName: String {
        return rawValue
    }
}
