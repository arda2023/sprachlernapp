import Flutter
import UIKit
import SwiftUI
import Translation

// Bounded local diagnostics: stage, error class/domain and numeric code only.
// Never include sentence text, translations, userInfo or localizedDescription.
private func translationDiagnostic(_ event: String) {
    guard let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return }
    let file = directory.appendingPathComponent("device_translation_diagnostic.txt")
    let previous = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
    let lines = (previous.split(separator: "\n").map(String.init) + [event]).suffix(12)
    try? (lines.joined(separator: "\n") + "\n").write(to: file, atomically: true, encoding: .utf8)
}

public final class DeviceTranslationPlugin: NSObject, FlutterPlugin {
    // Registration can precede attachment of Flutter's view in an implicit engine.
    // Resolve the current presenter for each request, never cache an early nil.
    private var registrar: FlutterPluginRegistrar?
    private var controller: UIViewController? { registrar?.viewController }
    private var active: AnyObject?
    private var generation = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "device_translation", binaryMessenger: registrar.messenger())
        let instance = DeviceTranslationPlugin()
        instance.registrar = registrar
        translationDiagnostic("register controller=\(instance.controller == nil ? "absent" : "present")")
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        Task { @MainActor in
            guard #available(iOS 18.0, *) else {
                if call.method == "status" { result("unsupported") }
                else if call.method == "cancel" { result(nil) }
                else { result(FlutterError(code: "unsupported", message: nil, details: nil)) }
                return
            }
            if call.method == "cancel" {
                self.generation += 1
                (self.active as? TranslationJob)?.cancel()
                result(nil)
                return
            }
            guard let args = call.arguments as? [String: Any],
                  let lang = args["lang"] as? String, ["en", "pt-BR"].contains(lang) else {
                result(FlutterError(code: "invalid", message: nil, details: nil)); return
            }
            let requestGeneration = self.generation
            let source = Locale.Language(identifier: lang)
            let target = Locale.Language(identifier: "de")
            let state = await LanguageAvailability().status(from: source, to: target)
            guard requestGeneration == self.generation else {
                result(FlutterError(code: "cancelled", message: nil, details: nil)); return
            }
            if call.method == "status" {
                switch state {
                case .installed: result("installed")
                case .supported: result("supported")
                default: result("unsupported")
                }
                return
            }
            guard call.method == "prepare" || call.method == "translate" else {
                result(FlutterMethodNotImplemented); return
            }
            guard state != .unsupported else {
                result(FlutterError(code: "unsupported", message: nil, details: nil)); return
            }
            if call.method == "translate" && state != .installed {
                result(FlutterError(code: "missing_model", message: nil, details: nil)); return
            }
            translationDiagnostic("request stage=\(call.method) controller=\(self.controller == nil ? "absent" : "present") active=\(self.active != nil)")
            guard self.active == nil, var presenter = self.controller else {
                result(FlutterError(code: "busy", message: nil, details: nil)); return
            }
            while let next = presenter.presentedViewController { presenter = next }
            let text = args["text"] as? String ?? ""
            guard call.method == "prepare" || (!text.isEmpty && text.utf16.count <= 600) else {
                result(FlutterError(code: "invalid", message: nil, details: nil)); return
            }
            let job = TranslationJob(source: source, target: target, text: text,
                                     prepare: call.method == "prepare") { [weak self] value in
                self?.active = nil
                result(value)
            }
            self.active = job
            let host = UIHostingController(rootView: TranslationPanel(job: job))
            job.host = host
            host.isModalInPresentation = true
            host.modalPresentationStyle = .pageSheet
            presenter.present(host, animated: true)
        }
    }
}

@available(iOS 18.0, *)
@MainActor
private final class TranslationJob {
    let source: Locale.Language
    let target: Locale.Language
    let text: String
    let prepare: Bool
    weak var host: UIViewController?
    private var completion: FlutterResult?
    var session: TranslationSession?
    private(set) var finished = false

    init(source: Locale.Language, target: Locale.Language, text: String,
         prepare: Bool, completion: @escaping FlutterResult) {
        self.source = source; self.target = target; self.text = text
        self.prepare = prepare; self.completion = completion
    }
    func finish(_ value: Any?) {
        guard !finished else { return }
        finished = true
        let callback = completion
        completion = nil
        host?.dismiss(animated: true) { callback?(value) }
    }
    func cancel() {
        if #available(iOS 26.0, *) { session?.cancel() }
        finish(FlutterError(code: "cancelled", message: nil, details: nil))
    }
    func run(_ session: TranslationSession) async {
        guard !finished else { return }
        self.session = session
        translationDiagnostic("session stage=\(prepare ? "prepare" : "translate")")
        do {
            if prepare {
                try await session.prepareTranslation()
                finish(nil)
            } else {
                let response = try await session.translate(text)
                guard !Task.isCancelled && !finished else { return }
                finish(response.targetText)
            }
        } catch {
            let ns = error as NSError
            translationDiagnostic("failure class=\(String(reflecting: type(of: error))) domain=\(ns.domain) code=\(ns.code)")
            let storage = ns.domain == NSCocoaErrorDomain && ns.code == NSFileWriteOutOfSpaceError
            finish(FlutterError(code: Task.isCancelled ? "cancelled" : storage ? "storage" : "local_failure",
                                message: nil, details: nil))
        }
        self.session = nil
    }
}

@available(iOS 18.0, *)
private struct TranslationPanel: View {
    let job: TranslationJob
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
            Text(job.prepare ? "Sprachmodelle vorbereiten" : "Auf dem Gerät übersetzen")
            Text("Apple Translation · Dein Text bleibt auf diesem Gerät.")
                .font(.footnote)
            Button("Abbrechen") { job.cancel() }
        }
        .padding()
        .translationTask(source: job.source, target: job.target) { session in
            await job.run(session)
        }
    }
}
