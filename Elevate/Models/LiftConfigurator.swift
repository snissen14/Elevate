import SwiftUI

// MARK: - Configurator Data Model

@Observable
final class LiftConfigurator {

    // MARK: Lift model

    struct LiftModel: Identifiable, Hashable {
        let id: String
        let name: String
        let tagline: String
        let icon: String
        let basePrice: Int
    }

    static let liftModels: [LiftModel] = [
        .init(id: "split14", name: "Split 14",  tagline: "14,000 lb · Dual Beam",   icon: "arrow.up.left.and.arrow.down.right", basePrice: 8_950),
        .init(id: "split16", name: "Split 16",  tagline: "16,000 lb · Dual Beam",   icon: "arrow.up.left.and.arrow.down.right", basePrice: 10_450),
        .init(id: "mono12",  name: "Mono 12",   tagline: "12,000 lb · Single Beam", icon: "arrow.up.to.line",                  basePrice: 7_250),
        .init(id: "mono20",  name: "Mono 20",   tagline: "20,000 lb · Single Beam", icon: "arrow.up.to.line",                  basePrice: 13_900),
    ]

    // MARK: Motor

    struct Motor: Identifiable, Hashable {
        let id: String
        let name: String
        let spec: String
        let priceDelta: Int
    }

    static let motors: [Motor] = [
        .init(id: "standard",  name: "Standard",   spec: "1 HP · 110V",   priceDelta: 0),
        .init(id: "highspeed", name: "High-Speed",  spec: "1.5 HP · 110V", priceDelta: 650),
        .init(id: "premium",   name: "Premium",     spec: "2 HP · 220V",   priceDelta: 1_400),
    ]

    // MARK: Finish

    struct Finish: Identifiable, Hashable {
        let id: String
        let name: String
        let color: Color
        let priceDelta: Int
    }

    static let finishes: [Finish] = [
        .init(id: "galvanized", name: "Galvanized",     color: Color(hex: "9CA3AF"), priceDelta: 0),
        .init(id: "white",      name: "Arctic White",   color: Color(hex: "E8E8E8"), priceDelta: 450),
        .init(id: "black",      name: "Midnight Black", color: Color(hex: "1F2937"), priceDelta: 450),
        .init(id: "navy",       name: "Nautical Blue",  color: Color(hex: "1E3A5F"), priceDelta: 550),
        .init(id: "bronze",     name: "Bronze",         color: Color(hex: "8B6914"), priceDelta: 550),
    ]

    // MARK: Accessories

    struct Accessory: Identifiable, Hashable {
        let id: String
        let name: String
        let subtitle: String
        let icon: String
        let price: Int
    }

    static let accessories: [Accessory] = [
        .init(id: "bunkboards",  name: "Bunk Boards",       subtitle: "Carpeted composite",     icon: "rectangle.split.2x1",         price: 320),
        .init(id: "guidepoles",  name: "Guide Poles",        subtitle: "60\" PVC w/ LED caps",    icon: "arrow.up.and.down.and.sparkles", price: 280),
        .init(id: "ledkit",      name: "Underwater LED Kit", subtitle: "RGBW · App-controlled",  icon: "lightbulb.fill",              price: 475),
        .init(id: "remote",      name: "Wireless Remote",    subtitle: "300 ft range · Keyfob",  icon: "antenna.radiowaves.left.and.right", price: 195),
        .init(id: "solar",       name: "Solar Charger",      subtitle: "30W panel + controller", icon: "sun.max.fill",                price: 385),
    ]

    // MARK: - State

    var selectedModel: LiftModel    = liftModels[0]
    var selectedMotor: Motor        = motors[0]
    var selectedFinish: Finish      = finishes[0]
    var selectedAccessories: Set<String> = []

    // MARK: - Computed

    var totalPrice: Int {
        selectedModel.basePrice
        + selectedMotor.priceDelta
        + selectedFinish.priceDelta
        + Self.accessories
            .filter { selectedAccessories.contains($0.id) }
            .reduce(0) { $0 + $1.price }
    }

    var formattedPrice: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.maximumFractionDigits = 0
        return fmt.string(from: NSNumber(value: totalPrice)) ?? "$\(totalPrice)"
    }

    func toggleAccessory(_ id: String) {
        if selectedAccessories.contains(id) {
            selectedAccessories.remove(id)
        } else {
            selectedAccessories.insert(id)
        }
    }
}
