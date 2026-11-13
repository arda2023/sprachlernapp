import SwiftUI
import WidgetKit
import UIKit
import ImageIO

enum LinglossaWidgetSize {
    case small, medium, large
}

/// The outer view keeps every API introduced after iOS 15 behind an availability check.
struct LinglossaWidgetView: View {
    let snapshot: EffectiveWidgetSnapshot
    let size: LinglossaWidgetSize
    var coverContainer: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroup)
    var previewBackground = false

    var body: some View {
        if #available(iOS 16.0, *) {
            RenderingModeView(snapshot: snapshot, size: size, coverContainer: coverContainer, previewBackground: previewBackground)
        } else {
            WidgetCanvas(snapshot: snapshot, size: size, coverContainer: coverContainer, accented: false, previewBackground: previewBackground)
        }
    }
}

@available(iOS 16.0, *)
private struct RenderingModeView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    let snapshot: EffectiveWidgetSnapshot
    let size: LinglossaWidgetSize
    let coverContainer: URL?
    let previewBackground: Bool

    var body: some View {
        WidgetCanvas(snapshot: snapshot, size: size, coverContainer: coverContainer,
                     accented: renderingMode != .fullColor, previewBackground: previewBackground)
    }
}

private struct WidgetCanvas: View {
    @Environment(\.colorScheme) private var colorScheme
    let snapshot: EffectiveWidgetSnapshot
    let size: LinglossaWidgetSize
    let coverContainer: URL?
    let accented: Bool
    let previewBackground: Bool

    private var palette: WidgetPalette {
        WidgetPalette(dark: colorScheme == .dark, accented: accented,
                      filled: size == .small && snapshot.available, achieved: snapshot.goalReached)
    }

    var body: some View {
        content
            .padding(size == .large ? 18 : 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .foregroundStyle(palette.ink)
            .modifier(WidgetBackground(color: palette.background, preview: previewBackground))
            .widgetURL(snapshot.available ? (size == .large ? WidgetLinks.home : WidgetLinks.practice) : WidgetLinks.home)
    }

    @ViewBuilder
    private var content: some View {
        if !snapshot.available {
            EmptyWidget(palette: palette, size: size)
        } else {
            switch size {
            case .small:
                StreakWidget(snapshot: snapshot, palette: palette)
            case .medium:
                WeekWidget(snapshot: snapshot, palette: palette)
            case .large:
                LearningWidget(snapshot: snapshot, palette: palette, coverContainer: coverContainer)
            }
        }
    }
}

private struct WidgetPalette {
    let dark: Bool
    let accented: Bool
    let filled: Bool
    let achieved: Bool

    var orange: Color { Color(hex: 0xF77F00) }
    var green: Color { Color(hex: dark ? 0x34C77B : 0x1FA463) }
    var accent: Color { achieved ? green : orange }
    var background: Color {
        if accented { return .clear }
        return filled ? accent : Color(hex: dark ? 0x1A1D26 : 0xFFFFFF)
    }
    var ink: Color {
        if accented { return .primary }
        return Color(hex: filled ? (dark ? 0x0D0F14 : 0x202632) : (dark ? 0xF0F2F5 : 0x202632))
    }
    var muted: Color {
        if accented { return .primary.opacity(0.85) }
        return filled ? ink : Color(hex: dark ? 0x8E95A5 : 0x596477)
    }
    var line: Color { ink.opacity(accented ? 0.35 : 0.14) }
}

private enum WidgetFont {
    static func medium(_ size: CGFloat, relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom("Figtree-Medium", size: size, relativeTo: style)
    }
    static func bold(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
        .custom("Figtree-Bold", size: size, relativeTo: style)
    }
    static func numeral(_ size: CGFloat) -> Font {
        // The display numeral uses ScaledMetric at the call site to fit the fixed widget canvas.
        .custom("Figtree-ExtraBold", fixedSize: size)
    }
    static func story(_ size: CGFloat) -> Font {
        .custom("SourceSerif4-SemiBold", size: size, relativeTo: .headline)
    }
}

private struct StreakWidget: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .largeTitle) private var numberSize = 60.0
    let snapshot: EffectiveWidgetSnapshot
    let palette: WidgetPalette

    private var goalCaption: String {
        if snapshot.goalReached { return "Geschafft" }
        if typeSize >= .accessibility3 { return "Noch \(snapshot.remaining)" }
        return "Noch \(snapshot.remaining) \(snapshot.remaining == 1 ? "Wort" : "Wörter")"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 8) {
                Text(snapshot.streak.formatted(.number.locale(Locale(identifier: "de_DE"))))
                    .font(WidgetFont.numeral(min(numberSize, 70)))
                    .tracking(-2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .layoutPriority(1)
                Spacer(minLength: 0)
                Image(systemName: snapshot.goalReached ? "checkmark.seal.fill" : "flame.fill")
                    .font(.system(size: typeSize.isAccessibilitySize ? 22 : 30, weight: .semibold))
                    .padding(.top, 9)
                    .modifier(AccentGroup())
                    .accessibilityHidden(true)
            }
            if !typeSize.isAccessibilitySize {
                Text(snapshot.streak == 0 ? "Heute starten" : (snapshot.streak == 1 ? "Tag in Folge" : "Tage in Folge"))
                    .font(WidgetFont.medium(14, relativeTo: .subheadline))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 5)
            HStack(spacing: 4) {
                if snapshot.goalReached {
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).accessibilityHidden(true)
                }
                Text(goalCaption)
                    .font(WidgetFont.medium(13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            GoalBar(progress: snapshot.goalProgress, color: palette.ink, track: palette.line)
                .padding(.top, 5)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(snapshot.streakDescription). \(snapshot.goalDescription).")
        .accessibilityHint("Öffnet die Übung")
        .accessibilityAddTraits(.isLink)
    }
}

private struct WeekWidget: View {
    let snapshot: EffectiveWidgetSnapshot
    let palette: WidgetPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StreakAndGoal(snapshot: snapshot, palette: palette)
            Spacer(minLength: 0)
            WeekStrip(days: snapshot.week, palette: palette)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Öffnet die Übung")
        .accessibilityAddTraits(.isLink)
    }
}

