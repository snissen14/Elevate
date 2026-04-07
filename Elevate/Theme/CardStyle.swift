import SwiftUI

// MARK: - Reusable card modifier

struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.radiusMedium
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(radius: CGFloat = AppTheme.radiusMedium, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: radius, padding: padding))
    }
}
