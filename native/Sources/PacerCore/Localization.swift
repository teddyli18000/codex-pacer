import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    public var locale: Locale {
        let region = Locale.current.region?.identifier
        return Locale(identifier: region.map { rawValue + "_" + $0 } ?? rawValue)
    }
}

public enum LanguagePreference: String, CaseIterable, Sendable {
    case system
    case simplifiedChinese = "zh-Hans"
    case english = "en"

    public static let defaultsKey = "appLanguage"
    public static func load(from defaults: UserDefaults = .standard) -> Self {
        defaults.string(forKey: defaultsKey).flatMap(Self.init(rawValue:)) ?? .system
    }
    public func resolved(preferredLanguages: [String] = Self.systemLanguages()) -> AppLanguage {
        switch self {
        case .english: return .english
        case .simplifiedChinese: return .simplifiedChinese
        case .system:
            for identifier in preferredLanguages {
                let language = identifier.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-").first
                if language == "zh" { return .simplifiedChinese }
                if language == "en" { return .english }
            }
            return .english
        }
    }
    public static func systemLanguages(defaults: UserDefaults = .standard) -> [String] {
        // Ignore this app's explicit override when the user chooses Follow macOS.
        defaults.persistentDomain(forName: UserDefaults.globalDomain)?["AppleLanguages"] as? [String]
            ?? Locale.preferredLanguages
    }
    public func save(to defaults: UserDefaults = .standard) {
        defaults.set(rawValue, forKey: Self.defaultsKey)
        // This is the application's preferences domain, never NSGlobalDomain.
        // Relaunch lets AppKit, open panels and Sparkle use the same language.
        if self == .system { defaults.removeObject(forKey: "AppleLanguages") }
        else { defaults.set([rawValue], forKey: "AppleLanguages") }
    }
    public var label: String {
        switch self {
        case .system: return L10n.text("language.system")
        case .simplifiedChinese: return "简体中文"
        case .english: return "English"
        }
    }
}

public enum DisplayTimeZone {
    public static let defaultsKey = "displayTimeZone"
    public static func resolve(_ selected: String?, system: TimeZone = Calendar.current.timeZone) -> TimeZone {
        selected.flatMap(TimeZone.init(identifier:)) ?? system
    }
    public static var current: TimeZone {
        resolve(UserDefaults.standard.string(forKey: defaultsKey))
    }
}

public enum L10n {
    /// A language is fixed for one launch, including stored notices and errors.
    public static let language = LanguagePreference.load().resolved()
    public static var locale: Locale { language.locale }

    public static let sharedResourceBundle: Bundle = Bundle.module
    private final class Snapshot: @unchecked Sendable {
        let bundle: Bundle
        let catalog: BundleLocalizationCatalog
        let resources: LocalizationResources
        init(bundle: Bundle, platform: (any LocalizationCatalog)? = nil) {
            self.bundle = bundle
            catalog = BundleLocalizationCatalog(bundle: bundle)
            resources = LocalizationResources(shared: catalog, platform: platform)
        }
    }
    private final class ResourceState: @unchecked Sendable {
        let lock = NSLock()
        var snapshot: Snapshot?
    }
    private static let state = ResourceState()
    private static var current: Snapshot {
        state.lock.lock(); defer { state.lock.unlock() }
        if let snapshot = state.snapshot { return snapshot }
        let snapshot = Snapshot(bundle: sharedResourceBundle)
        state.snapshot = snapshot
        return snapshot
    }
    /// Hosts configure packaged resources before creating clients or views.
    public static func configureResources(bundle: Bundle, platform: (any LocalizationCatalog)? = nil) {
        let snapshot = Snapshot(bundle: bundle, platform: platform)
        state.lock.lock(); state.snapshot = snapshot; state.lock.unlock()
    }
    public static var resourceBundle: Bundle { current.bundle }
    static func localizationResourceURL(for language: AppLanguage) -> URL? { current.catalog.resourceURL(for: language) }

    public static func text(_ key: String, _ arguments: CVarArg..., language selected: AppLanguage? = nil) -> String {
        current.resources.text(key, arguments: arguments, language: selected ?? language)
    }
    /// The same text with arguments gathered at run time.
    public static func text(_ key: String, arguments: [CVarArg], language selected: AppLanguage? = nil) -> String {
        current.resources.text(key, arguments: arguments, language: selected ?? language)
    }

    /// The user's time zone, which local days and date text use. On the Mac it
    /// is the system zone. On Windows, Foundation's `TimeZone.current` stays GMT;
    /// the engine sets the host's zone as `NSTimeZone.default`, which
    /// `Calendar.current` follows.
    public static var timeZone: TimeZone { DisplayTimeZone.current }

    /// Date text in `calendar`'s calendar and zone, in the app's locale unless
    /// another is given. Core formats dates only here: a `Date.FormatStyle`'s
    /// own default zone is GMT on Windows, even after the engine sets the host's.
    public static func format(_ value: Date, _ style: Date.FormatStyle, calendar: Calendar? = nil,
                              locale: Locale? = nil) -> String {
        var selectedCalendar = calendar ?? .current
        if calendar == nil { selectedCalendar.timeZone = DisplayTimeZone.current }
        var style = style.locale(locale ?? Self.locale)
        style.calendar = selectedCalendar
        style.timeZone = selectedCalendar.timeZone
        return value.formatted(style)
    }

    public static func date(_ value: Date, date dateStyle: Date.FormatStyle.DateStyle = .abbreviated,
                            time timeStyle: Date.FormatStyle.TimeStyle = .shortened, calendar: Calendar? = nil) -> String {
        format(value, Date.FormatStyle(date: dateStyle, time: timeStyle), calendar: calendar)
    }

    /// A reset short enough for one row: the time today, the weekday within the
    /// coming six days, otherwise the date.
    public static func moment(_ value: Date, relativeTo now: Date, calendar: Calendar? = nil,
                              locale: Locale? = nil) -> String {
        var selectedCalendar = calendar ?? .current
        if calendar == nil { selectedCalendar.timeZone = DisplayTimeZone.current }
        let days = selectedCalendar.dateComponents([.day], from: selectedCalendar.startOfDay(for: now), to: selectedCalendar.startOfDay(for: value)).day ?? 0
        let style = days == 0 ? Date.FormatStyle(date: .omitted, time: .shortened)
            : (1...6).contains(days) ? Date.FormatStyle().weekday(.abbreviated).hour().minute()
            : Date.FormatStyle().month(.abbreviated).day().hour().minute()
        return format(value, style, calendar: selectedCalendar, locale: locale)
    }
}
