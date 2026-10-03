import Foundation

final class SaveService {
    static let key = "big-hand-native-save-v1"
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func load() -> SaveData {
        guard let data = defaults.data(forKey: Self.key), let save = try? JSONDecoder().decode(SaveData.self, from: data) else { return SaveData() }
        return save
    }
    func write(_ save: SaveData) {
        guard let data = try? JSONEncoder().encode(save) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
