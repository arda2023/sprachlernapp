import SwiftUI
import WidgetKit
import UIKit
import CoreText

enum WidgetQAFixtures {
    static let calendar = WidgetSnapshot.localCalendar(timeZone: TimeZone(identifier: "Europe/Berlin")!)
    static let date = WidgetSnapshot.parseTimestamp("2026-11-13T11:00:00Z")!
    static let states = ["open", "complete", "zero", "unavailable"]
    static let sizes: [(String, LinglossaWidgetSize, CGSize)] = [
        ("small", .small, CGSize(width: 170, height: 170)),
        ("medium", .medium, CGSize(width: 360, height: 170)),
        ("large", .large, CGSize(width: 360, height: 376))
    ]

    static func snapshot(_ state: String) -> EffectiveWidgetSnapshot {
        guard state != "unavailable" else { return .unavailable }
        let zero = state == "zero"
        let snapshot = WidgetSnapshot(
            available: true, generatedAt: date, day: "2026-11-13", language: "en",
            streak: zero ? 0 : 14, lastActiveDay: zero ? nil : "2026-11-13",
            activeDays: zero ? [] : ["2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12", "2026-11-13"],
            goalDone: state == "complete" ? 10 : (zero ? 0 : 6), goalTarget: 10,
            dueDates: Array(repeating: date.addingTimeInterval(-3_600), count: 12),
            story: .init(id: "catalog-restaurant-05", title: "Ein Abend in Paris", coverFileName: "qa-cover.png", progress: 0.37)
        )
        return snapshot.effective(at: date, calendar: calendar)
    }

    static func registerFonts() {
        for name in ["Figtree-Medium", "Figtree-Bold", "Figtree-ExtraBold", "SourceSerif4-SemiBold"] {
            if UIFont(name: name, size: 12) == nil,
               let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
}

struct WidgetPreviewCard: View {
    let state: String
    let size: LinglossaWidgetSize
    let dimensions: CGSize
    let scheme: ColorScheme
    var typeSize: DynamicTypeSize = .large
    var accented = false

    var body: some View {
        LinglossaWidgetView(snapshot: WidgetQAFixtures.snapshot(state), size: size,
                           coverContainer: Bundle.main.bundleURL, previewBackground: true)
            .environment(\.colorScheme, scheme)
            .environment(\.dynamicTypeSize, typeSize)
            .environment(\.locale, Locale(identifier: "de_DE"))
            .environment(\.widgetRenderingMode, accented ? .accented : .fullColor)
            .frame(width: dimensions.width, height: dimensions.height)
            .background(accented ? Color(white: scheme == .dark ? 0.12 : 0.9) : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct WidgetQAOverview: View {
    let state: String
    let scheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 20) {
                WidgetPreviewCard(state: state, size: .small, dimensions: CGSize(width: 170, height: 170), scheme: scheme)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Linglossa").font(.system(size: 20, weight: .semibold))
                    Text(state == "open" ? "Heute offen" : (state == "complete" ? "Heute erledigt" : (state == "zero" ? "Streak 0" : "Keine Daten")))
                        .font(.system(size: 14, weight: .medium))
                    Text(scheme == .dark ? "Dunkel" : "Hell").font(.system(size: 12))
                    Text("SwiftUI\nSimulator-Rendering")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                        .padding(.top, 10)
                }
                .padding(.top, 14)
            }
            WidgetPreviewCard(state: state, size: .medium, dimensions: CGSize(width: 360, height: 170), scheme: scheme)
            WidgetPreviewCard(state: state, size: .large, dimensions: CGSize(width: 360, height: 376), scheme: scheme)
        }
        .padding(16)
        .background(Color(white: scheme == .dark ? 0.06 : 0.94))
        .environment(\.colorScheme, scheme)
    }
}

@main
struct WidgetQAApp: App {
    init() { WidgetQAFixtures.registerFonts() }
    var body: some Scene {
        WindowGroup {
            ScrollView { WidgetQAOverview(state: "open", scheme: .light) }
                .task { WidgetQARenderer.renderAll() }
        }
    }
}

@MainActor
enum WidgetQARenderer {
    static func renderAll() {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("widget-qa", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            var files = [String]()
            for (theme, scheme) in [("light", ColorScheme.light), ("dark", ColorScheme.dark)] {
                for state in WidgetQAFixtures.states {
                    for (name, size, dimensions) in WidgetQAFixtures.sizes {
                        let view = WidgetPreviewCard(state: state, size: size, dimensions: dimensions, scheme: scheme)
                        let file = "\(name)-\(state)-\(theme).png"
                        try save(view, to: folder.appendingPathComponent(file))
                        files.append(file)
                    }
                    try save(WidgetQAOverview(state: state, scheme: scheme), to: folder.appendingPathComponent("overview-\(state)-\(theme).png"))
                }
                for (name, size, dimensions) in WidgetQAFixtures.sizes {
                    let accessibility = WidgetPreviewCard(state: "open", size: size, dimensions: dimensions, scheme: scheme, typeSize: .accessibility1)
                    try save(accessibility, to: folder.appendingPathComponent("\(name)-accessibility-\(theme).png"))
                    let largest = WidgetPreviewCard(state: "open", size: size, dimensions: dimensions, scheme: scheme, typeSize: .accessibility5)
                    try save(largest, to: folder.appendingPathComponent("\(name)-accessibility-largest-\(theme).png"))
                    let accented = WidgetPreviewCard(state: "open", size: size, dimensions: dimensions, scheme: scheme, accented: true)
                    try save(accented, to: folder.appendingPathComponent("\(name)-accented-branch-\(theme).png"))
                }
                try save(HStack(alignment: .top, spacing: 0) {
                    ForEach(WidgetQAFixtures.states, id: \.self) { state in
                        WidgetQAOverview(state: state, scheme: scheme)
                    }
                }, to: folder.appendingPathComponent("contact-sheet-\(theme).png"))
            }
            let manifest: [String: Any] = [
                "renderer": "SwiftUI ImageRenderer, iOS Simulator", "scale": 2,
                "runID": ProcessInfo.processInfo.environment["QA_RUN_ID"] ?? "manual",
                "timestamp": Date().ISO8601Format(), "requiredScreenshots": files,
                "states": WidgetQAFixtures.states, "count": files.count,
                "note": "Accented previews verify the rendering branch, not SpringBoard's clear/tinted glass compositing."
            ]
            try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
                .write(to: folder.appendingPathComponent("manifest.json"))
            try Data("PASS: 24 required widget screenshots, 8 overviews, 2 contact sheets, 12 accessibility and 6 accented-branch previews.\n".utf8)
                .write(to: folder.appendingPathComponent("completed.txt"))
        } catch {
            try? Data("FAIL: \(error)\n".utf8).write(to: folder.appendingPathComponent("error.txt"))
        }
    }

    private static func save(_ content: some View, to url: URL) throws {
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.uiImage, let data = image.pngData() else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url, options: .atomic)
    }
}

struct LinglossaWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetQAOverview(state: "open", scheme: .light)
            WidgetQAOverview(state: "complete", scheme: .dark)
            WidgetQAOverview(state: "zero", scheme: .light)
            WidgetQAOverview(state: "unavailable", scheme: .dark)
        }
        .previewLayout(.sizeThatFits)
    }
}
