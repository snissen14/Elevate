import SwiftUI

struct TabBarView: View {
    @Environment(DeviceState.self) private var device

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DeviceState.Tab.allCases, id: \.self) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .background(
            AppTheme.backgroundCard
                .shadow(color: .black.opacity(0.3), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(_ tab: DeviceState.Tab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                device.selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: iconName(for: tab))
                    .font(.system(size: 18, weight: .medium))

                Text(tab.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(
                device.selectedTab == tab
                    ? AppTheme.accent
                    : AppTheme.textTertiary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                device.selectedTab == tab
                    ? AppTheme.accentMuted
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func iconName(for tab: DeviceState.Tab) -> String {
        switch tab {
        case .controls: "slider.horizontal.3"
        case .led:      "lightbulb.fill"
        case .details:  "info.circle.fill"
        }
    }
}
