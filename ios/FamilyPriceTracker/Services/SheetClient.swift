import Foundation

enum SheetClientError: Error, LocalizedError {
    case empty
    case loadFailed(String)

    var errorDescription: String? {
        switch self {
        case .empty:
            return "No wishlist items yet."
        case .loadFailed(let message):
            return message
        }
    }
}

/// Seam for Sheet-backed item loads. Sample stub today; OAuth Sheets later.
protocol SheetClient {
    func fetchItems() throws -> [WishlistItem]
}

struct SampleSheetClient: SheetClient {
    func fetchItems() throws -> [WishlistItem] {
        guard
            let url = Bundle.main.url(forResource: "sample_items", withExtension: "json")
        else {
            throw SheetClientError.loadFailed("Sample wishlist file is missing from the app bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([WishlistItem].self, from: data)
            if items.isEmpty {
                throw SheetClientError.empty
            }
            return items
        } catch let error as SheetClientError {
            throw error
        } catch {
            throw SheetClientError.loadFailed("Could not read sample wishlist.")
        }
    }
}
