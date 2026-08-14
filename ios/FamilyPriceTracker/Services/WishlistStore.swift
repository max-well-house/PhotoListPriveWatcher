import Combine
import Foundation

@MainActor
final class WishlistStore: ObservableObject {
    let client: any SheetClient

    @Published private(set) var items: [WishlistItem] = []
    @Published private(set) var listOwners: [String] = []
    @Published private(set) var storeDirectory: [StoreDirectoryEntry] = []
    @Published var loadError: String?
    @Published private(set) var didLoad = false

    init(client: any SheetClient) {
        self.client = client
    }

    var checklistStores: [StoreDirectoryEntry] {
        StoreURL.checklist(from: storeDirectory)
    }

    func item(id: String) -> WishlistItem? {
        items.first { $0.id == id }
    }

    func reload() async {
        do {
            items = try await client.fetchItems()
            listOwners = try await client.fetchListOwners()
            storeDirectory = try await client.fetchStores()
            loadError = nil
        } catch let error as SheetClientError {
            items = []
            loadError = error.errorDescription
        } catch {
            items = []
            loadError = "Could not load wishlist."
        }
        didLoad = true
    }

    func addTextItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String
    ) async throws {
        _ = try await client.createTextItem(
            name: name,
            notes: notes,
            priority: priority,
            listOwner: listOwner
        )
        await reload()
    }

    func addTrackedItem(
        name: String,
        notes: String,
        priority: Int,
        listOwner: String,
        storeKeys: [String],
        amazonURL: String?,
        targetURL: String?,
        walmartURL: String?
    ) async throws {
        _ = try await client.createTrackedItem(
            name: name,
            notes: notes,
            priority: priority,
            listOwner: listOwner,
            storeKeys: storeKeys,
            amazonURL: amazonURL,
            targetURL: targetURL,
            walmartURL: walmartURL
        )
        await reload()
    }

    func save(_ item: WishlistItem) async throws {
        try await client.updateItem(item)
        await reload()
    }
}
