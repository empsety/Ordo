import Combine
import XCTest
@testable import Ordo

@MainActor
final class LocalizationTests: XCTestCase {
    func testCatalogCoverageAndCompiledResources() throws {
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Ordo/Resources/Localizable.xcstrings")
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: source)) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: [String: Any]])
        for (key, entry) in strings {
            let translations = try XCTUnwrap(entry["localizations"] as? [String: [String: Any]])
            for language in AppLanguage.allCases where language != .system {
                let unit = try XCTUnwrap(translations[language.rawValue]?["stringUnit"] as? [String: String])
                let value = try XCTUnwrap(unit["value"])
                XCTAssertFalse(value.isEmpty)
                XCTAssertEqual(value.components(separatedBy: "%@").count, key.components(separatedBy: "%@").count)
                XCTAssertEqual(AppLocalization(language: language).text(key), value)
            }
        }
    }

    func testSystemRefreshAndExplicitOverride() {
        var preferences = ["ja-JP"]
        let defaults = UserDefaults(suiteName: "OrdoTests.Language.\(UUID().uuidString)")!
        let controller = AppController(defaults: defaults, preferredLanguages: { preferences }, accessibilityTrust: { _ in false })
        XCTAssertEqual(controller.localization.language, .japanese)
        preferences = ["ko-KR"]
        controller.refreshLanguage()
        XCTAssertEqual(controller.localization.language, .korean)
        controller.setLanguage(.traditionalChinese)
        preferences = ["en-US"]
        controller.refreshLanguage()
        XCTAssertEqual(controller.localization.language, .traditionalChinese)
        controller.setLanguage(.system)
        XCTAssertEqual(controller.localization.language, .english)
    }

    func testSystemLanguageMatching() {
        for (identifier, expected) in [
            ("zh-CN", AppLanguage.simplifiedChinese), ("zh-SG", .simplifiedChinese),
            ("zh-TW", .traditionalChinese), ("zh-HK", .traditionalChinese),
            ("zh-Hant-CN", .traditionalChinese), ("zh-Hans-HK", .simplifiedChinese),
            ("en-GB", .english), ("ja-JP", .japanese), ("ko-KR", .korean)
        ] {
            XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: [identifier]), expected)
        }
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["fr", "ja"]), .japanese)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: ["fr"]), .english)
        XCTAssertEqual(AppLanguage.system.resolved(preferredLanguages: []), .english)
    }

    func testLanguagePersistenceAndNoOpSelection() {
        let defaults = UserDefaults(suiteName: "OrdoTests.Language.\(UUID().uuidString)")!
        let controller = AppController(defaults: defaults, accessibilityTrust: { _ in false })
        XCTAssertEqual(controller.language, .system)
        controller.mainWindowPage = .about
        let chord = controller.resizeChord
        controller.setLanguage(.japanese)
        XCTAssertEqual(defaults.string(forKey: "ordo.language"), "ja")
        XCTAssertEqual(controller.localization.text("基础"), "基本")
        XCTAssertEqual(controller.mainWindowPage, .about)
        XCTAssertEqual(controller.resizeChord, chord)
        var publications = 0
        let token = controller.objectWillChange.sink { publications += 1 }
        controller.setLanguage(.japanese)
        XCTAssertEqual(publications, 0)
        withExtendedLifetime(token) {}
        let restored = AppController(defaults: defaults, accessibilityTrust: { _ in false })
        XCTAssertEqual(restored.language, .japanese)
        defaults.set("unknown", forKey: "ordo.language")
        XCTAssertEqual(AppController(defaults: defaults, accessibilityTrust: { _ in false }).language, .system)
    }

    func testEveryLanguageHasResourcesAndFormattedVersion() {
        for language in AppLanguage.allCases where language != .system {
            let strings = AppLocalization(language: language)
            XCTAssertNotEqual(strings.text("打开"), "")
            XCTAssertTrue(strings.format("版本 %@（%@）", "1.2", "3").contains("1.2"))
            XCTAssertFalse(strings.format("版本 %@（%@）", "1.2", "3").contains("%@"))
        }
    }
}
