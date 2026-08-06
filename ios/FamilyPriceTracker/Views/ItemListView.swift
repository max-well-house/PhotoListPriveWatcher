import SwiftUI

struct ItemListView: View {
    @State private var items: [WishlistItem] = SampleData.load()
    @State private var ownerFilter: String = "All"

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
                items = SampleData.load()
            }
        }
    }
}

enum SampleData {
    static func load() -> [WishlistItem] {
        guard
            let url = Bundle.main.url(forResource: "sample_items", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([WishlistItem].self, from: data)
        else {
            return [
                WishlistItem(
                    id: "sample-text-001",
                    name: "pajamas",
                    listOwner: "Kid A",
                    priority: 2,
                    type: "text",
                    notes: "soft cotton preferred",
                    status: "wanted",
                    amazonPrice: nil,
                    amazonURL: nil
                ),
                WishlistItem(
                    id: "sample-tracked-001",
                    name: "Example tracked item",
                    listOwner: "Me",
                    priority: 1,
                    type: "tracked",
                    notes: "demo row",
                    status: "wanted",
                    amazonPrice: "19.99",
                    amazonURL: "https://www.amazon.com/dp/B0D1XD1ZV3"
                ),
            ]
        }
        return decoded
    }
}
