import Foundation
import CryptoKit

// 主应用和扩展使用同一 App Group；不回退到互不可见的私有目录。
enum SharedWidgetStore {
    /// 发布主体需在开发者账号中启用相同 App Group。
    static let group = "group.com.growthrecord.shiyu"
    private static let calendarRegions = Set(["CN", "US", "JP", "KR", "HK", "TW"])

    static func writeSettings(_ text: String) throws {
        try write(text)
        try? write(text, name: "settings.last-good.json")
    }

    static func readLastGoodSettings() throws -> String? {
        try read("settings.last-good.json")
    }

    static func readCalendar(region: String) -> String? {
        calendar(region: region)?.calendar
    }

    static func writeCalendar(_ raw: String) throws -> Bool {
        let next = try decodeCalendar(raw)
        guard (calendar(region: next.region)?.version ?? 0) < next.version else { return false }
        let name = "calendar-\(next.region).json"
        try write(raw, name: name)
        try? write(raw, name: "\(name).bak")
        return true
    }

    private static func calendar(region: String) -> CalendarEnvelope? {
        guard calendarRegions.contains(region) else { return nil }
        let name = "calendar-\(region).json"
        for candidate in [name, "\(name).bak"] {
            if let raw = try? read(candidate), let value = try? decodeCalendar(raw), value.region == region {
                return value
            }
        }
        return nil
    }

    private struct CalendarEnvelope: Decodable {
        let schema_version: Int
        let version: Int64
        let region: String
        let calendar: String
        let sha256: String
    }

    private struct CalendarIdentity: Decodable {
        let schema_version: Int
        let region: String
    }

    private static func decodeCalendar(_ raw: String) throws -> CalendarEnvelope {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(CalendarEnvelope.self, from: Data(raw.utf8))
        let calendar = Data(envelope.calendar.utf8)
        let identity = try decoder.decode(CalendarIdentity.self, from: calendar)
        let hash = SHA256.hash(data: calendar).map { String(format: "%02x", $0) }.joined()
        guard envelope.schema_version == 1, envelope.version > 0,
              calendarRegions.contains(envelope.region),
              identity.schema_version == 1, identity.region == envelope.region,
              hash == envelope.sha256 else {
            throw NSError(domain: "ShiyuSharedStore", code: 3)
        }
        return envelope
    }

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
