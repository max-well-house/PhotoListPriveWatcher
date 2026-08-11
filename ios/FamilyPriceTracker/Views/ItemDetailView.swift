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
    }
}
