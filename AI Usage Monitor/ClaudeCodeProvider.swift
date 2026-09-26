import Foundation

struct ClaudeCodeProvider: UsageProvider {
    let id: String = "claude-code"

    enum ProviderError: LocalizedError {
        case noDataAvailable
        case parseError(String)

        var errorDescription: String? {
            switch self {
            case .noDataAvailable:
                return "No Claude Code usage data found on this device."
            case .parseError(let msg):
                return "Failed to parse Claude Code data: \(msg)"
            }
        }
    }

    func fetchUsage() async throws -> UsageInfo {
        // 1. Попытка прочитать оперативный снимок rate_limits.json (если записан активной сессией Claude Code)
        if let liveQuotas = tryFetchLiveRateLimits() {
            return UsageInfo(providerId: id, serviceName: "Claude Code", quotas: liveQuotas)
        }

        // 2. Чтение данных из локального хранилища Claude на Mac (~/Library/Application Support/Claude/plan-usage-history.json)
        if let historyQuotas = tryFetchPlanUsageHistory() {
            return UsageInfo(providerId: id, serviceName: "Claude Code", quotas: historyQuotas)
        }

        throw ProviderError.noDataAvailable
    }

    private func tryFetchLiveRateLimits() -> [QuotaInfo]? {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let candidatePaths = [
            homeDir.appendingPathComponent(".claude/rate_limits.json"),
            homeDir.appendingPathComponent(".claude/current_usage.json")
        ]

        for path in candidatePaths {
            guard fileManager.fileExists(atPath: path.path),
                  let data = try? Data(contentsOf: path) else { continue }

            if let quotas = parseLiveRateLimits(data: data), !quotas.isEmpty {
                return quotas
            }
        }
        return nil
    }

    private func parseLiveRateLimits(data: Data) -> [QuotaInfo]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let rootLimits = (json["rate_limits"] as? [String: Any]) ?? json
        var result: [QuotaInfo] = []

        // 1. 5h Session
        if let fh = rootLimits["five_hour"] as? [String: Any] {
            let usedPct = (fh["used_percentage"] as? Double)
                ?? (fh["utilization"] as? Double)
            if let used = usedPct {
                let remaining = max(0.0, min(100.0, 100.0 - used))
                var resetDate: Date? = nil
                if let resetSec = (fh["resets_at"] as? Double) ?? (fh["resets_at"] as? Int).map(Double.init) {
                    resetDate = Date(timeIntervalSince1970: resetSec)
                } else if let resetStr = fh["resets_at"] as? String {
                    resetDate = ISO8601DateFormatter().date(from: resetStr)
                }
                result.append(
                    QuotaInfo(
                        id: "claude-5h",
                        name: "5h Session",
                        remainingPercentage: remaining,
                        resetDate: resetDate
                    )
                )
            }
        }

        // 2. 7d Usage
        if let sd = rootLimits["seven_day"] as? [String: Any] {
            let usedPct = (sd["used_percentage"] as? Double)
                ?? (sd["utilization"] as? Double)
            if let used = usedPct {
                let remaining = max(0.0, min(100.0, 100.0 - used))
                var resetDate: Date? = nil
                if let resetSec = (sd["resets_at"] as? Double) ?? (sd["resets_at"] as? Int).map(Double.init) {
                    resetDate = Date(timeIntervalSince1970: resetSec)
                } else if let resetStr = sd["resets_at"] as? String {
                    resetDate = ISO8601DateFormatter().date(from: resetStr)
                }
                result.append(
                    QuotaInfo(
                        id: "claude-7d",
                        name: "7d Usage",
                        remainingPercentage: remaining,
                        resetDate: resetDate
                    )
                )
            }
        }

        return result.isEmpty ? nil : result
    }

    private func tryFetchPlanUsageHistory() -> [QuotaInfo]? {
        let fileManager = FileManager.default
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let historyPath = homeDir.appendingPathComponent("Library/Application Support/Claude/plan-usage-history.json")

        guard fileManager.fileExists(atPath: historyPath.path),
              let data = try? Data(contentsOf: historyPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let samples = json["samples"] as? [[String: Any]] else {
            return nil
        }

        // Поиск последнего среза с заполненным объектом 'u'
        for sample in samples.reversed() {
            guard let u = sample["u"] as? [String: Any], !u.isEmpty else { continue }

            var quotas: [QuotaInfo] = []

            // 1. 5h Session
            if let fhUsed = (u["fh"] as? Double) ?? (u["fh"] as? Int).map(Double.init) {
                let remaining = max(0.0, min(100.0, 100.0 - fhUsed))
                let resetDate = calculateRollingResetDate(windowHours: 5)
                quotas.append(
                    QuotaInfo(
                        id: "claude-5h",
                        name: "5h session",
                        remainingPercentage: remaining,
                        resetDate: resetDate
                    )
                )
            }

            // 2. 7d Usage
            if let sdUsed = (u["sd"] as? Double) ?? (u["sd"] as? Int).map(Double.init) {
                let remaining = max(0.0, min(100.0, 100.0 - sdUsed))
                let resetDate = calculateRollingResetDate(windowHours: 7 * 24)
                quotas.append(
                    QuotaInfo(
                        id: "claude-7d",
                        name: "7d usage",
                        remainingPercentage: remaining,
                        resetDate: resetDate
                    )
                )
            }

            if !quotas.isEmpty {
                return quotas
            }
        }

        return nil
    }

    private func calculateRollingResetDate(windowHours: Int) -> Date {
        let calendar = Calendar.current
        let now = Date()
        if windowHours == 5 {
            // Расчёт времени до окончания 5-часового скользящего окна
            let currentHour = calendar.component(.hour, from: now)
            let nextBoundaryHour = ((currentHour / 5) + 1) * 5
            let hoursRemaining = nextBoundaryHour - currentHour
            let minutesRemaining = 60 - calendar.component(.minute, from: now)
            let totalSeconds = max(60, (hoursRemaining - 1) * 3600 + minutesRemaining * 60)
            return now.addingTimeInterval(TimeInterval(totalSeconds))
        } else {
            // Расчёт времени до окончания 7-дневного окна
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilEnd = (8 - weekday) % 7 + 1
            let hoursRemaining = 24 - calendar.component(.hour, from: now)
            let totalSeconds = max(3600, daysUntilEnd * 86400 + hoursRemaining * 3600)
            return now.addingTimeInterval(TimeInterval(totalSeconds))
        }
    }
}
