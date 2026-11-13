import Foundation

/// The only data shared with the extension. It contains no account identifiers or imports.
nonisolated struct WidgetSnapshot: Decodable, Sendable {
    static let appGroup = "group.com.ardasayar.linglossa"
    static let storageKey = "learningSnapshot"

    let available: Bool
    let generatedAt: Date
    let day: String
    let language: String
    let streak: Int
    let lastActiveDay: String?
    let activeDays: Set<String>
    let goalDone: Int
    let goalTarget: Int
    /// Sorted once, so each timeline entry can count due cards in O(log n).
    let dueDates: [Date]
    let story: Story?

    struct Story: Decodable, Sendable {
        let id: String
        let title: String
        let coverFileName: String?
        let progress: Double

        var safeCoverFileName: String? {
            guard let name = coverFileName,
                  !name.isEmpty, name.count <= 160,
                  name != ".", name != "..",
                  name.unicodeScalars.allSatisfy({
                      CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
                          .contains($0)
                  }) else { return nil }
            return name
        }

        func coverURL(in container: URL?) -> URL? {
            guard let container, let name = safeCoverFileName else { return nil }
            let group = container.resolvingSymlinksInPath().standardizedFileURL
            let root = group.appendingPathComponent("home_widget", isDirectory: true)
                .resolvingSymlinksInPath().standardizedFileURL
            guard root.deletingLastPathComponent().path == group.path else { return nil }
            let file = root.appendingPathComponent(name, isDirectory: false)
                .resolvingSymlinksInPath().standardizedFileURL
            guard file.deletingLastPathComponent().path == root.path else { return nil }
            return file
        }
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, available, generatedAt, day, language, streak
        case lastActiveDay, activeDays, goalDone, goalTarget, dueDates, story
    }

    static let unavailable = WidgetSnapshot(
        available: false, generatedAt: .distantPast, day: "", language: "",
        streak: 0, lastActiveDay: nil, activeDays: [], goalDone: 0,
        goalTarget: 1, dueDates: [], story: nil
    )

    init(
        available: Bool, generatedAt: Date, day: String, language: String,
        streak: Int, lastActiveDay: String?, activeDays: Set<String>,
        goalDone: Int, goalTarget: Int, dueDates: [Date], story: Story?
    ) {
        self.available = available
        self.generatedAt = generatedAt
        self.day = day
        self.language = language
        self.streak = max(0, streak)
        self.lastActiveDay = lastActiveDay
        self.activeDays = activeDays
        self.goalDone = max(0, goalDone)
        self.goalTarget = max(1, goalTarget)
        self.dueDates = dueDates.sorted()
        self.story = story
    }

    init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        guard try values.decode(Int.self, forKey: .schemaVersion) == 1 else {
            throw DecodingError.dataCorruptedError(forKey: .schemaVersion, in: values, debugDescription: "Unsupported widget schema")
        }
        // A tombstone may intentionally contain no other fields. Never retain prior data.
        guard try values.decode(Bool.self, forKey: .available) else {
            self = .unavailable
            return
        }
        let timestamp = try values.decode(String.self, forKey: .generatedAt)
        guard let generatedAt = Self.parseTimestamp(timestamp) else {
            throw DecodingError.dataCorruptedError(forKey: .generatedAt, in: values, debugDescription: "Invalid timestamp")
        }
        let day = try values.decode(String.self, forKey: .day)
        let lastActiveDay = try values.decodeIfPresent(String.self, forKey: .lastActiveDay)
        let activeDays = try values.decode([String].self, forKey: .activeDays)
        let calendar = Self.localCalendar()
        guard Self.date(for: day, calendar: calendar) != nil,
              lastActiveDay.map({ Self.date(for: $0, calendar: calendar) != nil }) ?? true,
              activeDays.allSatisfy({ Self.date(for: $0, calendar: calendar) != nil }) else {
            throw DecodingError.dataCorruptedError(forKey: .day, in: values, debugDescription: "Invalid local day")
        }
        let language = try values.decode(String.self, forKey: .language)
        guard !language.isEmpty, language.count <= 64 else {
            throw DecodingError.dataCorruptedError(forKey: .language, in: values, debugDescription: "Invalid language")
        }
        let rawDueDates = try values.decode([String].self, forKey: .dueDates)
        let dueDates = rawDueDates.compactMap(Self.parseTimestamp)
        guard dueDates.count == rawDueDates.count else {
            throw DecodingError.dataCorruptedError(forKey: .dueDates, in: values, debugDescription: "Invalid due date")
        }
        let rawStory = try values.decodeIfPresent(Story.self, forKey: .story)
        let story: Story?
        if let rawStory, !rawStory.id.isEmpty, !rawStory.title.isEmpty,
           rawStory.id.count <= 256, rawStory.title.count <= 300,
           rawStory.progress.isFinite {
            story = Story(id: rawStory.id, title: rawStory.title,
                          coverFileName: rawStory.safeCoverFileName,
                          progress: min(1, max(0, rawStory.progress)))
        } else {
            story = nil
        }
        self.init(
            available: true, generatedAt: generatedAt, day: day, language: language,
            streak: try values.decode(Int.self, forKey: .streak), lastActiveDay: lastActiveDay,
            activeDays: Set(activeDays), goalDone: try values.decode(Int.self, forKey: .goalDone),
            goalTarget: try values.decode(Int.self, forKey: .goalTarget), dueDates: dueDates, story: story
        )
    }

    static func load(defaults: UserDefaults? = UserDefaults(suiteName: appGroup)) -> WidgetSnapshot {
        guard let json = defaults?.string(forKey: storageKey),
              let data = json.data(using: .utf8), data.count <= 4_194_304,
              let snapshot = try? JSONDecoder().decode(Self.self, from: data) else {
            return .unavailable
        }
        return snapshot
    }

    func effective(at now: Date, calendar: Calendar = Self.localCalendar()) -> EffectiveWidgetSnapshot {
        guard available else { return .unavailable }
        let today = calendar.startOfDay(for: now)
        let todayKey = Self.dayKey(today, calendar: calendar)
        let lastActivity = lastActiveDay.flatMap { Self.date(for: $0, calendar: calendar) }
        let gap = lastActivity.flatMap { calendar.dateComponents([.day], from: $0, to: today).day }
        let effectiveStreak = gap.map { (0...1).contains($0) ? streak : 0 } ?? 0
        let mondayOffset = (calendar.component(.weekday, from: today) + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: today) ?? today
        let shortNames = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]
        let fullNames = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"]
        let week = (0..<7).compactMap { index -> EffectiveWidgetSnapshot.WeekDay? in
            guard let date = calendar.date(byAdding: .day, value: index, to: monday) else { return nil }
            let key = Self.dayKey(date, calendar: calendar)
            return .init(id: key, shortName: shortNames[index], fullName: fullNames[index],
                         practiced: date <= today && activeDays.contains(key),
                         isToday: key == todayKey, isFuture: date > today)
        }
        var lower = 0
        var upper = dueDates.count
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if dueDates[middle] <= now { lower = middle + 1 } else { upper = middle }
        }
        return .init(available: true, language: language, streak: effectiveStreak,
                     goalDone: day == todayKey ? goalDone : 0, goalTarget: goalTarget,
                     dueCount: lower, week: week, story: story)
    }

    /// ISO date keys use the Gregorian calendar, independent of the user's calendar preference.
    /// The autoupdating system time zone still determines local days and DST boundaries.
    static func localCalendar(timeZone: TimeZone = .autoupdatingCurrent) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    static func dayKey(_ date: Date, calendar: Calendar = localCalendar()) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(for key: String, calendar: Calendar = localCalendar()) -> Date? {
        let parts = key.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]),
              (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day),
              let date = calendar.date(from: DateComponents(year: year, month: month, day: day)),
              dayKey(date, calendar: calendar) == key else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func parseTimestamp(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

nonisolated struct EffectiveWidgetSnapshot: Sendable {
    struct WeekDay: Identifiable, Sendable {
        let id: String
        let shortName: String
        let fullName: String
        let practiced: Bool
        let isToday: Bool
        let isFuture: Bool
        var accessibilityLabel: String {
            "\(fullName)\(isToday ? ", heute" : ""), \(practiced ? "geübt" : (isFuture ? "noch nicht begonnen" : "nicht geübt"))"
        }
    }
    let available: Bool
    let language: String
    let streak: Int
    let goalDone: Int
    let goalTarget: Int
    let dueCount: Int
    let week: [WeekDay]
    let story: WidgetSnapshot.Story?

    static let unavailable = EffectiveWidgetSnapshot(available: false, language: "", streak: 0,
        goalDone: 0, goalTarget: 1, dueCount: 0, week: [], story: nil)
    var goalReached: Bool { goalDone >= goalTarget }
    var remaining: Int { max(0, goalTarget - goalDone) }
    var goalProgress: Double { min(1, Double(goalDone) / Double(goalTarget)) }
    var streakDescription: String { streak == 1 ? "1 Tag in Folge" : "\(streak) Tage in Folge" }
    var goalDescription: String { goalReached ? "Tagesziel erreicht" : "\(goalDone) von \(goalTarget) Wörtern geübt" }
    var practiceURL: URL { WidgetLinks.practice }
    var storyURL: URL { WidgetLinks.story(id: story?.id, language: language) }
}

nonisolated enum WidgetLinks {
    // These fixed literals are part of the host app's URL contract.
    static let home = URL(string: "linglossa://home?homeWidget=1")!
    static let practice = URL(string: "linglossa://practice?homeWidget=1")!

    static func story(id: String?, language: String) -> URL {
        guard let id, !id.isEmpty, !language.isEmpty else { return home }
        var components = URLComponents()
        components.scheme = "linglossa"
        components.host = "story"
        components.queryItems = [URLQueryItem(name: "id", value: id), URLQueryItem(name: "language", value: language),
                                 URLQueryItem(name: "homeWidget", value: "1")]
        // Dart query decoding treats '+' as a space; keep literal plus signs unambiguous.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url ?? home
    }
}

nonisolated struct WidgetTimelineSchedule: Sendable {
    let dates: [Date]
    let reloadAt: Date

    init(snapshot: WidgetSnapshot, now: Date, calendar: Calendar = WidgetSnapshot.localCalendar()) {
        let today = calendar.startOfDay(for: now)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: today) ?? now.addingTimeInterval(3_600)
        // Keep a week's midnight fallbacks if the OS delays a requested refresh.
        var dates = Set([now])
        for offset in 1...7 {
            if let midnight = calendar.date(byAdding: .day, value: offset, to: today) { dates.insert(midnight) }
        }
        // Bound archive size. The next omitted due instant requests a new timeline.
        let nextDueDates = Array(Set(snapshot.available ? snapshot.dueDates.filter { $0 > now && $0 < nextMidnight } : [])).sorted()
        dates.formUnion(nextDueDates.prefix(48))
        self.dates = dates.sorted()
        self.reloadAt = nextDueDates.count > 48 ? nextDueDates[48] : nextMidnight
    }
}
