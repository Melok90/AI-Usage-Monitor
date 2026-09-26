import Foundation

struct UsageInfo: Sendable, Equatable {
    let providerId: String
    let serviceName: String
    let quotas: [QuotaInfo]

    var lowestRemainingPercentage: Double? {
        quotas.map(\.remainingPercentage).min()
    }

    init(providerId: String = "claude-code", serviceName: String, quotas: [QuotaInfo]) {
        self.providerId = providerId
        self.serviceName = serviceName
        self.quotas = quotas
    }
}
