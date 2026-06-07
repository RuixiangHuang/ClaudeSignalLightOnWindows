import AppKit

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-CN"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

enum NotificationSound: String, CaseIterable, Identifiable {
    case glass
    case ping
    case pop
    case submarine
    case none

    var id: String { rawValue }

    func displayName(language: AppLanguage) -> String {
        switch (language, self) {
        case (.english, .glass):
            return "Glass (Recommended)"
        case (.english, .ping):
            return "Ping"
        case (.english, .pop):
            return "Pop"
        case (.english, .submarine):
            return "Submarine"
        case (.english, .none):
            return "None"
        case (.simplifiedChinese, .glass):
            return "玻璃清响（推荐）"
        case (.simplifiedChinese, .ping):
            return "清脆 Ping"
        case (.simplifiedChinese, .pop):
            return "轻柔 Pop"
        case (.simplifiedChinese, .submarine):
            return "低沉提醒"
        case (.simplifiedChinese, .none):
            return "静音"
        }
    }

    func preview() {
        guard self != .none else {
            return
        }
        NSSound(named: NSSound.Name(rawValue: soundName))?.play()
    }

    private var soundName: String {
        switch self {
        case .glass:
            return "Glass"
        case .ping:
            return "Ping"
        case .pop:
            return "Pop"
        case .submarine:
            return "Submarine"
        case .none:
            return ""
        }
    }
}
