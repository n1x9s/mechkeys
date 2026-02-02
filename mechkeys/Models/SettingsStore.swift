//
//  SettingsStore.swift
//  MechKeys
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    nonisolated let objectWillChange = ObservableObjectPublisher()

    static let shared = SettingsStore()

    @AppStorage("soundsEnabled") var soundsEnabled: Bool = true
    @AppStorage("selectedSoundPackId") var selectedSoundPackId: String = "cherrymxblue"
    @AppStorage("volume") var volume: Double = 0.75
    @AppStorage("pitch") var pitch: Double = 1.0
    @AppStorage("variability") var variability: Double = 0.3
    @AppStorage("keyUpSoundEnabled") var keyUpSoundEnabled: Bool = true
    @AppStorage("ignoreKeyRepeat") var ignoreKeyRepeat: Bool = true
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("showInDock") var showInDock: Bool = false
    @AppStorage("showNotifications") var showNotifications: Bool = true
    @AppStorage("excludedAppBundleIds") private var excludedAppBundleIdsString: String = ""

    var excludedAppBundleIds: Set<String> {
        get {
            Set(excludedAppBundleIdsString.split(separator: ",").map(String.init))
        }
        set {
            excludedAppBundleIdsString = newValue.joined(separator: ",")
        }
    }

    func isAppExcluded(_ bundleId: String) -> Bool {
        excludedAppBundleIds.contains(bundleId)
    }

    func addExcludedApp(_ bundleId: String) {
        var ids = excludedAppBundleIds
        ids.insert(bundleId)
        excludedAppBundleIds = ids
    }

    func removeExcludedApp(_ bundleId: String) {
        var ids = excludedAppBundleIds
        ids.remove(bundleId)
        excludedAppBundleIds = ids
    }

    private init() {}
}
