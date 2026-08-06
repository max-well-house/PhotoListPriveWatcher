import SwiftUI

struct ItemDetailView: View {
    let item: WishlistItem

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("List", value: item.listOwner)
                LabeledContent("Priority", value: "\(item.priority)")
                LabeledContent("Type", value: item.type)
                LabeledContent("Status", value: item.status)
                if !item.notes.isEmpty {
                    Text(item.notes)
                }
            }
            Section("Prices") {
                if let urlString = item.amazonURL, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Text("Amazon")
                            Spacer()
                            Text(item.amazonPrice.map { "$\($0)" } ?? "Open")
                        }
                    }
                } else {
                    Text("No store links yet")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(item.name)
    }
}
