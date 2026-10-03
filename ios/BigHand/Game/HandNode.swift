import SpriteKit
import UIKit

// Small, cached authored vector parts rasterized once at 3x. No per-frame path work.
@MainActor
private enum HandArt {
    static var cache: [String: SKTexture] = [:]
    static func texture(skin: HandSkin, part: String, width: CGFloat, height: CGFloat) -> SKTexture {
        let key = "\(skin.id)-\(part)-\(width)-\(height)"
        if let texture = cache[key] { return texture }
        let format = UIGraphicsImageRendererFormat(); format.scale = 3
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { renderer in
            let c = renderer.cgContext
            c.translateBy(x: width / 2, y: height / 2); c.scaleBy(x: 1, y: -1)
            c.setLineCap(.round); c.setLineJoin(.round)
            let colors = skin.colors
            func draw(_ path: UIBezierPath, _ hex: UInt32, outline: Bool = false) {
                c.addPath(path.cgPath); c.setFillColor(UIColor(hex: hex).cgColor); c.fillPath()
                if outline { c.addPath(path.cgPath); c.setStrokeColor(ArcadePalette.ink.cgColor); c.setLineWidth(2.8); c.strokePath() }
            }
            func rect(_ r: CGRect, radius: CGFloat, color: UInt32) { draw(UIBezierPath(roundedRect: r, cornerRadius: radius), color) }
            func line(_ a: CGPoint, _ b: CGPoint, width: CGFloat = 1.5) {
                c.move(to: a); c.addLine(to: b); c.setStrokeColor(UIColor(hex: colors.shade).cgColor); c.setLineWidth(width); c.strokePath()
            }
            let path: UIBezierPath
            if part == "palm" {
                path = UIBezierPath()
                path.move(to: CGPoint(x: -37, y: 28))
                path.addCurve(to: CGPoint(x: 34, y: 26), controlPoint1: CGPoint(x: -12, y: 35), controlPoint2: CGPoint(x: 14, y: 32))
                path.addCurve(to: CGPoint(x: 34, y: -23), controlPoint1: CGPoint(x: 43, y: 14), controlPoint2: CGPoint(x: 43, y: -12))
                path.addCurve(to: CGPoint(x: -27, y: -34), controlPoint1: CGPoint(x: 16, y: -49), controlPoint2: CGPoint(x: -11, y: -48))
                path.addCurve(to: CGPoint(x: -37, y: 28), controlPoint1: CGPoint(x: -42, y: -27), controlPoint2: CGPoint(x: -41, y: 7)); path.close()
            } else {
                path = UIBezierPath(roundedRect: CGRect(x: -width / 2 + 3, y: -height / 2 + 3, width: width - 6, height: height - 6), cornerRadius: part == "cuff" ? 5 : (width - 6) / 2)
            }
            draw(path, part == "cuff" ? colors.cuff : colors.base, outline: true)
            c.saveGState(); c.addPath(path.cgPath); c.clip()
            rect(CGRect(x: width / 2 - 13, y: -height / 2, width: 16, height: height), radius: 7, color: part == "cuff" ? 0x253132 : colors.shade)
            if part == "palm" {
                draw(UIBezierPath(ovalIn: CGRect(x: -30, y: -18, width: 35, height: 39)), colors.highlight)
                if skin == .robot {
                    rect(CGRect(x: -24, y: -23, width: 48, height: 44), radius: 6, color: colors.shade)
                    rect(CGRect(x: -19, y: -15, width: 38, height: 29), radius: 3, color: colors.highlight)
                    for x in [-27.0, 28.0] { draw(UIBezierPath(ovalIn: CGRect(x: x, y: 19, width: 4, height: 4)), 0x253132) }
                    line(CGPoint(x: -15, y: -5), CGPoint(x: 15, y: -5), width: 3)
                } else if skin == .foam {
                    // Readable foam sporting-hand mark; all five digits stay distinct.
                    rect(CGRect(x: -7, y: -24, width: 14, height: 42), radius: 2, color: colors.cuff)
                    rect(CGRect(x: -16, y: -25, width: 32, height: 7), radius: 2, color: colors.cuff)
                    rect(CGRect(x: -16, y: 8, width: 16, height: 8), radius: 2, color: colors.cuff)
                } else {
                    let crease = UIBezierPath(); crease.move(to: CGPoint(x: -21, y: 10))
                    crease.addQuadCurve(to: CGPoint(x: 22, y: 6), controlPoint: CGPoint(x: 0, y: -1))
                    c.addPath(crease.cgPath); c.setStrokeColor(UIColor(hex: colors.shade).cgColor); c.setLineWidth(2); c.strokePath()
                    line(CGPoint(x: 18, y: -4), CGPoint(x: 9, y: -21), width: 2)
                    if skin == .redGlove || skin == .zombie {
                        line(CGPoint(x: -19, y: -17), CGPoint(x: 5, y: -28), width: 2)
                        for x in stride(from: -16.0, through: 2, by: 6) { line(CGPoint(x: x, y: -15 - (x + 16) * 0.4), CGPoint(x: x + 2, y: -24 - (x + 16) * 0.4), width: 2) }
                    }
                }
            } else if part == "cuff" {
                rect(CGRect(x: -width / 2 + 6, y: 1, width: width - 12, height: 4), radius: 2, color: colors.highlight)
            } else {
                rect(CGRect(x: -width / 2 + 7, y: height / 2 - 23, width: width - 15, height: 15), radius: 5, color: colors.highlight)
                let joints: [CGFloat] = skin == .robot ? [-7, 0, 7] : [-5]
                for y in joints {
                    line(CGPoint(x: -width / 2 + 7, y: y), CGPoint(x: width / 2 - 7, y: y), width: skin == .robot ? 2.5 : 1.3)
                }
            }
            c.restoreGState()
        }
        let texture = SKTexture(image: image); texture.filteringMode = .linear; cache[key] = texture
        return texture
    }
}

