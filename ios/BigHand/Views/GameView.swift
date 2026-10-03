import SwiftUI
import SpriteKit

struct GameView: View {
    @EnvironmentObject private var session: GameSession
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: session.scene, preferredFramesPerSecond: 120)
                .onAppear { session.scene.resize(viewSize: geometry.size) }
                .onChange(of: geometry.size) { _, size in session.scene.resize(viewSize: size) }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("gameTrack")
                .accessibilityValue("Size \(Int(session.snapshot.size)); position \(Int(session.snapshot.x)); crushed \(session.snapshot.objectScore)")
                .accessibilityLabel("Game track. Drag horizontally to move your hand.")
                .overlay(alignment: .top) {
                    HStack(alignment: .top) {
                        metric("SCORE", value: session.snapshot.score.formatted())
                        Spacer(minLength: 6)
                        VStack(alignment: .trailing, spacing: 4) {
                            metric("COINS", value: session.runCoins.formatted())

                        }
                        Button { session.setPaused(true) } label: {
                            Image(systemName: "pause.fill").font(.system(size: 18, weight: .black)).frame(width: 44, height: 44)
                        }.foregroundStyle(Color(uiColor: ArcadePalette.ink)).background(Color(uiColor: ArcadePalette.paper), in: RoundedRectangle(cornerRadius: 9))
                            .accessibilityLabel("Pause game")
                    }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 15)
                        .background(Color(uiColor: ArcadePalette.paper))
                }
                .overlay {
                    if session.paused {
                        VStack(spacing: 18) {
                            Text("TAKE A BREATHER.").font(ArcadeType.title(28))
                            FeedbackToggles()
                            Button("BACK TO CRUSHING →") { session.setPaused(false) }.buttonStyle(ArcadeButtonStyle())
                        }.modifier(ArcadePanel()).padding(DesignSystem.inset).frame(maxWidth: 450)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(uiColor: ArcadePalette.track).opacity(0.85))
                    }
                }
        }.persistentSystemOverlays(.hidden)
    }
    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(ArcadeType.caption)
            Text(value).font(ArcadeType.title(25)).monospacedDigit()
        }
    }
}
