import Foundation
import SwiftUI

/// 偏好保存稳定语言标识；菜单中的语言名称始终使用母语。
enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case english = "en"
    case japanese = "ja"
    case korean = "ko"

    var nativeName: String {
        switch self {
        case .system: "跟随系统"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .english: "English"
        case .japanese: "日本語"
        case .korean: "한국어"
        }
    }

    func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        guard self == .system else { return self }
        for identifier in preferredLanguages {
            let parts = identifier.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-")
            switch parts.first {
            case "zh":
                if parts.contains("hant") { return .traditionalChinese }
                if parts.contains("hans") { return .simplifiedChinese }
                return parts.contains("tw") || parts.contains("hk") || parts.contains("mo")
                    ? .traditionalChinese : .simplifiedChinese
            case "en": return .english
            case "ja": return .japanese
            case "ko": return .korean
            default: continue
            }
        }
        return .english
    }
}

/// 显式选择资源 Bundle，避免系统缓存阻碍 App 内即时切换。
struct AppLocalization: Equatable, Sendable {
    let language: AppLanguage

    init(language: AppLanguage = .system) {
        self.language = language.resolved()
    }

    func text(_ key: String) -> String {
        let bundle = Bundle.main
        guard let path = bundle.path(forResource: language.rawValue, ofType: "lproj"),
              let localized = Bundle(path: path) else { return key }
        return localized.localizedString(forKey: key, value: key, table: "Localizable")
    }

    func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale(identifier: language.rawValue), arguments: arguments)
    }
}

private struct OrdoLocalizationKey: EnvironmentKey {
    static let defaultValue = AppLocalization()
}

extension EnvironmentValues {
    var ordoLocalization: AppLocalization {
        get { self[OrdoLocalizationKey.self] }
        set { self[OrdoLocalizationKey.self] = newValue }
    }
}
