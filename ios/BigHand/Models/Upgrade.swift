import Foundation

enum Upgrade: String, Codable, CaseIterable, Identifiable, Sendable {
    case start, growth, handling, coins, luck
    var id: String { rawValue }
    var title: String {
        switch self {
        case .start: "Starting Hand Size"
        case .growth: "Crush Growth"
        case .handling: "Handling"
        case .coins: "Coin Multiplier"
        case .luck: "Lucky Gates"
        }
    }
    var detail: String {
        switch self {
        case .start: "Bigger from the first second."
        case .growth: "More size from every crush."
        case .handling: "A quicker response to your thumb."
        case .coins: "Every reward goes further."
        case .luck: "More pairs with two helpful gates."
        }
    }
    func effectLabel(level: Int) -> String {
        switch self {
        case .start: "Size \(20 + level * 5)"
        case .growth: "Growth \(100 + level * 30)%"
        case .handling: "Response \(100 + level * 15)%"
        case .coins: String(format: "Coins ×%.1f", 1 + Double(level) * 0.2)
        case .luck: "Helpful pair \(10 + level * 5)%"
        }
    }
    func cost(at level: Int) -> Int? {
        GameBalance.upgradeCosts.indices.contains(level) ? GameBalance.upgradeCosts[level] : nil
    }
}

struct UpgradeEffects: Equatable, Sendable {
    let startingSize: Double
    let growth: Double
    let handling: Double
    let coinMultiplier: Double
    let positiveGateChance: Double

    init(levels: [Upgrade: Int]) {
        func level(_ upgrade: Upgrade) -> Double { Double(min(GameBalance.maxUpgradeLevel, max(0, levels[upgrade, default: 0]))) }
        startingSize = 20 + level(.start) * 5
        growth = 1 + level(.growth) * 0.3
        handling = 1 + level(.handling) * 0.15
        coinMultiplier = 1 + level(.coins) * 0.2
        positiveGateChance = 0.1 + level(.luck) * 0.05
    }
}
