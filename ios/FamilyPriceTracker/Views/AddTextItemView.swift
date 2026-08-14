import SwiftUI

struct AddTextItemView: View {
    @EnvironmentObject private var store: WishlistStore
    @Binding var isPresented: Bool

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var priority: Int = ItemPriority.default
    @State private var listOwner: String = ""
    @State private var showingConfirm = false

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !trimmedName.isEmpty && store.listOwners.contains(listOwner)
    }

    var body: some View {
        Form {
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
        }
        .navigationTitle("New item")
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
            ConfirmAddTextItemView(
                isPresented: $isPresented,
                name: trimmedName,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                listOwner: listOwner
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
    }
}

struct ConfirmAddTextItemView: View {
    @EnvironmentObject private var store: WishlistStore
    @Binding var isPresented: Bool

    let name: String
    let notes: String
    let priority: Int
    let listOwner: String

    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        List {
            Section("Confirm") {
                LabeledContent("Name", value: name)
                LabeledContent("List", value: listOwner)
                LabeledContent("Priority", value: ItemPriority.label(priority))
                if notes.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                } else {
                    Text(notes)
                }
            }
            Section {
                Text("Saves a text wishlist row. Store links stay empty until you add them later.")
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
            try await store.addTextItem(
                name: name,
                notes: notes,
                priority: priority,
                listOwner: listOwner
            )
            isPresented = false
        } catch let error as SheetClientError {
            saveError = error.errorDescription
        } catch {
            saveError = "Could not save this item."
        }
    }
}
