import SwiftUI

struct DeviceCard: View {
    @Environment(DeviceState.self) private var device

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.deviceName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(device.connectionStatus.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .frame(width: 36, height: 36)
                .background(AppTheme.backgroundElevated)
                .clipShape(Circle())
        }
        .cardStyle(radius: AppTheme.radiusMedium)
    }

    private var statusColor: Color {
        switch device.connectionStatus {
        case .connected:    AppTheme.connected
        case .connecting:   .orange
        case .disconnected: AppTheme.textTertiary
        }
    }
}
