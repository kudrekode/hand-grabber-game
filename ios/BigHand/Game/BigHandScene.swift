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
        hand.position = CGPoint(x: 210, y: GameBalance.handY); hand.zPosition = 10
        let badge = NodeArt.rect(-58, -14, 116, 49, ArcadePalette.ink, radius: 12)
        badge.name = "sizeBadge"; badge.zPosition = 60; world.addChild(badge)
        badge.addChild(sizeBadge); sizeBadge.position.y = 17
        badge.addChild(stageBadge); stageBadge.position.y = 0
        rebuildTrack()
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }

    func resize(viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        size = CGSize(width: 420, height: max(640, viewSize.height / viewSize.width * 420))
        rebuildTrack()
    }
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        view.preferredFramesPerSecond = 120
    }
    private func rebuildTrack() {
        background.removeAllChildren()
        background.addChild(NodeArt.rect(28, 0, 364, size.height, ArcadePalette.paper, radius: 0, stroke: nil))
        for x in [0.0, 392] { background.addChild(NodeArt.rect(x, 0, 28, size.height, UIColor(hex: 0x42485B), radius: 0, stroke: nil)) }
        for x in [143.0, 277] {
            for y in stride(from: -43.0, through: Double(size.height) + 43, by: 43) {
                let dash = NodeArt.rect(x - 1.5, y, 3, 18, UIColor(hex: 0xDED7C4), radius: 0, stroke: nil)
                dash.name = "dash"; dash.userData = ["baseY": y]; background.addChild(dash)
            }
        }
        for x in [8.0, 401] {
            for y in stride(from: -90.0, through: Double(size.height) + 90, by: 90) {
                let stripe = NodeArt.rect(x, y, 12, 35, ArcadePalette.gold, radius: 0, stroke: nil)
                stripe.name = "stripe"; stripe.userData = ["baseY": y]; background.addChild(stripe)
            }
        }
    }
    func start(effects: UpgradeEffects, boosted: Bool) {
        isPaused = false; removeAllActions(); world.removeAllActions(); world.position = .zero
        world.children.filter { $0.name == "effect" }.forEach { $0.removeFromParent() }
        entities.forEach { $0.node.removeFromParent() }; entities.removeAll()
        self.effects = effects
        state = RunState(size: effects.startingSize * (boosted ? 1.5 : 1))
        spawner = SpawnSystem(); phase = -1; worldTravel = 0; hitStop = 0; spawnTimer = 0.35; hudTimer = 0
        hand.reset(size: state.size); hand.position.x = state.x
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
        hand.reset(size: state.size); spawnTimer = 1.0; hitStop = 0; lastTime = 0; trackingTouch = nil
        isPaused = false; isRunning = true; feedback.play(.gate); refreshLabels(); onSnapshot?(state)
    }
    func pause(_ paused: Bool) {
        isPaused = paused; trackingTouch = nil; lastTime = 0
        if paused { feedback.sound.stop() }
    }
    func stop() { isRunning = false; pause(true) }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, !isPaused, trackingTouch == nil, let touch = touches.first else { return }
        trackingTouch = touch; lastTouchX = touch.location(in: self).x
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning, let active = trackingTouch, touches.contains(active) else { return }
        let x = active.location(in: self).x
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
        let previousX = state.x
        state.x += (state.targetX - state.x) * (1 - exp(-dt * GameBalance.steeringResponse * effects.handling))
        hand.position.x = state.x; hand.grow(size: state.size, dt: dt)
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
                    feedback.play(.coin)
                }
            case .gate(let gate):
                let h = CollisionSystem.handBounds(size: state.size)
                if CollisionSystem.sweptEllipse(fromX: x - previousX, fromY: oldY - GameBalance.handY, toX: dx, toY: dy, rx: 52 + h.x, ry: 18 + h.y) {
                    for other in entities where other.row == entity.row {
                        if case .gate = other.kind { other.hit = true; other.node.run(.sequence([.fadeOut(withDuration: 0.1), .removeFromParent()])) }
                    }
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
                node.addChild(NodeArt.object(object))
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
            node.zPosition = 20; world.addChild(node); entities.append(entity)
        }
    }
    private func refreshDanger(_ entity: Entity, object: ObjectDefinition) {
        let danger = object.size > state.size
        entity.label?.text = "\(danger ? "! " : "")\(Int(object.size))"
        entity.label?.fontColor = danger ? UIColor(hex: 0xB33528) : UIColor(hex: 0x237C55)
    }
    private func refreshLabels() {
        if let badge = world.childNode(withName: "sizeBadge") { badge.position = CGPoint(x: min(359, max(61, state.x)), y: 66) }
        sizeBadge.text = "SIZE \(Int(state.size))"; stageBadge.text = GameBalance.stage(state.size)
    }
    private func crush(_ entity: Entity, object: ObjectDefinition) {
        entity.hit = true; entity.label?.removeFromParent()
        let weight = CollisionSystem.impact(object.size), point = entity.node.position
        state.objectScore += object.score
        let growth = Economy.growth(objectSize: object.size, multiplier: effects.growth)
        state.grow(by: growth)
        let flatten = SKAction.group([.scaleX(to: 1.5, duration: 0.11), .scaleY(to: 0.15, duration: 0.11), .moveBy(x: 0, y: -10, duration: 0.11)])
        entity.node.run(.sequence([flatten, .fadeOut(withDuration: 0.12), .removeFromParent()]))
        hand.crush(weight: weight, reduceMotion: reduceMotion)
        hitStop = object.size < 22 ? 0.012 : object.size < 70 ? 0.028 : object.size < 180 ? 0.045 : 0.075
        shake(strength: object.size < 22 ? 0 : object.size < 70 ? 1.4 + weight * 2 : object.size < 180 ? 3 + weight * 3 : 7 + weight * 3)
        burst(at: point, color: UIColor(hex: object.color), weight: weight, fruit: object.isFruit)
        popup("+\(object.score) \(object.size < 70 ? "SQUISH!" : "CRUNCH!")", at: CGPoint(x: point.x, y: point.y + 80))
        popup(String(format: "+%.2f SIZE", growth), at: CGPoint(x: point.x, y: point.y + 110), color: UIColor(hex: 0x237C55), fontSize: 13)
        let coin = NodeArt.ellipse(0, 0, 10, 10, ArcadePalette.gold)
        coin.position = CGPoint(x: point.x, y: GameBalance.handY + 75); coin.zPosition = 30
        world.addChild(coin); entities.append(Entity(node: coin, kind: .coin(object.coins), row: entity.row))
        feedback.crush(size: object.size)
    }
    private func fail(_ entity: Entity, object: ObjectDefinition) {
        isRunning = false; state.health = 0; trackingTouch = nil
        hand.fail(reduceMotion: reduceMotion); shake(strength: 17)
        burst(at: entity.node.position, color: ArcadePalette.gold, weight: 1.6, fruit: false)
        let banner = NodeArt.rect(53, GameBalance.handY + 165, 314, 74, ArcadePalette.coral, radius: 13)
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
    private func shake(strength: Double) {
        guard strength > 0, !reduceMotion else { return }
        world.removeAction(forKey: "shake"); world.position = .zero
        let steps = (0..<6).map { i in SKAction.moveTo(x: (i % 2 == 0 ? 1 : -1) * strength * Double(6 - i) / 6, duration: 0.025) }
        world.run(.sequence(steps + [.move(to: .zero, duration: 0.04)]), withKey: "shake")
    }
    private func popup(_ text: String, at point: CGPoint, color: UIColor = ArcadePalette.ink, fontSize: CGFloat = 16) {
        let label = NodeArt.label(text, size: fontSize, color: color)
        label.position = CGPoint(x: min(310, max(110, point.x)), y: point.y)
        label.name = "effect"; label.zPosition = 70; world.addChild(label)
        label.run(.sequence([.group([.moveBy(x: 0, y: reduceMotion ? 8 : 38, duration: 0.8), .sequence([.wait(forDuration: 0.45), .fadeOut(withDuration: 0.35)])]), .removeFromParent()]))
    }
    private func burst(at point: CGPoint, color: UIColor, weight: Double, fruit: Bool) {
        let count = reduceMotion ? 4 : Int(5 + weight * 13)
        for _ in 0..<count {
            let r = Double.random(in: 2...5) * weight
            let chip = fruit ? NodeArt.ellipse(0, 0, r * 0.7, r, color, stroke: nil) : NodeArt.rect(-r / 2, -r / 2, r, r * 0.6, color, radius: 1, stroke: nil)
            chip.position = point; chip.name = "effect"; chip.zPosition = 50; world.addChild(chip)
            let angle = Double.random(in: 0...(.pi * 2)), distance = Double.random(in: 25...80) * weight
            chip.run(.sequence([.group([.moveBy(x: cos(angle) * distance, y: sin(angle) * distance, duration: 0.4), .rotate(byAngle: 3, duration: 0.4), .fadeOut(withDuration: 0.4)]), .removeFromParent()]))
        }
        if weight > 0.7 {
            let ring = NodeArt.ellipse(0, 0, 16, 8, .clear, stroke: color)
            ring.name = "effect"; ring.position = point; ring.zPosition = 40; world.addChild(ring)
            ring.run(.sequence([.group([.scale(to: reduceMotion ? 1.3 : 4 * weight, duration: 0.3), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
        }
    }
}
