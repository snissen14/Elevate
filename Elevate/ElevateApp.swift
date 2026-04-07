import SwiftUI

@main
struct ElevateApp: App {
    @State private var device = DeviceState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(device)
        }
    }
}
