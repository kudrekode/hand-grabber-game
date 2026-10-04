import Foundation

struct GateDefinition: Equatable, Sendable {
    enum Operation: Sendable { case add, multiply, subtract }
    let operation: Operation
    let amount: Double
    let label: String
    let positive: Bool
    let weight: Int
}

enum GateSystem {
    static let all: [GateDefinition] = [
        .init(operation: .add, amount: 10, label: "+10", positive: true, weight: 18),
        .init(operation: .add, amount: 25, label: "+25", positive: true, weight: 1),
        .init(operation: .multiply, amount: 1.5, label: "×1.5", positive: true, weight: 1),
        .init(operation: .subtract, amount: 10, label: "−10", positive: false, weight: 3),
        .init(operation: .multiply, amount: 0.5, label: "÷2", positive: false, weight: 1)
    ]
    static func apply(_ gate: GateDefinition, to size: Double) -> Double {
        switch gate.operation {
        case .add: max(1, size + gate.amount)
        case .multiply: max(1, size * gate.amount)
        case .subtract: max(1, size - gate.amount)
        }
    }
    static func pick<R: RandomNumberGenerator>(positive: Bool, handSize: Double = 20, using random: inout R) -> GateDefinition {
        let pool = all.filter { $0.positive == positive }
        var roll = Int.random(in: 0..<pool.reduce(0) { $0 + $1.weight }, using: &random)
        for gate in pool { roll -= gate.weight; if roll < 0 { return scaled(gate, handSize: handSize) } }
        return scaled(pool[pool.count - 1], handSize: handSize)
    }
    static func scaled(_ gate: GateDefinition, handSize: Double) -> GateDefinition {
        guard gate.operation != .multiply else { return gate }
        let amount = (gate.amount * max(1, handSize / 80)).rounded(.up)
        return .init(operation: gate.operation, amount: amount,
                     label: "\(gate.positive ? "+" : "−")\(String(format: "%.0f", amount))", positive: gate.positive, weight: gate.weight)
    }
}
