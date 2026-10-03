import Foundation

enum DifficultySystem {
    static func phase(at seconds: Double) -> Int { seconds < 10 ? 0 : seconds < 30 ? 1 : seconds < 60 ? 2 : 3 }
    static func speed(at seconds: Double) -> Double { min(570, 210 + max(0, seconds - 10) * 4.5) }
    static func rowInterval(at seconds: Double) -> Double { max(1.08, 1.6 - max(0, seconds - 10) * 0.008) }
    static func maxObjectSize(at seconds: Double) -> Double {
        [(0.0, 15.0), (8, 35), (12, 70), (16, 180), (24, 360)].last { seconds >= $0.0 }?.1 ?? 15
    }
    static func dangerChance(at seconds: Double) -> Double { [0.18, 0.85, 0.96, 1][phase(at: seconds)] }
    static func doubleDangerChance(at seconds: Double) -> Double { [0.0, 0.3, 0.7, 0.9][phase(at: seconds)] }
    static let notices = ["WARM UP · GET SQUISHING", "KEEP MOVING", "NO EASY LANES", "HOLD ON!"]
}
