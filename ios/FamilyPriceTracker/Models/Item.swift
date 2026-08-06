import Foundation

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
}
