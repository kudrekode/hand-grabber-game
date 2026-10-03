import SpriteKit
import UIKit

@MainActor
final class BigHandScene: SKScene {
    private final class Entity {
        enum Kind { case object(ObjectDefinition), gate(GateDefinition), coin(Int) }
        let node: SKNode
        let kind: Kind
        let row: Int
        var hit = false
        var label: SKLabelNode?
        init(node: SKNode, kind: Kind, row: Int) { self.node = node; self.kind = kind; self.row = row }
    }

    private(set) var state = RunState(size: 20)
    private(set) var effects = UpgradeEffects(levels: [:])
    private(set) var isRunning = false
    var onSnapshot: ((RunState) -> Void)?
    var onFail: ((RunState, ObjectDefinition) -> Void)?
    let feedback: FeedbackService
    private let world = SKNode()
    private let background = SKNode()
    private let hand = HandNode()
    private let gameCamera = SKCameraNode()
    private let hud = SKNode()
    private var lastStage = ""
    private var cameraZoom: CGFloat = 1
    private let sizeBadge = NodeArt.label("", size: 18, color: ArcadePalette.paper)
    private let stageBadge = NodeArt.label("", size: 10, color: ArcadePalette.lime)
    private var entities: [Entity] = []
    private var spawner = SpawnSystem()
    private var random: SeededRandom
    private var lastTime: TimeInterval = 0
    private var spawnTimer = 0.35
    private var hudTimer = 0.0
    private var hitStop = 0.0
    private var worldTravel = 0.0
    private var phase = -1
    #if DEBUG
    private var fixtureWaitingForTouch = false
    #endif
    private var trackingTouch: UITouch?
    private var lastTouchX: CGFloat = 0
    private var reduceMotion: Bool { UIAccessibility.isReduceMotionEnabled }

    init(feedback: FeedbackService, randomSeed: UInt64? = nil) {
        self.feedback = feedback
        random = SeededRandom(seed: randomSeed ?? UInt64.random(in: .min ... .max))
        super.init(size: CGSize(width: 420, height: 800))
        scaleMode = .aspectFit
        backgroundColor = ArcadePalette.track
        addChild(world); world.addChild(background); world.addChild(hand)
        addChild(gameCamera); camera = gameCamera
        gameCamera.addChild(hud)
        hand.position = CGPoint(x: 210, y: GameBalance.handY); hand.zPosition = 10
        let badge = NodeArt.rect(-58, -14, 116, 49, ArcadePalette.ink, radius: DesignSystem.radius)
        badge.name = "sizeBadge"; badge.zPosition = 60; hud.addChild(badge)
        badge.addChild(sizeBadge); sizeBadge.position.y = 17
        badge.addChild(stageBadge); stageBadge.position.y = 0
        rebuildTrack()
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }

