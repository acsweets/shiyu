import Foundation

// 主应用和扩展使用同一 App Group；不回退到互不可见的私有目录。
enum SharedWidgetStore {
    /// 发布主体需在开发者账号中启用相同 App Group。
    static let group = "group.com.growthrecord.shiyu"

    static func url() throws -> URL {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            throw NSError(domain: "ShiyuSharedStore", code: 1)
        }
        return container.appendingPathComponent("settings.json")
    }

    static func read() throws -> String? {
        let file = try url()
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
        guard ((attributes[.size] as? NSNumber)?.intValue ?? 0) <= 131072 else {
            throw NSError(domain: "ShiyuSharedStore", code: 2)
        }
        return try String(contentsOf: file, encoding: .utf8)
    }

    static func write(_ text: String) throws {
        let data = Data(text.utf8)
        guard data.count <= 131072 else { throw NSError(domain: "ShiyuSharedStore", code: 2) }
        try data.write(to: url(), options: .atomic)
    }
}
