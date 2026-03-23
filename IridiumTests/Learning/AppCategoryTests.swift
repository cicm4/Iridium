//
//  AppCategoryTests.swift
//  IridiumTests
//

import Testing
@testable import Iridium

@Suite("AppCategory")
struct AppCategoryTests {

    // MARK: - LSApplicationCategoryType mapping

    @Test("LSApplicationCategoryType: developer-tools → development")
    func lsCategoryDeveloperTools() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.developer-tools") == .development)
    }

    @Test("LSApplicationCategoryType: graphics-design → creativity")
    func lsCategoryGraphicsDesign() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.graphics-design") == .creativity)
    }

    @Test("LSApplicationCategoryType: productivity → productivity")
    func lsCategoryProductivity() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.productivity") == .productivity)
    }

    @Test("LSApplicationCategoryType: social-networking → communication")
    func lsCategorySocial() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.social-networking") == .communication)
    }

    @Test("LSApplicationCategoryType: education → research")
    func lsCategoryEducation() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.education") == .research)
    }

    @Test("LSApplicationCategoryType: video → media")
    func lsCategoryVideo() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.video") == .media)
    }

    @Test("LSApplicationCategoryType: utilities → utility")
    func lsCategoryUtilities() {
        #expect(AppCategory.from(lsCategoryType: "public.app-category.utilities") == .utility)
    }

    @Test("LSApplicationCategoryType: nil → other")
    func lsCategoryNil() {
        #expect(AppCategory.from(lsCategoryType: nil) == .other)
    }

    // MARK: - Bundle ID fallback mapping

    @Test("Bundle ID: Xcode → development")
    func bundleIDXcode() {
        #expect(AppCategory.from(bundleID: "com.apple.dt.Xcode") == .development)
    }

    @Test("Bundle ID: Cursor → development")
    func bundleIDCursor() {
        #expect(AppCategory.from(bundleID: "com.todesktop.230313mzl4w4u92") == .development)
    }

    @Test("Bundle ID: VSCode → development")
    func bundleIDVSCode() {
        #expect(AppCategory.from(bundleID: "com.microsoft.VSCode") == .development)
    }

    @Test("Bundle ID: Figma → creativity")
    func bundleIDFigma() {
        #expect(AppCategory.from(bundleID: "com.figma.Desktop") == .creativity)
    }

    @Test("Bundle ID: Safari → research")
    func bundleIDSafari() {
        #expect(AppCategory.from(bundleID: "com.apple.Safari") == .research)
    }

    @Test("Bundle ID: Slack → communication")
    func bundleIDSlack() {
        #expect(AppCategory.from(bundleID: "com.tinyspeck.slackmacgap") == .communication)
    }

    @Test("Bundle ID: Pages → productivity")
    func bundleIDPages() {
        #expect(AppCategory.from(bundleID: "com.apple.iWork.Pages") == .productivity)
    }

    @Test("Bundle ID: unknown → other")
    func bundleIDUnknown() {
        #expect(AppCategory.from(bundleID: "com.unknown.app") == .other)
    }
}
