//
//  KeyListener.swift
//  MechKeys
//

import Foundation
import CoreGraphics
import AppKit

final class KeyListener: @unchecked Sendable {
    static let shared = KeyListener()

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    private var soundsEnabled = true
    private var ignoreKeyRepeat = true
    private var excludedBundleIds: Set<String> = []

    private var lastKeyDown: Int64 = -1 // For detecting key repeat

    private let lock = NSLock()

    private init() {}

    func start() {
        guard !isRunning else {
            print("[KeyListener] Already running")
            return
        }

        print("[KeyListener] Starting event tap...")

        let eventMask = (1 << CGEventType.keyDown.rawValue) |
                       (1 << CGEventType.keyUp.rawValue) |
                       (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
            let listener = Unmanaged<KeyListener>.fromOpaque(refcon).takeUnretainedValue()
            listener.handleEvent(type: type, event: event)
            return Unmanaged.passUnretained(event)
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        ) else {
            print("Failed to create event tap. Accessibility permission may be required.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isRunning = true
            print("[KeyListener] Event tap started successfully")
        }
    }

    func stop() {
        guard isRunning else { return }

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false
    }

    func updateSettings(soundsEnabled: Bool, ignoreKeyRepeat: Bool, excludedBundleIds: Set<String>) {
        lock.lock()
        defer { lock.unlock() }

        self.soundsEnabled = soundsEnabled
        self.ignoreKeyRepeat = ignoreKeyRepeat
        self.excludedBundleIds = excludedBundleIds
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        lock.lock()
        let enabled = soundsEnabled
        let ignoreRepeat = ignoreKeyRepeat
        let excluded = excludedBundleIds
        lock.unlock()

        guard enabled else { return }

        // Check if current app is excluded
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier,
           excluded.contains(bundleId) {
            return
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        switch type {
        case .keyDown:
            // Check for key repeat
            if ignoreRepeat && keyCode == lastKeyDown {
                return
            }
            lastKeyDown = keyCode

            let category = KeyCategory.from(keyCode: keyCode)
            SoundEngine.shared.play(category: category, action: .keyDown)

        case .keyUp:
            lastKeyDown = -1
            let category = KeyCategory.from(keyCode: keyCode)
            SoundEngine.shared.play(category: category, action: .keyUp)

        case .flagsChanged:
            // Handle modifier keys
            let category = KeyCategory.modifier
            // We can't easily distinguish press/release for modifiers,
            // so we play keyDown sound
            SoundEngine.shared.play(category: category, action: .keyDown)

        default:
            break
        }
    }
}
