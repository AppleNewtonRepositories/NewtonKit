

import Foundation
import newch


class CommandPrompt {

    private enum State {
        case idle
        case initiatingKeyboardPassthrough
        case keyboardPassthrough
    }

    private enum Command: String {
        case keyboard
    }

    private var state: State = .idle

    private let dockConnectionLayer: DockConnectionLayer

    init(dockConnectionLayer: DockConnectionLayer) {
        self.dockConnectionLayer = dockConnectionLayer
    }

    private func prompt() -> String? {
        print("[\(state)] ? ", terminator: "")
        return readLine()
    }

    private func startKeyboardPassthrough() throws {
        let dockState = dockConnectionLayer.state
        guard dockState == .connected else {
            print("Can't connect in dock connection state: \(dockState)")
            return
        }

        state = .initiatingKeyboardPassthrough
        try dockConnectionLayer.startKeyboardPassthrough()
    }

    private func sendKeyboardString(_ line: String) throws {
        guard state == .keyboardPassthrough else {
            print("Can't send keyboard string in state: \(state)")
            return
        }

        try dockConnectionLayer.sendKeyboardString(line)
    }

    func handleDockConnectionState(state: DockConnectionLayer.State) {
        switch self.state {
        case .initiatingKeyboardPassthrough:
            if state == .keyboardPassthrough {
                print("keyboard passthrough active\n")
                self.state = .keyboardPassthrough
            }
        default:
            break
        }
    }

    func start() throws {
        while let line = prompt() {
            guard !line.isEmpty else {
                continue
            }

            switch state {
            case .idle:
                if let command = Command(rawValue: line) {
                    switch command {
                    case .keyboard:
                        try startKeyboardPassthrough()
                    }
                }
            case .keyboardPassthrough:
                try sendKeyboardString(line)
            default:
                continue
            }
        }
    }
}
