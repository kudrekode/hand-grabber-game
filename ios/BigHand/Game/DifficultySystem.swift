import Foundation

enum DifficultySystem {
    static func phase(at seconds: Double) -> Int { seconds < 6 ? 0 : seconds < 18 ? 1 : seconds < 35 ? 2 : 3 }
    static func speed(at seconds: Double) -> Double { min(GameBalance.maximumSpeed, GameBalance.startingSpeed + max(0, seconds - 3) * 14) }
    static func rowInterval(at seconds: Double) -> Double { max(0.72, 1.25 - max(0, seconds - 3) * 0.02) }
    static func maxObjectSize(at seconds: Double) -> Double {
        if seconds >= 18 { return 360 * pow(1 + (seconds - 18) / 30, 1.6) }
        return [(0.0, 15.0), (4, 35), (7, 70), (11, 180)].last { seconds >= $0.0 }?.1 ?? 15
    }
    static func dangerChance(at seconds: Double) -> Double { [0.3, 0.9, 0.98, 1][phase(at: seconds)] }
    static func doubleDangerChance(at seconds: Double) -> Double { [0.0, 0.5, 0.85, 0.95][phase(at: seconds)] }
    static let notices = ["WARM UP · GET SQUISHING", "KEEP MOVING", "NO EASY LANES", "HOLD ON!"]
}
