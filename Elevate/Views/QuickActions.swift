import SwiftUI

struct QuickActions: View {
    @Environment(DeviceState.self) private var device

    var body: some View {
        HStack(spacing: 12) {
            // Lock / Unlock
            quickActionTile(
                icon: device.lockState == .locked ? "lock.fill" : "lock.open.fill",
                title: device.lockState == .locked ? "Locked" : "Unlocked",
                subtitle: device.lockState == .locked ? "Tap to unlock" : "Tap to lock",
                isActive: device.lockState == .locked
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    device.lockState = device.lockState == .locked ? .unlocked : .locked
                }
            }

            // Level
            quickActionTile(
                icon: "level.fill",
                title: "Level",
                subtitle: "Hold 5s to enable",
                isActive: device.isLevelEnabled
            ) {
                // level action
            }
        }
    }

    private func quickActionTile(
        icon: String,
        title: String,
        subtitle: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isActive ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        isActive ? AppTheme.accentMuted : AppTheme.backgroundElevated
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppTheme.textTertiary)
                }

                Spacer()
            }
            .cardStyle(radius: AppTheme.radiusSmall, padding: 12)
        }
        .buttonStyle(.plain)
    }
}
