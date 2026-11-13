import SwiftUI
import WidgetKit

nonisolated struct LearningEntry: TimelineEntry, Sendable {
    let date: Date
    let snapshot: EffectiveWidgetSnapshot
}

nonisolated struct LearningTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> LearningEntry {
        LearningEntry(date: Date(), snapshot: .unavailable)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (LearningEntry) -> Void) {
        let now = Date()
        completion(LearningEntry(date: now, snapshot: WidgetSnapshot.load().effective(at: now)))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<LearningEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshot.load()
        let calendar = WidgetSnapshot.localCalendar()
        let schedule = WidgetTimelineSchedule(snapshot: snapshot, now: now, calendar: calendar)
        let entries = schedule.dates.map { date in
            LearningEntry(date: date, snapshot: snapshot.effective(at: date, calendar: calendar))
        }
        completion(Timeline(entries: entries, policy: .after(schedule.reloadAt)))
    }
}

#if !WIDGET_QA
@main
#endif
struct LinglossaWidgets: WidgetBundle {
    var body: some Widget {
        LinglossaStreakWidget()
        LinglossaWeekWidget()
        LinglossaLearningWidget()
    }
}

struct LinglossaStreakWidget: Widget {
    let kind = "LinglossaStreak"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LearningTimelineProvider()) { entry in
            LinglossaWidgetView(snapshot: entry.snapshot, size: .small)
        }
        .configurationDisplayName("Streak")
        .description("Deine Serie und dein Tagesziel.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

struct LinglossaWeekWidget: Widget {
    let kind = "LinglossaWeek"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LearningTimelineProvider()) { entry in
            LinglossaWidgetView(snapshot: entry.snapshot, size: .medium)
        }
        .configurationDisplayName("Diese Woche")
        .description("Deine Lerntage im Blick.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

struct LinglossaLearningWidget: Widget {
    let kind = "LinglossaLearning"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LearningTimelineProvider()) { entry in
            LinglossaWidgetView(snapshot: entry.snapshot, size: .large)
        }
        .configurationDisplayName("Weiterlernen")
        .description("Weiterlesen und Wörter wiederholen.")
        .supportedFamilies([.systemLarge])
        .contentMarginsDisabled()
    }
}
