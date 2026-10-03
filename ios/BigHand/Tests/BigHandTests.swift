import XCTest
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
