//
//  MechKeysApp.swift
//  MechKeys
//

import SwiftUI

@main
struct MechKeysApp: App {
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var packManager = SoundPackManager.shared

    @State private var showOnboarding = false
    @State private var showSettings = false

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                soundsEnabled: $settings.soundsEnabled,
                volume: $settings.volume,
                showSettings: $showSettings
            )
        } label: {
            Image(systemName: settings.soundsEnabled ? "keyboard.fill" : "keyboard")
        }

        Window("MechKeys Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .commandsRemoved()

        Window("Welcome to MechKeys", id: "onboarding") {
            OnboardingView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        // Setup will be done in onAppear of the menu bar
    }
}

struct MenuBarView: View {
    @Binding var soundsEnabled: Bool
    @Binding var volume: Double
    @ObservedObject var packManager = SoundPackManager.shared
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var permissionManager = PermissionManager.shared
    @Binding var showSettings: Bool

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Toggle sounds
            Button {
                soundsEnabled.toggle()
                KeyListener.shared.updateSettings(
                    soundsEnabled: soundsEnabled,
                    ignoreKeyRepeat: settings.ignoreKeyRepeat,
                    excludedBundleIds: settings.excludedAppBundleIds
                )
            } label: {
                HStack {
                    Image(systemName: soundsEnabled ? "checkmark" : "")
                        .frame(width: 16)
                    Text("Sounds Enabled")
                    Spacer()
                    Text("⌥⌘K")
                        .foregroundStyle(.secondary)
                }
            }
            .keyboardShortcut("k", modifiers: [.option, .command])

            Divider()
                .padding(.vertical, 4)

            // Sound pack submenu
            Menu {
                ForEach(packManager.availablePacks) { pack in
                    Button {
                        settings.selectedSoundPackId = pack.id
                        packManager.selectPack(pack)
                    } label: {
                        HStack {
                            if settings.selectedSoundPackId == pack.id {
                                Image(systemName: "checkmark")
                            }
                            Text(pack.name)
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Sound Pack")
                    Spacer()
                    Text(packManager.currentPack?.name ?? "None")
                        .foregroundStyle(.secondary)
                }
            }

            // Volume submenu
            Menu {
                VStack {
                    Slider(value: $volume, in: 0...1)
                        .frame(width: 150)
                    Text("\(Int(volume * 100))%")
                        .font(.caption)
                        .monospacedDigit()
                }
                .padding(8)
            } label: {
                HStack {
                    Text("Volume")
                    Spacer()
                    Text("\(Int(volume * 100))%")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .padding(.vertical, 4)

            // Permission warning if needed
            if !permissionManager.hasAccessibilityPermission {
                Button {
                    openWindow(id: "onboarding")
                } label: {
                    Label("Accessibility Required", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }

                Divider()
                    .padding(.vertical, 4)
            }

            // Settings
            Button {
                openWindow(id: "settings")
            } label: {
                HStack {
                    Text("Settings...")
                    Spacer()
                    Text("⌘,")
                        .foregroundStyle(.secondary)
                }
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()
                .padding(.vertical, 4)

            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Text("Quit MechKeys")
                    Spacer()
                    Text("⌘Q")
                        .foregroundStyle(.secondary)
                }
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(4)
        .onAppear {
            setupApp()
        }
        .onChange(of: volume) { newValue in
            SoundEngine.shared.updateSettings(
                volume: Float(newValue),
                pitch: Float(settings.pitch),
                variability: Float(settings.variability),
                keyUpEnabled: settings.keyUpSoundEnabled
            )
        }
        .onChange(of: permissionManager.hasAccessibilityPermission) { hasPermission in
            if hasPermission {
                print("[MechKeys] Permission granted, starting KeyListener")
                KeyListener.shared.start()
            }
        }
    }

    private func setupApp() {
        print("[MechKeys] Setting up app...")
        // Check permissions
        permissionManager.checkPermission()

        if !permissionManager.hasAccessibilityPermission {
            openWindow(id: "onboarding")
            permissionManager.startPolling()
        }

        // Load sound pack
        print("[MechKeys] Loading sound pack: \(settings.selectedSoundPackId)")
        print("[MechKeys] Available packs: \(packManager.availablePacks.map { $0.id })")
        packManager.selectPack(id: settings.selectedSoundPackId)
        print("[MechKeys] Current pack: \(packManager.currentPack?.name ?? "none")")

        // Configure sound engine
        SoundEngine.shared.updateSettings(
            volume: Float(settings.volume),
            pitch: Float(settings.pitch),
            variability: Float(settings.variability),
            keyUpEnabled: settings.keyUpSoundEnabled
        )

        // Configure key listener
        KeyListener.shared.updateSettings(
            soundsEnabled: settings.soundsEnabled,
            ignoreKeyRepeat: settings.ignoreKeyRepeat,
            excludedBundleIds: settings.excludedAppBundleIds
        )

        // Start listening if we have permission
        if permissionManager.hasAccessibilityPermission {
            KeyListener.shared.start()
        }
    }
}
