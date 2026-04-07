import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            // Logo
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.accent)

                Text("Elevate")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            // Settings
            Button {
                // settings action
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.backgroundCard)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(AppTheme.border, lineWidth: 1)
                    )
            }
        }
    }
}
