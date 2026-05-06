import CoreFoundation

// Corner radius scale (DRD §3.4). No radius below 8pt anywhere in the app.
enum FTRadius {
    static let sm:   CGFloat = 8    // chips, small tags
    static let md:   CGFloat = 12   // inputs, secondary buttons
    static let lg:   CGFloat = 16   // cards, list rows, primary buttons
    static let xl:   CGFloat = 24   // modal sheets, large hero cards
    static let full: CGFloat = 999  // avatars, FAB, pill buttons
}
