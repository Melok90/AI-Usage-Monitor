import Foundation
import Combine

struct ProviderConfiguration: Identifiable, Equatable {
    let id: String
    let displayName: String
    var isEnabled: Bool
}

@MainActor
final class ProviderSettings: ObservableObject {
    static let shared = ProviderSettings()

    static let defaultConfigurations: [ProviderConfiguration] = [
        ProviderConfiguration(id: "claude-code", displayName: "Claude Code", isEnabled: true),
        ProviderConfiguration(id: "antigravity", displayName: "Antigravity", isEnabled: false),
        ProviderConfiguration(id: "gemini", displayName: "Gemini", isEnabled: false),
        ProviderConfiguration(id: "codex", displayName: "Codex", isEnabled: false)
    ]

    @Published var configurations: [ProviderConfiguration] = []

    init() {
        load()
    }

    func isEnabled(id: String) -> Bool {
        configurations.first(where: { $0.id == id })?.isEnabled ?? false
    }

    func toggle(id: String) {
        guard let index = configurations.firstIndex(where: { $0.id == id }) else { return }
        configurations[index].isEnabled.toggle()
        save()
    }

    func setEnabled(id: String, isEnabled: Bool) {
        guard let index = configurations.firstIndex(where: { $0.id == id }) else { return }
        configurations[index].isEnabled = isEnabled
        save()
    }

    private func load() {
        configurations = Self.defaultConfigurations.map { def in
            let key = "provider_enabled_\(def.id)"
            if UserDefaults.standard.object(forKey: key) != nil {
                let saved = UserDefaults.standard.bool(forKey: key)
                return ProviderConfiguration(id: def.id, displayName: def.displayName, isEnabled: saved)
            } else {
                return def
            }
        }
    }

    private func save() {
        for config in configurations {
            UserDefaults.standard.set(config.isEnabled, forKey: "provider_enabled_\(config.id)")
        }
    }
}