private struct StreakAndGoal: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @ScaledMetric(relativeTo: .title) private var numberSize = 34.0
    let snapshot: EffectiveWidgetSnapshot
    let palette: WidgetPalette
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(snapshot.streak)")
                        .font(WidgetFont.numeral(min(numberSize, compact ? 40 : 48)))
                        .tracking(-1)
                        .minimumScaleFactor(0.55)
                    Text(snapshot.streak == 1 ? "Tag" : "Tage")
                        .font(WidgetFont.medium(14, relativeTo: .subheadline))
                        .minimumScaleFactor(0.65)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(palette.accented ? palette.ink : palette.orange)
                        .modifier(AccentGroup())
                        .accessibilityHidden(true)
                }
                .lineLimit(1)
                if !typeSize.isAccessibilitySize {
                    Text(snapshot.streak == 0 ? "Heute starten" : (snapshot.goalReached ? "Heute geschafft" : "Heute dranbleiben"))
                        .font(WidgetFont.medium(13))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(snapshot.streakDescription)

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    if snapshot.goalReached {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(palette.accented ? palette.ink : palette.green)
                            .modifier(AccentGroup())
                            .accessibilityHidden(true)
                    }
                    Text("\(snapshot.goalDone)/\(snapshot.goalTarget)")
                        .font(WidgetFont.bold(compact ? 20 : 23, relativeTo: .title3))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                if !typeSize.isAccessibilitySize {
                    Text("Wörter").font(WidgetFont.medium(12)).foregroundStyle(palette.muted)
                }
            }
            .frame(maxWidth: 110, alignment: .trailing)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(snapshot.goalDescription)
        }
    }
}

private struct WeekStrip: View {
    @ScaledMetric(relativeTo: .caption) private var circleSize = 26.0
    let days: [EffectiveWidgetSnapshot.WeekDay]
    let palette: WidgetPalette

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            ForEach(days) { day in
                VStack(spacing: 6) {
                    Text(day.shortName)
                        .underline(day.isToday && palette.accented, color: palette.ink)
                        .font(WidgetFont.medium(11))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    ZStack {
                        Circle()
                            .fill(day.practiced && !palette.accented ? palette.orange : Color.clear)
                            .modifier(AccentGroup(active: day.practiced))
                        if day.isToday {
                            Circle().strokeBorder(palette.ink, lineWidth: 1.5)
                        } else if day.practiced && palette.accented {
                            Circle().strokeBorder(palette.ink, lineWidth: 1)
                        } else if !day.practiced {
                            Circle().strokeBorder(palette.line, lineWidth: 1)
                        }
                        if day.practiced {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(palette.accented ? palette.ink : Color(hex: 0x202632))
                                .modifier(AccentGroup(active: palette.accented))
                        } else if day.isToday {
                            Circle().fill(palette.ink).frame(width: 4, height: 4)
                        }
                    }
                    .frame(width: min(circleSize, 32), height: min(circleSize, 32))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(day.accessibilityLabel)
            }
        }
    }
}

