import SwiftUI

@MainActor
final class GameSession: ObservableObject {
    enum Route { case home, playing, results }
    @Published private(set) var route = Route.home
    @Published private(set) var save: SaveData
    @Published private(set) var snapshot = RunState(size: 20)
    @Published private(set) var result: RunResult?
    @Published private(set) var boosted = false
    @Published private(set) var paused = false
    @Published private(set) var rewardBusy = false
    @Published var shopOpen = false
    @Published var soundEnabled: Bool { didSet { feedback.sound.enabled = soundEnabled; settings.set(soundEnabled, forKey: "big-hand-sound") } }
    @Published var hapticsEnabled: Bool { didSet { feedback.haptics.enabled = hapticsEnabled; settings.set(hapticsEnabled, forKey: "big-hand-haptics") } }
    let scene: BigHandScene
    let feedback: FeedbackService
    private let storage: SaveService
    private let settings: UserDefaults
    private let ads: any RewardedAdService
    private var ledger = RewardLedger()
    private var runID = UUID()
    private var continued = false
    private var counted = false

    init(storage: SaveService = SaveService(), settings: UserDefaults = .standard,
         ads: any RewardedAdService = SimulatedRewardedAdService()) {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        let uiTesting = arguments.contains("-ui-testing")
        let testDefaults = UserDefaults(suiteName: "big-hand-presentation-tests")!
        let storage = uiTesting ? SaveService(defaults: testDefaults) : storage
        let settings = uiTesting ? testDefaults : settings
        #endif
        self.storage = storage; self.settings = settings; self.ads = ads
        save = storage.load()
        soundEnabled = settings.bool(forKey: "big-hand-sound")
        hapticsEnabled = settings.object(forKey: "big-hand-haptics") == nil || settings.bool(forKey: "big-hand-haptics")
        let feedback = FeedbackService(); self.feedback = feedback
        scene = BigHandScene(feedback: feedback)
        feedback.sound.enabled = soundEnabled; feedback.haptics.enabled = hapticsEnabled
        scene.onSnapshot = { [weak self] state in self?.snapshot = state }
        scene.onFail = { [weak self] state, object in self?.finish(state: state, object: object) }
        #if DEBUG
        if uiTesting {
            save = SaveData(); save.coins = 10_000
            feedback.sound.enabled = false; feedback.haptics.enabled = false
            if let index = arguments.firstIndex(of: "-presentation-scenario"), arguments.indices.contains(index + 1) {
                start(); scene.preparePresentationScenario(arguments[index + 1], waitForTouch: true)
            }
            if arguments.contains("-shop") { shopOpen = true }
        }
        #endif
    }
    var runCoins: Int { Economy.coins(base: snapshot.baseCoins, multiplier: scene.effects.coinMultiplier) }

    func start() {
        guard !rewardBusy else { return }
        ledger = RewardLedger(); counted = false; continued = false; runID = UUID(); result = nil; paused = false
        scene.start(effects: UpgradeEffects(levels: save.upgrades), boosted: boosted, skin: save.equippedSkin)
        boosted = false; route = .playing
    }
    private func finish(state: RunState, object: ObjectDefinition) {
        let earned = Economy.coins(base: state.baseCoins, multiplier: scene.effects.coinMultiplier)
        let highScore = state.score > save.bestScore
        save.coins += ledger.settle(earned: earned)
        save.record(state)
        if !counted { counted = true; save.totalRuns += 1 }
        storage.write(save)
        result = RunResult(id: runID, state: state, obstacle: object, coins: earned * (ledger.doubled ? 2 : 1),
                           isHighScore: highScore, continued: continued, doubled: ledger.doubled)
        scene.pause(true); paused = false; route = .results
        if highScore { feedback.play(.highScore) }
    }
    func buy(_ upgrade: Upgrade) {
        guard route != .playing, save.buy(upgrade) else { return }
        storage.write(save); feedback.play(.upgrade)
    }
    func selectSkin(_ skin: HandSkin) {
        guard route != .playing else { return }
        if !save.unlockedSkins.contains(skin) {
            guard save.unlock(skin) else { return }
            feedback.play(.upgrade)
        } else { feedback.play(.coin) }
        guard save.equip(skin) else { return }
        scene.equip(skin); storage.write(save)
    }
    func reward(_ placement: RewardPlacement) async {
        guard !rewardBusy else { return }
        switch placement {
        case .continueRun: guard route == .results, !continued else { return }
        case .doubleCoins: guard route == .results, !ledger.doubled else { return }
        case .biggerStart: guard route == .home, !boosted else { return }
        }
        rewardBusy = true
        defer { rewardBusy = false }
        let requestedID = runID
        guard await ads.request(placement), requestedID == runID else { return }
        switch placement {
        case .biggerStart:
            guard route == .home else { return }
            boosted = true; feedback.play(.gate)
        case .continueRun:
            guard route == .results, !continued else { return }
            continued = true; result = nil; paused = false; scene.continueRun(); route = .playing
        case .doubleCoins:
            guard route == .results, let current = result, !ledger.doubled else { return }
            let earned = Economy.coins(base: current.state.baseCoins, multiplier: scene.effects.coinMultiplier)
            save.coins += ledger.double(earned: earned); storage.write(save); feedback.play(.coin)
            result = RunResult(id: current.id, state: current.state, obstacle: current.obstacle, coins: earned * 2,
                               isHighScore: current.isHighScore, continued: continued, doubled: true)
        }
    }
    func setPaused(_ value: Bool) {
        guard route == .playing else { return }
        paused = value; scene.pause(value)
    }
    func enterBackground() { if route == .playing { setPaused(true) }; storage.write(save); feedback.sound.stop() }
    func home() { guard !rewardBusy else { return }; scene.stop(); result = nil; route = .home }
}
