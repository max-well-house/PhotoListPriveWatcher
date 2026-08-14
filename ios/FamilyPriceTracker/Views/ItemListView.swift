import SwiftUI

enum StatusFilter: String, CaseIterable, Identifiable {
    case wanted
    case all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .wanted: return "Wanted"
        case .all: return "All"
        }
    }
}

struct ItemListView: View {
    @EnvironmentObject private var store: WishlistStore
    @State private var ownerFilter: String = "All"
    @State private var statusFilter: StatusFilter = .wanted
    @State private var showingAddMenu = false
    @State private var showingAddText = false
    @State private var showingAddURL = false

    private var owners: [String] {
        let fromConfig = store.listOwners
        if fromConfig.isEmpty {
            let set = Set(store.items.map(\.listOwner))
            return ["All"] + set.sorted()
        }
        return ["All"] + fromConfig
    }

    private var filtered: [WishlistItem] {
        var base = store.items
        if ownerFilter != "All" {
            base = base.filter { $0.listOwner == ownerFilter }
        }
        if statusFilter == .wanted {
            base = base.filter { $0.status == ItemStatus.wanted.rawValue }
        }
        return base.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private var emptyDescription: String {
        if store.items.isEmpty {
            return "Add a text item or paste a product URL to start the family wishlist."
        }
        if statusFilter == .wanted, ownerFilter == "All" {
            return "No wanted items. Switch status to All to see purchased or dropped."
        }
        if ownerFilter != "All" {
            return "No items for this list. Try All or another owner."
        }
        return "Nothing matches these filters."
    }

    var body: some View {
        NavigationStack {
            Group {
                if let loadError = store.loadError {
                    ContentUnavailableView(
                        "Couldn’t load wishlist",
                        systemImage: "exclamationmark.triangle",
                        description: Text(loadError)
                    )
                } else if store.didLoad && filtered.isEmpty {
                    ContentUnavailableView(
                        "No items",
                        systemImage: "list.bullet",
                        description: Text(emptyDescription)
                    )
                } else {
                    List(filtered) { item in
                        NavigationLink(value: item.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name).font(.headline)
                                Text("P\(item.priority) · \(item.listOwner) · \(item.status)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if let summary = priceSummary(item) {
                                    Text(summary)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist")
            .navigationDestination(for: String.self) { id in
                ItemDetailView(itemId: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Picker("Status", selection: $statusFilter) {
                        ForEach(StatusFilter.allCases) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("List", selection: $ownerFilter) {
                        ForEach(owners, id: \.self) { Text($0).tag($0) }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddMenu = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                    .confirmationDialog("Add", isPresented: $showingAddMenu, titleVisibility: .visible) {
                        Button("Text item") { showingAddText = true }
                        Button("From product URL") { showingAddURL = true }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .sheet(isPresented: $showingAddText) {
                NavigationStack {
                    AddTextItemView(isPresented: $showingAddText)
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $showingAddURL) {
                NavigationStack {
                    AddURLItemView(isPresented: $showingAddURL)
                }
                .environmentObject(store)
            }
            .refreshable {
                await store.reload()
            }
            .task {
                if !store.didLoad {
                    await store.reload()
                }
            }
        }
    }

    private func priceSummary(_ item: WishlistItem) -> String? {
        for key in StoreURL.urlBackedKeys {
            if let price = item.price(for: key), !price.isEmpty {
                let label = StoreURL.displayName(for: key, directory: store.storeDirectory)
                return "\(label) $\(price)"
            }
        }
        return nil
    }
}
