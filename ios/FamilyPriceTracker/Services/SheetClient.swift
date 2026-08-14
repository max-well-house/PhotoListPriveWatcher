import Foundation

enum SheetClientError: Error, LocalizedError, Equatable {
    case empty
    case loadFailed(String)
    case saveFailed(String)
    case unknownListOwner(String)
    case invalidItem(String)
    case notFound(String)
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .empty:
            return "No wishlist items yet."
        case .loadFailed(let message), .saveFailed(let message), .invalidItem(let message):
            return message
        case .unknownListOwner(let owner):
            return "“\(owner)” is not a Config list owner. Pick a list from Config."
        case .notFound(let itemId):
            return "Item not found: \(itemId)"
        case .notSignedIn:
            return "Sign in with Google to read and write the family Sheet (v0.9.1 Mac session)."
        }
    }
}

/// Seam for Sheet-backed loads and item CRUD. Sample stub today; live OAuth in v0.9.1.
@MainActor
protocol SheetClient: AnyObject {
    func fetchItems() async throws -> [WishlistItem]
    func fetchListOwners() async throws -> [String]
    func fetchStores() async throws -> [StoreDirectoryEntry]
    func createTextItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String
    ) async throws -> WishlistItem
    func createTrackedItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String,
        storeKeys: [String],
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) async throws -> WishlistItem
    func updateItem(_ item: WishlistItem) async throws
}

/// In-memory overlay on bundled sample JSON so add/edit works without Xcode/OAuth.
@MainActor
final class SampleSheetClient: SheetClient {
    private var items: [WishlistItem] = []
    private var owners: [String] = []
    private var stores: [StoreDirectoryEntry] = []
    private var didLoadItems = false
    private var didLoadOwners = false
    private var didLoadStores = false

    func fetchItems() async throws -> [WishlistItem] {
        try loadItemsIfNeeded()
        return items
    }

    func fetchListOwners() async throws -> [String] {
        try loadOwnersIfNeeded()
        return owners
    }

    func fetchStores() async throws -> [StoreDirectoryEntry] {
        try loadStoresIfNeeded()
        return stores
    }

    func createTextItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String
    ) async throws -> WishlistItem {
        try loadItemsIfNeeded()
        try loadOwnersIfNeeded()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SheetClientError.invalidItem("Name is required.")
        }
        try requireOwner(listOwner)
        let created = WishlistItem.makeText(
            name: trimmed,
            notes: notes,
            priority: priority,
            listOwner: listOwner
        )
        items.append(created)
        return created
    }

    func createTrackedItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String,
        storeKeys: [String],
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) async throws -> WishlistItem {
        try loadItemsIfNeeded()
        try loadOwnersIfNeeded()
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SheetClientError.invalidItem("Name is required.")
        }
        try requireOwner(listOwner)
        if let message = StoreURL.invalidURLMessage(
            amazonURL: amazonURL,
            targetURL: targetURL,
            walmartURL: walmartURL
        ) {
            throw SheetClientError.invalidItem(message)
        }
        let created = WishlistItem.makeTracked(
            name: trimmed,
            notes: notes,
            priority: priority,
            listOwner: listOwner,
            storeKeys: storeKeys,
            amazonURL: amazonURL,
            targetURL: targetURL,
            walmartURL: walmartURL
        )
        guard created.hasAnyStoreURL, !created.storeKeys.isEmpty else {
            throw SheetClientError.invalidItem("Pick at least one store and paste a product URL.")
        }
        items.append(created)
        return created
    }

    func updateItem(_ item: WishlistItem) async throws {
        try loadItemsIfNeeded()
        try loadOwnersIfNeeded()
        try requireOwner(item.listOwner)
        guard ItemStatus(rawValue: item.status) != nil else {
            throw SheetClientError.invalidItem("Status must be wanted, purchased, or dropped.")
        }
        if let message = StoreURL.invalidURLMessage(
            amazonURL: item.amazonURL,
            targetURL: item.targetURL,
            walmartURL: item.walmartURL
        ) {
            throw SheetClientError.invalidItem(message)
        }
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw SheetClientError.notFound(item.id)
        }
        var updated = items[index]
        updated.notes = item.notes
        updated.priority = ItemPriority.clamp(item.priority)
        updated.listOwner = item.listOwner
        updated.status = item.status
        updated.stores = StoreURL.encode(item.storeKeys)
        updated.amazonURL = item.amazonURL
        updated.targetURL = item.targetURL
        updated.walmartURL = item.walmartURL
        if item.type == "tracked" || item.hasAnyStoreURL {
            updated.type = "tracked"
        } else {
            updated.type = item.type
        }
        items[index] = updated
    }

    private func requireOwner(_ owner: String) throws {
        guard owners.contains(owner) else {
            throw SheetClientError.unknownListOwner(owner)
        }
    }

    private func loadItemsIfNeeded() throws {
        guard !didLoadItems else { return }
        guard
            let url = Bundle.main.url(forResource: "sample_items", withExtension: "json")
        else {
            throw SheetClientError.loadFailed("Sample wishlist file is missing from the app bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            items = try JSONDecoder().decode([WishlistItem].self, from: data)
            didLoadItems = true
        } catch let error as SheetClientError {
            throw error
        } catch {
            throw SheetClientError.loadFailed("Could not read sample wishlist.")
        }
    }

    private func loadOwnersIfNeeded() throws {
        guard !didLoadOwners else { return }
        if let url = Bundle.main.url(forResource: "sample_owners", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([String].self, from: data),
           !decoded.isEmpty
        {
            owners = decoded
        } else {
            owners = ["Me", "Spouse", "Kid A", "Kid B", "Shared"]
        }
        didLoadOwners = true
    }

    private func loadStoresIfNeeded() throws {
        guard !didLoadStores else { return }
        if let url = Bundle.main.url(forResource: "sample_stores", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([StoreDirectoryEntry].self, from: data),
           !decoded.isEmpty
        {
            stores = decoded
        } else {
            stores = StoreURL.fallbackDirectory
        }
        didLoadStores = true
    }
}
