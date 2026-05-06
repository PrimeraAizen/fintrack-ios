import CoreFoundation

// 4-pt spacing grid (DRD §3.3). Use these tokens exclusively — no arbitrary spacing.
enum FTSpacing {
    static let s1:  CGFloat = 4
    static let s2:  CGFloat = 8
    static let s3:  CGFloat = 12
    static let s4:  CGFloat = 16   // default screen horizontal padding
    static let s5:  CGFloat = 20
    static let s6:  CGFloat = 24   // vertical rhythm between sections
    static let s8:  CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
    static let s16: CGFloat = 64
}
