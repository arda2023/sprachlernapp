import Foundation
import Testing
@testable import WidgetModel

private let berlin = WidgetSnapshot.localCalendar(timeZone: TimeZone(identifier: "Europe/Berlin")!)
private let sampleJSON = """
{
  "schemaVersion": 1, "available": true,
  "generatedAt": "2026-11-13T11:00:00.123Z", "day": "2026-11-13", "language": "fr",
  "streak": 14, "lastActiveDay": "2026-11-13",
  "activeDays": ["2026-11-09", "2026-11-10", "2026-11-11", "2026-11-13"],
  "goalDone": 6, "goalTarget": 10,
  "dueDates": ["2026-11-14T10:00:00Z", "2026-11-13T10:00:00Z", "2026-11-13T14:00:00Z"],
  "story": {"id": "catalog-1", "title": "Ein Abend in Paris", "coverFileName": "cover-1.png", "progress": 0.37}
}
"""

private func sample() throws -> WidgetSnapshot {
    try JSONDecoder().decode(WidgetSnapshot.self, from: Data(sampleJSON.utf8))
}

@Test func currentDayPreservesProgressAndCountsDueDates() throws {
    let value = try sample().effective(at: #require(WidgetSnapshot.parseTimestamp("2026-11-13T11:00:00Z")), calendar: berlin)
    #expect(value.goalDone == 6)
    #expect(value.streak == 14)
    #expect(value.dueCount == 1)
    #expect(value.week.map(\.shortName) == ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"])
    #expect(value.week.filter(\.practiced).count == 4)
    #expect(value.week.first(where: \.isToday)?.id == "2026-11-13")
}

@Test(arguments: [("2026-11-13T23:00:00Z", 14, 2), ("2026-11-14T23:00:00Z", 0, 3)])
func midnightResetsGoalAndExpiresStreak(input: (String, Int, Int)) throws {
    let value = try sample().effective(at: #require(WidgetSnapshot.parseTimestamp(input.0)), calendar: berlin)
    #expect(value.goalDone == 0)
    #expect(value.streak == input.1)
    #expect(value.dueCount == input.2)
}

@Test func mondayStartsANewWeekWithoutOldChecks() throws {
    let value = try sample().effective(at: #require(WidgetSnapshot.parseTimestamp("2026-11-16T10:00:00Z")), calendar: berlin)
    #expect(value.week.first?.id == "2026-11-16")
    #expect(value.week.filter(\.practiced).isEmpty)
    #expect(value.week.first?.isToday == true)
}

@Test func logoutTombstoneDropsAllPreviousFields() throws {
    let json = sampleJSON.replacingOccurrences(of: "\"available\": true", with: "\"available\": false")
    let snapshot = try JSONDecoder().decode(WidgetSnapshot.self, from: Data(json.utf8))
    let value = snapshot.effective(at: Date(), calendar: berlin)
    #expect(!value.available)
    #expect(value.story == nil)
    #expect(value.streak == 0)
    #expect(value.dueCount == 0)
    #expect(value.week.isEmpty)
    let minimal = Data("{\"schemaVersion\":1,\"available\":false}".utf8)
    #expect(try !JSONDecoder().decode(WidgetSnapshot.self, from: minimal).available)
}

@Test(arguments: [("2026-03-29", 23.0), ("2026-10-25", 25.0)])
func timelineUsesLocalMidnightAcrossDST(input: (String, Double)) throws {
    let now = try #require(WidgetSnapshot.date(for: input.0, calendar: berlin))
    let schedule = WidgetTimelineSchedule(snapshot: .unavailable, now: now, calendar: berlin)
    #expect(schedule.reloadAt.timeIntervalSince(now) == input.1 * 3_600)
    #expect(schedule.dates.count == 8)
    for date in schedule.dates {
        #expect(berlin.component(.hour, from: date) == 0)
        #expect(berlin.component(.minute, from: date) == 0)
    }
}

@Test func dueInstantsAreEntriesAndMidnightRemainsAFallback() throws {
    let now = try #require(WidgetSnapshot.parseTimestamp("2026-11-13T11:00:00Z"))
    let schedule = WidgetTimelineSchedule(snapshot: try sample(), now: now, calendar: berlin)
    #expect(schedule.dates.contains(try #require(WidgetSnapshot.parseTimestamp("2026-11-13T14:00:00Z"))))
    #expect(schedule.reloadAt == WidgetSnapshot.parseTimestamp("2026-11-13T23:00:00Z"))
    #expect(schedule.dates.count == 9)
}

@Test func timelineCapsDueEntriesAndRequestsRefreshAtTheNextOmittedInstant() throws {
    let now = try #require(WidgetSnapshot.parseTimestamp("2026-11-13T11:00:00Z"))
    let dates = (1...80).map { now.addingTimeInterval(Double($0 * 60)) }
    let snapshot = WidgetSnapshot(available: true, generatedAt: now, day: "2026-11-13", language: "fr", streak: 0,
        lastActiveDay: nil, activeDays: [], goalDone: 0, goalTarget: 10, dueDates: dates, story: nil)
    let schedule = WidgetTimelineSchedule(snapshot: snapshot, now: now, calendar: berlin)
    #expect(schedule.dates.count == 56)
    #expect(schedule.reloadAt == dates[48])
}

@Test func storyLinkEscapesEachQueryValue() throws {
    let id = "début+ & id=another/#?"
    let url = WidgetLinks.story(id: id, language: "fr&redirect=elsewhere")
    let query = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    #expect(url.scheme == "linglossa")
    #expect(url.host == "story")
    #expect(query.count == 3)
    #expect(query[0].value == id)
    #expect(query[1].value == "fr&redirect=elsewhere")
    #expect(query[2] == URLQueryItem(name: "homeWidget", value: "1"))
    #expect(url.absoluteString.contains("%2B"))
    #expect(WidgetLinks.story(id: nil, language: "fr") == WidgetLinks.home)
}

@Test(arguments: ["../cover.png", "/private/cover.png", "a/b.png", "a\\b.png", "%2e%2e.png", ".", "..", ""])
func coverCannotEscapeTheSharedContainer(name: String) {
    let story = WidgetSnapshot.Story(id: "a", title: "A", coverFileName: name, progress: 0)
    #expect(story.safeCoverFileName == nil)
    #expect(story.coverURL(in: FileManager.default.temporaryDirectory.appendingPathComponent("linglossa-qa-group")) == nil)
}

@Test func validCoverResolvesInsideContainer() throws {
    let story = try #require(try sample().story)
    #expect(story.coverURL(in: FileManager.default.temporaryDirectory.appendingPathComponent("linglossa-qa-group"))?.lastPathComponent == "cover-1.png")
    #expect(story.coverURL(in: FileManager.default.temporaryDirectory.appendingPathComponent("linglossa-qa-group"))?.deletingLastPathComponent().lastPathComponent == "home_widget")
}

@Test func symlinkedCoverCannotReadOutsideTheImageDirectory() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("widget-cover-test-\(UUID().uuidString)")
    let covers = root.appendingPathComponent("home_widget")
    try FileManager.default.createDirectory(at: covers, withIntermediateDirectories: true)
    let outside = root.appendingPathComponent("outside.png")
    try Data().write(to: outside)
    try FileManager.default.createSymbolicLink(at: covers.appendingPathComponent("cover.png"), withDestinationURL: outside)
    let story = WidgetSnapshot.Story(id: "a", title: "A", coverFileName: "cover.png", progress: 0)
    #expect(story.coverURL(in: root) == nil)
}

@Test(arguments: ["2026-02-30", "2026-2-09", "2026-00-01", "-026-12-13", "2026-13-01"])
func invalidLocalDatesAreRejected(key: String) {
    #expect(WidgetSnapshot.date(for: key, calendar: berlin) == nil)
}

@Test func changedTimezoneUsesItsOwnLocalDay() throws {
    let now = try #require(WidgetSnapshot.parseTimestamp("2026-11-13T23:30:00Z"))
    let newYork = WidgetSnapshot.localCalendar(timeZone: try #require(TimeZone(identifier: "America/New_York")))
    #expect(try sample().effective(at: now, calendar: berlin).goalDone == 0)
    #expect(try sample().effective(at: now, calendar: newYork).goalDone == 6)
}

@Test func invalidSchemaAndMalformedDueDatesDoNotDecode() {
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WidgetSnapshot.self, from: Data(sampleJSON.replacingOccurrences(of: "\"schemaVersion\": 1", with: "\"schemaVersion\": 2").utf8))
    }
    #expect(throws: (any Error).self) {
        try JSONDecoder().decode(WidgetSnapshot.self, from: Data(sampleJSON.replacingOccurrences(of: "2026-11-14T10:00:00Z", with: "invalid").utf8))
    }
}
