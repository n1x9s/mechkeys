//
//  OnboardingView.swift
//  MechKeys
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var permissionManager = PermissionManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("MechKeys needs Accessibility access")
                .font(.title2)
                .fontWeight(.semibold)

            Text("To play keyboard sounds, MechKeys needs permission to detect when you press keys. This is used only to trigger sounds — no keystrokes are recorded or transmitted.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(
                    icon: "lock.shield",
                    title: "Privacy First",
                    description: "No data leaves your Mac"
                )
                FeatureRow(
                    icon: "eye.slash",
                    title: "Listen Only",
                    description: "Cannot modify or block keystrokes"
                )
                FeatureRow(
                    icon: "bolt",
                    title: "Instant Sounds",
                    description: "Ultra-low latency playback"
                )
            }
            .padding()
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if permissionManager.hasAccessibilityPermission {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)

                Button("Get Started") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("Open System Settings") {
                    permissionManager.requestPermission()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("After enabling, this window will update automatically")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
        .frame(width: 420)
        .onAppear {
            permissionManager.startPolling()
        }
        .onDisappear {
            permissionManager.stopPolling()
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
