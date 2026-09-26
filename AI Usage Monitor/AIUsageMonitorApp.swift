import SwiftUI
import AppKit

struct ConstrainedProviderQuota {
    let providerId: String
    let lowestRemainingPercentage: Double
}

@main
struct AIUsageMonitorApp: App {
    @StateObject private var manager = UsageManager(providers: [ClaudeCodeProvider()])
    @ObservedObject private var settings = ProviderSettings.shared

    private var mostConstrainedProviderQuota: ConstrainedProviderQuota? {
        let activeQuotas: [ConstrainedProviderQuota] = manager.usages.compactMap { usage in
            guard settings.isEnabled(id: usage.providerId),
                  let lowest = usage.lowestRemainingPercentage else {
                return nil
            }
            return ConstrainedProviderQuota(providerId: usage.providerId, lowestRemainingPercentage: lowest)
        }

        return activeQuotas.min(by: { $0.lowestRemainingPercentage < $1.lowestRemainingPercentage })
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(manager: manager)
        } label: {
            if let quota = mostConstrainedProviderQuota {
                let text = "\(Int(round(quota.lowestRemainingPercentage)))%"
                if quota.lowestRemainingPercentage <= 20.0 {
                    Image(nsImage: MenuBarIconHelper.warningItemImage(for: quota.providerId, text: text))
                } else {
                    HStack(spacing: 4) {
                        Image(nsImage: MenuBarIconHelper.icon(for: quota.providerId))
                        Text(text)
                            .font(.system(size: 12, weight: .medium))
                            .monospacedDigit()
                    }
                }
            } else {
                Image(nsImage: MenuBarIconHelper.defaultAIIcon)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

private enum MenuBarIconHelper {
    private static var iconCache: [String: NSImage] = [:]

    static func warningItemImage(for providerId: String, text: String) -> NSImage {
        let cacheKey = "\(providerId)_warning_\(text)"
        if let cached = iconCache[cacheKey] {
            return cached
        }

        let baseIcon = icon(for: providerId)
        let height: CGFloat = 22
        let iconSize = NSSize(width: 15, height: 14)
        let spacing: CGFloat = 4

        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let textAttrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: ThemeColors.warningYellowNS
        ]
        let str = NSAttributedString(string: text, attributes: textAttrs)
        let textSize = str.size()

        let totalWidth = iconSize.width + spacing + textSize.width
        let image = NSImage(size: NSSize(width: totalWidth, height: height))
        image.lockFocus()

        let iconY = (height - iconSize.height) / 2
        let iconRect = NSRect(x: 0, y: iconY, width: iconSize.width, height: iconSize.height)
        let tintedIcon = NSImage(size: iconSize, flipped: false) { rect in
            baseIcon.draw(in: rect)
            ThemeColors.warningYellowNS.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        tintedIcon.draw(in: iconRect)

        let textY = (height - textSize.height) / 2
        str.draw(at: NSPoint(x: iconSize.width + spacing, y: textY))

        image.unlockFocus()
        image.isTemplate = false

        iconCache[cacheKey] = image
        return image
    }

    static func icon(for providerId: String?) -> NSImage {
        guard let providerId = providerId else {
            return defaultAIIcon
        }

        if let cached = iconCache[providerId] {
            return cached
        }

        let generated = createIcon(for: providerId)
        iconCache[providerId] = generated
        return generated
    }

    private static func createIcon(for providerId: String) -> NSImage {
        switch providerId {
        case "claude-code":
            if let img = NSImage(named: "ClaudeIcon") {
                return makeTemplateIcon(from: img, targetSize: NSSize(width: 15, height: 14))
            }
        case "antigravity":
            if let img = NSImage(named: "AntigravityIcon") {
                return makeTemplateIcon(from: img, targetSize: NSSize(width: 14, height: 14))
            }
        case "gemini":
            if let img = NSImage(systemSymbolName: "sparkle", accessibilityDescription: "Gemini") {
                img.isTemplate = true
                return img
            }
        case "codex":
            if let img = NSImage(systemSymbolName: "chevron.left.forwardslash.chevron.right", accessibilityDescription: "Codex") {
                img.isTemplate = true
                return img
            }
        default:
            if let customImg = NSImage(named: "\(providerId)Icon") {
                return makeTemplateIcon(from: customImg, targetSize: NSSize(width: 14, height: 14))
            }
            if let img = NSImage(systemSymbolName: "cpu", accessibilityDescription: providerId) {
                img.isTemplate = true
                return img
            }
        }
        return defaultAIIcon
    }

    private static func makeTemplateIcon(from source: NSImage, targetSize: NSSize) -> NSImage {
        let image = NSImage(size: targetSize, flipped: false) { rect in
            source.draw(in: rect)
            return true
        }
        image.isTemplate = true
        return image
    }

    static let defaultAIIcon: NSImage = {
        let size = NSSize(width: 19, height: 15)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath(
                roundedRect: NSRect(x: 0.5, y: 0.5, width: rect.width - 1, height: rect.height - 1),
                xRadius: 3.5,
                yRadius: 3.5
            )
            path.lineWidth = 1.2
            NSColor.labelColor.setStroke()
            path.stroke()

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 8.5, weight: .bold),
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]
            let str = NSAttributedString(string: "AI", attributes: attrs)
            let strRect = NSRect(x: 0, y: 1.5, width: rect.width, height: 11)
            str.draw(in: strRect)
            return true
        }
        image.isTemplate = true
        return image
    }()
}
