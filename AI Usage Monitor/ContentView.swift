import SwiftUI
import Combine

struct ContentView: View {
    @ObservedObject var manager: UsageManager

    @ObservedObject var settings: ProviderSettings = .shared

    init(manager: UsageManager) {
        self.manager = manager
    }

    @State private var isShowingSettings: Bool = false
    @State private var currentDate = Date()

    private let secondTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let autoRefreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var quota5h: QuotaInfo? {
        manager.usages.first?.quotas.first(where: { $0.id == "claude-5h" || $0.name.contains("5h") })
            ?? manager.usages.first?.quotas.first
    }

    private var quota7d: QuotaInfo? {
        manager.usages.first?.quotas.first(where: { $0.id == "claude-7d" || $0.name.contains("7d") })
            ?? (manager.usages.first?.quotas.count ?? 0 > 1 ? manager.usages.first?.quotas[1] : nil)
    }

    private var isClaudeEnabled: Bool {
        settings.isEnabled(id: "claude-code")
    }

    private var otherEnabledConfigs: [ProviderConfiguration] {
        settings.configurations.filter { $0.id != "claude-code" && $0.isEnabled }
    }

    private var hasAnyEnabledAgents: Bool {
        isClaudeEnabled || !otherEnabledConfigs.isEmpty
    }

    var body: some View {
        Group {
            if isShowingSettings {
                SettingsView {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowingSettings = false
                    }
                }
            } else {
                mainContentView
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(width: 276)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            await manager.fetchAllUsage()
        }
        .onReceive(secondTimer) { date in
            currentDate = date
        }
        .onReceive(autoRefreshTimer) { _ in
            Task {
                await manager.fetchAllUsage()
            }
        }
    }

    private var mainContentView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack(alignment: .center, spacing: 7) {
                if isClaudeEnabled {
                    AgentIconView(agentId: "claude-code")

                    Text("Claude Code")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                } else {
                    Text("AI Usage Monitor")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white)
                }

                Spacer()

                if isClaudeEnabled {
                    // Refresh button
                    Button {
                        Task {
                            await manager.fetchAllUsage()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.65))
                            .rotationEffect(.degrees(manager.isRefreshing ? 360 : 0))
                            .animation(
                                manager.isRefreshing
                                    ? .linear(duration: 0.8).repeatForever(autoreverses: false)
                                    : .default,
                                value: manager.isRefreshing
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(manager.isRefreshing)
                    .help("Refresh · \(formattedLastUpdated())")
                }

                // Settings button
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowingSettings = true
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help("Settings")
            }
            .padding(.bottom, 8)

            // MARK: - Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.75)
                .padding(.bottom, 11)

            if !hasAnyEnabledAgents {
                VStack(spacing: 6) {
                    Text("No active agents")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("Enable agents in Settings")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                if isClaudeEnabled {
                    claudeQuotasView
                }

                ForEach(otherEnabledConfigs) { config in
                    if isClaudeEnabled {
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 0.75)
                            .padding(.vertical, 10)
                    }

                    HStack(alignment: .center, spacing: 7) {
                        AgentIconView(agentId: config.id)

                        Text(config.displayName)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.white)

                        Spacer()

                        Text("Not available")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var claudeQuotasView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - 5h Session Quota
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundStyle(Color.white)

                        Text("5h session")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    if let quota = quota5h {
                        HStack(spacing: 4) {
                            Text("\(Int(round(quota.remainingPercentage)))%")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white)

                            if let countdown = formattedCountdown(from: quota.resetDate) {
                                Text("·")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.4))

                                Text("\(countdown) left")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.65))
                            }
                        }
                    } else {
                        Text("No data")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                if let quota = quota5h {
                    RemainingProgressBar(remainingPercentage: quota.remainingPercentage, totalSegments: 48, height: 8.5)
                }
            }
            .padding(.bottom, 13)

            // MARK: - 7d Usage Quota
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundStyle(Color.white)

                        Text("7d usage")
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    if let quota = quota7d {
                        HStack(spacing: 4) {
                            Text("\(Int(round(quota.remainingPercentage)))%")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white)

                            if let countdown = formattedCountdown(from: quota.resetDate) {
                                Text("·")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.4))

                                Text("\(countdown) left")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.65))
                            }
                        }
                    } else {
                        Text("No data")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                if let quota = quota7d {
                    RemainingProgressBar(remainingPercentage: quota.remainingPercentage, totalSegments: 48, height: 8.5)
                }
            }
        }
    }

    private func formattedLastUpdated() -> String {
        guard let last = manager.lastUpdated else { return "Not updated" }
        let seconds = max(0, Int(currentDate.timeIntervalSince(last)))
        if seconds < 60 {
            return "Updated just now"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "Updated \(minutes)m ago"
        }
        let hours = minutes / 60
        return "Updated \(hours)h ago"
    }

    private func formattedCountdown(from date: Date?) -> String? {
        guard let date = date else { return nil }
        let interval = date.timeIntervalSince(currentDate)
        if interval <= 0 {
            return "0m"
        }
        let totalMinutes = Int((interval + 30) / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours >= 24 {
            let days = hours / 24
            let remHours = hours % 24
            return "\(days)d \(remHours)h"
        } else if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else {
            return "\(minutes)m"
        }
    }
}
