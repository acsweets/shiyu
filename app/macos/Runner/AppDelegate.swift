import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
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
