import SwiftUI

enum AgentStatus: String, Codable {
    case running
    case waiting
    case done

    var color: Color {
        switch self {
        case .running:
            return Color(red: 0.19, green: 0.82, blue: 0.49)
        case .waiting:
            return Color(red: 1.0, green: 0.78, blue: 0.24)
        case .done:
            return Color(red: 1.0, green: 0.22, blue: 0.28)
        }
    }

    func localizedName(language: AppLanguage) -> String {
        switch (language, self) {
        case (.english, .running):
            return "Running"
        case (.english, .waiting):
            return "Action required"
        case (.english, .done):
            return "Done"
        case (.simplifiedChinese, .running):
            return "运行中"
        case (.simplifiedChinese, .waiting):
            return "待操作"
        case (.simplifiedChinese, .done):
            return "已完成"
        }
    }
}

struct AgentState: Codable, Equatable {
    let status: AgentStatus
    let message: String
    let sessionId: String?
    let cwd: String?
    let updatedAt: String?
    let source: String?

    static let idle = AgentState(
        status: .done,
        message: "Waiting for Claude Code",
        sessionId: nil,
        cwd: nil,
        updatedAt: nil,
        source: nil
    )

    var projectName: String {
        guard let cwd, !cwd.isEmpty else {
            return "Claude"
        }
        return URL(fileURLWithPath: cwd).lastPathComponent
    }

    var shortSessionId: String {
        guard let sessionId, !sessionId.isEmpty else {
            return "-"
        }
        return String(sessionId.prefix(8))
    }
}
