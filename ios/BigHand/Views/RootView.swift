import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: GameSession
    var body: some View {
        Group {
            switch session.route {
            case .home: HomeView()
            case .playing: GameView()
            case .results: if let result = session.result { ResultsView(result: result) }
            }
        }
        .foregroundStyle(Color(uiColor: ArcadePalette.ink))
        .background(Color(uiColor: ArcadePalette.track).ignoresSafeArea())
        .sheet(isPresented: $session.shopOpen) { UpgradeShopView().environmentObject(session) }
    }
}

struct FeedbackToggles: View {
    @EnvironmentObject private var session: GameSession
    var body: some View {
        HStack(spacing: 18) {
            Toggle("Sound", isOn: $session.soundEnabled)
            Toggle("Haptics", isOn: $session.hapticsEnabled)
        }
        .font(ArcadeType.caption).tint(Color(uiColor: ArcadePalette.accent))
    }
}

struct NextUpgradeView: View {
    @EnvironmentObject private var session: GameSession
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack { Text("TOTAL COINS").font(ArcadeType.caption); Spacer(); Text(session.save.coins.formatted()).font(ArcadeType.title(24)) }
            if let upgrade = session.save.nextUpgrade, let cost = upgrade.cost(at: session.save.upgrades[upgrade, default: 0]) {
                if session.save.coins >= cost {
                    Text("Ready: \(upgrade.title) · \(cost.formatted()) coins").font(ArcadeType.body(13))
                } else {
                    Text("\((cost - session.save.coins).formatted()) more coins for \(upgrade.title)").font(ArcadeType.body(13))
                }
            } else { Text("Every upgrade is maxed. Go absurd.").font(ArcadeType.caption) }
        }
    }
}
