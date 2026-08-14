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
    var amazonPrice: String?
    var amazonURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name, notes, status, priority, type
        case listOwner = "list_owner"
        case amazonPrice = "amazon_price"
        case amazonURL = "amazon_url"
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
            status: ItemStatus.wanted.rawValue,
            amazonPrice: nil,
            amazonURL: nil
        )
    }
}
