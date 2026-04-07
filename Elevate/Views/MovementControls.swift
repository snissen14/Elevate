import SwiftUI

struct MovementControls: View {
    var body: some View {
        VStack(spacing: 2) {
            // Raise
            movementButton(
                label: "Raise",
                icon: "chevron.up",
                iconOnTop: true
            )

            // Lower
            movementButton(
                label: "Lower",
                icon: "chevron.down",
                iconOnTop: false
            )
        }
        .background(AppTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusLarge, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func movementButton(label: String, icon: String, iconOnTop: Bool) -> some View {
        Button {
            // movement action
        } label: {
            VStack(spacing: 6) {
                if iconOnTop {
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    Text(label)
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                }
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(AppTheme.backgroundElevated.opacity(0.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(MovementButtonStyle())
    }
}

// MARK: - Button press style

struct MovementButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? AppTheme.accentMuted
                    : Color.clear
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
