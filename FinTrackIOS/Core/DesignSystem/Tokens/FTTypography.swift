import SwiftUI

// Typography scale using SF Pro (DRD §3.2).
// SF Pro Rounded is used for display and numeric tokens to reinforce the warm tone.
// All numeric tokens apply .monospacedDigit() to prevent amount jitter.
enum FTTypography {
    // Display
    static let displayXL = Font.system(size: 48, weight: .semibold, design: .rounded)   // hero balance
    static let displayLG = Font.system(size: 34, weight: .semibold, design: .rounded)   // screen-level totals

    // Headings
    static let headingLG = Font.system(size: 22, weight: .semibold)                     // section titles
    static let headingMD = Font.system(size: 17, weight: .semibold)                     // card titles, list group headers

    // Body
    static let bodyLG = Font.system(size: 17, weight: .regular)                         // default body
    static let bodyMD = Font.system(size: 15, weight: .regular)                         // secondary body, list items
    static let bodySM = Font.system(size: 13, weight: .regular)                         // metadata, captions

    // Label
    static let label = Font.system(size: 13, weight: .medium)                           // form labels, chip text

    // Numeric — monospaced digits prevent layout jitter when amounts update
    static let numericLG = Font.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit()
    static let numericMD = Font.system(size: 17, weight: .medium,   design: .rounded).monospacedDigit()
}
