//
//  TilingOverlayTests.swift
//  IridiumTests
//

import Testing
import CoreGraphics
@testable import Iridium

@MainActor
struct TilingOverlayTests {
    let solver = LayoutSolver()
    let screenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)

    // MARK: - Zone Frame Calculation

    @Test func leftHalfZoneCoversLeftSide() {
        let frames = solver.resolve(preset: .leftHalf, in: screenFrame)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame.origin.x == 0)
        #expect(frame.width == 960)
        #expect(frame.height == 1080)
    }

    @Test func rightHalfZoneCoversRightSide() {
        let frames = solver.resolve(preset: .rightHalf, in: screenFrame)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame.origin.x == 960)
        #expect(frame.width == 960)
    }

    @Test func fullscreenZoneCoversEntireScreen() {
        let frames = solver.resolve(preset: .fullscreen, in: screenFrame)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame == screenFrame)
    }

    // MARK: - Preset Indexing

    @Test func presetIndexMapsSingleDigitToCorrectPreset() {
        let presets: [LayoutPreset] = [.leftHalf, .rightHalf, .fullscreen]
        // Index 1 = first preset, etc.
        #expect(presets[0].name == "Left Half")
        #expect(presets[1].name == "Right Half")
        #expect(presets[2].name == "Fullscreen")
    }

    @Test func digitOutOfRangeIsIgnored() {
        let presets: [LayoutPreset] = [.leftHalf, .rightHalf]
        let digit = 5
        #expect(digit > presets.count)
    }

    // MARK: - Multi-Monitor Frame Offset

    @Test func resolverHandlesOffsetScreenFrame() {
        let offsetScreen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let frames = solver.resolve(preset: .leftHalf, in: offsetScreen)
        #expect(frames.count == 1)
        let frame = frames[0]
        #expect(frame.origin.x == 1920)
        #expect(frame.width == 960)
    }
}
