import AppKit
import SwiftUI

@main
struct ClaudeSignalLightApp: App {
    @StateObject private var monitor = StatusMonitor()
    @AppStorage("language") private var language = AppLanguage.english.rawValue
    @AppStorage("notificationSound") private var notificationSound = NotificationSound.glass.rawValue

    var body: some Scene {
        MenuBarExtra {
            SignalMenu(
                monitor: monitor,
                language: languageBinding,
                notificationSound: soundBinding
            )
        } label: {
            MenuBarStatusIcon(status: monitor.status)
                .accessibilityLabel(
                    monitor.status.localizedName(language: selectedLanguage)
                )
        }
        .menuBarExtraStyle(.menu)
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: language) ?? .english
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { selectedLanguage },
            set: { language = $0.rawValue }
        )
    }

    private var soundBinding: Binding<NotificationSound> {
        Binding(
            get: { NotificationSound(rawValue: notificationSound) ?? .glass },
            set: {
                notificationSound = $0.rawValue
                $0.preview()
            }
        )
    }
}

private struct MenuBarStatusIcon: View {
    let status: AgentStatus

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.08)) { timeline in
            Image(systemName: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(status.color)
                .opacity(opacity(at: timeline.date))
        }
    }

    private func opacity(at date: Date) -> Double {
        guard status == .waiting else {
            return 1
        }
        let phase = date.timeIntervalSinceReferenceDate * .pi
        return 0.55 + (sin(phase) + 1) * 0.225
    }
}
