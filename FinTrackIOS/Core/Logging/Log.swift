import OSLog

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "kz.diyas.fintrack"

    static let api   = Logger(subsystem: subsystem, category: "api")
    static let auth  = Logger(subsystem: subsystem, category: "auth")
    static let ui    = Logger(subsystem: subsystem, category: "ui")
    static let cache = Logger(subsystem: subsystem, category: "cache")
}
