//
//  SettingsView.swift
//  MechKeys
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SoundTabView()
                .tabItem {
                    Label("Sound", systemImage: "speaker.wave.2.fill")
                }

            GeneralTabView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AboutTabView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 520, height: 620)
    }
}

#Preview {
    SettingsView()
}
