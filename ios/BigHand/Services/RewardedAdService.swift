import Foundation

enum RewardPlacement { case continueRun, doubleCoins, biggerStart }

@MainActor
protocol RewardedAdService {
    func request(_ placement: RewardPlacement) async -> Bool
}

@MainActor
final class SimulatedRewardedAdService: RewardedAdService {
    func request(_ placement: RewardPlacement) async -> Bool {
        // Deliberately no networking or SDK. Replace this implementation when integrating ads.
        await Task.yield()
        return !Task.isCancelled
    }
}
