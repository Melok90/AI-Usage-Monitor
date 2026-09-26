import SwiftUI

struct SegmentedProgressBar: View {
    /// Used percentage from 0.0 to 100.0
    let value: Double
    var totalSegments: Int = 48
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 1.0
            let availableWidth = geometry.size.width
            let totalSpacing = spacing * CGFloat(totalSegments - 1)
            let segmentWidth = max(1.5, (availableWidth - totalSpacing) / CGFloat(totalSegments))

            let clampedValue = min(max(value, 0.0), 100.0)
            let activeCount = Int(round((clampedValue / 100.0) * Double(totalSegments)))

            HStack(spacing: spacing) {
                ForEach(0..<totalSegments, id: \.self) { index in
                    if index < activeCount {
                        // Used portion: solid bright white segment
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: segmentWidth, height: height)
                    } else {
                        // Remaining portion: dark stippled / dotted segment
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.06))
                                .frame(width: segmentWidth, height: height)

                            // 2x4 dot matrix matching reference
                            VStack(spacing: 0.8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    HStack(spacing: 0.8) {
                                        Circle()
                                            .fill(Color.white.opacity(0.38))
                                            .frame(width: 0.85, height: 0.85)
                                        Circle()
                                            .fill(Color.white.opacity(0.38))
                                            .frame(width: 0.85, height: 0.85)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(height: height)
    }
}
