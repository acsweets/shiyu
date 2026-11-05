import Foundation

// 主应用和扩展使用同一 App Group；不回退到互不可见的私有目录。
enum SharedWidgetStore {
    /// 发布主体需在开发者账号中启用相同 App Group。
    static let group = "group.com.growthrecord.shiyu"

    static func readAppearance() throws -> String? {
        try read("widget_appearance.json")
    }

    static func writeAppearance(_ text: String) throws {
        try write(text, name: "widget_appearance.json")
    }

    private static func url(_ name: String) throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw NSError(domain: "ShiyuSharedStore", code: 1)
        }
        return container.appendingPathComponent(name)
    }

    static func read(_ name: String = "settings.json") throws -> String? {
        let file = try url(name)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard ((attributes[.size] as? NSNumber)?.intValue ?? 0) <= 131072 else {
            throw NSError(domain: "ShiyuSharedStore", code: 2)
        }
        return try String(contentsOf: file, encoding: .utf8)
    }

    static func write(_ text: String, name: String = "settings.json") throws {
        let data = Data(text.utf8)
        guard data.count <= 131072 else { throw NSError(domain: "ShiyuSharedStore", code: 2) }
        try data.write(to: url(name), options: .atomic)
    }
}
