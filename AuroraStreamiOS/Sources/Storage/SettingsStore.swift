import Foundation
import Combine

struct AppSettings: Codable, Equatable {
    var repo: String = ""
    var branch: String = "main"
    var token: String = ""
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings = AppSettings()

    private let defaults = UserDefaults.standard
    private let key = "aurora_settings_v1"

    init() {
        load()
    }

    func load() {
        if let data = defaults.data(forKey: key), let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }

    func updateRepo(_ raw: String) {
        settings.repo = raw
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "https://github.com/", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        save()
    }
}
