import Foundation

enum RelativeTimeFormatter {

    /// Returns a human-readable relative string, e.g. "2h ago", "Yesterday", "May 3".
    static func string(from date: Date, relativeTo now: Date = .now) -> String {
        let diff = now.timeIntervalSince(date)

        switch diff {
        case ..<60:
            return "Just now"
        case 60..<3_600:
            let m = Int(diff / 60)
            return "\(m)m ago"
        case 3_600..<86_400:
            let h = Int(diff / 3_600)
            return "\(h)h ago"
        default:
            let cal = Calendar.current
            if cal.isDateInYesterday(date) { return "Yesterday" }
            if diff < 7 * 86_400 {
                let d = Int(diff / 86_400)
                return "\(d)d ago"
            }
            return DateFormatter.display.string(from: date)
        }
    }

    /// "Updated Xm ago" caption for exchange rate staleness.
    static func rateCaption(updatedAt: Date, now: Date = .now) -> String {
        let diff = now.timeIntervalSince(updatedAt)
        if diff < 60 { return "Rate just updated" }
        let m = Int(diff / 60)
        return "Rate updated \(m)m ago"
    }
}
