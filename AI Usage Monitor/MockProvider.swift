import Foundation

struct MockProvider: UsageProvider {
    let id: String = "antigravity"

    func fetchUsage() async throws -> UsageInfo {
        UsageInfo(
            serviceName: "Antigravity",
            quotas: [
                QuotaInfo(
                    id: "gemini-flash",
                    name: "Gemini Flash",
                    remainingPercentage: 58.0,
                    resetDate: Date().addingTimeInterval(1 * 3600 + 32 * 60)
                ),
                QuotaInfo(
                    id: "gemini-pro",
                    name: "Gemini Pro",
                    remainingPercentage: 37.0,
                    resetDate: Date().addingTimeInterval(4 * 3600 + 15 * 60)
                ),
                QuotaInfo(
                    id: "claude-models",
                    name: "Claude Models",
                    remainingPercentage: 75.0,
                    resetDate: Date().addingTimeInterval(6 * 3600)
                )
            ]
        )
    }
}
