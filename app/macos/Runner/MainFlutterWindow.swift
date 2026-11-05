import Cocoa
import FlutterMacOS
import desktop_multi_window
import window_manager

class MainFlutterWindow: NSWindow {
  private var runtimeObservers: [(NotificationCenter, NSObjectProtocol)] = []

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerRuntimeEvents(flutterViewController.engine.binaryMessenger)

    // 子窗仅控制自己的窗口，业务状态与全局入口由主窗管理。
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
    }

    super.awakeFromNib()
  }

  private func registerRuntimeEvents(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "shiyu/runtime", binaryMessenger: messenger)
    let workspace = NSWorkspace.shared.notificationCenter
    let system = NotificationCenter.default
    let events: [(NotificationCenter, Notification.Name, String)] = [
      (workspace, NSWorkspace.willSleepNotification, "sleep"),
      (workspace, NSWorkspace.didWakeNotification, "wake"),
      (workspace, NSWorkspace.sessionDidResignActiveNotification, "lock"),
      (workspace, NSWorkspace.sessionDidBecomeActiveNotification, "unlock"),
      (system, .NSSystemClockDidChange, "clockChanged"),
      (system, .NSSystemTimeZoneDidChange, "clockChanged"),
    ]
    for (center, name, method) in events {
      let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
        channel.invokeMethod(method, arguments: nil)
      }
      runtimeObservers.append((center, token))
    }
  }

  deinit {
    for (center, token) in runtimeObservers {
      center.removeObserver(token)
    }
  }
}
