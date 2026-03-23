//
//  KeywordTaskResolverTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@Suite("KeywordTaskResolver")
struct KeywordTaskResolverTests {

    let resolver = KeywordTaskResolver()

    // MARK: - Development tasks

    @Test("'coding' resolves to development category")
    func codingResolves() async {
        let result = await resolver.resolve(description: "coding a new feature")
        #expect(result[.development] != nil, "Should resolve to development")
        #expect(result[.development]! >= 0.8, "Development weight should be high: \(result[.development]!)")
    }

    @Test("'software project' resolves to development")
    func softwareProjectResolves() async {
        let result = await resolver.resolve(description: "working on a software project")
        #expect(result[.development] != nil)
    }

    @Test("'debugging API' resolves to development")
    func debuggingAPIResolves() async {
        let result = await resolver.resolve(description: "debugging an API issue")
        #expect(result[.development] != nil)
    }

    // MARK: - Video / Media tasks

    @Test("'editing a video' resolves to media + creativity")
    func videoEditingResolves() async {
        let result = await resolver.resolve(description: "editing a video")
        #expect(result[.media] != nil, "Should resolve to media")
        #expect(result[.creativity] != nil, "Should also resolve to creativity")
        #expect(result[.media]! >= 0.7)
        #expect(result[.creativity]! >= 0.7)
    }

    @Test("'film production' resolves to media")
    func filmProductionResolves() async {
        let result = await resolver.resolve(description: "film production and color grading")
        #expect(result[.media] != nil)
    }

    // MARK: - Writing tasks

    @Test("'writing thesis' resolves to productivity + research")
    func writingThesisResolves() async {
        let result = await resolver.resolve(description: "writing my thesis")
        #expect(result[.productivity] != nil, "Should resolve to productivity")
        #expect(result[.research] != nil, "Should resolve to research")
    }

    @Test("'blog post' resolves to productivity")
    func blogPostResolves() async {
        let result = await resolver.resolve(description: "writing a blog post about tech")
        #expect(result[.productivity] != nil)
    }

    // MARK: - Design tasks

    @Test("'UI design' resolves to creativity")
    func uiDesignResolves() async {
        let result = await resolver.resolve(description: "UI design in Figma")
        #expect(result[.creativity] != nil)
        #expect(result[.creativity]! >= 0.8)
    }

    // MARK: - Communication tasks

    @Test("'email and meetings' resolves to communication")
    func emailMeetingsResolves() async {
        let result = await resolver.resolve(description: "catching up on email and meetings")
        #expect(result[.communication] != nil)
        #expect(result[.communication]! >= 0.8)
    }

    // MARK: - Research tasks

    @Test("'academic research' resolves to research")
    func academicResearchResolves() async {
        let result = await resolver.resolve(description: "academic research for my paper")
        #expect(result[.research] != nil)
        #expect(result[.research]! >= 0.8)
    }

    // MARK: - Edge cases

    @Test("Unknown input returns empty categories")
    func unknownReturnsEmpty() async {
        let result = await resolver.resolve(description: "xyzzy foobar baz")
        #expect(result.isEmpty, "Unknown keywords should produce empty categories")
    }

    @Test("Empty string returns empty categories")
    func emptyReturnsEmpty() async {
        let result = await resolver.resolve(description: "")
        #expect(result.isEmpty)
    }

    @Test("Case insensitive matching")
    func caseInsensitive() async {
        let result = await resolver.resolve(description: "VIDEO EDITING PROJECT")
        #expect(result[.media] != nil, "Should match regardless of case")
    }

    @Test("Multi-keyword matching combines categories")
    func multiKeywordCombines() async {
        let result = await resolver.resolve(description: "coding a web design project")
        #expect(result[.development] != nil, "Should match 'coding'")
        #expect(result[.creativity] != nil, "Should match 'design'")
    }
}
