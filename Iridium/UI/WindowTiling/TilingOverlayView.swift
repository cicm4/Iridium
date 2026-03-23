//
//  TilingOverlayView.swift
//  Iridium
//

import SwiftUI

struct TilingOverlayView: View {
    let presets: [LayoutPreset]
    let screenFrame: CGRect
    let solver: LayoutSolver

    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.2)

            // Zone rectangles
            ForEach(Array(presets.enumerated()), id: \.element.id) { index, preset in
                let frames = solver.resolve(preset: preset, in: screenFrame)
                if let frame = frames.first {
                    zoneView(index: index + 1, preset: preset, frame: frame)
                }
            }

            // Help text
            VStack {
                Spacer()
                Text("Press a number to snap window, Esc to cancel")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea()
    }

    private func zoneView(index: Int, preset: LayoutPreset, frame: CGRect) -> some View {
        // Convert absolute frame to relative position within the screen
        let relX = (frame.origin.x - screenFrame.origin.x) / screenFrame.width
        let relY = (frame.origin.y - screenFrame.origin.y) / screenFrame.height
        let relW = frame.width / screenFrame.width
        let relH = frame.height / screenFrame.height

        return GeometryReader { geo in
            let x = relX * geo.size.width
            let y = (1.0 - relY - relH) * geo.size.height // Flip Y for SwiftUI
            let w = relW * geo.size.width
            let h = relH * geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.8)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor.opacity(0.6), lineWidth: 2)

                VStack(spacing: 4) {
                    Text("\(index)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(preset.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: max(w - 12, 0), height: max(h - 12, 0))
            .position(x: x + w / 2, y: y + h / 2)
        }
    }
}
