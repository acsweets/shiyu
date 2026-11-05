import Flutter
import WidgetKit

final class WidgetSettingsBridge: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "shiyu/widgets", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(WidgetSettingsBridge(), channel: channel)
    }

    // 共享文件只包含版本化设置；计时计算交给 Rust，不在桥接层重新实现。
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "readSettings": result(try SharedWidgetStore.read())
            case "writeSettings":
                guard let json = call.arguments as? String else {
                    result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
                    return
                }
                try SharedWidgetStore.writeSettings(json)
                result(nil)
            case "writeCalendar":
                guard let json = call.arguments as? String else {
                    result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
                    return
                }
                result(try SharedWidgetStore.writeCalendar(json))
            case "readAppearance": result(try SharedWidgetStore.readAppearance())
            case "writeAppearance":
                guard let json = call.arguments as? String else {
                    result(FlutterError(code: "invalid_arguments", message: nil, details: nil))
                    return
                }
                try SharedWidgetStore.writeAppearance(json)
                WidgetCenter.shared.reloadTimelines(ofKind: "ShiyuRetirement")
                result(nil)
            case "refresh":
                WidgetCenter.shared.reloadTimelines(ofKind: "ShiyuRetirement")
                result(nil)
            case "pin": result(false)
            default: result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "shared_storage_unavailable", message: "Check App Group entitlements", details: nil))
        }
    }
}
