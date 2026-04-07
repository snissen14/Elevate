import Foundation

enum ConnectionStatus: String {
    case connected = "Connected"
    case disconnected = "Disconnected"
    case connecting = "Connecting…"
}

enum LockState {
    case locked, unlocked
}

enum MovementCommand {
    case raise, lower, stop
}

@Observable
final class DeviceState {
    var deviceName: String = "Marina Bay – Split 14"
    var connectionStatus: ConnectionStatus = .connected
    var lockState: LockState = .unlocked
    var isLevelEnabled: Bool = false
    var selectedTab: Tab = .controls

    enum Tab: String, CaseIterable {
        case controls = "Controls"
        case led      = "LED"
        case details  = "Details"
    }
}
