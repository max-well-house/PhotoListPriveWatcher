import Foundation

enum ItemStatus: String, CaseIterable, Identifiable {
    case wanted
    case purchased
    case dropped

    var id: String { rawValue }

    var label: String { rawValue }
}

enum ItemPriority {
    static let range = 1 ... 5
    static let `default` = 3

    static func clamp(_ value: Int) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }

    static func label(_ value: Int) -> String {
        switch value {
        case 1: return "1 (highest)"
        case 5: return "5 (lowest)"
        default: return "\(value)"
        }
    }
}

struct WishlistItem: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var listOwner: String
    var priority: Int
    var type: String
    var notes: String
    var status: String
    var stores: String
    var amazonPrice: String?
    var amazonURL: String?
    var targetPrice: String?
    var targetURL: String?
    var walmartPrice: String?
    var walmartURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, notes, status, priority, type, stores
        case listOwner = "list_owner"
        case amazonPrice = "amazon_price"
        case amazonURL = "amazon_url"
        case targetPrice = "target_price"
        case targetURL = "target_url"
        case walmartPrice = "walmart_price"
        case walmartURL = "walmart_url"
    }

    init(
        id: String,
        name: String,
        listOwner: String,
        priority: Int,
        type: String,
        notes: String,
        status: String,
        stores: String = "",
        amazonPrice: String? = nil,
        amazonURL: String? = nil,
        targetPrice: String? = nil,
        targetURL: String? = nil,
        walmartPrice: String? = nil,
        walmartURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.listOwner = listOwner
        self.priority = priority
        self.type = type
        self.notes = notes
        self.status = status
        self.stores = stores
        self.amazonPrice = amazonPrice
        self.amazonURL = amazonURL
        self.targetPrice = targetPrice
        self.targetURL = targetURL
        self.walmartPrice = walmartPrice
        self.walmartURL = walmartURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        listOwner = try c.decode(String.self, forKey: .listOwner)
        priority = try c.decode(Int.self, forKey: .priority)
        type = try c.decode(String.self, forKey: .type)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? ItemStatus.wanted.rawValue
        stores = try c.decodeIfPresent(String.self, forKey: .stores) ?? ""
        amazonPrice = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .amazonPrice))
        amazonURL = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .amazonURL))
        targetPrice = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .targetPrice))
        targetURL = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .targetURL))
        walmartPrice = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .walmartPrice))
        walmartURL = Self.optionalString(try c.decodeIfPresent(String.self, forKey: .walmartURL))
    }

    var storeKeys: [String] {
        StoreURL.decode(stores)
    }

    var hasAnyStoreURL: Bool {
        StoreURL.urlBackedKeys.contains { url(for: $0) != nil }
    }

    func url(for storeKey: String) -> String? {
        switch storeKey {
        case "amazon": return Self.optionalString(amazonURL)
        case "target": return Self.optionalString(targetURL)
        case "walmart": return Self.optionalString(walmartURL)
        default: return nil
        }
    }

    func price(for storeKey: String) -> String? {
        switch storeKey {
        case "amazon": return Self.optionalString(amazonPrice)
        case "target": return Self.optionalString(targetPrice)
        case "walmart": return Self.optionalString(walmartPrice)
        default: return nil
        }
    }

    mutating func setURL(_ raw: String?, for storeKey: String) {
        let value = Self.optionalString(raw)
        switch storeKey {
        case "amazon": amazonURL = value
        case "target": targetURL = value
        case "walmart": walmartURL = value
        default: break
        }
    }

    static func makeText(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String
    ) -> WishlistItem {
        WishlistItem(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            listOwner: listOwner,
            priority: ItemPriority.clamp(priority),
            type: "text",
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            status: ItemStatus.wanted.rawValue
        )
    }

    static func makeTracked(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String,
        storeKeys: [String],
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) -> WishlistItem {
        var keys = storeKeys
        if let key = StoreURL.storeKey(from: amazonURL ?? "") { keys.append(key) }
        if let key = StoreURL.storeKey(from: targetURL ?? "") { keys.append(key) }
        if let key = StoreURL.storeKey(from: walmartURL ?? "") { keys.append(key) }
        return WishlistItem(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            listOwner: listOwner,
            priority: ItemPriority.clamp(priority),
            type: "tracked",
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            status: ItemStatus.wanted.rawValue,
            stores: StoreURL.encode(keys),
            amazonURL: optionalString(amazonURL),
            targetURL: optionalString(targetURL),
            walmartURL: optionalString(walmartURL)
        )
    }

    private static func optionalString(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
