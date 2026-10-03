import UIKit
import AVFoundation

enum FeedbackCue: String, CaseIterable, Sendable { case crush, mediumCrush, largeCrush, metalCrush, gate, shrink, coin, fail, upgrade, highScore }
struct ImpactProfile: Equatable, Sendable {
    let weight: Double
    let contactDelay: Double
    let hold: Double
    let shake: Double
    let particles: Int
    let cue: FeedbackCue
    init(size: Double) {
        weight = CollisionSystem.impact(size)
        contactDelay = size < 22 ? 0.045 : size < 70 ? 0.065 : 0.085
        hold = size < 22 ? 0.035 : size < 180 ? 0.065 : 0.095
        shake = size < 22 ? 0 : size < 70 ? 2 : size < 180 ? 4 : 7
        particles = size < 22 ? 7 : size < 70 ? 12 : size < 180 ? 17 : 24
        cue = size < 22 ? .crush : size < 70 ? .mediumCrush : size < 180 ? .largeCrush : .metalCrush
    }
}


@MainActor
final class SoundService {
    var enabled = false
    private var players: [FeedbackCue: [AVAudioPlayer]] = [:]
    private var lastPlay: [FeedbackCue: TimeInterval] = [:]
    func play(_ cue: FeedbackCue) {
        guard enabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - (lastPlay[cue] ?? -1) > (cue == .coin ? 0.08 : 0.045) else { return }
        if players[cue] == nil {
            guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Sounds") else { return }
            players[cue] = (0..<2).compactMap { _ in
                let player = try? AVAudioPlayer(contentsOf: url); player?.prepareToPlay(); return player
            }
        }
        guard players.values.flatMap({ $0 }).filter({ $0.isPlaying }).count < 6 else { return }
        guard let player = players[cue]?.first(where: { !$0.isPlaying }) else { return }
        lastPlay[cue] = now
        player.currentTime = 0; player.volume = cue == .coin ? 0.30 : cue == .metalCrush ? 0.8 : 0.6
        player.rate = Float.random(in: 0.96...1.04); player.enableRate = true; player.play()
    }
    func activate() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    func stop() { players.values.flatMap { $0 }.forEach { $0.stop() }; lastPlay.removeAll() }
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
        else if size < 180 { heavy.impactOccurred(intensity: 0.8) }
        else { heavy.impactOccurred(intensity: 1) }
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
        case .mediumCrush: medium.impactOccurred(intensity: 0.7)
        case .largeCrush, .metalCrush: heavy.impactOccurred()
        }
        prepare()
    }
}

@MainActor
final class FeedbackService {
    let sound = SoundService()
    let haptics = HapticService()
    func crush(size: Double) { sound.play(ImpactProfile(size: size).cue); haptics.crush(size: size) }
    func play(_ cue: FeedbackCue) { sound.play(cue); haptics.play(cue) }
}
