import Foundation

protocol UsageProvider: Sendable {
    var id: String { get }
    func fetchUsage() async throws -> UsageInfo
}
