import SwiftUI
import SpriteKit

struct UpgradeShopView: View {
    @EnvironmentObject private var session: GameSession
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("THE\nWORKSHOP.").font(ArcadeType.title(42)).tracking(-2)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.title3.bold()).frame(width: 44, height: 44) }.accessibilityLabel("Close shop")
                }
                NextUpgradeView()
                Text("Permanent. Apply to your next new run.").font(ArcadeType.caption)
                Text("UPGRADES").font(ArcadeType.title(24))
                ForEach(Upgrade.allCases) { upgrade in
                    let level = session.save.upgrades[upgrade, default: 0]
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        HStack { Text(upgrade.title).font(ArcadeType.title(20)); Spacer(); Text("\(level)/5").font(ArcadeType.caption) }
                        Text(upgrade.detail).font(ArcadeType.body(13))
                        Text(upgrade.effectLabel(level: level) + (level < 5 ? " → " + upgrade.effectLabel(level: level + 1) : " · MAX"))
                            .font(ArcadeType.body(14)).foregroundStyle(Color(uiColor: ArcadePalette.accent))
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in Capsule().fill(index < level ? Color(uiColor: ArcadePalette.accent) : Color(uiColor: ArcadePalette.ink).opacity(0.15)).frame(width: 25, height: 5) }
                            Spacer()
                        }.accessibilityHidden(true)
                        if let cost = upgrade.cost(at: level) {
                            Button("BUY · \(cost.formatted()) COINS") { session.buy(upgrade) }
                                .buttonStyle(ArcadeButtonStyle())
                                .disabled(session.save.coins < cost)
                                .opacity(session.save.coins < cost ? 0.45 : 1)
                                .accessibilityLabel("Buy \(upgrade.title) level \(level + 1) for \(cost) coins")
                        }
                    }
                }
                Divider().overlay(Color(uiColor: ArcadePalette.ink))
                Text("HAND COLLECTION").font(ArcadeType.title(24))
                Text("Same crushing power. A different kind of hand.").font(ArcadeType.caption)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(HandSkin.allCases) { skin in
                        let owned = session.save.unlockedSkins.contains(skin)
                        let equipped = session.save.equippedSkin == skin
                        VStack(alignment: .leading, spacing: 6) {
                            SkinPreview(skin: skin)
                            Text(skin.title.uppercased()).font(ArcadeType.title(15)).minimumScaleFactor(0.8).lineLimit(1)
                            Text(equipped ? "ON YOUR HAND" : owned ? "READY TO WEAR" : "LOCKED · COIN UNLOCK").font(ArcadeType.caption)
                            Button(equipped ? "EQUIPPED" : owned ? "EQUIP" : "\(skin.coinPrice.formatted()) COINS") { session.selectSkin(skin) }
                                .buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: equipped ? ArcadePalette.paper : ArcadePalette.lime)))
                                .disabled(equipped || (!owned && session.save.coins < skin.coinPrice))
                                .opacity(!owned && session.save.coins < skin.coinPrice ? 0.5 : 1)
                                .accessibilityLabel(equipped ? "\(skin.title), equipped" : owned ? "Equip \(skin.title)" : "Unlock and equip \(skin.title), \(skin.coinPrice) coins")
                        }
                    }
                }
            }.padding(DesignSystem.inset).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color(uiColor: ArcadePalette.ink))
        .background(Color(uiColor: ArcadePalette.paper).ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }
}

@MainActor
private final class SkinPreviewScene: SKScene {
    init(skin: HandSkin) {
        super.init(size: CGSize(width: 150, height: 162))
        backgroundColor = ArcadePalette.paper; scaleMode = .resizeFill
        let hand = HandNode(); hand.equip(skin); hand.setScale(0.95)
        hand.position = CGPoint(x: 72, y: 79); addChild(hand)
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard let hand = children.first as? HandNode else { return }
        hand.position = CGPoint(x: size.width / 2, y: size.height / 2 + 4)
        hand.setScale(min((size.height - 16) / 160, (size.width - 12) / 125))
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }
}

private struct SkinPreview: View {
    @State private var scene: SkinPreviewScene
    init(skin: HandSkin) { _scene = State(initialValue: SkinPreviewScene(skin: skin)) }
    var body: some View {
        SpriteView(scene: scene, preferredFramesPerSecond: 30)
            .frame(height: 138).allowsHitTesting(false).accessibilityHidden(true)
    }
}
