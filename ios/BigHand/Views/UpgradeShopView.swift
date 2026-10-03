import SwiftUI

struct UpgradeShopView: View {
    @EnvironmentObject private var session: GameSession
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text("UPGRADE\nSHOP.").font(ArcadeType.title(42)).tracking(-2)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.title3.bold()).frame(width: 44, height: 44) }.accessibilityLabel("Close shop")
                }
                NextUpgradeView()
                Text("Permanent. Apply to your next new run.").font(ArcadeType.caption)
                ForEach(Upgrade.allCases) { upgrade in
                    let level = session.save.upgrades[upgrade, default: 0]
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                        HStack { Text(upgrade.title).font(ArcadeType.title(20)); Spacer(); Text("\(level)/5").font(ArcadeType.caption) }
                        Text(upgrade.detail).font(.system(size: 13, weight: .medium, design: .rounded))
                        Text(upgrade.effectLabel(level: level) + (level < 5 ? " → " + upgrade.effectLabel(level: level + 1) : " · MAX"))
                            .font(.system(size: 14, weight: .heavy, design: .rounded)).foregroundStyle(Color(uiColor: ArcadePalette.purple))
                        HStack(spacing: 6) {
                            ForEach(0..<5) { index in Capsule().fill(index < level ? Color(uiColor: ArcadePalette.purple) : Color(uiColor: ArcadePalette.ink).opacity(0.15)).frame(width: 25, height: 5) }
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
            }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
        .foregroundStyle(Color(uiColor: ArcadePalette.ink))
        .background(Color(uiColor: ArcadePalette.paper).ignoresSafeArea())
        .presentationDragIndicator(.visible)
    }
}
