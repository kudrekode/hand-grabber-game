import SwiftUI
import UIKit

enum ArcadePalette {
    static let ink = UIColor(hex: 0x253132)
    static let paper = UIColor(hex: 0xFFF7E7)
    static let track = UIColor(hex: 0xE8DECA)
    static let lime = UIColor(hex: 0xC6F45E)
    static let coral = UIColor(hex: 0xED6B59)
    static let gold = UIColor(hex: 0xFFCE59)
    static let skin = UIColor(hex: 0xFFC477)
    static let accent = UIColor(hex: 0x375B55)
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
                  blue: CGFloat(hex & 255) / 255, alpha: 1)
    }
}

enum DesignSystem {
    static let space: CGFloat = 8
    static let inset: CGFloat = 24
    static let radius: CGFloat = 10
    static let outline: CGFloat = 2.5
    static let press = 0.09
    static let settle = 0.22
    static let fontName = "AvenirNext-Heavy"
}

enum ArcadeType {
    static func title(_ size: CGFloat) -> Font { .custom(DesignSystem.fontName, size: size, relativeTo: .title) }
    static func body(_ size: CGFloat = 16) -> Font { .custom("AvenirNext-DemiBold", size: size, relativeTo: .body) }
    static let caption = Font.custom("AvenirNext-DemiBold", size: 11, relativeTo: .caption)
}

struct ArcadeButtonStyle: ButtonStyle {
    var fill: Color = Color(uiColor: ArcadePalette.lime)
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ArcadeType.title(17))
            .frame(maxWidth: .infinity).padding(.vertical, 15).padding(.horizontal, 12)
            .foregroundStyle(Color(uiColor: ArcadePalette.ink))
            .background(fill, in: RoundedRectangle(cornerRadius: DesignSystem.radius))
            .background(RoundedRectangle(cornerRadius: DesignSystem.radius).fill(Color(uiColor: ArcadePalette.ink)).offset(y: configuration.isPressed ? 1 : 4))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.radius).strokeBorder(Color(uiColor: ArcadePalette.ink), lineWidth: DesignSystem.outline))
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeOut(duration: DesignSystem.press), value: configuration.isPressed)
    }
}

struct ArcadePanel: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(18).background(Color(uiColor: ArcadePalette.paper), in: RoundedRectangle(cornerRadius: DesignSystem.radius))
            .overlay(RoundedRectangle(cornerRadius: DesignSystem.radius).strokeBorder(Color(uiColor: ArcadePalette.ink), lineWidth: DesignSystem.outline))
    }
}
