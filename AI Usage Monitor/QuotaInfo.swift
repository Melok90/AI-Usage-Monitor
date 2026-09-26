import Foundation

struct QuotaInfo: Identifiable, Sendable, Equatable {
    let id: String
    let name: String
    let remainingPercentage: Double
    let resetDate: Date?

    init(id: String = UUID().uuidString, name: String, remainingPercentage: Double, resetDate: Date? = nil) {
        self.id = id
        self.name = name
        self.remainingPercentage = min(max(remainingPercentage, 0.0), 100.0)
        self.resetDate = resetDate
    }
}
