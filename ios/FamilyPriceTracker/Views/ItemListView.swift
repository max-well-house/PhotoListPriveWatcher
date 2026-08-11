import SwiftUI

struct ItemListView: View {
    private let client: SheetClient
    @State private var items: [WishlistItem] = []
    @State private var ownerFilter: String = "All"
    @State private var loadError: String?
    @State private var didLoad = false

    init(client: SheetClient = SampleSheetClient()) {
        self.client = client
    }

    private var owners: [String] {
        let set = Set(items.map(\.listOwner))
        return ["All"] + set.sorted()
    }

    private var filtered: [WishlistItem] {
        let base = ownerFilter == "All" ? items : items.filter { $0.listOwner == ownerFilter }
        return base.sorted { $0.priority < $1.priority }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let loadError {
                    ContentUnavailableView(
                        "Couldn’t load wishlist",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if didLoad && filtered.isEmpty {
                    ContentUnavailableView(
                        "No items",
                        systemImage: "list.bullet",
                        description: Text(
                            ownerFilter == "All"
                                ? "Add items in the Google Sheet, then refresh."
                                : "No items for this list. Try All or another owner."
                        )
                    )
                } else {
                    List(filtered) { item in
                        NavigationLink(value: item) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.headline)
                                Text("P\(item.priority) · \(item.listOwner) · \(item.type)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let price = item.amazonPrice, !price.isEmpty {
                                    Text("Amazon $\(price)")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .navigationDestination(for: WishlistItem.self) { item in
                ItemDetailView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("List", selection: $ownerFilter) {
                        ForEach(owners, id: \.self) { Text($0).tag($0) }
                    }
                }
            }
            .refreshable {
                reload()
            }
            .task {
                if !didLoad {
                    reload()
                }
            }
        }
    }

    private func reload() {
        do {
            items = try client.fetchItems()
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
}
