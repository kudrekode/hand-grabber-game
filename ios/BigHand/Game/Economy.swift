import Foundation

enum Economy {
    static func growth(objectSize: Double, multiplier: Double) -> Double { objectSize * GameBalance.crushGrowth * multiplier }
    static func coins(base: Int, multiplier: Double) -> Int { Int(floor(Double(base) * multiplier + 1e-9)) }
}

// Bank deltas, rather than whole totals: continue and double can never pay the same coins twice.
struct RewardLedger {
    private(set) var banked = 0
    private(set) var doubled = false
    mutating func settle(earned: Int) -> Int {
        let total = earned * (doubled ? 2 : 1)
        let delta = max(0, total - banked)
        banked += delta
        return delta
    }
    mutating func double(earned: Int) -> Int {
        guard !doubled else { return 0 }
        doubled = true
        return settle(earned: earned)
    }
}
