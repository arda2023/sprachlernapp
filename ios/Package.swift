// swift-tools-version: 6.2
import Foundation
import PackageDescription

// The extension's SwiftUI views, fonts and Xcode resources do not belong to the
// Foundation-only model test target. Keep newly added resources excluded too.
let widgetDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("LinglossaWidgets", isDirectory: true)
let modelExclusions = (try? FileManager.default.contentsOfDirectory(atPath: widgetDirectory.path))?
    .filter { $0 != "WidgetSnapshot.swift" } ?? []

let package = Package(
    name: "LinglossaWidgetModelQA",
    platforms: [.macOS(.v13)],
    products: [.library(name: "WidgetModel", targets: ["WidgetModel"])],
    targets: [
        .target(name: "WidgetModel", path: "LinglossaWidgets", exclude: modelExclusions,
                sources: ["WidgetSnapshot.swift"]),
        .testTarget(name: "WidgetModelTests", dependencies: ["WidgetModel"], path: "WidgetTests")
    ]
)
