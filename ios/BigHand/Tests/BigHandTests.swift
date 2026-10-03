import XCTest
import AVFoundation
import SpriteKit
@testable import BigHand

final class BigHandTests: XCTestCase {
    func testCrushEligibilityAndSweptContact() throws { try CoreChecks.crushEligibility() }
    func testGrowthAndVisualCap() throws { try CoreChecks.growth() }
    func testGateModifiers() throws { try CoreChecks.gates() }
    func testUpgradeEffectsAndPurchases() throws { try CoreChecks.upgrades() }
    func testCoinMultiplierAndRewardSettlement() throws { try CoreChecks.coins() }
    func testDifficultyThresholdsAndSpeed() throws { try CoreChecks.difficulty() }
    func testPersistenceModelAndCorruptionRecovery() throws { try CoreChecks.persistence() }
    func testConnectedSafeRoutesOver4800Rows() throws { try CoreChecks.spawning() }
}

@MainActor
final class GameSessionTests: XCTestCase {
    func testSimulatedStartBoostIsSingleUse() async {
        let suite = "BigHandSessionTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let session = GameSession(storage: SaveService(defaults: defaults), settings: defaults)
        await session.reward(.biggerStart)
        await session.reward(.biggerStart)
        XCTAssertTrue(session.boosted)
        session.start()
        XCTAssertEqual(session.snapshot.size, 30)
        XCTAssertFalse(session.boosted)
        session.setPaused(true)
        XCTAssertTrue(session.paused)
        session.setPaused(false)
        session.enterBackground()
        XCTAssertTrue(session.paused)
        session.home()
        session.start()
        XCTAssertEqual(session.snapshot.size, 20)
    }

    func testFailureContinueDoubleAndFrozenUpgrades() async {
        let suite = "BigHandSettlementTests-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let storage = SaveService(defaults: defaults)
        let session = GameSession(storage: storage, settings: defaults)
        session.start()
        // Inject the scene's failure event to exercise the coordinator independently of art/timing.
        var failed = session.scene.state
        failed.baseCoins = 250; failed.health = 0
        session.scene.stop()
        session.scene.onFail?(failed, ObjectCatalog.all[10])
        XCTAssertEqual(session.save.coins, 250)
        XCTAssertEqual(session.save.totalRuns, 1)
        session.buy(.start)
        XCTAssertEqual(session.save.coins, 0)
        XCTAssertEqual(session.scene.effects.startingSize, 20)
        await session.reward(.continueRun)
        XCTAssertEqual(session.snapshot.size, 25)
        XCTAssertEqual(session.scene.effects.startingSize, 20)
        var secondFailure = session.scene.state
        secondFailure.baseCoins = 300; secondFailure.health = 0
        session.scene.stop()
        session.scene.onFail?(secondFailure, ObjectCatalog.all[11])
        XCTAssertEqual(session.save.coins, 50)
        XCTAssertEqual(session.save.totalRuns, 1)
        XCTAssertTrue(session.result?.continued == true)
        await session.reward(.doubleCoins)
        await session.reward(.doubleCoins)
        XCTAssertEqual(session.save.coins, 350)
        XCTAssertEqual(session.result?.coins, 600)
        XCTAssertEqual(storage.load(), session.save)
        session.start()
        XCTAssertEqual(session.snapshot.size, 25)
    }

    func testSceneSteppingCrushesCollectsAndGrows() {
        let feedback = FeedbackService()
        feedback.haptics.enabled = false
        let scene = BigHandScene(feedback: feedback, randomSeed: 1)
        scene.start(effects: UpgradeEffects(levels: [:]), boosted: false)
        for frame in 0..<420 { scene.update(Double(frame) / 60) }
        XCTAssertTrue(scene.isRunning)
        XCTAssertGreaterThan(scene.state.objectScore, 0)
        XCTAssertGreaterThan(scene.state.baseCoins, 0)
        XCTAssertGreaterThan(scene.state.size, 20)
        XCTAssertGreaterThan(scene.state.distance, 50)
        scene.pause(true)
    }
}