    func resize(viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        size = CGSize(width: 420, height: max(640, viewSize.height / viewSize.width * 420))
        rebuildTrack(); gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        refreshLabels()
    }
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        view.preferredFramesPerSecond = min(120, (view.window?.windowScene?.screen.maximumFramesPerSecond ?? 60))
        NodeArt.prewarm(in: view)
    }
    private func rebuildTrack() {
        background.removeAllChildren()
        background.addChild(NodeArt.rect(28, 0, 364, size.height, ArcadePalette.paper, radius: 0, stroke: nil))
        for x in [30.0, 387] { background.addChild(NodeArt.rect(x, 0, 3, size.height, UIColor(hex: 0xC8BEA9), radius: 0, stroke: nil)) }
        for x in [0.0, 392] { background.addChild(NodeArt.rect(x, 0, 28, size.height, UIColor(hex: 0x375B55), radius: 0, stroke: nil)) }
        for x in [143.0, 277] {
            for y in stride(from: -43.0, through: Double(size.height) + 43, by: 43) {
                let dash = NodeArt.rect(x - 1.5, y, 3, 18, UIColor(hex: 0xE2D8C3), radius: 0, stroke: nil)
                dash.name = "dash"; dash.userData = ["baseY": y]; background.addChild(dash)
            }
        }
        for x in [8.0, 401] {
            for y in stride(from: -90.0, through: Double(size.height) + 90, by: 90) {
                let stripe = NodeArt.rect(x, y, 12, 35, UIColor(hex: 0x5B7A67), radius: 3, stroke: nil)
                stripe.name = "stripe"; stripe.userData = ["baseY": y]; background.addChild(stripe)
            }
        }
    }
    func start(effects: UpgradeEffects, boosted: Bool, skin: HandSkin = .classic) {
        isPaused = false; removeAllActions(); world.removeAllActions(); world.position = .zero
        world.children.filter { $0.name == "effect" }.forEach { $0.removeFromParent() }
        entities.forEach { $0.node.removeFromParent() }; entities.removeAll()
        self.effects = effects
        state = RunState(size: effects.startingSize * (boosted ? 1.5 : 1))
        spawner = SpawnSystem(); phase = -1; worldTravel = 0; hitStop = 0; spawnTimer = 0.35; hudTimer = 0
        hand.equip(skin); hand.reset(size: state.size); hand.position.x = state.x
        resetCamera(); lastStage = GameBalance.stage(state.size)
        trackingTouch = nil; lastTime = 0; isRunning = true
        feedback.sound.activate(); feedback.haptics.prepare()
        refreshLabels(); onSnapshot?(state)
    }
    func continueRun() {
        guard !isRunning else { return }
        removeAllActions(); world.removeAllActions(); world.position = .zero
        // A clear approach gives the player time to reorient after the result screen.
        entities.forEach { $0.node.removeFromParent() }; entities.removeAll()
        world.children.filter { $0.name == "effect" }.forEach { $0.removeFromParent() }
        state.grow(by: state.size * 0.25); state.health = 1; state.targetX = state.x
        resetCamera(); hand.reset(size: state.size); spawnTimer = 1.0; hitStop = 0; lastTime = 0; trackingTouch = nil
        isPaused = false; isRunning = true; feedback.play(.gate); refreshLabels(); onSnapshot?(state)
    }
    func pause(_ paused: Bool) {
        isPaused = paused; trackingTouch = nil; lastTime = 0
        if paused { feedback.sound.stop() }
    }
    func stop() { isRunning = false; pause(true) }

    private func touchX(_ touch: UITouch) -> CGFloat {
        guard let view, view.bounds.width > 0 else { return touch.location(in: self).x }
        // Camera shake / zoom must never feed back into the drag delta.
        return touch.location(in: view).x * size.width / view.bounds.width
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, !isPaused, trackingTouch == nil, let touch = touches.first else { return }
        #if DEBUG
        fixtureWaitingForTouch = false
        #endif
        trackingTouch = touch; lastTouchX = touchX(touch)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let active = trackingTouch, touches.contains(active) else { return }
        let x = touchX(active)
        state.targetX = min(372, max(48, state.targetX + Double(x - lastTouchX)))
        lastTouchX = x
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let active = trackingTouch, touches.contains(active) { trackingTouch = nil }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { touchesEnded(touches, with: event) }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : min(0.05, max(0, currentTime - lastTime))
        lastTime = currentTime
        guard isRunning, dt > 0 else { return }
        #if DEBUG
        if fixtureWaitingForTouch { return }
        #endif
        let previousX = state.x
        state.x += (state.targetX - state.x) * (1 - exp(-dt * GameBalance.steeringResponse * effects.handling))
        hand.position.x = state.x; hand.grow(size: state.size, dt: dt)
        hand.steer(velocity: (state.x - previousX) / dt, dt: dt, reduceMotion: reduceMotion)
        let targetZoom: CGFloat = reduceMotion ? 1 : 1 + CGFloat((DifficultySystem.speed(at: state.elapsed) - 210) / 360) * 0.012
        cameraZoom += (targetZoom - cameraZoom) * CGFloat(1 - exp(-dt * 3))
        gameCamera.setScale(cameraZoom)
        state.elapsed += dt
        if hitStop > 0 { hitStop -= dt; return }
        let travel = DifficultySystem.speed(at: state.elapsed) * dt
        state.distance += travel * GameBalance.distanceScale; worldTravel += travel
        for child in background.children where child.name == "dash" || child.name == "stripe" {
            let period = child.name == "dash" ? 43.0 : 90.0
            child.position.y = -(worldTravel * (child.name == "dash" ? 1 : 0.55)).truncatingRemainder(dividingBy: period)
        }
        let nextPhase = DifficultySystem.phase(at: state.elapsed)
        if phase != nextPhase {
            phase = nextPhase
            popup(DifficultySystem.notices[phase], at: CGPoint(x: 210, y: size.height - 115), color: ArcadePalette.ink, fontSize: 15)
        }
        spawnTimer -= dt
        if spawnTimer <= 0 { spawnRow(); spawnTimer += DifficultySystem.rowInterval(at: state.elapsed) }
        // Coins may be appended during crush; a snapshot keeps this pass stable.
        for entity in Array(entities) where !entity.hit {
            let oldY = Double(entity.node.position.y)
            entity.node.position.y -= travel
            let x = Double(entity.node.position.x), y = Double(entity.node.position.y)
            let dx = x - state.x, dy = y - GameBalance.handY
            switch entity.kind {
            case .coin(let value):
                if CollisionSystem.sweptEllipse(fromX: x - previousX, fromY: oldY - (GameBalance.handY - 15), toX: dx, toY: y - (GameBalance.handY - 15), rx: 64, ry: 64) {
                    let before = Economy.coins(base: state.baseCoins, multiplier: effects.coinMultiplier)
                    state.baseCoins += value
                    let after = Economy.coins(base: state.baseCoins, multiplier: effects.coinMultiplier)
                    entity.hit = true; entity.node.removeFromParent()
                    popup("+\(after - before) COINS", at: entity.node.position, color: UIColor(hex: 0x996500), fontSize: 13)
                    burst(at: entity.node.position, color: ArcadePalette.gold, weight: 0.25, fruit: false)
                    feedback.play(.coin)
                }
            case .gate(let gate):
                let h = CollisionSystem.handBounds(size: state.size)
                if CollisionSystem.sweptEllipse(fromX: x - previousX, fromY: oldY - GameBalance.handY, toX: dx, toY: dy, rx: 52 + h.x, ry: 18 + h.y) {
                    for other in entities where other.row == entity.row {
                        if case .gate = other.kind { other.hit = true; other.node.run(.sequence([.group([.scaleY(to: 0.75, duration: 0.12), .fadeOut(withDuration: 0.14)]), .removeFromParent()])) }
                    }
                    entity.node.removeAllActions()
                    entity.node.alpha = 1
                    entity.node.run(.sequence([.group([.scale(to: 1.12, duration: 0.10), .moveBy(x: 0, y: -12, duration: 0.1)]), .scaleY(to: 0.1, duration: 0.12), .removeFromParent()]))
                    state.size = GateSystem.apply(gate, to: state.size); state.maxSize = max(state.maxSize, state.size)
                    let color = gate.positive ? ArcadePalette.lime : ArcadePalette.coral
                    popup("\(gate.label) SIZE", at: CGPoint(x: state.x, y: GameBalance.handY + 140), color: gate.positive ? UIColor(hex: 0x237C55) : ArcadePalette.coral)
                    burst(at: hand.position, color: color, weight: 0.8, fruit: false)
                    feedback.play(gate.positive ? .gate : .shrink)
                }
            case .object(let object):
                refreshDanger(entity, object: object)
                if CollisionSystem.contact(fromX: x - previousX, fromY: oldY - GameBalance.handY, toX: dx, toY: dy, handSize: state.size, object: object) {
                    if CollisionSystem.canCrush(hand: state.size, object: object.size) { crush(entity, object: object) }
                    else { fail(entity, object: object); return }
                }
            }
        }
        for entity in entities where entity.node.position.y < -130 { entity.node.removeFromParent() }
        entities.removeAll { $0.node.parent == nil }
        refreshLabels()
        hudTimer -= dt
        if hudTimer <= 0 { hudTimer = 0.1; onSnapshot?(state) }
    }
    private func spawnRow() {
        let row = spawner.next(run: state, effects: effects, using: &random)
        for item in row.items {
            let node = SKNode(), entity: Entity
            switch item.kind {
            case .object(let object):
                let art = NodeArt.cachedObject(object); art.name = "objectArt"; node.addChild(art)
                entity = Entity(node: node, kind: .object(object), row: row.number)
                let label = NodeArt.label("", size: 16); label.position.y = CollisionSystem.radius(object) + 25
                node.addChild(label); entity.label = label
                let name = NodeArt.label(object.name.uppercased(), size: 9, color: UIColor(hex: 0x697669))
                name.position.y = -CollisionSystem.radius(object) - 17; node.addChild(name)
                refreshDanger(entity, object: object)
            case .gate(let gate):
                node.addChild(NodeArt.gate(gate)); entity = Entity(node: node, kind: .gate(gate), row: row.number)
            }
            node.position = CGPoint(x: GameBalance.lanes[item.lane], y: Double(size.height) + 90)
            if case .gate = item.kind, !reduceMotion {
                node.xScale = 0.86; node.alpha = 0
                let enter = SKAction.group([.scaleX(to: 1, duration: 0.24), .fadeIn(withDuration: 0.18)]); enter.timingMode = .easeOut; node.run(enter)
            }
            node.zPosition = 20; world.addChild(node); entities.append(entity)
        }
    }
    private func refreshDanger(_ entity: Entity, object: ObjectDefinition) {
        let danger = object.size > state.size
        entity.label?.text = "\(danger ? "! " : "")\(Int(object.size))"
        entity.label?.fontColor = danger ? UIColor(hex: 0xB33528) : UIColor(hex: 0x237C55)
    }
    private func refreshLabels() {
        if let badge = hud.childNode(withName: "sizeBadge") { badge.position = CGPoint(x: 0, y: -size.height / 2 + 52) }
        let stage = GameBalance.stage(state.size)
        if stage != lastStage {
            lastStage = stage
            popup("\(stage) HAND", at: CGPoint(x: 210, y: GameBalance.handY + 170), color: ArcadePalette.accent, fontSize: 23)
            burst(at: hand.position, color: ArcadePalette.gold, weight: 1.1, fruit: false)
            feedback.play(.highScore)
        }
        sizeBadge.text = "SIZE \(Int(state.size))"; stageBadge.text = GameBalance.stage(state.size)
    }
    private func crush(_ entity: Entity, object: ObjectDefinition) {
        entity.hit = true; entity.label?.removeFromParent()
        let weight = CollisionSystem.impact(object.size), point = entity.node.position
        state.objectScore += object.score
        let growth = Economy.growth(objectSize: object.size, multiplier: effects.growth)
        state.grow(by: growth)
        let profile = ImpactProfile(size: object.size)
        // Keep labels stable; deform only the material artwork, then hold the crushed shape.
        entity.node.children.filter { $0.name != "objectArt" }.forEach { $0.removeFromParent() }
        let art = entity.node.childNode(withName: "objectArt") ?? entity.node
        let contact = SKAction.group([.scaleX(to: object.isFruit ? 1.28 : 1.15, duration: profile.contactDelay), .scaleY(to: object.isFruit ? 0.48 : 0.62, duration: profile.contactDelay), .rotate(toAngle: object.isFruit ? 0.08 : -0.07, duration: profile.contactDelay)])
        contact.timingMode = .easeIn
        let flatten = SKAction.group([.scaleX(to: 1.45, duration: 0.035), .scaleY(to: object.isFruit ? 0.10 : 0.24, duration: 0.035), .moveBy(x: 0, y: -8, duration: 0.035)])
        art.run(.sequence([contact, flatten]))
        hand.crush(profile: profile, reduceMotion: reduceMotion)
        // The impact lands at peak contraction, not at first contact.
        entity.node.run(.sequence([.wait(forDuration: profile.contactDelay), .run { [weak self] in
            guard let self else { return }
            self.shake(strength: profile.shake)
            self.burst(at: point, color: UIColor(hex: object.color), weight: weight, fruit: object.isFruit, count: profile.particles)
            self.feedback.crush(size: object.size)
        }, .wait(forDuration: profile.hold + 0.15), .scale(to: 0, duration: 0.08), .removeFromParent()]))
        hitStop = object.size < 22 ? 0.012 : object.size < 70 ? 0.028 : object.size < 180 ? 0.045 : 0.065
        popup("+\(object.score) \(object.size < 70 ? "SQUISH!" : "CRUNCH!")", at: CGPoint(x: point.x, y: point.y + 80))
        popup(String(format: "+%.2f SIZE", growth), at: CGPoint(x: point.x, y: point.y + 110), color: UIColor(hex: 0x237C55), fontSize: 13)
        let coin = NodeArt.coin()
        coin.position = CGPoint(x: point.x, y: GameBalance.handY + 75); coin.zPosition = 30
        world.addChild(coin); entities.append(Entity(node: coin, kind: .coin(object.coins), row: entity.row))
    }
    private func fail(_ entity: Entity, object: ObjectDefinition) {
        isRunning = false; state.health = 0; trackingTouch = nil
        hand.fail(reduceMotion: reduceMotion); shake(strength: 17)
        if let art = entity.node.childNode(withName: "objectArt") {
            art.run(.sequence([.group([.scaleX(to: 0.94, duration: 0.06), .scaleY(to: 1.06, duration: 0.06)]), .scale(to: 1, duration: 0.16)]))
        }
        burst(at: entity.node.position, color: ArcadePalette.gold, weight: 1.6, fruit: false)
        let banner = NodeArt.rect(53, GameBalance.handY + 165, 314, 74, ArcadePalette.coral, radius: DesignSystem.radius)
        banner.name = "effect"; banner.zPosition = 80; world.addChild(banner)
        let title = NodeArt.label("TOO SMALL!", size: 30, color: ArcadePalette.paper)
        title.position = CGPoint(x: 210, y: GameBalance.handY + 212); title.name = "effect"; title.zPosition = 81; world.addChild(title)
        let reason = NodeArt.label("\(object.name.uppercased()) \(Int(object.size)) > HAND \(Int(state.size))", size: 13, color: ArcadePalette.paper)
        reason.position = CGPoint(x: 210, y: GameBalance.handY + 184); reason.name = "effect"; reason.zPosition = 81; world.addChild(reason)
        feedback.play(.fail); onSnapshot?(state)
        UIAccessibility.post(notification: .announcement, argument: "Too small. \(object.name) needs size \(Int(object.size)). Your hand is \(Int(state.size)).")
        let finalState = state
        run(.sequence([.wait(forDuration: 0.75), .run { [weak self] in self?.onFail?(finalState, object) }]))
    }
    #if DEBUG
    // Deterministic, isolated simulator fixtures. Release builds cannot enter these paths.
    func preparePresentationScenario(_ scenario: String, waitForTouch: Bool = false) {
        fixtureWaitingForTouch = waitForTouch
        entities.forEach { $0.node.removeFromParent() }; entities.removeAll()
        spawnTimer = 10_000; phase = 0
        state = RunState(size: scenario == "large" ? 500 : scenario == "giant" ? 50_000 : 20)
        lastStage = GameBalance.stage(state.size); hand.reset(size: state.size)
        if scenario != "movement" {
            let kind: Entity.Kind
            let node = SKNode()
            if scenario == "gate" || scenario == "negativeGate" {
                let gate = GateSystem.all[scenario == "gate" ? 0 : 3]
                node.addChild(NodeArt.gate(gate)); kind = .gate(gate)
                let otherGate = GateSystem.all[scenario == "gate" ? 3 : 0]
                let other = SKNode(); other.addChild(NodeArt.gate(otherGate)); other.position = CGPoint(x: 77, y: 520); other.zPosition = 20; world.addChild(other)
                entities.append(Entity(node: other, kind: .gate(otherGate), row: 1))
            } else {
                let object = ObjectCatalog.all[scenario == "fail" || scenario == "large" || scenario == "giant" ? 11 : 0]
                let art = NodeArt.cachedObject(object); art.name = "objectArt"; node.addChild(art); kind = .object(object)
                let label = NodeArt.label("\(Int(object.size))", size: 18, color: object.size > state.size ? ArcadePalette.coral : ArcadePalette.accent)
                label.position.y = CollisionSystem.radius(object) + 22; node.addChild(label)
            }
            node.position = CGPoint(x: 210, y: 520); node.zPosition = 20; world.addChild(node)
            entities.append(Entity(node: node, kind: kind, row: 1))
            if scenario == "giant" {
                for lane in [0, 2] {
                    let object = ObjectCatalog.all[10]
                    let node = SKNode(), art = NodeArt.cachedObject(object); art.name = "objectArt"; node.addChild(art)
                    node.position = CGPoint(x: GameBalance.lanes[lane], y: 435); node.zPosition = 20; world.addChild(node)
                    entities.append(Entity(node: node, kind: .object(object), row: 2))
                }
            }
        }
        refreshLabels(); onSnapshot?(state)
    }
    #endif
    private func resetCamera() {
        gameCamera.removeAllActions(); cameraZoom = 1; gameCamera.setScale(1)
        gameCamera.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }
    private func shake(strength: Double) {
        guard strength > 0, !reduceMotion else { return }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        gameCamera.removeAction(forKey: "shake")
        gameCamera.run(.sequence([.customAction(withDuration: 0.22) { node, elapsed in
            let t = Double(elapsed), decay = pow(max(0, 1 - t / 0.22), 2)
            node.position = CGPoint(x: center.x + sin(t * 115) * strength * decay, y: center.y + cos(t * 97) * strength * 0.45 * decay)
        }, .move(to: center, duration: 0)]), withKey: "shake")
    }
    func equip(_ skin: HandSkin) { hand.equip(skin) }
    private func popup(_ text: String, at point: CGPoint, color: UIColor = ArcadePalette.ink, fontSize: CGFloat = 16) {
        let label = NodeArt.label(text, size: fontSize, color: color)
        label.position = CGPoint(x: min(310, max(110, point.x)), y: point.y)
        label.name = "effect"; label.zPosition = 70; world.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: reduceMotion ? 8 : 38, duration: 0.8), .sequence([.wait(forDuration: 0.45), .fadeOut(withDuration: 0.35)])]), .removeFromParent()]))
    }
    private func burst(at point: CGPoint, color: UIColor, weight: Double, fruit: Bool, count: Int? = nil) {
        // Bound concurrent emitters and particles, including at high speed / wide hands.
        guard world.children.filter({ $0 is SKEmitterNode }).count < 8 else { return }
        let emitter = SKEmitterNode()
        emitter.name = "effect"; emitter.position = point; emitter.zPosition = 45
        emitter.particleTexture = NodeArt.particleTexture(fruit: fruit)
        emitter.particleColor = color; emitter.particleColorBlendFactor = 1
        emitter.numParticlesToEmit = reduceMotion ? 4 : min(24, count ?? Int(5 + weight * 11))
        emitter.particleBirthRate = 700
        emitter.particleLifetime = 0.34 + weight * 0.07; emitter.particleLifetimeRange = 0.12
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = reduceMotion ? 35 : 80 + weight * 55; emitter.particleSpeedRange = 60
        emitter.yAcceleration = -180
        emitter.particleScale = CGFloat(0.45 + weight * 0.25); emitter.particleScaleRange = 0.22
        emitter.particleScaleSpeed = -0.35
        emitter.particleAlpha = 1; emitter.particleAlphaSpeed = -1.4
        emitter.particleRotationRange = .pi; emitter.particleRotationSpeed = fruit ? 0 : 4
        world.addChild(emitter)
        emitter.run(.sequence([.wait(forDuration: 0.9), .removeFromParent()]))
        if weight > 0.7, !reduceMotion {
            let ring = NodeArt.ellipse(0, 0, 18, 9, .clear, stroke: color)
            ring.name = "effect"; ring.position = point; ring.zPosition = 40; world.addChild(ring)
            ring.run(.sequence([.group([.scale(to: 2.5, duration: 0.18), .fadeOut(withDuration: 0.18)]), .removeFromParent()]))
        }
    }
}
