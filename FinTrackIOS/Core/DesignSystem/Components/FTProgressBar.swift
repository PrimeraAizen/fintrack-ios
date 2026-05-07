import SwiftUI

struct FTProgressBar: View {
    let value: Decimal
    let total: Decimal

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return NSDecimalNumber(decimal: value / total).doubleValue.clamped(to: 0...1)
    }

    private var barColor: Color {
        if fraction >= 1.0 { return FTColor.danger }
        if fraction >= 0.8 { return FTColor.warning }
        return FTColor.primary
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FTColor.primarySoft)
                    .frame(height: 6)

                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width * fraction, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: fraction)
            }
        }
        .frame(height: 6)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    VStack(spacing: FTSpacing.s4) {
        FTProgressBar(value: 40, total: 100)
        FTProgressBar(value: 85, total: 100)
        FTProgressBar(value: 110, total: 100)
    }
    .padding()
}
