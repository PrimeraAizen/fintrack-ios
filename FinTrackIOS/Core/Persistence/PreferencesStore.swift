import SwiftUI
import Observation

@Observable
final class PreferencesStore {
    private let defaults: UserDefaults

    var baseCurrency: String {
        didSet { defaults.set(baseCurrency, forKey: Keys.baseCurrency) }
    }

    var colorScheme: ColorScheme? {
        didSet { defaults.set(colorScheme.map(\.rawStorageValue), forKey: Keys.colorScheme) }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.baseCurrency = defaults.string(forKey: Keys.baseCurrency) ?? "USD"
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)

        if let raw = defaults.string(forKey: Keys.colorScheme) {
            self.colorScheme = ColorScheme(rawStorageValue: raw)
        } else {
            self.colorScheme = nil
        }
    }

    private enum Keys {
        static let baseCurrency         = "pref.baseCurrency"
        static let colorScheme          = "pref.colorScheme"
        static let hasCompletedOnboarding = "pref.hasCompletedOnboarding"
    }
}

private extension ColorScheme {
    var rawStorageValue: String {
        switch self {
        case .light: "light"
        case .dark:  "dark"
        @unknown default: "light"
        }
    }

    init?(rawStorageValue: String) {
        switch rawStorageValue {
        case "light": self = .light
        case "dark":  self = .dark
        default:      return nil
        }
    }
}
