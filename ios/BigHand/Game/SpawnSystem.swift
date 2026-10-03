import Foundation

enum SpawnKind: Equatable { case object(ObjectDefinition), gate(GateDefinition) }
struct SpawnItem: Equatable { let lane: Int; let kind: SpawnKind }
struct SpawnRow { let number: Int; let items: [SpawnItem]; let safeLanes: [Int] }

struct SpawnSystem {
    private(set) var row = 0
    private(set) var previousSafeLanes = [1]

    mutating func next<R: RandomNumberGenerator>(run: RunState, effects: UpgradeEffects, using random: inout R) -> SpawnRow {
        row += 1
        let reachable = (0...2).filter { lane in previousSafeLanes.allSatisfy { abs(lane - $0) <= 1 } }
        let preferred = reachable.filter { !previousSafeLanes.contains($0) }
        let pool = !preferred.isEmpty && Double.random(in: 0..<1, using: &random) < 0.85 ? preferred : reachable
        let route = pool.randomElement(using: &random) ?? 1
        var items: [SpawnItem] = []
        if row.isMultiple(of: 6) {
            let positive = Double.random(in: 0..<1, using: &random) < effects.positiveGateChance
            let empty = (0...2).filter { $0 != route && abs($0 - route) <= 1 }.randomElement(using: &random)!
            let other = (0...2).first { $0 != route && $0 != empty }!
            items = [.init(lane: route, kind: .gate(GateSystem.pick(positive: true, using: &random))),
                     .init(lane: other, kind: .gate(GateSystem.pick(positive: positive, using: &random)))]
            previousSafeLanes = positive ? [0, 1, 2] : [route, empty]
        } else {
            let available = ObjectCatalog.all.filter { $0.size <= DifficultySystem.maxObjectSize(at: run.elapsed) }
            let edible = available.filter { $0.size <= run.size }
            let threats = available.filter { $0.size > run.size }
            let dangerCount = !threats.isEmpty && Double.random(in: 0..<1, using: &random) < DifficultySystem.dangerChance(at: run.elapsed)
                ? (Double.random(in: 0..<1, using: &random) < DifficultySystem.doubleDangerChance(at: run.elapsed) ? 2 : 1) : 0
            let choices = (0...2).filter { $0 != route }.shuffled(using: &random) + [route]
            previousSafeLanes = []
            for (index, lane) in choices.enumerated() {
                let dangerous = index < dangerCount
                if !dangerous { previousSafeLanes.append(lane) }
                guard index < (run.elapsed < 10 ? 2 : 3) else { continue }
                if let object = (dangerous ? threats : edible).randomElement(using: &random) {
                    items.append(.init(lane: lane, kind: .object(object)))
                }
            }
        }
        return .init(number: row, items: items, safeLanes: previousSafeLanes)
    }
}

struct SeededRandom: RandomNumberGenerator {
    var seed: UInt64
    mutating func next() -> UInt64 {
        seed &+= 0x9E3779B97F4A7C15
        var z = seed
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
