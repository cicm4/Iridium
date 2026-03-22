//
//  LayoutSolver.swift
//  Iridium
//

import CoreGraphics

struct LayoutSolver: Sendable {
    /// Converts a layout preset's fractional regions to absolute screen coordinates.
    func resolve(preset: LayoutPreset, in screenFrame: CGRect) -> [CGRect] {
        preset.regions.map { region in
            CGRect(
                x: screenFrame.origin.x + region.x * screenFrame.width,
                y: screenFrame.origin.y + region.y * screenFrame.height,
                width: region.width * screenFrame.width,
                height: region.height * screenFrame.height
            )
        }
    }

    /// Creates a grid layout with the given number of columns and rows.
    func grid(columns: Int, rows: Int, in screenFrame: CGRect) -> [CGRect] {
        guard columns > 0, rows > 0 else { return [] }

        let cellWidth = screenFrame.width / CGFloat(columns)
        let cellHeight = screenFrame.height / CGFloat(rows)

        var cells: [CGRect] = []
        for row in 0..<rows {
            for col in 0..<columns {
                cells.append(CGRect(
                    x: screenFrame.origin.x + CGFloat(col) * cellWidth,
                    y: screenFrame.origin.y + CGFloat(row) * cellHeight,
                    width: cellWidth,
                    height: cellHeight
                ))
            }
        }
        return cells
    }
}