private struct LearningWidget: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let snapshot: EffectiveWidgetSnapshot
    let palette: WidgetPalette
    let coverContainer: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            Link(destination: snapshot.practiceURL) {
                VStack(spacing: 10) {
                    StreakAndGoal(snapshot: snapshot, palette: palette, compact: true)
                    WeekStrip(days: snapshot.week, palette: palette)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint("Öffnet die Übung")

            Rectangle().fill(palette.line).frame(height: 1).accessibilityHidden(true)

            Link(destination: snapshot.storyURL) {
                storyRow
                    .frame(maxWidth: .infinity, minHeight: typeSize.isAccessibilitySize ? 75 : 88, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(snapshot.story.map { "Weiterlesen: \($0.title), \(Int(($0.progress * 100).rounded())) Prozent gelesen" } ?? "Geschichte entdecken")
            .accessibilityHint(snapshot.story == nil ? "Öffnet die Startseite" : "Öffnet die Geschichte")

            Spacer(minLength: 0)

            Link(destination: snapshot.practiceURL) {
                HStack(spacing: 8) {
                    Text(snapshot.dueCount == 0 ? "Alles wiederholt" : "\(snapshot.dueCount) fällig")
                        .font(WidgetFont.medium(14, relativeTo: .subheadline))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 8)
                    Text("Üben").font(WidgetFont.bold(14, relativeTo: .subheadline)).lineLimit(1).minimumScaleFactor(0.7)
                    Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold)).accessibilityHidden(true)
                }
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 13).strokeBorder(palette.line, lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Üben, \(snapshot.dueCount) fällige Wiederholungen")
        }
    }

    @ViewBuilder
    private var storyRow: some View {
        HStack(spacing: 13) {
            if !typeSize.isAccessibilitySize {
                StoryCover(story: snapshot.story, container: coverContainer, palette: palette)
                    .frame(width: 67, height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                if let story = snapshot.story {
                    if !typeSize.isAccessibilitySize {
                        Text("WEITERLESEN")
                            .font(WidgetFont.medium(9))
                            .tracking(1)
                            .foregroundStyle(palette.muted)
                    }
                    Text(story.title)
                        .font(WidgetFont.story(typeSize.isAccessibilitySize ? 16 : 19))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(Int((story.progress * 100).rounded())) % gelesen")
                        .font(WidgetFont.medium(12))
                        .foregroundStyle(palette.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !typeSize.isAccessibilitySize {
                        GoalBar(progress: story.progress, color: palette.accented ? palette.ink : palette.orange, track: palette.line)
                            .padding(.top, 2)
                    }
                } else {
                    Text("Geschichte entdecken")
                        .font(WidgetFont.story(20))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text("App öffnen")
                        .font(WidgetFont.medium(13))
                        .foregroundStyle(palette.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct StoryCover: View {
    let story: WidgetSnapshot.Story?
    let container: URL?
    let palette: WidgetPalette

    var body: some View {
        if let image = thumbnail {
            if #available(iOS 18.0, *) {
                Image(uiImage: image).resizable()
                    .widgetAccentedRenderingMode(palette.accented ? .desaturated : .fullColor)
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 7).fill(palette.line)
                Image(systemName: "book.closed")
                    .font(.system(size: 26, weight: .medium))
                    .modifier(AccentGroup())
            }
        }
    }

    private var thumbnail: UIImage? {
        guard let url = story?.coverURL(in: container),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 260,
            kCGImageSourceShouldCacheImmediately: true
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}

private struct EmptyWidget: View {
    let palette: WidgetPalette
    let size: LinglossaWidgetSize

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: "book.closed")
                .font(.system(size: size == .small ? 27 : 34, weight: .medium))
                .foregroundStyle(palette.accented ? palette.ink : palette.orange)
                .modifier(AccentGroup())
                .accessibilityHidden(true)
            Spacer(minLength: 8)
            Text("Linglossa")
                .font(WidgetFont.bold(size == .small ? 20 : 25, relativeTo: .title2))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("App öffnen")
                .font(WidgetFont.medium(14, relativeTo: .subheadline))
                .foregroundStyle(palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Linglossa, App öffnen")
        .accessibilityAddTraits(.isLink)
    }
}

private struct GoalBar: View {
    let progress: Double
    let color: Color
    let track: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(color)
                    .frame(width: geometry.size.width * min(1, max(0, progress)))
                    .modifier(AccentGroup())
            }
        }
        .frame(height: 4)
        .accessibilityHidden(true)
    }
}

private struct AccentGroup: ViewModifier {
    var active = true
    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 16.0, *) { content.widgetAccentable(active) } else { content }
    }
}

private struct WidgetBackground: ViewModifier {
    let color: Color
    let preview: Bool
    @ViewBuilder func body(content: Content) -> some View {
        if preview {
            content.background(color)
        } else if #available(iOS 17.0, *) {
            content.containerBackground(color, for: .widget)
        } else {
            content.background(color)
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255, opacity: 1)
    }
}
