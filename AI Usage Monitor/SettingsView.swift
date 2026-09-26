import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: ProviderSettings = .shared
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack(alignment: .center, spacing: 8) {
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .frame(width: 16, height: 16, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)

                Spacer()
            }
            .padding(.bottom, 8)

            // MARK: - Divider
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.75)
                .padding(.bottom, 12)

            // MARK: - Agents Section
            Text("Agents")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.45))
                .padding(.bottom, 8)

            // MARK: - Agents List
            VStack(spacing: 0) {
                ForEach(settings.configurations) { config in
                    HStack(alignment: .center, spacing: 7) {
                        AgentIconView(agentId: config.id)

                        Text(config.displayName)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.white)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { config.isEnabled },
                            set: { newValue in
                                settings.setEnabled(id: config.id, isEnabled: newValue)
                            }
                        ))
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)

                    if config.id != settings.configurations.last?.id {
                        Rectangle()
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 0.5)
                            .padding(.vertical, 3)
                    }
                }
            }
        }
    }
}

struct AgentIconView: View {
    let agentId: String

    var body: some View {
        Group {
            if let image = NSImage(named: assetName(for: agentId)) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else if agentId == "gemini" {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
            } else if agentId == "codex" {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
            } else {
                Image(systemName: "cpu")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
        }
        .frame(width: 14, height: 14)
    }

    private func assetName(for agentId: String) -> String {
        switch agentId {
        case "claude-code": return "ClaudeIcon"
        case "antigravity": return "AntigravityIcon"
        case "gemini": return "GeminiIcon"
        case "codex": return "CodexIcon"
        default: return ""
        }
    }
}
