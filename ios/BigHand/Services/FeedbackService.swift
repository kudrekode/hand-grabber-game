import UIKit
import AVFoundation

enum FeedbackCue: String, CaseIterable { case crush, largeCrush, gate, shrink, coin, fail, upgrade, highScore }

@MainActor
final class SoundService {
    var enabled = false
    private var players: [AVAudioPlayer] = []
    func play(_ cue: FeedbackCue) {
        guard enabled, let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds") else { return }
        players.removeAll { !$0.isPlaying }
        guard players.count < 8, let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.volume = cue == .coin ? 0.4 : 0.7
        player.prepareToPlay(); player.play(); players.append(player)
    }
    func activate() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    func stop() { players.forEach { $0.stop() }; players.removeAll() }
}

@MainActor
final class HapticService {
    var enabled = true
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    func prepare() { light.prepare(); medium.prepare(); heavy.prepare(); notification.prepare() }
    func crush(size: Double) {
        guard enabled else { return }
        if size < 22 { light.impactOccurred(intensity: 0.4) }
        else if size < 70 { medium.impactOccurred(intensity: 0.7) }
        else { heavy.impactOccurred(intensity: min(1, 0.6 + size / 900)) }
        prepare()
    }
    func play(_ cue: FeedbackCue) {
        guard enabled else { return }
        switch cue {
        case .fail: notification.notificationOccurred(.error)
        case .highScore, .upgrade: notification.notificationOccurred(.success)
        case .gate: medium.impactOccurred(intensity: 0.85)
        case .shrink: notification.notificationOccurred(.warning)
        case .coin: light.impactOccurred(intensity: 0.25)
        case .crush: light.impactOccurred(intensity: 0.4)
        case .largeCrush: heavy.impactOccurred()
        }
        prepare()
    }
}

@MainActor
final class FeedbackService {
    let sound = SoundService()
    let haptics = HapticService()
    func crush(size: Double) { sound.play(size >= 70 ? .largeCrush : .crush); haptics.crush(size: size) }
    func play(_ cue: FeedbackCue) { sound.play(cue); haptics.play(cue) }
}
