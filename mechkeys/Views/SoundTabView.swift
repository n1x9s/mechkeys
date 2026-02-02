//
//  SoundTabView.swift
//  MechKeys
//

import SwiftUI
import UniformTypeIdentifiers

struct SoundTabView: View {
    @ObservedObject var settings = SettingsStore.shared
    @ObservedObject var packManager = SoundPackManager.shared

    @State private var showImportPanel = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Sound Packs Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sound Packs")
                            .font(.headline)

                        Spacer()

                        Button {
                            showImportPanel = true
                        } label: {
                            Label("Add Pack", systemImage: "plus")
                        }
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(packManager.availablePacks) { pack in
                            SoundPackCard(
                                pack: pack,
                                isSelected: settings.selectedSoundPackId == pack.id,
                                onSelect: {
                                    settings.selectedSoundPackId = pack.id
                                    packManager.selectPack(pack)
                                },
                                onPreview: {
                                    packManager.previewPack(pack)
                                },
                                onDelete: pack.isBuiltIn ? nil : {
                                    deletePack(pack)
                                }
                            )
                        }
                    }
                }

                Divider()

                // Volume Controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sound Settings")
                        .font(.headline)

                    VStack(spacing: 12) {
                        SliderRow(
                            title: "Volume",
                            value: $settings.volume,
                            range: 0...1,
                            format: { "\(Int($0 * 100))%" }
                        )

                        SliderRow(
                            title: "Pitch",
                            value: $settings.pitch,
                            range: 0.8...1.2,
                            format: { String(format: "%.1fx", $0) }
                        )

                        SliderRow(
                            title: "Variability",
                            value: $settings.variability,
                            range: 0...1,
                            format: { "\(Int($0 * 100))%" }
                        )
                    }

                    Toggle("Play key up sounds", isOn: $settings.keyUpSoundEnabled)

                    Toggle("Ignore key repeat", isOn: $settings.ignoreKeyRepeat)
                }
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showImportPanel,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onChange(of: settings.volume) { newValue in
            updateSoundEngine()
        }
        .onChange(of: settings.pitch) { newValue in
            updateSoundEngine()
        }
        .onChange(of: settings.variability) { newValue in
            updateSoundEngine()
        }
        .onChange(of: settings.keyUpSoundEnabled) { newValue in
            updateSoundEngine()
        }
    }

    private func updateSoundEngine() {
        SoundEngine.shared.updateSettings(
            volume: Float(settings.volume),
            pitch: Float(settings.pitch),
            variability: Float(settings.variability),
            keyUpEnabled: settings.keyUpSoundEnabled
        )
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                try packManager.importSoundPack(from: url)
            } catch {
                // Show error alert
                print("Import failed: \(error.localizedDescription)")
            }

        case .failure(let error):
            print("File picker failed: \(error.localizedDescription)")
        }
    }

    private func deletePack(_ pack: SoundPack) {
        do {
            try packManager.deleteUserPack(pack)
        } catch {
            print("Delete failed: \(error.localizedDescription)")
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: (Double) -> String

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 80, alignment: .leading)

            Slider(value: $value, in: range)

            Text(format(value))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
        }
    }
}

#Preview {
    SoundTabView()
        .frame(width: 480, height: 500)
}
