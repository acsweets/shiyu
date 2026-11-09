import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func application(_ application: NSApplication, open urls: [URL]) {
    let packs = urls.filter { $0.isFileURL && $0.pathExtension.lowercased() == "timerpack" }
    if let window = mainFlutterWindow as? MainFlutterWindow {
      packs.forEach { window.installTimerPack($0) }
    }
    let other = urls.filter { !packs.contains($0) }
    if !other.isEmpty { super.application(application, open: other) }
  }

  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    sender.windows.compactMap { $0 as? MainFlutterWindow }.first?.reopenShiyu()
    return false
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
