import SpriteKit
import UIKit

@MainActor
enum NodeArt {
    static func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
                     _ color: UIColor, radius: CGFloat = 8, stroke: UIColor? = ArcadePalette.ink) -> SKShapeNode {
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: height), cornerRadius: radius)
        return shape(path.cgPath, color: color, stroke: stroke)
    }
    static func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat,
                        _ color: UIColor, stroke: UIColor? = ArcadePalette.ink) -> SKShapeNode {
        shape(CGPath(ellipseIn: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2), transform: nil), color: color, stroke: stroke)
    }
    static func shape(_ path: CGPath, color: UIColor, stroke: UIColor? = ArcadePalette.ink) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.fillColor = color; node.strokeColor = stroke ?? .clear; node.lineWidth = stroke == nil ? 0 : 2.5
        node.isAntialiased = true
        return node
    }
    static func line(_ points: [CGPoint], color: UIColor, width: CGFloat = 3) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: first) }
        for point in points.dropFirst() { path.addLine(to: point) }
        let node = shape(path, color: .clear, stroke: color); node.lineWidth = width
        return node
    }
    static func polygon(_ points: [CGPoint], color: UIColor) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first { path.move(to: first) }
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return shape(path, color: color)
    }
    static func label(_ text: String, size: CGFloat, color: UIColor = ArcadePalette.ink) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        node.text = text; node.fontSize = size; node.fontColor = color
        node.verticalAlignmentMode = .center
        return node
    }

    static func object(_ object: ObjectDefinition) -> SKNode {
        let node = SKNode(), color = UIColor(hex: object.color), r = CGFloat(CollisionSystem.radius(object))
        func add(_ child: SKNode) { node.addChild(child) }
        func leaf() {
            add(line([.init(x: 0, y: r * 0.65), .init(x: 4, y: r * 1.1)], color: ArcadePalette.ink))
            let leaf = ellipse(13, r, 10, 5, UIColor(hex: 0x5CBA7D)); leaf.zRotation = 0.4; add(leaf)
        }
        switch object.id {
        case "cherry":
            add(line([.init(x: -11, y: 0), .init(x: 3, y: 30), .init(x: 14, y: -3)], color: UIColor(hex: 0x527754)))
            add(ellipse(-11, -8, 13, 13, color)); add(ellipse(13, -11, 14, 14, color))
        case "strawberry":
            let path = UIBezierPath()
            path.move(to: CGPoint(x: -r, y: r * 0.5))
            path.addCurve(to: CGPoint(x: 0, y: -r), controlPoint1: CGPoint(x: -r * 1.2, y: -r * 0.1), controlPoint2: CGPoint(x: -8, y: -r))
            path.addCurve(to: CGPoint(x: r, y: r * 0.5), controlPoint1: CGPoint(x: 8, y: -r), controlPoint2: CGPoint(x: r * 1.2, y: 0))
            path.addQuadCurve(to: CGPoint(x: -r, y: r * 0.5), controlPoint: CGPoint(x: 0, y: r * 1.2))
            add(shape(path.cgPath, color: color)); leaf()
            for i in 0..<7 { add(ellipse(CGFloat(i % 3 - 1) * 11, 7 - CGFloat(i / 3) * 12, 2, 3, ArcadePalette.paper, stroke: nil)) }
        case "apple", "orange", "coconut", "watermelon", "football":
            add(ellipse(0, 0, r, r, color))
            if object.id == "apple" || object.id == "orange" { leaf() }
            if object.id == "watermelon" {
                for x in [-0.5, 0.0, 0.5] {
                    let p = UIBezierPath()
                    p.move(to: CGPoint(x: r * x, y: -r * 0.85))
                    p.addQuadCurve(to: CGPoint(x: r * x, y: r * 0.85), controlPoint: CGPoint(x: r * (x + 0.4), y: 0))
                    let stripe = shape(p.cgPath, color: .clear, stroke: UIColor(hex: 0x31975D)); stripe.lineWidth = 4; add(stripe)
                }
            }
            if object.id == "coconut" {
                for x in [-8.0, 0, 8] { add(ellipse(x, 6 - abs(x), 3, 3, UIColor(hex: 0x513F32), stroke: nil)) }
            }
            if object.id == "football" {
                let points: [CGPoint] = (0..<5).map { i in
                    let angle = Double(i) * Double.pi * 2 / 5 + Double.pi / 2
                    return CGPoint(x: CGFloat(cos(angle)) * r * 0.4, y: CGFloat(sin(angle)) * r * 0.4)
                }
                add(polygon(points, color: ArcadePalette.ink))
                for p in points { add(line([p, CGPoint(x: p.x * 2.5, y: p.y * 2.5)], color: ArcadePalette.ink, width: 2)) }
            }
        case "cone":
            add(rect(-r, -r * 0.9, r * 2, r, color, radius: 5))
            add(polygon([.init(x: -r * 0.8, y: -r * 0.45), .init(x: 0, y: r), .init(x: r * 0.8, y: -r * 0.45)], color: color))
            add(polygon([.init(x: -r * 0.48, y: 0), .init(x: -r * 0.28, y: r * 0.4), .init(x: r * 0.28, y: r * 0.4), .init(x: r * 0.48, y: 0)], color: ArcadePalette.paper))
        case "bin":
            add(rect(-r * 0.7, -r * 0.9, r * 1.4, r * 1.65, color))
            add(rect(-r * 0.83, r * 0.65, r * 1.66, 11, UIColor(hex: 0x567E71), radius: 4))
            for x in [-0.35, 0, 0.35] { add(line([.init(x: r * x, y: -r * 0.6), .init(x: r * x, y: r * 0.4)], color: UIColor(hex: 0x52786B))) }
            for x in [-0.5, 0.5] { add(ellipse(r * x, -r * 0.9, 5, 5, ArcadePalette.ink)) }
        case "trolley":
            add(rect(-r * 0.85, -r * 0.55, r * 1.55, r * 1.15, color, radius: 4))
            for i in 0..<4 { let x = -r * 0.6 + CGFloat(i) * r * 0.33; add(line([.init(x: x, y: -r * 0.5), .init(x: x, y: r * 0.6)], color: ArcadePalette.ink, width: 2)) }
            add(line([.init(x: -r, y: r * 0.95), .init(x: -r * 0.85, y: r * 0.95), .init(x: -r * 0.7, y: -r * 0.75), .init(x: r * 0.7, y: -r * 0.75)], color: ArcadePalette.ink))
            for x in [-0.5, 0.5] { add(ellipse(r * x, -r * 0.85, 7, 7, ArcadePalette.ink)) }
        default:
            let h = object.id == "bus" ? r * 2 : r * 1.55
            add(rect(-r * 0.82, -h / 2, r * 1.64, h, color, radius: 12))
            add(rect(-r * 0.64, h * 0.01, r * 1.28, h * 0.32, UIColor(hex: 0x456D7B), radius: 6))
            add(rect(-r * 0.64, -h * 0.33, r * 1.28, h * 0.15, UIColor(hex: 0x456D7B), radius: 4))
            for x in [-0.96, 0.72] {
                add(rect(r * x, h * 0.07, r * 0.24, h * 0.23, ArcadePalette.ink, radius: 3))
                add(rect(r * x, -h * 0.47, r * 0.24, h * 0.23, ArcadePalette.ink, radius: 3))
            }
            for x in [-0.62, 0.32] { add(rect(r * x, h * 0.4, r * 0.3, 7, ArcadePalette.paper, radius: 2, stroke: nil)) }
            if object.id == "bus" { add(label("BIG BUS", size: 10)) }
        }
        return node
    }

    static func gate(_ gate: GateDefinition) -> SKNode {
        let node = SKNode(), dark = UIColor(hex: gate.positive ? 0x245C43 : 0x8E333B)
        node.addChild(rect(-57, -35, 114, 72, UIColor(hex: gate.positive ? 0xB9ED75 : 0xFF927D), radius: 11, stroke: dark))
        for x in [-61.0, 54] { node.addChild(rect(x, -45, 7, 85, dark, radius: 3, stroke: nil)) }
        let title = label(gate.positive ? "GROW" : "SHRINK", size: 10, color: dark); title.position.y = 21; node.addChild(title)
        let value = label(gate.label, size: 30, color: dark); value.position.y = -6; node.addChild(value)
        return node
    }
}

