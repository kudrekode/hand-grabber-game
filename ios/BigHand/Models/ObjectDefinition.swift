import Foundation

struct ObjectDefinition: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let size: Double
    let score: Int
    let coins: Int
    let color: UInt32
    var isFruit: Bool { ["cherry", "strawberry", "apple", "orange", "coconut", "watermelon"].contains(id) }
}

enum ObjectCatalog {
    // The current prototype values take precedence over the older spec.md.
    static let all: [ObjectDefinition] = [
        .init(id: "cherry", name: "Cherry", size: 5, score: 5, coins: 1, color: 0xEC4564),
        .init(id: "strawberry", name: "Strawberry", size: 8, score: 8, coins: 1, color: 0xF75262),
        .init(id: "apple", name: "Apple", size: 12, score: 12, coins: 2, color: 0xF16C47),
        .init(id: "orange", name: "Orange", size: 15, score: 15, coins: 2, color: 0xFFB540),
        .init(id: "coconut", name: "Coconut", size: 22, score: 20, coins: 3, color: 0xA7744C),
        .init(id: "watermelon", name: "Watermelon", size: 35, score: 30, coins: 4, color: 0x6BD68C),
        .init(id: "football", name: "Football", size: 45, score: 40, coins: 5, color: 0xE9EEEE),
        .init(id: "cone", name: "Traffic Cone", size: 55, score: 50, coins: 6, color: 0xFF924B),
        .init(id: "bin", name: "Bin", size: 70, score: 70, coins: 8, color: 0x87B8A6),
        .init(id: "trolley", name: "Shopping Trolley", size: 90, score: 90, coins: 10, color: 0xA3CAD0),
        .init(id: "car", name: "Car", size: 180, score: 150, coins: 20, color: 0xAD9DF8),
        .init(id: "bus", name: "Bus", size: 360, score: 250, coins: 30, color: 0xFFCE59)
    ]
}
