import Foundation

struct StoreDirectoryEntry: Identifiable, Codable, Hashable {
    var storeKey: String
    var displayName: String
    var enabled: Bool

    var id: String { storeKey }

    enum CodingKeys: String, CodingKey {
        case storeKey = "store_key"
        case displayName = "display_name"
        case enabled
    }
}

enum StoreURL {
    static let urlBackedKeys = ["amazon", "target", "walmart"]
    static let urlBackedKeySet = Set(urlBackedKeys)

    static let fallbackDirectory: [StoreDirectoryEntry] = [
        StoreDirectoryEntry(storeKey: "amazon", displayName: "Amazon", enabled: true),
        StoreDirectoryEntry(storeKey: "target", displayName: "Target", enabled: true),
        StoreDirectoryEntry(storeKey: "walmart", displayName: "Walmart", enabled: true),
    ]

    static let unknownHostMessage = "Amazon, Target, or Walmart URLs for now."

    static func checklist(from directory: [StoreDirectoryEntry]) -> [StoreDirectoryEntry] {
        let enabled = directory.filter { $0.enabled && urlBackedKeySet.contains($0.storeKey) }
        if enabled.isEmpty { return fallbackDirectory }
        return urlBackedKeys.compactMap { key in enabled.first { $0.storeKey == key } }
    }

    static func encode(_ keys: [String]) -> String {
        var seen = Set<String>()
        var ordered: [String] = []
        for raw in keys {
            let key = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard urlBackedKeySet.contains(key), !seen.contains(key) else { continue }
            seen.insert(key)
            ordered.append(key)
        }
        return ordered.joined(separator: ",")
    }

    static func decode(_ stores: String) -> [String] {
        stores.split(separator: ",").compactMap { part in
            let key = part.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return key.isEmpty ? nil : key
        }
    }

    static func normalizedURLString(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        if trimmed.contains("://") { return trimmed }
        return "https://\(trimmed)"
    }

    static func storeKey(from raw: String) -> String? {
        let value = normalizedURLString(raw)
        guard !value.isEmpty, let url = URL(string: value), let host = url.host?.lowercased() else {
            return nil
        }
        if host == "amzn.to" || host.hasSuffix(".amzn.to") { return "amazon" }
        if host == "amazon.com" || host.hasSuffix(".amazon.com") { return "amazon" }
        if host == "target.com" || host.hasSuffix(".target.com") { return "target" }
        if host == "walmart.com" || host.hasSuffix(".walmart.com") { return "walmart" }
        return nil
    }

    static func displayName(for storeKey: String, directory: [StoreDirectoryEntry]) -> String {
        if let match = directory.first(where: { $0.storeKey == storeKey }) {
            return match.displayName
        }
        switch storeKey {
        case "amazon": return "Amazon"
        case "target": return "Target"
        case "walmart": return "Walmart"
        default: return storeKey
        }
    }

    /// Empty URLs are allowed. Non-empty URLs must match the expected store host.
    static func invalidURLMessage(
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) -> String? {
        let pairs: [(String?, String)] = [
            (amazonURL, "amazon"),
            (targetURL, "target"),
            (walmartURL, "walmart"),
        ]
        for (raw, expected) in pairs {
            let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !trimmed.isEmpty else { continue }
            guard let key = storeKey(from: trimmed), key == expected else {
                return unknownHostMessage
            }
        }
        return nil
    }
}
