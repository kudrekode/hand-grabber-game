import SwiftUI
import SpriteKit

@MainActor
private final class HeroScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size); scaleMode = .aspectFill; backgroundColor = ArcadePalette.paper
        let hand = HandNode(); hand.position = CGPoint(x: 150, y: 110); hand.setScale(1.3); addChild(hand)
        if !UIAccessibility.isReduceMotionEnabled {
            hand.run(.repeatForever(.sequence([.moveBy(x: 0, y: 6, duration: 0.75), .moveBy(x: 0, y: -6, duration: 0.75)])))
        }
        for (index, id) in ["cherry", "watermelon"].enumerated() {
            if let object = ObjectCatalog.all.first(where: { $0.id == id }) {
                let node = NodeArt.object(object); node.setScale(0.75)
                node.position = CGPoint(x: index == 0 ? 46 : 252, y: index == 0 ? 90 : 120); addChild(node)
            }
        }
    }
    required init?(coder: NSCoder) { fatalError("Programmatic scene") }
}

struct HomeView: View {
    @EnvironmentObject private var session: GameSession
    @State private var hero = HeroScene(size: CGSize(width: 300, height: 210))
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("SMALL THINGS. BIG PROBLEMS.").font(ArcadeType.caption).tracking(1.5)
                HStack(alignment: .bottom) {
                    Text("BIG\nHAND.").font(ArcadeType.title(72)).lineSpacing(-15).tracking(-4)
                    Spacer()
                    Text("CRUSH.\nGROW.\nGO AGAIN.").font(ArcadeType.title(17)).padding(.bottom, 5)
                }
                SpriteView(scene: hero).frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 18))
                    .accessibilityLabel("A small cartoon hand, a cherry and a watermelon")
                Text("Drag anywhere on the track. Crush things smaller than your hand. Steer clear of bigger things.")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                VStack(spacing: 10) {
                    Button("LET’S CRUSH →") { session.start() }.buttonStyle(ArcadeButtonStyle())
                    Button(session.boosted ? "NEXT RUN: 50% BIGGER" : "SIMULATED REWARD · START 50% BIGGER") {
                        Task { await session.reward(.biggerStart) }
                    }.buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: ArcadePalette.gold)))
                        .disabled(session.boosted || session.rewardBusy)
                    Button("UPGRADES · \(session.save.coins.formatted()) COINS") { session.shopOpen = true }
                        .buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: ArcadePalette.paper)))
                }.disabled(session.rewardBusy)
                HStack {
                    record("BEST", session.save.bestScore.formatted())
                    Spacer(); record("LARGEST", "\(Int(session.save.maxHandSize))")
                    Spacer(); record("DISTANCE", "\(Int(session.save.longestDistance)) m")
                }
                FeedbackToggles()
                Text("\(session.save.totalRuns) runs · Rewards are simulated. No real ads.").font(ArcadeType.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
        }
    }
    private func record(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) { Text(label).font(ArcadeType.caption); Text(value).font(ArcadeType.title(21)) }
    }
}
