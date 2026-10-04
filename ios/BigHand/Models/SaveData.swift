import Foundation

struct SaveData: Codable, Equatable, Sendable {
    var version = 2
    var coins = 0
    var upgrades: [Upgrade: Int] = Dictionary(uniqueKeysWithValues: Upgrade.allCases.map { ($0, 0) })
    var bestScore = 0
    var maxHandSize = 20.0
    var longestDistance = 0.0
    var totalRuns = 0

    var unlockedSkins: Set<HandSkin> = [.classic]
    var equippedSkin: HandSkin = .classic

    init() {}
    enum CodingKeys: String, CodingKey { case version, coins, upgrades, bestScore, maxHandSize, longestDistance, totalRuns, unlockedSkins, equippedSkin }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func integer(_ key: CodingKeys) -> Int { max(0, (try? c.decode(Int.self, forKey: key)) ?? 0) }
        func number(_ key: CodingKeys, fallback: Double) -> Double {
            let value = (try? c.decode(Double.self, forKey: key)) ?? fallback
            return value.isFinite && value >= 0 ? value : fallback
        }
        let ids = (try? c.decode([String].self, forKey: .unlockedSkins)) ?? []
        unlockedSkins = Set(ids.compactMap(HandSkin.init(rawValue:))).union([.classic])
        let equipped = (try? c.decode(String.self, forKey: .equippedSkin)).flatMap(HandSkin.init(rawValue:)) ?? .classic
        equippedSkin = unlockedSkins.contains(equipped) ? equipped : .classic
        coins = integer(.coins)
        bestScore = integer(.bestScore)
        totalRuns = integer(.totalRuns)
        maxHandSize = number(.maxHandSize, fallback: 20)
        longestDistance = number(.longestDistance, fallback: 0)
        let raw = (try? c.decode([String: Int].self, forKey: .upgrades)) ?? [:]
        for upgrade in Upgrade.allCases {
            let level = raw[upgrade.rawValue] ?? (upgrade == .handling ? raw["magnet"] : nil) ?? 0
            upgrades[upgrade] = min(GameBalance.maxUpgradeLevel, max(0, level))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(version, forKey: .version)
        try c.encode(unlockedSkins.map(\.rawValue).sorted(), forKey: .unlockedSkins)
        try c.encode(equippedSkin.rawValue, forKey: .equippedSkin)
        try c.encode(coins, forKey: .coins)
        try c.encode(Dictionary(uniqueKeysWithValues: upgrades.map { ($0.key.rawValue, $0.value) }), forKey: .upgrades)
        try c.encode(bestScore, forKey: .bestScore)
        try c.encode(maxHandSize, forKey: .maxHandSize)
        try c.encode(longestDistance, forKey: .longestDistance)
        try c.encode(totalRuns, forKey: .totalRuns)
    }

    mutating func buy(_ upgrade: Upgrade) -> Bool {
        let level = upgrades[upgrade, default: 0]
        guard let cost = upgrade.cost(at: level), coins >= cost else { return false }
        coins -= cost
        upgrades[upgrade] = level + 1
        return true
    }
    @discardableResult
    mutating func unlock(_ skin: HandSkin) -> Bool {
        guard !unlockedSkins.contains(skin), coins >= skin.coinPrice else { return false }
        coins -= skin.coinPrice; unlockedSkins.insert(skin)
        return true
    }
    @discardableResult
    mutating func equip(_ skin: HandSkin) -> Bool {
        guard unlockedSkins.contains(skin) else { return false }
        equippedSkin = skin
        return true
    }
    mutating func record(_ run: RunState) {
        bestScore = max(bestScore, run.score)
        maxHandSize = max(maxHandSize, run.maxSize)
        longestDistance = max(longestDistance, run.distance)
    }
    var nextUpgrade: Upgrade? {
        let candidates = Upgrade.allCases.filter { $0.cost(at: upgrades[$0, default: 0]) != nil }
            .sorted { $0.cost(at: upgrades[$0, default: 0])! < $1.cost(at: upgrades[$1, default: 0])! }
        return candidates.first { $0.cost(at: upgrades[$0, default: 0])! <= coins } ?? candidates.first
    }
}
