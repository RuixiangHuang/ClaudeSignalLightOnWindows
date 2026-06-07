import AppKit
import Foundation

@MainActor
final class StatusMonitor: ObservableObject {
    @Published private(set) var state = AgentState.idle

    private var timer: Timer?
    private var previousStatus = AgentStatus.done
    private var hasLoadedState = false
    private let statusURL: URL

    var status: AgentStatus {
        state.status
    }

    init() {
        statusURL = RuntimePaths.statusFile
        RuntimePaths.ensureDirectory()
        refresh()

        timer = Timer.scheduledTimer(
            withTimeInterval: 0.75,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    func refresh() {
        guard
            let data = try? Data(contentsOf: statusURL),
            let nextState = try? JSONDecoder().decode(AgentState.self, from: data)
        else {
            return
        }

        if hasLoadedState, nextState.status == .waiting, previousStatus != .waiting {
            selectedSound.preview()
        }

        previousStatus = nextState.status
        state = nextState
        hasLoadedState = true
    }

    private var selectedSound: NotificationSound {
        let rawValue = UserDefaults.standard.string(forKey: "notificationSound")
        return NotificationSound(rawValue: rawValue ?? "") ?? .glass
    }
}

enum RuntimePaths {
    static let directory: URL = {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return base.appendingPathComponent(
            "ClaudeSignalLight",
            isDirectory: true
        )
    }()

    static let statusFile = directory.appendingPathComponent("status.json")

    static func ensureDirectory() {
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }
}
