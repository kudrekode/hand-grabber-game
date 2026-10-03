import Foundation
#if canImport(BigHand)
@testable import BigHand
#endif

// Shared by the iOS XCTest target and the platform-independent verification script.
enum CoreChecks {
    struct Failure: Error, CustomStringConvertible { let description: String }
    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw Failure(description: message) }
    }
    static func close(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 1e-8 }

    static func crushEligibility() throws {
        try expect(CollisionSystem.canCrush(hand: 20, object: 20), "Equal sizes must crush")
        try expect(!CollisionSystem.canCrush(hand: 19.99, object: 20), "Oversized objects must fail")
        let bus = ObjectCatalog.all.last!
        try expect(CollisionSystem.contact(fromX: 0, fromY: 200, toX: 0, toY: -200, handSize: 20, object: bus), "Swept contact must catch tunneling")
        try expect(!CollisionSystem.contact(fromX: 133, fromY: 0, toX: 133, toY: 0, handSize: 500, object: bus), "Adjacent lane must remain clear at maximum visual size")
    }
    static func growth() throws {
        try expect(close(Economy.growth(objectSize: 35, multiplier: 1), 0.525), "Preserve current 1.5% growth")
        try expect(close(Economy.growth(objectSize: 35, multiplier: 2.5), 1.3125), "Apply growth upgrade")
        var run = RunState(size: 20); run.grow(by: 10); run.grow(by: -20)
        try expect(run.size == 10 && run.maxSize == 30, "Largest hand survives shrink gates")
        try expect(GameBalance.handScale(500) == GameBalance.handScale(50_000), "Keep huge hands readable")
    }
    static func gates() throws {
        let expected = [30.0, 45, 30, 10, 10]
        for (gate, size) in zip(GateSystem.all, expected) {
            try expect(GateSystem.apply(gate, to: 20) == size, "Incorrect gate: \(gate.label)")
        }
        try expect(GateSystem.apply(GateSystem.all[3], to: 3) == 1, "Negative gates clamp at one")
        try expect(GateSystem.apply(GateSystem.all[4], to: 1) == 1, "Division clamps at one")
    }
    static func upgrades() throws {
        let effects = UpgradeEffects(levels: Dictionary(uniqueKeysWithValues: Upgrade.allCases.map { ($0, 5) }))
        try expect(effects.startingSize == 45, "Start upgrade")
        try expect(close(effects.growth, 2.5) && close(effects.handling, 1.75), "Growth / handling upgrades")
        try expect(close(effects.coinMultiplier, 2) && close(effects.positiveGateChance, 0.35), "Coins / luck upgrades")
        try expect(GameBalance.upgradeCosts == [250, 500, 1500, 4500, 13500], "Cost curve")
        for upgrade in Upgrade.allCases { try expect(upgrade.cost(at: 5) == nil, "Maximum five levels") }
        var save = SaveData(); save.coins = 250
        try expect(save.buy(.start) && save.coins == 0 && save.upgrades[.start] == 1, "Atomic purchase")
        try expect(!save.buy(.start) && save.upgrades[.start] == 1, "Insufficient balance")
        save.upgrades[.start] = 5; save.coins = 100_000
        try expect(!save.buy(.start), "Maxed purchase rejected")
    }
    static func coins() throws {
        try expect(Economy.coins(base: 5, multiplier: 1.2) == 6, "Fractional rewards accumulate before rounding")
        var ledger = RewardLedger()
        try expect(ledger.settle(earned: 6) == 6, "First bank")
        try expect(ledger.settle(earned: 6) == 0, "Idempotent settlement")
        try expect(ledger.double(earned: 6) == 6 && ledger.double(earned: 6) == 0, "Double exactly once")
        try expect(ledger.settle(earned: 10) == 8, "Continued run only banks new rewards, doubled")
        try expect(ledger.banked == 20, "Total payout")
    }
    static func difficulty() throws {
        for (seconds, phase) in [(0.0, 0), (9.99, 0), (10, 1), (29.99, 1), (30, 2), (59.99, 2), (60, 3)] {
            try expect(DifficultySystem.phase(at: seconds) == phase, "Phase at \(seconds)")
        }
        for (seconds, size) in [(0.0, 15.0), (8, 35), (12, 70), (16, 180), (24, 360)] {
            try expect(DifficultySystem.maxObjectSize(at: seconds) == size, "Unlock at \(seconds)")
        }
        try expect(DifficultySystem.speed(at: 10) == 210 && DifficultySystem.speed(at: 90) == 570, "Speed delay and cap")
        try expect(close(DifficultySystem.rowInterval(at: 100), 1.08), "Minimum spacing")
        try expect(GameBalance.stage(29) == "TINY" && GameBalance.stage(30) == "NORMAL" && GameBalance.stage(500) == "ABSURD", "Visual stage boundaries")
    }
    static func persistence() throws {
        let initial = SaveData()
        let initialData = try JSONEncoder().encode(initial)
        let restoredInitial = try JSONDecoder().decode(SaveData.self, from: initialData)
        try expect(initial == restoredInitial, "Default save round trip preserves canonical upgrade levels")
        let input = Data(#"{"coins":-20,"bestScore":123,"maxHandSize":87,"longestDistance":42,"totalRuns":3,"upgrades":{"start":99,"growth":-1,"magnet":2}}"#.utf8)
        let decoded = try JSONDecoder().decode(SaveData.self, from: input)
        try expect(decoded.coins == 0 && decoded.bestScore == 123 && decoded.totalRuns == 3, "Sanitize save totals")
        try expect(decoded.upgrades[.start] == 5 && decoded.upgrades[.growth] == 0 && decoded.upgrades[.handling] == 2, "Clamp levels and migrate magnet")
        let encoded = try JSONEncoder().encode(decoded)
        let roundTrip = try JSONDecoder().decode(SaveData.self, from: encoded)
        try expect(roundTrip == decoded, "Save round trip")
        let empty = try JSONDecoder().decode(SaveData.self, from: Data("{}".utf8))
        try expect(empty.coins == 0 && empty.maxHandSize == 20, "Missing fields default")
        var save = SaveData(); var run = RunState(size: 100); run.distance = 80; run.objectScore = 20
        save.record(run); save.record(RunState(size: 20))
        try expect(save.bestScore == 480 && save.maxHandSize == 100 && save.longestDistance == 80, "Records never decrease")
        let suite = "BigHandTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = SaveService(defaults: defaults)
        storage.write(decoded)
        try expect(storage.load() == decoded, "UserDefaults persistence")
        defaults.set(Data("broken".utf8), forKey: SaveService.key)
        try expect(storage.load() == SaveData(), "Corrupt storage falls back")
    }
    static func spawning() throws {
        for seed in 1...20 {
            var spawner = SpawnSystem(), random = SeededRandom(seed: UInt64(seed))
            let effects = UpgradeEffects(levels: [:])
            var run = RunState(size: seed.isMultiple(of: 2) ? 1 : 45)
            for index in 0..<240 {
                run.elapsed = Double(index) * 0.6
                let previous = spawner.previousSafeLanes
                let row = spawner.next(run: run, effects: effects, using: &random)
                try expect(!row.safeLanes.isEmpty, "Every row has a safe route")
                try expect(row.safeLanes.contains { lane in previous.allSatisfy { abs(lane - $0) <= 1 } }, "Safe choices connect with adjacent lane moves")
                for lane in row.safeLanes {
                    for item in row.items where item.lane == lane {
                        switch item.kind {
                        case .object(let object): try expect(object.size <= run.size, "Safe lane contains a crushable object")
                        case .gate(let gate): try expect(gate.positive, "Safe gate is positive")
                        }
                    }
                }
                if row.number.isMultiple(of: 6) {
                    try expect(row.items.count == 2, "Gate pair leaves a bypass")
                    try expect(row.items.contains { if case .gate(let gate) = $0.kind { return gate.positive }; return false }, "At least one green gate")
                }
            }
        }
    }
}