@MainActor
final class PresentationTests: XCTestCase {
    func testBundledFeedbackTiersDecodeAndArtStaysBounded() throws {
        for cue in FeedbackCue.allCases {
            let url = try XCTUnwrap(Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds"))
            let player = try AVAudioPlayer(contentsOf: url)
            XCTAssertGreaterThan(player.duration, 0.05); XCTAssertLessThan(player.duration, 0.5)
        }
        let hand = HandNode()
        for skin in HandSkin.allCases {
            hand.equip(skin); hand.reset(size: 50_000)
            let frame = hand.calculateAccumulatedFrame()
            XCTAssertLessThan(frame.width, 230); XCTAssertLessThan(frame.height, 310)
            XCTAssertEqual(hand.silhouette.children.filter { $0.name?.hasPrefix("finger") == true }.count, 4)
            XCTAssertNotNil(hand.silhouette.childNode(withName: "thumb")); XCTAssertNotNil(hand.silhouette.childNode(withName: "palm"))
        }
    }
    func testCosmeticMigrationPurchaseAndPersistence() throws {
        let old = Data(#"{"coins":1500,"upgrades":{"growth":2},"bestScore":99}"#.utf8)
        var save = try JSONDecoder().decode(SaveData.self, from: old)
        XCTAssertEqual(save.unlockedSkins, [.classic]); XCTAssertEqual(save.equippedSkin, .classic)
        XCTAssertFalse(save.equip(.robot)); XCTAssertTrue(save.unlock(.robot))
        XCTAssertEqual(save.coins, 0); XCTAssertFalse(save.unlock(.robot))
        XCTAssertTrue(save.equip(.robot))
        let restored = try JSONDecoder().decode(SaveData.self, from: JSONEncoder().encode(save))
        XCTAssertEqual(save, restored)
        XCTAssertEqual(restored.upgrades[.growth], 2); XCTAssertEqual(restored.bestScore, 99)
        let future = Data(#"{"unlockedSkins":["robot","futureSkin"],"equippedSkin":"gold"}"#.utf8)
        let recovered = try JSONDecoder().decode(SaveData.self, from: future)
        XCTAssertEqual(recovered.unlockedSkins, [.classic, .robot]); XCTAssertEqual(recovered.equippedSkin, .classic)
    }
    func testCosmeticsDoNotChangeRunEffectsAndCannotSpendDuringPlay() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let storage = SaveService(defaults: defaults)
        var save = SaveData(); save.coins = 1500; storage.write(save)
        let session = GameSession(storage: storage, settings: defaults)
        session.selectSkin(.robot)
        XCTAssertEqual(session.save.equippedSkin, .robot); XCTAssertEqual(storage.load(), session.save)
        session.start(); let effects = session.scene.effects
        session.selectSkin(.redGlove)
        XCTAssertEqual(session.save.unlockedSkins, [.classic, .robot])
        XCTAssertEqual(session.scene.effects, effects); XCTAssertEqual(session.snapshot.size, 20)
        session.scene.stop()
    }
    func testAllCrushWeightsAndGatesUseRealCollisionPath() {
        for scenario in ["small", "large", "gate", "negativeGate", "giant", "fail"] {
            let feedback = FeedbackService(); feedback.haptics.enabled = false
            let scene = BigHandScene(feedback: feedback, randomSeed: 1)
            scene.start(effects: UpgradeEffects(levels: [:]), boosted: false)
            scene.preparePresentationScenario(scenario)
            for frame in 0..<240 { scene.update(Double(frame) / 60) }
            if scenario == "fail" { XCTAssertFalse(scene.isRunning); XCTAssertEqual(scene.state.health, 0) }
            else {
                XCTAssertTrue(scene.isRunning, scenario)
                if scenario == "gate" { XCTAssertEqual(scene.state.size, 30) }
                else if scenario == "negativeGate" { XCTAssertEqual(scene.state.size, 10) }
                else { XCTAssertGreaterThan(scene.state.objectScore, 0); XCTAssertGreaterThan(scene.state.baseCoins, 0) }
            }
            scene.stop()
        }
        let tiers = [5.0, 45, 90, 360].map(ImpactProfile.init(size:))
        XCTAssertEqual(Set(tiers.map(\.cue)).count, 4)
        XCTAssertEqual(tiers.map(\.particles), tiers.map(\.particles).sorted())
        XCTAssertEqual(tiers.map(\.shake), tiers.map(\.shake).sorted())
    }
}
