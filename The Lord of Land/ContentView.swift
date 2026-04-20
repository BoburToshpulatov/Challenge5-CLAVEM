import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var store = AppStore()
    @State private var hasLoadedPersistentData = false

    var body: some View {
        NavigationStack {
            HomeView(store: store)
        }
        .task {
            guard !hasLoadedPersistentData else { return }

            let appStore = store
            appStore.load(from: modelContext)

            hasLoadedPersistentData = true
        }
        .onChange(of: store.properties) { _, _ in
            persist()
        }
        .onChange(of: store.tenants) { _, _ in
            persist()
        }
        .onChange(of: store.payments) { _, _ in
            persist()
        }
        .onChange(of: store.bills) { _, _ in
            persist()
        }
        .onChange(of: store.billShares) { _, _ in
            persist()
        }
        .onChange(of: store.occupancyHistory) { _, _ in
            persist()
        }
    }

    private func persist() {
        guard hasLoadedPersistentData else { return }

        let appStore = store
        appStore.save(to: modelContext)
    }
}
