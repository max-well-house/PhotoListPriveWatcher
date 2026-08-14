import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject private var store: WishlistStore
    let itemId: String

    @State private var notes: String = ""
    @State private var priority: Int = ItemPriority.default
    @State private var listOwner: String = ""
    @State private var status: String = ItemStatus.wanted.rawValue
    @State private var didHydrate = false
    @State private var isSaving = false
    @State private var saveError: String?

    private var item: WishlistItem? {
        store.item(id: itemId)
    }

    private var ownerChoices: [String] {
        var owners = store.listOwners
        if !listOwner.isEmpty, !owners.contains(listOwner) {
            owners.append(listOwner)
        }
        return owners
    }

    private var isDirty: Bool {
        guard let item else { return false }
        return notes != item.notes
            || priority != item.priority
            || listOwner != item.listOwner
            || status != item.status
    }

    var body: some View {
        Group {
            if let item {
                List {
                    Section("Details") {
                        LabeledContent("Name", value: item.name)
                        Picker("List", selection: $listOwner) {
                            ForEach(ownerChoices, id: \.self) { owner in
                                Text(owner).tag(owner)
                            }
                        }
                        .disabled(store.listOwners.isEmpty)
                        Picker("Priority", selection: $priority) {
                            ForEach(Array(ItemPriority.range), id: \.self) { value in
                                Text(ItemPriority.label(value)).tag(value)
                            }
                        }
                        LabeledContent("Type", value: item.type)
                        Picker("Status", selection: $status) {
                            ForEach(ItemStatus.allCases) { value in
                                Text(value.label).tag(value.rawValue)
                            }
                        }
                        TextField("Notes", text: $notes, axis: .vertical)
                            .lineLimit(3 ... 10)
                    }
                    Section("Prices") {
                        if let urlString = item.amazonURL, let url = URL(string: urlString) {
                            Link(destination: url) {
                                HStack {
                                    Text("Amazon")
                                    Spacer()
                                    if let price = item.amazonPrice, !price.isEmpty {
                                        Text("$\(price)")
                                    } else {
                                        Text("Open")
                                    }
                                }
                            }
                        } else {
                            Text("Not checked")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle(item.name)
            } else {
                ContentUnavailableView(
                    "Item unavailable",
                    systemImage: "questionmark.circle",
                    description: Text("This item is no longer in the list.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(!isDirty || isSaving || store.listOwners.isEmpty)
            }
        }
        .alert("Couldn’t save", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .onAppear { hydrateIfNeeded() }
    }

    private func hydrateIfNeeded(force: Bool = false) {
        guard let item else { return }
        guard force || !didHydrate else { return }
        notes = item.notes
        priority = item.priority
        listOwner = item.listOwner
        status = item.status
        didHydrate = true
    }

    private func save() async {
        guard var item else { return }
        isSaving = true
        defer { isSaving = false }
        item.notes = notes
        item.priority = priority
        item.listOwner = listOwner
        item.status = status
        do {
            try await store.save(item)
            didHydrate = false
            hydrateIfNeeded(force: true)
        } catch let error as SheetClientError {
            saveError = error.errorDescription
        } catch {
            saveError = "Could not save changes."
        }
    }
}
