import SpriteKit
import UIKit

@MainActor
enum NodeArt {
    private static var objects: [String: (SKTexture, CGRect)] = [:]
    private static var particles: [Bool: SKTexture] = [:]
    static func prewarm(in view: SKView) {
        for object in ObjectCatalog.all where objects[object.id] == nil {
            let node = self.object(object)
            let bounds = node.calculateAccumulatedFrame().insetBy(dx: -3, dy: -3)
            if let texture = view.texture(from: node, crop: bounds) { objects[object.id] = (texture, bounds) }
        }
        _ = particleTexture(fruit: true); _ = particleTexture(fruit: false)
    }
    static func cachedObject(_ object: ObjectDefinition) -> SKNode {
        guard let (texture, bounds) = objects[object.id] else { return self.object(object) }
        let node = SKNode(), sprite = SKSpriteNode(texture: texture, size: bounds.size)
        sprite.position = CGPoint(x: bounds.midX, y: bounds.midY); node.addChild(sprite)
        return node
    }
    static func particleTexture(fruit: Bool) -> SKTexture {
        if let texture = particles[fruit] { return texture }
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        let image = UIGraphicsImageRenderer(size: CGSize(width: 10, height: 10), format: format).image { _ in
            UIColor.white.setFill()
            if fruit { UIBezierPath(ovalIn: CGRect(x: 2, y: 1, width: 6, height: 8)).fill() }
            else {
                let path = UIBezierPath(); path.move(to: CGPoint(x: 1, y: 3)); path.addLine(to: CGPoint(x: 8, y: 1)); path.addLine(to: CGPoint(x: 9, y: 7)); path.addLine(to: CGPoint(x: 3, y: 9)); path.close(); path.fill()
            }
        }
        let texture = SKTexture(image: image); particles[fruit] = texture; return texture
    }

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
        let node = SKLabelNode(fontNamed: DesignSystem.fontName)
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
        let shadow = ellipse(3, -r * 0.7 - 3, r * 0.86, r * 0.22, ArcadePalette.ink.withAlphaComponent(0.14), stroke: nil)
        shadow.zPosition = -2; node.addChild(shadow)
        if object.isFruit {
            let highlight = ellipse(-r * 0.32, r * 0.24, r * 0.12, r * 0.24, ArcadePalette.paper.withAlphaComponent(0.65), stroke: nil)
            highlight.zRotation = -0.5; node.addChild(highlight)
        } else {
            let seam = line([CGPoint(x: -r * 0.53, y: -r * 0.6), CGPoint(x: r * 0.5, y: -r * 0.6)], color: ArcadePalette.ink.withAlphaComponent(0.3), width: 3)
            node.addChild(seam)
        }
        return node
    }

    static func gate(_ gate: GateDefinition) -> SKNode {
        let node = SKNode(), dark = UIColor(hex: gate.positive ? 0x245C43 : 0x8E333B)
        let fill = gate.positive ? ArcadePalette.lime : UIColor(hex: 0xF8977E)
        node.addChild(rect(-59, -43, 118, 10, ArcadePalette.ink.withAlphaComponent(0.15), radius: 3, stroke: nil))
        for x in [-58.0, 50] {
            node.addChild(rect(x, -35, 8, 92, dark, radius: 3, stroke: nil))
            node.addChild(rect(x - 4, -39, 16, 8, dark, radius: 2, stroke: nil))
        }
        node.addChild(rect(-57, -22, 114, 78, fill, radius: DesignSystem.radius, stroke: dark))
        node.addChild(rect(-53, 40, 106, 12, dark, radius: 3, stroke: nil))
        let title = label(gate.positive ? "GROW" : "SHRINK", size: 10, color: ArcadePalette.paper); title.position.y = 46; node.addChild(title)
        let value = label(gate.label, size: 33, color: dark); value.position.y = 12; node.addChild(value)
        let arrow = gate.positive ? [CGPoint(x: -7, y: -12), CGPoint(x: 0, y: -5), CGPoint(x: 7, y: -12)] : [CGPoint(x: -7, y: -5), CGPoint(x: 0, y: -12), CGPoint(x: 7, y: -5)]
        node.addChild(line(arrow, color: dark, width: 3))
        return node
    }

    static func coin() -> SKNode {
        let node = SKNode()
        node.addChild(ellipse(1, -3, 11, 10, UIColor(hex: 0xAE772A)))
        node.addChild(ellipse(0, 0, 11, 10, ArcadePalette.gold))
        node.addChild(ellipse(0, 0, 7, 6, .clear, stroke: UIColor(hex: 0xAE772A)))
        node.addChild(line([CGPoint(x: 0, y: -3), CGPoint(x: 0, y: 3)], color: UIColor(hex: 0xAE772A), width: 2))
        return node
    }
}
