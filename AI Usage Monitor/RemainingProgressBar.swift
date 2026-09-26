import SwiftUI

enum ThemeColors {
    static let warningYellow = Color(red: 246/255, green: 214/255, blue: 73/255)
    static let warningYellowNS = NSColor(red: 246/255, green: 214/255, blue: 73/255, alpha: 1.0)
}

/// A compact, dense segmented gauge displaying the REMAINING quota percentage.
struct RemainingProgressBar: View {
    /// Remaining percentage of quota (from 0.0 to 100.0)
    let remainingPercentage: Double
    var totalSegments: Int = 48
    var height: CGFloat = 8.5

    private var isWarning: Bool {
        remainingPercentage <= 20.0
    }

    private var activeColor: Color {
        isWarning ? ThemeColors.warningYellow : Color.white
    }

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 1.0
            let availableWidth = geometry.size.width
            let totalSpacing = spacing * CGFloat(totalSegments - 1)
            let segmentWidth = max(1.5, (availableWidth - totalSpacing) / CGFloat(totalSegments))

            let clamped = min(max(remainingPercentage, 0.0), 100.0)
            let activeCount = Int(round((clamped / 100.0) * Double(totalSegments)))

            HStack(spacing: spacing) {
                ForEach(0..<totalSegments, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                        .fill(index < activeCount ? activeColor : Color.white.opacity(0.15))
                        .frame(width: segmentWidth, height: height)
                }
            }
        }
        .frame(height: height)
    }
}