@MainActor
final class HandNode: SKNode {
    let silhouette = SKNode()
    private var fingers: [SKNode] = []
    private let palm: SKNode
    private let thumb: SKNode
    private let face = SKNode()
    private var shownScale = 1.0

    override init() {
        palm = NodeArt.rect(-35, -42, 72, 57, ArcadePalette.skin, radius: 23)
        thumb = NodeArt.rect(-2, -16, 24, 38, ArcadePalette.skin, radius: 12)
        super.init()
        addChild(silhouette)
        let wrist = NodeArt.rect(-15, -69, 30, 41, ArcadePalette.skin, radius: 9); silhouette.addChild(wrist)
        silhouette.addChild(NodeArt.rect(-22, -67, 44, 20, ArcadePalette.purple, radius: 6))
        silhouette.addChild(NodeArt.rect(-20, -54, 40, 7, UIColor(hex: 0xBFA8FF), radius: 3, stroke: nil))
        for (x, length) in [(-36.0, 28.0), (-18, 38), (0, 45), (18, 32)] {
            let finger = SKNode(); finger.position = CGPoint(x: x, y: -14)
            finger.addChild(NodeArt.rect(0, 0, 17, length + 30, ArcadePalette.skin, radius: 8))
            finger.addChild(NodeArt.rect(4, length + 15, 9, 10, UIColor(hex: 0xFFE9BE), radius: 4, stroke: nil))
            fingers.append(finger); silhouette.addChild(finger)
        }
        thumb.position = CGPoint(x: 31, y: -8); thumb.zRotation = 0.6; silhouette.addChild(thumb)
        silhouette.addChild(palm); silhouette.addChild(face)
        for x in [-11.0, 12] {
            face.addChild(NodeArt.ellipse(x, -3, 6, 6, ArcadePalette.paper))
            face.addChild(NodeArt.ellipse(x, -4, 2.6, 3.1, ArcadePalette.ink, stroke: nil))
        }
        let smile = UIBezierPath(); smile.move(to: CGPoint(x: -8, y: -18))
        smile.addQuadCurve(to: CGPoint(x: 12, y: -18), controlPoint: CGPoint(x: 1, y: -28))
        face.addChild(NodeArt.shape(smile.cgPath, color: .clear))
        for x in [-23.0, 26] { face.addChild(NodeArt.ellipse(x, -14, 4, 2, UIColor(hex: 0xEB806B), stroke: nil)) }
    }
    required init?(coder: NSCoder) { fatalError("Programmatic node") }

