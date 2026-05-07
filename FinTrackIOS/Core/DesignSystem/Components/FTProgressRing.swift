import SwiftUI

struct FTProgressRing: View {
    let value: Decimal
    let total: Decimal
    var lineWidth: CGFloat = 8

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: value / total).doubleValue.clamped(to: 0...1)
    }

    private var ringColor: Color {
        if fraction >= 1.0 { return FTColor.danger }
        if fraction >= 0.8 { return FTColor.warning }
        return FTColor.primary
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(FTColor.primarySoft, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: fraction)
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    HStack(spacing: FTSpacing.s6) {
        FTProgressRing(value: 40, total: 100).frame(width: 64, height: 64)
        FTProgressRing(value: 85, total: 100).frame(width: 64, height: 64)
        FTProgressRing(value: 110, total: 100).frame(width: 64, height: 64)
    }
    .padding()
}
