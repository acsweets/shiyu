import Cocoa
import Carbon
import FlutterMacOS
import ServiceManagement
import desktop_multi_window
import file_selector_macos
import screen_retriever_macos
import window_manager

class MainFlutterWindow: NSWindow {
  private var runtimeObservers: [(NotificationCenter, NSObjectProtocol)] = []
  private var desktopChannel: FlutterMethodChannel?
  private var packChannel: FlutterMethodChannel?
  private var shortcuts: DesktopShortcuts?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = .clear
    self.isOpaque = false
    self.backgroundColor = .clear
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    registerRuntimeEvents(flutterViewController.engine.binaryMessenger)
    let packs = FlutterMethodChannel(
      name: "shiyu/timerpack", binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    packs.resizeBuffer(8)
    packChannel = packs

    // 子窗仅控制自己的窗口，业务状态与全局入口由主窗管理。
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      controller.backgroundColor = .clear
      WindowManagerPlugin.register(with: controller.registrar(forPlugin: "WindowManagerPlugin"))
      ScreenRetrieverMacosPlugin.register(
        with: controller.registrar(forPlugin: "ScreenRetrieverMacosPlugin")
      )
      FileSelectorPlugin.register(with: controller.registrar(forPlugin: "FileSelectorPlugin"))
    }

    super.awakeFromNib()
  }

  private func registerRuntimeEvents(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "shiyu/runtime", binaryMessenger: messenger)
    desktopChannel = channel
    shortcuts = DesktopShortcuts(channel: channel)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleDesktop(call, result: result)
    }
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

  func reopenShiyu() {
    desktopChannel?.invokeMethod("reopen", arguments: nil)
  }

  func installTimerPack(_ url: URL) {
    let access = url.startAccessingSecurityScopedResource()
    defer { if access { url.stopAccessingSecurityScopedResource() } }
    let limit = 8 * 1024 * 1024
    guard let file = try? FileHandle(forReadingFrom: url) else {
      packChannel?.invokeMethod("install", arguments: nil)
      return
    }
    defer { try? file.close() }
    let data = try? file.read(upToCount: limit + 1)
    let payload = data.flatMap { $0.count <= limit ? FlutterStandardTypedData(bytes: $0) : nil }
    packChannel?.invokeMethod("install", arguments: payload)
  }

  private func handleDesktop(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "visibilityShortcut":
      result(shortcuts?.setVisibility(call.arguments as? Bool ?? false) ?? false)
    case "amountShortcut":
      result(shortcuts?.setAmount(call.arguments as? String ?? "") ?? false)
    case "startupSupported":
      if #available(macOS 13.0, *) { result(true) } else { result(false) }
    case "startupEnabled":
      if #available(macOS 13.0, *) {
        result(SMAppService.mainApp.status == .enabled)
      } else {
        result(false)
      }
    case "startupSet":
      guard #available(macOS 13.0, *), let enabled = call.arguments as? Bool else {
        result(false)
        return
      }
      let service = SMAppService.mainApp
      do {
        if enabled && service.status != .enabled {
          try service.register()
        } else if !enabled && (service.status == .enabled || service.status == .requiresApproval) {
          try service.unregister()
        }
        result(true)
      } catch {
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  deinit {
    desktopChannel?.setMethodCallHandler(nil)
    for (center, token) in runtimeObservers {
      center.removeObserver(token)
    }
  }
}

/// 注册系统快捷键时保留上次成功的键位，直到新键位注册成功。
private final class DesktopShortcuts {
  private let channel: FlutterMethodChannel
  private var handler: EventHandlerRef?
  private var visibility: EventHotKeyRef?
  private var amount: EventHotKeyRef?
  private var amountLetter = ""
  private var amountID: UInt32 = 2
  private static let signature: OSType = 0x53485955
  private static let keys = [
    kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F,
    kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L,
    kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_Q, kVK_ANSI_R,
    kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
    kVK_ANSI_Y, kVK_ANSI_Z,
  ].map { UInt32($0) }

  init(channel: FlutterMethodChannel) {
    self.channel = channel
    var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(GetEventDispatcherTarget(), { _, event, context in
      guard let event = event, let context = context else { return OSStatus(eventNotHandledErr) }
      return Unmanaged<DesktopShortcuts>.fromOpaque(context).takeUnretainedValue().send(event)
    }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
  }

  func setVisibility(_ enabled: Bool) -> Bool {
    if enabled && visibility == nil {
      visibility = register(UInt32(kVK_ANSI_T), id: 1)
      return visibility != nil
    }
    if !enabled, let previous = visibility {
      UnregisterEventHotKey(previous)
      visibility = nil
    }
    return true
  }

  func setAmount(_ letter: String) -> Bool {
    if letter == amountLetter { return true }
    let newID: UInt32 = amountID == 2 ? 3 : 2
    var next: EventHotKeyRef?
    if !letter.isEmpty {
      guard letter.utf8.count == 1, let key = letter.utf8.first,
            key >= 65, key <= 90, letter != "T",
            let registered = register(Self.keys[Int(key - 65)], id: newID) else {
        return false
      }
      next = registered
    }
    if let previous = amount { UnregisterEventHotKey(previous) }
    amount = next
    amountLetter = letter
    amountID = newID
    return true
  }

  private func register(_ code: UInt32, id: UInt32) -> EventHotKeyRef? {
    guard handler != nil else { return nil }
    var result: EventHotKeyRef?
    let identity = EventHotKeyID(signature: Self.signature, id: id)
    let status = RegisterEventHotKey(
      code, UInt32(cmdKey | shiftKey), identity, GetEventDispatcherTarget(), 0, &result
    )
    return status == noErr ? result : nil
  }

  private func send(_ event: EventRef) -> OSStatus {
    var id = EventHotKeyID()
    let status = GetEventParameter(
      event, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID),
      nil, MemoryLayout<EventHotKeyID>.size, nil, &id
    )
    guard status == noErr, id.signature == Self.signature else { return OSStatus(eventNotHandledErr) }
    channel.invokeMethod(id.id == 1 ? "toggleVisibility" : "toggleAmount", arguments: nil)
    return noErr
  }

  deinit {
    if let key = visibility { UnregisterEventHotKey(key) }
    if let key = amount { UnregisterEventHotKey(key) }
    if let handler = handler { RemoveEventHandler(handler) }
  }
}
