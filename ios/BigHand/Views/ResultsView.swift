import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var session: GameSession
    let result: RunResult
    private let columns = [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(result.isHighScore ? "NEW BEST SCORE!" : "\(GameBalance.stage(result.state.maxSize)) HAND. BIG AMBITIONS.")
                    .font(ArcadeType.caption).tracking(1)
                Text("TOO\nSMALL!").font(ArcadeType.title(64)).lineSpacing(-10).tracking(-3)
                    .foregroundStyle(Color(uiColor: ArcadePalette.coral))
                Text("\(result.obstacle.name) needed \(Int(result.obstacle.size)). Your hand was \((floor(result.state.size * 10) / 10).formatted(.number.precision(.fractionLength(1)))).")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                LazyVGrid(columns: columns, alignment: .leading, spacing: 18) {
                    stat("SCORE", result.state.score.formatted())
                    stat("DISTANCE", "\(Int(result.state.distance)) m")
                    stat("LARGEST HAND", "\(Int(result.state.maxSize))")
                    stat(result.doubled ? "COINS · DOUBLED" : "COINS EARNED", result.coins.formatted())
                }.padding(.vertical, 8)
                Divider().overlay(Color(uiColor: ArcadePalette.ink))
                NextUpgradeView()
                VStack(spacing: 10) {
                    Button("RETRY →") { session.start() }.buttonStyle(ArcadeButtonStyle())
                    if !result.continued {
                        Button("SIMULATED REWARD · CONTINUE +25%") { Task { await session.reward(.continueRun) } }
                            .buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: ArcadePalette.gold)))
                    }
                    if !result.doubled {
                        Button("SIMULATED REWARD · DOUBLE COINS") { Task { await session.reward(.doubleCoins) } }
                            .buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: ArcadePalette.gold)))
                    }
                    Button("UPGRADE SHOP") { session.shopOpen = true }.buttonStyle(ArcadeButtonStyle(fill: Color(uiColor: ArcadePalette.paper)))
                    Button("HOME") { session.home() }.font(ArcadeType.caption).padding(10)
                }.disabled(session.rewardBusy)
                Text("Progress saved on this iPhone. Rewards are simulated.").font(ArcadeType.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 520).frame(maxWidth: .infinity)
        }
    }
    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) { Text(label).font(ArcadeType.caption); Text(value).font(ArcadeType.title(28)).monospacedDigit() }
    }
}
