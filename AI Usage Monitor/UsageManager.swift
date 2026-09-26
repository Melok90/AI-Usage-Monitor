import Foundation
import Combine

@MainActor
final class UsageManager: ObservableObject {
    private let providers: [any UsageProvider]
    @Published var usages: [UsageInfo] = []
    @Published var isRefreshing: Bool = false
    @Published var lastUpdated: Date? = nil
    @Published var lastError: String? = nil

    init(providers: [any UsageProvider] = []) {
        self.providers = providers
        Task { [weak self] in
            await self?.fetchAllUsage()
        }
    }

    func fetchAllUsage() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        var fetched: [UsageInfo] = []
        var latestError: Error? = nil

        for provider in providers {
            do {
                let info = try await provider.fetchUsage()
                fetched.append(info)
            } catch {
                latestError = error
                continue
            }
        }

        if !fetched.isEmpty {
            self.usages = fetched
            self.lastUpdated = Date()
            self.lastError = nil
        } else if let error = latestError {
            self.lastError = error.localizedDescription
        }
    }
}
