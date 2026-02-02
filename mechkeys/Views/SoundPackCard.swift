//
//  SoundPackCard.swift
//  MechKeys
//

import SwiftUI

struct SoundPackCard: View {
    let pack: SoundPack
    let isSelected: Bool
    let onSelect: () -> Void
    let onPreview: () -> Void
    let onDelete: (() -> Void)?

    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.headline)
                        .lineLimit(1)

                    if !pack.isBuiltIn {
                        Label("Custom", systemImage: "person.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }

            Text(pack.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Spacer()

            HStack {
                Button {
                    onPreview()
                } label: {
                    Label("Preview", systemImage: "play.fill")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                if let onDelete = onDelete, !pack.isBuiltIn {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .opacity(isHovering ? 1 : 0)
                }
            }
        }
        .padding(12)
        .frame(height: 120)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    HStack {
        SoundPackCard(
            pack: SoundPack(
                id: "test",
                manifest: SoundPackManifest(
                    name: "Cherry MX Blue",
                    description: "Clicky, loud, tactile",
                    author: "MechKeys",
                    version: "1.0"
                ),
                url: URL(fileURLWithPath: "/"),
                isBuiltIn: true
            ),
            isSelected: true,
            onSelect: {},
            onPreview: {},
            onDelete: nil
        )
        .frame(width: 200)

        SoundPackCard(
            pack: SoundPack(
                id: "custom",
                manifest: SoundPackManifest(
                    name: "Custom Pack",
                    description: "User imported pack",
                    author: "User",
                    version: "1.0"
                ),
                url: URL(fileURLWithPath: "/"),
                isBuiltIn: false
            ),
            isSelected: false,
            onSelect: {},
            onPreview: {},
            onDelete: {}
        )
        .frame(width: 200)
    }
    .padding()
}
