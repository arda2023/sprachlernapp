import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Flutter stores private imports, cards and SQLite caches here. Excluding
    // the directory covers existing files, new files and SQLite sidecars.
    do {
      var support = try FileManager.default.url(
        for: .applicationSupportDirectory, in: .userDomainMask,
        appropriateFor: nil, create: true
      )
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try support.setResourceValues(values)
    } catch {
      // Do not log filesystem paths, user content or credentials.
      NSLog("Private storage backup exclusion could not be applied.")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
