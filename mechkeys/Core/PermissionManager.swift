//
//  PermissionManager.swift
//  MechKeys
//

import Foundation
import AppKit
import Combine

@MainActor
final class PermissionManager: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    static let shared = PermissionManager()

    @Published private(set) var hasAccessibilityPermission: Bool = false

    private var pollTimer: Timer?

    private init() {
        checkPermission()
    }

    func checkPermission() {
        hasAccessibilityPermission = AXIsProcessTrusted()
    }

    func startPolling() {
        stopPolling()
        checkPermission()

        guard !hasAccessibilityPermission else { return }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPermission()
                if self?.hasAccessibilityPermission == true {
                    self?.stopPolling()
                }
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        startPolling()
    }

    deinit {
        pollTimer?.invalidate()
    }
}
