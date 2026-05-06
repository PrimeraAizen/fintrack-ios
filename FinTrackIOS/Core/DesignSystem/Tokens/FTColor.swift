import SwiftUI

enum FTColor {
    // MARK: — Primary (DRD §3.1)
    static let primary     = Color(hex: 0x5B8A72)
    static let primarySoft = Color(hex: 0xE8F0EA)
    static let primaryDark = Color(hex: 0x3F6353)

    // MARK: — Neutrals — adaptive light / dark via Assets.xcassets
    static let bg            = Color("Background")
    static let surface       = Color("Surface")
    static let surfaceAlt    = Color("SurfaceAlt")
    static let border        = Color("Border")
    static let textPrimary   = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary  = Color("TextTertiary")

    // MARK: — Semantic
    static let income  = Color(hex: 0x5B8A72)   // same as primary; income is the positive default
    static let expense = Color("TextPrimary")    // expenses use primary text color, never red
    static let warning = Color(hex: 0xD4863A)    // amber — budget 80–100%
    static let danger  = Color(hex: 0xB85450)    // terracotta — over-budget, errors, destructive
    static let info    = Color(hex: 0x6E8CAE)    // soft blue — informational banners

    // MARK: — Category (auto-assigned in pickers and charts, DRD §3.1)
    static let catPeach   = Color(hex: 0xE8A87C)
    static let catMauve   = Color(hex: 0xC38D9E)
    static let catMint    = Color(hex: 0x85B79D)
    static let catMustard = Color(hex: 0xE8C547)
    static let catSlate   = Color(hex: 0xA8B4C9)
    static let catRose    = Color(hex: 0xD88C9A)
    static let catTeal    = Color(hex: 0x7A9E9F)
    static let catSand    = Color(hex: 0xB5A382)

    static let categoryPalette: [Color] = [
        catPeach, catMauve, catMint, catMustard, catSlate, catRose, catTeal, catSand,
    ]
}
