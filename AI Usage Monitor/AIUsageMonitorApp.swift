import SwiftUI
import AppKit

@main
struct AIUsageMonitorApp: App {
    @StateObject private var manager = UsageManager(providers: [ClaudeCodeProvider()])
    @ObservedObject private var settings = ProviderSettings.shared

    private var activeLowestPercentage: Double? {
        let enabledUsages = manager.usages.filter { usage in
            settings.isEnabled(id: usage.providerId)
        }
        return enabledUsages.compactMap(\.lowestRemainingPercentage).min()
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(manager: manager)
        } label: {
            HStack(spacing: 4) {
                Image(nsImage: StatusIconHelper.icon)

                if let lowest = activeLowestPercentage {
                    Text("\(Int(round(lowest)))%")
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

private enum StatusIconHelper {
    static let icon: NSImage = {
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
