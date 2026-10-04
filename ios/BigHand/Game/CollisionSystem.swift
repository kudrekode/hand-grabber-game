import Foundation

enum CollisionSystem {
    static func canCrush(hand: Double, object: Double) -> Bool { hand >= object }
    static func handBounds(size: Double) -> (x: Double, y: Double) {
        let scale = GameBalance.handScale(size)
        return (min(55, 33 * scale), min(34, 23 * scale))
    }
    static func radius(_ object: ObjectDefinition) -> Double { min(60, 18 + sqrt(object.size) * 2.15) }
    static func objectBounds(_ object: ObjectDefinition) -> (x: Double, y: Double) {
        let r = radius(object)
        return (min(48, r * 0.78), r * 0.72)
    }
    // Test the closest point on relative motion, so a dropped frame cannot skip a collision.
    static func contact(fromX: Double, fromY: Double, toX: Double, toY: Double,
                        handSize: Double, object: ObjectDefinition) -> Bool {
        let h = handBounds(size: handSize), o = objectBounds(object)
        return sweptEllipse(fromX: fromX, fromY: fromY, toX: toX, toY: toY, rx: h.x + o.x, ry: h.y + o.y)
    }
    static func sweptEllipse(fromX: Double, fromY: Double, toX: Double, toY: Double, rx: Double, ry: Double) -> Bool {
        let ax = fromX / rx, ay = fromY / ry, vx = (toX - fromX) / rx, vy = (toY - fromY) / ry
        let length = vx * vx + vy * vy
        let t = length > 0 ? min(1, max(0, -(ax * vx + ay * vy) / length)) : 0
        return pow(ax + t * vx, 2) + pow(ay + t * vy, 2) <= 1
    }
    static func impact(_ size: Double) -> Double { min(1.65, 0.22 + sqrt(size / 180)) }
}
