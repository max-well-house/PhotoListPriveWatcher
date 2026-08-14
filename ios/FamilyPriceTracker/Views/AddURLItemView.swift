import SwiftUI

struct AddURLItemView: View {
    @EnvironmentObject private var store: WishlistStore
    @Binding var isPresented: Bool

    @State private var urlText: String = ""
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var priority: Int = ItemPriority.default
    @State private var listOwner: String = ""
    @State private var selectedStores: Set<String> = []
    @State private var showingConfirm = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedURL: String {
        urlText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var detectedStore: String? {
        StoreURL.storeKey(from: trimmedURL)
    }

    private var urlHint: String? {
        if trimmedURL.isEmpty { return nil }
        if detectedStore == nil { return StoreURL.unknownHostMessage }
        return nil
    }

    private var amazonURL: String? { url(for: "amazon") }
    private var targetURL: String? { url(for: "target") }
    private var walmartURL: String? { url(for: "walmart") }

    private var canContinue: Bool {
        !trimmedName.isEmpty
            && store.listOwners.contains(listOwner)
            && detectedStore != nil
            && !selectedStores.isEmpty
    }

    var body: some View {
        Form {
            Section("Product URL") {
                TextField("https://www.amazon.com/dp/…", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                if let urlHint {
                    Text(urlHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Section("Item") {
                TextField("Name", text: $name)
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3 ... 8)
            }
            Section("List") {
                if store.listOwners.isEmpty {
                    Text("No list owners in Config. Add owners on the Config tab, then refresh.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Owner", selection: $listOwner) {
                        ForEach(store.listOwners, id: \.self) { owner in
                            Text(owner).tag(owner)
                        }
                    }
                }
                Picker("Priority", selection: $priority) {
                    ForEach(Array(ItemPriority.range), id: \.self) { value in
                        Text(ItemPriority.label(value)).tag(value)
                    }
                }
            }
            Section("Stores") {
                ForEach(store.checklistStores) { entry in
                    Toggle(entry.displayName, isOn: binding(for: entry.storeKey))
                }
                Text("Checked stores are the ones the worker will refresh. Extra stores can wait for a URL later.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("From URL")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { isPresented = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") { showingConfirm = true }
                    .disabled(!canContinue)
            }
        }
        .navigationDestination(isPresented: $showingConfirm) {
            ConfirmAddURLItemView(
                isPresented: $isPresented,
                name: trimmedName,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                listOwner: listOwner,
                storeKeys: StoreURL.urlBackedKeys.filter { selectedStores.contains($0) },
                productURL: StoreURL.normalizedURLString(trimmedURL),
                amazonURL: amazonURL,
                targetURL: targetURL,
                walmartURL: walmartURL
            )
        }
        .onAppear {
            if listOwner.isEmpty {
                if store.listOwners.contains("Me") {
                    listOwner = "Me"
                } else {
                    listOwner = store.listOwners.first ?? ""
                }
            }
        }
        .onChange(of: urlText) { _, _ in
            if let detectedStore {
                selectedStores.insert(detectedStore)
            }
        }
    }

    private func url(for storeKey: String) -> String? {
        guard detectedStore == storeKey else { return nil }
        let value = StoreURL.normalizedURLString(trimmedURL)
        return value.isEmpty ? nil : value
    }

    private func binding(for storeKey: String) -> Binding<Bool> {
        Binding(
            get: { selectedStores.contains(storeKey) },
            set: { on in
                if let detectedStore, storeKey == detectedStore {
                    selectedStores.insert(storeKey)
                    return
                }
                if on {
                    selectedStores.insert(storeKey)
                } else {
                    selectedStores.remove(storeKey)
                }
            }
        )
    }
}

struct ConfirmAddURLItemView: View {
    @EnvironmentObject private var store: WishlistStore
    @Binding var isPresented: Bool

    let name: String
    let notes: String
    let priority: Int
    let listOwner: String
    let storeKeys: [String]
    let productURL: String
    let amazonURL: String?
    let targetURL: String?
    let walmartURL: String?

    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        List {
            Section("Confirm") {
                LabeledContent("Name", value: name)
                LabeledContent("List", value: listOwner)
                LabeledContent("Priority", value: ItemPriority.label(priority))
                LabeledContent("URL", value: productURL)
                LabeledContent(
                    "Stores",
                    value: storeKeys.map {
                        StoreURL.displayName(for: $0, directory: store.storeDirectory)
                    }.joined(separator: ", ")
                )
                if notes.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                } else {
                    Text(notes)
                }
            }
            Section {
                Text("Saves a tracked row. Prices stay empty until the home worker refreshes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Confirm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(isSaving)
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
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await store.addTrackedItem(
                name: name,
                notes: notes,
                priority: priority,
                listOwner: listOwner,
                storeKeys: storeKeys,
                amazonURL: amazonURL,
                targetURL: targetURL,
                walmartURL: walmartURL
            )
            isPresented = false
        } catch let error as SheetClientError {
            saveError = error.errorDescription
        } catch {
            saveError = "Could not save this item."
        }
    }
}