@MainActor
final class HandNode: SKNode {
    let silhouette = SKNode()
    private let palm = SKNode()
    private let thumb = SKNode()
    private var fingers: [SKNode] = []
    private let shadow = NodeArt.ellipse(1, -40, 48, 16, ArcadePalette.ink.withAlphaComponent(0.14), stroke: nil)
    private var rest: [CGPoint] = []
    private var shownScale = 1.0
    private(set) var skin: HandSkin = .classic
    private var lean: CGFloat = 0

    override init() {
        super.init(); name = "hand"
        addChild(shadow); addChild(silhouette)
        equip(.classic)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic node") }

    func equip(_ skin: HandSkin) {
        self.skin = skin
        silhouette.removeAllChildren(); silhouette.removeAllActions(); fingers.removeAll(); rest.removeAll()
        palm.removeAllChildren(); thumb.removeAllChildren()
        func sprite(_ part: String, _ width: CGFloat, _ height: CGFloat) -> SKSpriteNode {
            SKSpriteNode(texture: HandArt.texture(skin: skin, part: part, width: width, height: height), size: CGSize(width: width, height: height))
        }
        let wrist = sprite("wrist", 38, 51); wrist.position = CGPoint(x: 0, y: -51); silhouette.addChild(wrist)
        for (i, values) in [(-29.0, 49.0), (-9, 64), (13, 59), (33, 43)].enumerated() {
            let finger = SKNode(); finger.name = "finger\(i)"
            let length = values.1 + (skin == .foam && i == 1 ? 12 : 0)
            let art = sprite("finger\(i)", 25, length + 8); art.position.y = length / 2
            finger.addChild(art); finger.position = CGPoint(x: values.0, y: 3)
            finger.zRotation = CGFloat(1.5 - Double(i)) * 0.045
            fingers.append(finger); rest.append(finger.position); silhouette.addChild(finger)
        }
        thumb.name = "thumb"; thumb.position = CGPoint(x: 34, y: -18); thumb.zRotation = -0.75
        let thumbArt = sprite("thumb", 30, 48); thumbArt.position.y = 19; thumb.addChild(thumbArt); silhouette.addChild(thumb)
        palm.name = "palm"; palm.position.y = -10; palm.addChild(sprite("palm", 90, 94)); silhouette.addChild(palm)
        let cuff = sprite("cuff", 47, 24); cuff.position = CGPoint(x: 0, y: -62); silhouette.addChild(cuff)
        restorePose()
    }
    private func restorePose() {
        silhouette.position = .zero; silhouette.zRotation = 0
        palm.xScale = 1; palm.yScale = 1; palm.position.y = -10
        thumb.zRotation = -0.75; thumb.yScale = 1
        for (i, finger) in fingers.enumerated() {
            finger.position = rest[i]; finger.yScale = 1; finger.xScale = 1
            finger.zRotation = CGFloat(1.5 - Double(i)) * 0.045
        }
    }
    func reset(size: Double) {
        removeAllActions(); silhouette.removeAllActions(); restorePose()
        lean = 0; zRotation = 0
        shownScale = GameBalance.handScale(size); setScale(shownScale)
    }
    func grow(size: Double, dt: Double) {
        shownScale += (GameBalance.handScale(size) - shownScale) * (1 - exp(-dt * 9)); setScale(shownScale)
    }
    func steer(velocity: Double, dt: Double, reduceMotion: Bool) {
        let target = reduceMotion ? 0 : max(-0.12, min(0.12, -velocity / 6500))
        lean += (CGFloat(target) - lean) * CGFloat(1 - exp(-dt * 16)); zRotation = lean
    }
    func crush(profile: ImpactProfile, reduceMotion: Bool) {
        silhouette.removeAllActions(); restorePose()
        let w = profile.weight, contact = profile.contactDelay, release = contact + profile.hold
        let duration = release + DesignSystem.settle
        silhouette.run(.sequence([.customAction(withDuration: duration) { [weak self] _, elapsed in
            guard let self else { return }
            let t = Double(elapsed)
            let press = t < contact ? sin(t / contact * .pi / 2) : t < release ? 1 : pow(max(0, 1 - (t - release) / DesignSystem.settle), 2)
            let recoil = t < release ? 0 : sin(min(1, (t - release) / DesignSystem.settle) * .pi)
            self.palm.xScale = 1 + w * 0.12 * press
            self.palm.yScale = 1 - w * 0.19 * press
            self.palm.position.y = -10 - w * 5 * press
            self.silhouette.position.y = reduceMotion ? 0 : w * (10 * press - 12 * recoil)
            self.thumb.zRotation = -0.75 + 0.85 * press
            self.thumb.yScale = 1 - 0.22 * press
            for (i, finger) in self.fingers.enumerated() {
                finger.yScale = 1 - (0.30 + 0.08 * w) * press
                finger.xScale = 1 + 0.10 * press
                finger.position = CGPoint(x: self.rest[i].x * (1 - 0.18 * press), y: self.rest[i].y - 7 * press)
                finger.zRotation = CGFloat(1.5 - Double(i)) * (0.045 + 0.10 * press)
            }
        }, .run { [weak self] in self?.restorePose() }]), withKey: "crush")
    }
    func fail(reduceMotion: Bool) {
        silhouette.removeAllActions(); restorePose()
        silhouette.run(.sequence([.group([.moveTo(y: reduceMotion ? -5 : -21, duration: 0.09), .rotate(toAngle: reduceMotion ? 0 : -0.18, duration: 0.09)]), .wait(forDuration: 0.08), .group([.moveTo(y: 0, duration: 0.28), .rotate(toAngle: 0, duration: 0.28)])]))
    }
}
