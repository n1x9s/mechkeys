//
//  GeneralTabView.swift
//  MechKeys
//

import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct GeneralTabView: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var permissionManager = PermissionManager.shared

    @State private var excludedApps: [(bundleId: String, name: String)] = []
    @State private var showAppPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Startup Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Startup")
                        .font(.headline)

                    Toggle("Launch at login", isOn: $settings.launchAtLogin)
                        .onChange(of: settings.launchAtLogin) { newValue in
                            updateLoginItem(enabled: newValue)
                        }

                    Toggle("Show in Dock", isOn: $settings.showInDock)

                    Toggle("Show notifications on toggle", isOn: $settings.showNotifications)
                }

                Divider()

                // Accessibility Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Accessibility")
                        .font(.headline)

                    HStack {
                        if permissionManager.hasAccessibilityPermission {
                            Label("Permission granted", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Permission required", systemImage: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        }

                        Spacer()

                        Button("Open Settings") {
                            permissionManager.openAccessibilitySettings()
                        }
                    }
                }

                Divider()

                // Excluded Apps Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Excluded Apps")
                            .font(.headline)

                        Spacer()

                        Button {
                            showAppPicker = true
                        } label: {
                            Label("Add App", systemImage: "plus")
                        }
                    }

                    Text("Sounds will be disabled when these apps are in the foreground.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if excludedApps.isEmpty {
                        Text("No excluded apps")
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(excludedApps, id: \.bundleId) { app in
                                HStack {
                                    if let icon = getAppIcon(bundleId: app.bundleId) {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    }

                                    Text(app.name)

                                    Spacer()

                                    Button(role: .destructive) {
                                        removeExcludedApp(bundleId: app.bundleId)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)

                                if app.bundleId != excludedApps.last?.bundleId {
                                    Divider()
                                }
                            }
                        }
                        .background(.quaternary.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showAppPicker,
            allowedContentTypes: [UTType.application],
            allowsMultipleSelection: false
        ) { result in
            handleAppSelection(result)
        }
        .onAppear {
            loadExcludedApps()
        }
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update login item: \(error)")
            settings.launchAtLogin = !enabled // Revert
        }
    }

    private func loadExcludedApps() {
        excludedApps = settings.excludedAppBundleIds.compactMap { bundleId in
            if let name = getAppName(bundleId: bundleId) {
                return (bundleId, name)
            }
            return (bundleId, bundleId)
        }
    }

    private func handleAppSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier {
                settings.addExcludedApp(bundleId)
                loadExcludedApps()
                updateKeyListener()
            }

        case .failure(let error):
            print("App selection failed: \(error)")
        }
    }

    private func removeExcludedApp(bundleId: String) {
        settings.removeExcludedApp(bundleId)
        loadExcludedApps()
        updateKeyListener()
    }

    private func updateKeyListener() {
        KeyListener.shared.updateSettings(
            soundsEnabled: settings.soundsEnabled,
            ignoreKeyRepeat: settings.ignoreKeyRepeat,
            excludedBundleIds: settings.excludedAppBundleIds
        )
    }

    private func getAppName(bundleId: String) -> String? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return FileManager.default.displayName(atPath: url.path)
    }

    private func getAppIcon(bundleId: String) -> NSImage? {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: url.path)
    }
}

#Preview {
    GeneralTabView()
        .frame(width: 480, height: 500)
}
