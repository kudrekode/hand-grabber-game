import Foundation

enum GameBalance {
    static let width = 420.0
    static let height = 800.0
    static let lanes = [77.0, 210.0, 343.0]
    static let handY = 185.0
    static let startingSize = 20.0
    static let crushGrowth = 0.015
    static let steeringResponse = 24.0
    static let distanceScale = 0.045
    static let upgradeCosts = [75, 180, 450, 1_200, 3_000, 7_000, 16_000, 36_000]
    static var maxUpgradeLevel: Int { upgradeCosts.count }
    static let startingSpeed = 280.0
    static let maximumSpeed = 760.0
    static let stageThresholds = [30.0, 80.0, 160.0, 500.0]

    static func stage(_ size: Double) -> String {
        ["TINY", "NORMAL", "LARGE", "HUGE", "ABSURD"][stageThresholds.firstIndex { size < $0 } ?? 4]
    }

    static func handScale(_ size: Double) -> Double {
        let sizes = [1.0] + stageThresholds
        let scales = [0.65, 1.0, 1.35, 1.75, 2.4]
        for i in 1..<sizes.count where size < sizes[i] {
            let fraction = max(0, (size - sizes[i - 1]) / (sizes[i] - sizes[i - 1]))
            return 0.7 + (scales[i - 1] + fraction * (scales[i] - scales[i - 1]) - 0.65) * 0.63
        }
        return 0.7 + (2.4 - 0.65) * 0.63
    }
}
