import SwiftUI

struct ContentView: View {
    @Environment(DeviceState.self) private var device

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView()
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        DeviceCard()
                        QuickActions()
                        MovementControls()
                        StopButton()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }

                TabBarView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(DeviceState())
}
