import SwiftUI

struct ContentView: View {
    @Environment(DeviceState.self) private var device
    @State private var showConfigurator = false

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(showConfigurator: $showConfigurator)
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
        .fullScreenCover(isPresented: $showConfigurator) {
            ConfiguratorView()
        }
    }
}

#Preview {
    ContentView()
        .environment(DeviceState())
}
