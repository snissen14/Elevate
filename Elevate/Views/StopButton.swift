import SwiftUI

struct StopButton: View {
    var body: some View {
        Button {
            // stop action
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 22, weight: .medium))

                Text("Stop")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMedium, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
