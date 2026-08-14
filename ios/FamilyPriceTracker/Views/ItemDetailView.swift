import SwiftUI

struct ItemDetailView: View {
    @EnvironmentObject private var store: WishlistStore
    let itemId: String

    @State private var notes: String = ""
    @State private var priority: Int = ItemPriority.default
    @State private var listOwner: String = ""
    @State private var status: String = ItemStatus.wanted.rawValue
    @State private var selectedStores: Set<String> = []
    @State private var amazonURLText: String = ""
    @State private var targetURLText: String = ""
    @State private var walmartURLText: String = ""
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

    private var detailStores: [StoreDirectoryEntry] {
        var byKey: [String: StoreDirectoryEntry] = [:]
        for entry in store.checklistStores {
            byKey[entry.storeKey] = entry
        }
        for key in selectedStores where byKey[key] == nil && StoreURL.urlBackedKeySet.contains(key) {
            byKey[key] = StoreDirectoryEntry(
                storeKey: key,
                displayName: StoreURL.displayName(for: key, directory: store.storeDirectory),
                enabled: true
            )
        }
        return StoreURL.urlBackedKeys.compactMap { byKey[$0] }
    }

    private var isDirty: Bool {
        guard let item else { return false }
        return notes != item.notes
            || priority != item.priority
            || listOwner != item.listOwner
            || status != item.status
            || selectedStores != Set(item.storeKeys)
            || trimmed(amazonURLText) != (item.amazonURL ?? "")
            || trimmed(targetURLText) != (item.targetURL ?? "")
            || trimmed(walmartURLText) != (item.walmartURL ?? "")
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
                    Section("Stores") {
                        if detailStores.isEmpty {
                            Text("No stores in Config. Add Amazon, Target, or Walmart on the Config tab.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(detailStores) { entry in
                                Toggle(entry.displayName, isOn: storeBinding(for: entry.storeKey))
                            }
                        }
                    }
                    Section("Prices") {
                        ForEach(detailStores) { entry in
                            storePriceRow(entry, item: item)
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

    @ViewBuilder
    private func storePriceRow(_ entry: StoreDirectoryEntry, item: WishlistItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("\(entry.displayName) URL", text: urlBinding(for: entry.storeKey))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            if let urlString = liveURL(for: entry.storeKey), let url = URL(string: urlString) {
                Link(destination: url) {
                    HStack {
                        Text(entry.displayName)
                        Spacer()
                        if let price = item.price(for: entry.storeKey), !price.isEmpty {
                            Text("$\(price)")
                        } else {
                            Text("Open")
                        }
                    }
                }
            } else if selectedStores.contains(entry.storeKey) {
                Text("Not checked")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func hydrateIfNeeded(force: Bool = false) {
        guard let item else { return }
        guard force || !didHydrate else { return }
        notes = item.notes
        priority = item.priority
        listOwner = item.listOwner
        status = item.status
        selectedStores = Set(item.storeKeys)
        amazonURLText = item.amazonURL ?? ""
        targetURLText = item.targetURL ?? ""
        walmartURLText = item.walmartURL ?? ""
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
        item.amazonURL = optionalURL(amazonURLText)
        item.targetURL = optionalURL(targetURLText)
        item.walmartURL = optionalURL(walmartURLText)
        item.stores = StoreURL.encode(
            StoreURL.urlBackedKeys.filter { selectedStores.contains($0) }
        )
        if item.hasAnyStoreURL {
            item.type = "tracked"
        }
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

    private func storeBinding(for storeKey: String) -> Binding<Bool> {
        Binding(
            get: { selectedStores.contains(storeKey) },
            set: { on in
                if on {
                    selectedStores.insert(storeKey)
                } else {
                    selectedStores.remove(storeKey)
                }
            }
        )
    }

    private func urlBinding(for storeKey: String) -> Binding<String> {
        Binding(
            get: {
                switch storeKey {
                case "amazon": return amazonURLText
                case "target": return targetURLText
                case "walmart": return walmartURLText
                default: return ""
                }
            },
            set: { value in
                switch storeKey {
                case "amazon": amazonURLText = value
                case "target": targetURLText = value
                case "walmart": walmartURLText = value
                default: break
                }
                if StoreURL.storeKey(from: value) == storeKey {
                    selectedStores.insert(storeKey)
                }
            }
        )
    }

    private func liveURL(for storeKey: String) -> String? {
        let raw: String
        switch storeKey {
        case "amazon": raw = amazonURLText
        case "target": raw = targetURLText
        case "walmart": raw = walmartURLText
        default: return nil
        }
        let value = StoreURL.normalizedURLString(raw)
        return value.isEmpty ? nil : value
    }

    private func optionalURL(_ raw: String) -> String? {
        let value = StoreURL.normalizedURLString(raw)
        return value.isEmpty ? nil : value
    }

    private func trimmed(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
