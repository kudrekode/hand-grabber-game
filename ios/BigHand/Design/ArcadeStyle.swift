import SwiftUI
import UIKit

enum ArcadePalette {
    static let ink = UIColor(hex: 0x253132)
    static let paper = UIColor(hex: 0xFFF7E7)
    static let track = UIColor(hex: 0xECE5D2)
    static let lime = UIColor(hex: 0xC6F45E)
    static let coral = UIColor(hex: 0xED6B59)
    static let gold = UIColor(hex: 0xFFCE59)
    static let skin = UIColor(hex: 0xFFC477)
    static let purple = UIColor(hex: 0x8065D4)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

enum ArcadeType {
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .black, design: .rounded) }
    static let caption = Font.system(size: 11, weight: .heavy, design: .rounded)
}

struct ArcadeButtonStyle: ButtonStyle {
    var fill: Color = Color(uiColor: ArcadePalette.lime)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .black, design: .rounded))
            .frame(maxWidth: .infinity).padding(.vertical, 15).padding(.horizontal, 12)
            .foregroundStyle(Color(uiColor: ArcadePalette.ink))
            .background(fill, in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(Color(uiColor: ArcadePalette.ink), lineWidth: 3))
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct ArcadePanel: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(18).background(Color(uiColor: ArcadePalette.paper), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color(uiColor: ArcadePalette.ink), lineWidth: 3))
    }
}
