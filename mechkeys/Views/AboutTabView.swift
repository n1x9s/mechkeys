//
//  AboutTabView.swift
//  MechKeys
//

import SwiftUI

struct AboutTabView: View {
    @State private var updateStatus: UpdateStatus = .idle
    @State private var latestVersion: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon and Name
            VStack(spacing: 12) {
                Image(systemName: "keyboard.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)

                Text("MechKeys")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .foregroundStyle(.secondary)
            }

            // Description
            Text("Mechanical keyboard sound simulator for macOS")
                .foregroundStyle(.secondary)

            Divider()
                .padding(.horizontal, 40)

            // Links
            VStack(spacing: 12) {
                Link(destination: URL(string: "https://github.com/yourusername/mechkeys")!) {
                    Label("GitHub Repository", systemImage: "link")
                }

                Link(destination: URL(string: "https://github.com/yourusername/mechkeys/issues")!) {
                    Label("Report an Issue", systemImage: "exclamationmark.bubble")
                }
            }

            // Update Check
            VStack(spacing: 8) {
                switch updateStatus {
                case .idle:
                    Button("Check for Updates") {
                        checkForUpdates()
                    }

                case .checking:
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Checking...")
                    }

                case .upToDate:
                    Label("You're up to date!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                case .updateAvailable:
                    VStack(spacing: 8) {
                        Label("Update available: \(latestVersion ?? "")", systemImage: "arrow.down.circle.fill")
                            .foregroundStyle(.orange)

                        Link("Download Update", destination: URL(string: "https://github.com/yourusername/mechkeys/releases/latest")!)
                            .buttonStyle(.borderedProminent)
                    }

                case .error:
                    Label("Couldn't check for updates", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            .padding(.top, 8)

            Spacer()

            // License
            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func checkForUpdates() {
        updateStatus = .checking

        Task {
            do {
                let url = URL(string: "https://api.github.com/repos/yourusername/mechkeys/releases/latest")!
                let (data, _) = try await URLSession.shared.data(from: url)

                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    let version = tagName.replacingOccurrences(of: "v", with: "")
                    latestVersion = version

                    if version.compare(appVersion, options: .numeric) == .orderedDescending {
                        updateStatus = .updateAvailable
                    } else {
                        updateStatus = .upToDate
                    }
                } else {
                    updateStatus = .error
                }
            } catch {
                updateStatus = .error
            }
        }
    }
}

private enum UpdateStatus {
    case idle
    case checking
    case upToDate
    case updateAvailable
    case error
}

#Preview {
    AboutTabView()
        .frame(width: 480, height: 500)
}
