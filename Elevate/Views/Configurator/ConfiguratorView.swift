import SwiftUI

struct ConfiguratorView: View {
    @State private var config = LiftConfigurator()
    @State private var heroRotation: Double = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.backgroundPrimary.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    configHeader
                    heroSection
                    configSections
                }
                .padding(.bottom, 100)
            }

            stickyBottomBar
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var configHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.backgroundCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
            }

            Spacer()

            Text("Configure")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            // Balance spacer
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            // Lift illustration
            ZStack {
                // Glow backdrop
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [AppTheme.accent.opacity(0.08), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 180
                        )
                    )
                    .frame(height: 200)

                // Schematic lift icon
                VStack(spacing: 12) {
                    Image(systemName: "square.split.bottomrightquarter")
                        .font(.system(size: 80, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.textPrimary, AppTheme.textSecondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(heroRotation))

                    // Water line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 2)
                        .padding(.horizontal, 60)
                }
            }
            .frame(height: 220)

            // Model name + price
            VStack(spacing: 6) {
                Text(config.selectedModel.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(config.selectedModel.tagline)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Config Sections

    private var configSections: some View {
        VStack(spacing: 32) {
            modelSection
            motorSection
            finishSection
            accessoriesSection
        }
        .padding(.horizontal, 20)
    }

    // MARK: Model

    private var modelSection: some View {
        ConfigSection(title: "Model") {
            VStack(spacing: 10) {
                ForEach(LiftConfigurator.liftModels) { model in
                    let selected = config.selectedModel.id == model.id
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            config.selectedModel = model
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: model.icon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(selected ? AppTheme.accent : AppTheme.textTertiary)
                                .frame(width: 44, height: 44)
                                .background(selected ? AppTheme.accentMuted : AppTheme.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(model.tagline)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }

                            Spacer()

                            Text(formatPrice(model.basePrice))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary)
                        }
                        .padding(14)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Motor

    private var motorSection: some View {
        ConfigSection(title: "Motor") {
            HStack(spacing: 10) {
                ForEach(LiftConfigurator.motors) { motor in
                    let selected = config.selectedMotor.id == motor.id
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            config.selectedMotor = motor
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(motor.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(motor.spec)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(AppTheme.textTertiary)

                            if motor.priceDelta > 0 {
                                Text("+\(formatPrice(motor.priceDelta))")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppTheme.accent)
                            } else {
                                Text("Included")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Finish

    private var finishSection: some View {
        ConfigSection(title: "Finish") {
            VStack(spacing: 16) {
                // Swatches
                HStack(spacing: 16) {
                    ForEach(LiftConfigurator.finishes) { finish in
                        let selected = config.selectedFinish.id == finish.id
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                config.selectedFinish = finish
                            }
                        } label: {
                            Circle()
                                .fill(finish.color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 2.5 : 1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.backgroundPrimary, lineWidth: 3)
                                        .padding(selected ? -1 : 0)
                                        .opacity(selected ? 1 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(AppTheme.accent, lineWidth: 2)
                                        .padding(-4)
                                        .opacity(selected ? 1 : 0)
                                )
                                .scaleEffect(selected ? 1.08 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Selected finish label
                HStack {
                    Text(config.selectedFinish.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    if config.selectedFinish.priceDelta > 0 {
                        Text("+\(formatPrice(config.selectedFinish.priceDelta))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.accent)
                    } else {
                        Text("Included")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: Accessories

    private var accessoriesSection: some View {
        ConfigSection(title: "Accessories") {
            VStack(spacing: 10) {
                ForEach(LiftConfigurator.accessories) { acc in
                    let selected = config.selectedAccessories.contains(acc.id)
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            config.toggleAccessory(acc.id)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: acc.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(selected ? AppTheme.accent : AppTheme.textTertiary)
                                .frame(width: 40, height: 40)
                                .background(selected ? AppTheme.accentMuted : AppTheme.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(acc.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Text(acc.subtitle)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(AppTheme.textTertiary)
                            }

                            Spacer()

                            HStack(spacing: 8) {
                                Text("+\(formatPrice(acc.price))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.textSecondary)

                                // Checkbox
                                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected ? AppTheme.accent : AppTheme.textTertiary)
                            }
                        }
                        .padding(14)
                        .background(AppTheme.backgroundCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusSmall, style: .continuous)
                                .stroke(selected ? AppTheme.accent : AppTheme.border, lineWidth: selected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sticky Bottom Bar

    private var stickyBottomBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Estimated Total")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textTertiary)
                Text(config.formattedPrice)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Spacer()

            Button {
                // order action
            } label: {
                Text("Get Quote")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.backgroundPrimary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            AppTheme.backgroundCard
                .shadow(color: .black.opacity(0.4), radius: 20, y: -8)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Helpers

    private func formatPrice(_ value: Int) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Section wrapper (Tesla-style label + content)

struct ConfigSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .textCase(.uppercase)
                .tracking(1.2)

            content()
        }
    }
}

#Preview {
    ConfiguratorView()
}
