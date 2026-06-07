import AppKit
import SwiftUI

struct SignalMenu: View {
    @ObservedObject var monitor: StatusMonitor
    @Binding var language: AppLanguage
    @Binding var notificationSound: NotificationSound

    var body: some View {
        Group {
            Label {
                Text(monitor.status.localizedName(language: language))
            } icon: {
                Image(systemName: "circle.fill")
                    .foregroundStyle(monitor.status.color)
            }

            Text(monitor.state.projectName)
            Text("Session: \(monitor.state.shortSessionId)")
            Text(monitor.state.message)

            Divider()

            Menu(text("language")) {
                ForEach(AppLanguage.allCases) { item in
                    Button {
                        language = item
                    } label: {
                        checkmarkedLabel(
                            title: item.displayName,
                            selected: language == item
                        )
                    }
                }
            }

            Menu(text("notificationSound")) {
                ForEach(NotificationSound.allCases) { sound in
                    Button {
                        notificationSound = sound
                    } label: {
                        checkmarkedLabel(
                            title: sound.displayName(language: language),
                            selected: notificationSound == sound
                        )
                    }
                }
            }

            Divider()

            Button(text("refresh")) {
                monitor.refresh()
            }

            Button(text("quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private func checkmarkedLabel(title: String, selected: Bool) -> some View {
        if selected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    private func text(_ key: String) -> String {
        let translations: [String: (String, String)] = [
            "language": ("Language", "语言"),
            "notificationSound": ("Notification Sound", "提示音"),
            "refresh": ("Refresh", "刷新"),
            "quit": ("Quit", "退出")
        ]
        let pair = translations[key] ?? (key, key)
        return language == .english ? pair.0 : pair.1
    }
}
