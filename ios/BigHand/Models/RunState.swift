import Foundation

struct RunState: Equatable, Sendable {
    var x = 210.0
    var targetX = 210.0
    var size: Double
    var maxSize: Double
    var health = 1
    var objectScore = 0
    var baseCoins = 0
    var distance = 0.0
    var elapsed = 0.0
    var score: Int { objectScore + Int((distance * 2 + maxSize * 3).rounded(.down)) }

    init(size: Double) { self.size = size; maxSize = size }
    mutating func grow(by amount: Double) { size = max(1, size + amount); maxSize = max(maxSize, size) }
}

struct RunResult: Identifiable, Sendable {
    let id: UUID
    let state: RunState
    let obstacle: ObjectDefinition
    let coins: Int
    let isHighScore: Bool
    let continued: Bool
    let doubled: Bool
}
