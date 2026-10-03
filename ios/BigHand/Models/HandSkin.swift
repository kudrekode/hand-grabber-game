import Foundation

// Stable entitlement IDs; a future StoreKit adapter can grant these without touching run stats.
enum HandSkin: String, CaseIterable, Codable, Identifiable, Sendable {
    case classic, redGlove, gold, robot, zombie, foam
    var id: String { rawValue }
    var title: String {
        switch self {
        case .classic: "Classic"
        case .redGlove: "Red Glove"
        case .gold: "Gold Hand"
        case .robot: "Robot Hand"
        case .zombie: "Zombie Hand"
        case .foam: "Foam Finger"
        }
    }
    var coinPrice: Int {
        switch self {
        case .classic: 0
        case .redGlove: 500
        case .gold: 4_500
        case .robot: 1_500
        case .zombie: 1_500
        case .foam: 500
        }
    }
    var colors: (base: UInt32, shade: UInt32, highlight: UInt32, cuff: UInt32) {
        switch self {
        case .classic: (0xF9BD79, 0xDC8A56, 0xFFE1AE, 0x375B55)
        case .redGlove: (0xE66050, 0xA63839, 0xFF9880, 0xFFF3DC)
        case .gold: (0xE8B647, 0xAF772A, 0xFFE6A0, 0x375B55)
        case .robot: (0xAABAB9, 0x647E80, 0xE6EEDE, 0xE66050)
        case .zombie: (0xACC180, 0x6B8B64, 0xD9DFA1, 0x735D77)
        case .foam: (0xE78645, 0xAF502D, 0xFFBE76, 0xFFF3DC)
        }
    }
}
