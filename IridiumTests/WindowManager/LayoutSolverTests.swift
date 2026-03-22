//
//  LayoutSolverTests.swift
//  IridiumTests
//

import Testing
import CoreGraphics
@testable import Iridium

struct LayoutSolverTests {
    let solver = LayoutSolver()
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    // MARK: - Preset Resolution

    @Test func leftHalfPreset() {
        let frames = solver.resolve(preset: .leftHalf, in: screen)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame.origin.x == 0)
        #expect(frame.origin.y == 0)
        #expect(frame.width == 960) // half of 1920
        #expect(frame.height == 1080)
    }

    @Test func rightHalfPreset() {
        let frames = solver.resolve(preset: .rightHalf, in: screen)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame.origin.x == 960)
        #expect(frame.width == 960)
    }

    @Test func fullscreenPreset() {
        let frames = solver.resolve(preset: .fullscreen, in: screen)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame == screen)
    }

    // MARK: - Screen Offset

    @Test func handlesScreenOffset() {
        let offsetScreen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let frames = solver.resolve(preset: .leftHalf, in: offsetScreen)
        #expect(frames[0].origin.x == 1920) // Starts at the offset
        #expect(frames[0].width == 960)
    }

    // MARK: - Grid Layout

    @Test func twoByTwoGrid() {
        let cells = solver.grid(columns: 2, rows: 2, in: screen)
        #expect(cells.count == 4)

        // Top-left
        #expect(cells[0].origin.x == 0)
        #expect(cells[0].origin.y == 0)
        #expect(cells[0].width == 960)
        #expect(cells[0].height == 540)

        // Top-right
        #expect(cells[1].origin.x == 960)
        #expect(cells[1].origin.y == 0)

        // Bottom-left
        #expect(cells[2].origin.x == 0)
        #expect(cells[2].origin.y == 540)

        // Bottom-right
        #expect(cells[3].origin.x == 960)
        #expect(cells[3].origin.y == 540)
    }

    @Test func threeColumnGrid() {
        let cells = solver.grid(columns: 3, rows: 1, in: screen)
        #expect(cells.count == 3)
        #expect(cells[0].width == 640) // 1920 / 3
        #expect(cells[1].origin.x == 640)
        #expect(cells[2].origin.x == 1280)
    }

    @Test func zeroColumnsReturnsEmpty() {
        let cells = solver.grid(columns: 0, rows: 2, in: screen)
        #expect(cells.isEmpty)
    }

    @Test func zeroRowsReturnsEmpty() {
        let cells = solver.grid(columns: 2, rows: 0, in: screen)
        #expect(cells.isEmpty)
    }
}
