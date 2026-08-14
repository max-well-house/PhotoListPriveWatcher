import SwiftUI

@main
struct FamilyPriceTrackerApp: App {
    @StateObject private var store = WishlistStore(client: SampleSheetClient())

    var body: some Scene {
        WindowGroup {
            ItemListView()
                .environmentObject(store)
        }
    }
}
