import SwiftUI

@main
struct BigHandApp: App {
    @StateObject private var session = GameSession()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(session)
                .preferredColorScheme(.light)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { session.enterBackground() }
                }
        }
    }
}