    func reset(size: Double) {
        removeAllActions(); silhouette.removeAllActions()
        shownScale = GameBalance.handScale(size); setScale(shownScale)
        silhouette.position = .zero; silhouette.xScale = 1; silhouette.yScale = 1; silhouette.zRotation = 0
        for finger in fingers { finger.removeAllActions(); finger.yScale = 1 }
    }
    func grow(size: Double, dt: Double) {
        shownScale += (GameBalance.handScale(size) - shownScale) * (1 - exp(-dt * 9))
        setScale(shownScale)
    }
    func crush(weight: Double, reduceMotion: Bool) {
        silhouette.removeAllActions()
        silhouette.position = .zero; silhouette.xScale = 1; silhouette.yScale = 1
        let press = SKAction.group([.scaleX(to: 1 + weight * 0.1, duration: 0.065), .scaleY(to: 1 - weight * 0.14, duration: 0.065), .moveTo(y: -8 * weight, duration: 0.065)])
        let recoil = SKAction.group([.scaleX(to: 0.98, duration: 0.07), .scaleY(to: 1.05, duration: 0.07), .moveTo(y: reduceMotion ? 0 : 6 * weight, duration: 0.07)])
        silhouette.run(.sequence([press, recoil, .group([.scale(to: 1, duration: 0.14), .moveTo(y: 0, duration: 0.14)])]))
        for finger in fingers { finger.removeAllActions(); finger.run(.sequence([.scaleY(to: 0.7, duration: 0.065), .scaleY(to: 1, duration: 0.22)])) }
    }
    func fail(reduceMotion: Bool) {
        silhouette.removeAllActions()
        silhouette.run(.sequence([.group([.moveTo(y: reduceMotion ? -8 : -30, duration: 0.09), .rotate(toAngle: -0.16, duration: 0.09)]), .wait(forDuration: 0.08), .group([.moveTo(y: 0, duration: 0.3), .rotate(toAngle: 0, duration: 0.3)])]))
    }
}
